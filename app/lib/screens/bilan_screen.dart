import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/reglages_utilisateur.dart';
import '../models/tache.dart';
import '../services/firestore_service.dart';
import '../services/utilisateur_service.dart';
import '../utils/dates_fr.dart';
import '../widgets/statistiques_bilan.dart';
import 'dossier_detail_screen.dart';

enum _Periode { semaine, mois, trimestre, semestre, annee }

extension on _Periode {
  String get libelle => switch (this) {
        _Periode.semaine => 'Semaine',
        _Periode.mois => 'Mois',
        _Periode.trimestre => 'Trimestre',
        _Periode.semestre => 'Semestre',
        _Periode.annee => 'Année',
      };

  /// null = calculé en jours (semaine), sinon en blocs de mois.
  int? get moisParPeriode => switch (this) {
        _Periode.semaine => null,
        _Periode.mois => 1,
        _Periode.trimestre => 3,
        _Periode.semestre => 6,
        _Periode.annee => 12,
      };
}

/// Bornes [début, fin) de la période choisie, décalée de [decalage] crans
/// (0 = période en cours, -1 = précédente, etc.) — correction demandée par
/// Tobie : pouvoir naviguer dans les semaines/mois/... passés, pas juste
/// une fenêtre glissante de N jours autour d'aujourd'hui.
({DateTime debut, DateTime fin}) _bornesPeriode(_Periode periode, int decalage) {
  final maintenant = DateTime.now();
  if (periode == _Periode.semaine) {
    final lundiCetteSemaine = DateTime(maintenant.year, maintenant.month, maintenant.day)
        .subtract(Duration(days: maintenant.weekday - DateTime.monday));
    final debut = lundiCetteSemaine.add(Duration(days: 7 * decalage));
    return (debut: debut, fin: debut.add(const Duration(days: 7)));
  }
  final taille = periode.moisParPeriode!;
  final totalMoisActuel = maintenant.year * 12 + (maintenant.month - 1);
  final indexPeriodeActuelle = totalMoisActuel ~/ taille;
  final indexPeriodeCible = indexPeriodeActuelle + decalage;

  // indexPeriodeCible désigne un bloc de `taille` mois (ex: le 3e trimestre) :
  // on le reconvertit en (année, mois) en repassant par un total de mois.
  DateTime debutDuBloc(int indexBloc) {
    final totalMois = indexBloc * taille;
    return DateTime(totalMois ~/ 12, totalMois % 12 + 1, 1);
  }

  return (debut: debutDuBloc(indexPeriodeCible), fin: debutDuBloc(indexPeriodeCible + 1));
}

const _moisFrPlein = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

String _libellePeriode(_Periode periode, DateTime debut, DateTime finExclusive) {
  final finInclusive = finExclusive.subtract(const Duration(days: 1));
  return switch (periode) {
    _Periode.semaine => '${formaterDateFr(debut)} - ${formaterDateFr(finInclusive)}',
    _Periode.mois => '${_moisFrPlein[debut.month - 1]} ${debut.year}',
    _Periode.trimestre => 'T${((debut.month - 1) ~/ 3) + 1} ${debut.year}',
    _Periode.semestre => 'S${((debut.month - 1) ~/ 6) + 1} ${debut.year}',
    _Periode.annee => '${debut.year}',
  };
}

/// Écran 3 du MVP : le bilan, groupé par dossier, navigable période par
/// période (semaine, mois, trimestre, semestre, année — passées ou en cours).
/// - "Fait" = tâches marquées faites PENDANT la période affichée.
/// - "À venir" = tâches à faire dont l'échéance tombe PENDANT la période affichée.
/// - "En retard" = état réel actuel, affiché seulement sur la période en cours
///   (ça n'a pas de sens de parler de "retard" pour une période déjà passée).
class BilanScreen extends StatefulWidget {
  const BilanScreen({super.key});

  @override
  State<BilanScreen> createState() => _BilanScreenState();
}

