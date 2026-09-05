import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profession.dart';
import '../models/reglages_utilisateur.dart';
import '../models/tache.dart';
import 'firestore_service.dart';
import 'nature_dossier_service.dart';

/// Réglages propres à chaque utilisateur (délai de rappel, pseudo, profession...).
/// Nécessaire dès maintenant que l'app est pensée pour plusieurs
/// utilisateurs (pas seulement le père) — chacun doit pouvoir régler ses
/// propres préférences plutôt que d'avoir des valeurs fixes dans le code.
class UtilisateurService {
  UtilisateurService._();
  static final UtilisateurService instance = UtilisateurService._();

  static const delaiRappelParDefaut = 14;

  final _db = FirebaseFirestore.instance;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Aucun utilisateur connecté.');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _document =>
      _db.collection('utilisateurs').doc(_uid);

  /// À appeler juste après la connexion : crée le document de réglages
  /// s'il n'existe pas encore (première connexion).
  Future<void> assurerDocumentExiste() async {
    final doc = await _document.get();
    if (!doc.exists) {
      await _document.set({
        'onboardingTermine': false,
        'delaiRappelJours': delaiRappelParDefaut,
        'creeLe': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<ReglagesUtilisateur> reglages() {
    return _document.snapshots().map(ReglagesUtilisateur.depuisDocument);
  }

  Future<int> delaiRappelJours() async {
    final doc = await _document.get();
    return (doc.data()?['delaiRappelJours'] as int?) ?? delaiRappelParDefaut;
  }

  /// Change le délai de rappel ET recalcule aussitôt la date de premier
  /// rappel de TOUTES les tâches en cours avec la nouvelle valeur, sans
  /// exception. Sans ce recalcul, changer ce réglage n'affecterait que les
  /// futurs dossiers : les anciens garderaient pour toujours le délai qui
  /// était actif au moment de leur création, mélangeant par exemple des
  /// tâches à 7 jours et à 14 jours sans aucun moyen de les distinguer
  /// (bug remonté par Tobie le 22/08/2026). Changer ce réglage doit rester
  /// sans risque, aussi souvent que voulu.
  Future<void> definirDelaiRappelJours(int jours) async {
    await _document.set({'delaiRappelJours': jours}, SetOptions(merge: true));

    // filtreParticipant (pas juste `uid == moi`, trouvé en re-vérifiant ce
    // correctif, via /code-review, le 2026-08-31) : sinon, les tâches des
    // dossiers partagés dont on n'est pas propriétaire ne se recalculaient
    // jamais, malgré la promesse du commentaire ci-dessus ("sans exception").
    final taches = await _db
        .collection('taches')
        .where(FirestoreService.instance.filtreParticipant)
        .where('statut', isEqualTo: StatutTache.aFaire.name)
        .get();

    var batch = _db.batch();
    var enAttente = 0;
    for (final doc in taches.docs) {
      final tache = Tache.depuisDocument(doc);
      batch.update(doc.reference, {
        'datePremierRappel': Timestamp.fromDate(
          Tache.calculerDatePremierRappel(tache.dateDeclenchante, jours),
        ),
      });
      enAttente++;
      if (enAttente >= 400) {
        await batch.commit();
        batch = _db.batch();
        enAttente = 0;
      }
    }
    if (enAttente > 0) await batch.commit();
  }

  Future<void> definirPseudo(String pseudo) {
    return _document.set({'pseudo': pseudo}, SetOptions(merge: true));
  }

  Future<void> definirBilanIaActif(bool actif) {
    return _document.set({'bilanIaActif': actif}, SetOptions(merge: true));
  }

  /// Change la profession après coup (depuis le Profil). Ne re-remplit pas
  /// les types de dossier automatiquement (l'utilisateur a pu les personnaliser
  /// depuis) — seulement le libellé affiché.
  Future<void> definirProfession(Profession profession, {String? professionPersonnalisee}) {
    return _document.set({
      'profession': profession.name,
      'professionPersonnalisee': profession == Profession.autre ? professionPersonnalisee : null,
    }, SetOptions(merge: true));
  }

  /// Termine l'accueil : enregistre les infos de base et pré-remplit les
  /// types de dossier selon la profession choisie.
  Future<void> terminerOnboarding({
    required String nom,
    required String pseudo,
    required Profession profession,
    String? professionPersonnalisee,
    required int delaiRappelJours,
  }) async {
    await _document.set({
      'onboardingTermine': true,
      'nom': nom,
      'pseudo': pseudo,
      'profession': profession.name,
      'professionPersonnalisee': profession == Profession.autre ? professionPersonnalisee : null,
      'delaiRappelJours': delaiRappelJours,
    }, SetOptions(merge: true));
    await NatureDossierService.instance.initialiserPourProfession(profession);
  }

  /// Supprime définitivement le compte : révoque chaque connexion Google
  /// auprès de Google, efface TOUTES les données (dossiers, tâches, notes
  /// de dossier, natures, réglages, historique de notifications,
  /// propositions, connexions Google...), puis le compte de connexion
  /// lui-même. Irréversible — protégé par triple confirmation côté écran
  /// Profil.
  ///
  /// Fait côté serveur (fonction `supprimer_compte_definitivement`) depuis
  /// l'audit de sécurité du 2026-08-29 : la version précédente, entièrement
  /// côté téléphone, oubliait plusieurs sous-collections (dont la connexion
  /// Google — jamais révoquée auprès de Google, ni même supprimée) — seul
  /// le serveur a la clé de déchiffrement nécessaire pour révoquer
  /// proprement, et peut découvrir toutes les sous-collections
  /// automatiquement sans les lister à la main.
  Future<void> supprimerCompteEtDonnees() async {
    await FirebaseFunctions.instance.httpsCallable('supprimer_compte_definitivement').call();
    await FirebaseAuth.instance.signOut();
  }
}
