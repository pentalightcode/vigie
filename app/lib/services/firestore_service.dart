import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dossier.dart';
import '../models/entree_journal.dart';
import '../models/notification_envoyee.dart';
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
  Filter get _filtreParticipant => Filter.or(
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

  /// Modifie les informations d'un dossier (nom de code, date de l'événement)
  /// et recalcule automatiquement le rappel de toutes ses tâches liées
  /// (correction du point I).
  Future<void> modifierDossier(String dossierId, {required String nomCode, DateTime? dateEvenement}) async {
    await _db.collection('dossiers').doc(dossierId).update({
      'nomCode': nomCode,
      'dateEvenement': dateEvenement != null ? Timestamp.fromDate(dateEvenement) : null,
    });

    if (dateEvenement == null) return;

    final delai = await UtilisateurService.instance.delaiRappelJours();
    final taches = await _db
        .collection('taches')
        .where(_filtreParticipant)
        .where('dossierId', isEqualTo: dossierId)
        .get();

    final batch = _db.batch();
    for (final doc in taches.docs) {
      batch.update(doc.reference, {
        'nomCodeDossier': nomCode,
        'dateDeclenchante': Timestamp.fromDate(dateEvenement),
        'datePremierRappel': Timestamp.fromDate(
          Tache.calculerDatePremierRappel(dateEvenement, delai),
        ),
      });
    }
    await batch.commit();
  }

  /// Supprime un dossier et toutes ses tâches ET entrées de journal liées.
  /// Le journal était oublié jusqu'ici (trouvé en Red Team le 2026-08-30,
  /// voir Notes/2026-08-30-redteam-code-collaboration.md, point 5) : des
  /// notes potentiellement confidentielles restaient orphelines dans
  /// Firestore pour toujours après la "suppression" de leur dossier.
  Future<void> supprimerDossier(String dossierId) async {
    final taches = await _db
        .collection('taches')
        .where(_filtreParticipant)
        .where('dossierId', isEqualTo: dossierId)
        .get();
    final entreesJournal = await _db
        .collection('journalDossier')
        .where(_filtreParticipant)
        .where('dossierId', isEqualTo: dossierId)
        .get();

    final batch = _db.batch();
    for (final doc in taches.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in entreesJournal.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('dossiers').doc(dossierId));
    await batch.commit();
  }

  Stream<Dossier> dossier(String dossierId) {
    return _db.collection('dossiers').doc(dossierId).snapshots().map(Dossier.depuisDocument);
  }

  Stream<List<Tache>> tachesDuDossier(String dossierId) {
    return _db
        .collection('taches')
        .where(_filtreParticipant)
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
        .where(_filtreParticipant)
        .where('statut', isEqualTo: StatutTache.aFaire.name)
        .snapshots()
        .map((snap) => snap.docs.map(Tache.depuisDocument).toList());
  }

  /// Toutes les tâches (faites ou non, y compris les dossiers partagés), pour le bilan.
  Stream<List<Tache>> toutesLesTaches() {
    return _db
        .collection('taches')
        .where(_filtreParticipant)
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
    // Le filtre sur "participant" (voir _filtreParticipant) est nécessaire
    // même si les règles Firestore le vérifient déjà par document : pour une
    // requête de LISTE (pas juste un document), Firestore exige que la
    // requête elle-même prouve qu'elle ne peut renvoyer que des documents
    // autorisés — sans ce filtre, la requête est refusée en bloc
    // (PERMISSION_DENIED), trouvé le 2026-08-20 avec le vrai message
    // d'erreur montré par Tobie.
    return _db
        .collection('journalDossier')
        .where(_filtreParticipant)
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
}
