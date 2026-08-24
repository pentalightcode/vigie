import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gère la connexion par lien magique (email link, sans mot de passe).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const _prefsEmailKey = 'email_en_attente_de_connexion';

  /// URL vers laquelle Firebase enverra le père : elle doit correspondre
  /// au domaine Hosting configuré (assetlinks.json + intent-filter Android).
  ActionCodeSettings get _actionCodeSettings => ActionCodeSettings(
        url: 'https://vigie.pentalightcode.com/connexion',
        handleCodeInApp: true,
        androidPackageName: 'bj.pentalightcode.secretaire_aje',
        androidInstallApp: true,
        androidMinimumVersion: '1',
        iOSBundleId: 'bj.pentalightcode.secretaireAje',
      );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Envoie le lien de connexion à l'adresse indiquée.
  Future<void> envoyerLienDeConnexion(String email) async {
    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: _actionCodeSettings,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsEmailKey, email);
  }

  bool estUnLienDeConnexion(String lien) {
    return _auth.isSignInWithEmailLink(lien);
  }

  /// Cherche l'email associé à la demande de lien en cours sur cet appareil.
  /// Renvoie null si le lien a été ouvert ailleurs (autre navigateur/appareil) —
  /// dans ce cas il faudra redemander l'email au père pour confirmer.
  Future<String?> emailEnAttente() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsEmailKey);
  }

  /// Termine la connexion une fois le lien reçu (ouvert depuis le mail),
  /// avec l'email fourni (retrouvé automatiquement, ou confirmé par le père).
  Future<void> terminerConnexionAvecLienEtEmail(String lien, String email) async {
    await _auth.signInWithEmailLink(email: email, emailLink: lien);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsEmailKey);
  }

  Future<void> seDeconnecter() => _auth.signOut();
}
