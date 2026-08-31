import 'package:cloud_functions/cloud_functions.dart';

/// Gestion des participants d'un dossier partagé (ajouté le 2026-08-29,
/// refonte "travail de groupe" — voir
/// Notes/2026-08-29-redteam-collaboration-multi-angles.md). Passe par la
/// fonction serveur `gerer_participant_dossier` plutôt que d'écrire
/// directement `participantsUids`/`roles` sur le dossier : c'est elle qui
/// résout l'email en uid (recherche par email, impossible côté téléphone),
/// vérifie que le demandeur est créateur/administrateur, et synchronise la
/// liste sur les tâches/entrées de journal déjà existantes du dossier.
class DossierParticipantsService {
  DossierParticipantsService._();
  static final DossierParticipantsService instance = DossierParticipantsService._();

  Future<void> ajouter({required String dossierId, required String email, required String role}) {
    return FirebaseFunctions.instance.httpsCallable('gerer_participant_dossier').call({
      'action': 'ajouter',
      'dossierId': dossierId,
      'email': email,
      'role': role,
    });
  }

  Future<void> retirer({required String dossierId, required String uid}) {
    return FirebaseFunctions.instance.httpsCallable('gerer_participant_dossier').call({
      'action': 'retirer',
      'dossierId': dossierId,
      'uid': uid,
    });
  }

  Future<void> changerRole({required String dossierId, required String uid, required String role}) {
    return FirebaseFunctions.instance.httpsCallable('gerer_participant_dossier').call({
      'action': 'changerRole',
      'dossierId': dossierId,
      'uid': uid,
      'role': role,
    });
  }
}
