# Vigie — Document de transfert de connaissances

**Rédigé le :** 29 août 2026
**Pour :** toute personne (ou IA) qui rejoint le projet sans avoir participé aux échanges précédents.
**But :** donner une vision complète — architecture, décisions et leur pourquoi, état actuel de chaque service externe, limites connues — sans avoir à reconstituer l'historique à partir de zéro.

**Ce document ne contient AUCUNE valeur de secret** (mots de passe, clés API...) — volontairement. Voir la section "Secrets — inventaire des emplacements" tout en bas : elle dit où chaque secret vit, jamais ce qu'il vaut. Les valeurs elles-mêmes doivent être transmises à un nouveau collaborateur par un canal séparé et sécurisé (gestionnaire de mots de passe, remise en main propre), jamais copiées dans ce fichier ni collées dans une conversation avec une IA.

À lire dans l'ordre : ce document d'abord (vue d'ensemble), puis `PROGRESS.md` (journal chronologique détaillé de chaque session de travail), puis `Notes/` (fiches de décision individuelles, surtout utiles pour la phase de conception initiale, dates du 05 au 24 août 2026). Le code source lui-même contient énormément de contexte "pourquoi" en commentaire — c'est une convention de la maison, voir plus bas.

---

## 1. Le projet, en une minute

**Vigie** est une application (Android + Web) de suivi d'échéances pensée pour des professions où la confidentialité n'est pas négociable — l'exemple concret et le premier vrai utilisateur visé est le père de Tobie, magistrat au Bénin, débordé par le suivi manuel de ses dossiers.

Principe central : l'utilisateur ne désigne **jamais** ses dossiers par leur vrai nom — il choisit lui-même un nom de code pour chacun. L'app suit les échéances (audiences, rendez-vous, dates limites), relance jusqu'à confirmation que c'est fait, et propose un bilan périodique.

**Éditeur :** PENTALIGHTCODE (Tobie Vincent Amadou), Cotonou, Bénin.
**Utilisateurs réels actuels (29/08/2026) :** 3 comptes existent, dont Tobie et son père. Pas encore publiée sur le Play Store — en cours de vérification Google (voir section 6).

## 2. Architecture technique

- **Client :** Flutter (Dart), buildé pour Android (cible principale, APK signé distribué directement depuis le site le temps que le Play Store soit prêt) et Web (accessible sur `vigie.pentalightcode.com`, sert aussi de page de téléchargement de l'APK).
- **Backend :** Firebase — projet `secretaire-aje`.
  - **Auth** : connexion par lien magique email (pas de mot de passe) — `firebase_auth`, `sendSignInLinkToEmail`.
  - **Firestore** : base de données principale. Collections : `dossiers`, `taches`, `journalDossier` (top-level, filtrées par `uid`) ; `utilisateurs/{uid}/` avec sous-collections `naturesDossier`, `notifications`, `propositions`, `connexionsGoogle` (+ sous-collections internes `emailsTraites`/`tachesGoogleTraitees`/`evenementsGoogleTraites`), `etatSync`, `etatsNotifies` ; `config/version` (public, lecture seule, pour la bannière de mise à jour).
  - **Cloud Functions** (Python 3.14, 2ᵉ génération, `app/functions/main.py`) : logique serveur — digest quotidien de rappels, scan Gmail/Tasks/Calendar, gestion des connexions Google (chiffrement/révocation des jetons), suppression de compte, publication de version, résumé IA du bilan (Groq).
  - **FCM** : notifications push.
  - **Hosting** : sert le build web + les pages publiques statiques (`/apropos/`, `/confidentialite/`) + l'APK téléchargeable + `.well-known/assetlinks.json` (App Links Android).
  - **Secret Manager** : tous les secrets serveur (voir section 8).
- **Intégrations externes (optionnelles, activées par l'utilisateur)** : Google (Gmail/Tasks/Calendar, lecture seule, OAuth), Groq (résumé IA du bilan + extraction IA des dates d'emails, désactivé par défaut, avertissement avant activation).
- **i18n** : français (langue de référence) + anglais, 321+ clés, `flutter_localizations` + fichiers `.arb` dans `lib/l10n/`.

## 3. Principes de sécurité et de confidentialité — ce qui est réellement construit aujourd'hui

**Point important à comprendre avant de faire des hypothèses** : les toutes premières notes de conception (`Notes/2026-08-06-redteam-anonymisation.md`, `Notes/2026-08-07-mvp-scope.md`) envisageaient un **chiffrement côté téléphone** (clé dérivée d'une phrase secrète mémorisée par l'utilisateur, jamais stockée) pour un champ "note privée" optionnel — une protection allant au-delà du simple contrôle d'accès serveur. **Ce chiffrement n'a jamais été implémenté.** Le champ `notePrivee` existe encore dans `lib/models/dossier.dart` avec un commentaire `// chiffré côté téléphone avant écriture (à venir)`, mais il n'est lu ni écrit nulle part dans l'interface — code mort, remplacé en pratique par le système `journalDossier` (notes de dossier), qui lui **ne chiffre rien côté client** et repose entièrement sur les règles Firestore.

**Concrètement, aujourd'hui, la confidentialité de Vigie repose sur deux mécanismes, pas trois :**
1. **Les noms de code** — aucune vraie information n'est demandée à l'utilisateur, c'est lui qui choisit le libellé affiché pour chaque dossier.
2. **Le contrôle d'accès côté serveur** (règles Firestore, `uid`-scopées) — quiconque a accès à la base de données avec les identifiants Admin (PENTALIGHTCODE, ou un compromis du projet Firebase) peut lire l'intégralité des dossiers/tâches/notes en clair. **Il n'y a pas de troisième couche de chiffrement bout-en-bout.**

Ce n'est pas nécessairement un problème — le modèle actuel (noms de code + contrôle d'accès serveur solide) est une pratique de sécurité légitime et suffisante pour beaucoup d'usages. Mais c'est **différent** de ce que les toutes premières notes envisageaient comme protection renforcée, et un nouveau collaborateur doit le savoir avant de supposer le contraire ou de communiquer une promesse de sécurité qui ne correspond pas à la réalité du code.

**Autre point non résolu, trouvé dans les notes fondatrices, jamais retranché depuis** : `Notes/2026-08-06-confidentialite-donnees.md` soulève que les données que le père manipule (affaires judiciaires) sont probablement des "données sensibles" au sens de la loi béninoise sur la protection des données (Code du numérique, loi n°2017-20, autorité APDP), et recommandait prudemment de commencer par une solution 100% locale, le temps de clarifier les obligations légales exactes (notamment le transfert de données hors du Bénin, puisque Firebase est un cloud américain/européen). **Le projet est parti directement sur Firebase (cloud, hors Bénin)** sans qu'une trace dans ce dépôt ne montre qu'un avis juridique formel ait été obtenu entre-temps. Ce n'est pas forcément un problème (le père a probablement statué lui-même, étant magistrat), mais c'est un point à vérifier explicitement avec Tobie plutôt qu'à supposer réglé.

### Ce qui EST solidement construit (audit de sécurité complet mené le 28-29/08/2026, voir `PROGRESS.md` pour le détail)
- Verrou PIN local (indépendant de Firebase Auth) : hachage PBKDF2-HMAC-SHA256 (120 000 itérations, sel aléatoire), jamais stocké en clair, verrouillage progressif après échecs répétés.
- Jetons OAuth Google : chiffrés (Fernet/AES) avec une clé qui ne vit que dans Secret Manager, jamais renvoyés au téléphone, révoqués auprès de Google à la déconnexion et à la suppression de compte.
- Notifications push : contenu générique par défaut sur l'écran verrouillé (jamais le nom de code d'un dossier ni le contenu d'un email), sécurisé par défaut (opt-in explicite requis pour afficher un texte réel).
- Règles Firestore relues intégralement : chaque collection sensible ancrée sur `uid`, champs immuables protégés à la mise à jour.
- Aucune vulnérabilité connue dans les 148 dépendances Flutter (base OSV de Google) ni dans les dépendances Python (`pip-audit`), vérifié le 29/08/2026 — à revérifier périodiquement, ce n'est pas figé dans le temps.
- Limite connue et **acceptée en connaissance de cause par Tobie** : un attaquant avec accès root/ADB physique au téléphone déjà déverrouillé et connecté peut contourner le verrou PIN local (limite partagée par toute app de verrou local — WhatsApp, Signal, etc. — pas spécifique à Vigie).

## 4. Conventions de la maison (style, pas négociable, à respecter)

- **Identifiants en français** dans tout le code (`nomCodeDossier`, `dateDeclenchante`, `_envoyer`...) — délibéré, ne pas "corriger" vers l'anglais.
- **Commentaires rares, uniquement le "pourquoi"** — jamais ce que fait le code (les noms de variables/fonctions le disent déjà), toujours pourquoi une décision non-évidente a été prise, avec la date et le contexte (ex: `// trouvé le 2026-08-20 avec le vrai message d'erreur montré par Tobie`). C'est la source la plus riche de contexte historique dans ce projet — la lire vaut souvent mieux que deviner.
- **`PROGRESS.md` mis à jour après chaque étape significative**, jamais après coup en bloc — c'est une règle de checkpoint permanente, voir `/home/tobie/CLAUDE.md` (config globale, s'applique à tous les projets de Tobie).
- **`Notes/` pour les fiches de décision individuelles**, une par sujet, souvent avec un historique de versions successives corrigées par "Red Team" (challenger sa propre proposition avant de la valider — méthode explicitement demandée par Tobie dès la conception).
- **Discipline de déploiement stricte** : grouper plusieurs changements liés en un seul déploiement, ne jamais déployer après chaque micro-modification. Raison historique : un incident du 25/08/2025 (Netlify, projet différent) où 17 déploiements en une session ont épuisé un quota mensuel. S'applique à Vigie même si Firebase ne facture pas de la même façon.
- **Toujours vérifier le résultat réel après une action** (`curl` sur le site après un déploiement, pas juste "la commande a dit succès") — plusieurs bugs de ce type ont été trouvés dans ce projet (build web périmé redéployé sans changement réel, par exemple).

