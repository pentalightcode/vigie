import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/dossier.dart';

/// Contenu de corps affiché à la place d'un écran de dossier quand le flux
/// Firestore sous-jacent renvoie une erreur plutôt que de nouvelles données —
/// sans ce garde-fou, Flutter efface silencieusement les dernières données
/// reçues et l'écran reste bloqué sur un indicateur de chargement infini,
/// sans aucune explication. Ne contient PAS son propre `Scaffold` : à
/// utiliser comme `body:` d'un `Scaffold` déjà existant.
///
/// Scénario devenu possible avec la Phase 1 "travail de groupe" (trouvé en
/// Red Team le 2026-08-30) : avant, un dossier appartenait pour toujours à
/// son unique propriétaire — perdre l'accès à SON PROPRE dossier en cours de
/// consultation ne pouvait pas arriver. Maintenant qu'un administrateur peut
/// retirer un participant en direct, quelqu'un peut se retrouver ici pendant
/// qu'il regarde encore l'écran.
///
/// [erreur] distingue un vrai retrait (`FirebaseException` avec le code
/// `permission-denied`) d'une erreur transitoire — panne réseau, déconnexion
/// momentanée (trouvé en re-vérifiant ce correctif, via /code-review, le
/// 2026-08-31) : sans cette distinction, un simple accroc réseau (l'app
/// cible des connexions mobiles pas toujours fiables) affichait faussement
/// "tu n'as plus accès à ce dossier" à quelqu'un qui n'a en réalité rien
/// perdu — message alarmant et faux.
class VueAccesRevoque extends StatelessWidget {
  const VueAccesRevoque({super.key, this.erreur});

  final Object? erreur;

  bool get _revocationConfirmee {
    final e = erreur;
    // Dossier supprimé (pas seulement un retrait d'accès) : `doc.exists`
    // faux, `Dossier.depuisDocument` lève ceci plutôt qu'un TypeError sur un
    // cast null — traité comme "plus disponible" au même titre qu'un vrai
    // retrait, la distinction n'a pas d'importance pour l'utilisateur
    // (trouvé en re-vérifiant ce correctif, via /code-review, le 2026-08-31).
    return (e is FirebaseException && e.code == 'permission-denied') || e is DossierIntrouvableException;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final revocationConfirmee = _revocationConfirmee;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              revocationConfirmee ? Icons.lock_outline : Icons.wifi_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              revocationConfirmee ? l10n.dossierAccesRevoqueMessage : l10n.dossierErreurChargementMessage,
              textAlign: TextAlign.center,
            ),
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
