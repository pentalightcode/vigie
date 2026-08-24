# Fiche de note — Barre de progression par dossier

**Date :** 2026-08-09
**Idée de Tobie :** un dossier contient plusieurs tâches ; si une tâche sur cinq est faite, le dossier a "avancé" de 20%. Afficher une barre de progression.

---

## 1. Pourquoi c'est une bonne idée
Aujourd'hui, un dossier avec 5 tâches et un dossier avec 1 tâche se ressemblent visuellement — pas de sens de l'ampleur du travail restant. Une barre de progression donne une vue d'ensemble immédiate, utile en particulier dans "Bilan" et sur l'écran "À traiter" où les dossiers sont regroupés.

## 2. Petits pièges réglés avant de coder
- **Dossier à 0 tâche** (toutes supprimées) : afficher "0/5" donnerait une division par zéro. → on masque simplement la barre s'il n'y a aucune tâche.
- **Quelles tâches comptent ?** J'inclus aussi les tâches "en attente" (pas encore actives) dans le calcul, pas seulement les tâches visibles aujourd'hui — sinon un dossier pourrait afficher "100%" alors qu'il reste en réalité une échéance future non traitée. Ça correspond à ta définition : "si je ne fais pas toutes les tâches, je n'ai pas fini de traiter le dossier."
- **Où l'afficher** : sur l'écran de détail d'un dossier (déjà présent), et sur chaque carte dossier de l'écran "À traiter" (là où tu regardes le plus souvent).

## 3. Décision
Calcul simple et transparent : `tâches faites / total des tâches du dossier`, recalculé en direct à chaque changement (pas de champ stocké séparément qui pourrait se désynchroniser).
