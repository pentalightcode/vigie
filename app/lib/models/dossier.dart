import 'package:cloud_firestore/cloud_firestore.dart';

/// Un dossier (affaire, réunion ou rendez-vous), désigné par un nom de code
/// choisi par le père — jamais le vrai nom des parties ou la nature de l'affaire.
class Dossier {
  Dossier({
    required this.id,
    required this.uid,
    required this.nomCode,
    this.dateEvenement,
    this.notePrivee,
  });

  final String id;
  final String uid;
  final String nomCode;
  final DateTime? dateEvenement; // date de l'audience, du rendez-vous, etc.
  final String? notePrivee; // chiffré côté téléphone avant écriture (à venir)

  factory Dossier.depuisDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Dossier(
      id: doc.id,
      uid: data['uid'] as String,
      nomCode: data['nomCode'] as String,
      dateEvenement: (data['dateEvenement'] as Timestamp?)?.toDate(),
      notePrivee: data['notePrivee'] as String?,
    );
  }

  Map<String, dynamic> versDocument() {
    return {
      'uid': uid,
      'nomCode': nomCode,
      'dateEvenement': dateEvenement != null ? Timestamp.fromDate(dateEvenement!) : null,
      'notePrivee': notePrivee,
      'creeLe': FieldValue.serverTimestamp(),
    };
  }

  Dossier copierAvec({String? nomCode, DateTime? dateEvenement, bool effacerDate = false}) {
    return Dossier(
      id: id,
      uid: uid,
      nomCode: nomCode ?? this.nomCode,
      dateEvenement: effacerDate ? null : (dateEvenement ?? this.dateEvenement),
      notePrivee: notePrivee,
    );
  }
}
