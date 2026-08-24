# Fiche de note — Red Team du périmètre MVP

**Date :** 2026-08-07
**Objectif :** relire le MVP proposé avec un œil critique, en confrontant chaque choix aux vrais mots du père dans l'interview. Trouver les trous AVANT de coder.

---

## 🔴 Gaps critiques (cassent l'objectif du projet si pas corrigés)

### A. Une notification par tâche = on recrée exactement le problème de départ
Le MVP disait "notification listant les échéances actives" — mais si techniquement ça envoie **un push par échéance**, avec 7 à 9 audiences/semaine + leurs diligences, ça peut vite faire 5-10 notifications séparées par jour. Or c'est **très exactement** ce qu'il a dénoncé au début : *"quand tu as beaucoup trop de notifications... ça vient, mais tu sais même pas que c'est venu."* On aurait reconstruit le problème qu'on voulait résoudre.
**Correction :** un seul push quotidien, un seul "digest" qui résume tout ("Aujourd'hui : 3 choses à traiter"), jamais une notif par item.

### B. Le chiffrement ne sert à rien si le contenu passe en clair dans la notification
On a décidé que les données chiffrées ne doivent jamais être lisibles par un tiers (Google/Firebase, toi). Mais une notification push classique envoie généralement son texte (titre + contenu) **en clair à travers les serveurs de Google/Apple** pour l'afficher sur l'écran verrouillé. Si le nom de code ou la note apparaît dans cette notification, on casse la promesse de confidentialité au moment précis où l'app est le plus utilisée.
**Correction :** la notification push doit rester **muette/générique** ("Tu as des tâches à traiter aujourd'hui"), sans détails. Les vrais détails ne s'affichent qu'une fois l'app ouverte, où le téléphone déchiffre localement.

### C. Le formulaire "ajouter une échéance une par une" recrée sa plus grosse perte de temps actuelle
Il a dit explicitement que ce qui lui fait perdre le plus de temps aujourd'hui, c'est de **"recenser les trucs à faire, remplir les dates dans l'agenda."** Il reçoit un **"rôle"** chaque semaine (la liste des dossiers qui passent), publié d'un coup par la juridiction. Si le MVP ne permet que d'ajouter *une* échéance à la fois, on lui redonne la même corvée, juste dans une autre app.
**Correction :** prévoir une saisie rapide/groupée (ex: coller/saisir plusieurs lignes d'un coup pour tout le "rôle" de la semaine), pas seulement un formulaire un-par-un.

### D. Pas de notion de "Dossier" regroupant plusieurs tâches
Il pense "par dossier" (écritures + diligences + courriers liés à UNE affaire), pas par tâche isolée. Le modèle actuel (une seule liste plate d'"Échéances") ne regroupe rien. Résultat : le bilan de fin de semaine listerait des lignes déconnectées au lieu de dire "Dossier Alpha : 2 choses faites sur 3" — moins utile, moins lisible pour lui.
**Correction :** ajouter un niveau **Dossier** (nom de code) qui peut contenir plusieurs Échéances/tâches liées.

## 🟠 Gaps moyens (à corriger, mais pas bloquants)

### E. Changement de date pas géré explicitement
Il l'a dit : *"c'est un programme qui change... si ça change je modifie."* Il faut un vrai flux "modifier la date d'une échéance existante", qui recalcule automatiquement la date de premier rappel — pas juste supposé possible "en théorie".

### F. Ordre d'affichage du digest quotidien
Même sans priorisation automatique (il garde la main dessus), le digest doit au moins être trié par urgence (le plus proche en premier), sinon c'est juste une liste en vrac.

## 🟡 Amélioration mineure (facultative, pas urgente)
### G. Bouton "C'est fait" directement depuis la notification, sans ouvrir l'app — plus rapide pour lui vu qu'il est débordé. Techniquement faisable avec les actions rapides des notifications (Android/iOS), mais pas indispensable pour un tout premier prototype.

---

## Conclusion
Les gaps A, B, C, D sont structurants — ils changent le modèle de données et l'architecture des notifications. Mieux vaut les intégrer **avant** la première ligne de code plutôt que de refactorer après coup.
