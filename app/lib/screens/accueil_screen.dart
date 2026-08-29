import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

const _clePrefsAccueilVu = 'accueil_vu';

/// True si l'utilisateur a déjà vu ou passé cette présentation — pour ne
/// jamais la réafficher à quelqu'un qui revient se connecter (ex: après
/// déconnexion), seulement à la toute première ouverture de l'app.
Future<bool> accueilDejaVu() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_clePrefsAccueilVu) ?? false;
}

Future<void> _marquerAccueilVu() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_clePrefsAccueilVu, true);
}

/// Présentation de Vigie affichée avant l'écran de connexion, uniquement à
/// la première ouverture — demandé par Tobie le 2026-08-29 : arriver
/// directement sur le champ email sans aucune explication de ce qu'est
/// l'app donnait une mauvaise première impression, sur le web comme dans
/// l'app (même écran des deux côtés).
class AccueilScreen extends StatefulWidget {
  const AccueilScreen({super.key, required this.onTermine});

  final VoidCallback onTermine;

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  final _controleur = PageController();
  int _page = 0;
  static const _nombreDePages = 4;

  Future<void> _terminer() async {
    await _marquerAccueilVu();
    widget.onTermine();
  }

  void _pageSuivante() {
    _controleur.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final derniere = _page == _nombreDePages - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: derniere
                    ? null
                    : TextButton(onPressed: _terminer, child: Text(l10n.accueilBoutonPasser)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controleur,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _pageHero(l10n),
                  _pageFonctionnalite(icone: Icons.add_circle_outline, titre: l10n.accueilPage2Titre, texte: l10n.accueilPage2Texte),
                  _pageFonctionnalite(icone: Icons.notifications_active_outlined, titre: l10n.accueilPage3Titre, texte: l10n.accueilPage3Texte),
                  _pageFinale(l10n),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_nombreDePages, (i) {
                  final actif = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: actif ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: actif ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: derniere ? _terminer : _pageSuivante,
                  child: Text(derniere ? l10n.accueilBoutonSeConnecter : l10n.accueilBoutonSuivant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageHero(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset('assets/images/logo.png', width: 96, height: 96),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.accueilPage1Titre,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.accueilPage1Texte,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _pageFonctionnalite({required IconData icone, required String titre, required String texte}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            titre,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            texte,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _pageFinale(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fact_check_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            l10n.accueilPage4Titre,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.accueilPage4Texte,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 20, color: Theme.of(context).colorScheme.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.accueilConfidentialiteNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
