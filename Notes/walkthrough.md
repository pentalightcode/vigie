# Finalisation de la Phase 2 : Déploiement et iOS (PWA)

## Résumé des travaux
Nous avons terminé la **Phase 2 (Collaboration)** du projet Vigie en déployant l'ensemble de notre travail en production. L'application supporte désormais entièrement le workflow d'approbation et la gestion granulaire des rôles.

Au cours de cette dernière session, nous avons résolu deux problématiques majeures :

1.  **Suppression de dossiers partagés par un administrateur :**
    -   *Problème :* Les règles de sécurité empêchaient un administrateur sans le droit de `modération` de supprimer un dossier partagé en un seul *batch* client, car la suppression en cascade touchait aux tâches/entrées de journal.
    -   *Solution :* Déplacement de cette logique complexe sur une **Cloud Function (`supprimer_dossier_partage`)**. Le client Flutter appelle désormais cette fonction, qui s'exécute avec les privilèges d'administration tout en vérifiant l'identité et les droits (rôle administrateur) de l'appelant.

2.  **Distribution sur iOS :**
    -   *Problème :* La publication sur l'App Store n'était pas envisageable dans l'immédiat en raison de sa complexité et de ses délais. Un simple "raccourci web" n'offrait pas l'expérience applicative native souhaitée.
    -   *Solution :* Déploiement de l'application sous forme de **Progressive Web App (PWA)** via Firebase Hosting. 
    -   Implémentation d'une bannière interactive (`BanniereInstallationIos`) spécifique aux utilisateurs naviguant depuis Safari sous iOS. Cette bannière leur explique comment "Ajouter à l'écran d'accueil", ce qui installe la PWA comme une véritable application autonome sur leur appareil (sans barre de navigation, icône dédiée).

## Déploiements effectués

-   **Cloud Functions & Firestore Rules** : Déployés avec succès. La logique de validation backend et les cascades asynchrones sont actives.
-   **Web App (PWA)** : Déployée sur Firebase Hosting (`https://secretaire-aje.web.app`). C'est le point d'entrée pour les utilisateurs iOS.
-   **Android APK** : L'exécutable pour Android a été compilé (`flutter build apk --release`) et a été extrait sur votre bureau (`~/Desktop/Vigie-Phase2.apk`) prêt à être distribué aux utilisateurs Android.

## État des documents de suivi
Les fichiers `PROGRESS.md` et le journal de *Red Team* ont été mis à jour pour refléter l'achèvement de ces tâches. La discipline de ne déployer qu'après un contrôle qualité strict a été respectée.
