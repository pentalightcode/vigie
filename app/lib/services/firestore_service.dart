import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dossier.dart';
import '../models/entree_journal.dart';
import '../models/notification_envoyee.dart';
import '../models/proposition_en_attente.dart';
import '../models/tache.dart';
import 'utilisateur_service.dart';

/// Accès aux données (Dossiers/Tâches) — toujours filtré sur l'utilisateur
/// connecté, en cohérence avec les règles de sécurité Firestore.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Aucun utilisateur connecté.');
    return uid;
  }

  /// Filtre "j'ai accès à ce document" pour les requêtes de LISTE sur
  /// taches/journalDossier — équivalent de `estParticipant()` côté
  /// `firestore.rules`, mais exprimé comme une requête (Firestore exige que
  /// la requête elle-même prouve qu'elle ne peut renvoyer que des documents
  /// autorisés, voir le commentaire historique sur journalDossier() plus
  /// bas). Combine (OR, dédupliqué nativement par Firestore) l'ancien
  /// critère `uid == moi` (documents créés avant la refonte collaboration
  /// du 2026-08-29, qui n'ont pas encore `participantsUids`) et le nouveau
  /// `participantsUids array-contains moi` — choisi plutôt qu'une migration
  /// qui aurait dû réécrire tous les documents existants : aucune écriture
  /// requise, aucun risque de migration ratée, marche à l'identique pour
  /// les anciens ET les nouveaux documents.
  ///
  /// Rendu public (trouvé en re-vérifiant ce correctif, via /code-review, le
  /// 2026-08-31) : `UtilisateurService.definirDelaiRappelJours` avait besoin
  /// exactement du même filtre et le dupliquait en `uid ==` seul, oubliant
  /// les tâches des dossiers partagés dont l'utilisateur n'est pas
  /// propriétaire — mieux vaut le réutiliser d'ici que le tripler.
  Filter get filtreParticipant => Filter.or(
        Filter('uid', isEqualTo: _uid),
        Filter('participantsUids', arrayContains: _uid),
      );

  void _ajouterDossierEtTacheAuBatch(
    WriteBatch batch, {
    required String nomCode,
    DateTime? dateEvenement,
    required int delaiRappelJours,
    required String nature,
    String? descriptionTache,
    String? notesDetaillees,
  }) {
    final dossierRef = _db.collection('dossiers').doc();
    final dossier = Dossier(id: dossierRef.id, uid: _uid, nomCode: nomCode, dateEvenement: dateEvenement);

    final dateDeclenchante = dateEvenement ?? DateTime.now();
    final tache = Tache(
      id: '',
      uid: _uid,
      dossierId: dossierRef.id,
      nomCodeDossier: nomCode,
      descriptionCourte: descriptionTache ?? nature,
      nature: nature,
      dateDeclenchante: dateDeclenchante,
      datePremierRappel: Tache.calculerDatePremierRappel(dateDeclenchante, delaiRappelJours),
      statut: StatutTache.aFaire,
      notesDetaillees: notesDetaillees,
    );

    batch.set(dossierRef, dossier.versDocument());
    batch.set(_db.collection('taches').doc(), tache.versDocument());
  }

  /// Crée un dossier et sa première tâche par défaut en une seule fois
  /// (correction du point P : l'ajout ne doit pas laisser un dossier "vide").
  Future<void> creerDossierAvecTache({
    required String nomCode,
    DateTime? dateEvenement,
    required String nature,
    String? descriptionTache,
    String? notesDetaillees,
  }) async {
    final delai = await UtilisateurService.instance.delaiRappelJours();
    final batch = _db.batch();
    _ajouterDossierEtTacheAuBatch(
      batch,
      nomCode: nomCode,
      dateEvenement: dateEvenement,
      delaiRappelJours: delai,
      nature: nature,
      descriptionTache: descriptionTache,
      notesDetaillees: notesDetaillees,
    );
    await batch.commit();
  }

  /// Ajout groupé (correction des points C/P) : plusieurs dossiers d'un coup,
  /// chacun avec sa tâche par défaut — pour saisir le "rôle" hebdomadaire
  /// sans avoir à répéter l'opération dossier par dossier.
  Future<void> creerPlusieursDossiers(
    List<({String nomCode, DateTime? dateAudience})> entrees, {
    required String nature,
  }) async {
    final delai = await UtilisateurService.instance.delaiRappelJours();
    final batch = _db.batch();
    for (final entree in entrees) {
      _ajouterDossierEtTacheAuBatch(
        batch,
        nomCode: entree.nomCode,
        dateEvenement: entree.dateAudience,
        delaiRappelJours: delai,
        nature: nature,
      );
    }
    await batch.commit();
  }

  /// Ajoute une tâche supplémentaire à un dossier déjà existant (un dossier
  /// peut avoir plusieurs écritures/diligences liées à la même affaire).
  /// [proprietaireUid]/[participantsUids] viennent du dossier parent
  /// (`dossier.uid`/`dossier.participantsUids`) — l'auteur réel de cette
  /// tâche reste celui qui l'ajoute (voir `Tache.auteurUid`), même si elle
  /// appartient au dossier d'un autre participant.
  Future<void> ajouterTacheADossier({
    required String dossierId,
    required String nomCodeDossier,
    required String descriptionCourte,
    required String nature,
    required DateTime dateDeclenchante,
    String? notesDetaillees,
    String? proprietaireUid,
    List<String>? participantsUids,
    bool proposerSeulement = false,
  }) async {
    final delai = await UtilisateurService.instance.delaiRappelJours();
    final tache = Tache(
      id: '',
      uid: proprietaireUid ?? _uid,
      dossierId: dossierId,
      nomCodeDossier: nomCodeDossier,
      descriptionCourte: descriptionCourte,
      nature: nature,
      dateDeclenchante: dateDeclenchante,
      datePremierRappel: Tache.calculerDatePremierRappel(dateDeclenchante, delai),
      statut: StatutTache.aFaire,
      notesDetaillees: notesDetaillees,
      participantsUids: participantsUids ?? [proprietaireUid ?? _uid],
      auteurUid: _uid,
      propositionEnAttente: proposerSeulement ? PropositionEnAttente(type: 'creer', proposePar: _uid) : null,
    );
    await _db.collection('taches').add(tache.versDocument());
  }

  Future<void> modifierTache(Tache tache) async {
    final delai = await UtilisateurService.instance.delaiRappelJours();
    final miseAJour = {
      'descriptionCourte': tache.descriptionCourte,
      'nature': tache.nature,
      'dateDeclenchante': Timestamp.fromDate(tache.dateDeclenchante),
      'datePremierRappel': Timestamp.fromDate(
        Tache.calculerDatePremierRappel(tache.dateDeclenchante, delai),
      ),
      'notesDetaillees': tache.notesDetaillees,
    };
    await _db.collection('taches').doc(tache.id).update(miseAJour);
  }

  Future<void> supprimerTache(String tacheId) {
    return _db.collection('taches').doc(tacheId).delete();
  }

  // --- Workflow d'approbation (Phase 2, 2026-08-31) -----------------------
  // Deux chemins, voir firestore.rules : l'auteur ou créateur/administrateur
  // (avec 'modererContenu') écrit directement — modifierTache/marquerFait/
  // marquerNonFait/supprimerTache ci-dessus, inchangées. Tout autre
  // participant pose une proposition à la place (méthodes ci-dessous),
  // approuvée/rejetée ensuite par le créateur/l'auteur (approuverProposition*/
  // retirerProposition*, cette dernière servant aussi bien à rejeter la
  // proposition d'un autre qu'à retirer la sienne — les règles Firestore
  // distinguent déjà qui a le droit de le faire, la méthode est la même
  // écriture des deux côtés).

  Future<void> proposerModificationTache(Tache tache) {
    return _db.collection('taches').doc(tache.id).update({
      'propositionEnAttente': PropositionEnAttente(
        type: 'modifier',
        proposePar: _uid,
        donnees: {
          'descriptionCourte': tache.descriptionCourte,
          'nature': tache.nature,
          'dateDeclenchante': Timestamp.fromDate(tache.dateDeclenchante),
          'notesDetaillees': tache.notesDetaillees,
        },
      ).versMap(),
    });
  }

  Future<void> proposerMarquerFaitTache(String tacheId) {
    return _db.collection('taches').doc(tacheId).update({
      'propositionEnAttente': PropositionEnAttente(type: 'marquerFait', proposePar: _uid).versMap(),
    });
  }

  Future<void> proposerMarquerNonFaitTache(String tacheId) {
    return _db.collection('taches').doc(tacheId).update({
      'propositionEnAttente': PropositionEnAttente(type: 'marquerNonFait', proposePar: _uid).versMap(),
    });
  }

  Future<void> proposerSuppressionTache(String tacheId) {
    return _db.collection('taches').doc(tacheId).update({
      'propositionEnAttente': PropositionEnAttente(type: 'supprimer', proposePar: _uid).versMap(),
    });
  }

  Future<void> retirerPropositionTache(Tache tache) {
    if (tache.propositionEnAttente?.type == 'creer') {
      return _db.collection('taches').doc(tache.id).delete();
    }
    return _db.collection('taches').doc(tache.id).update({'propositionEnAttente': null});
  }

  /// Applique la proposition en attente d'une tâche : les vraies valeurs
  /// pour 'modifier' (recalcule datePremierRappel comme `modifierTache`,
  /// mais à partir des valeurs PROPOSÉES) ou le statut pour 'marquerFait'/
  /// 'marquerNonFait', et efface la proposition — en une seule écriture, sauf
  /// pour 'supprimer' où la tâche est directement supprimée (la proposition
  /// disparaît avec elle, rien à effacer séparément).
  Future<void> approuverPropositionTache(Tache tache) async {
    final proposition = tache.propositionEnAttente;
    if (proposition == null) return;
    final ref = _db.collection('taches').doc(tache.id);
    switch (proposition.type) {
      case 'creer':
        await ref.update({'propositionEnAttente': null});
        return;
      case 'supprimer':
        await ref.delete();
        return;
      case 'marquerFait':
        await ref.update({
          'statut': StatutTache.fait.name,
          'dateFait': Timestamp.now(),
          'propositionEnAttente': null,
        });
        return;
      case 'marquerNonFait':
        await ref.update({
          'statut': StatutTache.aFaire.name,
          'dateFait': null,
          'propositionEnAttente': null,
        });
        return;
      default: // 'modifier'
        final delai = await UtilisateurService.instance.delaiRappelJours();
        final donnees = proposition.donnees;
        final dateDeclenchante = (donnees['dateDeclenchante'] as Timestamp).toDate();
        await ref.update({
          'descriptionCourte': donnees['descriptionCourte'],
          'nature': donnees['nature'],
          'dateDeclenchante': donnees['dateDeclenchante'],
          'datePremierRappel': Timestamp.fromDate(
            Tache.calculerDatePremierRappel(dateDeclenchante, delai),
          ),
          'notesDetaillees': donnees['notesDetaillees'],
          'propositionEnAttente': null,
        });
    }
  }

  /// Modifie les informations d'un dossier (nom de code, date de l'événement)
  /// et recalcule automatiquement le rappel de toutes ses tâches liées
  /// (correction du point I).
  Future<void> modifierDossier(String dossierId, {required String nomCode, DateTime? dateEvenement}) async {
    await _db.collection('dossiers').doc(dossierId).update({
      'nomCode': nomCode,
      'dateEvenement': dateEvenement != null ? Timestamp.fromDate(dateEvenement) : null,
    });

    final delai = await UtilisateurService.instance.delaiRappelJours();
    final taches = await _db
        .collection('taches')
        .where(filtreParticipant)
        .where('dossierId', isEqualTo: dossierId)
        .get();

    final batch = _db.batch();
    for (final doc in taches.docs) {
      final misesAJour = <String, dynamic>{
        'nomCodeDossier': nomCode,
      };
      if (dateEvenement != null) {
        misesAJour['dateDeclenchante'] = Timestamp.fromDate(dateEvenement);
        misesAJour['datePremierRappel'] = Timestamp.fromDate(
          Tache.calculerDatePremierRappel(dateEvenement, delai),
        );
      }
      batch.update(doc.reference, misesAJour);
    }
    await batch.commit();
  }

  /// Supprimer un dossier via une Cloud Function pour contourner les
  /// règles Firestore de suppression (une suppression par lot client
  /// échouerait si l'admin n'a pas la permission `modererContenu` sur les tâches/journal des autres).
  Future<void> supprimerDossier(String dossierId) async {
    final callable = FirebaseFunctions.instance.httpsCallable('supprimer_dossier_partage');
    await callable.call({'dossierId': dossierId});
  }

  Stream<Dossier> dossier(String dossierId) {
    return _db.collection('dossiers').doc(dossierId).snapshots().map(Dossier.depuisDocument);
  }

  /// Lecture ponctuelle, forcée depuis le SERVEUR (pas le cache local) —
  /// pour les cas où la fraîcheur compte vraiment (trouvé en re-vérifiant ce
  /// correctif, via /code-review, le 2026-08-31) : `dossier(id).first` sur
  /// le flux ci-dessus peut se résoudre depuis le cache local si une version
  /// y est déjà présente, AVANT tout aller-retour serveur — exactement le
  /// contraire de ce que cherche `_ajouterTache` en relisant le dossier pour
  /// satisfaire la correspondance EXACTE exigée par `tacheCoherente()` côté
  /// firestore.rules.
  Future<Dossier> dossierDepuisServeur(String dossierId) async {
    final doc = await _db.collection('dossiers').doc(dossierId).get(const GetOptions(source: Source.server));
    return Dossier.depuisDocument(doc);
  }

  Stream<List<Tache>> tachesDuDossier(String dossierId) {
    return _db
        .collection('taches')
        .where(filtreParticipant)
        .where('dossierId', isEqualTo: dossierId)
        .snapshots()
        .map((snap) => snap.docs.map(Tache.depuisDocument).toList());
  }

  /// Toutes les tâches non terminées de l'utilisateur (les siennes + celles
  /// des dossiers partagés dont il est participant), pour l'écran "À traiter"
  /// (le filtrage "actif"/"en retard" se fait ensuite côté modèle).
  Stream<List<Tache>> tachesNonTerminees() {
    return _db
        .collection('taches')
        .where(filtreParticipant)
        .where('statut', isEqualTo: StatutTache.aFaire.name)
        .snapshots()
        .map((snap) => snap.docs.map(Tache.depuisDocument).toList());
  }

  /// Toutes les tâches (faites ou non, y compris les dossiers partagés), pour le bilan.
  Stream<List<Tache>> toutesLesTaches() {
    return _db
        .collection('taches')
        .where(filtreParticipant)
        .snapshots()
        .map((snap) => snap.docs.map(Tache.depuisDocument).toList());
  }

  /// Historique des rappels déjà envoyés par le digest quotidien (matin/soir),
  /// du plus récent au plus ancien — pour l'écran "Notifications".
  Stream<List<NotificationEnvoyee>> notifications() {
    return _db
        .collection('utilisateurs')
        .doc(_uid)
        .collection('notifications')
        .orderBy('envoyeLe', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(NotificationEnvoyee.depuisDocument).toList());
  }

  Future<void> marquerFait(String tacheId) {
    return _db.collection('taches').doc(tacheId).update({
      'statut': StatutTache.fait.name,
      'dateFait': Timestamp.now(),
    });
  }

  /// Permet de revenir en arrière après un "C'est fait" cliqué par erreur.
  Future<void> marquerNonFait(String tacheId) {
    return _db.collection('taches').doc(tacheId).update({
      'statut': StatutTache.aFaire.name,
      'dateFait': null,
    });
  }

  /// Journal de bord d'un dossier — entrées datées ajoutées au fil du temps
  /// pour documenter l'avancement, jamais écrasées (demandé par Tobie le
  /// 2026-08-20, distinct des notes par tâche qui décrivent un état ponctuel).
  Stream<List<EntreeJournal>> journalDossier(String dossierId) {
    // Le filtre sur "participant" (voir filtreParticipant) est nécessaire
    // même si les règles Firestore le vérifient déjà par document : pour une
    // requête de LISTE (pas juste un document), Firestore exige que la
    // requête elle-même prouve qu'elle ne peut renvoyer que des documents
    // autorisés — sans ce filtre, la requête est refusée en bloc
    // (PERMISSION_DENIED), trouvé le 2026-08-20 avec le vrai message
    // d'erreur montré par Tobie.
    return _db
        .collection('journalDossier')
        .where(filtreParticipant)
        .where('dossierId', isEqualTo: dossierId)
        .orderBy('creeLe', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(EntreeJournal.depuisDocument).toList());
  }

  /// [chiffre] doit refléter si [texte] est déjà chiffré (voir
  /// ChiffrementNotesService) — ce champ ne change jamais après coup,
  /// même en cas de modification ultérieure de l'entrée.
  /// [participantsUids] vient du dossier parent (`dossier.participantsUids`)
  /// — permet à chaque participant de retrouver cette entrée par une
  /// requête directe, sans dépendre d'une lecture du dossier à chaque fois.
  Future<void> ajouterEntreeJournal(
    String dossierId,
    String texte,
    TypeEntreeJournal type, {
    required bool chiffre,
    List<String>? participantsUids,
    bool proposerSeulement = false,
  }) {
    return _db.collection('journalDossier').add({
      'uid': _uid,
      'dossierId': dossierId,
      'texte': texte,
      'type': type.name,
      'creeLe': Timestamp.now(),
      'chiffre': chiffre,
      'participantsUids': participantsUids ?? [_uid],
      'auteurUid': _uid,
      if (proposerSeulement) 'propositionEnAttente': PropositionEnAttente(type: 'creer', proposePar: _uid).versMap(),
    });
  }

  Future<void> supprimerEntreeJournal(String entreeId) {
    return _db.collection('journalDossier').doc(entreeId).delete();
  }

  /// Modification libre d'une entrée déjà écrite (choix explicite de Tobie le
  /// 2026-08-21, malgré le principe initial "jamais écrasé") — seuls le texte
  /// et le type changent, la date de création réelle reste intacte.
  Future<void> modifierEntreeJournal(String entreeId, String texte, TypeEntreeJournal type) {
    return _db.collection('journalDossier').doc(entreeId).update({
      'texte': texte,
      'type': type.name,
      'modifieLe': Timestamp.now(),
    });
  }

  // --- Workflow d'approbation, journal (Phase 2, 2026-08-31) ---------------
  // Même principe que /taches ci-dessus (voir ces commentaires).

  Future<void> proposerModificationEntreeJournal(EntreeJournal entree) {
    return _db.collection('journalDossier').doc(entree.id).update({
      'propositionEnAttente': PropositionEnAttente(
        type: 'modifier',
        proposePar: _uid,
        donnees: {'texte': entree.texte, 'type': entree.type.name},
      ).versMap(),
    });
  }

  Future<void> proposerSuppressionEntreeJournal(String entreeId) {
    return _db.collection('journalDossier').doc(entreeId).update({
      'propositionEnAttente': PropositionEnAttente(type: 'supprimer', proposePar: _uid).versMap(),
    });
  }

  Future<void> retirerPropositionEntreeJournal(EntreeJournal entree) {
    if (entree.propositionEnAttente?.type == 'creer') {
      return _db.collection('journalDossier').doc(entree.id).delete();
    }
    return _db.collection('journalDossier').doc(entree.id).update({'propositionEnAttente': null});
  }

  Future<void> approuverPropositionEntreeJournal(EntreeJournal entree) async {
    final proposition = entree.propositionEnAttente;
    if (proposition == null) return;
    final ref = _db.collection('journalDossier').doc(entree.id);
    if (proposition.type == 'creer') {
      await ref.update({'propositionEnAttente': null});
      return;
    }
    if (proposition.type == 'supprimer') {
      await ref.delete();
      return;
    }
    final donnees = proposition.donnees;
    await ref.update({
      'texte': donnees['texte'],
      'type': donnees['type'],
      'modifieLe': Timestamp.now(),
      'propositionEnAttente': null,
    });
  }
}
