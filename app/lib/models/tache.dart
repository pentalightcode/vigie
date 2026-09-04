import 'package:cloud_firestore/cloud_firestore.dart';

import 'proposition_en_attente.dart';

enum StatutTache { aFaire, fait }

StatutTache _statutDepuisTexte(String texte) =>
    StatutTache.values.firstWhere((s) => s.name == texte, orElse: () => StatutTache.aFaire);

/// Une tâche liée à un [Dossier] (diligence, écriture, réponse à un courrier...).
/// `nature` est dénormalisée depuis la [NatureDossier] choisie au moment de la
/// création (comme `nomCodeDossier`) — si l'utilisateur renomme ou supprime
/// cette nature plus tard, les tâches déjà créées gardent leur libellé d'origine.
class Tache {
  Tache({
    required this.id,
    required this.uid,
    required this.dossierId,
    required this.nomCodeDossier,
    required this.descriptionCourte,
    required this.nature,
    required this.dateDeclenchante,
    required this.datePremierRappel,
    required this.statut,
    this.dateFait,
    this.notesDetaillees,
    List<String>? participantsUids,
    String? auteurUid,
    this.propositionEnAttente,
    this.creeLe,
  })  : participantsUids = participantsUids ?? [uid],
        auteurUid = auteurUid ?? uid;

  final String id;
  final String uid;
  final String dossierId;
  final String nomCodeDossier; // dénormalisé pour un affichage rapide
  final String descriptionCourte;
  final String nature;
  final DateTime dateDeclenchante;
  final DateTime datePremierRappel;
  final StatutTache statut;
  final DateTime? dateFait; // pour savoir si c'est "fait cette semaine" dans le bilan
  /// Copié depuis le dossier parent (voir `Dossier.participantsUids`),
  /// synchronisé par la fonction serveur quand la liste change — permet de
  /// retrouver "mes tâches" par une requête directe, sans passer par le
  /// dossier à chaque fois.
  final List<String> participantsUids;
  /// Qui a réellement créé cette tâche — distinct de `uid` (qui reste
  /// l'identifiant du dossier auquel elle appartient, pas forcément la
  /// personne qui l'a écrite une fois plusieurs participants possibles).
  final String auteurUid;
  /// Détails libres — rempli automatiquement quand la tâche vient d'un
  /// événement Google Calendar ou d'une tâche Google Tasks (leur description
  /// d'origine, sinon perdue), modifiable ensuite comme un bloc-notes libre
  /// par tâche (demandé par Tobie le 2026-08-20). Reste en clair comme
  /// `descriptionCourte` — même rappel de prudence sur les noms de code.
  final String? notesDetaillees;

  /// Proposition de modification/marquage/suppression en attente
  /// d'approbation par l'auteur ou créateur/administrateur (Phase 2,
  /// 2026-08-31 — voir PropositionEnAttente, firestore.rules). `null` = rien
  /// en attente sur cette tâche.
  final PropositionEnAttente? propositionEnAttente;

  /// Date de création réelle de la tâche (ajoutée pour affichage).
  final DateTime? creeLe;

  /// Calculé, jamais stocké : l'échéance est dépassée et ce n'est toujours
  /// pas fait (correction du point O — distinguer "encore le temps" et "trop tard").
  bool get estEnRetard =>
      statut == StatutTache.aFaire && dateDeclenchante.isBefore(DateTime.now());

  /// Calculé : la tâche doit apparaître dans les rappels (on est dans sa
  /// fenêtre active) et elle n'est pas encore faite.
  bool get estActive =>
      statut == StatutTache.aFaire && !datePremierRappel.isAfter(DateTime.now());

  factory Tache.depuisDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Tache(
      id: doc.id,
      uid: data['uid'] as String,
      dossierId: data['dossierId'] as String,
      nomCodeDossier: data['nomCodeDossier'] as String,
      descriptionCourte: data['descriptionCourte'] as String,
      nature: data['nature'] as String? ?? 'Autre',
      dateDeclenchante: (data['dateDeclenchante'] as Timestamp).toDate(),
      datePremierRappel: (data['datePremierRappel'] as Timestamp).toDate(),
      statut: _statutDepuisTexte(data['statut'] as String),
      dateFait: (data['dateFait'] as Timestamp?)?.toDate(),
      notesDetaillees: data['notesDetaillees'] as String?,
      participantsUids: (data['participantsUids'] as List<dynamic>?)?.cast<String>(),
      auteurUid: data['auteurUid'] as String?,
      propositionEnAttente: (data['propositionEnAttente'] as Map<String, dynamic>?) != null
          ? PropositionEnAttente.depuisMap(data['propositionEnAttente'] as Map<String, dynamic>)
          : null,
      creeLe: (data['creeLe'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> versDocument() {
    return {
      'uid': uid,
      'dossierId': dossierId,
      'nomCodeDossier': nomCodeDossier,
      'descriptionCourte': descriptionCourte,
      'nature': nature,
      'dateDeclenchante': Timestamp.fromDate(dateDeclenchante),
      'datePremierRappel': Timestamp.fromDate(datePremierRappel),
      'statut': statut.name,
      'dateFait': dateFait != null ? Timestamp.fromDate(dateFait!) : null,
      'notesDetaillees': notesDetaillees,
      'participantsUids': participantsUids,
      'auteurUid': auteurUid,
    };
  }

  /// Calcule la date de premier rappel : le délai choisi par l'utilisateur
  /// avant la date de l'événement (par défaut 14 jours — voir
  /// [UtilisateurService]), sans exception — toutes les natures de tâche
  /// respectent le même délai (avant, "Courrier" ignorait le délai et
  /// apparaissait toujours tout de suite ; changé le 22/08/2026 à la demande
  /// de Tobie, qui trouvait ce cas particulier incohérent avec le reste).
  static DateTime calculerDatePremierRappel(DateTime dateDeclenchante, int delaiJours) {
    return dateDeclenchante.subtract(Duration(days: delaiJours));
  }
}
