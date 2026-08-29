import 'package:cloud_firestore/cloud_firestore.dart';
import 'profession.dart';

class ReglagesUtilisateur {
  ReglagesUtilisateur({
    required this.onboardingTermine,
    required this.nom,
    required this.pseudo,
    required this.profession,
    required this.professionPersonnalisee,
    required this.delaiRappelJours,
    required this.methodeExtraction,
    required this.expediteursConfiance,
    required this.bilanIaActif,
  });

  final bool onboardingTermine;
  final String? nom;
  final String? pseudo;
  final Profession? profession;
  /// Renseigné seulement si `profession == Profession.autre` : le nom que
  /// l'utilisateur a lui-même donné à son métier (correction demandée par
  /// Tobie : toutes les professions ne peuvent pas être listées à l'avance).
  final String? professionPersonnalisee;
  final int delaiRappelJours;

  /// "motif" (recherche de motif, gratuite, par défaut) ou "ia" (payant,
  /// avertissement affiché avant activation — décision du 2026-08-15).
  final String methodeExtraction;
  /// Adresses dont on lit les emails pour l'automatisation — jamais toute la boîte.
  final List<String> expediteursConfiance;
  /// Résumé + recommandations du Bilan via IA (Groq) — désactivé par défaut,
  /// même principe que le chemin IA pour l'extraction Gmail (avertissement
  /// avant activation, décision du 2026-08-15).
  final bool bilanIaActif;

  factory ReglagesUtilisateur.depuisDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final professionTexte = data['profession'] as String?;
    return ReglagesUtilisateur(
      onboardingTermine: data['onboardingTermine'] as bool? ?? false,
      nom: data['nom'] as String?,
      pseudo: data['pseudo'] as String?,
      profession: professionTexte == null
          ? null
          : Profession.values.firstWhere((p) => p.name == professionTexte, orElse: () => Profession.autre),
      professionPersonnalisee: data['professionPersonnalisee'] as String?,
      delaiRappelJours: data['delaiRappelJours'] as int? ?? 14,
      methodeExtraction: data['methodeExtraction'] as String? ?? 'motif',
      expediteursConfiance: (data['expediteursConfiance'] as List<dynamic>?)?.cast<String>() ?? [],
      bilanIaActif: data['bilanIaActif'] as bool? ?? false,
    );
  }
}
