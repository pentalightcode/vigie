import 'package:flutter/material.dart';

/// Demande une confirmation en deux étapes successives (décidé avec Tobie :
/// fixe pour tout le monde, pour les actions à risque — marquer fait,
/// supprimer, se déconnecter...). Renvoie true seulement si les deux
/// étapes ont été confirmées.
Future<bool> demanderDoubleConfirmation(
  BuildContext context, {
  required String titre,
  required String message,
  String texteBouton = 'Confirmer',
  bool destructif = false,
}) async {
  final premiereConfirmation = await _dialogue(context, titre, message, texteBouton, destructif);
  if (premiereConfirmation != true) return false;
  if (!context.mounted) return false;

  final secondeConfirmation = await _dialogue(
    context,
    'Tu es sûr ?',
    'Dernière confirmation : $message',
    texteBouton,
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
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
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
