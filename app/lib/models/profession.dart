/// Top 12 professions les plus courantes, tous secteurs confondus — pas
/// seulement le droit (correction demandée par Tobie : l'app ne doit pas
/// sembler réservée aux juristes).
enum Profession {
  medecin,
  enseignant,
  avocatJuriste,
  magistrat,
  comptable,
  consultant,
  commercial,
  architecteIngenieur,
  agentImmobilier,
  artisanBatiment,
  beauteBienEtre,
  entrepreneur,
  autre,
}

extension ProfessionLabel on Profession {
  String get libelle => switch (this) {
        Profession.medecin => 'Médecin / Professionnel de santé',
        Profession.enseignant => 'Enseignant / Professeur',
        Profession.avocatJuriste => 'Avocat / Juriste',
        Profession.magistrat => 'Magistrat',
        Profession.comptable => 'Comptable / Expert-comptable',
        Profession.consultant => 'Consultant / Indépendant',
        Profession.commercial => 'Commercial / Chargé de clientèle',
        Profession.architecteIngenieur => 'Architecte / Ingénieur',
        Profession.agentImmobilier => 'Agent immobilier',
        Profession.artisanBatiment => 'Artisan / Entrepreneur du bâtiment',
        Profession.beauteBienEtre => 'Coiffeur / Esthéticienne / Bien-être',
        Profession.entrepreneur => 'Entrepreneur / Chef d\'entreprise',
        Profession.autre => 'Autre',
      };
}

/// Un type de dossier "de départ", proposé selon la profession choisie à
/// l'inscription. Toutes les natures suivent le même délai de rappel choisi
/// par l'utilisateur (ex: 14 jours avant une audience) — aucune exception.
typedef NatureDeDepart = ({String nom});

const _naturesCommunes = <NatureDeDepart>[
  (nom: 'Courrier',),
  (nom: 'Autre',),
];

Map<Profession, List<NatureDeDepart>> _naturesParProfession = {
  Profession.magistrat: [
    (nom: 'Audience',),
    (nom: 'Réunion / Rendez-vous',),
    ..._naturesCommunes,
  ],
  Profession.avocatJuriste: [
    (nom: 'Audience',),
    (nom: 'Rendez-vous client',),
    ..._naturesCommunes,
  ],
  Profession.medecin: [
    (nom: 'Consultation',),
    (nom: 'Suivi patient',),
    ..._naturesCommunes,
  ],
  Profession.enseignant: [
    (nom: 'Séance à préparer',),
    (nom: 'Copies à corriger',),
    ..._naturesCommunes,
  ],
  Profession.comptable: [
    (nom: 'Déclaration à préparer',),
    (nom: 'Rendez-vous client',),
    ..._naturesCommunes,
  ],
  Profession.consultant: [
    (nom: 'Mission client',),
    (nom: 'Rendez-vous',),
    ..._naturesCommunes,
  ],
  Profession.commercial: [
    (nom: 'Rendez-vous client',),
    (nom: 'Relance prospect',),
    ..._naturesCommunes,
  ],
  Profession.architecteIngenieur: [
    (nom: 'Rendez-vous chantier',),
    (nom: 'Livrable à préparer',),
    ..._naturesCommunes,
  ],
  Profession.agentImmobilier: [
    (nom: 'Visite',),
    (nom: 'Rendez-vous client',),
    ..._naturesCommunes,
  ],
  Profession.artisanBatiment: [
    (nom: 'Chantier',),
    (nom: 'Devis à préparer',),
    ..._naturesCommunes,
  ],
  Profession.beauteBienEtre: [
    (nom: 'Rendez-vous client',),
    ..._naturesCommunes,
  ],
  Profession.entrepreneur: [
    (nom: 'Rendez-vous',),
    (nom: 'Échéance administrative',),
    ..._naturesCommunes,
  ],
  Profession.autre: [
    (nom: 'Réunion / Rendez-vous',),
    ..._naturesCommunes,
  ],
};

List<NatureDeDepart> naturesDeDepartPour(Profession profession) =>
    _naturesParProfession[profession] ?? _naturesParProfession[Profession.autre]!;
