import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Chiffrement bout-en-bout des notes de dossier (journalDossier) — prévu
/// dès la toute première conception (Notes/2026-08-07-mvp-scope.md, point Q :
/// "clé de chiffrement dérivée d'une phrase secrète... jamais stockée
/// nulle part"), jamais implémenté jusqu'ici (le champ notePrivee qui
/// devait porter ça est resté du code mort, remplacé en pratique par
/// journalDossier sans chiffrement). Ajouté le 2026-08-29 sur demande
/// explicite de Tobie pour combler cet écart.
///
/// Différence fondamentale avec le code PIN (lock_service.dart) : le PIN
/// est un simple verrou, réinitialisable par email en cas d'oubli, sans
/// perte de données. Ici, la phrase secrète EST directement la clé de
/// chiffrement — si elle est oubliée, les notes déjà écrites deviennent
/// définitivement illisibles, pour tout le monde, PENTALIGHTCODE compris.
/// C'est le prix d'une vraie confidentialité bout-en-bout (le serveur ne
/// voit jamais que du texte chiffré), pas un bug — l'utilisateur doit en
/// être informé clairement avant de choisir sa phrase (voir le dialogue
/// associé).
///
/// Mise en cache locale (ajoutée après retour de Tobie le 2026-08-29 :
/// redemander la phrase à CHAQUE ouverture de l'app, en plus du PIN déjà
/// redemandé à chaque fois, était trop de friction pour un usage quotidien).
/// La clé dérivée est mise en cache dans le stockage sécurisé du téléphone
/// (même mécanisme que le PIN) après la première saisie — la phrase n'est
/// donc redemandée qu'une fois par appareil, pas à chaque session. Ça ne
/// change rien à la vraie protection visée (empêcher un accès serveur/
/// PENTALIGHTCODE de lire les notes en clair : la clé ne quitte jamais
/// l'appareil, ni dans un cas ni dans l'autre) — ça aligne juste le niveau
/// de risque "accès local à l'appareil" sur celui déjà accepté pour le PIN,
/// au lieu d'être artificiellement plus strict pour cette seule fonctionnalité.
class ChiffrementNotesService {
  ChiffrementNotesService._();
  static final ChiffrementNotesService instance = ChiffrementNotesService._();