## 5. Rituel de build + déploiement (à suivre précisément)

1. Bump de version dans `app/pubspec.yaml` (`version: X.Y.Z+N`, le `+N` doit toujours augmenter).
2. `flutter analyze` — doit rester propre (2 infos pré-existantes sans rapport, `dart:html` déprécié dans `telechargement_web.dart`, sans impact).
3. `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`.
4. Copier l'APK vers `app/web/telecharger/Vigie.apk` ET `~/Téléchargements/Vigie.apk`.
5. `flutter build web --release` → `build/web/`.
6. Copier l'APK dans `build/web/telecharger/Vigie.apk` (le build web ne le fait pas automatiquement).
7. Vérifier que `build/web/.well-known/assetlinks.json`, `/apropos/`, `/confidentialite/` ont bien survécu au build (ils vivent dans `app/web/` et sont copiés par `flutter build web`, mais ça a déjà cassé silencieusement une fois).
8. Si `functions/main.py` a changé : `firebase deploy --only functions` (depuis `app/`).
9. `firebase deploy --only hosting --force` (depuis `app/`) — **attention** : si vous avez modifié un fichier statique dans `app/web/` (les pages `/apropos/`, `/confidentialite/`) sans avoir refait `flutter build web` derrière, ce déploiement republie l'ancien `build/web/` sans le changement — toujours vérifier après coup avec `curl`.
10. Publier le numéro de version pour déclencher la bannière de mise à jour :
    ```bash
    cd app && ADMIN_PUBLICATION_SECRET="$(firebase functions:secrets:access ADMIN_PUBLICATION_SECRET)" python3 scripts/publier_version.py <version> <build>
    ```

