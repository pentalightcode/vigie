import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/tache.dart';

const _joursFr = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
const _paletteNatures = [
  Colors.indigo, Colors.teal, Colors.orange, Colors.purple,
  Colors.green, Colors.pink, Colors.brown, Colors.blueGrey,
];

/// Statistiques enrichies du Bilan — inspiré d'une app de séries/habitudes
/// comparée (carte de chaleur, camembert par catégorie, "jour le plus
/// productif"), transformé pour l'esprit Vigie : pas de gamification ludique
/// (mal placée pour un outil professionnel), mais un indicateur de fiabilité
/// ("X jours sans retard") plutôt qu'une série façon jeu (demandé par
/// Tobie le 2026-08-20, approfondissement du Red Team).
class StatistiquesBilan extends StatelessWidget {
  const StatistiquesBilan({
    super.key,
    required this.toutesLesTaches,
    required this.tachesFaitesPeriode,
    required this.totalEnRetardPeriode,
    required this.totalAVenirPeriode,
  });

  /// Toutes les tâches, non filtrées par période — pour la carte de chaleur
  /// (activité récente réelle) et la fiabilité (calculée sur tout l'historique).
  final List<Tache> toutesLesTaches;

  /// Tâches marquées faites PENDANT la période affichée dans le Bilan — pour
  /// le camembert, le graphique par jour et le taux d'achèvement, cohérents
  /// avec la navigation par période déjà en place.
  final List<Tache> tachesFaitesPeriode;
  final int totalEnRetardPeriode;
  final int totalAVenirPeriode;

  @override
  Widget build(BuildContext context) {
    final fiabilite = _joursSansRetard(toutesLesTaches);
    final parJour = <int, int>{};
    for (final t in tachesFaitesPeriode) {
      if (t.dateFait == null) continue;
      parJour[t.dateFait!.weekday] = (parJour[t.dateFait!.weekday] ?? 0) + 1;
    }
    final parNature = <String, int>{};
    for (final t in tachesFaitesPeriode) {
      parNature[t.nature] = (parNature[t.nature] ?? 0) + 1;
    }
    final totalPeriode = tachesFaitesPeriode.length + totalEnRetardPeriode + totalAVenirPeriode;
    final tauxAchevement = totalPeriode == 0 ? null : tachesFaitesPeriode.length / totalPeriode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        fiabilite == null ? Icons.info_outline : Icons.verified_outlined,
                        color: fiabilite == null ? Colors.grey : Colors.green,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fiabilite == null
                            ? 'Aucune tâche terminée en retard pour l\'instant.'
                            : '$fiabilite jour(s) sans tâche terminée en retard.',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.donut_large_outlined),
                      const SizedBox(height: 6),
                      Text(
                        tauxAchevement == null
                            ? 'Rien sur cette période.'
                            : '${(tauxAchevement * 100).round()}% de taux d\'achèvement',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (parNature.isNotEmpty) ...[
          Text('Répartition par type', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: [
                        for (final (i, entree) in parNature.entries.indexed)
                          PieChartSectionData(
                            value: entree.value.toDouble(),
                            color: _paletteNatures[i % _paletteNatures.length],
                            title: '${entree.value}',
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final (i, entree) in parNature.entries.indexed)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 10, height: 10, color: _paletteNatures[i % _paletteNatures.length]),
                            const SizedBox(width: 4),
                            Text(entree.key, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (parJour.isNotEmpty) ...[
          Text('Tâches terminées par jour de la semaine', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(height: 120, child: _GraphiqueParJour(parJour: parJour)),
          const SizedBox(height: 12),
        ],
        Text('Activité des 12 dernières semaines', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _CarteDeChaleur(toutesLesTaches: toutesLesTaches),
      ],
    );
  }
}

/// Jours écoulés depuis la dernière tâche terminée APRÈS sa date déclenchante
/// (approximation honnête du "retard" avec les données disponibles — Vigie
/// ne garde pas un historique jour par jour de l'état "en retard", donc pas
/// de vraie série calculable, seulement cette mesure). `null` si aucune
/// tâche terminée en retard n'a jamais été trouvée.
int? _joursSansRetard(List<Tache> toutes) {
  DateTime? derniereEnRetard;
  for (final t in toutes) {
    if (t.statut != StatutTache.fait || t.dateFait == null) continue;
    if (t.dateFait!.isAfter(t.dateDeclenchante)) {
      if (derniereEnRetard == null || t.dateFait!.isAfter(derniereEnRetard)) {
        derniereEnRetard = t.dateFait;
      }
    }
  }
  if (derniereEnRetard == null) return null;
  return DateTime.now().difference(derniereEnRetard).inDays;
}

class _GraphiqueParJour extends StatelessWidget {
  const _GraphiqueParJour({required this.parJour});
  final Map<int, int> parJour;

  @override
  Widget build(BuildContext context) {
    final maxY = parJour.values.isEmpty ? 1.0 : parJour.values.reduce((a, b) => a > b ? a : b).toDouble();
    final couleur = Theme.of(context).colorScheme.primary;
    return BarChart(
      BarChartData(
        maxY: maxY + 1,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (valeur, meta) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_joursFr[valeur.toInt()], style: const TextStyle(fontSize: 10)),
              ),
            ),
          ),
        ),
        barGroups: List.generate(7, (i) {
          final jourSemaine = i + 1; // 1=lundi ... 7=dimanche, ordre de _joursFr
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: (parJour[jourSemaine] ?? 0).toDouble(),
                color: couleur,
                width: 16,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _CarteDeChaleur extends StatelessWidget {
  const _CarteDeChaleur({required this.toutesLesTaches});
  final List<Tache> toutesLesTaches;

  static const _nbSemaines = 12;

  @override
  Widget build(BuildContext context) {
    final maintenant = DateTime.now();
    final aujourdHui = DateTime(maintenant.year, maintenant.month, maintenant.day);
    final lundiCourant = aujourdHui.subtract(Duration(days: aujourdHui.weekday - DateTime.monday));
    final debut = lundiCourant.subtract(const Duration(days: 7 * (_nbSemaines - 1)));

    final comptageParJour = <DateTime, int>{};
    for (final t in toutesLesTaches) {
      if (t.statut != StatutTache.fait || t.dateFait == null) continue;
      final jour = DateTime(t.dateFait!.year, t.dateFait!.month, t.dateFait!.day);
      if (!jour.isBefore(debut)) {
        comptageParJour[jour] = (comptageParJour[jour] ?? 0) + 1;
      }
    }
    final maxCompte = comptageParJour.values.isEmpty
        ? 1
        : comptageParJour.values.reduce((a, b) => a > b ? a : b);
    final couleurBase = Theme.of(context).colorScheme.primary;

    return Column(
      children: List.generate(_nbSemaines, (semaine) {
        final lundiSemaine = debut.add(Duration(days: 7 * semaine));
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: List.generate(7, (jourIndex) {
              final jour = lundiSemaine.add(Duration(days: jourIndex));
              final compte = comptageParJour[jour] ?? 0;
              final intensite = compte == 0 ? 0.0 : (compte / maxCompte).clamp(0.2, 1.0);
              final futur = jour.isAfter(aujourdHui);
              return Expanded(
                child: Tooltip(
                  message: '${jour.day}/${jour.month} : $compte tâche(s)',
                  child: Container(
                    margin: const EdgeInsets.all(1.5),
                    height: 13,
                    decoration: BoxDecoration(
                      color: futur
                          ? Colors.transparent
                          : (compte == 0
                              ? Theme.of(context).colorScheme.surfaceContainerHighest
                              : couleurBase.withValues(alpha: intensite)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
