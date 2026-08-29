import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gère le verrou propre à l'app (code PIN + biométrie), indépendant du
/// verrouillage du téléphone. Sans ça, toute la confidentialité construite
/// (noms de code + chiffrement) ne servirait à rien si quelqu'un ouvre le
/// téléphone déjà déverrouillé de son père et lance l'app directement.
class LockService {
  LockService._();
  static final LockService instance = LockService._();

  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  static const _selKey = 'code_pin_sel';
  static const _hachageKey = 'code_pin_hachage';

  // Trouvé lors de l'audit de sécurité du 2026-08-29 (demandé par Tobie) :
  // le PIN était stocké en clair — le commentaire de verrou_screen.dart
  // affirmait le contraire depuis le début. PBKDF2 (dérivation lente, pense
  // pour des secrets courts comme un PIN à 4-6 chiffres) + sel aléatoire par
  // appareil : même en cas d'extraction du stockage sécurisé, le PIN réel
  // n'y figure jamais.
  static final _pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 120000, bits: 256);

  Future<String> _hacher(String pin, List<int> sel) async {
    final cle = await _pbkdf2.deriveKeyFromPassword(password: pin, nonce: sel);
    return base64Encode(await cle.extractBytes());
  }

  Future<bool> pinDejaDefini() async {
    final hachage = await _storage.read(key: _hachageKey);
    return hachage != null;
  }

  Future<void> definirPin(String pin) async {
    final sel = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final hachage = await _hacher(pin, sel);
    await _storage.write(key: _selKey, value: base64Encode(sel));
    await _storage.write(key: _hachageKey, value: hachage);
    await _reinitialiserTentatives();
  }

  /// Efface le code PIN (utilisé en cas d'oubli, après avoir reprouvé son
  /// identité par email — voir [AuthService.seDeconnecter]). Ne touche pas
  /// aux dossiers/tâches : ils restent liés au compte, pas au PIN.
  Future<void> reinitialiserPin() async {
    await _storage.delete(key: _selKey);
    await _storage.delete(key: _hachageKey);
    await _reinitialiserTentatives();
  }

  /// Vérifie le PIN, avec verrouillage progressif après plusieurs échecs
  /// (trouvé lors de l'audit du 2026-08-29 : rien n'empêchait avant de
  /// tester les 10 000 combinaisons d'un PIN à 4 chiffres sans limite).
  /// Renvoie un délai en secondes si l'appareil est temporairement bloqué,
  /// sinon vérifie normalement.
  Future<PinResultat> verifierPin(String pin) async {
    final attente = await _secondesAvantProchainEssai();
    if (attente > 0) return PinResultat.verrouille(attente);

    final selBase64 = await _storage.read(key: _selKey);
    final hachageEnregistre = await _storage.read(key: _hachageKey);
    if (selBase64 == null || hachageEnregistre == null) return PinResultat.incorrect();

    final hachageCalcule = await _hacher(pin, base64Decode(selBase64));
    if (hachageCalcule == hachageEnregistre) {
      await _reinitialiserTentatives();
      return PinResultat.correct();
    }
    await _enregistrerEchec();
    return PinResultat.incorrect();
  }

  static const _tentativesKey = 'pin_tentatives_echouees';
  static const _verrouJusquaKey = 'pin_verrouille_jusqua_epoch';
  static const _seuilAvantVerrouillage = 5;

  Future<int> _secondesAvantProchainEssai() async {
    final prefs = await SharedPreferences.getInstance();
    final jusqua = prefs.getInt(_verrouJusquaKey);
    if (jusqua == null) return 0;
    final restant = jusqua - DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return restant > 0 ? restant : 0;
  }

  Future<void> _enregistrerEchec() async {
    final prefs = await SharedPreferences.getInstance();
    final tentatives = (prefs.getInt(_tentativesKey) ?? 0) + 1;
    await prefs.setInt(_tentativesKey, tentatives);
    if (tentatives >= _seuilAvantVerrouillage) {
      // Double à chaque palier de 5 échecs supplémentaires (30s, 60s, 120s...),
      // plafonné à 10 minutes — ralentit un essai automatisé sans bloquer
      // définitivement quelqu'un qui a simplement oublié son code.
      final palier = (tentatives - _seuilAvantVerrouillage) ~/ _seuilAvantVerrouillage;
      final secondes = (30 * (1 << palier)).clamp(30, 600);
      final jusqua = DateTime.now().millisecondsSinceEpoch ~/ 1000 + secondes;
      await prefs.setInt(_verrouJusquaKey, jusqua);
    }
  }

  Future<void> _reinitialiserTentatives() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tentativesKey);
    await prefs.remove(_verrouJusquaKey);
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

class PinResultat {
  const PinResultat._({required this.correct, this.secondesAvantProchainEssai});

  factory PinResultat.correct() => const PinResultat._(correct: true);
  factory PinResultat.incorrect() => const PinResultat._(correct: false);
  factory PinResultat.verrouille(int secondes) =>
      PinResultat._(correct: false, secondesAvantProchainEssai: secondes);

  final bool correct;
  /// Non nul uniquement si l'appareil est temporairement verrouillé après
  /// trop d'échecs (voir [LockService.verifierPin]).
  final int? secondesAvantProchainEssai;
}
