import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/connexion_google.dart';
import '../models/profession.dart';
import '../models/reglages_utilisateur.dart';
import '../services/auth_service.dart';
import '../services/gmail_service.dart';
import '../services/locale_service.dart';
import '../services/theme_service.dart';
import '../services/utilisateur_service.dart';
import '../utils/confirmation.dart';
import 'automatisation_screen.dart';
import 'gestion_natures_sheet.dart';
import 'pourquoi_vigie_screen.dart';

/// Écran Profil — corrige le manque relevé par Tobie : jusqu'ici aucun
/// moyen de modifier son pseudo ou de se déconnecter normalement.
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profilTitre)),
      body: StreamBuilder<ReglagesUtilisateur>(
        stream: UtilisateurService.instance.reglages(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reglages = snapshot.data!;
          final libelleProfession = reglages.profession == Profession.autre &&
                  (reglages.professionPersonnalisee?.isNotEmpty ?? false)
              ? reglages.professionPersonnalisee!
              : reglages.profession?.libelle(context) ?? '';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  leading: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  title: Text(
                    l10n.profilPourquoiVigieTitre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  subtitle: Text(
                    l10n.profilPourquoiVigieSousTitre,
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PourquoiVigieScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.alternate_email),
                title: Text(
                  l10n.profilConnecteEnTantQue(FirebaseAuth.instance.currentUser?.email ?? l10n.profilEmailInconnu),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(reglages.pseudo ?? l10n.profilPseudoNonDefini),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _modifierPseudo(context, reglages.pseudo ?? ''),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.work_outline),
                title: Text(libelleProfession.isEmpty ? l10n.profilProfessionNonDefinie : libelleProfession),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _modifierProfession(
                    context,
                    reglages.profession ?? Profession.autre,
                    reglages.professionPersonnalisee ?? '',
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(l10n.profilDelaiRappelTitre),
                subtitle: Text(l10n.profilDelaiRappelSousTitre(reglages.delaiRappelJours)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _modifierDelai(context, reglages.delaiRappelJours),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(l10n.profilTypesDossierTitre),
                subtitle: Text(l10n.profilTypesDossierSousTitre),
                onTap: () => GestionNaturesSheet.ouvrir(context),
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(l10n.profilThemeTitre),
                subtitle: Text(l10n.profilThemeSousTitre),
                onTap: () => _ouvrirChoixTheme(context),
              ),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(l10n.profilLangueTitre),
                subtitle: Text(l10n.profilLangueSousTitre),
                onTap: () => _ouvrirChoixLangue(context),
              ),
              StreamBuilder<List<ConnexionGoogle>>(
                stream: GmailService.instance.connexionsGoogle(),
                builder: (context, snapshotConnexions) {
                  final connexions = snapshotConnexions.data ?? [];
                  final nombre = connexions.length;
                  return ListTile(
                    leading: const Icon(Icons.auto_awesome_outlined),
                    title: Text(l10n.profilAutomatisationTitre),
                    subtitle: Text(
                      nombre == 0
                          ? l10n.profilAutomatisationAucunCompte
                          : nombre == 1
                              ? l10n.profilAutomatisationUnCompte
                              : l10n.profilAutomatisationDeuxComptes,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AutomatisationScreen()),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(l10n.profilSeDeconnecterTitre),
                onTap: () => _seDeconnecter(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(l10n.profilSupprimerCompteTitre, style: const TextStyle(color: Colors.red)),
                onTap: () => _supprimerCompte(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _modifierPseudo(BuildContext context, String pseudoActuel) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: pseudoActuel);
    final nouveau = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profilModifierPseudoTitre),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: l10n.profilPseudoLabel)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonAnnuler)),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.commonEnregistrer),
          ),
        ],
      ),
    );
    if (nouveau != null && nouveau.isNotEmpty) {
      await UtilisateurService.instance.definirPseudo(nouveau);
    }
  }

  Future<void> _modifierProfession(
    BuildContext context,
    Profession professionActuelle,
    String professionPersonnaliseeActuelle,
  ) async {
    final resultat = await showDialog<(Profession, String)>(
      context: context,
      builder: (context) => _DialogueProfession(
        professionActuelle: professionActuelle,
        professionPersonnaliseeActuelle: professionPersonnaliseeActuelle,
      ),
    );
    if (resultat != null) {
      await UtilisateurService.instance.definirProfession(resultat.$1, professionPersonnalisee: resultat.$2);
    }
  }

  Future<void> _modifierDelai(BuildContext context, int delaiActuel) async {
    final l10n = AppLocalizations.of(context)!;
    final nouveau = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profilDelaiRappelTitre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [7, 14, 21, 30]
              .map((j) => ListTile(
                    title: Text(l10n.joursAvant(j)),
                    trailing: j == delaiActuel ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(context, j),
                  ))
              .toList(),
        ),
      ),
    );
    if (nouveau != null) {
      await UtilisateurService.instance.definirDelaiRappelJours(nouveau);
    }
  }

  Future<void> _seDeconnecter(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirme = await demanderDoubleConfirmation(
      context,
      titre: l10n.profilSeDeconnecterConfirmationTitre,
      message: l10n.profilSeDeconnecterConfirmationMessage,
    );
    if (confirme) {
      await AuthService.instance.seDeconnecter();
    }
  }

  Future<void> _supprimerCompte(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messages = [
      l10n.profilSupprimerCompteMessage1,
      l10n.profilSupprimerCompteMessage2,
      l10n.profilSupprimerCompteMessage3,
    ];
    for (final message in messages) {
      final confirme = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.profilSupprimerCompteDialogueTitre),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonAnnuler)),
            FilledButton.tonal(
              style: FilledButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonContinuer),
            ),
          ],
        ),
      );
      if (confirme != true) return;
      if (!context.mounted) return;
    }
    await UtilisateurService.instance.supprimerCompteEtDonnees();
  }

  Future<void> _ouvrirChoixTheme(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => const _FeuilleChoixTheme(),
    );
  }

  Future<void> _ouvrirChoixLangue(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => const _FeuilleChoixLangue(),
    );
  }
}