## 6. État actuel des systèmes externes (au 29/08/2026)

- **Firebase / GCP** : projet `secretaire-aje`, forfait Blaze (paiement à l'usage) actif. Carte bancaire enregistrée = virtuelle, refusée par Google Cloud Billing pour ce type d'usage ; une vraie carte physique sera nécessaire si l'usage dépasse le quota gratuit (pas urgent, factures à 0,00 $ jusqu'ici).
- **Domaine** : `pentalightcode.com` acheté chez Porkbun, `vigie.pentalightcode.com` pointé vers Firebase Hosting, propriété vérifiée dans Google Search Console (couvre tous les sous-domaines).
- **GitHub** : `github.com/pentalightcode/vigie`, dépôt public (choix explicite de Tobie), transféré depuis un dépôt personnel. `git status` doit toujours être vérifié avant tout commit — plusieurs recherches de secrets ont déjà été faites avant chaque push, à refaire par réflexe.
- **Vérification OAuth Google** (pour les scopes Gmail/Tasks/Calendar en lecture seule) : **en cours, 3ᵉ soumission envoyée le 29/08/2026.** Deux rejets précédents (vidéo de démo inaccessible sur YouTube — modération automatique supprimant la vidéo à répétition, cause exacte inconnue). La 3ᵉ tentative utilise une vidéo hébergée à la fois sur Google Drive (dans le fil email avec l'équipe Trust & Safety) et sur YouTube (champ obligatoire "Lien YouTube" dans Google Cloud Console → Google Auth Platform → Accès aux données → section "Démonstration vidéo" — ce champ refuse strictement tout lien qui n'est pas youtube.com/youtu.be, Drive seul ne suffit pas ici). Délai annoncé par Google : premier email sous 3-5 jours, procédure complète 4-6 semaines. **Si une nouvelle vidéo doit être réenregistrée** : montrer l'écran de consentement OAuth complet en ANGLAIS (bascule de langue nécessaire), scopes développés via "Show all services", chaque fonctionnalité démontrée séparément, environnement de production réelle (pas de test).
- **Play Store** : pas encore soumis, bloqué sur la vérification OAuth ci-dessus (Google déconseille la vérification pour un usage <100 utilisateurs mais Tobie a choisi explicitement de continuer). Le scope `gmail.readonly` étant "restreint", une évaluation de sécurité CASA (payante, annuelle) sera probablement exigée après l'approbation initiale.
- **Signature Android** : vraie clé de release générée le 24/08/2026 (`app/android/upload-keystore.jks`), remplace l'ancienne clé de debug. **Cette clé n'a pas de sauvegarde connue en dehors de cette machine** — point critique non résolu, si la machine est perdue sans sauvegarde, impossible de mettre à jour l'app une fois publiée sur le Play Store, aucune récupération possible.