  static final _algo = AesGcm.with256bits();
  // 600 000 itérations (recommandation OWASP 2023 pour PBKDF2-HMAC-SHA256
  // utilisé comme dérivation de clé de chiffrement réelle) — volontairement
  // plus élevé que les 120 000 du hachage du PIN : ici la phrase protège
  // directement des données, pas juste un verrou d'accès local.
  static final _pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 600000, bits: 256);
  static const _texteVerification = 'vigie-verification-phrase-secrete';

  final _db = FirebaseFirestore.instance;
  final _stockage = const FlutterSecureStorage();

  /// Clé dérivée, gardée en mémoire pour la session en cours ET mise en
  /// cache dans le stockage sécurisé (voir doc de la classe) — jamais dans
  /// Firestore, jamais en clair.
  SecretKey? _cle;

  bool get estDeverrouille => _cle != null;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference<Map<String, dynamic>> get _document =>
      _db.collection('utilisateurs').doc(_uid);

  // Préfixée par l'uid : deux comptes différents sur le même appareil (ex:
  // Tobie et son père testant sur le même téléphone) n'écrasent jamais le
  // cache l'un de l'autre.
  String get _cleStockage => 'chiffrement_notes_cle_$_uid';

  /// True si une phrase a déjà été définie sur CE compte (donc sur
  /// n'importe quel appareil, le sel/vérificateur vivent dans Firestore,
  /// pas localement) — sinon on propose d'en créer une, jamais de la redemander.
  Future<bool> phraseDejaDefinie() async {
    final doc = await _document.get();
    return doc.data()?['chiffrementSel'] != null;
  }

  /// À tenter avant de proposer le dialogue — si une clé a déjà été mise en
  /// cache sur cet appareil pour ce compte, déverrouille directement sans
  /// rien demander à l'utilisateur.
  Future<bool> tenterDeverrouillageAutomatique() async {
    if (estDeverrouille) return true;
    final brutBase64 = await _stockage.read(key: _cleStockage);
    if (brutBase64 == null) return false;
    _cle = SecretKeyData(base64Decode(brutBase64));
    return true;
  }

  Future<SecretKey> _deriverCle(String phrase, List<int> sel) {
    return _pbkdf2.deriveKeyFromPassword(password: phrase, nonce: sel);
  }

  Future<void> _mettreEnCache(SecretKey cle) async {
    final octets = await cle.extractBytes();
    await _stockage.write(key: _cleStockage, value: base64Encode(octets));
  }

  /// Première définition de la phrase secrète : génère un sel aléatoire,
  /// dérive la clé, et enregistre un "vérificateur" (un texte connu chiffré
  /// avec cette clé) — jamais la phrase ni la clé elles-mêmes. Le
  /// vérificateur permet de confirmer plus tard qu'une phrase retapée est
  /// la bonne, sans jamais pouvoir en retrouver la valeur à partir de ce
  /// qui est stocké.
  Future<void> definirPhrase(String phrase) async {
    final sel = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final cle = await _deriverCle(phrase, sel);
    final verificateur = await _algo.encrypt(utf8.encode(_texteVerification), secretKey: cle);
    await _document.set({
      'chiffrementSel': base64Encode(sel),
      'chiffrementVerificateur': base64Encode(verificateur.concatenation()),
    }, SetOptions(merge: true));
    _cle = cle;
    await _mettreEnCache(cle);
  }

  /// Tente de déverrouiller avec la phrase donnée. Renvoie false si elle
  /// est incorrecte (aucune limite de tentatives ici volontairement : la
  /// vraie défense contre le brute-force est le coût de calcul du PBKDF2
  /// à 600 000 itérations, pas un verrou d'interface — un attaquant qui
  /// aurait déjà accès au sel/vérificateur stockés a de toute façon
  /// contourné la couche applicative).
  Future<bool> deverrouillerAvecPhrase(String phrase) async {
    final doc = await _document.get();
    final selBase64 = doc.data()?['chiffrementSel'] as String?;
    final verifBase64 = doc.data()?['chiffrementVerificateur'] as String?;
    if (selBase64 == null || verifBase64 == null) return false;

    final cle = await _deriverCle(phrase, base64Decode(selBase64));
    try {
      final boite = SecretBox.fromConcatenation(
        base64Decode(verifBase64),
        nonceLength: AesGcm.defaultNonceLength,
        macLength: _algo.macAlgorithm.macLength,
      );
      final dechiffre = await _algo.decrypt(boite, secretKey: cle);
      if (utf8.decode(dechiffre) != _texteVerification) return false;
    } catch (_) {
      return false;
    }
    _cle = cle;
    await _mettreEnCache(cle);
    return true;
  }

  /// Efface la clé de la mémoire ET du cache local de cet appareil — à
  /// utiliser explicitement (ex: si on ajoute un jour un bouton "verrouiller
  /// mes notes"), jamais appelé automatiquement à la déconnexion : se
  /// déconnecter puis se reconnecter avec le même compte ne doit pas obliger
  /// à retaper la phrase, tant que c'est le même appareil.
  Future<void> verrouiller() async {
    _cle = null;
    await _stockage.delete(key: _cleStockage);
  }

  /// N'efface QUE la mémoire (pas le cache disque) — pour un changement de
  /// compte dans la même session app (déconnexion vers un autre compte),
  /// afin de ne jamais garder en mémoire la clé du compte précédent tout en
  /// préservant son cache pour son prochain retour sur cet appareil.
  void oublierSession() => _cle = null;

  Future<String> chiffrer(String texteClair) async {
    final cle = _cle;
    if (cle == null) throw StateError('Notes non déverrouillées.');
    final boite = await _algo.encrypt(utf8.encode(texteClair), secretKey: cle);
    return base64Encode(boite.concatenation());
  }

  Future<String> dechiffrer(String texteChiffre) async {
    final cle = _cle;
    if (cle == null) throw StateError('Notes non déverrouillées.');
    final boite = SecretBox.fromConcatenation(
      base64Decode(texteChiffre),
      nonceLength: AesGcm.defaultNonceLength,
      macLength: _algo.macAlgorithm.macLength,
    );
    final dechiffre = await _algo.decrypt(boite, secretKey: cle);
    return utf8.decode(dechiffre);
  }
}
