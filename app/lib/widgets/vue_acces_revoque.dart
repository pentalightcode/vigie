import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Contenu de corps affiché à la place d'un écran de dossier quand le flux
/// Firestore sous-jacent renvoie une erreur (accès révoqué) plutôt que de
/// nouvelles données — sans ce garde-fou, Flutter efface silencieusement les
/// dernières données reçues et l'écran reste bloqué sur un indicateur de
/// chargement infini, sans aucune explication. Ne contient PAS son propre
/// `Scaffold` : à utiliser comme `body:` d'un `Scaffold` déjà existant.
///
/// Scénario devenu possible avec la Phase 1 "travail de groupe" (trouvé en
/// Red Team le 2026-08-30) : avant, un dossier appartenait pour toujours à
/// son unique propriétaire — perdre l'accès à SON PROPRE dossier en cours de
/// consultation ne pouvait pas arriver. Maintenant qu'un administrateur peut
/// retirer un participant en direct, quelqu'un peut se retrouver ici pendant
/// qu'il regarde encore l'écran.
class VueAccesRevoque extends StatelessWidget {
  const VueAccesRevoque({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(l10n.dossierAccesRevoqueMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.commonFermer),
            ),
          ],
        ),
      ),
    );
  }
}
