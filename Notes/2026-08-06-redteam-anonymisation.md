# Fiche de note — Red Team de l'idée "noms de code + cloud (Firebase/Supabase)"

**Date :** 2026-08-06
**Idée de Tobie :** utiliser un cloud simple (Firebase/Supabase), mais ne jamais stocker les vraies infos des dossiers — seulement des noms de code que le père choisit lui-même.

---

## 1. Ce qui est juste dans cette idée

C'est exactement le principe de **"minimisation des données"** : si l'information sensible n'est jamais entrée dans le système, elle ne peut pas fuiter depuis ce système. C'est une vraie bonne pratique de sécurité (utilisée par plein d'apps sérieuses). Donc oui, sur le principe, tu n'as pas tort.

## 2. Les 3 trous à colmater (Red Team — règle "challenger avant de valider")

### Trou n°1 — Les métadonnées parlent quand même
Même avec des noms de code, le simple fait de voir "7 audiences cette semaine, dont 3 le même jour" ou les dates exactes peut, en théorie, être recoupé avec le rôle public d'une juridiction pour retrouver de quoi il s'agit. Risque faible mais réel — à connaître, pas forcément à résoudre tout de suite.

### Trou n°2 — Où vit la correspondance "nom de code ↔ vrai dossier" ?
Si "Dossier Alpha" = telle vraie affaire, cette info doit être stockée **quelque part** pour que ton père s'y retrouve. Si c'est "dans sa tête" : fragile — c'est justement parce qu'il oublie des choses qu'on construit cet outil ! S'il l'écrit sur papier ou dans une note à part : on a juste déplacé le problème de confidentialité ailleurs, pas résolu.

### Trou n°3 — Le facteur humain (le plus dangereux)
Il est débordé. Un jour, fatigué, il va taper "prépare les conclusions pour l'affaire X contre Y, vol qualifié" dans un champ texte libre au lieu du nom de code — par habitude, par flemme, ou parce qu'il dicte à l'oral. **Un seul oubli suffit** pour que la vraie info parte dans le cloud, définitivement. Compter uniquement sur sa discipline, alors que le projet part du constat qu'il est débordé, est risqué.

## 3. Renforcement proposé (pour combler les 3 trous d'un coup)

En plus des noms de code (qui restent une bonne idée pour les *intitulés/labels visibles*), ajouter un **chiffrement côté téléphone** : avant que la moindre donnée parte vers Firebase/Supabase, elle est chiffrée directement sur son téléphone avec une clé que lui seul possède. Firebase/Supabase ne stockent alors que du texte illisible (comme un coffre-fort dont seul lui a la clé) — même s'il tape par erreur un vrai nom, ce nom part chiffré, jamais en clair.

- **Avantage :** couvre le Trou n°3 automatiquement (pas besoin de compter sur sa discipline à 100%).
- **Avantage :** la correspondance nom de code ↔ vraie affaire peut alors être stockée dans l'app elle-même (chiffrée), pas sur un post-it à part (résout le Trou n°2).
- **Coût :** un peu plus de travail de développement au départ (mettre en place le chiffrement), mais c'est un standard éprouvé (utilisé par des apps comme Bitwarden, Standard Notes).
- Bonus simple : si Firebase/Supabase, choisir une **région Europe** plutôt qu'US par défaut (léger mieux, pas une garantie légale en soi vu qu'on est sous droit béninois, mais dans le doute autant réduire l'exposition).

## 4. Question pour trancher
- **Option 1 (simple)** : noms de code seulement, sans chiffrement — rapide à construire, mais dépend à 100% de sa discipline (Trou n°3 non résolu).
- **Option 2 (robuste)** : noms de code + chiffrement côté téléphone — un peu plus de travail, mais résout les 3 trous, même s'il se trompe une fois.
