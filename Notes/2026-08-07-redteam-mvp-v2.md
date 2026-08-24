# Fiche de note — Red Team round 2 (sur le MVP v2)

**Date :** 2026-08-07
**Objectif :** re-challenger le MVP v2 (qui corrigeait A, B, C, D) pour voir ce qui reste fragile.

---

## 🔴 Gaps critiques

### H. Le "push silencieux" (solution retenue pour le point B) dépend d'un mécanisme peu fiable, surtout sur iPhone
Pour éviter d'afficher du contenu sensible dans la notification, le v2 propose un push "silencieux" qui réveille l'app en arrière-plan pour qu'elle génère elle-même une notification locale. Problème : **sur iPhone, ce type de réveil en arrière-plan n'est pas garanti** — iOS peut le retarder ou l'ignorer (économie de batterie, app fermée, etc.). Résultat possible : le rappel du jour n'arrive tout simplement pas, un jour sur trois — ce qui casse la fonctionnalité la plus critique du produit.
**Correction plus robuste :** pas besoin d'un mécanisme silencieux compliqué. On envoie une **notification normale** (donc livrée de façon fiable par Android/iOS, même app fermée), mais avec un texte **volontairement générique** — jamais de nom de dossier, jamais le compte exact si on veut être extra prudent. Ex : *"Ton assistant a des choses à te montrer aujourd'hui."* Simple, fiable, et tout aussi confidentiel.

### I. Toujours pas de flux "modifier une date" — remonté de moyen à critique
Le v2 avait mis ça de côté comme "gap moyen, pas bloquant". En y repensant : il a **insisté** sur le fait que les dates d'audience changent souvent ("*c'est un programme qui change*"). Si ce flux n'existe pas dès le premier prototype, les rappels vont rapidement devenir **faux** dans la réalité (dès la 2e ou 3e semaine d'usage) — et une app qui donne de mauvaises dates, il va vite arrêter de lui faire confiance et revenir à ses anciennes habitudes. Ce n'est donc pas un "nice to have", c'est une condition pour que le prototype soit testable sérieusement.
**Correction :** ajouter dès le MVP un bouton "Modifier la date" sur un Dossier existant, qui recalcule automatiquement `date_premier_rappel` de toutes ses tâches liées.

### J. Aucun verrou sur l'app elle-même
On a construit toute une architecture de confidentialité (noms de code + chiffrement) — mais si n'importe qui prend le téléphone déverrouillé de son père et ouvre l'app, il voit direct la liste des dossiers et les notes déchiffrées. Le maillon faible, c'est l'accès à l'app elle-même, pas juste les données en base.
**Correction :** ajouter un verrouillage propre à l'app (code PIN ou empreinte/Face ID), séparé du verrouillage du téléphone.

## 🟠 Gaps moyens

### K. Pas de vérification avant d'enregistrer un ajout groupé
Il va coller/taper plusieurs lignes d'un coup (le "rôle" de la semaine). S'il fait une faute de date sur une ligne, rien ne l'avertit — l'erreur ne sera visible que dans 2 semaines, au pire moment.
**Correction :** un écran de relecture ("voici ce que j'ai compris, tu confirmes ?") avant d'enregistrer un ajout groupé.

### L. Pas de stratégie pour la clé de chiffrement
Si son téléphone est perdu/cassé/changé, et que la clé de chiffrement n'existe que dessus, toutes les notes privées deviennent illisibles pour toujours. Ce n'est pas forcément un problème (on peut décider que c'est acceptable, les notes étant optionnelles), mais ça doit être un choix **conscient**, pas un oubli.

## 🟡 Mineur
### M. Heure d'envoi du digest quotidien non définie
Vu qu'il commence sa journée par une réunion, le digest devrait probablement arriver avant — à confirmer avec lui plus tard, pas bloquant pour coder le MVP.

---

## Conclusion
H, I, J sont à corriger avant de coder (ils touchent la fiabilité et la confidentialité — les deux piliers du projet). K et L sont à trancher consciemment mais peuvent attendre une itération de plus si besoin.
