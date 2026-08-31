import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/dossier.dart';
import '../models/entree_journal.dart';
import '../models/nature_dossier.dart';
import '../models/tache.dart';
import '../services/chiffrement_notes_service.dart';
import '../services/firestore_service.dart';
import '../services/nature_dossier_service.dart';
import '../utils/confirmation.dart';
import '../utils/dates_fr.dart';
import '../utils/notes_structurees.dart';
import '../widgets/dialogue_phrase_secrete.dart';
import '../widgets/vue_acces_revoque.dart';
import 'participants_dossier_screen.dart';

/// Écran de détail d'un dossier — corrige le point le plus critique du
/// dernier Red Team : voir/ajouter/modifier/supprimer les tâches d'un
/// dossier, et modifier ou supprimer le dossier lui-même.
class DossierDetailScreen extends StatelessWidget {
  const DossierDetailScreen({super.key, required this.dossierId});

  final String dossierId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Dossier>(
        stream: FirestoreService.instance.dossier(dossierId),
        builder: (context, snapshotDossier) {
          // Accès révoqué pendant la consultation (retiré du dossier par un
          // administrateur) : sans ce garde-fou, l'écran reste bloqué sur le
          // chargement pour toujours (voir VueAccesRevoque).
          if (snapshotDossier.hasError) {
            return VueAccesRevoque(erreur: snapshotDossier.error);
          }
          if (!snapshotDossier.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final l10n = AppLocalizations.of(context)!;
          final dossier = snapshotDossier.data!;
          // Repli défensif plutôt qu'un `!.uid` qui planterait (trouvé en
          // Red Team le 2026-08-30, via /code-review) : un garde d'auth au
          // sommet de l'app (main.dart) rend `currentUser` null quasiment
          // impossible ici en pratique, mais reste plus sûr qu'un crash pur
          // si jamais un rebuild survenait pile pendant une déconnexion.
          final monUid = FirebaseAuth.instance.currentUser?.uid;
          if (monUid == null) {
            return const VueAccesRevoque();
          }
          // Bouton "Supprimer" réservé créateur/administrateur côté règles
          // (voir firestore.rules) — masqué ici pour un simple contributeur
          // plutôt que de le laisser taper dans le vide après la double
          // confirmation (trouvé en Red Team le 2026-08-30, via /code-review) :
          // avant la Phase 1, TOUT participant était forcément le seul
          // propriétaire, donc ce bouton n'avait jamais besoin d'être masqué.
          final monRole = dossier.roleDe(monUid);
          final jePeuxSupprimer = monRole == 'createur' || monRole == 'administrateur';
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(dossier.nomCode),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.people_outline),
                    tooltip: l10n.dossierDetailParticipantsTooltip,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ParticipantsDossierScreen(dossierId: dossier.id)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: l10n.dossierDetailModifierTooltip,
                    onPressed: () => _modifierDossier(context, dossier),
                  ),
                  if (jePeuxSupprimer)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l10n.dossierDetailSupprimerTooltip,
                      onPressed: () => _supprimerDossier(context, dossier),
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    dossier.dateEvenement != null
                        ? l10n.dossierDetailDateAvecValeur(formaterDateFr(dossier.dateEvenement!))
                        : l10n.dossierDetailPasDeDate,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(l10n.dossierDetailTachesLieesTitre, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              StreamBuilder<List<Tache>>(
                stream: FirestoreService.instance.tachesDuDossier(dossierId),
                builder: (context, snapshotTaches) {
                  final taches = snapshotTaches.data ?? [];
                  if (!snapshotTaches.hasData) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (taches.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.dossierDetailAucuneTache),
                      ),
                    );
                  }
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(child: _BarreProgression(taches: taches)),
                      SliverList.builder(
                        itemCount: taches.length,
                        itemBuilder: (context, i) => _LigneTacheDetail(tache: taches[i]),
                      ),
                    ],
                  );
                },
              ),
              SliverToBoxAdapter(
                child: _SectionJournal(
                  dossierId: dossierId,
                  participantsUids: dossier.participantsUids,
                  monUid: monUid,
                  monRole: monRole,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ajouterTache(context, dossierId),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.dossierDetailAjouterTacheBouton),
      ),
    );
  }

  Future<void> _modifierDossier(BuildContext context, Dossier dossier) async {
    final resultat = await showDialog<({String nomCode, DateTime? date})>(
      context: context,
      builder: (context) => _DialogueModifierDossier(dossier: dossier),
    );
    if (resultat != null) {
      await FirestoreService.instance.modifierDossier(
        dossier.id,
        nomCode: resultat.nomCode,
        dateEvenement: resultat.date,
      );
    }
  }

  Future<void> _supprimerDossier(BuildContext context, Dossier dossier) async {
    final l10n = AppLocalizations.of(context)!;
    final confirme = await demanderDoubleConfirmation(
      context,
      titre: l10n.dossierDetailSupprimerDossierTitre,
      message: l10n.dossierDetailSupprimerDossierMessage(dossier.nomCode),
      texteBouton: l10n.commonSupprimer,
      destructif: true,
    );
    if (confirme && context.mounted) {
      try {
        await FirestoreService.instance.supprimerDossier(dossier.id);
        if (context.mounted) Navigator.of(context).pop();
      } catch (e) {
        // Défense en profondeur (le bouton est déjà masqué pour un simple
        // contributeur) : couvre la fenêtre de course où le rôle changerait
        // pendant la double confirmation, plutôt qu'une exception non
        // gérée sans aucun retour visible pour l'utilisateur.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.participantsErreurGenerique)),
          );
        }
      }
    }
  }

  Future<void> _ajouterTache(BuildContext context, String dossierId) async {
    final dossier = await FirestoreService.instance.dossier(dossierId).first;
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (context) => _DialogueTache(dossier: dossier),
    );
  }
}

