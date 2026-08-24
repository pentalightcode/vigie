import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _erreur = 'Entre une adresse email valide.');
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
      setState(() => _erreur = 'Impossible d\'envoyer le lien. Vérifie ta connexion.');
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
          FilledButton.icon(
            onPressed: _telechargerApk,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.android),
            label: Text(
              _versionDisponible != null
                  ? 'Télécharger l\'app Android (v$_versionDisponible)'
                  : 'Télécharger l\'app Android (recommandé)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'La version installée fonctionne mieux que le site (notifications, Gmail...).',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Divider(),
        ],
        const SizedBox(height: 8),
        const Text(
          'Entre ton adresse email, tu recevras un lien de connexion — pas besoin de mot de passe.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
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
          onPressed: _envoiEnCours ? null : _envoyerLien,
          child: _envoiEnCours
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Recevoir le lien de connexion'),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 64),
        const SizedBox(height: 16),
        Text(
          'Un lien a été envoyé à ${_emailController.text.trim()}.\nOuvre ta boîte mail et clique sur le lien pour te connecter.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _lienEnvoye = false),
          child: const Text('Mauvaise adresse ? Recommencer'),
        ),
      ],
    );
  }
}
