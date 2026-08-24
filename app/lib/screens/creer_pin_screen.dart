import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final pin = _pinController.text;
    final confirmation = _confirmationController.text;

    if (pin.length < 4) {
      setState(() => _erreur = 'Le code doit faire au moins 4 chiffres.');
      return;
    }
    if (pin != confirmation) {
      setState(() => _erreur = 'Les deux codes ne correspondent pas.');
      return;
    }

    await LockService.instance.definirPin(pin);
    widget.onPinDefini();
  }

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Crée un code PIN pour protéger l\'app.\nÀ chaque ouverture, ce code (ou ton empreinte/Face ID) sera demandé.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Nouveau code PIN',
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Retape le code',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 8),
                  Text(_erreur!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                FilledButton(onPressed: _valider, child: const Text('Valider')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
