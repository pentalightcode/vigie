import 'package:url_launcher/url_launcher.dart';

/// Version utilisée hors web (Android/iOS) : ouvre le lien dans le
/// navigateur externe de l'appareil (le mode "externalApplication" est
/// l'équivalent natif de l'intent Android standard — sans lien avec le bug
/// url_launcher rencontré sur le web le 2026-08-15, qui était spécifique à
/// l'ouverture d'un nouvel onglet depuis du code async côté navigateur).
/// L'utilisateur télécharge alors l'APK normalement, comme n'importe quel
/// fichier, puis l'installe en l'ouvrant depuis ses téléchargements.
Future<void> declencherTelechargementFichier(String url) async {
  // launchUrl ne lève pas toujours d'exception en cas d'échec : il peut
  // simplement renvoyer false (aucun gestionnaire trouvé pour ouvrir le
  // lien) — sans vérifier cette valeur, l'échec passait inaperçu, sans
  // aucune erreur à afficher à l'utilisateur (trouvé le 2026-08-17, testé
  // en conditions réelles sur le téléphone du père : ni message d'erreur,
  // ni navigateur ouvert, ni notification de téléchargement).
  final ouvert = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ouvert) {
    throw StateError('Aucune application capable d\'ouvrir ce lien n\'a été trouvée.');
  }
}
