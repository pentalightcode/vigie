import 'package:flutter/material.dart';
import '../models/proposition_dossier.dart';
import '../services/gmail_service.dart';
import '../utils/confirmation.dart';
import '../utils/dates_fr.dart';
import '../utils/source_proposition.dart';
import '../widgets/dialogue_creation_dossier.dart';

/// Dates détectées automatiquement dans les emails/tâches/événements, en
/// attente de validation — rien n'est jamais créé sans confirmation
/// explicite (décision du 2026-08-12, redemandée le 2026-08-12 : "on ne
/// peut pas pallier aux erreurs sans IA sans une étape de confirmation").
/// Codées par couleur selon l'origine (Gmail/Tasks/Calendar) et filtrables
/// — inspiré des calendriers colorés de Google Agenda (demandé par Tobie
/// le 2026-08-20).
class PropositionsScreen extends StatefulWidget {
  const PropositionsScreen({super.key});

  @override
  State<PropositionsScreen> createState() => _PropositionsScreenState();
}

class _PropositionsScreenState extends State<PropositionsScreen> {
  SourceProposition? _filtre;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Propositions')),
      body: StreamBuilder<List<PropositionDossier>>(
        stream: GmailService.instance.propositions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final toutes = snapshot.data ?? [];
          if (toutes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucune proposition pour l\'instant. Dès qu\'une date sera '
                  'trouvée dans un email, une tâche Google Tasks ou un '
                  'événement Google Calendar, elle apparaîtra ici.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final propositions = _filtre == null
              ? toutes
              : toutes.where((p) => infosSource(p.expediteur).source == _filtre).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _pucheFiltre(null, 'Tout'),
                      const SizedBox(width: 8),
                      _pucheFiltre(SourceProposition.gmail, 'Gmail'),
                      const SizedBox(width: 8),
                      _pucheFiltre(SourceProposition.tasks, 'Google Tasks'),
                      const SizedBox(width: 8),
                      _pucheFiltre(SourceProposition.calendar, 'Google Calendar'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: propositions.length,
                  itemBuilder: (context, i) => _LigneProposition(proposition: propositions[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pucheFiltre(SourceProposition? source, String libelle) {
    return FilterChip(
      label: Text(libelle),
      selected: _filtre == source,
      onSelected: (_) => setState(() => _filtre = source),
    );
  }
}

class _LigneProposition extends StatelessWidget {
  const _LigneProposition({required this.proposition});

  final PropositionDossier proposition;

  @override
  Widget build(BuildContext context) {
    final infos = infosSource(proposition.expediteur);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(infos.icone, size: 16, color: infos.couleur),
                const SizedBox(width: 6),
                Text(infos.libelle, style: TextStyle(color: infos.couleur, fontSize: 12, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(
                  proposition.date != null ? formaterDateFr(proposition.date!) : 'Date inconnue',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('De : ${proposition.expediteur}', style: const TextStyle(color: Colors.grey)),
            if (proposition.sujetEmail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(proposition.sujetEmail, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (proposition.details.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                proposition.details,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _refuser(context),
                    child: const Text('Ignorer'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _creerDossier(context),
                    child: const Text('Créer le dossier'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refuser(BuildContext context) async {
    final confirme = await demanderDoubleConfirmation(
      context,
      titre: 'Ignorer cette proposition ?',
      message: 'Aucun dossier ne sera créé pour "${proposition.sujetEmail}".',
      texteBouton: 'Ignorer',
      destructif: true,
    );
    if (confirme) {
      await GmailService.instance.supprimerProposition(proposition.id);
    }
  }

  Future<void> _creerDossier(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => DialogueCreationDossier(
        dateInitiale: proposition.date,
        notesInitiales: proposition.details,
        apresCreation: () => GmailService.instance.supprimerProposition(proposition.id),
      ),
    );
  }
}
