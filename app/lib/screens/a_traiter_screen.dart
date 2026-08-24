import 'dart:async';

import 'package:flutter/material.dart';
import '../models/proposition_dossier.dart';
import '../models/tache.dart';
import '../services/firestore_service.dart';
import '../services/gmail_service.dart';
import '../utils/confirmation.dart';
import '../utils/dates_fr.dart';
import 'ajouter_screen.dart';
import 'dossier_detail_screen.dart';
import 'notifications_screen.dart';
import 'propositions_screen.dart';

/// Écran "À traiter" (anciennement "Aujourd'hui", renommé pour éviter la
/// confusion : il montre ce qu'il faut commencer à traiter maintenant,
/// pas seulement ce qui est dû aujourd'hui — certaines tâches apparaissent
/// jusqu'à plusieurs jours avant leur échéance réelle, volontairement).
/// Groupé par dossier, trié par urgence. Les tâches "en retard" sont mises
/// en évidence (correction du point O).
///
/// Contient aussi une section "En attente" (correction demandée par Tobie) :
/// les tâches dont le délai de rappel n'a pas encore ouvert sont invisibles
/// tant qu'elles ne sont pas actives — sans cette section, le père pourrait
/// oublier qu'il les a déjà ajoutées et les recréer en double. Toujours
/// visible ici, sans avoir à naviguer ailleurs pour y penser.
class ATraiterScreen extends StatefulWidget {
  const ATraiterScreen({super.key});

  @override
  State<ATraiterScreen> createState() => _ATraiterScreenState();
}

class _ATraiterScreenState extends State<ATraiterScreen> {
  Timer? _minuteur;

