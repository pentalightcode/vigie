# Vigie — instructions pour Claude

Ce fichier existe pour que toute session Claude Code ouverte sur ce dépôt reçoive automatiquement ce contexte, sans que Tobie ait besoin de le redemander à chaque fois.

**Avant toute action sur ce projet, lire [`HANDOVER.md`](HANDOVER.md) en entier.** Il contient la méthode de travail (section 1 — red team systématique, qui décide quoi, discipline de déploiement), l'histoire du projet, l'architecture, l'état de sécurité, et ce qui reste ouvert. Ne pas se contenter d'un survol : les règles de méthode qu'il contient ne sont pas optionnelles.

Ensuite, dans cet ordre :
1. `PROGRESS.md` — journal chronologique détaillé, la source la plus fiable pour savoir où en est le projet à un instant donné.
2. `Notes/` — une fiche par décision ou exploration substantielle, souvent avec plusieurs tours de red team documentés.

**Résumé des règles qui comptent le plus** (détaillées avec exemples concrets dans `HANDOVER.md`, section 1) :
- Red team avant toute décision structurante — jamais un seul passage, y compris se relire soi-même après coup sur ses propres correctifs.
- L'IA red-teame et propose des options avec leurs compromis ; Tobie tranche les questions de produit/architecture ambiguës — ne jamais décider à sa place.
- `PROGRESS.md` mis à jour après chaque résultat significatif, pas après coup en bloc.
- Discipline de déploiement stricte : grouper les changements liés, vérifier en local (`flutter analyze`, `firebase deploy --only firestore --dry-run`), ne jamais déployer après chaque micro-modification.
- Transparence totale, y compris sur ses propres erreurs, surtout celles que personne n'a encore remarquées.

**Conventions de code** (détail en section 6 de `HANDOVER.md`) : identifiants en français dans tout le code (`nomCodeDossier`, pas `caseCodeName`), commentaires rares et uniquement sur le "pourquoi" jamais le "quoi", datés et contextualisés.

Ce fichier reste volontairement court — il ne duplique pas `HANDOVER.md`, il y renvoie.
