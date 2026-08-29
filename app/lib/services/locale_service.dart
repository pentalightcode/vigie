import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Choix de langue (français/anglais) — préférence locale à l'appareil
/// (SharedPreferences), suit le même schéma que ThemeService : un
/// ValueNotifier écouté par le MaterialApp racine pour se reconstruire
/// immédiatement, sans redémarrage de l'app.
class LocaleService {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  static const _cleLangue = 'locale_langue';

  final ValueNotifier<Locale?> locale = ValueNotifier(null);

  Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_cleLangue);
    if (code != null) {
      locale.value = Locale(code);
    }
  }

  Future<void> definirLangue(String? codeLangue) async {
    locale.value = codeLangue == null ? null : Locale(codeLangue);
    final prefs = await SharedPreferences.getInstance();
    if (codeLangue == null) {
      await prefs.remove(_cleLangue);
    } else {
      await prefs.setString(_cleLangue, codeLangue);
    }
  }
}
