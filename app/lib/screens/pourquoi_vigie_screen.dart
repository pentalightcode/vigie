import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Met en avant ce qui distingue Vigie des autres apps de tâches/agenda —
/// demandé par Tobie le 2026-08-20 : "on doit vraiment bien mettre en avant
/// et bien valoriser les fonctionnalités exclusives et hors du commun de
/// Vigie". Réécrit après le Red Team approfondi (carte de chaleur, escalade
/// des rappels, journal de bord, export anonymisé...) — la première version
/// avait été faite trop tôt, avant que ces fonctionnalités existent
/// vraiment. Accessible depuis Profil.
class PourquoiVigieScreen extends StatelessWidget {
  const PourquoiVigieScreen({super.key});

  static const _icones = [
    Icons.trending_up,
    Icons.vpn_key_outlined,
    Icons.hub_outlined,
    Icons.insights_outlined,
    Icons.menu_book_outlined,
    Icons.ios_share,
  ];

  static List<(String titre, String texte)> _points(AppLocalizations l10n) => [
        (l10n.pourquoiVigieTitre1, l10n.pourquoiVigieTexte1),
        (l10n.pourquoiVigieTitre2, l10n.pourquoiVigieTexte2),
        (l10n.pourquoiVigieTitre3, l10n.pourquoiVigieTexte3),
        (l10n.pourquoiVigieTitre4, l10n.pourquoiVigieTexte4),
        (l10n.pourquoiVigieTitre5, l10n.pourquoiVigieTexte5),
        (l10n.pourquoiVigieTitre6, l10n.pourquoiVigieTexte6),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final points = _points(l10n);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pourquoiVigieAppBarTitre)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: points.length,
        itemBuilder: (context, i) {
          final (titre, texte) = points[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_icones[i], color: Theme.of(context).colorScheme.primary, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titre, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(texte, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
