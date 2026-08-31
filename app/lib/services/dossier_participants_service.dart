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

  /// Permissions à la carte qu'un créateur peut accorder à un administrateur
  /// (Phase 2, 2026-08-31) — miroir de `_PERMISSIONS_ADMINISTRATEUR_VALABLES`
  /// côté serveur (functions/main.py). Défaut désactivé pour tout nouvel
  /// administrateur : sans 'modererContenu', il est traité comme un simple
  /// contributeur face au contenu créé par quelqu'un d'autre.
  static const permissionsValables = ['gererParticipants', 'supprimerDossier', 'modererContenu'];

  static const libellesPermissions = {
    'gererParticipants': 'Ajouter/retirer des participants, changer leur rôle',
    'supprimerDossier': 'Supprimer le dossier',
    'modererContenu': 'Modifier/marquer fait/supprimer le contenu des autres sans validation',
  };

  Future<void> ajouter({
    required String dossierId,
    required String email,
    required String role,
    List<String>? permissions,
  }) {
    return FirebaseFunctions.instance.httpsCallable('gerer_participant_dossier').call({
      'action': 'ajouter',
      'dossierId': dossierId,
      'email': email,
      'role': role,
      if (permissions != null) 'permissions': permissions,
    });
  }

  Future<void> retirer({required String dossierId, required String uid}) {
    return FirebaseFunctions.instance.httpsCallable('gerer_participant_dossier').call({
      'action': 'retirer',
      'dossierId': dossierId,
      'uid': uid,
    });
  }

  Future<void> changerRole({
    required String dossierId,
    required String uid,
    required String role,
    List<String>? permissions,
  }) {
    return FirebaseFunctions.instance.httpsCallable('gerer_participant_dossier').call({
      'action': 'changerRole',
      'dossierId': dossierId,
      'uid': uid,
      'role': role,
      if (permissions != null) 'permissions': permissions,
    });
  }

  /// Ajuste les permissions d'un administrateur déjà en place — strictement
  /// créateur-only côté serveur (Phase 2, 2026-08-31), voir
  /// `gerer_participant_dossier` action `definirPermissionsAdministrateur`.
  Future<void> definirPermissionsAdministrateur({
    required String dossierId,
    required String uid,
    required List<String> permissions,
  }) {
    return FirebaseFunctions.instance.httpsCallable('gerer_participant_dossier').call({
      'action': 'definirPermissionsAdministrateur',
      'dossierId': dossierId,
      'uid': uid,
      'permissions': permissions,
    });
  }
}
