/// Un événement Google Calendar tel qu'affiché dans l'écran Agenda (lecture
/// seule, en direct — distinct des Propositions créées par
/// scanner_calendrier_google, qui elles attendent une validation).
class EvenementCalendrier {
  EvenementCalendrier({
    required this.titre,
    required this.date,
    required this.journeeEntiere,
    this.description = '',
  });

  final String titre;
  final DateTime date;
  final bool journeeEntiere;
  final String description;

  factory EvenementCalendrier.depuisJson(Map<String, dynamic> json) {
    return EvenementCalendrier(
      titre: json['titre'] as String? ?? '(sans titre)',
      date: DateTime.parse(json['date'] as String),
      journeeEntiere: json['journeeEntiere'] as bool? ?? true,
      description: json['description'] as String? ?? '',
    );
  }
}
