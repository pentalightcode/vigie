# Vigie — Document de transfert de connaissances

**Rédigé le :** 29 août 2026. **Mis à jour le :** 31 août 2026 (chantier collaboration par dossier + méthode de travail).
**Pour :** toute personne (ou IA) qui rejoint le projet sans avoir participé aux échanges précédents.
**But :** donner une vision complète — méthode de travail, histoire du projet, comment installer et lancer le projet depuis zéro, architecture, décisions et leur pourquoi, état actuel de chaque service externe, limites connues — sans avoir à reconstituer l'historique à partir de zéro, et sans avoir accès aux fichiers personnels de Tobie qui vivent hors de ce dépôt.

**Ce document ne contient AUCUNE valeur de secret** (mots de passe, clés API...) — volontairement. Voir la section "Secrets — inventaire des emplacements" tout en bas : elle dit où chaque secret vit, jamais ce qu'il vaut. Les valeurs elles-mêmes doivent être transmises à un nouveau collaborateur par un canal séparé et sécurisé (gestionnaire de mots de passe, remise en main propre), jamais copiées dans ce fichier ni collées dans une conversation avec une IA.

À lire dans l'ordre : ce document d'abord (méthode + vue d'ensemble + mise en route), puis `PROGRESS.md` (journal chronologique détaillé de chaque session de travail — le plus fiable pour savoir "où on en est exactement" à un instant donné), puis `Notes/` (fiches de décision individuelles et fiches de red team, une par sujet). Le code source lui-même contient énormément de contexte "pourquoi" en commentaire — c'est une convention de la maison, voir section 6.

---

## 1. Méthode de travail — les règles d'or

Cette section n'existait pas avant le 31/08/2026 — ajoutée sur demande explicite de Tobie, parce que ces règles vivaient jusqu'ici uniquement dans un fichier de configuration personnel (`/home/tobie/CLAUDE.md`) hors de ce dépôt, donc invisibles pour quiconque clone juste `vigie`. Ce ne sont pas des préférences de style : ce sont les règles qui ont concrètement évité plusieurs incidents réels sur ce projet (voir les exemples cités).

1. **Red team avant toute décision structurante — jamais un seul passage.** Aucune fonctionnalité qui touche à l'architecture, aux données, ou à la sécurité n'est considérée finie après un premier jet. Le chantier collaboration (voir section 8) a été relu **neuf fois de suite** les 30-31/08/2026, et plusieurs de ces passes ont trouvé des trous dans les corrections de la passe **précédente** — se relire soi-même après coup fait partie de la méthode, pas juste relire le code d'origine. Concrètement : après chaque changement de règles Firestore ou de fonction Cloud touchant à un modèle de données partagé, relire à froid en cherchant activement "qu'est-ce qu'un client malveillant pourrait faire que l'app elle-même ne ferait jamais" — puis vérifier la syntaxe (`flutter analyze`, `firebase deploy --only firestore --dry-run`, import Python) avant de considérer que c'est fini.

2. **L'IA red-teame et propose, Tobie décide — ne jamais inverser les rôles.** Sur toute question ambiguë de produit ou d'architecture, poser la question clairement (options + compromis de chacune) plutôt que de trancher unilatéralement, même quand une option semble évidemment meilleure — la présenter comme une recommandation, pas comme un fait accompli. Exemples concrets de cette discipline appliquée sur ce projet : "un administrateur peut-il gérer un autre administrateur ?" (posé, tranché "non" par Tobie) ; "qui peut modifier l'entrée de journal d'un autre participant ?" (posé avec les compromis, tranché "auteur + créateur + administrateur") ; "accès automatique aux dossiers d'un futur groupe multi-dossiers ?" (Tobie a explicitement demandé "aide-moi à prendre une décision logique" — réponse : présenter le raisonnement complet des deux options, recommander une réponse, laisser Tobie trancher). Ne jamais présenter une préférence personnelle de l'IA comme si c'était la seule option raisonnable.

3. **`PROGRESS.md` mis à jour après CHAQUE résultat significatif, jamais après coup en bloc.** C'est le fil qui permet de reconstituer l'état exact du projet à tout moment, y compris au milieu d'une session interrompue, sans avoir à redemander à Tobie "où on en est". Une entrée par étape franchie, pas un résumé écrit à la fin.

4. **`Notes/` pour toute décision ou exploration substantielle — un fichier par sujet, daté.** Pas seulement le résultat final : le raisonnement, les fausses pistes, et pour les fiches de red team, chaque faille trouvée avec un scénario concret d'exploitation, pas juste "c'est corrigé". `Notes/2026-08-30-redteam-code-collaboration.md` en est l'exemple le plus complet à ce jour — neuf passes, chacune documentée séparément avec ce qui a été trouvé, pourquoi, et comment ça a été corrigé.

5. **Discipline de déploiement stricte : grouper, vérifier en local, ne jamais déployer après chaque micro-changement.** Née d'un incident réel (25/08/2025, projet Netlify différent de Vigie mais même compte) : 17 déploiements poussés en une seule session, un par petite modification, ont épuisé un quota mensuel entier — plus aucun déploiement possible pendant près d'un mois. Règle depuis : un ensemble cohérent de changements liés est déployé ensemble, jamais un par un, et toujours vérifié en local (`flutter analyze`, `--dry-run`) avant. Au 31/08/2026, tout le chantier collaboration (règles, index, fonction Cloud, écran) attend sciemment d'être déployé en un seul groupe plutôt qu'au fil de l'eau.

6. **Transparence totale, y compris sur ses propres erreurs — surtout quand personne ne les a encore remarquées.** Exemple concret : le 29/08/2026, un premier déploiement des règles Firestore de la collaboration avait un trou qui aurait coupé l'accès de tous les utilisateurs existants à leurs propres dossiers. Trouvé et corrigé avant que Tobie ne rencontre le problème — mais expliqué en détail à Tobie quand même, plutôt que corrigé silencieusement comme si de rien n'était.

7. **Toujours vérifier le résultat réel d'une action, jamais supposer qu'elle a réussi parce qu'aucune erreur ne s'est affichée.** Exemple concret : un déploiement d'hébergement avait "réussi" (aucune erreur) mais republiait en fait un ancien build jamais reconstruit — repéré uniquement en vérifiant le site en ligne avec `curl` après coup, pas en faisant confiance au message de la commande.

8. **Une chose à la fois — valider avant de passer à la suite.** Ne pas enchaîner plusieurs chantiers sans un point de validation explicite entre chacun, même quand la suite logique semble évidente.

## 2. Histoire du projet, en condensé

Version courte de l'arc complet — le détail exhaustif, jour par jour, vit dans `PROGRESS.md` et `Notes/`. Utile pour comprendre le "pourquoi" de certaines décisions sans avoir à tout relire.

- **05/08/2026 — Origine** : idée née d'une note vocale entre Tobie et son père (magistrat au Bénin), transcrite et analysée. Besoin réel identifié : suivi de dossiers judiciaires, débordé par une gestion manuelle, avec une exigence de confidentialité non négociable.
- **05-06/08 — Cadrage avant le code** : recherche de solutions existantes (aucune ne correspond au besoin précis), interview approfondie du père pour valider le besoin réel plutôt que supposé. Décision explicite de Tobie : trancher la confidentialité AVANT de choisir l'outil.
- **06-07/08 — Décisions fondatrices** : red team sur l'anonymisation → noms de code choisis par l'utilisateur + chiffrement côté téléphone envisagé (jamais complètement construit depuis pour le champ d'origine, voir section 9). Firebase choisi comme backend (vs Supabase). Cadrage du MVP : échéances en cascade + relance quotidienne + bilan périodique — explicitement PAS de planification horaire.
- **Reste du mois d'août — Construction MVP** : plusieurs tours de red team successifs (rounds MVP v1/v2/v3) trouvant et corrigeant des trous réels (notification par item plutôt que par dossier, ajout un par un au lieu de par lot, pas de niveau "dossier" au départ...). Ajout du journal de dossier (20/08), intégration Gmail/Tasks/Calendar en lecture seule (scan automatique, propositions de dossiers détectées dans les emails).
- **24/08 — Nouvelle clé de signature Android** générée pour la release — causera, sans que ce soit su à l'époque, un bug de reconnexion Google découvert et non résolu pendant plusieurs jours.
- **28-29/08 — Audit de sécurité complet** : 6 failles réelles trouvées et corrigées (PIN en clair, contenu confidentiel sur écran verrouillé, notifications fantômes, textes non plafonnés envoyés à l'IA, suppression de compte incomplète). Root-cause enfin trouvée pour le bug de reconnexion Google (la nouvelle clé de signature n'avait jamais été enregistrée auprès de Firebase/Google). Page d'accueil ajoutée. Première version de ce document (`HANDOVER.md`) créée.
- **29/08 (suite) — Chiffrement bout-en-bout du journal** construit pour de vrai (abandonné puis repris une fois, voir section 9), puis l'exploration à 74 angles sur "comment Vigie sert le travail de groupe" démarre (`Notes/2026-08-29-redteam-collaboration-multi-angles.md`) — voulue exhaustive et généraliste (toutes professions, pas seulement le droit) par Tobie.
- **29-30/08 — Conception puis construction de la Phase 1 collaboration** : modèle par dossier (`participantsUids`/`roles`) validé après l'exploration à 74 angles, implémenté (règles Firestore, modèles Dart, fonction Cloud `gerer_participant_dossier`, écran de gestion des participants). Un incident (near-miss) auto-détecté et corrigé le jour même, avant que Tobie ne le rencontre.
- **30-31/08 — Neuf tours de red team successifs** sur ce même code (voir section 8 et `Notes/2026-08-30-redteam-code-collaboration.md`), plusieurs failles critiques trouvées et corrigées. Décisions de roadmap prises pendant cette période : workflow d'approbation à construire, principe d'accès pour de futurs groupes multi-dossiers tranché. **`HANDOVER.md` réécrit en profondeur** (cette version) pour combler un vrai manque signalé par Tobie : aucune étape d'installation, aucune méthode de travail documentée, chantier collaboration entier absent du document. Premier commit + push de tout ce chantier sur GitHub.

## 3. Le projet, en une minute

**Vigie** est une application (Android + Web) de suivi d'échéances pensée pour des professions où la confidentialité n'est pas négociable — l'exemple concret et le premier vrai utilisateur visé est le père de Tobie, magistrat au Bénin, débordé par le suivi manuel de ses dossiers.

Principe central : l'utilisateur ne désigne **jamais** ses dossiers par leur vrai nom — il choisit lui-même un nom de code pour chacun. L'app suit les échéances (audiences, rendez-vous, dates limites), relance jusqu'à confirmation que c'est fait, et propose un bilan périodique. Depuis fin août 2026, un dossier peut aussi être **partagé** avec d'autres comptes Vigie (voir section 8).

**Éditeur :** PENTALIGHTCODE (Tobie Vincent Amadou), Cotonou, Bénin.
**Utilisateurs réels (chiffre du 29/08/2026, à reconfirmer avec Tobie) :** 3 comptes existent, dont Tobie et son père. Pas encore publiée sur le Play Store — en cours de vérification Google (voir section 11).

## 4. Architecture technique

- **Client :** Flutter (Dart), buildé pour Android (cible principale, APK signé distribué directement depuis le site le temps que le Play Store soit prêt) et Web (accessible sur `vigie.pentalightcode.com`, sert aussi de page de téléchargement de l'APK).
- **Backend :** Firebase — projet `secretaire-aje`.
  - **Auth** : connexion par lien magique email (pas de mot de passe) — `firebase_auth`, `sendSignInLinkToEmail`.
  - **Firestore** : base de données principale. Collections : `dossiers`, `taches`, `journalDossier` (top-level ; filtrées par `uid` ET par appartenance à `participantsUids`, voir section 8) ; `utilisateurs/{uid}/` avec sous-collections `naturesDossier`, `notifications`, `propositions`, `connexionsGoogle` (+ sous-collections internes `emailsTraites`/`tachesGoogleTraitees`/`evenementsGoogleTraites`), `collaborateursParDefaut`, `etatSync`, `etatsNotifies` ; `config/version` (public, lecture seule, pour la bannière de mise à jour).
  - **Cloud Functions** (Python 3.14, 2ᵉ génération, `app/functions/main.py`) : digest quotidien de rappels, scan Gmail/Tasks/Calendar, gestion des connexions Google (chiffrement/révocation des jetons), suppression de compte, publication de version, résumé IA du bilan (Groq), et depuis fin août 2026 `gerer_participant_dossier` (gestion des participants d'un dossier partagé).
  - **FCM** : notifications push.
  - **Hosting** : sert le build web + les pages publiques statiques (`/apropos/`, `/confidentialite/`) + l'APK téléchargeable + `.well-known/assetlinks.json` (App Links Android).
  - **Secret Manager** : tous les secrets serveur (voir section 13).
- **Intégrations externes (optionnelles, activées par l'utilisateur)** : Google (Gmail/Tasks/Calendar, lecture seule, OAuth), Groq (résumé IA du bilan + extraction IA des dates d'emails, désactivé par défaut, avertissement avant activation).
- **i18n** : français (langue de référence) + anglais, `flutter_localizations` + fichiers `.arb` dans `lib/l10n/` (`app_fr.arb`/`app_en.arb`, régénérer avec `flutter gen-l10n` après toute modification — `flutter analyze` seul ne le fait pas).

## 5. Mise en route depuis zéro — installer et lancer le projet

**Outils à installer** (versions utilisées sur la machine de développement actuelle, au 31/08/2026 — une version proche suffit généralement) :
- Flutter 3.44.8, canal stable (inclut Dart 3.12.2) — `flutter --version` pour vérifier. Contrainte du projet : `sdk: ^3.12.2` dans `app/pubspec.yaml`.
- Firebase CLI ≥ 15.26.0 (`npm install -g firebase-tools`) — nécessite Node.js (v24.14.0 utilisé ici) + npm.
- Python 3.14 pour les Cloud Functions (`app/functions/`) — runtime déclaré `"python314"` dans `app/firebase.json`.
- Android SDK / Android Studio uniquement si vous devez builder l'APK — pas nécessaire pour travailler sur le code Dart ou Python seul (`flutter run -d chrome` suffit pour tester côté web).

**Étapes :**
1. Cloner le dépôt : `git clone https://github.com/pentalightcode/vigie.git` (ou l'URL SSH si un accès en écriture a été provisionné, voir section 14).
2. `google-services.json` (`app/android/app/`) et `firebase_options.dart` (`app/lib/`) sont **déjà dans le dépôt** — ce ne sont pas des secrets (identifiants client publics, la vraie protection vient des règles Firestore, voir section 13), rien à régénérer via `flutterfire configure`.
3. `cd app && flutter pub get`.
4. `firebase login` avec un compte Google ayant accès au projet `secretaire-aje` (à faire provisionner par Tobie, section 14), puis depuis `app/` : `firebase use secretaire-aje`.
5. Pour toucher aux Cloud Functions (Python) : `cd app/functions && python3.14 -m venv venv && source venv/bin/activate && pip install -r requirements.txt`.
6. `flutter analyze` (depuis `app/`) doit rester propre — seules 2 infos préexistantes sans rapport sont normales (`dart:html` déprécié dans `lib/utils/telechargement_web.dart`, sans impact réel).
7. Lancer l'app en local : `flutter run` depuis `app/` (choisir la cible — Chrome pour le web, un appareil/émulateur Android connecté sinon).
8. Pour valider une modification des règles Firestore ou des index **sans rien déployer en production** : `firebase deploy --only firestore --dry-run` (depuis `app/`) — compile et vérifie la syntaxe uniquement.
9. Pour valider une modification de `functions/main.py` sans déployer : `cd app/functions && source venv/bin/activate && python3 -c "import main"` (charge le fichier, révèle toute erreur de syntaxe/référence) — pas un vrai test d'exécution, juste une vérification rapide de cohérence.

**Ce que vous n'aurez PAS automatiquement en clonant** (à demander à Tobie personnellement, jamais par un canal non sécurisé — email en clair, chat, collé dans une conversation avec une IA) :
- Les vraies valeurs des secrets serveur (Secret Manager, section 13) — inutiles sauf si vous devez modifier une fonction qui les utilise ET la tester en conditions réelles connectées à Google/Groq.
- `app/android/upload-keystore.jks` + `app/android/key.properties` (tous deux gitignorés) — nécessaires **seulement** pour builder un APK signé destiné à une vraie mise à jour publiée. Une sauvegarde existe (voir section 11), à transmettre par Tobie en main propre ou via un canal chiffré.
- Un rôle IAM réel sur le projet Firebase/GCP pour pouvoir déployer (`firebase deploy` sans `--dry-run`) — sans lui, tout fonctionne en local mais aucun déploiement réel n'est possible.

## 6. Conventions de la maison (style, pas négociable, à respecter)

- **Identifiants en français** dans tout le code (`nomCodeDossier`, `dateDeclenchante`, `_envoyer`...) — délibéré, ne pas "corriger" vers l'anglais.
- **Commentaires rares, uniquement le "pourquoi"** — jamais ce que fait le code (les noms de variables/fonctions le disent déjà), toujours pourquoi une décision non-évidente a été prise, avec la date et le contexte (ex: `// trouvé le 2026-08-20 avec le vrai message d'erreur montré par Tobie`). C'est la source la plus riche de contexte historique dans ce projet — la lire vaut souvent mieux que deviner.
- Le reste des règles de méthode (checkpoint `PROGRESS.md`, discipline de déploiement, red team systématique...) est en section 1 — ce ne sont pas de simples conventions de style, elles ont leur propre section parce qu'elles sont plus importantes que ça.

## 7. Principes de sécurité et de confidentialité — ce qui est réellement construit aujourd'hui

**Point important à comprendre avant de faire des hypothèses** : les toutes premières notes de conception (`Notes/2026-08-06-redteam-anonymisation.md`, `Notes/2026-08-07-mvp-scope.md`) envisageaient un **chiffrement côté téléphone** (clé dérivée d'une phrase secrète mémorisée par l'utilisateur, jamais stockée) pour un champ "note privée" optionnel. **Ce chiffrement pour `notePrivee` n'a jamais été implémenté** — champ resté mort dans `lib/models/dossier.dart`, remplacé en pratique par `journalDossier`.

**Mise à jour du 29/08/2026 : un VRAI chiffrement bout-en-bout a depuis été construit, mais pour le journal (`journalDossier`), pas pour `notePrivee`** — `lib/services/chiffrement_notes_service.dart` (AES-256-GCM, clé dérivée d'une phrase secrète via PBKDF2-HMAC-SHA256 600 000 itérations). **Puis désactivé automatiquement dès qu'un dossier est partagé** (décision de Tobie le 30/08/2026, en construisant la collaboration) : la clé est strictement personnelle à celui qui écrit, donc un autre participant ne pourrait jamais déchiffrer l'entrée de quelqu'un d'autre — `chiffre: false` forcé côté client dès que `participantsUids.length > 1`. Reste actif uniquement pour un dossier strictement solo. Une limite résiduelle assumée : un dossier solo qui avait déjà de vraies entrées chiffrées AVANT d'être partagé garde ces entrées-là illisibles pour les nouveaux participants (comportement sûr — jamais de fuite en clair — juste verrouillé pour de bon sur ces entrées précises).

**Concrètement, aujourd'hui, la confidentialité de Vigie repose sur trois mécanismes :**
1. **Les noms de code** — aucune vraie information n'est demandée à l'utilisateur, c'est lui qui choisit le libellé affiché pour chaque dossier.
2. **Le contrôle d'accès côté serveur** (règles Firestore, `uid`/`participantsUids`-scopées) — quiconque a accès à la base de données avec les identifiants Admin (PENTALIGHTCODE, ou un compromis du projet Firebase) peut lire l'intégralité des dossiers/tâches/notes non chiffrées en clair.
3. **Le chiffrement bout-en-bout du journal pour un dossier solo uniquement** (voir ci-dessus) — inexistant pour tout le reste (nom de dossier, tâches, journal d'un dossier partagé).

**Autre point non résolu, trouvé dans les notes fondatrices, jamais retranché depuis** : `Notes/2026-08-06-confidentialite-donnees.md` soulève que les données que le père manipule (affaires judiciaires) sont probablement des "données sensibles" au sens de la loi béninoise sur la protection des données (Code du numérique, loi n°2017-20, autorité APDP), et recommandait prudemment de commencer par une solution 100% locale, le temps de clarifier les obligations légales exactes (notamment le transfert de données hors du Bénin, puisque Firebase est un cloud américain/européen). **Le projet est parti directement sur Firebase (cloud, hors Bénin)** sans qu'une trace dans ce dépôt ne montre qu'un avis juridique formel ait été obtenu entre-temps. Ce n'est pas forcément un problème (le père a probablement statué lui-même, étant magistrat), mais c'est un point à vérifier explicitement avec Tobie plutôt qu'à supposer réglé.

### Ce qui EST solidement construit (audit de sécurité complet mené le 28-29/08/2026 + neuf tours de red team sur la collaboration les 30-31/08/2026, voir `PROGRESS.md` pour le détail)
- Verrou PIN local (indépendant de Firebase Auth) : hachage PBKDF2-HMAC-SHA256 (120 000 itérations, sel aléatoire), jamais stocké en clair, verrouillage progressif après échecs répétés. Limite connue et acceptée par Tobie : ne protège pas contre un accès root/ADB physique au téléphone déjà déverrouillé (limite partagée par toute app de verrou local).
- Jetons OAuth Google : chiffrés (Fernet/AES) avec une clé qui ne vit que dans Secret Manager, jamais renvoyés au téléphone, révoqués auprès de Google à la déconnexion et à la suppression de compte.
- Notifications push : contenu générique par défaut sur l'écran verrouillé (jamais le nom de code d'un dossier ni le contenu d'un email), sécurisé par défaut (opt-in explicite requis pour afficher un texte réel).
- Règles Firestore relues intégralement, plusieurs fois, y compris après coup sur leurs propres correctifs (voir section 8) : chaque collection sensible ancrée sur `uid`/`participantsUids`, champs immuables protégés à la mise à jour, forgerie de documents fermée à la création.
- Aucune vulnérabilité connue dans les dépendances Flutter (base OSV de Google) ni dans les dépendances Python (`pip-audit`), vérifié le 29/08/2026 — à revérifier périodiquement, ce n'est pas figé dans le temps.

## 8. Collaboration par dossier — modèle "participants" (nouveau, 29-31/08/2026)

**Ce qui a changé** : un dossier peut désormais être partagé avec d'autres comptes Vigie, pas seulement consulté par son créateur. Chaque dossier porte trois champs dénormalisés :
- `participantsUids` (tableau d'uid) — qui a accès, pour les requêtes ET pour les règles Firestore sans lecture supplémentaire dans le cas courant.
- `roles` (map uid → `'createur'` | `'administrateur'` | `'contributeur'`) — quel niveau chacun a.
- `participantsEmails` (map uid → email) — écrit UNIQUEMENT côté serveur, pour que l'écran de gestion affiche un email plutôt qu'un identifiant technique.

Les tâches et entrées de journal portent une copie de `participantsUids` (synchronisée automatiquement) pour être interrogeables directement. Toute gestion de participant (ajouter par email, retirer, changer de rôle, se retirer soi-même) passe **exclusivement** par la fonction Cloud `gerer_participant_dossier` — jamais en écriture directe sur les champs `participantsUids`/`roles`/`participantsEmails`, même pour le créateur (les règles Firestore l'interdisent explicitement).

**Ce chantier a fait l'objet de neuf tours de red team successifs les 30 et 31 août 2026** (voir la règle 1 en section 1, et le détail complet faille par faille dans `Notes/2026-08-30-redteam-code-collaboration.md`). Plusieurs failles réelles trouvées et corrigées, dont deux critiques : un participant retiré du dossier gardait un accès permanent à ses propres notes de journal (le repli de rétrocompatibilité des règles ne s'éteignait jamais) ; et un document forgé (tâche ou entrée de journal) pouvait rester dormant puis "s'activer" automatiquement dès qu'une action de gestion parfaitement légitime survenait sur le dossier visé, via la synchronisation en cascade qui recopie la liste de participants sans vérifier la provenance des documents qu'elle touche. Plusieurs de ces corrections ont elles-mêmes été relues et corrigées lors des passes suivantes — le fichier de Notes documente aussi ce processus, pas seulement le résultat final.

**Statut au 31/08/2026 : le code est écrit et vérifié statiquement** (`flutter analyze` propre, `firebase deploy --only firestore --dry-run` compile sans erreur, `functions/main.py` s'importe sans erreur), **mais rien n'a encore été buildé ni déployé en production, et rien n'a encore tourné en conditions réelles.** Voir `PROGRESS.md` (entrées du 29 au 31/08/2026) pour l'état exact.

**Une incertitude technique non résolue, à vérifier en PRIORITÉ dès le premier déploiement réel** : la fonction `estParticipant()` des règles Firestore a une structure conditionnelle (pas un simple OU), et les requêtes `Filter.or()` utilisées côté app (`_filtreParticipant` dans `firestore_service.dart`) n'ont jamais été exécutées contre un vrai projet Firebase depuis cet environnement de développement (pas de compte connecté disponible ici). Si Firestore refuse ce genre de requête contre une règle conditionnelle, ce serait un échec bruyant et immédiat (`PERMISSION_DENIED` pour tout le monde), pas une faille silencieuse — mais ça doit être testé en vrai (deux comptes réels, un dossier partagé) avant de considérer la fonctionnalité opérationnelle.

**Décisions de roadmap prises mais pas encore conçues en détail** (voir `Notes/2026-08-30-redteam-code-collaboration.md`, section "Décisions de roadmap") :
- Workflow d'approbation : toute action d'un contributeur devra être validée par un administrateur ou le créateur ; un administrateur devra avoir la confirmation du créateur avant de supprimer un dossier ou des tâches. Décidé par Tobie le 31/08/2026, pas encore construit.
- Groupes multi-dossiers : une future notion de "groupe"/"communauté" regroupant plusieurs dossiers liés pour une équipe qui travaille dessus ensemble. Principe d'accès déjà tranché par Tobie (raisonnement présenté et validé, voir règle 2 en section 1) : le groupe reste **organisationnel seulement**, jamais d'accès automatique aux dossiers qu'il contient — l'accès à chaque dossier reste décidé séparément, comme aujourd'hui. Rien conçu en détail au-delà de ce principe.
- Séquencement tranché par Tobie : déployer la Phase 1 actuelle (accès complet par dossier, sans workflow d'approbation) en premier pour un vrai test en conditions réelles, plutôt que de tout construire avant le premier déploiement.

## 9. Rituel de build + déploiement (à suivre précisément)

1. Bump de version dans `app/pubspec.yaml` (`version: X.Y.Z+N`, le `+N` doit toujours augmenter).
2. `flutter analyze` — doit rester propre (2 infos pré-existantes sans rapport, voir section 5).
3. Si des règles Firestore, index, ou fonctions Cloud ont changé (`firestore.rules`, `firestore.indexes.json`, `functions/main.py`) : `firebase deploy --only firestore,functions` (depuis `app/`) — déployer ça AVANT l'app, pour qu'un client déjà mis à jour trouve un serveur déjà prêt à le recevoir plutôt que l'inverse.
4. `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`.
5. Copier l'APK vers `app/web/telecharger/Vigie.apk` ET `~/Téléchargements/Vigie.apk`.
6. `flutter build web --release` → `build/web/`.
7. Copier l'APK dans `build/web/telecharger/Vigie.apk` (le build web ne le fait pas automatiquement).
8. Vérifier que `build/web/.well-known/assetlinks.json`, `/apropos/`, `/confidentialite/` ont bien survécu au build (ils vivent dans `app/web/` et sont copiés par `flutter build web`, mais ça a déjà cassé silencieusement une fois).
9. `firebase deploy --only hosting --force` (depuis `app/`) — **attention** : si un fichier statique dans `app/web/` a changé sans avoir refait `flutter build web` derrière, ce déploiement republie l'ancien `build/web/` sans le changement — toujours vérifier après coup avec `curl` (voir règle 7, section 1).
10. Publier le numéro de version pour déclencher la bannière de mise à jour :
    ```bash
    cd app && ADMIN_PUBLICATION_SECRET="$(firebase functions:secrets:access ADMIN_PUBLICATION_SECRET)" python3 scripts/publier_version.py <version> <build>
    ```

## 10. Ce qui reste ouvert / en attente au 31/08/2026

- **Build + déploiement groupé du chantier collaboration** (règles, index, fonction Cloud `gerer_participant_dossier`, écran participants) — tout est écrit et vérifié statiquement, rien n'est encore parti en production. Voir section 8 pour l'incertitude technique à tester en priorité juste après ce déploiement.
- Concevoir en détail le workflow d'approbation et les groupes multi-dossiers (voir section 8) — décisions de principe prises, rien construit.
- Réponse de Google sur la 3ᵉ demande de vérification OAuth (voir section 11) — pas revérifié depuis le 29/08.
- Déplacer la sauvegarde du keystore Android hors de cette machine (voir section 11) — la sauvegarde existe, mais reste au même endroit que l'original.
- Carte bancaire physique pour le forfait Blaze — pas urgent.
- Clarifier la question légale APDP (Bénin) soulevée dès la conception, jamais formellement refermée — voir section 7.
- Mise à jour `flutter_secure_storage` vers une version plus récente — bloquée par un conflit de dépendances avec `share_plus` (nécessite aussi de monter `compileSdk`), pas urgent.

## 11. État actuel des systèmes externes (au 31/08/2026)

- **Firebase / GCP** : projet `secretaire-aje`, forfait Blaze (paiement à l'usage) actif. Carte bancaire enregistrée = virtuelle, refusée par Google Cloud Billing pour ce type d'usage ; une vraie carte physique sera nécessaire si l'usage dépasse le quota gratuit (pas urgent, factures à 0,00 $ jusqu'ici, à reconfirmer).
- **Domaine** : `pentalightcode.com` acheté chez Porkbun, `vigie.pentalightcode.com` pointé vers Firebase Hosting, propriété vérifiée dans Google Search Console (couvre tous les sous-domaines).
- **GitHub** : `github.com/pentalightcode/vigie`, dépôt public (choix explicite de Tobie), transféré depuis un dépôt personnel. `git status` doit toujours être vérifié avant tout commit — plusieurs recherches de secrets ont déjà été faites avant chaque push, à refaire par réflexe.
- **Vérification OAuth Google** (pour les scopes Gmail/Tasks/Calendar en lecture seule) : statut au 29/08/2026, **pas revérifié depuis** — 3ᵉ soumission envoyée ce jour-là, deux rejets précédents (vidéo de démo inaccessible sur YouTube, modération automatique). Délai annoncé par Google : premier email sous 3-5 jours, procédure complète 4-6 semaines — vérifier la boîte mail de Tobie pour une éventuelle réponse.
- **Play Store** : pas encore soumis au 29/08/2026, bloqué sur la vérification OAuth ci-dessus.
- **Signature Android** : vraie clé de release générée le 24/08/2026 (`app/android/upload-keystore.jks`). **Une sauvegarde chiffrée existe** (`/home/tobie/vigie-keystore-backup.zip`, créée et vérifiée octet pour octet identique le 29/08/2026, protégée par mot de passe d'archive) — **mais elle vit encore uniquement sur cette même machine**. Reste à faire, par Tobie personnellement : la déplacer physiquement ailleurs (stockage externe, coffre-fort numérique) — tant que ce n'est pas fait, la perte de cette machine reste un point de défaillance unique pour toute future mise à jour de l'app.

## 12. Failles de sécurité trouvées et corrigées

**Audit du 28-29/08/2026** (détail complet dans `PROGRESS.md`) :
1. PIN stocké en clair, sans limite de tentatives → hachage PBKDF2 + verrouillage progressif.
2. Contenu confidentiel affiché sur l'écran verrouillé via les notifications push → texte générique par défaut.
3. Notifications "fantômes" → corrigé avec deux créneaux garantis (9h/18h).
4. Texte envoyé à l'IA Groq sans limite de taille → plafonné.
5. Suppression de compte incomplète → révocation Google réelle + suppression récursive complète.
6. Sujet d'email non plafonné avant envoi à l'IA Groq → même correctif que le point 4.
- Risque accepté (décision explicite de Tobie) : contournement du PIN local possible avec un accès root/ADB physique au téléphone.

**Red team du chantier collaboration, 30-31/08/2026** (neuf tours, détail complet faille par faille dans `Notes/2026-08-30-redteam-code-collaboration.md`) — points marquants :
- 🔴 Critique : un participant retiré du dossier gardait un accès permanent à ses propres notes de journal (repli de rétrocompatibilité des règles jamais éteint).
- 🟠 Élevé : des tâches/entrées de journal forgées pouvaient être injectées dans la liste de n'importe qui.
- 🔴 Critique (trouvé en re-vérifiant le correctif précédent) : `uid` librement réécrivable sur dossiers/tâches/entrées → destruction de données cross-utilisateur possible via la suppression de compte d'un tiers sans lien.
- 🔴 Critique (trouvé encore plus tard) : un document forgé pouvait rester dormant puis "s'activer" via la synchronisation en cascade déclenchée par une action de gestion légitime.
- Deux risques documentés et **acceptés en connaissance de cause**, pas corrigés : énumération de comptes par email via `gerer_participant_dossier` (base d'utilisateurs trop petite pour que ce soit un vrai risque aujourd'hui, à reconsidérer si Vigie s'ouvre à plus de monde) ; le cache Firestore hors-ligne garde la dernière copie synchronisée sur l'appareil d'un participant retiré (limite inhérente à toute app "offline-first", pas de correctif propre sans désactiver le mode hors-ligne).

**Zones vérifiées saines à l'audit du 28-29/08/2026** : AndroidManifest, lien magique de connexion, logs, IDOR sur les fonctions serveur, chiffrement des jetons Google, injection de prompt IA, dépendances tierces, `firestore.indexes.json`, Firebase Storage (pas utilisé), point d'administration `publier_version_admin`.

## 13. Secrets — inventaire des emplacements (jamais les valeurs)

| Secret | Où il vit | Jamais où |
|---|---|---|
| Clé de signature Android + mot de passe | `app/android/upload-keystore.jks` + `app/android/key.properties` (tous deux gitignorés) | Sauvegarde existe mais reste sur cette machine (voir section 11) — à déplacer en priorité |
| `TOKEN_CHIFFREMENT_CLE` (chiffrement des jetons Google) | Firebase Secret Manager | Jamais dans le code, jamais dans Firestore |
| `GOOGLE_OAUTH_CLIENT_SECRET` | Firebase Secret Manager | — |
| `GROQ_API_KEY` | Firebase Secret Manager | — |
| `ADMIN_PUBLICATION_SECRET` | Firebase Secret Manager | — |
| Clé Firebase publique (`apiKey` dans `firebase_options.dart`/`google-services.json`) | Dans le code source (normal, déjà dans le dépôt) | N'est **pas** un secret par conception — identifiant client public, la vraie protection vient des règles Firestore |

Pour lire un secret depuis la machine de développement : `firebase functions:secrets:access <NOM_DU_SECRET>` (nécessite d'être authentifié sur le projet `secretaire-aje` via `firebase login`, avec un compte ayant le rôle IAM approprié).

## 14. Accès à provisionner pour un nouveau collaborateur (à faire par Tobie personnellement, pas par ce document)

- [ ] Accès en écriture au dépôt GitHub `pentalightcode/vigie` (ajouter comme collaborateur).
- [ ] Rôle IAM approprié sur le projet Google Cloud/Firebase `secretaire-aje` (lecture seule pour observer, ou éditeur pour déployer réellement — sans ça, `firebase deploy` sans `--dry-run` échoue).
- [ ] Selon le besoin réel : copie du fichier `upload-keystore.jks` + son mot de passe, transmis par un canal sécurisé (jamais par email en clair, jamais collé dans un chat) — nécessaire uniquement si cette personne doit un jour publier une mise à jour de l'app elle-même.
- [ ] Accès au compte Google Play Console une fois créé (pas encore fait à ce jour).
- [ ] Accès au registrar de domaine (Porkbun) si la gestion DNS doit être partagée.
