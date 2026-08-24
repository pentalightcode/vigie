# Fiche de note — Red Team de vérification (Phase 1 + corrections en direct)

**Date :** 2026-08-07
**Méthode :** relecture systématique du code (pas juste de mémoire) — recherche de références obsolètes, vérification fichier par fichier, recompilation.

---

## ✅ Ce qui a été vérifié comme correct

1. **Aucune référence obsolète** : ni `dateAudience` (ancien nom de champ), ni `TypeTache.diligence/ecriture` (anciens types supprimés) ne traînent nulle part dans le code.
2. **Fichiers morts supprimés proprement** : `aujourdhui_screen.dart` et `parseur_role.dart` bien effacés (plus utilisés après les refontes).
3. **Compilation propre** (`flutter analyze` → 0 problème) à chaque étape.
4. **Double confirmation bien appliquée aux 4 actions à risque** : marquer fait, annuler un fait, supprimer une tâche, supprimer un dossier — vérifié un par un dans le code, aucun oubli.
5. **Règles de sécurité Firestore cohérentes** : dossiers, tâches et réglages utilisateur tous protégés par uid.

## 🔴 2 vrais problèmes trouvés et corrigés pendant cette vérification

### 1. Incohérence type/description sur l'écran "Ajouter"
Si on changeait le type (ex: passer de "Audience" à "Courrier") sans toucher au champ "Détail", celui-ci gardait le texte par défaut "Diligences avant audience" — incohérent avec le type réellement choisi. **Corrigé** : le champ se resynchronise automatiquement avec le type choisi, sauf si le père l'a lui-même modifié à la main (dans ce cas, on respecte ce qu'il a tapé).

### 2. Un trou de sécurité fin dans les règles Firestore
Rien n'empêchait, techniquement, de modifier le champ `uid` d'un dossier ou d'une tâche déjà existant lors d'une mise à jour — un client mal intentionné aurait pu changer le propriétaire d'un document. **Corrigé** : les règles vérifient maintenant explicitement que le `uid` ne change jamais lors d'une modification.

## Conclusion
Tout ce qui était prévu pour la Phase 1 est fait, plus les corrections demandées pendant tes tests en direct (terminologie, ajout groupé en formulaire, bilan par période). Les 2 problèmes trouvés ici étaient réels mais mineurs (un souci de cohérence d'affichage, un renforcement de sécurité préventif) — rien de cassé, rien d'oublié dans le plan.

**On peut avancer vers la Phase 3 en confiance.**