## 7. Failles de sécurité trouvées et corrigées (audit du 28-29/08/2026)

Résumé — détail complet dans `PROGRESS.md` à la date du 28-29/08/2026 :
1. PIN stocké en clair, sans limite de tentatives → hachage PBKDF2 + verrouillage progressif.
2. Contenu confidentiel (nom de dossier, extrait d'email) affiché sur l'écran verrouillé via les notifications push → texte générique par défaut, sécurisé par défaut.
3. Notifications "fantômes" (quasi jamais reçues en journée) → cause : calcul d'urgence en jours entiers, ne changeait qu'à minuit ; corrigé avec deux créneaux garantis (9h/18h).
4. Texte envoyé à l'IA Groq (résumé du bilan) sans limite de taille → plafonné, cohérent avec le reste du code.
5. Suppression de compte incomplète (ne supprimait qu'une partie des données, ne révoquait jamais la connexion Google auprès de Google) → déplacé côté serveur, révocation réelle + suppression récursive complète de toutes les sous-collections.
6. Sujet d'email non plafonné avant envoi à l'IA Groq → même correctif que le point 4.
- Risque accepté (pas corrigé, décision explicite de Tobie) : contournement du PIN local possible avec un accès root/ADB physique au téléphone.
- Zones vérifiées saines : AndroidManifest, lien magique de connexion, logs, IDOR sur les fonctions serveur, chiffrement des jetons Google, injection de prompt IA, dépendances tierces (0 CVE connue), `firestore.indexes.json`, Firebase Storage (pas utilisé), point d'administration `publier_version_admin`.

## 8. Secrets — inventaire des emplacements (jamais les valeurs)

| Secret | Où il vit | Jamais où |
|---|---|---|
| Clé de signature Android + mot de passe | `app/android/upload-keystore.jks` + `app/android/key.properties` (tous deux gitignored) | Pas de sauvegarde externe connue à ce jour — **à corriger en priorité** |
| `TOKEN_CHIFFREMENT_CLE` (chiffrement des jetons Google) | Firebase Secret Manager | Jamais dans le code, jamais dans Firestore |
| `GOOGLE_OAUTH_CLIENT_SECRET` | Firebase Secret Manager | — |
| `GROQ_API_KEY` | Firebase Secret Manager | — |
| `ADMIN_PUBLICATION_SECRET` | Firebase Secret Manager | — |
| Clé Firebase publique (`apiKey` dans `firebase_options.dart`/`google-services.json`) | Dans le code source (normal) | N'est **pas** un secret par conception — c'est un identifiant client public, la vraie protection vient des règles Firestore |

Pour lire un secret depuis la machine de développement : `firebase functions:secrets:access <NOM_DU_SECRET>` (nécessite d'être authentifié sur le projet `secretaire-aje` via `firebase login`).

## 9. Accès à provisionner pour un nouveau collaborateur (à faire par Tobie personnellement, pas par ce document)

- [ ] Accès en écriture au dépôt GitHub `pentalightcode/vigie` (ajouter comme collaborateur).
- [ ] Rôle IAM approprié sur le projet Google Cloud/Firebase `secretaire-aje` (selon le niveau de responsabilité voulu — lecture seule pour observer, ou éditeur pour déployer).
- [ ] Selon le besoin réel : copie du fichier `upload-keystore.jks` + son mot de passe, transmis par un canal sécurisé (jamais par email en clair, jamais collé dans un chat) — nécessaire uniquement si cette personne doit un jour publier une mise à jour de l'app elle-même.
- [ ] Accès au compte Google Play Console une fois créé (pas encore fait à ce jour).
- [ ] Accès au registrar de domaine (Porkbun) si la gestion DNS doit être partagée.

## 10. Ce qui reste ouvert / en attente au 29/08/2026

- Réponse de Google sur la 3ᵉ demande de vérification OAuth (voir section 6).
- Sauvegarde du keystore Android — critique, non faite.
- Carte bancaire physique pour le forfait Blaze — pas urgent.
- Décision à prendre : réimplémenter le chiffrement côté client prévu à l'origine pour les notes sensibles (`journalDossier`), ou assumer explicitement le modèle actuel (noms de code + contrôle d'accès serveur) comme suffisant — voir section 3.
- Clarifier la question légale APDP (Bénin) soulevée dès la conception, jamais formellement refermée — voir section 3.
- Mise à jour `flutter_secure_storage` vers une version plus récente — bloquée par un conflit de dépendances avec `share_plus`, pas urgent.
