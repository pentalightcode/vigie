import 'package:flutter/material.dart';
import '../models/nature_dossier.dart';
import '../services/firestore_service.dart';
import '../services/nature_dossier_service.dart';
import '../utils/dates_fr.dart';
import '../utils/notes_structurees.dart';
import 'ajout_groupe_screen.dart';
import 'gestion_natures_sheet.dart';

/// Écran 1 du MVP : ajouter un dossier + sa première tâche, un par un,
/// ou plusieurs d'un coup via [AjoutGroupeScreen] (le "rôle" hebdomadaire).
class AjouterScreen extends StatefulWidget {
  const AjouterScreen({super.key});

  @override
  State<AjouterScreen> createState() => _AjouterScreenState();
}

class _AjouterScreenState extends State<AjouterScreen> {
  final _nomCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _resteController = TextEditingController();
  final _attenteController = TextEditingController();
  final _autreController = TextEditingController();
  NatureDossier? _nature;
  DateTime? _dateEvenement;
  bool _enCours = false;
  String? _erreur;
  bool _descriptionModifieeManuellement = false;

  void _changerNature(NatureDossier nouvelleNature) {
    setState(() {
      _nature = nouvelleNature;
      if (!_descriptionModifieeManuellement) {
        _descriptionController.text = nouvelleNature.nom;
      }
    });
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _dateEvenement = date);
  }

  Future<void> _enregistrer() async {
    final nomCode = _nomCodeController.text.trim();
    if (nomCode.isEmpty) {
      setState(() => _erreur = 'Donne un nom de code au dossier.');
      return;
    }
    if (_nature == null) {
      setState(() => _erreur = 'Choisis une nature de dossier.');
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final notes = NotesStructurees(
        resteAVerifier: _resteController.text.trim(),
        enAttenteDe: _attenteController.text.trim(),
        autre: _autreController.text.trim(),
      );
      await FirestoreService.instance.creerDossierAvecTache(
        nomCode: nomCode,
        dateEvenement: _dateEvenement,
        nature: _nature!.nom,
        descriptionTache:
            _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        notesDetaillees: notes.estVide ? null : notes.formater(),
      );
      if (mounted) {
        _nomCodeController.clear();
        _resteController.clear();
        _attenteController.clear();
        _autreController.clear();
        setState(() => _dateEvenement = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dossier ajouté.')),
        );
      }
    } catch (e) {
      setState(() => _erreur = 'Impossible d\'enregistrer. Vérifie ta connexion.');
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un dossier'),
        actions: [
          IconButton(
            tooltip: 'Ajout groupé (plusieurs dossiers d\'un coup)',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AjoutGroupeScreen()),
            ),
            icon: const Icon(Icons.playlist_add),
          ),
        ],
      ),
      body: StreamBuilder<List<NatureDossier>>(
        stream: NatureDossierService.instance.natures(),
        builder: (context, snapshotNatures) {
          final natures = snapshotNatures.data ?? [];
          if (snapshotNatures.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_nature == null && natures.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _changerNature(natures.first));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Type de dossier', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<NatureDossier>(
                  initialValue: _nature,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: natures
                      .map((n) => DropdownMenuItem(value: n, child: Text(n.nom)))
                      .toList(),
                  onChanged: (n) => _changerNature(n!),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _gererNatures(context),
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text('Gérer mes types de dossier'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nomCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de code',
                    hintText: 'ex : Dossier Alpha',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Détail (pour distinguer plusieurs tâches)',
                    hintText: 'ex : Conclusions en défense',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _descriptionModifieeManuellement = true,
                ),
                const SizedBox(height: 12),
                // Raccourcis de date rapides (le cas courant en un tap) + sélecteur
                // complet pour une date précise — plutôt qu'un seul bouton qui
                // ouvre toujours le calendrier (simplicité de saisie demandée par
                // Tobie le 2026-08-09, inspirée de Todoist).
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Dans 2 semaines'),
                      onPressed: () =>
                          setState(() => _dateEvenement = DateTime.now().add(const Duration(days: 14))),
                    ),
                    ActionChip(
                      label: const Text('Dans 1 mois'),
                      onPressed: () =>
                          setState(() => _dateEvenement = DateTime.now().add(const Duration(days: 30))),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.event, size: 16),
                      label: const Text('Choisir une date'),
                      onPressed: _choisirDate,
                    ),
                    if (_dateEvenement != null)
                      ActionChip(
                        avatar: const Icon(Icons.close, size: 16),
                        label: const Text('Retirer'),
                        onPressed: () => setState(() => _dateEvenement = null),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _dateEvenement == null
                      ? 'Aucune date choisie (optionnel).'
                      : 'Échéance : ${formaterDateFr(_dateEvenement!)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                // Notes repliées par défaut : le cas courant (juste un nom, un
                // type, une date) devient plus rapide à remplir, sans rien perdre
                // pour qui a besoin d'écrire une note (demandé par Tobie).
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    title: const Text('Ajouter une note', style: TextStyle(fontWeight: FontWeight.w600)),
                    children: [
                      TextField(
                        controller: _resteController,
                        decoration: const InputDecoration(
                          labelText: 'Reste à vérifier',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _attenteController,
                        decoration: const InputDecoration(
                          labelText: 'En attente de',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _autreController,
                        maxLines: 3,
                        minLines: 1,
                        decoration: const InputDecoration(
                          labelText: 'Autre',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Comme pour le nom du dossier, évite d\'écrire de vraies informations '
                        'sensibles ici.',
                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 8),
                  Text(_erreur!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _enCours ? null : _enregistrer,
                  child: _enCours
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _gererNatures(BuildContext context) => GestionNaturesSheet.ouvrir(context);
}