/// Barre de progression du dossier : compte TOUTES les tâches (y compris
/// celles "en attente", pas encore actives) — un dossier n'est vraiment
/// terminé que quand plus aucune tâche, présente ou future, ne reste à faire.
class _BarreProgression extends StatelessWidget {
  const _BarreProgression({required this.taches});

  final List<Tache> taches;

  @override
  Widget build(BuildContext context) {
    final total = taches.length;
    final faites = taches.where((t) => t.statut == StatutTache.fait).length;
    final ratio = faites / total;
    final termine = faites == total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              color: termine ? Colors.green : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.aTraiterProgressionDossier(faites, total, (ratio * 100).round()),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LigneTacheDetail extends StatelessWidget {
  const _LigneTacheDetail({required this.tache});

  final Tache tache;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: tache.statut == StatutTache.fait,
        onChanged: (coche) => _basculerStatut(context, coche ?? false),
      ),
      title: Text(
        tache.descriptionCourte,
        style: tache.statut == StatutTache.fait
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text(
        tache.notesDetaillees?.isNotEmpty == true
            ? '${AppLocalizations.of(context)!.dossierDetailNatureEtDate(tache.nature, formaterDateFr(tache.dateDeclenchante))}\n${tache.notesDetaillees}'
            : AppLocalizations.of(context)!.dossierDetailNatureEtDate(tache.nature, formaterDateFr(tache.dateDeclenchante)),
      ),
      isThreeLine: tache.notesDetaillees?.isNotEmpty == true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => _DialogueTache(tache: tache),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _supprimer(context),
          ),
        ],
      ),
    );
  }

  Future<void> _basculerStatut(BuildContext context, bool coche) async {
    final l10n = AppLocalizations.of(context)!;
    final action = coche ? l10n.dossierDetailBasculerMarquerFait : l10n.dossierDetailBasculerRemettreAFaire;
    final confirme = await demanderDoubleConfirmation(
      context,
      titre: l10n.dossierDetailConfirmerTitre,
      message: l10n.dossierDetailBasculerMessage(action, tache.descriptionCourte),
    );
    if (!confirme) return;
    if (coche) {
      await FirestoreService.instance.marquerFait(tache.id);
    } else {
      await FirestoreService.instance.marquerNonFait(tache.id);
    }
  }

  Future<void> _supprimer(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirme = await demanderDoubleConfirmation(
      context,
      titre: l10n.dossierDetailSupprimerTacheTitre,
      message: l10n.dossierDetailSupprimerTacheMessage(tache.descriptionCourte),
      texteBouton: l10n.commonSupprimer,
      destructif: true,
    );
    if (confirme) {
      await FirestoreService.instance.supprimerTache(tache.id);
    }
  }
}

class _DialogueModifierDossier extends StatefulWidget {
  const _DialogueModifierDossier({required this.dossier});
  final Dossier dossier;

  @override
  State<_DialogueModifierDossier> createState() => _DialogueModifierDossierState();
}

