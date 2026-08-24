const _moisFr = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

/// Formate une date en "5 août" sans dépendre de l'initialisation des
/// données de locale d'intl (pas nécessaire pour un affichage aussi simple).
String formaterDateFr(DateTime date) => '${date.day} ${_moisFr[date.month - 1]}';

/// Idem, avec l'heure : "5 août à 07h05".
String formaterDateHeureFr(DateTime date) {
  final heure = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${formaterDateFr(date)} à ${heure}h$minute';
}
