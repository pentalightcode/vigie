import 'package:cloud_firestore/cloud_firestore.dart';

/// Le type d'une entrée de journal — guide l'utilisateur au moment d'écrire
/// (demandé par Tobie le 2026-08-20 : "on doit guider l'utilisateur afin
/// qu'il remplisse bien le journal", pas un champ de texte libre générique).
enum TypeEntreeJournal { avancement, blocage, decision, autre }

TypeEntreeJournal _typeDepuisTexte(String? texte) =>
    TypeEntreeJournal.values.firstWhere((t) => t.name == texte, orElse: () => TypeEntreeJournal.autre);

/// Une entrée du journal d'un dossier — pas un champ qu'on écrase, une ligne
/// qu'on ajoute à la suite pour documenter l'avancement étape par étape
/// (demandé par Tobie le 2026-08-20 : "noter et documenter l'avancement,
/// l'évolution d'une tâche ou d'un dossier" — bien distinct des notes par
/// tâche, qui décrivent un état ponctuel, pas une progression).
class EntreeJournal {
  EntreeJournal({
    required this.id,
    required this.dossierId,
    required this.texte,
    required this.creeLe,
    required this.type,
    this.modifieLe,
  });

  final String id;
  final String dossierId;
  final String texte;
  final DateTime creeLe;
  final TypeEntreeJournal type;
  final DateTime? modifieLe;

  factory EntreeJournal.depuisDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EntreeJournal(
      id: doc.id,
      dossierId: data['dossierId'] as String,
      texte: data['texte'] as String,
      creeLe: (data['creeLe'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: _typeDepuisTexte(data['type'] as String?),
      modifieLe: (data['modifieLe'] as Timestamp?)?.toDate(),
    );
  }
}