class _DialogueModifierDossierState extends State<_DialogueModifierDossier> {
  late final _nomController = TextEditingController(text: widget.dossier.nomCode);
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _date = widget.dossier.dateEvenement;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.dossierDetailModifierTooltip),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nomController, decoration: InputDecoration(labelText: l10n.creationDossierChampNomCode)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.event),
            label: Text(_date == null ? l10n.ajouterChoisirDate : formaterDateFr(_date!)),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonAnnuler)),
        FilledButton(
          onPressed: () => Navigator.pop(context, (nomCode: _nomController.text.trim(), date: _date)),
          child: Text(l10n.commonEnregistrer),
        ),
      ],
    );
  }
}

/// Ajoute une nouvelle tâche, ou modifie une tâche existante si [tache] est fourni.
class _DialogueTache extends StatefulWidget {
  const _DialogueTache({this.dossier, this.tache}) : assert(dossier != null || tache != null);
  final Dossier? dossier;
  final Tache? tache;

  @override
  State<_DialogueTache> createState() => _DialogueTacheState();
}

class _DialogueTacheState extends State<_DialogueTache> {
  late final _descriptionController =
      TextEditingController(text: widget.tache?.descriptionCourte ?? '');
  late final _notesInitiales = NotesStructurees.analyser(widget.tache?.notesDetaillees);
  late final _resteController = TextEditingController(text: _notesInitiales.resteAVerifier);
  late final _attenteController = TextEditingController(text: _notesInitiales.enAttenteDe);
  late final _autreController = TextEditingController(text: _notesInitiales.autre);
  NatureDossier? _nature;
  late DateTime _date = widget.tache?.dateDeclenchante ?? DateTime.now().add(const Duration(days: 14));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.tache == null ? l10n.dossierDetailAjouterTacheBouton : l10n.dossierDetailModifierTacheTitre),
      content: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: l10n.dossierDetailDetailTacheLabel),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<NatureDossier>>(
            stream: NatureDossierService.instance.natures(),
            builder: (context, snapshot) {
              final natures = snapshot.data ?? [];
              _nature ??= natures.firstWhere(
                (n) => n.nom == widget.tache?.nature,
                orElse: () => natures.isNotEmpty
                    ? natures.first
                    : NatureDossier(id: '', nom: widget.tache?.nature ?? l10n.professionAutre),
              );
              return DropdownButtonFormField<NatureDossier>(
                initialValue: _nature,
                items: {...natures, _nature!}
                    .map((n) => DropdownMenuItem(value: n, child: Text(n.nom)))
                    .toList(),
                onChanged: (n) => setState(() => _nature = n!),
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.event),
            label: Text(formaterDateFr(_date)),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(l10n.creationDossierNotesTitre, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _resteController,
            decoration: InputDecoration(
              labelText: l10n.creationDossierChampResteAVerifier,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _attenteController,
            decoration: InputDecoration(
              labelText: l10n.creationDossierChampEnAttenteDe,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _autreController,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              labelText: l10n.creationDossierChampAutre,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.creationDossierAvertissementSensible,
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline),
          ),
        ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonAnnuler)),
        FilledButton(
          onPressed: () async {
            final description = _descriptionController.text.trim();
            if (description.isEmpty || _nature == null) return;
            final notes = NotesStructurees(
              resteAVerifier: _resteController.text.trim(),
              enAttenteDe: _attenteController.text.trim(),
              autre: _autreController.text.trim(),
            );
            final notesTexte = notes.estVide ? null : notes.formater();
            if (widget.tache == null) {
              // Relit le dossier ICI plutôt que d'utiliser le `widget.dossier`
              // capturé à l'ouverture du dialogue (trouvé en Red Team le
              // 2026-08-31, via /code-review) : la boîte peut rester ouverte
              // un moment (temps de remplir le formulaire) pendant lequel les
              // participants peuvent avoir changé — `tacheCoherente()` côté
              // firestore.rules exige désormais une correspondance EXACTE
              // avec l'état ACTUEL du dossier, donc une liste périmée
              // provoquerait un refus (PERMISSION_DENIED) même pour un
              // utilisateur parfaitement légitime.
              final dossierActuel = await FirestoreService.instance.dossier(widget.dossier!.id).first;
              await FirestoreService.instance.ajouterTacheADossier(
                dossierId: dossierActuel.id,
                nomCodeDossier: dossierActuel.nomCode,
                descriptionCourte: description,
                nature: _nature!.nom,
                dateDeclenchante: _date,
                notesDetaillees: notesTexte,
                proprietaireUid: dossierActuel.uid,
                participantsUids: dossierActuel.participantsUids,
              );
            } else {
              await FirestoreService.instance.modifierTache(
                Tache(
                  id: widget.tache!.id,
                  uid: widget.tache!.uid,
                  dossierId: widget.tache!.dossierId,
                  nomCodeDossier: widget.tache!.nomCodeDossier,
                  descriptionCourte: description,
                  nature: _nature!.nom,
                  dateDeclenchante: _date,
                  datePremierRappel: widget.tache!.datePremierRappel,
                  statut: widget.tache!.statut,
                  notesDetaillees: notesTexte,
                ),
              );
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(l10n.commonEnregistrer),
        ),
      ],
    );
  }
}

