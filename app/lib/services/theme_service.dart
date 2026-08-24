import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Couleurs d'accent proposées — un choix restreint et cohérent plutôt
/// qu'une roue de couleurs libre (plus simple à choisir, garantit un rendu
/// propre avec Material 3 quel que soit le choix).
const couleursTheme = <String, Color>{
  'Indigo': Colors.indigo,
  'Bleu': Colors.blue,
  'Sarcelle': Colors.teal,
  'Vert': Colors.green,
  'Violet': Colors.deepPurple,
  'Orange': Colors.deepOrange,
};

/// Thème personnalisable (demandé par Tobie le 2026-08-20 : "donner la
/// possibilité à l'utilisateur de choisir une variété de thèmes"). Préférence
/// locale à l'appareil (SharedPreferences) — un réglage d'affichage, pas une
/// donnée à synchroniser entre appareils.
class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const _cleCouleur = 'theme_couleur';
  static const _cleMode = 'theme_mode';

  final ValueNotifier<Color> couleur = ValueNotifier(Colors.indigo);
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    final nomCouleur = prefs.getString(_cleCouleur);
    if (nomCouleur != null && couleursTheme.containsKey(nomCouleur)) {
      couleur.value = couleursTheme[nomCouleur]!;
    }
    final nomMode = prefs.getString(_cleMode);
    mode.value = switch (nomMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> definirCouleur(String nom) async {
    final c = couleursTheme[nom];
    if (c == null) return;
    couleur.value = c;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cleCouleur, nom);
  }

  Future<void> definirMode(ThemeMode nouveauMode) async {
    mode.value = nouveauMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cleMode, nouveauMode.name);
  }
}