  @override
  void initState() {
    super.initState();
    // La répartition "actif" / "en attente" dépend de l'heure actuelle
    // (datePremierRappel comparé à DateTime.now()), mais le flux Firestore
    // ne renvoie une mise à jour que si un document change — jamais juste
    // parce que le temps passe. Sans ce minuteur, une tâche pouvait rester
    // coincée dans "En attente" après sa date de rappel, tant qu'aucune
    // autre modification n'avait lieu ailleurs pour forcer un rafraîchissement
    // (bug trouvé par Tobie le 2026-08-22). Toutes les heures suffit largement
    // (la précision utile ici est la journée, pas la minute) et ne coûte
    // qu'un nouveau calcul local, aucun appel réseau.
    _minuteur = Timer.periodic(const Duration(hours: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('À traiter'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          StreamBuilder<List<PropositionDossier>>(
            stream: GmailService.instance.propositions(),
            builder: (context, snapshot) {
              final nombre = snapshot.data?.length ?? 0;
              if (nombre == 0) return const SizedBox.shrink();
              return IconButton(
                tooltip: '$nombre proposition(s) de dossier à valider',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PropositionsScreen()),
                ),
                icon: Badge(
                  label: Text('$nombre'),
                  child: const Icon(Icons.fact_check_outlined),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Tache>>(
        stream: FirestoreService.instance.tachesNonTerminees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final toutes = snapshot.data ?? [];
          final actives = toutes.where((t) => t.estActive).toList()
            ..sort((a, b) {
              if (a.estEnRetard != b.estEnRetard) return a.estEnRetard ? -1 : 1;
              return a.dateDeclenchante.compareTo(b.dateDeclenchante);
            });
          final enAttente = toutes.where((t) => !t.estActive).toList()
            ..sort((a, b) => a.datePremierRappel.compareTo(b.datePremierRappel));

          if (actives.isEmpty && enAttente.isEmpty) {
            return const Center(child: Text('Rien à faire pour l\'instant.'));
          }

          final parDossier = <String, List<Tache>>{};
          for (final t in actives) {
            parDossier.putIfAbsent(t.dossierId, () => []).add(t);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (actives.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Rien à faire pour l\'instant.'),
                ),
              ...parDossier.entries.map((entree) {
                final nomDossier = entree.value.first.nomCodeDossier;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => DossierDetailScreen(dossierId: entree.key),
                        )),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(nomDossier, style: Theme.of(context).textTheme.titleMedium),
                                  ),
                                  const Icon(Icons.chevron_right, size: 18),
                                ],
                              ),
                              _ProgressionDossier(dossierId: entree.key),
                            ],
                          ),
                        ),
                      ),
                      ...entree.value.map((t) => _LigneTache(tache: t)),
                    ],
                  ),
                );
              }),
              if (enAttente.isNotEmpty) ...[
                // Explication déplacée dans une info-bulle au tap plutôt qu'un
                // paragraphe permanent — allège l'écran (design épuré demandé
                // par Tobie) sans perdre la visibilité de la liste elle-même,
                // qui doit rester toujours affichée (évite les doublons, point
                // du 2026-08-08).
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
                  child: Row(
                    children: [
                      const Text('En attente (pas encore actif)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 2),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.info_outline, size: 16),
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ces dossiers existent déjà — inutile de les recréer. Ils passeront '
                                'automatiquement dans la liste ci-dessus quand leur moment arrivera.',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...enAttente.map((t) => _LigneEnAttente(tache: t)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Ajouter',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AjouterScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Progression du dossier (toutes tâches confondues, actives ou en attente) —
/// affichée sous le titre de chaque carte pour voir d'un coup d'œil ce qu'il
/// reste à traiter, sans avoir à ouvrir le dossier.
class _ProgressionDossier extends StatelessWidget {
  const _ProgressionDossier({required this.dossierId});

  final String dossierId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Tache>>(
      stream: FirestoreService.instance.tachesDuDossier(dossierId),
      builder: (context, snapshot) {
        final taches = snapshot.data ?? [];
        if (taches.isEmpty) return const SizedBox.shrink();
        final total = taches.length;
        final faites = taches.where((t) => t.statut == StatutTache.fait).length;
        final ratio = faites / total;
        final termine = faites == total;
        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  color: termine ? Colors.green : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$faites/$total tâches faites (${(ratio * 100).round()}%)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LigneEnAttente extends StatelessWidget {
  const _LigneEnAttente({required this.tache});

  final Tache tache;

  @override
  Widget build(BuildContext context) {
    final joursAvantActivation = DateTime(
      tache.datePremierRappel.year,
      tache.datePremierRappel.month,
      tache.datePremierRappel.day,
    ).difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: ListTile(
        leading: const Icon(Icons.hourglass_empty, color: Colors.grey),
        title: Text('${tache.nomCodeDossier} — ${tache.descriptionCourte}'),
        subtitle: Text(
          'Échéance le ${formaterDateFr(tache.dateDeclenchante)} — '
          'apparaîtra dans "À traiter" dans $joursAvantActivation jours',
        ),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DossierDetailScreen(dossierId: tache.dossierId),
        )),
      ),
    );
  }
}

class _LigneTache extends StatelessWidget {
  const _LigneTache({required this.tache});

  final Tache tache;

  // Comparer des dates calendaires (sans l'heure), sinon "demain" peut se
  // décaler selon l'heure qu'il est au moment où on regarde (bug trouvé
  // par Tobie : le 8 août à 15h, le 10 août calculait "1 jour" au lieu de 2).
  int get _joursRestants {
    final aujourdhui = DateTime.now();
    final aujourdhuiSansHeure = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);
    final echeanceSansHeure = DateTime(
      tache.dateDeclenchante.year,
      tache.dateDeclenchante.month,
      tache.dateDeclenchante.day,
    );
    return echeanceSansHeure.difference(aujourdhuiSansHeure).inDays;
  }

  /// Pastille courte et colorée plutôt qu'une phrase complète — plus
  /// scannable d'un coup d'œil dans une liste (design épuré, inspiré de
  /// Todoist, demandé par Tobie le 2026-08-09).
  String get _texteCourt {
    if (tache.estEnRetard) return 'En retard';
    final j = _joursRestants;
    if (j <= 0) return 'Aujourd\'hui';
    if (j == 1) return 'Demain';
    return 'Dans $j j';
  }

  Color get _couleurEcheance {
    if (tache.estEnRetard) return Colors.red;
    final j = _joursRestants;
    if (j <= 0) return Colors.orange;
    if (j <= 2) return Colors.amber.shade800;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        tache.estEnRetard ? Icons.warning_amber_rounded : Icons.schedule,
        color: tache.estEnRetard ? Colors.red : Colors.grey,
      ),
      title: Text(tache.descriptionCourte),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _couleurEcheance.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _texteCourt,
                style: TextStyle(color: _couleurEcheance, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formaterDateFr(tache.dateDeclenchante),
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
      // Revenu au bouton texte "C'est fait" (2026-08-21, retour de Tobie
      // après test réel) : la case à cocher tentée le même jour, pourtant
      // inspirée de Todoist, s'est révélée moins intuitive à l'usage — la
      // double confirmation reste inchangée dans les deux cas.
      trailing: FilledButton(
        onPressed: () => _confirmerFait(context),
        child: const Text('C\'est fait'),
      ),
    );
  }

  Future<void> _confirmerFait(BuildContext context) async {
    final confirme = await demanderDoubleConfirmation(
      context,
      titre: 'Marquer comme fait ?',
      message: '"${tache.descriptionCourte}" sera marquée comme faite.',
    );
    if (confirme) {
      await FirestoreService.instance.marquerFait(tache.id);
    }
  }
}
