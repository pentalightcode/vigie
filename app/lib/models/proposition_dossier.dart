import 'package:cloud_firestore/cloud_firestore.dart';

/// Une date détectée dans un email d'un expéditeur de confiance, en attente
/// de validation — rien n'est jamais créé automatiquement (décision du
/// 2026-08-12 : proposer, pas décider à la place de l'utilisateur).
class PropositionDossier {
  PropositionDossier({
    required this.id,
    required this.nomSuggere,
    required this.date,
    required this.expediteur,
    required this.sujetEmail,
    this.details = '',
  });

  final String id;
  final String nomSuggere;
  final DateTime? date;
  final String expediteur;
  final String sujetEmail;
  /// Description/notes d'origine (Google Tasks/Calendar) — vide pour les
  /// propositions Gmail, qui n'en capturent pas.
  final String details;

  factory PropositionDossier.depuisDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PropositionDossier(
      id: doc.id,
      nomSuggere: data['nomSuggere'] as String? ?? 'À nommer',
      date: (data['date'] as Timestamp?)?.toDate(),
      expediteur: data['expediteur'] as String? ?? '',
      sujetEmail: data['sujetEmail'] as String? ?? '',
      details: data['details'] as String? ?? '',
    );
  }
}
