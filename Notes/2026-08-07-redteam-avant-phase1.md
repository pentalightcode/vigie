# Fiche de note — Red Team final avant de démarrer la Phase 1

**Date :** 2026-08-07
**Déclencheur :** le projet vient de changer de nature (outil perso → futur produit multi-utilisateurs par abonnement). Ça change certaines choses qu'il vaut mieux corriger avant de coder plutôt qu'après.

---

## 🔴 À corriger avant de commencer

### 1. Il n'existe aucun endroit où stocker les réglages d'un utilisateur
On vient de décider que le délai de rappel (2 semaines) doit être **par utilisateur**, pas fixe dans le code. Mais il n'existe aujourd'hui **aucun document Firestore pour les réglages d'un utilisateur** (pseudo, délai préféré...). Il faut créer une collection `/utilisateurs/{uid}` dès maintenant, avec un délai par défaut (14 jours) — même si l'écran pour le modifier (Phase 3) vient plus tard. Sinon, le sélecteur de type qu'on construit en Phase 1 devra être refait une 2e fois quand on ajoutera le réglage.

### 2. "Réunion/RDV" — quel délai de rappel lui appliquer ?
On ajoute ce type sans avoir décidé de sa règle. Une audience se prépare 2 semaines à l'avance ; un rendez-vous a probablement besoin de beaucoup moins (un jour avant ? le jour même ?). **Proposition simple :** traiter "Réunion/RDV" comme "Audience" pour le calcul (même délai configurable), pour ne pas complexifier inutilement — à ajuster plus tard si l'usage réel montre que ça ne convient pas. Confirme si ça te va.

## 🟠 Tensions à trancher, pas des bugs

### 3. La double confirmation systématique, envisagée pour TON père — est-ce le bon réglage pour TOUS les futurs clients payants ?
Ton père voulait volontairement plus de friction (garde-fou contre l'oubli). Mais pour un produit vendu à d'autres magistrats, une double confirmation obligatoire à **chaque** tâche cochée (potentiellement 10 fois par jour) pourrait agacer des clients qui n'ont pas le même besoin. **Deux options :**
- Garder double confirmation fixe pour tout le monde (simple, mais pourrait desservir l'expérience d'autres clients).
- En faire un réglage par utilisateur, comme le délai de rappel (plus de travail maintenant, mais évite de devoir choisir à la place de futurs clients).
Je penche pour la 2e option vu qu'on vient déjà de rendre le délai configurable — même logique, même écran de réglages. Ton avis ?

### 4. Suppression de compte — bonne nouvelle : ça sert aussi la conformité légale
Ce que tu as demandé pour la confiance utilisateur (triple confirmation) tombe bien : pour un produit commercial, un "droit à la suppression de ses données" est souvent une **obligation légale** (on l'a vu avec l'APDP au Bénin, et ça existe ailleurs aussi sous d'autres noms). Pas une correction à faire, juste une confirmation que ce qu'on construit sert double objectif (confiance + conformité).

### 5. La phrase secrète "oubliée = perdu pour toujours" — risque commercial à anticiper
Pour ton père, ce compromis est acceptable et bien expliqué. Pour un client payant lambda qui découvre l'app, oublier sa phrase et perdre définitivement ses notes pourrait générer de la frustration, des avis négatifs, des demandes de remboursement. Pas un bug à corriger maintenant, mais **l'écran où on lui fait choisir cette phrase (futur, Phase 4) devra insister très clairement** sur les conséquences, plus encore que ce qu'on avait prévu pour un usage strictement familial.

## 🟡 Détail
### 6. Le champ `dateAudience` du modèle Dossier garde son nom technique même s'il sert maintenant aussi aux réunions/RDV. Pas grave en soi (nom interne), mais je le renommerai en interne en `dateEvenement` pour que le code reste lisible — aucun impact visible pour toi.

---

## Ce qui ne change pas
Le cœur (sécurité Firestore par utilisateur, chiffrement, architecture Dossier/Tâche) est déjà pensé pour supporter plusieurs utilisateurs sans réécriture — bon signe, on n'a pas à tout refaire.
