import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/connexion_google.dart';
import '../models/etat_sync.dart';
import '../models/evenement_calendrier.dart';
import '../models/proposition_dossier.dart';

/// Connexion de comptes Google (autant qu'on veut, aucun rôle prédéfini —
/// revu le 2026-08-21) pour l'automatisation des dossiers — lecture seule,
/// jamais toute la boîte pour Gmail (seulement les expéditeurs déclarés de
/// confiance, voir Notes/2026-08-12).
///
/// Le jeton d'accès Google ne transite JAMAIS en clair côté client au-delà
/// du "code" à usage unique : on demande un code d'autorisation serveur
/// (serverAuthCode), qu'on envoie directement à la fonction serveur — c'est
/// elle seule qui l'échange contre un jeton, le chiffre, et le stocke.
/// Décision de sécurité actée le 2026-08-07.
class GmailService {
  GmailService._();
  static final GmailService instance = GmailService._();

  // ID client "Application Web" (auto-créé par Firebase) — sert de
  // serverClientId pour obtenir un code d'autorisation utilisable côté serveur.
  static const _webClientId =
      '740523786640-pks5j67kshcu9rshgvsvjert7udoe206.apps.googleusercontent.com';
  static const _scopeGmailLectureSeule = 'https://www.googleapis.com/auth/gmail.readonly';
  // Ajouté le 2026-08-18 (demande de Tobie) : mêmes tâches Google que celles
  // qu'il utilise déjà au quotidien, importées automatiquement comme
  // Propositions — données déjà structurées (titre + date), donc un bien
  // meilleur test de bout en bout que les emails. Un seul clic, une seule
  // autorisation, comme pour Gmail.
  static const _scopeTachesLectureSeule = 'https://www.googleapis.com/auth/tasks.readonly';
  // Ajouté le 2026-08-18 (demande de Tobie, juste après Tasks) : même
  // principe, les événements de calendrier sont déjà structurés (titre +
  // date), aucune extraction à faire.
  static const _scopeCalendrierLectureSeule = 'https://www.googleapis.com/auth/calendar.readonly';
  static const _scopeContactsLectureSeule = 'https://www.googleapis.com/auth/contacts.readonly';

  final _db = FirebaseFirestore.instance;
  bool _initialise = false;

