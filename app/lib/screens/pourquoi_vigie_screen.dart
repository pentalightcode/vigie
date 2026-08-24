import 'package:flutter/material.dart';

/// Met en avant ce qui distingue Vigie des autres apps de tâches/agenda —
/// demandé par Tobie le 2026-08-20 : "on doit vraiment bien mettre en avant
/// et bien valoriser les fonctionnalités exclusives et hors du commun de
/// Vigie". Réécrit après le Red Team approfondi (carte de chaleur, escalade
/// des rappels, journal de bord, export anonymisé...) — la première version
/// avait été faite trop tôt, avant que ces fonctionnalités existent
/// vraiment. Accessible depuis Profil.
class PourquoiVigieScreen extends StatelessWidget {
  const PourquoiVigieScreen({super.key});

  static const _points = [
    (
      icon: Icons.trending_up,
      titre: 'Des rappels qui s\'adaptent, pas un message figé',
      texte: 'Le ton se durcit avec le retard — neutre, puis ferme, puis '
          'prioritaire — au lieu de répéter éternellement la même phrase. '
          'Une échéance qui approche est signalée même sans retard.',
    ),
    (
      icon: Icons.vpn_key_outlined,
      titre: 'Confidentialité par conception',
      texte: 'Les dossiers sont désignés par des noms de code choisis par toi, '
          'jamais par les vraies informations sensibles — du nom du dossier '
          'jusqu\'au journal de bord et au bilan exporté.',
    ),
    (
      icon: Icons.hub_outlined,
      titre: 'Toutes tes sources, une seule validation',
      texte: 'Gmail, Google Tasks et Google Calendar alimentent le même écran '
          'de propositions, codées par couleur selon leur origine — tu choisis '
          'ce qui devient un vrai dossier. L\'état de chaque vérification est '
          'visible, pas une boîte noire.',
    ),
    (
      icon: Icons.insights_outlined,
      titre: 'Un bilan qui raconte une histoire',
      texte: 'Carte de chaleur d\'activité, répartition par type de dossier, '
          'jour le plus chargé, taux d\'achèvement, et un indicateur de '
          'fiabilité — pas juste des compteurs bruts.',
    ),
    (
      icon: Icons.menu_book_outlined,
      titre: 'Un journal de bord, pas des cases à cocher',
      texte: 'Documente l\'avancement d\'un dossier étape par étape : chaque '
          'note s\'ajoute à la suite, rien n\'est jamais écrasé — une vraie '
          'mémoire de la progression, pas un simple statut.',
    ),
    (
      icon: Icons.ios_share,
      titre: 'Un rapport sûr à partager, par construction',
      texte: 'Le bilan s\'exporte en un clic — et comme tout est déjà en noms '
          'de code, il n\'y a jamais rien de sensible dedans, où qu\'il soit '
          'partagé.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pourquoi Vigie')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _points.length,
        itemBuilder: (context, i) {
          final point = _points[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(point.icon, color: Theme.of(context).colorScheme.primary, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(point.titre, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(point.texte, style: const TextStyle(color: Colors.grey)),
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
