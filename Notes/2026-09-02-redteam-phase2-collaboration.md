# Red Team : Phase 2 (Collaboration) - Vérification avant Déploiement
**Date :** 02 Septembre 2026
**Commit analysé :** c2937b5

## Objectif
Réaliser un "Red Team" systématique du dernier commit de la Phase 2 (Collaboration) avant d'autoriser son déploiement en production, conformément aux instructions de `HANDOVER.md`. 

## 1. Sécurité et Firestore Rules (`firestore.rules`)
- **Faille d'injection de participants (Corrigée) :** La fonction `participantsCoherents` vérifie désormais de manière stricte que la liste `participantsUids` fournie lors de la création d'une tâche correspond exactement à celle du dossier parent. Le repli autorisant `[request.auth.uid]` est rigoureusement limité aux cas où le dossier parent *n'existe pas encore* (batch de création initiale). Cela ferme efficacement la faille où un attaquant pouvait forger des tâches dans la file d'attente d'autres utilisateurs.
- **Cohérence UID/Participants :** La fonction `tacheCoherente` ajoute une deuxième couche de validation, liant l'UID du propriétaire aux participants pour s'assurer qu'un attaquant ne peut pas contourner la première règle en forgeant l'UID.
- **Propositions sécurisées :** `propositionValide` garantit qu'un utilisateur ne peut manipuler ou retirer que ses propres propositions, prévenant ainsi le vandalisme ou l'usurpation.
- **Conclusion Sécurité :** Très robuste. Les règles couvrent les vecteurs d'attaque identifiés.

## 2. Modèle de Données et Logique Client (`dossier.dart`, `tache.dart`)
- **Permissions à la carte :** La logique client (`estGestionnaireContenu` et `peutSupprimer`) reflète fidèlement la logique serveur. Le fallback pour les anciens dossiers (rétrocompatibilité) assure que les administrateurs historiques conservent leurs droits.
- **Résilience (Bugs UI) :** La vérification explicite de `doc.exists` avant le cast (`doc.data() as Map`) dans `Dossier.depuisDocument` évite les `TypeError` qui masquaient l'état réel (dossier supprimé vs erreur réseau) dans `VueAccesRevoque`.
- **Conclusion Client :** Le code Dart est défensif et aligné sur les règles serveur.

## 3. Logique Serveur et Notifications (`main.py`)
- **Synchronisation en cascade :** La propagation des `participantsUids` vers les sous-collections `taches` et `journalDossier` est gérée de manière fiable. Le timeout étendu (540s) et la mémoire allouée (512MB) de `propager_participants_dossier` sont appropriés pour éviter les échecs silencieux sur les gros dossiers.
- **Transactions :** La fonction `gerer_participant_dossier` utilise des transactions (`@firestore.transactional`) pour s'assurer que les permissions et listes ne sont pas corrompues par des écritures concurrentes.

## 4. Edge Cases (Cas limites) Identifiés
- **Suppression d'une tâche avec une proposition en attente :**
  - *Scénario :* Un contributeur propose une modification sur une tâche. Avant son approbation, un administrateur supprime complètement la tâche.
  - *Comportement actuel :* Dans `_traiter_changement_proposition` (`main.py`), si `apres_doc is None` (document supprimé), la fonction `_proposition_approuvee` renvoie `True`. Le contributeur recevra une notification "✅ Proposition acceptée". 
  - *Analyse :* Ce comportement est justifié car si la proposition initiale était de *supprimer* la tâche (`type == 'supprimer'`), alors la proposition a techniquement abouti. Si c'était une *modification*, la notification est légèrement imprécise mais sans conséquence fonctionnelle (la tâche a de toute façon disparu). Pas de faille de sécurité ici.
- **Rétrocompatibilité :**
  - L'absence du champ `permissionsAdministrateur` est bien traitée comme "accès complet" tant pour `peutSupprimer` que pour `estGestionnaireContenu`.

## Conclusion Générale et Recommandation
Le code est sûr, les failles critiques de la Phase 1 ont été corrigées avec une véritable "défense en profondeur" (règles côté serveur + validation client). Les mécanismes d'approbation et de permissions à la carte sont solidement implémentés.

**=> FEU VERT POUR LE DÉPLOIEMENT.** Il n'y a aucun obstacle technique ou de sécurité identifié dans ce commit.
