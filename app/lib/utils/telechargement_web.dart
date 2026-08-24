import 'dart:html' as html;

/// Déclenche un téléchargement de fichier via la technique standard du web
/// (lien avec l'attribut "download", cliqué par le code) — plus fiable que
/// url_launcher pour un fichier du même site : aucun nouvel onglet, aucun
/// mécanisme pouvant être bloqué par un anti-popup (trouvé le 2026-08-15,
/// url_launcher échouait silencieusement pour ce cas précis).
Future<void> declencherTelechargementFichier(String url) async {
  final ancre = html.AnchorElement(href: url)
    ..download = ''
    ..target = '_self';
  html.document.body?.append(ancre);
  ancre.click();
  ancre.remove();
}
