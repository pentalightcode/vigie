import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/nature_dossier.dart';
import '../models/profession.dart';

/// Gère les natures de dossier propres à chaque utilisateur (correction
/// demandée par Tobie : l'app sert plusieurs métiers, chacun doit pouvoir
/// définir ses propres catégories plutôt que d'avoir 4 types fixes pour tous).
class NatureDossierService {
  NatureDossierService._();
  static final NatureDossierService instance = NatureDossierService._();

  final _db = FirebaseFirestore.instance;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Aucun utilisateur connecté.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('utilisateurs').doc(_uid).collection('naturesDossier');

  /// À appeler une seule fois, à l'inscription : remplit la liste de départ
  /// selon la profession choisie.
  Future<void> initialiserPourProfession(Profession profession) async {
    final existant = await _collection.limit(1).get();
    if (existant.docs.isNotEmpty) return; // déjà initialisé, on ne double pas

    final batch = _db.batch();
    for (final nature in naturesDeDepartPour(profession)) {
      batch.set(_collection.doc(), {'nom': nature.nom});
    }
    await batch.commit();
  }

  Stream<List<NatureDossier>> natures() {
    return _collection
        .orderBy('nom')
        .snapshots()
        .map((snap) => snap.docs.map(NatureDossier.depuisDocument).toList());
  }

  Future<void> ajouterNature(String nom) {
    return _collection.add({'nom': nom});
  }

  Future<void> supprimerNature(String id) {
    return _collection.doc(id).delete();
  }
}
