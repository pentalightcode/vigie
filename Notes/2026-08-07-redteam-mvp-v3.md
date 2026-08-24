# Fiche de note — Red Team round 3 (questions de Tobie, traitées par Claude)

**Date :** 2026-08-07
**Méthode utilisée :** les 5 questions posées par Tobie, appliquées une par une au MVP v3.

---

## Question 1 — "Est-ce que le MVP la couvre vraiment, ou juste en apparence ?"

### 🔴 Gap trouvé (P) — L'ajout groupé ne résout que la moitié du problème
Le MVP v3 permet de coller/saisir plusieurs **Dossiers** d'un coup (le "rôle" hebdomadaire). Mais il crée seulement les Dossiers avec leur date d'audience — **pas les Tâches (diligences) liées**. En pratique, le père devrait donc quand même ouvrir chaque Dossier ensuite pour ajouter la tâche à la main. On n'a résolu **qu'en apparence** sa plus grosse perte de temps (il faudrait encore "recenser les trucs à faire" un par un après le bulk-add).

**Solution concrète :** l'ajout groupé crée automatiquement, pour chaque Dossier, **une Tâche par défaut** ("Diligences avant audience", rappel à J-14). Il peut ensuite la préciser ou en ajouter d'autres s'il y a plusieurs choses à faire pour ce dossier — mais il n'a plus besoin de tout recréer de zéro.

## Question 2 — "Où deux bonnes idées se contredisent ?"

### 🟠 Tension trouvée (T) — Saisie rapide vs écran de relecture
Le point K (ajouté au round 2) proposait un écran de relecture avant de valider un ajout groupé, pour éviter les erreurs de date. Mais l'objectif du point C était justement d'aller **vite**. Si la relecture est un gros formulaire, on recrée de la friction.
**Solution concrète :** la relecture doit être **ultra-légère** — une simple liste "voici ce que j'ai compris : Dossier X le [date], Dossier Y le [date]... — tout est bon ?" avec un seul bouton de confirmation globale, pas une validation ligne par ligne.

*(Autre tension vérifiée mais pas bloquante : "il garde la main sur les priorités" vs "trier le digest par urgence" — trier par date n'est pas décider pour lui, c'est juste rendre la liste lisible. Pas de vraie contradiction.)*

## Question 3 — Simulation : le père, débordé, un mardi matin

- 7h : il ouvre l'app → verrou PIN/Face ID → notification générique déjà vue sur l'écran verrouillé ("des choses à te montrer") → il ouvre et voit "Aujourd'hui" groupé par dossier.
- Il traite 2 choses, appuie "C'est fait" sur chacune. Une 3e (dossier "Beta"), il n'a pas le temps → il ignore, ça reviendra demain.
- Simulation utile : elle a fait remonter la question suivante d'elle-même → **qu'est-ce qui distingue, dans cette liste, une tâche "j'ai encore 10 jours" d'une tâche "l'audience était hier et je n'ai toujours pas fait la diligence" ?** Rien actuellement. C'est le sujet de la question 5 de Tobie — voir plus bas.

## Question 4 — "Est-ce qu'il pourra utiliser l'app offline ?"

**Réponse concrète, pas juste "oui" :**
- **Consulter / ajouter / cocher "C'est fait" hors-ligne : oui.** Firestore (choisi justement pour ça) garde une copie locale sur le téléphone et resynchronise automatiquement dès que le réseau revient. Aucun développement supplémentaire requis, c'est le comportement natif.
- **Recevoir la notification quotidienne hors-ligne : partiellement.** Firebase met le message en attente sur ses serveurs et le livre **dès que le téléphone se reconnecte** (comportement standard FCM). Donc s'il est hors réseau toute une journée, il recevra le rappel dès qu'il retrouve du réseau — pas de rappel perdu.
- **🟠 Point à régler (N) :** si le père reste hors-ligne plusieurs jours (ex: déplacement), il pourrait recevoir plusieurs notifications d'un coup, une par jour manqué — ce qui recréerait un mini flux de notifications (le problème de départ !). **Solution concrète :** utiliser un `collapse_key` Firebase — la nouvelle notification **remplace** l'ancienne au lieu de s'ajouter, donc il ne voit jamais qu'**une seule** notification, toujours à jour, peu importe combien de jours sont passés.
- Premier lancement de l'app : nécessite une connexion au moins une fois (pour créer son compte et charger les premières données).