  Future<void> _assurerInitialise() async {
    if (_initialise) return;
    // Sur le Web, l'initialisation a aussi besoin de clientId (pas seulement
    // serverClientId) pour pouvoir afficher l'écran de connexion Google —
    // sur mobile, ça vient automatiquement du fichier de config Firebase.
    await GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? _webClientId : null,
      serverClientId: _webClientId,
    );
    _initialise = true;
  }

  /// Lance la connexion d'UN nouveau compte Google : mêmes 4 scopes en
  /// lecture seule à chaque fois (Gmail, Tasks, Calendar, Contacts), aucun "rôle" à
  /// choisir — appelable plusieurs fois pour connecter plusieurs comptes.
  /// Envoie le code obtenu à la fonction serveur qui finalise la connexion.
  /// Retourne l'adresse email connectée.
  Future<String> connecter() async {
    await _assurerInitialise();

    final compte = await GoogleSignIn.instance.authenticate();
    final autorisation = await compte.authorizationClient.authorizeServer(
      [_scopeGmailLectureSeule, _scopeTachesLectureSeule, _scopeCalendrierLectureSeule, _scopeContactsLectureSeule],
    );
    final code = autorisation?.serverAuthCode;
    if (code == null) {
      throw StateError('Autorisation refusée ou indisponible sur cet appareil.');
    }

    final resultat = await FirebaseFunctions.instance.httpsCallable('connecter_gmail').call({
      'code': code,
      // Adresse déjà connue côté téléphone (authentification Google de
      // base) — évite au serveur de devoir la redemander à Google avec un
      // jeton dont le scope est volontairement limité (bug trouvé par
      // Tobie le 2026-08-21 : l'adresse restait vide tant qu'on ne
      // renommait pas soi-même la connexion).
      'email': compte.email,
    });
    return resultat.data['emailConnecte'] as String;
  }

  /// Supprime la connexion demandée : efface le jeton côté serveur. Ne
  /// touche à aucun dossier/tâche déjà créé, ni aux autres connexions.
  Future<void> deconnecter(String connexionId) async {
    await FirebaseFunctions.instance.httpsCallable('deconnecter_gmail').call({'connexionId': connexionId});
  }

  /// Renomme un compte connecté — purement pour l'affichage, l'utilisateur
  /// choisit librement le libellé (ex : "Boîte confidentielle", "Mon vrai
  /// compte") ; écriture directe autorisée côté règles Firestore, limitée
  /// à ce seul champ (voir firestore.rules).
  Future<void> renommerConnexion(String connexionId, String libelle) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db
        .collection('utilisateurs')
        .doc(uid)
        .collection('connexionsGoogle')
        .doc(connexionId)
        .update({'libelle': libelle});
  }

  /// Vérifie que le domaine de l'adresse a bien des serveurs mail
  /// configurés — attrape les fautes de frappe de domaine. Ne garantit pas
  /// qu'une boîte précise existe (voir explication côté serveur).
  Future<bool> domaineValide(String email) async {
    final resultat = await FirebaseFunctions.instance.httpsCallable('verifier_domaine_email').call({
      'email': email,
    });
    return resultat.data['valide'] as bool? ?? true;
  }

  /// Événements du calendrier Google principal sur une période — pour
  /// l'écran Agenda (vue en direct, lecture seule).
  ///
  /// Nouvelle tentative automatique (jusqu'à 3 essais) sur les erreurs de
  /// type réseau/serveur temporairement indisponible (`unavailable`,
  /// `deadline-exceeded`) — trouvé le 2026-08-23 sur le téléphone d'un
  /// utilisateur (Tecno/HiOS) : la requête n'atteignait jamais le serveur
  /// (vérifié côté serveur, aucune trace), cohérent avec une coupure réseau
  /// passagère due aux restrictions d'arrière-plan propres à cette marque.
  /// Sans solution côté réglages du téléphone (aucun réglage à demander à
  /// personne — décision de Tobie), on absorbe ici ce qu'on peut : une
  /// erreur transitoire ne doit pas se voir si une deuxième tentative
  /// quelques secondes après suffit. Les autres erreurs (droits, données
  /// invalides...) ne sont jamais retentées, ça ne changerait rien.
  Future<List<EvenementCalendrier>> evenementsCalendrier(DateTime debut, DateTime fin) async {
    const delaisRetentative = [Duration(seconds: 1), Duration(seconds: 3)];
    for (var tentative = 0; ; tentative++) {
      try {
        final resultat = await FirebaseFunctions.instance.httpsCallable('lister_evenements_calendrier').call({
          'debut': debut.toIso8601String(),
          'fin': fin.toIso8601String(),
        });
        final liste = resultat.data['evenements'] as List<dynamic>;
        return liste.map((e) => EvenementCalendrier.depuisJson(Map<String, dynamic>.from(e as Map))).toList();
      } on FirebaseFunctionsException catch (e) {
        final transitoire = e.code == 'unavailable' || e.code == 'deadline-exceeded';
        if (!transitoire || tentative >= delaisRetentative.length) rethrow;
        await Future.delayed(delaisRetentative[tentative]);
      }
    }
  }

  /// Expéditeurs vus dans les emails récents de la boîte connectée, du plus
  /// fréquent au moins fréquent — pour choisir plutôt que taper à la main.
  Future<List<({String email, int nombre})>> expediteursRecents() async {
    // Délai aligné sur le timeout_sec=300 côté serveur : le catalogue peut
    // scanner jusqu'à 500 emails, largement plus long que le délai par
    // défaut du plugin (trop court pour une boîte mail chargée).
    final resultat = await FirebaseFunctions.instance
        .httpsCallable(
          'lister_expediteurs_recents',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 300)),
        )
        .call();
    final liste = resultat.data['expediteurs'] as List<dynamic>;
    return liste
        .map((e) => (email: e['email'] as String, nombre: e['nombre'] as int))
        .toList();
  }

  /// Contacts (noms et emails) récupérés depuis les comptes Google connectés
  /// (Inspiration Slack) pour faciliter l'invitation de collaborateurs.
  Future<List<({String email, String nom})>> contactsGoogle() async {
    final resultat = await FirebaseFunctions.instance
        .httpsCallable(
          'lister_contacts_google',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
        )
        .call();
    final liste = resultat.data['contacts'] as List<dynamic>;
    return liste
        .map((c) => (email: c['email'] as String, nom: c['nom'] as String))
        .toList();
  }

  Future<void> definirMethodeExtraction(String methode) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('utilisateurs').doc(uid).set(
      {'methodeExtraction': methode},
      SetOptions(merge: true),
    );
  }

  Future<void> ajouterExpediteurConfiance(String email) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('utilisateurs').doc(uid).set(
      {'expediteursConfiance': FieldValue.arrayUnion([email.trim().toLowerCase()])},
      SetOptions(merge: true),
    );
  }

  Future<void> retirerExpediteurConfiance(String email) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('utilisateurs').doc(uid).update(
      {'expediteursConfiance': FieldValue.arrayRemove([email])},
    );
  }

  /// Dates détectées dans les emails, en attente de validation.
  Stream<List<PropositionDossier>> propositions() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db
        .collection('utilisateurs')
        .doc(uid)
        .collection('propositions')
        .orderBy('creeLe', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PropositionDossier.depuisDocument).toList());
  }

  /// Tous les comptes Google actuellement connectés (0 à plusieurs, aucun
  /// ordre/rôle imposé).
  Stream<List<ConnexionGoogle>> connexionsGoogle() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db
        .collection('utilisateurs')
        .doc(uid)
        .collection('connexionsGoogle')
        .snapshots()
        .map((snap) => snap.docs.map(ConnexionGoogle.depuisDocument).toList());
  }

  /// État de la dernière vérification par source (Gmail/Tasks/Calendar) —
  /// clé = "gmail"/"tasks"/"calendar".
  Stream<Map<String, EtatSync>> etatsSync() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db
        .collection('utilisateurs')
        .doc(uid)
        .collection('etatSync')
        .snapshots()
        .map((snap) => {for (final doc in snap.docs) doc.id: EtatSync.depuisDocument(doc)});
  }

  /// Retire une proposition (refusée, ou déjà transformée en vrai dossier).
  Future<void> supprimerProposition(String propositionId) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db
        .collection('utilisateurs')
        .doc(uid)
        .collection('propositions')
        .doc(propositionId)
        .delete();
  }
}
