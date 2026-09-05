# Vigie — instructions pour tout agent IA (Antigravity, Cursor, Windsurf, etc.)

Ce fichier existe pour que toute IA agentique ouverte sur ce dépôt reçoive automatiquement ce contexte, sans que Tobie ait besoin de le redemander à chaque fois. Équivalent de `CLAUDE.md` (lu par Claude Code), mais au format `AGENTS.md` reconnu par la plupart des autres outils agentiques.

**Avant toute action sur ce projet, lire [`HANDOVER.md`](HANDOVER.md) en entier.** Il contient la méthode de travail (section 1 — red team systématique, qui décide quoi, discipline de déploiement), l'histoire du projet, l'architecture, l'état de sécurité, et ce qui reste ouvert. Ne pas se contenter d'un survol : les règles de méthode qu'il contient ne sont pas optionnelles.

Ensuite, dans cet ordre :
1. `PROGRESS.md` — journal chronologique détaillé, la source la plus fiable pour savoir où en est le projet à un instant donné (lire surtout les 100-150 dernières lignes).
2. `Notes/` — une fiche par décision ou exploration substantielle, souvent avec plusieurs tours de red team documentés.

**Résumé des règles qui comptent le plus** (détaillées avec exemples concrets dans `HANDOVER.md`, section 1) :
- Red team avant toute décision structurante — jamais un seul passage, y compris se relire soi-même après coup sur ses propres correctifs.
- **QA / Autocritique stricte :** L'IA ne doit JAMAIS proposer de code non testé à Tobie en espérant qu'il trouve les bugs. L'IA fait son propre QA : anticiper les impacts client/serveur (ex: bloquer une action sur serveur implique d'adapter le client), vérifier la compilation et la logique locale (`flutter analyze`, `firebase dry-run`) AVANT de soumettre.
- L'IA red-teame et propose des options avec leurs compromis ; Tobie tranche les questions de produit/architecture ambiguës — ne jamais décider à sa place.
- `PROGRESS.md` mis à jour après chaque résultat significatif, pas après coup en bloc.
- Discipline de déploiement stricte : grouper les changements liés, vérifier en local (`flutter analyze`, `firebase deploy --only firestore --dry-run`), ne jamais déployer après chaque micro-modification.
- Transparence totale, y compris sur ses propres erreurs, surtout celles que personne n'a encore remarquées.
- Avant tout commit/push : relire `git status`/`git diff` réellement (jamais un `git add -A` en confiance aveugle), vérifier l'absence de secret dans le contenu, et ne jamais pousser sans confirmation explicite de Tobie sauf urgence qu'il a lui-même autorisée dans l'échange.

**Conventions de code** (détail en section 6 de `HANDOVER.md`) : identifiants en français dans tout le code (`nomCodeDossier`, pas `caseCodeName`), commentaires rares et uniquement sur le "pourquoi" jamais le "quoi", datés et contextualisés.

**Passation en cours (01/09/2026)** : la Phase 2 collaboration (permissions à la carte, workflow d'approbation, notifications instantanées) vient d'être entièrement écrite et vérifiée localement, mais **n'a subi aucun red team complet et n'est PAS déployée** — voir `HANDOVER.md` section 8 ("⚠️ PASSATION URGENTE") et la toute dernière entrée de `PROGRESS.md` pour l'état exact et la priorité immédiate.

Ce fichier reste volontairement court — il ne duplique pas `HANDOVER.md`, il y renvoie. Il est maintenu en miroir de `CLAUDE.md` : toute mise à jour de l'un doit se refléter dans l'autre.
