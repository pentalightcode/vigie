import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Affiche une bannière explicative sur iOS (Safari Web) pour indiquer
/// comment installer la PWA. La bannière peut être masquée définitivement.
class BanniereInstallationIos extends StatefulWidget {
  const BanniereInstallationIos({super.key});

  @override
  State<BanniereInstallationIos> createState() => _BanniereInstallationIosState();
}

class _BanniereInstallationIosState extends State<BanniereInstallationIos> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _verifierEligibilite();
  }

  Future<void> _verifierEligibilite() async {
    // S'affiche uniquement si on est sur le Web et que l'appareil est sous iOS.
    if (!kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

    final prefs = await SharedPreferences.getInstance();
    final masque = prefs.getBool('ios_install_prompt_masque') ?? false;

    if (!masque && mounted) {
      setState(() => _visible = true);
    }
  }

  Future<void> _masquer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ios_install_prompt_masque', true);
    if (mounted) {
      setState(() => _visible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(Icons.apple, color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pour installer l\'application, appuyez sur l\'icône de partage en bas de l\'écran, puis sur "Sur l\'écran d\'accueil".',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _masquer,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                tooltip: 'Masquer',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
