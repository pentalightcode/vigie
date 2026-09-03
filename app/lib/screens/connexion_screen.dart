import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/version_service.dart';
import '../utils/telechargement.dart';

/// Écran affiché quand personne n'est connecté : demande l'email
/// et envoie le lien magique.
class ConnexionScreen extends StatefulWidget {
  const ConnexionScreen({super.key});

  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen> {
  final _emailController = TextEditingController();
  bool _envoiEnCours = false;
  bool _lienEnvoye = false;
  String? _erreur;
  String? _versionDisponible;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      VersionService.instance.derniereVersionPubliee().then((v) {
        if (mounted) setState(() => _versionDisponible = v);
      });
    }
  }

  Future<void> _envoyerLien() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _erreur = l10n.connexionErreurEmailInvalide);
      return;
    }
    setState(() {
      _envoiEnCours = true;
      _erreur = null;
    });
    try {
      await AuthService.instance.envoyerLienDeConnexion(email);
      setState(() => _lienEnvoye = true);
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG erreur envoi lien: $e');
      setState(() => _erreur = l10n.connexionErreurEnvoiLien);
    } finally {
      setState(() => _envoiEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: _lienEnvoye ? _vueAttente() : _vueSaisieEmail(),
          ),
        ),
      ),
    );
  }

  Widget _vueSaisieEmail() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Vigie',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (kIsWeb) ...[
          const SizedBox(height: 20),
          if (defaultTargetPlatform == TargetPlatform.iOS) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.apple, size: 32, color: Colors.blue.shade900),
                  const SizedBox(height: 8),
                  Text(
                    l10n.connexionInstructionsIosTitre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.connexionInstructionsIos,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blue.shade900, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
          ] else ...[
            FilledButton.icon(
              onPressed: _telechargerApk,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.android),
              label: Text(
                _versionDisponible != null
                    ? l10n.connexionTelechargerAvecVersion(_versionDisponible!)
                    : l10n.connexionTelechargerSansVersion,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.connexionVersionInstalleeMeilleure,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Divider(),
          ],
        ],
        const SizedBox(height: 8),
        Text(
          l10n.connexionInstructions,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
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
          onPressed: _envoiEnCours ? null : _envoyerLien,
          child: _envoiEnCours
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.connexionRecevoirLienBouton),
        ),
      ],
    );
  }

  void _telechargerApk() {
    // Technique standard du web (lien "download" cliqué par le code) —
    // url_launcher échouait silencieusement pour ce cas précis (2026-08-15,
    // deux tentatives infructueuses). Cette méthode est celle utilisée par
    // la quasi-totalité des boutons "télécharger" sur le web, justement
    // parce qu'elle ne dépend d'aucun mécanisme pouvant être bloqué.
    final url = Uri.base.resolve('telecharger/Vigie.apk').toString();
    declencherTelechargementFichier(url);
  }

  Widget _vueAttente() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 64),
        const SizedBox(height: 16),
        Text(
          l10n.connexionLienEnvoye(_emailController.text.trim()),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _lienEnvoye = false),
          child: Text(l10n.connexionMauvaiseAdresse),
        ),
      ],
    );
  }
}
