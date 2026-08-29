import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Demande une confirmation en deux étapes successives (décidé avec Tobie :
/// fixe pour tout le monde, pour les actions à risque — marquer fait,
/// supprimer, se déconnecter...). Renvoie true seulement si les deux
/// étapes ont été confirmées.
Future<bool> demanderDoubleConfirmation(
  BuildContext context, {
  required String titre,
  required String message,
  String? texteBouton,
  bool destructif = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final bouton = texteBouton ?? l10n.commonConfirmer;
  final premiereConfirmation = await _dialogue(context, titre, message, bouton, destructif);
  if (premiereConfirmation != true) return false;
  if (!context.mounted) return false;

  final secondeConfirmation = await _dialogue(
    context,
    l10n.commonTuEsSur,
    l10n.commonDerniereConfirmation(message),
    bouton,
    destructif,
  );
  return secondeConfirmation == true;
}

Future<bool?> _dialogue(
  BuildContext context,
  String titre,
  String message,
  String texteBouton,
  bool destructif,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titre),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppLocalizations.of(context)!.commonAnnuler),
        ),
        destructif
            ? FilledButton.tonal(
                style: FilledButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: Text(texteBouton),
              )
            : FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(texteBouton)),
      ],
    ),
  );
}
