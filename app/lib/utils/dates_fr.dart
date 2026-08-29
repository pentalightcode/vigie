import 'dart:ui';

import 'package:intl/intl.dart';

import '../services/locale_service.dart';

/// Langue active pour le formatage : le choix explicite de l'utilisateur
/// (LocaleService) s'il existe, sinon la langue de l'appareil si elle est
/// supportée — même règle de résolution que celle appliquée par le
/// MaterialApp racine pour `supportedLocales`.
String _codeLangueActif() {
  final explicite = LocaleService.instance.locale.value?.languageCode;
  if (explicite != null) return explicite;
  return PlatformDispatcher.instance.locale.languageCode == 'en' ? 'en' : 'fr';
}

/// Formate une date en "5 août" (ou "Aug 5" en anglais) via les données de
/// locale d'intl, initialisées au démarrage pour fr_FR et en_US.
String formaterDateFr(DateTime date) => DateFormat.MMMd(_codeLangueActif() == 'en' ? 'en_US' : 'fr_FR').format(date);

/// Idem, avec l'heure : "5 août à 07h05" (ou "Aug 5 at 07:05" en anglais).
String formaterDateHeureFr(DateTime date) {
  final heure = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final estFrancais = _codeLangueActif() != 'en';
  final heureTexte = estFrancais ? '${heure}h$minute' : '$heure:$minute';
  final connecteur = estFrancais ? 'à' : 'at';
  return '${formaterDateFr(date)} $connecteur $heureTexte';
}