/// Rendu visuel d'un [TypeEntreeJournal] — guide l'utilisateur en lui
/// proposant un choix rapide plutôt qu'un champ de texte libre générique
/// (demandé par Tobie le 2026-08-20).
extension _AffichageType on TypeEntreeJournal {
  String libelle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      TypeEntreeJournal.avancement => l10n.journalTypeAvancement,
      TypeEntreeJournal.blocage => l10n.journalTypeBlocage,
      TypeEntreeJournal.decision => l10n.journalTypeDecision,
      TypeEntreeJournal.autre => l10n.professionAutre,
    };
  }

  IconData get icone => switch (this) {
        TypeEntreeJournal.avancement => Icons.trending_up,
        TypeEntreeJournal.blocage => Icons.block,
        TypeEntreeJournal.decision => Icons.gavel,
        TypeEntreeJournal.autre => Icons.notes,
      };

  Color get couleur => switch (this) {
        TypeEntreeJournal.avancement => Colors.green,
        TypeEntreeJournal.blocage => Colors.red,
        TypeEntreeJournal.decision => Colors.blue,
        TypeEntreeJournal.autre => Colors.grey,
      };
}

/// Une entrée prête à afficher : [entree].texte est le texte réel (en clair)
/// si [verrouillee] est faux, ou reste le texte chiffré (jamais affiché
/// directement, voir _ligneEntree) si vrai.
class _EntreeAffichable {
  _EntreeAffichable({required this.entree, required this.verrouillee});
  final EntreeJournal entree;
  final bool verrouillee;
}

/// Journal de bord du dossier — des entrées datées et taguées qu'on ajoute
/// au fil du temps pour documenter l'avancement étape par étape, jamais un
/// champ qu'on écrase (demandé par Tobie le 2026-08-20 : "noter et
/// documenter l'avancement, l'évolution d'un dossier" — bien distinct des
/// notes par tâche, qui décrivent un état ponctuel, pas une progression).
/// Chaque entrée est taguée (Avancement/Blocage/Décision/Autre) pour guider
/// la saisie, et affichée en frise chronologique plutôt qu'en simples cartes
/// identiques ("il ne s'agit pas juste d'ajouter une note tout court").
class _SectionJournal extends StatefulWidget {
  const _SectionJournal({
    required this.dossierId,
    required this.participantsUids,
    required this.monUid,
    required this.monRole,
  });
  final String dossierId;
  final List<String> participantsUids;
  final String monUid;
  final String monRole;

  @override
  State<_SectionJournal> createState() => _SectionJournalState();
}

class _SectionJournalState extends State<_SectionJournal> {
  final _controleur = TextEditingController();
  TypeEntreeJournal _typeSelectionne = TypeEntreeJournal.avancement;
  bool _enCours = false;
  TypeEntreeJournal? _filtreType;

