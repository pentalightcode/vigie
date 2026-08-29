import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/lock_service.dart';

/// Première ouverture : demande de créer un code PIN pour verrouiller l'app.
class CreerPinScreen extends StatefulWidget {
  const CreerPinScreen({super.key, required this.onPinDefini});

  final VoidCallback onPinDefini;

  @override
  State<CreerPinScreen> createState() => _CreerPinScreenState();
}

class _CreerPinScreenState extends State<CreerPinScreen> {
  final _pinController = TextEditingController();
  final _confirmationController = TextEditingController();
  String? _erreur;

  Future<void> _valider() async {
    final l10n = AppLocalizations.of(context)!;
    final pin = _pinController.text;
    final confirmation = _confirmationController.text;

    if (pin.length < 4) {
      setState(() => _erreur = l10n.creerPinErreurTropCourt);
      return;
    }
    if (pin != confirmation) {
      setState(() => _erreur = l10n.creerPinErreurNeCorrespondentPas);
      return;
    }

    await LockService.instance.definirPin(pin);
    widget.onPinDefini();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  l10n.creerPinInstructions,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: l10n.creerPinChampNouveauCode,
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmationController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: l10n.creerPinChampRetaperCode,
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 8),
                  Text(_erreur!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                FilledButton(onPressed: _valider, child: Text(l10n.creerPinBoutonValider)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
