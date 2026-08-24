import 'package:flutter/material.dart';
import '../models/profession.dart';
import '../services/utilisateur_service.dart';

/// Premier écran après la création du compte : accueil personnalisé,
/// collecte du prénom, pseudo, profession et délai de rappel préféré.
/// La profession détermine les natures de dossier proposées par défaut
/// (correction demandée par Tobie : l'app sert plusieurs métiers).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onTermine});

  final VoidCallback onTermine;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nomController = TextEditingController();
  final _pseudoController = TextEditingController();
  final _professionPersonnaliseeController = TextEditingController();
  Profession _profession = Profession.magistrat;
  int _delaiRappelJours = 14;
  bool _enCours = false;
  String? _erreur;

  Future<void> _valider() async {
    final nom = _nomController.text.trim();
    final pseudo = _pseudoController.text.trim();
    if (nom.isEmpty || pseudo.isEmpty) {
      setState(() => _erreur = 'Renseigne au moins ton prénom et un pseudo.');
      return;
    }
    if (_profession == Profession.autre && _professionPersonnaliseeController.text.trim().isEmpty) {
      setState(() => _erreur = 'Précise le nom de ta profession.');
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await UtilisateurService.instance.terminerOnboarding(
        nom: nom,
        pseudo: pseudo,
        profession: _profession,
        professionPersonnalisee: _professionPersonnaliseeController.text.trim(),
        delaiRappelJours: _delaiRappelJours,
      );
      widget.onTermine();
    } catch (e) {
      setState(() => _erreur = 'Impossible d\'enregistrer. Vérifie ta connexion.');
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.waving_hand_outlined, size: 48, color: Colors.amber),
              const SizedBox(height: 12),
              Text(
                'Bienvenue !',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Quelques infos pour personnaliser ton assistant.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Prénom', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pseudoController,
                decoration: const InputDecoration(
                  labelText: 'Pseudo (comment l\'app t\'appelle)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Profession>(
                initialValue: _profession,
                decoration: const InputDecoration(labelText: 'Ta profession', border: OutlineInputBorder()),
                items: Profession.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.libelle)))
                    .toList(),
                onChanged: (p) => setState(() => _profession = p!),
              ),
              if (_profession == Profession.autre) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _professionPersonnaliseeController,
                  decoration: const InputDecoration(
                    labelText: 'Précise ta profession',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'On pré-remplira des types de dossier adaptés à ton métier — modifiables ensuite.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _delaiRappelJours,
                decoration: const InputDecoration(
                  labelText: 'Être prévenu combien de jours à l\'avance ?',
                  border: OutlineInputBorder(),
                ),
                items: const [7, 14, 21, 30]
                    .map((j) => DropdownMenuItem(value: j, child: Text('$j jours avant')))
                    .toList(),
                onChanged: (j) => setState(() => _delaiRappelJours = j!),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 12),
                Text(_erreur!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _enCours ? null : _valider,
                child: _enCours
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Commencer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
