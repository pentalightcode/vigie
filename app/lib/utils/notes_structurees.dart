/// Bloc-notes "spécial Vigie" — pas un champ libre générique (risque évident
/// d'y taper une vraie info sensible par réflexe), mais 3 prompts courts qui
/// poussent vers une utilisation professionnelle : ce qui reste à vérifier,
/// ce qu'on attend, et le reste. Inspiré de Notein (cartes de notes),
/// transformé pour coller à l'esprit dossier/confidentialité de Vigie
/// (demandé par Tobie le 2026-08-20 : "pas juste un simple bloc-notes").
///
/// Stocké comme un seul texte formaté (`Tache.notesDetaillees`, pas de
/// migration de schéma) — [analyser] sait relire ce format, et range tout
/// texte non reconnu (notes déjà là, description importée de Google) dans
/// "Autre" plutôt que de le perdre.
class NotesStructurees {
  NotesStructurees({this.resteAVerifier = '', this.enAttenteDe = '', this.autre = ''});

  final String resteAVerifier;
  final String enAttenteDe;
  final String autre;

  bool get estVide => resteAVerifier.isEmpty && enAttenteDe.isEmpty && autre.isEmpty;

  static const _prefixeReste = 'Reste à vérifier : ';
  static const _prefixeAttente = 'En attente de : ';
  static const _prefixeAutre = 'Autre : ';

  String formater() {
    final lignes = <String>[];
    if (resteAVerifier.isNotEmpty) lignes.add('$_prefixeReste$resteAVerifier');
    if (enAttenteDe.isNotEmpty) lignes.add('$_prefixeAttente$enAttenteDe');
    if (autre.isNotEmpty) lignes.add('$_prefixeAutre$autre');
    return lignes.join('\n');
  }

  factory NotesStructurees.analyser(String? texte) {
    if (texte == null || texte.trim().isEmpty) return NotesStructurees();

    String? reste, attente, autre;
    for (final ligne in texte.split('\n')) {
      if (ligne.startsWith(_prefixeReste)) {
        reste = ligne.substring(_prefixeReste.length);
      } else if (ligne.startsWith(_prefixeAttente)) {
        attente = ligne.substring(_prefixeAttente.length);
      } else if (ligne.startsWith(_prefixeAutre)) {
        autre = ligne.substring(_prefixeAutre.length);
      }
    }
    // Format non reconnu (texte importé, ou ancien format libre) : préservé
    // tel quel dans "Autre" plutôt que perdu.
    if (reste == null && attente == null && autre == null) {
      return NotesStructurees(autre: texte);
    }
    return NotesStructurees(resteAVerifier: reste ?? '', enAttenteDe: attente ?? '', autre: autre ?? '');
  }
}
