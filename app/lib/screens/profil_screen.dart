import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/connexion_google.dart';
import '../models/profession.dart';
import '../models/reglages_utilisateur.dart';
import '../services/auth_service.dart';
import '../services/gmail_service.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: StreamBuilder<ReglagesUtilisateur>(
        stream: UtilisateurService.instance.reglages(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reglages = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  leading: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  title: Text(
                    'Pourquoi Vigie ?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  subtitle: Text(
                    'Ce qui rend Vigie différent',
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
                  'Connecté en tant que ${FirebaseAuth.instance.currentUser?.email ?? 'inconnu'}',
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(reglages.pseudo ?? 'Pseudo non défini'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _modifierPseudo(context, reglages.pseudo ?? ''),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.work_outline),
                title: Text(reglages.libelleProfession.isEmpty ? 'Profession non définie' : reglages.libelleProfession),
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
                title: const Text('Délai de rappel'),
                subtitle: Text('${reglages.delaiRappelJours} jours avant l\'échéance'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _modifierDelai(context, reglages.delaiRappelJours),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Mes types de dossier'),
                subtitle: const Text('Ajouter ou supprimer tes catégories personnalisées'),
                onTap: () => GestionNaturesSheet.ouvrir(context),
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Thème'),
                subtitle: const Text('Couleur et mode clair/sombre'),
                onTap: () => _ouvrirChoixTheme(context),
              ),
              StreamBuilder<List<ConnexionGoogle>>(
                stream: GmailService.instance.connexionsGoogle(),
                builder: (context, snapshotConnexions) {
                  final connexions = snapshotConnexions.data ?? [];
                  final nombre = connexions.length;
                  return ListTile(
                    leading: const Icon(Icons.auto_awesome_outlined),
                    title: const Text('Automatisation'),
                    subtitle: Text(
                      nombre == 0
                          ? 'Connecter un compte Google pour détecter les dates automatiquement'
                          : nombre == 1
                              ? '1 compte Google connecté'
                              : '2 comptes Google connectés',
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
                title: const Text('Se déconnecter'),
                onTap: () => _seDeconnecter(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Supprimer mon compte', style: TextStyle(color: Colors.red)),
                onTap: () => _supprimerCompte(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _modifierPseudo(BuildContext context, String pseudoActuel) async {
    final controller = TextEditingController(text: pseudoActuel);
    final nouveau = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le pseudo'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Pseudo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enregistrer'),
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
    final nouveau = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Délai de rappel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [7, 14, 21, 30]
              .map((j) => ListTile(
                    title: Text('$j jours avant'),
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
    final confirme = await demanderDoubleConfirmation(
      context,
      titre: 'Se déconnecter ?',
      message: 'Tu devras te reconnecter par email pour rouvrir l\'app.',
    );
    if (confirme) {
      await AuthService.instance.seDeconnecter();
    }
  }

  Future<void> _supprimerCompte(BuildContext context) async {
    final messages = [
      'Tous tes dossiers et toutes tes tâches seront supprimés définitivement. Il n\'y a aucun moyen de les récupérer ensuite.',
      'Ton compte de connexion sera lui aussi supprimé — tu ne pourras plus te reconnecter avec cet email sans recréer un compte, vide, à zéro.',
      'Dernière alerte : cette action est irréversible et immédiate. Es-tu vraiment certain de vouloir supprimer ton compte ?',
    ];
    for (final message in messages) {
      final confirme = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Supprimer le compte'),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            FilledButton.tonal(
              style: FilledButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuer'),
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
}

class _FeuilleChoixTheme extends StatelessWidget {
  const _FeuilleChoixTheme();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Couleur', style: Theme.of(context).textTheme.titleMedium),
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
                          Text(entree.key, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            Text('Mode', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeService.instance.mode,
              builder: (context, modeActuel, _) {
                return SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('Système')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Clair')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Sombre')),
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
    return AlertDialog(
      title: const Text('Modifier la profession'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<Profession>(
            initialValue: _profession,
            items: Profession.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.libelle)))
                .toList(),
            onChanged: (p) => setState(() => _profession = p!),
          ),
          if (_profession == Profession.autre) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Précise ta profession'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_profession, _controller.text.trim())),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
