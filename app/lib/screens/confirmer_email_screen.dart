import 'package:flutter/material.dart';
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
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _erreur = 'Entre l\'adresse email utilisée pour demander le lien.');
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
      setState(() => _erreur = 'Ce lien ne correspond pas à cette adresse, ou il a expiré.');
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
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
                const Text(
                  'Confirme ton adresse email pour terminer la connexion.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse email',
                    border: OutlineInputBorder(),
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
                      : const Text('Confirmer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
