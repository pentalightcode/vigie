import 'package:flutter/material.dart';
import '../models/nature_dossier.dart';
import '../services/firestore_service.dart';
import '../services/nature_dossier_service.dart';
import '../utils/dates_fr.dart';
import '../utils/notes_structurees.dart';

/// Dialogue de création d'un dossier+tâche à partir d'une source externe
/// (proposition Gmail/Tasks/Calendar, ou événement d'agenda cliqué
/// directement) — nom et date pré-remplis si fournis, mais rien n'est créé
/// sans ce passage par l'utilisateur (même principe partout dans Vigie :
/// jamais de création automatique silencieuse).
class DialogueCreationDossier extends StatefulWidget {
  const DialogueCreationDossier({
    super.key,
    this.nomSuggere = '',
    this.dateInitiale,
    this.notesInitiales,
    this.apresCreation,
  });

  final String nomSuggere;
  final DateTime? dateInitiale;
  /// Détails d'origine (description Google Calendar/Tasks) — pré-remplit le
  /// champ notes, modifiable avant validation.
  final String? notesInitiales;
  /// Appelé après la création réussie — ex: supprimer la proposition source.
  final Future<void> Function()? apresCreation;

  @override
  State<DialogueCreationDossier> createState() => _DialogueCreationDossierState();
}

class _DialogueCreationDossierState extends State<DialogueCreationDossier> {
  late final _nomController = TextEditingController(text: widget.nomSuggere);
  late final _notesInitiales = NotesStructurees.analyser(widget.notesInitiales);
  late final _resteController = TextEditingController(text: _notesInitiales.resteAVerifier);
  late final _attenteController = TextEditingController(text: _notesInitiales.enAttenteDe);
  late final _autreController = TextEditingController(text: _notesInitiales.autre);
  NatureDossier? _nature;
  late DateTime _date = widget.dateInitiale ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter à un dossier'),
      content: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nomController,
            decoration: const InputDecoration(
              labelText: 'Nom de code',
              hintText: 'ex : Dossier Alpha',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<NatureDossier>>(
            stream: NatureDossierService.instance.natures(),
            builder: (context, snapshot) {
              final natures = snapshot.data ?? [];
              // Choisir la nature par défaut doit passer par setState (pas
              // une simple affectation directe) pour que le bouton "Créer"
              // (qui dépend de _nature) se réévalue — sinon il restait grisé
              // tant qu'on ne touchait pas manuellement un autre champ, même
              // quand tout était déjà pré-rempli (bug trouvé par Tobie le
              // 2026-08-22, en ouvrant un événement d'agenda déjà complet).
              // Programmé juste après cette image : on est déjà en train de
              // construire ici, un setState() immédiat lèverait une erreur.
              if (_nature == null && natures.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _nature == null) setState(() => _nature = natures.first);
                });
              }
              return DropdownButtonFormField<NatureDossier>(
                initialValue: _nature,
                decoration: const InputDecoration(labelText: 'Type de dossier', border: OutlineInputBorder()),
                items: natures.map((n) => DropdownMenuItem(value: n, child: Text(n.nom))).toList(),
                onChanged: (n) => setState(() => _nature = n),
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.event),
            label: Text(formaterDateFr(_date)),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Notes', style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(height: 8),
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
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: _nature == null ? null : () => _valider(context),
          child: const Text('Créer'),
        ),
      ],
    );
  }

  Future<void> _valider(BuildContext context) async {
    final nom = _nomController.text.trim();
    if (nom.isEmpty || _nature == null) return;
    final notes = NotesStructurees(
      resteAVerifier: _resteController.text.trim(),
      enAttenteDe: _attenteController.text.trim(),
      autre: _autreController.text.trim(),
    );
    await FirestoreService.instance.creerDossierAvecTache(
      nomCode: nom,
      dateEvenement: _date,
      nature: _nature!.nom,
      notesDetaillees: notes.estVide ? null : notes.formater(),
    );
    await widget.apresCreation?.call();
    if (context.mounted) Navigator.pop(context);
  }
}