class _FeuilleChoixLangue extends StatelessWidget {
  const _FeuilleChoixLangue();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.profilLangueTitre, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ValueListenableBuilder<Locale?>(
              valueListenable: LocaleService.instance.locale,
              builder: (context, _, _) {
                return SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'fr', label: Text('Français')),
                    ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {Localizations.localeOf(context).languageCode},
                  onSelectionChanged: (s) => LocaleService.instance.definirLangue(s.first),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeuilleChoixTheme extends StatelessWidget {
  const _FeuilleChoixTheme();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.profilThemeCouleurLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ValueListenableBuilder<Color>(
              valueListenable: ThemeService.instance.couleur,
              builder: (context, couleurActuelle, _) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: couleursTheme.entries.map((entree) {
                    final selectionnee = entree.value.toARGB32() == couleurActuelle.toARGB32();
                    return GestureDetector(
                      onTap: () => ThemeService.instance.definirCouleur(entree.key),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: entree.value,
                              shape: BoxShape.circle,
                              border: selectionnee
                                  ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                                  : null,
                            ),
                            child: selectionnee ? const Icon(Icons.check, color: Colors.white) : null,
                          ),
                          const SizedBox(height: 4),
                          Text(_libelleCouleur(l10n, entree.key), style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(l10n.profilThemeModeLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeService.instance.mode,
              builder: (context, modeActuel, _) {
                return SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(l10n.profilThemeModeSysteme)),
                    ButtonSegment(value: ThemeMode.light, label: Text(l10n.profilThemeModeClair)),
                    ButtonSegment(value: ThemeMode.dark, label: Text(l10n.profilThemeModeSombre)),
                  ],
                  selected: {modeActuel},
                  onSelectionChanged: (s) => ThemeService.instance.definirMode(s.first),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// [couleursTheme] est indexée par un nom français fixe (clé de stockage
/// SharedPreferences, ne doit pas changer) — ce switch ne fait que choisir
/// le libellé affiché selon la langue active.
String _libelleCouleur(AppLocalizations l10n, String nomInterne) => switch (nomInterne) {
      'Indigo' => l10n.couleurIndigo,
      'Bleu' => l10n.couleurBleu,
      'Sarcelle' => l10n.couleurSarcelle,
      'Vert' => l10n.couleurVert,
      'Violet' => l10n.couleurViolet,
      'Orange' => l10n.couleurOrange,
      _ => nomInterne,
    };

class _DialogueProfession extends StatefulWidget {
  const _DialogueProfession({
    required this.professionActuelle,
    required this.professionPersonnaliseeActuelle,
  });

  final Profession professionActuelle;
  final String professionPersonnaliseeActuelle;

  @override
  State<_DialogueProfession> createState() => _DialogueProfessionState();
}

class _DialogueProfessionState extends State<_DialogueProfession> {
  late Profession _profession = widget.professionActuelle;
  late final _controller = TextEditingController(text: widget.professionPersonnaliseeActuelle);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.profilModifierProfessionTitre),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<Profession>(
            initialValue: _profession,
            items: Profession.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.libelle(context))))
                .toList(),
            onChanged: (p) => setState(() => _profession = p!),
          ),
          if (_profession == Profession.autre) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: l10n.profilPreciseProfessionLabel),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonAnnuler)),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_profession, _controller.text.trim())),
          child: Text(l10n.commonEnregistrer),
        ),
      ],
    );
  }
}