class _BilanScreenState extends State<BilanScreen> {
  _Periode _periode = _Periode.semaine;
  int _decalage = 0;

  void _changerPeriode(_Periode nouvelle) {
    setState(() {
      _periode = nouvelle;
      _decalage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bornes = _bornesPeriode(_periode, _decalage);
    final periodeEnCours = _decalage == 0;

    return StreamBuilder<List<Tache>>(
        stream: FirestoreService.instance.toutesLesTaches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(title: const Text('Bilan')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Bilan')),
              body: Center(child: Text('Erreur : ${snapshot.error}')),
            );
          }
          final taches = snapshot.data ?? [];

          bool estFaitDansLaPeriode(Tache t) =>
              t.statut == StatutTache.fait &&
              t.dateFait != null &&
              !t.dateFait!.isBefore(bornes.debut) &&
              t.dateFait!.isBefore(bornes.fin);
          bool estAVenirDansLaPeriode(Tache t) =>
              t.statut == StatutTache.aFaire &&
              !t.estEnRetard &&
              !t.dateDeclenchante.isBefore(bornes.debut) &&
              t.dateDeclenchante.isBefore(bornes.fin);

          final parDossier = <String, List<Tache>>{};
          for (final t in taches) {
            parDossier.putIfAbsent(t.dossierId, () => []).add(t);
          }

          final totalFait = taches.where(estFaitDansLaPeriode).length;
          final totalEnRetard = taches.where((t) => t.estEnRetard).length;
          final totalAVenir = taches.where(estAVenirDansLaPeriode).length;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Bilan'),
              actions: [
                IconButton(
                  tooltip: 'Partager ce bilan',
                  icon: const Icon(Icons.ios_share),
                  onPressed: () => _partager(
                    bornes: bornes,
                    totalFait: totalFait,
                    totalEnRetard: totalEnRetard,
                    totalAVenir: totalAVenir,
                    periodeEnCours: periodeEnCours,
                    parDossier: parDossier,
                    estFaitDansLaPeriode: estFaitDansLaPeriode,
                    estAVenirDansLaPeriode: estAVenirDansLaPeriode,
                  ),
                ),
              ],
            ),
            body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<_Periode>(
                    segments: _Periode.values
                        .map((p) => ButtonSegment(value: p, label: Text(p.libelle)))
                        .toList(),
                    selected: {_periode},
                    onSelectionChanged: (s) => _changerPeriode(s.first),
                    showSelectedIcon: false,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() => _decalage -= 1),
                    ),
                    Text(
                      _libellePeriode(_periode, bornes.debut, bornes.fin),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      // Navigation libre vers le futur aussi : c'est ce qui permet
                      // de voir les dossiers "en attente" (délai standard pas encore
                      // ouvert) avant qu'ils n'apparaissent dans "À traiter" — sinon
                      // ils restent invisibles et risquent d'être oubliés/redoublés.
                      onPressed: () => setState(() => _decalage += 1),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: taches.isEmpty
                    ? const Center(child: Text('Rien à afficher pour l\'instant.'))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        children: [
                          Card(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  _Compteur(label: 'Fait', valeur: totalFait, couleur: Colors.green),
                                  if (periodeEnCours)
                                    _Compteur(label: 'En retard', valeur: totalEnRetard, couleur: Colors.red),
                                  _Compteur(label: 'À venir', valeur: totalAVenir, couleur: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                          if (!periodeEnCours)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                '"En retard" n\'est affiché que sur la période en cours — '
                                'ça n\'a pas de sens pour une période déjà passée.',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Card(
                            child: ExpansionTile(
                              leading: const Icon(Icons.insights_outlined),
                              title: const Text('Statistiques'),
                              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              children: [
                                StatistiquesBilan(
                                  toutesLesTaches: taches,
                                  tachesFaitesPeriode: taches.where(estFaitDansLaPeriode).toList(),
                                  totalEnRetardPeriode: periodeEnCours ? totalEnRetard : 0,
                                  totalAVenirPeriode: totalAVenir,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          _SectionResumeIa(
                            texteBilan: _texteBilan(
                              bornes: bornes,
                              totalFait: totalFait,
                              totalEnRetard: totalEnRetard,
                              totalAVenir: totalAVenir,
                              periodeEnCours: periodeEnCours,
                              parDossier: parDossier,
                              estFaitDansLaPeriode: estFaitDansLaPeriode,
                              estAVenirDansLaPeriode: estAVenirDansLaPeriode,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...parDossier.entries.map((entree) {
                            final tachesDossier = entree.value;
                            final nomDossier = tachesDossier.first.nomCodeDossier;
                            final fait = tachesDossier.where(estFaitDansLaPeriode).length;
                            final enRetard = tachesDossier.where((t) => t.estEnRetard).length;
                            final aVenir = tachesDossier.where(estAVenirDansLaPeriode).length;
                            if (fait == 0 && (!periodeEnCours || enRetard == 0) && aVenir == 0) {
                              return const SizedBox.shrink();
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: InkWell(
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => DossierDetailScreen(dossierId: entree.key),
                                )),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
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
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          _Compteur(label: 'Fait', valeur: fait, couleur: Colors.green),
                                          if (periodeEnCours)
                                            _Compteur(label: 'En retard', valeur: enRetard, couleur: Colors.red),
                                          _Compteur(label: 'À venir', valeur: aVenir, couleur: Colors.grey),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
              ),
            ],
            ),
          );
        },
      );
  }

  /// Texte anonymisé du Bilan (chiffres + noms de code, jamais de vraies
  /// informations — demandé par Tobie le 2026-08-20) : source commune pour
  /// le partage ET pour le résumé IA (2026-08-22), pour ne jamais envoyer
  /// à un tiers plus de données que ce que l'utilisateur partage déjà
  /// volontairement ailleurs dans l'app.
  String _texteBilan({
    required ({DateTime debut, DateTime fin}) bornes,
    required int totalFait,
    required int totalEnRetard,
    required int totalAVenir,
    required bool periodeEnCours,
    required Map<String, List<Tache>> parDossier,
    required bool Function(Tache) estFaitDansLaPeriode,
    required bool Function(Tache) estAVenirDansLaPeriode,
  }) {
    final buffer = StringBuffer()
      ..writeln('Bilan Vigie — ${_libellePeriode(_periode, bornes.debut, bornes.fin)}')
      ..writeln()
      ..write('Total : $totalFait fait, ')
      ..write(periodeEnCours ? '$totalEnRetard en retard, ' : '')
      ..writeln('$totalAVenir à venir')
      ..writeln();

    for (final entree in parDossier.entries) {
      final tachesDossier = entree.value;
      final nomDossier = tachesDossier.first.nomCodeDossier;
      final fait = tachesDossier.where(estFaitDansLaPeriode).length;
      final enRetard = tachesDossier.where((t) => t.estEnRetard).length;
      final aVenir = tachesDossier.where(estAVenirDansLaPeriode).length;
      if (fait == 0 && (!periodeEnCours || enRetard == 0) && aVenir == 0) continue;
      buffer.write('$nomDossier : $fait fait, ');
      if (periodeEnCours) buffer.write('$enRetard en retard, ');
      buffer.writeln('$aVenir à venir');
    }
    return buffer.toString();
  }

  Future<void> _partager({
    required ({DateTime debut, DateTime fin}) bornes,
    required int totalFait,
    required int totalEnRetard,
    required int totalAVenir,
    required bool periodeEnCours,
    required Map<String, List<Tache>> parDossier,
    required bool Function(Tache) estFaitDansLaPeriode,
    required bool Function(Tache) estAVenirDansLaPeriode,
  }) async {
    final texte = _texteBilan(
      bornes: bornes,
      totalFait: totalFait,
      totalEnRetard: totalEnRetard,
      totalAVenir: totalAVenir,
      periodeEnCours: periodeEnCours,
      parDossier: parDossier,
      estFaitDansLaPeriode: estFaitDansLaPeriode,
      estAVenirDansLaPeriode: estAVenirDansLaPeriode,
    );
    final buffer = StringBuffer()
      ..write(texte)
      ..writeln()
      ..write(
        'Généré par Vigie — noms de code choisis par l\'utilisateur, '
        'aucune information sensible.',
      );

    await Share.share(buffer.toString());
  }
}

/// Résumé + recommandations générés par IA (Groq) à partir du texte
/// anonymisé du Bilan — désactivé par défaut, avertissement avant
/// activation (même principe que le chemin IA pour l'extraction Gmail,
/// décision du 2026-08-15). Demandé par Tobie le 18 août ("résumé écrit
/// automatique via IA Groq, recommandations/alertes intelligentes"), resté
/// en attente jusqu'ici (seuls les statistiques/graphiques avaient été
/// faits).
class _SectionResumeIa extends StatefulWidget {
  const _SectionResumeIa({required this.texteBilan});

  final String texteBilan;

  @override
  State<_SectionResumeIa> createState() => _SectionResumeIaState();
}

class _SectionResumeIaState extends State<_SectionResumeIa> {
  bool _enCours = false;
  String? _resume;
  String? _erreur;

  @override
  void didUpdateWidget(covariant _SectionResumeIa oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La période affichée a changé : le résumé précédent ne correspond plus
    // à rien de visible à l'écran, on l'efface plutôt que de laisser un
    // résumé obsolète sous des chiffres différents.
    if (oldWidget.texteBilan != widget.texteBilan) {
      setState(() {
        _resume = null;
        _erreur = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ReglagesUtilisateur>(
      stream: UtilisateurService.instance.reglages(),
      builder: (context, snapshot) {
        final actif = snapshot.data?.bilanIaActif ?? false;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_outlined, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Résumé & recommandations', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    if (actif)
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          tooltip: 'Désactiver',
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: _desactiver,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (!actif) ...[
                  const Text(
                    'Un résumé et des recommandations générés par une IA (Groq), à partir '
                    'des mêmes chiffres anonymisés que le partage du Bilan — désactivé par défaut.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _activer,
                    icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: const Text('Activer'),
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed: _enCours ? null : _generer,
                    icon: _enCours
                        ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: Text(_resume == null ? 'Générer' : 'Régénérer'),
                  ),
                  if (_erreur != null) ...[
                    const SizedBox(height: 8),
                    Text(_erreur!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                  if (_resume != null) ...[
                    const SizedBox(height: 10),
                    Text(_resume!),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _activer() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Avant d\'activer le résumé IA'),
        content: const Text(
          'Le texte du Bilan (chiffres et noms de code, jamais de vraies informations '
          '— le même contenu déjà utilisé pour le partage) est envoyé à un service '
          'd\'intelligence artificielle tiers (Groq) pour générer un résumé.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Activer')),
        ],
      ),
    );
    if (confirme == true) {
      await UtilisateurService.instance.definirBilanIaActif(true);
    }
  }

  Future<void> _desactiver() async {
    await UtilisateurService.instance.definirBilanIaActif(false);
    if (mounted) setState(() { _resume = null; _erreur = null; });
  }

  Future<void> _generer() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final resultat = await FirebaseFunctions.instance
          .httpsCallable('generer_resume_bilan')
          .call({'texteBilan': widget.texteBilan});
      if (mounted) setState(() => _resume = resultat.data['resume'] as String);
    } catch (e) {
      if (mounted) setState(() => _erreur = 'Impossible de générer le résumé : $e');
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }
}

class _Compteur extends StatelessWidget {
  const _Compteur({required this.label, required this.valeur, required this.couleur});

  final String label;
  final int valeur;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label : $valeur'),
      backgroundColor: couleur.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: couleur, fontWeight: FontWeight.w600),
    );
  }
}
