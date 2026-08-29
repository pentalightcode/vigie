import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

/// Affiché quand le lien magique est ouvert sur un appareil/navigateur
/// différent de celui où il a été demandé : on ne connaît pas l'email
/// automatiquement, on le redemande une seule fois pour confirmer.
class ConfirmerEmailScreen extends StatefulWidget {
  const ConfirmerEmailScreen({super.key, required this.lien, required this.onConnecte});

  final String lien;
  final VoidCallback onConnecte;

  @override
  State<ConfirmerEmailScreen> createState() => _ConfirmerEmailScreenState();
}

class _ConfirmerEmailScreenState extends State<ConfirmerEmailScreen> {
  final _emailController = TextEditingController();
  bool _enCours = false;
  String? _erreur;

  Future<void> _confirmer() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _erreur = l10n.confirmerEmailErreurVide);
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await AuthService.instance.terminerConnexionAvecLienEtEmail(widget.lien, email);
      widget.onConnecte();
    } catch (e) {
      setState(() => _erreur = l10n.confirmerEmailErreurLienInvalide);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
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
                Text(
                  l10n.confirmerEmailInstructions,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.connexionChampEmail,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 8),
                  Text(_erreur!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _enCours ? null : _confirmer,
                  child: _enCours
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.confirmerEmailBouton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
