import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Modèle d'une invitation à rejoindre un dossier partagé (Phase 2,
/// 2026-09-03). Stockée dans utilisateurs/{uid}/invitations/{dossierId}.
class InvitationDossier {
  const InvitationDossier({
    required this.dossierId,
    required this.nomCodeDossier,
    required this.role,
    required this.permissions,
    required this.inviteParEmail,
  });

  final String dossierId;
  final String nomCodeDossier;
  final String role;
  final List<String> permissions;
  final String inviteParEmail;

  factory InvitationDossier.depuisFirestore(String id, Map<String, dynamic> data) {
    return InvitationDossier(
      dossierId: id,
      nomCodeDossier: data['nomCodeDossier'] as String? ?? 'Dossier',
      role: data['role'] as String? ?? 'contributeur',
      permissions: List<String>.from(data['permissions'] as List? ?? []),
      inviteParEmail: data['inviteParEmail'] as String? ?? '',
    );
  }
}

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

  /// Flux des invitations en attente pour l'utilisateur courant (Phase 2,
  /// 2026-09-03). Écoute la sous-collection Firestore en temps réel.
  Stream<List<InvitationDossier>> invitations() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(uid)
        .collection('invitations')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => InvitationDossier.depuisFirestore(d.id, d.data()))
            .toList());
  }

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

  Future<void> annulerInvitation({
    required String dossierId,
    required String email,
  }) {
    return FirebaseFunctions.instance.httpsCallable('annuler_invitation_dossier').call({
      'dossierId': dossierId,
      'email': email,
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

  /// Répondre à une invitation (Phase 2, 2026-09-03).
  /// [reponse] : 'accepter' | 'refuser'
  Future<void> repondreInvitation({
    required String dossierId,
    required String reponse,
  }) {
    return FirebaseFunctions.instance.httpsCallable('repondre_invitation').call({
      'dossierId': dossierId,
      'reponse': reponse,
    });
  }
}
