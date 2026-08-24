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
  });

  final String id;
  final String corps;
  final String? dossierId;
  final Map<String, int> parType;
  final DateTime? envoyeLe;

  factory NotificationEnvoyee.depuisDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final parTypeBrut = (data['parType'] as Map<String, dynamic>?) ?? {};
    return NotificationEnvoyee(
      id: doc.id,
      corps: data['corps'] as String? ?? '',
      dossierId: data['dossierId'] as String?,
      parType: parTypeBrut.map((cle, valeur) => MapEntry(cle, (valeur as num).toInt())),
      envoyeLe: (data['envoyeLe'] as Timestamp?)?.toDate(),
    );
  }
}
