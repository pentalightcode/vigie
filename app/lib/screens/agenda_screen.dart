import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/connexion_google.dart';
import '../models/evenement_calendrier.dart';
import '../services/gmail_service.dart';
import '../utils/dates_fr.dart';
import '../widgets/dialogue_creation_dossier.dart';

/// Vue en direct de l'agenda Google — grille du mois + liste du jour
/// sélectionné en dessous (demandé par Tobie le 2026-08-19 : "on doit bien
/// voir un calendrier", pas juste une liste). Accessible depuis une icône
/// dans "À traiter", volontairement pas un onglet supplémentaire.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _moisAffiche = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _jourSelectionne = DateTime.now();

  Map<DateTime, List<EvenementCalendrier>>? _evenementsParJour;
  bool _chargement = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _chargerMois(_moisAffiche);
  }

  Future<void> _chargerMois(DateTime mois) async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      // Une marge d'une semaine de part et d'autre : la grille affiche
      // toujours quelques jours du mois précédent/suivant pour compléter
      // les lignes, sans ça ces jours-là paraîtraient vides à tort.
      final debut = DateTime(mois.year, mois.month, 1).subtract(const Duration(days: 7));
      final fin = DateTime(mois.year, mois.month + 1, 1).add(const Duration(days: 7));
      final evenements = await GmailService.instance.evenementsCalendrier(debut, fin);

      final parJour = <DateTime, List<EvenementCalendrier>>{};
      for (final e in evenements) {
        final jour = DateTime(e.date.year, e.date.month, e.date.day);
        parJour.putIfAbsent(jour, () => []).add(e);
      }
      if (mounted) setState(() => _evenementsParJour = parJour);
    } catch (e) {
      if (mounted) setState(() => _erreur = 'Impossible de lire le calendrier : $e');
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  List<EvenementCalendrier> _evenementsDuJour(DateTime jour) {
    final cle = DateTime(jour.year, jour.month, jour.day);
    return _evenementsParJour?[cle] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      // Gate sur "au moins un compte Google connecté" — depuis le
      // 2026-08-21, connecter un compte donne toujours accès à Tasks +
      // Calendar (aucun rôle prédéfini, voir ConnexionGoogle).
      body: StreamBuilder<List<ConnexionGoogle>>(
        stream: GmailService.instance.connexionsGoogle(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Connecte d\'abord un compte Google dans Automatisation '
                  'pour voir ton agenda ici.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _contenu(context);
        },
      ),
      floatingActionButton: _evenementsParJour == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _ajouterAUnDossier(context),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une tâche'),
            ),
    );
  }

  Future<void> _ajouterAUnDossier(
    BuildContext context, {
    String nomSuggere = '',
    String notesSuggere = '',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => DialogueCreationDossier(
        nomSuggere: nomSuggere,
        dateInitiale: _jourSelectionne,
        notesInitiales: notesSuggere,
      ),
    );
  }

  Widget _contenu(BuildContext context) {
    return Column(
      children: [
        TableCalendar<EvenementCalendrier>(
          locale: 'fr_FR',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: _moisAffiche,
          selectedDayPredicate: (jour) => isSameDay(jour, _jourSelectionne),
          eventLoader: _evenementsDuJour,
          onDaySelected: (jourSelectionne, jourFocus) {
            setState(() {
              _jourSelectionne = jourSelectionne;
              _moisAffiche = jourFocus;
            });
          },
          onPageChanged: (jourFocus) {
            _moisAffiche = jourFocus;
            _chargerMois(jourFocus);
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        ),
        if (_chargement) const LinearProgressIndicator(),
        if (_erreur != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_erreur!, style: const TextStyle(color: Colors.red)),
          ),
        const Divider(height: 1),
        Expanded(child: _listeDuJour()),
      ],
    );
  }

  Widget _listeDuJour() {
    final evenements = _evenementsDuJour(_jourSelectionne);
    if (evenements.isEmpty) {
      return Center(
        child: Text(
          'Rien le ${formaterDateFr(_jourSelectionne)}.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: evenements.length,
      itemBuilder: (context, i) {
        final e = evenements[i];
        final heure = e.journeeEntiere
            ? 'Journée entière'
            : '${e.date.hour.toString().padLeft(2, '0')}h${e.date.minute.toString().padLeft(2, '0')}';
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.event),
            title: Text(e.titre),
            subtitle: Text(
              e.description.isEmpty ? heure : '$heure\n${e.description}',
            ),
            isThreeLine: e.description.isNotEmpty,
            trailing: const Icon(Icons.add_circle_outline),
            onTap: () => _ajouterAUnDossier(context, nomSuggere: e.titre, notesSuggere: e.description),
          ),
        );
      },
    );
  }
}
