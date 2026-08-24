# Fiche de note — Red Team de l'architecture complète (v1 du produit construit)

**Date :** 2026-08-07
**Déclencheur :** remarques de Tobie après avoir testé les 3 écrans en vrai. Vérifié précisément dans le code (pas juste en apparence).

---

## 🔴 Critiques — cassent l'usage réel du produit

### 1. Aucun écran de détail d'un Dossier — la séparation Dossier/Tâche est inutile en pratique
Le modèle de données prévoit qu'un Dossier puisse contenir **plusieurs** tâches (écritures + diligences + courrier liés à la même affaire — c'est même écrit dans le MVP dès le round 2). Mais **aucun écran ne permet d'ouvrir un dossier pour voir/ajouter/gérer ses tâches**. Aujourd'hui, un dossier = automatiquement 1 seule tâche, pour toujours. Toute l'architecture à deux niveaux ne sert donc à rien pour l'instant, puisqu'invisible et inaccessible.
**Vérifié dans le code :** aucun `onTap`/navigation vers un détail de dossier n'existe dans `aujourdhui_screen.dart` ni `bilan_screen.dart`.

### 2. Le type (Audience / Courrier / Autre) n'est choisissable nulle part
Le modèle (`TypeTache`) et la règle métier ("courrier = rappel immédiat, réponse en 1 semaine" vs "audience = J-14") existent dans le code (`Tache.calculerDatePremierRappel`), **mais l'écran "Ajouter" ne propose aucun sélecteur** — tout est créé en dur comme `TypeTache.diligence`. Résultat : la règle "courrier" que le père a explicitement demandée est **techniquement présente mais totalement inaccessible**.

### 3. Impossible de modifier quoi que ce soit après création
`modifierDateAudience()` existe bien dans le code (correction du point I, round 2) — **mais aucun bouton, aucun écran ne l'appelle**. Vérifié : zéro référence à cette fonction ailleurs que sa propre définition. Donc en pratique : une faute de frappe sur le nom, une mauvaise date, rien n'est corrigible. Pareil pour la description d'une tâche.

### 4. Impossible de supprimer un dossier ou une tâche
Ajouté par erreur, doublon, test... aucune fonction de suppression n'existe, ni côté service ni côté interface.

### 5. Impossible d'annuler un "C'est fait" cliqué par erreur
Répond directement à ta remarque. Une fois `marquerFait()` appelé, la tâche disparaît de "Aujourd'hui" et il n'y a **aucun moyen de revenir en arrière** — ni bouton "annuler", ni écran listant les tâches faites pour les rebasculer en "à faire".

## 🟠 Moyens — utilisables mais mal dégrossis

### 6. "C'est fait" en un seul tap, sans filet de sécurité
Actuellement : un tap → confirmé, définitif (et sans le point 5 corrigé, c'est irréversible). Deux façons de traiter ça, avec un vrai compromis à trancher ensemble :
- **Confirmation systématique** (boîte de dialogue "Tu confirmes ?") : plus sûr, mais ajoute un clic à **chaque** tâche cochée — pour quelqu'un de débordé qui coche potentiellement 5-10 tâches par jour, ça peut vite agacer.
- **Annuler après coup** (un bandeau "Marqué fait ✓ [Annuler]" qui reste visible quelques secondes, comme dans Gmail) : zéro friction sur l'action normale, mais protège quand même contre l'erreur immédiate.
Je recommande la 2e option (moins de friction, protection quand même), combinée à la correction du point 5 (pouvoir aussi rebasculer une tâche depuis le Bilan, pas seulement juste après le clic) — mais c'est ton choix.

### 7. Le Bilan manque de contexte — ce que tu as vu sur ta capture
Juste des compteurs ("Fait : 1, En retard : 0, À venir : 0") sans aucun détail :
- Impossible de savoir **quelle** tâche est derrière chaque nombre (pas de clic pour voir le détail).
- Aucune indication écrite que "Fait" veut dire "sur les 7 derniers jours" — c'est un choix qu'on a fait dans le code, mais rien ne l'explique à l'écran.
- Pas de total global en haut (toutes affaires confondues) avant le détail par dossier.
Ce n'est pas bâclé dans le principe (l'idée des 3 compteurs est la bonne, validée depuis le début), mais l'exécution manque de finition pour être vraiment utile/lisible.

### 8. "Réunion" — à clarifier avant de coder quoi que ce soit
Tu mentionnes qu'il n'y a pas d'ajout de "réunion". En relisant l'interview, la réunion matinale semblait être **une routine personnelle** ("tous les jours, réunion" — sa journée type), pas un dossier à suivre avec échéance. Je ne veux pas décider à ta place si c'est un vrai besoin ou juste un exemple qu'il donnait — à trancher avec lui avant d'ajouter un 3e type.

### 10. Aucun accueil, aucune personnalisation, et pas moyen de se déconnecter normalement
Ajouté par Tobie, vérifié dans le code — c'est plus large que juste "pas de bonjour" :
- **Pas de prénom/pseudo demandé à l'inscription** — l'app ne sait pas comment s'adresser à son utilisateur, ne peut pas dire "Bonjour [prénom]".
- **Pas d'écran de bienvenue/onboarding** la première fois — on atterrit directement sur "Aujourd'hui" vide, sans explication de ce que l'app fait.
- **Aucun moyen de se déconnecter volontairement.** Vérifié : la seule fonction `seDeconnecter()` appelée dans tout le code est celle du flux "code PIN oublié" (`verrou_screen.dart`) — il n'existe **aucun écran Profil/Paramètres**, donc pas de bouton logout normal, pas moyen de voir/modifier son prénom, pas moyen de changer d'avis sur quoi que ce soit une fois connecté.
- **Icône et nom de l'app pas personnalisés** : vérifié, l'app utilise encore l'icône Flutter par défaut (`Icon-192.png`/`Icon-512.png` jamais remplacées), et le nom affiché sous l'icône sur le téléphone serait `secretaire_aje` (le nom technique du projet), pas "Secrétaire AJE" proprement écrit.

## 🟡 Mineur
### 11. Pas de vérification si un nom de dossier existe déjà (doublon) — impact faible, deux dossiers peuvent avoir le même nom de code sans casser quoi que ce soit techniquement, juste un peu déroutant visuellement.

---

## Constat global
Le cœur technique (Firebase, sécurité, calcul des dates, statuts) est solide. Mais **la couche "gestion du cycle de vie" d'un dossier est incomplète** : on sait très bien **créer**, mais pas **consulter en détail, modifier, corriger une erreur, ni supprimer**. C'est le classique "CRUD" (Créer/Lire/Modifier/Supprimer) où on n'a fait que le C et un L partiel. Ce n'est pas un vice de conception — juste le prochain incrément logique, maintenant qu'on voit le produit tourner en vrai.
