import 'package:cloud_firestore/cloud_firestore.dart';

/// Une proposition de modification en attente sur une tâche ou une entrée de
/// journal (Phase 2, 2026-08-31) — voir firestore.rules (Chemin B des règles
/// `update` de /taches et /journalDossier) : un participant qui n'a pas
/// d'accès libre au contenu créé par quelqu'un d'AUTRE écrit ceci au lieu du
/// champ réel. Le créateur (ou l'auteur/gestionnaire) approuve en appliquant
/// `donnees` aux vrais champs et en remettant ce champ à `null` en une seule
/// écriture, ou rejette en le remettant juste à `null`. Partagé entre
/// `Tache` et `EntreeJournal` — même forme dans les deux collections.
class PropositionEnAttente {
  const PropositionEnAttente({
    required this.type,
    required this.proposePar,
    this.proposeLe,
    this.donnees = const {},
  });

  /// Tâches : 'modifier' | 'marquerFait' | 'marquerNonFait' | 'supprimer'.
  /// Journal : 'modifier' | 'supprimer'.
  final String type;
  final String proposePar;
  final DateTime? proposeLe;

  /// Valeurs proposées — vide sauf pour `type == 'modifier'`, où elle porte
  /// les mêmes clés que `versDocument()` du champ concerné (ex:
  /// 'descriptionCourte'/'notesDetaillees' pour une tâche, 'texte' pour une
  /// entrée de journal).
  final Map<String, dynamic> donnees;

  factory PropositionEnAttente.depuisMap(Map<String, dynamic> data) {
    return PropositionEnAttente(
      type: data['type'] as String,
      proposePar: data['proposePar'] as String,
      proposeLe: (data['proposeLe'] as Timestamp?)?.toDate(),
      donnees: (data['donnees'] as Map<String, dynamic>?) ?? const {},
    );
  }

  /// `proposeLe` : toujours l'heure serveur pour une proposition tout juste
  /// créée (voir DossierParticipantsService/FirestoreService, aucun appelant
  /// ne fournit encore une date pour ce champ) — cohérent avec `creeLe`
  /// ailleurs dans ce modèle de données.
  Map<String, dynamic> versMap() {
    return {
      'type': type,
      'proposePar': proposePar,
      'proposeLe': proposeLe != null ? Timestamp.fromDate(proposeLe!) : FieldValue.serverTimestamp(),
      'donnees': donnees,
    };
  }
}
