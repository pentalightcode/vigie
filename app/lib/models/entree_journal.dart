import 'package:cloud_firestore/cloud_firestore.dart';

import 'proposition_en_attente.dart';

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
    this.chiffre = false,
    this.participantsUids = const [],
    this.auteurUid,
    this.propositionEnAttente,
  });

  final String id;
  final String dossierId;
  /// Le texte tel qu'il vient de Firestore — encore chiffré si [chiffre]
  /// est vrai, à déchiffrer avant affichage (voir ChiffrementNotesService).
  final String texte;
  final DateTime creeLe;
  final TypeEntreeJournal type;
  final DateTime? modifieLe;
  /// Ajouté le 2026-08-29 : distingue les entrées chiffrées bout-en-bout
  /// (écrites après que l'utilisateur a défini sa phrase secrète) de celles
  /// d'avant, restées en clair — jamais rechiffrées rétroactivement, pour
  /// ne prendre aucun risque de migration sur des données existantes.
  final bool chiffre;
  /// Copié depuis le dossier parent (voir `Dossier.participantsUids`).
  final List<String> participantsUids;
  /// Qui a réellement écrit cette entrée — distinct de `uid` (à qui
  /// appartient le dossier), voir `Notes/2026-08-29-redteam-collaboration-multi-angles.md`.
  final String? auteurUid;
  /// Proposition de modification/suppression en attente d'approbation
  /// (Phase 2, 2026-08-31 — voir PropositionEnAttente, firestore.rules).
  final PropositionEnAttente? propositionEnAttente;

  factory EntreeJournal.depuisDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EntreeJournal(
      id: doc.id,
      dossierId: data['dossierId'] as String,
      texte: data['texte'] as String,
      creeLe: (data['creeLe'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: _typeDepuisTexte(data['type'] as String?),
      modifieLe: (data['modifieLe'] as Timestamp?)?.toDate(),
      chiffre: data['chiffre'] as bool? ?? false,
      participantsUids: (data['participantsUids'] as List<dynamic>?)?.cast<String>() ?? const [],
      auteurUid: data['auteurUid'] as String? ?? data['uid'] as String?,
      propositionEnAttente: (data['propositionEnAttente'] as Map<String, dynamic>?) != null
          ? PropositionEnAttente.depuisMap(data['propositionEnAttente'] as Map<String, dynamic>)
          : null,
    );
  }

  EntreeJournal copierAvec({String? texte, TypeEntreeJournal? type}) => EntreeJournal(
        id: id,
        dossierId: dossierId,
        texte: texte ?? this.texte,
        creeLe: creeLe,
        type: type ?? this.type,
        modifieLe: modifieLe,
        chiffre: chiffre,
        participantsUids: participantsUids,
        auteurUid: auteurUid,
        propositionEnAttente: propositionEnAttente,
      );
}
