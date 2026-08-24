import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Gère le verrou propre à l'app (code PIN + biométrie), indépendant du
/// verrouillage du téléphone. Sans ça, toute la confidentialité construite
/// (noms de code + chiffrement) ne servirait à rien si quelqu'un ouvre le
/// téléphone déjà déverrouillé de son père et lance l'app directement.
class LockService {
  LockService._();
  static final LockService instance = LockService._();

  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  static const _pinKey = 'code_pin_app';

  Future<bool> pinDejaDefini() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null;
  }

  Future<void> definirPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  /// Efface le code PIN (utilisé en cas d'oubli, après avoir reprouvé son
  /// identité par email — voir [AuthService.seDeconnecter]). Ne touche pas
  /// aux dossiers/tâches : ils restent liés au compte, pas au PIN.
  Future<void> reinitialiserPin() async {
    await _storage.delete(key: _pinKey);
  }

  Future<bool> verifierPin(String pin) async {
    final enregistre = await _storage.read(key: _pinKey);
    return enregistre != null && enregistre == pin;
  }

  Future<bool> biometrieDisponible() async {
    try {
      final supporte = await _localAuth.isDeviceSupported();
      final peutVerifier = await _localAuth.canCheckBiometrics;
      return supporte && peutVerifier;
    } catch (_) {
      // Pas supporté sur cette plateforme (ex: web) — le PIN reste disponible.
      return false;
    }
  }

  Future<bool> authentifierAvecBiometrie() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Confirme ton identité pour ouvrir Vigie',
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}
