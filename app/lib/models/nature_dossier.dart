import 'package:cloud_firestore/cloud_firestore.dart';

/// Une "nature" de dossier propre à l'utilisateur (ex: Audience, Consultation,
/// Séance à préparer...) — remplace l'ancienne liste fixe de types, pour que
/// chaque utilisateur (magistrat, médecin, professeur...) ait ses propres
/// catégories, pré-remplies selon sa profession à l'inscription.
class NatureDossier {
  NatureDossier({required this.id, required this.nom});

  final String id;
  final String nom;

  factory NatureDossier.depuisDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NatureDossier(id: doc.id, nom: data['nom'] as String);
  }

  Map<String, dynamic> versDocument() => {'nom': nom};

  @override
  bool operator ==(Object other) => other is NatureDossier && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
