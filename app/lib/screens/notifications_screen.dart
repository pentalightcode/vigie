import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/notification_envoyee.dart';
import '../services/firestore_service.dart';
import '../utils/dates_fr.dart';
import 'dossier_detail_screen.dart';

/// Historique des rappels envoyés par le digest quotidien (matin/soir) —
/// demandé par Tobie car une notification système disparaît une fois lue,
/// sans laisser de trace consultable. Filtrable par type de dossier
/// (Audience, Courrier...), comme demandé.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _filtreType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitre)),
      body: StreamBuilder<List<NotificationEnvoyee>>(
        stream: FirestoreService.instance.notifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final toutes = snapshot.data ?? [];
          if (toutes.isEmpty) {
            return Center(child: Text(l10n.notificationsAucunePourLInstant));
          }

          final tousLesTypes = <String>{};
          for (final n in toutes) {
            tousLesTypes.addAll(n.parType.keys);
          }
          final typesTries = tousLesTypes.toList()..sort();

          final filtrees = _filtreType == null
              ? toutes
              : toutes.where((n) => n.parType.containsKey(_filtreType)).toList();

          return Column(
            children: [
              if (typesTries.isNotEmpty) _BarreDeFiltres(
                types: typesTries,
                filtreActif: _filtreType,
                onChanger: (t) => setState(() => _filtreType = t),
              ),
              Expanded(
                child: filtrees.isEmpty
                    ? Center(child: Text(l10n.notificationsAucunePourCeType))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtrees.length,
                        itemBuilder: (context, i) => _LigneNotification(notif: filtrees[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BarreDeFiltres extends StatelessWidget {
  const _BarreDeFiltres({required this.types, required this.filtreActif, required this.onChanger});

  final List<String> types;
  final String? filtreActif;
  final ValueChanged<String?> onChanger;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(AppLocalizations.of(context)!.notificationsFiltreTous),
            selected: filtreActif == null,
            onSelected: (_) => onChanger(null),
          ),
          const SizedBox(width: 8),
          ...types.map((t) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(t),
                  selected: filtreActif == t,
                  onSelected: (_) => onChanger(t),
                ),
              )),
        ],
      ),
    );
  }
}

/// Icône par type d'événement (Phase 2, 2026-08-31 — voir functions/main.py
/// `_notifier_evenement`) — le corps du message est déjà une phrase complète
/// et détaillée (voir _notifier_evenements_gestion_participant côté
/// serveur), l'icône suffit à distinguer d'un coup d'œil sans répéter un
/// libellé texte redondant.
IconData _iconePourType(String type) => switch (type) {
      'participantAjoute' => Icons.person_add_outlined,
      'participantRetire' => Icons.person_remove_outlined,
      'roleModifie' => Icons.swap_horiz,
      'ajoutParAdministrateur' => Icons.admin_panel_settings_outlined,
      'propositionCreee' => Icons.pending_actions_outlined,
      'propositionResolue' => Icons.fact_check_outlined,
      _ => Icons.notifications_outlined, // 'digest' (rappel quotidien) ou type inconnu
    };

class _LigneNotification extends StatelessWidget {
  const _LigneNotification({required this.notif});

  final NotificationEnvoyee notif;

  @override
  Widget build(BuildContext context) {
    final dossierId = notif.dossierId;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: dossierId == null
            ? null
            : () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => DossierDetailScreen(dossierId: dossierId),
                )),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconePourType(notif.type), size: 16, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      notif.envoyeLe != null
                          ? formaterDateHeureFr(notif.envoyeLe!)
                          : AppLocalizations.of(context)!.propositionsDateInconnue,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ),
                  if (dossierId != null) const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 4),
              Text(notif.corps),
              if (notif.parType.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: notif.parType.entries
                      .map((e) => Chip(
                            label: Text(AppLocalizations.of(context)!.notificationsChipTypeCompte(e.key, e.value)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
