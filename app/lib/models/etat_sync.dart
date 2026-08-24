import 'package:cloud_firestore/cloud_firestore.dart';

/// État de la dernière vérification automatique d'une source (Gmail, Google
/// Tasks, Google Calendar) — transparence demandée par Tobie le 2026-08-20 :
/// sans ça, un échec silencieux ne se voit nulle part côté utilisateur.
class EtatSync {
  EtatSync({required this.source, this.derniereExecution, required this.succes, this.erreur});

  final String source;
  final DateTime? derniereExecution;
  final bool succes;
  final String? erreur;

  factory EtatSync.depuisDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EtatSync(
      source: doc.id,
      derniereExecution: (data['derniereExecution'] as Timestamp?)?.toDate(),
      succes: data['succes'] as bool? ?? true,
      erreur: data['erreur'] as String?,
    );
  }
}