  @override
  void initState() {
    super.initState();
    // Tente le déverrouillage automatique (clé déjà en cache sur cet
    // appareil) dès l'ouverture, pour que le bouton "Déverrouiller mes
    // notes" n'apparaisse pas inutilement le temps d'une interaction.
    ChiffrementNotesService.instance.tenterDeverrouillageAutomatique().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _ajouter() async {
    final texte = _controleur.text.trim();
    if (texte.isEmpty) return;
    // Chiffrement désactivé dès qu'un dossier est partagé (décision de
    // Tobie le 2026-08-30, Red Team) : la clé dérivée de la phrase secrète
    // est strictement personnelle à celui qui écrit, jamais partagée — un
    // autre participant ne pourrait JAMAIS déchiffrer une entrée chiffrée
    // avec la clé de quelqu'un d'autre (voir _dechiffrerToutes, qui affiche
    // alors l'entrée comme verrouillée pour toujours, même après avoir
    // déverrouillé SA PROPRE phrase secrète). Reste actif pour un dossier
    // strictement solo, où ce problème ne se pose pas.
    if (widget.participantsUids.length <= 1) {
      final deverrouille = await demanderPhraseSecrete(context);
      if (!deverrouille || !mounted) return;
    }
    setState(() => _enCours = true);
    try {
      // Relu ICI, pas avant l'attente ci-dessus (trouvé en Red Team le
      // 2026-08-30, via /code-review) : le dossier peut avoir été partagé
      // PENDANT que l'utilisateur saisissait sa phrase secrète — utiliser
      // une valeur capturée avant l'attente aurait pu chiffrer une entrée
      // qui atterrit dans un dossier déjà devenu partagé entre-temps.
      final estPartage = widget.participantsUids.length > 1;
      final texteAEcrire = estPartage ? texte : await ChiffrementNotesService.instance.chiffrer(texte);
      await FirestoreService.instance.ajouterEntreeJournal(
        widget.dossierId,
        texteAEcrire,
        _typeSelectionne,
        chiffre: !estPartage,
        participantsUids: widget.participantsUids,
      );
      _controleur.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.dossierDetailErreurAjoutJournal(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _supprimer(BuildContext context, EntreeJournal entree) async {
    final l10n = AppLocalizations.of(context)!;
    final confirme = await demanderDoubleConfirmation(
      context,
      titre: l10n.dossierDetailSupprimerEntreeTitre,
      message: l10n.dossierDetailSupprimerEntreeMessage(formaterDateHeureFr(entree.creeLe)),
      texteBouton: l10n.commonSupprimer,
      destructif: true,
    );
    if (confirme) {
      try {
        await FirestoreService.instance.supprimerEntreeJournal(entree.id);
      } catch (e) {
        // Défense en profondeur : le bouton est déjà masqué pour qui n'a pas
        // le droit (voir peutGererCetteEntree), mais couvre la fenêtre de
        // course où le rôle changerait pendant la double confirmation.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.participantsErreurGenerique)),
          );
        }
      }
    }
  }

  /// Modification libre d'une entrée déjà écrite (demandé par Tobie le
  /// 2026-08-21, alors qu'au départ le journal était pensé "jamais écrasé" —
  /// choix assumé de Tobie malgré le compromis expliqué).
  Future<void> _editer(BuildContext context, EntreeJournal entree) async {
    if (entree.chiffre) {
      final deverrouille = await demanderPhraseSecrete(context);
      if (!deverrouille || !context.mounted) return;
    }
    final controleur = TextEditingController(text: entree.texte);
    var type = entree.type;
    final enregistrer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final l10n = AppLocalizations.of(dialogContext)!;
          return AlertDialog(
            title: Text(l10n.dossierDetailModifierEntreeTitre),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  children: TypeEntreeJournal.values.map((t) {
                    final selectionne = type == t;
                    return ChoiceChip(
                      label: Text(t.libelle(dialogContext)),
                      avatar: Icon(t.icone, size: 16, color: selectionne ? Colors.white : t.couleur),
                      selected: selectionne,
                      selectedColor: t.couleur,
                      labelStyle: TextStyle(color: selectionne ? Colors.white : null, fontSize: 12),
                      onSelected: (_) => setDialogState(() => type = t),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controleur,
                  autofocus: true,
                  maxLines: 4,
                  minLines: 2,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.commonAnnuler)),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.commonEnregistrer)),
            ],
          );
        },
      ),
    );
    if (enregistrer != true) return;
    final texte = controleur.text.trim();
    if (texte.isEmpty) return;
    try {
      final texteAEcrire = entree.chiffre ? await ChiffrementNotesService.instance.chiffrer(texte) : texte;
      await FirestoreService.instance.modifierEntreeJournal(entree.id, texteAEcrire, type);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.dossierDetailErreurModifJournal(e.toString()))),
        );
      }
    }
  }

  /// Déchiffre chaque entrée marquée [EntreeJournal.chiffre] avec la clé en
  /// mémoire, si elle est disponible — une entrée déjà en clair (écrite
  /// avant l'introduction de ce chiffrement) n'a rien à déchiffrer. Une
  /// entrée chiffrée mais pas encore déverrouillée reste marquée
  /// [_EntreeAffichable.verrouillee], jamais affichée en clair par erreur.
  Future<List<_EntreeAffichable>> _dechiffrerToutes(List<EntreeJournal> entrees) async {
    final resultat = <_EntreeAffichable>[];
    for (final entree in entrees) {
      if (!entree.chiffre) {
        resultat.add(_EntreeAffichable(entree: entree, verrouillee: false));
        continue;
      }
      if (!ChiffrementNotesService.instance.estDeverrouille) {
        resultat.add(_EntreeAffichable(entree: entree, verrouillee: true));
        continue;
      }
      try {
        final clair = await ChiffrementNotesService.instance.dechiffrer(entree.texte);
        resultat.add(_EntreeAffichable(entree: entree.copierAvec(texte: clair), verrouillee: false));
      } catch (_) {
        // Improbable (mauvaise clé déjà validée par le vérificateur pour
        // déverrouiller la session), mais si le déchiffrement échoue quand
        // même sur une entrée précise, mieux vaut la montrer verrouillée
        // que planter tout l'écran.
        resultat.add(_EntreeAffichable(entree: entree, verrouillee: true));
      }
    }
    return resultat;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book_outlined, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(l10n.dossierDetailJournalTitre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.dossierDetailJournalDescription,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
              ),
              if (!ChiffrementNotesService.instance.estDeverrouille) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final deverrouille = await demanderPhraseSecrete(context);
                    if (deverrouille && mounted) setState(() {});
                  },
                  icon: const Icon(Icons.lock_open_outlined, size: 16),
                  label: Text(l10n.dossierDetailBoutonDeverrouillerNotes),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: TypeEntreeJournal.values.map((type) {
                  final selectionne = _typeSelectionne == type;
                  return ChoiceChip(
                    label: Text(type.libelle(context)),
                    avatar: Icon(type.icone, size: 16, color: selectionne ? Colors.white : type.couleur),
                    selected: selectionne,
                    selectedColor: type.couleur,
                    labelStyle: TextStyle(color: selectionne ? Colors.white : null, fontSize: 12),
                    onSelected: (_) => setState(() => _typeSelectionne = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controleur,
                maxLines: 4,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: l10n.dossierDetailJournalHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _enCours ? null : _ajouter,
                  icon: _enCours
                      ? const SizedBox(
                          height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add),
                  label: Text(l10n.dossierDetailAjouterJournalBouton),
                ),
              ),
              StreamBuilder<List<EntreeJournal>>(
                stream: FirestoreService.instance.journalDossier(widget.dossierId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        l10n.dossierDetailErreurLectureJournal(snapshot.error.toString()),
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final entrees = snapshot.data ?? [];
                  if (entrees.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        l10n.dossierDetailAucuneEntree,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    );
                  }
                  // Le déchiffrement est asynchrone (AES-GCM) — imbriqué dans un
                  // second FutureBuilder plutôt que de bloquer le StreamBuilder
                  // parent, pour que les nouvelles entrées Firestore continuent
                  // d'arriver en direct pendant qu'une entrée se déchiffre.
                  return FutureBuilder<List<_EntreeAffichable>>(
                    future: _dechiffrerToutes(entrees),
                    builder: (context, snapshotAffichables) {
                      if (!snapshotAffichables.hasData) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final affichables = snapshotAffichables.data!;
                      final affichablesFiltres = _filtreType == null
                          ? affichables
                          : affichables.where((a) => a.entree.type == _filtreType).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 10),
                            child: Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(l10n.dossierDetailHistoriqueTitre, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                          ),
                          // Filtre par type : pour ne pas mélanger visuellement tous les
                          // types quand on veut suivre un seul fil (ex : juste les
                          // blocages) — demandé par Tobie le 2026-08-21 ("mélangé,
                          // trop en désordre").
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              FilterChip(
                                label: Text(l10n.propositionsFiltreTout),
                                selected: _filtreType == null,
                                onSelected: (_) => setState(() => _filtreType = null),
                              ),
                              ...TypeEntreeJournal.values.map((t) {
                                final selectionne = _filtreType == t;
                                return FilterChip(
                                  label: Text(t.libelle(context)),
                                  avatar: Icon(t.icone, size: 14, color: selectionne ? Colors.white : t.couleur),
                                  selected: selectionne,
                                  selectedColor: t.couleur,
                                  labelStyle: TextStyle(color: selectionne ? Colors.white : null, fontSize: 12),
                                  onSelected: (_) => setState(() => _filtreType = selectionne ? null : t),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (affichablesFiltres.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                l10n.dossierDetailAucuneEntreeType,
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            )
                          else
                            ..._construireFrise(context, affichablesFiltres),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Groupe les entrées par jour — un en-tête de date une seule fois par
  /// jour, puis juste l'heure pour chaque entrée en dessous, au lieu de
  /// répéter la date sur chaque ligne (clarifié avec Tobie le 2026-08-20 :
  /// "revoir l'architecture et la hiérarchie du journal").
  List<Widget> _construireFrise(BuildContext context, List<_EntreeAffichable> entrees) {
    final widgets = <Widget>[];
    DateTime? dernierJour;
    for (var i = 0; i < entrees.length; i++) {
      final affichable = entrees[i];
      final creeLe = affichable.entree.creeLe;
      final jour = DateTime(creeLe.year, creeLe.month, creeLe.day);
      if (jour != dernierJour) {
        if (dernierJour != null) widgets.add(const SizedBox(height: 4));
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_libelleJour(context, jour), style: Theme.of(context).textTheme.labelLarge),
          ),
        );
        dernierJour = jour;
      }
      final dernierDuJour = i == entrees.length - 1 ||
          DateTime(entrees[i + 1].entree.creeLe.year, entrees[i + 1].entree.creeLe.month, entrees[i + 1].entree.creeLe.day) != jour;
      widgets.add(_ligneEntree(context, affichable, dernierDuJour));
    }
    return widgets;
  }

  String _libelleJour(BuildContext context, DateTime jour) {
    final l10n = AppLocalizations.of(context)!;
    final aujourdHui = DateTime.now();
    final aujourdHuiSansHeure = DateTime(aujourdHui.year, aujourdHui.month, aujourdHui.day);
    if (jour == aujourdHuiSansHeure) return l10n.aTraiterAujourdhui;
    if (jour == aujourdHuiSansHeure.subtract(const Duration(days: 1))) return l10n.dossierDetailHier;
    return formaterDateFr(jour);
  }

  Widget _ligneEntree(BuildContext context, _EntreeAffichable affichable, bool dernierDuJour) {
    final entree = affichable.entree;
    final l10n = AppLocalizations.of(context)!;
    // Modifier/supprimer réservé à l'auteur ou créateur/administrateur
    // (décision de Tobie le 2026-08-30, voir estAuteurOuGestionnaire côté
    // firestore.rules — même règle reproduite ici pour ne pas afficher des
    // boutons qui échoueraient côté serveur).
    final peutGererCetteEntree =
        entree.auteurUid == widget.monUid || widget.monRole == 'createur' || widget.monRole == 'administrateur';
    final estFrancais = Localizations.localeOf(context).languageCode != 'en';
    final heure = estFrancais
        ? '${entree.creeLe.hour.toString().padLeft(2, '0')}h${entree.creeLe.minute.toString().padLeft(2, '0')}'
        : '${entree.creeLe.hour.toString().padLeft(2, '0')}:${entree.creeLe.minute.toString().padLeft(2, '0')}';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(shape: BoxShape.circle, color: entree.type.couleur),
              ),
              if (!dernierDuJour)
                Expanded(
                  // Colorée comme l'entrée qu'elle prolonge, plutôt qu'un gris neutre
                  // uniforme — pour que chaque type reste lisible d'un coup d'œil
                  // dans la frise (Tobie, 2026-08-21 : "mélangé, trop en désordre").
                  child: Container(width: 2, color: entree.type.couleur.withValues(alpha: 0.35)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(entree.type.icone, size: 14, color: entree.type.couleur),
                      const SizedBox(width: 4),
                      Text(
                        entree.type.libelle(context),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: entree.type.couleur),
                      ),
                      if (affichable.verrouillee) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                      ],
                      const Spacer(),
                      Text(heure, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      if (entree.modifieLe != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(l10n.dossierDetailModifieSuffixe, style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                        ),
                      if (peutGererCetteEntree) ...[
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            onPressed: affichable.verrouillee ? null : () => _editer(context, entree),
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.delete_outline, size: 16),
                            onPressed: () => _supprimer(context, entree),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (affichable.verrouillee)
                    Text(
                      l10n.dossierDetailEntreeVerrouillee,
                      style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
                    )
                  else
                    Text(entree.texte),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
