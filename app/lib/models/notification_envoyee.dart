import 'package:cloud_firestore/cloud_firestore.dart';

/// Un rappel déjà envoyé par le digest quotidien (matin/soir), tel
/// qu'enregistré côté serveur — sert à l'écran "Notifications" pour
/// consulter l'historique une fois la notification système disparue.
class NotificationEnvoyee {
  NotificationEnvoyee({
    required this.id,
    required this.corps,
    required this.dossierId,
    required this.parType,
    required this.envoyeLe,
    this.type = 'digest',
  });

  final String id;
  final String corps;
  final String? dossierId;
  final Map<String, int> parType;
  final DateTime? envoyeLe;

  /// Phase 2 (2026-08-31) : distingue le rappel quotidien ('digest', valeur
  /// par défaut — absent sur toute notification écrite avant cette date, même
  /// convention de repli que le reste de ce fichier) d'un événement de
  /// collaboration ('participantAjoute' | 'participantRetire' | 'roleModifie'
  /// | 'ajoutParAdministrateur' | 'propositionCreee' | 'propositionResolue',
  /// voir functions/main.py `_notifier_evenement`) — sert à choisir l'icône/
  /// le filtre adaptés à l'écran Notifications.
  final String type;

  factory NotificationEnvoyee.depuisDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final parTypeBrut = (data['parType'] as Map<String, dynamic>?) ?? {};
    return NotificationEnvoyee(
      id: doc.id,
      corps: data['corps'] as String? ?? '',
      dossierId: data['dossierId'] as String?,
      parType: parTypeBrut.map((cle, valeur) => MapEntry(cle, (valeur as num).toInt())),
      envoyeLe: (data['envoyeLe'] as Timestamp?)?.toDate(),
      type: data['type'] as String? ?? 'digest',
    );
  }
}