## Question 4bis — "Pourra-t-il retrouver ses données s'il perd ou réinitialise son téléphone ?"

**Réponse concrète et honnête, pas d'esquive :**
- Les données "normales" (noms de code, dates, statuts) sont dans le cloud Firebase → en se reconnectant avec son compte sur un nouveau téléphone, **tout revient automatiquement**. Pas de perte.
- **🔴 Sauf les notes privées chiffrées.** Si la clé de chiffrement n'existe que sur l'ancien téléphone (option envisagée jusqu'ici), perdre le téléphone = notes privées **perdues pour toujours**, même si le texte chiffré est toujours dans Firebase (illisible sans la clé).

**Solution concrète (résout aussi le point L, laissé en suspens depuis le round 2) :**
La clé de chiffrement n'est **pas générée par le téléphone**, elle est **dérivée d'une phrase secrète que le père choisit et mémorise** (comme le "mot de passe maître" de Bitwarden ou Standard Notes). Cette phrase n'est stockée nulle part, ni sur le téléphone ni dans Firebase. Conséquence :
- S'il change de téléphone : il retape sa phrase secrète, la même clé est recalculée, ses notes redeviennent lisibles. **Aucune perte.**
- **Mais** : s'il oublie cette phrase, ces notes précises sont perdues pour toujours — personne, pas même nous, ne peut les récupérer (c'est le prix d'une vraie confidentialité : si on pouvait la récupérer, ça voudrait dire qu'un tiers a un moyen d'accès, donc ce ne serait plus vraiment confidentiel).
- Ce risque ne concerne **que le champ note privée optionnelle** — tout le système de rappels (noms de code, dates, relances, bilan) continue de fonctionner normalement même s'il oublie sa phrase.

**Ce point doit être expliqué clairement au père avant qu'il choisisse sa phrase secrète** — ce n'est pas un détail technique, c'est un choix qui lui appartient (règle sécurité : décision qui touche à l'architecture des données = on l'explique, on ne décide pas à sa place).

## Question 5 — "Comment se comporte l'app quand il n'arrive malgré tout pas à faire ce qu'il doit faire à temps ?"

### 🔴 Gap trouvé (O) — Aucune distinction entre "encore le temps" et "trop tard"
Actuellement, une tâche reste juste "à faire" indéfiniment, qu'elle soit à J-14 ou que l'audience soit déjà passée depuis 3 jours. Dans la vraie vie d'un magistrat, ces deux situations n'ont **rien à voir** en termes de gravité — et les mélanger dans la même liste grise l'information la plus critique.

**Solution concrète :** un 3e statut calculé automatiquement, **"En retard"** — dès que `date_declenchante` (la date de l'audience ou l'échéance du courrier) est dépassée et que la tâche n'est toujours pas "Fait". Ce statut :
- s'affiche visuellement différent (ex: rouge) dans l'écran "Aujourd'hui" et dans le bilan hebdomadaire,
- reste dans la relance quotidienne (il continue d'être rappelé, comme demandé — "garde-fou"),
- est compté séparément dans le bilan ("2 en retard" vs "3 encore à venir") pour qu'il voie immédiatement où est l'urgence réelle.

---

## Récapitulatif des corrections à intégrer (round 3 → MVP v4)
- **O** : ajout du statut calculé "En retard".
- **P** : l'ajout groupé crée aussi une Tâche par défaut par Dossier.
- **Q** : clé de chiffrement dérivée d'une phrase secrète mémorisée (pas liée au téléphone) — résout aussi le point L du round 2.
- **N** : `collapse_key` sur les notifications pour éviter l'empilement après une coupure réseau longue.
- **T** : l'écran de relecture (point K) doit rester ultra-léger, une seule confirmation globale.
- **S** (nouveau, checklist dev, pas un gap de conception) : les règles de sécurité Firestore doivent restreindre l'accès aux seules données du compte du père — sinon toute l'architecture de confidentialité repose sur du sable côté serveur.
