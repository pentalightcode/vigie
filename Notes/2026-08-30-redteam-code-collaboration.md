# Red Team — tout le code de la collaboration par dossier (2026-08-30)

**Demande de Tobie** : "red team sur tout le code d'abord" — avant tout build/déploiement de la Phase 1 (participants par dossier), relire adversairement tout ce qui a été écrit hier et aujourd'hui : `firestore.rules`, `functions/main.py` (`gerer_participant_dossier`, cascade de `supprimer_compte_definitivement`), les modèles Dart, `FirestoreService`, le nouvel écran participants.

**Méthode** : pas une relecture superficielle — pour chaque règle/fonction, se demander "qu'est-ce qu'un client malveillant qui parle directement à l'API Firebase (pas forcément l'app) pourrait faire que l'app elle-même ne ferait jamais ?" (rappel : dans ce projet, **les règles Firestore sont la seule vraie limite**, jamais le code client — déjà acté dans `HANDOVER.md`).

Rien n'a été corrigé automatiquement — conforme à la règle "Claude fait les Red Team, Tobie décide". Chaque trouvaille ci-dessous attend une décision.

---

## 🔴 CRITIQUE — Un participant retiré garde un accès permanent à SES PROPRES notes de journal

**Où** : `firestore.rules`, fonction `estParticipant()`, utilisée par `match /journalDossier/{entreeId}`.

**Le mécanisme du bug** :
```
function estParticipant(data) {
  return request.auth != null && (
    (data.uid is string && data.uid == request.auth.uid)
    || ('participantsUids' in data && request.auth.uid in data.participantsUids)
  );
}
```
C'est un OU. Les deux branches sont vérifiées **indépendamment**, même quand `participantsUids` existe et est à jour.

Sur un **dossier** ou une **tâche**, le champ `uid` désigne toujours le **créateur du dossier** (jamais retirable par construction — `gerer_participant_dossier` interdit explicitement de retirer le créateur). Donc la première branche (`data.uid == moi`) ne peut JAMAIS accorder un accès indu : elle ne matche que la personne qui, par définition, a toujours accès.

Mais sur une **entrée de journal** (`journalDossier`), le champ `uid` ne désigne PAS le créateur du dossier — il désigne **l'auteur de cette entrée précise** (n'importe quel participant, y compris un simple contributeur). Voir `ajouterEntreeJournal` dans `firestore_service.dart` : `'uid': _uid` — toujours celui qui écrit, jamais celui qui possède le dossier.

**Scénario concret** :
1. Alice crée un dossier, ajoute Bob comme contributeur.
2. Bob écrit une entrée de journal (`uid: Bob`, `participantsUids: [Alice, Bob]`).
3. Alice retire Bob du dossier (`gerer_participant_dossier`, action "retirer"). La fonction met bien à jour `participantsUids` sur le dossier ET synchronise `participantsUids` sur toutes les tâches/entrées du dossier (`_synchroniser_participants_dossier`) — l'entrée de Bob devient `participantsUids: [Alice]`.
4. **Mais le champ `uid` de cette entrée n'est jamais touché par la synchronisation** (elle ne réécrit que `participantsUids`). Il reste `uid: Bob`.
5. Résultat : `estParticipant()` pour Bob sur cette entrée précise reste VRAI pour toujours, via la première branche — peu importe qu'il ait été retiré. Bob peut continuer à lire, modifier, et supprimer cette entrée indéfiniment (les règles `journalDossier` autorisent `read, delete` et un `update` limité, tous deux gardés par `estParticipant`).

**Pourquoi c'est grave ici précisément** : Vigie existe pour protéger des notes professionnelles confidentielles (dossiers judiciaires, médicaux...). "Retirer quelqu'un d'un dossier" est censé lui couper l'accès — ici, ça ne coupe PAS l'accès aux notes qu'il a personnellement écrites. C'est exactement le genre de faille qu'un audit de confidentialité est censé attraper.

**Pourquoi les tâches et les dossiers n'ont PAS ce problème** : sur `Tache`, j'ai délibérément fait en sorte que `uid` soit toujours le propriétaire du dossier (`proprietaireUid`), jamais la personne qui ajoute la tâche — un choix de conception qui, sans que ce soit anticipé à l'époque, évite ce bug par construction. Sur `Dossier`, `uid` = créateur = personne jamais retirable, donc la même logique reste sûre.

**Correctif proposé** (simple, sans effet de bord sur dossiers/tâches — vérifié) :
```
function estParticipant(data) {
  return request.auth != null && (
    ('participantsUids' in data)
      ? request.auth.uid in data.participantsUids
      : (data.uid is string && data.uid == request.auth.uid)
  );
}
```
Au lieu d'un OU permanent, le repli `uid ==` ne s'applique QUE tant que `participantsUids` n'existe pas du tout sur le document (vraies vieilles entrées d'avant le 29/08, jamais touchées par la nouvelle synchronisation). Dès qu'un document a `participantsUids` (soit parce qu'il est créé après le 29/08, soit parce qu'une seule synchronisation l'a déjà touché), c'est CE champ seul qui décide — et Bob y est bien absent après avoir été retiré. Revérifié que ça ne casse rien pour dossiers/tâches (le créateur est toujours automatiquement inclus dans leur `participantsUids` par construction, donc son accès ne dépend plus du tout de cette bascule).

---

## 🟠 ÉLEVÉ — N'importe quel participant (même contributeur) peut réécrire `participantsUids` sur UNE tâche ou UNE entrée directement

**Où** : `firestore.rules`
```
match /taches/{tacheId} {
  allow update: if estParticipant(resource.data)
    && request.resource.data.dossierId == resource.data.dossierId;
}
match /journalDossier/{entreeId} {
  allow update: if estParticipant(resource.data)
    && request.resource.data.dossierId == resource.data.dossierId
    && request.resource.data.creeLe == resource.data.creeLe;
}
```
Rien n'empêche un `update` de changer `participantsUids` sur le document. Seuls `dossierId` (et `creeLe` pour le journal) sont figés.

**Deux scénarios concrets** :
- **Auto-invitation détournée** : un simple contributeur ajoute directement l'uid d'un tiers dans `participantsUids` d'UNE tâche ou UNE entrée — ce tiers obtient un accès à CET ÉLÉMENT précis sans jamais passer par `gerer_participant_dossier` (donc sans vérification d'email, sans que créateur/administrateur soit informé ou n'ait validé quoi que ce soit).
- **Sabotage/dissimulation** : un contributeur retire le créateur du dossier de `participantsUids` sur une tâche ou une entrée précise (juste celle-là, pas le dossier entier) — cette tâche/entrée disparaît silencieusement des écrans "À traiter"/Bilan/Journal du créateur, qui ne se doute de rien.

**Pourquoi c'est nouveau et pas juste théorique** : avant aujourd'hui, la visibilité ne dépendait pas de `participantsUids` (les requêtes filtraient sur `uid == moi`) — donc ce champ n'avait aucune conséquence réelle. Depuis la correction de ce matin (`Filter.or` dans `FirestoreService`), **la visibilité dépend maintenant directement de ce champ**, donc le trou de la règle devient réellement exploitable.

**Correctif proposé** : figer aussi `participantsUids` dans la règle `update` de `taches`/`journalDossier`, comme c'est déjà fait pour `dossiers` :
```
allow update: if estParticipant(resource.data)
  && request.resource.data.dossierId == resource.data.dossierId
  && request.resource.data.get('participantsUids', []) == resource.data.get('participantsUids', []);
```
Aucune fonctionnalité actuelle n'en a besoin — le seul endroit qui écrit légitimement `participantsUids` après création est `_synchroniser_participants_dossier` (SDK Admin, qui ignore les règles), jamais le téléphone.

---

## 🟡 MOYEN — Un dossier peut être créé avec des participants imposés, hors du circuit d'invitation

**Où** : `firestore.rules`, règle `create` de `dossiers` :
```
allow create: if request.auth != null
  && (
    request.resource.data.get('roles', {}).get(request.auth.uid, null) == 'createur'
    || (!('roles' in request.resource.data) && request.resource.data.uid == request.auth.uid)
  )
  && estParticipant(request.resource.data);
```
Ça vérifie que le créateur se déclare bien lui-même "createur" — mais rien n'empêche d'inclure QUI QUE CE SOIT D'AUTRE dans `participantsUids`/`roles` dès la création, avec n'importe quel rôle (y compris administrateur).

**Scénario concret** : un client qui parle directement à l'API (pas forcément l'app Vigie) crée un dossier avec `participantsUids: [moi, uid_de_quelqu_un_d_autre]`, `roles: {moi: 'createur', uid_de_quelqu_un_d_autre: 'administrateur'}`. Ça marche — alors que tout le design de `gerer_participant_dossier` (vérification par email via `firebase_auth.get_user_by_email`, contrôle que le demandeur a le droit d'inviter) est censé être le SEUL chemin pour ajouter quelqu'un.

**Impact réel** : pas un accès aux données de quelqu'un d'autre (le "quelqu'un d'autre" gagne juste un accès non désiré à MON dossier, pas l'inverse) — mais ça casse l'invariant "toute invitation passe par une vérification d'email + un droit d'inviter", et permet d'ajouter un uid qui n'existe même pas (aucune vérification d'existence de compte à la création, contrairement à `gerer_participant_dossier`).

**Correctif proposé** : à la création, n'autoriser QUE le créateur seul dans `participantsUids`/`roles` :
```
&& request.resource.data.get('participantsUids', [request.auth.uid]) == [request.auth.uid]
&& request.resource.data.get('roles', {request.auth.uid: 'createur'}) == {request.auth.uid: 'createur'}
```
(toute invitation ultérieure passe alors obligatoirement par la fonction serveur).

---

## 🟡 MOYEN — `gerer_participant_dossier` n'est pas transactionnel (risque de perte d'une action concurrente)

**Où** : `functions/main.py`, `gerer_participant_dossier`. Lecture du dossier (`dossier_ref.get()`), calcul en mémoire Python, puis écriture (`dossier_ref.update(...)`) — sans transaction Firestore.

**Scénario concret** : deux administrateurs du même dossier ajoutent chacun une personne différente presque en même temps. Les deux fonctions lisent le même état de départ (avant que l'autre n'ait écrit), calculent chacune leur propre nouvelle liste, et la DERNIÈRE écriture écrase complètement celle de l'autre — un des deux ajouts est silencieusement perdu (pas d'erreur, pas d'avertissement).

**Correctif proposé** : envelopper la lecture+écriture dans une transaction Firestore (`@firestore.transactional` / `db.transaction()`), comme c'est l'usage standard pour tout compteur/liste partagée modifiée concurremment.

---

## 🟡 MOYEN (pré-existant, pas introduit cette session) — Supprimer un dossier ne supprime jamais son journal

**Où** : `firestore_service.dart`, `supprimerDossier()` :
```dart
Future<void> supprimerDossier(String dossierId) async {
  final taches = await _db.collection('taches')...get();
  final batch = _db.batch();
  for (final doc in taches.docs) { batch.delete(doc.reference); }
  batch.delete(_db.collection('dossiers').doc(dossierId));
  await batch.commit();
}
```
Les tâches sont bien supprimées. **Les entrées de `journalDossier` ne le sont jamais** — trouvé en relisant tout le code, pas lié à la collaboration, existe depuis la création du journal (20/08). "Supprimer un dossier" laisse ses notes de journal orphelines dans Firestore pour toujours, pleinement lisibles/modifiables par quiconque avait accès au moment de la suppression (et, combiné à la faille 🔴 CRITIQUE ci-dessus, potentiellement aussi par quelqu'un de retiré ENTRE-TEMPS s'il en a écrit).

**Impact** : dans une app dont toute la promesse est la confidentialité, "supprimer" un dossier ne supprime pas vraiment tout son contenu sensible.

**Correctif** : ajouter la suppression des `journalDossier` du dossier dans le même batch (même filtre `_filtreParticipant` + `dossierId` déjà utilisé pour les tâches).

---

## 🟢 FAIBLE-MOYEN — Un créateur/administrateur peut découvrir si un email a un compte Vigie

**Où** : `gerer_participant_dossier`, action "ajouter" — renvoie des codes d'erreur différents selon que l'email existe (`not-found`) ou est déjà participant (`already-exists`) ou réussit.

**Scénario** : n'importe qui, créateur d'au moins un dossier (donc tout le monde, en créant n'importe quel dossier), peut tester une adresse email sur un de SES dossiers pour savoir si elle correspond à un compte Vigie, sans que la personne visée en soit informée.

**Pourquoi ça compte pour cette app précisément** : savoir qui utilise Vigie peut déjà être une information sensible (ex : savoir qu'un magistrat/avocat précis utilise une app de suivi de dossiers judiciaires confidentiels). Un classique "user enumeration" des systèmes d'invitation par email, ici avec un enjeu de confidentialité un peu plus élevé que la moyenne.

**Correctif possible** : renvoyer un message générique identique ("invitation envoyée si un compte existe") plutôt que de distinguer `not-found`/`already-exists` — mais dégraderait l'expérience utilisateur (Tobie a explicitement demandé récemment de rester simple pour des utilisateurs peu technophiles, ex. son père). À trancher : commodité vs discrétion.

---

## 🟢 FAIBLE — Messages d'erreur non traduits

Les erreurs `FAILED_PRECONDITION` renvoyées par `gerer_participant_dossier` (ex. "Le créateur ne peut pas être retiré du dossier.") sont du texte français en dur, affiché tel quel côté app même si l'utilisateur est en anglais — contrairement au reste de l'app, entièrement bilingue. Cosmétique, pas un problème de sécurité.

---

## 🟢 FAIBLE / À VÉRIFIER EN CONDITIONS RÉELLES — `Filter.or` + `orderBy` sur `journalDossier`

La nouvelle requête `journalDossier()` combine un `Filter.or` (participant) avec un `.where(dossierId==)` et un `.orderBy(creeLe)`. Les index composites nécessaires ont été ajoutés (`firestore.indexes.json`), mais cet environnement ne peut pas se connecter à un vrai compte Firebase pour vérifier que la requête s'exécute réellement sans erreur d'index manquant — à tester sur un vrai appareil avant de considérer ce point acquis.

---

## Résumé

| # | Sévérité | Sujet | Fichier | Statut |
|---|---|---|---|---|
| 1 | 🔴 Critique | Accès permanent d'un participant retiré à ses propres notes de journal | `firestore.rules` | ✅ Corrigé le 2026-08-30 |
| 2 | 🟠 Élevé | `participantsUids` modifiable librement sur une tâche/entrée par n'importe quel participant | `firestore.rules` | ✅ Corrigé le 2026-08-30 |
| 3 | 🟡 Moyen | Création de dossier avec participants imposés, hors invitation | `firestore.rules` | ✅ Corrigé le 2026-08-30 |
| 4 | 🟡 Moyen | Pas de transaction sur `gerer_participant_dossier` (perte d'action concurrente) | `functions/main.py` | ✅ Corrigé le 2026-08-30 |
| 5 | 🟡 Moyen (préexistant) | Suppression de dossier n'efface pas le journal | `lib/services/firestore_service.dart` | ✅ Corrigé le 2026-08-30 |
| 6 | 🟢 Faible-moyen | Énumération de comptes par email | `functions/main.py` | ⚠️ Risque accepté (voir décision ci-dessous) |
| 7 | 🟢 Faible | Erreurs serveur non traduites | `functions/main.py` / écran participants | ✅ Corrigé le 2026-08-30 |
| 8 | 🟢 À vérifier | `Filter.or` + `orderBy` + index composites, jamais testé en réel | `firestore_service.dart` | ✅ Index manquants ajoutés — reste à tester sur appareil réel |

## Correctifs 4, 5, 7 et 8 — appliqués le 2026-08-30

- **Point 4 (transaction)** : `gerer_participant_dossier` lit et écrit maintenant le dossier dans une vraie transaction Firestore (`@firestore.transactional`) — la lecture de l'email (appel externe à l'API Auth, indépendant de l'état du dossier) reste hors transaction, mais tout ce qui dépend de l'état actuel du dossier (vérification du rôle, calcul de la nouvelle liste, écriture) est maintenant atomique. Vérifié : le décorateur Firestore ne relance la fonction QUE sur un vrai conflit de transaction (`Aborted`) — une erreur métier (ex. "créateur non retirable") remonte immédiatement sans nouvelle tentative, comme avant.
- **Point 5 (journal orphelin)** : `supprimerDossier()` supprime maintenant aussi les entrées de `journalDossier` du dossier, dans le même batch que les tâches.
- **Point 7 (traduction)** : les deux erreurs `FAILED_PRECONDITION` envoient maintenant un code stable dans `details` ("createurNonRetirable"/"createurRoleFixe") plutôt que le message français en dur — l'écran choisit le bon texte selon la langue de l'appareil via deux nouvelles clés `participantsErreurCreateurNonRetirable`/`participantsErreurCreateurRoleFixe` (FR+EN).
- **Point 8 (index)** : en creusant ce point, découvert que les requêtes `Filter.or` sur `taches` (`tachesDuDossier`, `tachesNonTerminees`, `modifierDossier`, `supprimerDossier`) n'avaient un index composite QUE pour la branche `participantsUids` — la branche `uid` (symétrique, nécessaire à la même requête) n'en avait aucun. Ajoutés dans `firestore.indexes.json` : `taches (uid, dossierId)` et `taches (uid, statut)`. `journalDossier` avait déjà les deux branches. **Reste à faire** : un vrai test sur appareil (compte réel, dossier partagé) pour confirmer qu'aucun index ne manque encore — impossible à vérifier depuis cet environnement.
- **Vérifié** : `firebase deploy --only firestore --dry-run` (règles + index, validation seule) compile sans erreur ; `flutter analyze` propre ; `main.py` importé avec succès après la réécriture transactionnelle ; `flutter gen-l10n` régénéré avec les 2 nouvelles clés dans les 3 fichiers générés.

## Deuxième passe — après le correctif transactionnel, la fonction digest, l'écran participants

Nouvelle relecture adversariale complète (demande : "continuons à red teamer" avant tout build/déploiement), en repartant de zéro sur tout ce qui avait changé depuis la première passe : la réécriture transactionnelle de `gerer_participant_dossier`, la correction du digest quotidien, `dossier_participants_service.dart`, et le modèle `Dossier` (champ `participantsEmails` pas encore audité). La plupart de ce qui a été revérifié tient bon à l'examen (sémantique de retry de la transaction, ordre lecture-avant-écriture, portée par-destinataire de l'état de notification). Trois points nouveaux, plus petits que la première passe :

### 🟡 Moyen — perdre l'accès à un dossier pendant qu'on le regarde plantait sur un chargement infini
`dossier_detail_screen.dart` et `participants_dossier_screen.dart` utilisaient tous deux un `StreamBuilder<Dossier>` sur le document unique, sans jamais vérifier `snapshot.hasError`. Avant la Phase 1, ce scénario ne pouvait pas arriver (un dossier appartenait pour toujours à son unique propriétaire) — maintenant qu'un administrateur peut retirer quelqu'un en direct, la personne retirée, si elle a l'écran ouvert au même moment, reçoit une erreur de permission sur son flux Firestore ; Flutter efface alors silencieusement les dernières données reçues (comportement par défaut de `AsyncSnapshot.withError`), et l'écran reste bloqué indéfiniment sur l'indicateur de chargement, sans aucune explication.
**Corrigé** : nouveau widget partagé `VueAccesRevoque` (`lib/widgets/vue_acces_revoque.dart`) — message clair + bouton pour revenir en arrière, branché sur `snapshot.hasError` dans les deux écrans.

### 🟢 Faible → tranché par Tobie — un administrateur pouvait gérer un AUTRE administrateur
La première version de `gerer_participant_dossier` ne protégeait que le créateur ; n'importe quel administrateur pouvait retirer, rétrograder, ou changer le rôle d'un AUTRE administrateur (pair à pair), et promouvoir librement quelqu'un au rang d'administrateur. **Décision de Tobie : à restreindre — seul le créateur gère les administrateurs.**
**Corrigé sur trois niveaux** :
- **Fonction serveur** : `gerer_participant_dossier` refuse maintenant (`PERMISSION_DENIED`) toute action d'un non-créateur qui ajouterait, retirerait, ou changerait le rôle d'un administrateur (dans un sens ou dans l'autre — promotion incluse).
- **Règles Firestore** : la règle `update` de `/dossiers` réserve maintenant TOUTE modification de `participantsUids`/`roles`/`participantsEmails` au créateur seul (au lieu de créateur+administrateur) — ferme le contournement par écriture directe (hors fonction Cloud), vérifié sans casser l'app (`modifierDossier` ne touche jamais ces champs, confirmé en relisant `firestore_service.dart`).
- **Écran** : `participants_dossier_screen.dart` masque désormais l'option "Passer administrateur" et le menu de gestion sur une ligne administrateur pour quiconque n'est pas le créateur.

### 🟢 Très faible, resté inerte, corrigé par cohérence — `participantsEmails` pas figé à la création
La règle `create` des dossiers ne figeait pas `participantsEmails` (contrairement à `participantsUids`/`roles`) — sans conséquence réelle (jamais affiché pour un uid absent de `roles`, verrouillé au créateur seul à la création), mais figé par cohérence à coût nul (`== {}` ajouté à la règle `create`).

**Vérifié** : `firebase deploy --only firestore --dry-run` (règles + index) compile sans nouvelle erreur, `flutter analyze` propre, `flutter gen-l10n` régénéré (nouvelle clé `dossierAccesRevoqueMessage`), `main.py` importé avec succès.

## Troisième passe — après les corrections admin/administrateur

Nouvelle relecture ("continuons le red team"). Vérifié : permissions de suppression/modification sur tâches/journal (tout participant peut agir sur n'importe quelle entrée, y compris pas la sienne — cohérent avec le principe "accès complet" déjà choisi par Tobie pour le contenu, pas une nouvelle incohérence) ; cas limites du digest quotidien (tous sains) ; interaction entre la cascade de `supprimer_compte_definitivement` et la nouvelle restriction "seul le créateur gère les administrateurs" (correctement exemptée — retirer un compte SUPPRIMÉ n'est pas quelqu'un qui agit sur un autre, c'est un nettoyage après auto-suppression). Aucun nouveau bug de code trouvé cette fois. Un point différent, de nature structurelle plutôt qu'un bug :

### 🟢 Limitation documentée (pas un bug) — le cache Firestore hors-ligne survit à un retrait
Firestore garde par défaut une copie locale (SQLite/IndexedDB) des documents déjà synchronisés sur l'appareil. Quand un administrateur retire un participant, l'accès EN DIRECT est bien coupé côté serveur (vérifié tout au long de cette session), mais la dernière copie déjà synchronisée reste sur le téléphone de la personne retirée jusqu'à ce que le cache soit effacé. Le verrou PIN (`verrou_screen.dart`) protège l'écran de l'app, pas le stockage brut du téléphone (confirmé : c'est un simple portail UI, pas un chiffrement du stockage) — quelqu'un avec un accès technique à SON PROPRE appareil (root/débogage) pourrait en théorie extraire la dernière version connue après avoir été retiré.
**Pas corrigé** : limite inhérente à toute app "offline-first", pas introduite par la collaboration, pas de correctif propre sans désactiver le mode hors-ligne (une des raisons d'être de l'app) ou construire une invalidation de cache par-document (non supportée par le SDK Firestore côté client). Traité comme le point 6 — risque accepté et documenté plutôt que correctif disproportionné.

## Quatrième passe — via l'agent de revue de code automatisé

Nouvelle demande ("on continue"). Cette fois, plutôt que de continuer seul, appel à l'agent `/code-review` sur l'ensemble du diff de la session pour un regard indépendant. Résultat : 4 trouvailles, dont une sérieuse — la plus grave de toute cette exploration après le point 🔴 critique de la première passe.

### 🟠 Élevé — des tâches/entrées de journal forgées pouvaient être injectées dans la liste de N'IMPORTE QUI
`firestore.rules`, règle `create` de `taches`/`journalDossier` : `estParticipant(request.resource.data)` vérifiait seulement que le DEMANDEUR figurait dans le `participantsUids` qu'il écrivait lui-même — rien n'empêchait d'y ajouter AUSSI l'uid d'une victime. Un compte authentifié pouvait donc créer `taches.add({uid: soi, dossierId: n'importe quoi, participantsUids: [soi, uidVictime], descriptionCourte: "texte de phishing", ...})` : la tâche forgée apparaissait directement dans les écrans "À traiter"/Bilan de la victime ET dans son rappel quotidien, sans que la victime ait jamais accepté quoi que ce soit. Exploitable par quiconque a DÉJÀ partagé ne serait-ce qu'un seul dossier avec quelqu'un (`participantsEmails` révèle les uids aux co-participants) — donc réellement par toute personne ayant déjà collaboré une fois, même après avoir été retirée de tout dossier commun depuis.
**Corrigé** : nouvelle fonction `participantsCoherents()` dans `firestore.rules` — une liste solo (`[soi-même]`) reste autorisée sans lecture supplémentaire (nécessaire pour la création "dossier + première tâche" dans le même batch, où le dossier n'existe pas encore au moment où la règle s'évalue), mais toute liste contenant quelqu'un d'autre doit désormais correspondre EXACTEMENT à la vraie liste actuelle du dossier référencé (vérifié via `get()`). Vérifié que ça ne casse aucun chemin légitime existant (`_ajouterDossierEtTacheAuBatch` reste solo, `ajouterTacheADossier`/`ajouterEntreeJournal` sur un dossier partagé passent par la vérification `get()` avec une liste qui correspond réellement).

### 🟡 Moyen — la synchronisation en cascade pouvait geler un mauvais état sous concurrence
`_synchroniser_participants_dossier` recevait la liste `participantsUids` en PARAMÈTRE (figée au moment de l'appel), au lieu de la relire. Deux appels `gerer_participant_dossier` concurrents sur le même dossier (ex. deux administrateurs ajoutent chacun quelqu'un presque en même temps) pouvaient chacun synchroniser leurs tâches/entrées avec LEUR propre liste — si l'exécution la plus lente des deux terminait APRÈS la plus rapide, elle écrasait le bon résultat final avec une liste périmée, faisant perdre la visibilité du dernier participant ajouté sur toutes les tâches/entrées déjà existantes du dossier, jusqu'à la prochaine action de gestion.
**Corrigé** : `_synchroniser_participants_dossier` relit maintenant la liste ACTUELLE du dossier au moment où elle s'exécute, au lieu de faire confiance à une valeur capturée plus tôt — fait converger vers le bon état quel que soit l'ordre d'exécution des synchronisations concurrentes.

### 🟢 Faible — `participantsEmails` jamais nettoyé à la suppression de compte
`supprimer_compte_definitivement` retirait bien le compte supprimé de `participantsUids`/`roles` sur les dossiers partagés d'autrui (Angle 66), mais oubliait `participantsEmails` — l'adresse email du compte "vraiment supprimé" restait visible indéfiniment dans le dossier des autres.
**Corrigé** : `participantsEmails` nettoyé en même temps que `participantsUids`/`roles`.

### 🟢 Faible — bouton "Supprimer" affiché à tout le monde, y compris à qui ne peut pas l'utiliser
`dossier_detail_screen.dart` affichait le bouton de suppression du dossier à TOUT participant, alors que la règle le réserve créateur/administrateur — un simple contributeur pouvait passer par la double confirmation (friction + avertissement d'irréversibilité) puis essuyer une exception non gérée sans aucun message.
**Corrigé** : bouton masqué pour un simple contributeur ; `_supprimerDossier` enveloppé dans un `try/catch` (défense en profondeur, pour la fenêtre de course où le rôle changerait pendant la confirmation).

**Vérifié** : `firebase deploy --only firestore --dry-run` compile sans nouvelle erreur, `flutter analyze` propre, `main.py` importé avec succès.

## Cinquième passe — re-vérification par l'agent /code-review, après mes propres correctifs

Nouvelle demande ("on continue toujours"). Cette fois, appel à `/code-review` pour vérifier mes PROPRES correctifs de la passe précédente — bonne pratique de relire ce qu'on vient soi-même de corriger. 3 trouvailles, 2 confirmées et corrigées immédiatement, 1 qui est un vrai conflit de produit, pas un bug à corriger seul.

### 🔴 Critique, corrigé — `uid` librement réécrivable, menant à une destruction de données cross-utilisateur
En comparant avec `git diff` contre l'état d'AVANT cette session : les règles ORIGINALES (avant la refonte collaboration du 29/08) figeaient `uid` à l'update sur `dossiers`/`taches`/`journalDossier` (`request.resource.data.uid == resource.data.uid`). La refonte vers le modèle par rôles a supprimé cet invariant PAR ERREUR sur les trois collections, sans que je m'en rende compte pendant tout le reste de cette exploration.
**Scénario concret** : Bob (simple contributeur d'un dossier d'Alice) modifie ce dossier en changeant SEULEMENT le champ `uid` vers l'uid de Charlie (un tiers sans aucun rapport), sans toucher participantsUids/roles/participantsEmails — la règle l'autorisait (elle ne vérifiait que "les champs de participants n'ont pas changé", jamais `uid` lui-même). Plus tard, quand Charlie supprime SON PROPRE compte pour des raisons totalement indépendantes, `supprimer_compte_definitivement` (qui filtre par `uid==`) supprime le dossier d'Alice — quelqu'un qui n'a jamais eu aucun lien avec ce dossier détruit malgré lui les données professionnelles d'Alice, simplement en fermant son compte. Même mécanisme pour les tâches (en plus : `_taches_actives_visibles`, utilisée par le rappel quotidien, interroge aussi par `uid==` — une tâche forgée avec l'uid d'un tiers non invité l'expose directement dans son historique de notifications, en clair, en contournant totalement les règles côté client puisque la requête passe par le SDK Admin).
**Corrigé** : `uid` figé à l'update sur les trois collections, restaurant l'invariant d'origine.

### 🟢 Faible, corrigé — trou dans mon propre correctif de la passe précédente
En ajoutant la restriction "seul le créateur gère les administrateurs" (passe précédente), `peutGerer` dans `participants_dossier_screen.dart` a été réécrit sans revérifier `jePeuxGerer` (est-ce que le VIEWER a ne serait-ce qu'un droit de gestion à la base) — un simple contributeur voyait donc le menu de gestion (changer de rôle / retirer) sur les autres contributeurs, bloqué seulement côté serveur avec un message d'erreur confus au lieu d'être simplement invisible.
**Corrigé** : `jePeuxGerer` réintégré dans la condition.

### 🟠 Conflit de produit réel, PAS corrigé — le chiffrement des notes casse le journal partagé
Vérifié en relisant `dossier_detail_screen.dart` (lignes 585-597, 699-722) : **toute** nouvelle entrée de journal passe actuellement, sans option, par `ChiffrementNotesService` (`chiffre: true` en dur dans `_ajouter()`) — chiffrée avec une clé dérivée de la phrase secrète PERSONNELLE de celui qui écrit, jamais partagée avec personne d'autre, jamais envoyée au serveur.
**Le problème** : dans un dossier partagé, si Alice et Bob ont chacun leur propre phrase secrète (des clés différentes), Bob ne pourra JAMAIS déchiffrer les entrées écrites par Alice, et réciproquement — `_dechiffrerToutes()` (ligne 713) attrape l'échec de déchiffrement (mauvaise clé) et affiche l'entrée comme "verrouillée" **pour toujours**, même après avoir correctement déverrouillé sa PROPRE phrase secrète. Le commentaire du code lui-même ("Improbable... mauvaise clé déjà validée") montre que ce cas n'avait jamais été anticipé comme le cas NORMAL pour un deuxième participant — seulement comme un bug rarissime.
**Pourquoi ce n'est pas juste un bug technique à corriger seul** : Tobie avait explicitement choisi d'abandonner ce chantier ("ça commence à devenir bizarre et c'est une perte de temps... on oublie cette histoire"), en laissant le code déployé mais "dormant". Le souci, c'est qu'il n'est PAS dormant : il s'active automatiquement sur CHAQUE nouvelle entrée de journal, sans que l'utilisateur ait explicitement demandé à chiffrer quoi que ce soit — jusqu'ici sans conséquence puisque personne ne partageait de dossier avec personne d'autre. Maintenant que la Phase 1 rend le partage réel, ce chantier abandonné devient activement nuisible pour toute personne qui partage un dossier et utilise le journal.
**Décision de Tobie : option 1 — désactiver le chiffrement dès qu'un dossier est partagé.**
**Corrigé** dans `_SectionJournal._ajouter()` (`dossier_detail_screen.dart`) : `estPartage = widget.participantsUids.length > 1` — si le dossier est partagé, l'entrée s'écrit en clair (`chiffre: false`), sans jamais demander/dériver de phrase secrète ; si le dossier reste strictement solo, comportement inchangé (chiffrement actif).
**Limite résiduelle assumée, pas corrigée** : un dossier qui était SOLO avec de vraies entrées chiffrées puis PARTAGÉ ensuite garde ses anciennes entrées chiffrées avec la clé de l'auteur d'origine — toujours illisibles pour les nouveaux participants (mais lisibles pour l'auteur d'origine). Seules les NOUVELLES entrées, à partir de maintenant, respectent la règle "partagé ⇒ jamais chiffré". Cas rare (il faudrait déjà avoir testé le chiffrement en solo avant de partager le dossier), et le comportement reste sûr dans tous les cas (jamais de contenu affiché en clair par erreur — juste "verrouillée" pour de bon sur ces entrées précises).
**Vérifié** : `flutter analyze` propre.

## Sixième passe — encore l'agent /code-review sur mes correctifs précédents

Nouvelle demande ("on continue"). Même méthode : `/code-review` sur les tout derniers correctifs (fixation `uid`, désactivation chiffrement partagé). 3 trouvailles, toutes corrigées.

### 🟠 Élevé, corrigé — `uid` jamais vérifié à la CRÉATION (seulement à l'update, oublié)
La faille du point 🔴 critique de la passe précédente ("uid figé") n'avait été corrigée qu'à l'UPDATE — jamais à la CRÉATION. Sur `taches`/`journalDossier`, la règle `create` ne vérifiait jamais `uid` du tout : un attaquant pouvait créer directement un document avec `uid: <victime réelle>` et `participantsUids: [soi-même]` (solo, suffisant pour passer `estParticipant`/`participantsCoherents`). Exposition côté serveur (SDK Admin, ignore les règles) via `_taches_actives_visibles`/`digest_quotidien`.
**Piège en corrigeant** : sur une TÂCHE, `uid` désigne le PROPRIÉTAIRE du dossier — pas toujours le demandeur (un contributeur peut ajouter une tâche au dossier de quelqu'un d'autre). Une simple règle "`uid == request.auth.uid`" aurait cassé ce cas légitime. Et vérifier `uid` et `participantsUids` par DEUX fonctions indépendantes (chacune avec son propre repli solo) aurait rouvert la même classe de trou en mélangeant un repli solo sur l'un avec une correspondance forgée sur l'autre.
**Corrigé** : nouvelle fonction `tacheCoherente()` qui valide `uid` ET `participantsUids` ENSEMBLE, dans les deux seuls cas réels (tout solo, ou correspond exactement au vrai dossier référencé). Sur `journalDossier`, plus simple : `uid` désigne toujours l'auteur réel (toujours le demandeur), donc figé sans condition (`uid == request.auth.uid`), à côté de `participantsCoherents()` inchangée.

### 🟢 Corrigé — entrées de journal d'un AUTRE participant orphelines à la suppression de compte
`supprimer_compte_definitivement` supprimait `journalDossier` par `where('uid','==',ceCompte)` — mais `journalDossier.uid` = l'AUTEUR réel, pas le propriétaire du dossier. Une entrée écrite par Bob dans le dossier d'Alice (`uid: Bob`) n'était jamais retrouvée quand Alice supprimait son compte, laissant orpheline une note qui référence un dossier qui n'existe plus. `FirestoreService.supprimerDossier` (le flux manuel côté app) était déjà correct sur ce point (filtre par `participantsUids contains`, qui capture tout le monde) — la fonction serveur ne l'était pas.
**Corrigé** : filtrage par `dossierId` (pas par `uid`) pour les dossiers que ce compte POSSÈDE, retrouvant tout le contenu quel qu'en soit l'auteur — même logique que côté app.

### 🟢 Corrigé — fenêtre de course résiduelle sur la désactivation du chiffrement
`estPartage` était capturé AVANT l'attente (potentiellement longue) de la saisie de la phrase secrète — si le dossier passait de solo à partagé PENDANT cette saisie, l'écriture utilisait encore la valeur périmée et chiffrait quand même l'entrée.
**Corrigé** : `estPartage` relu juste avant l'écriture réelle, après l'attente. Fenêtre résiduelle réduite au strict minimum (le temps de calcul du chiffrement lui-même), jamais totalement éliminable sans transaction — proportionné.

**Vérifié** : `firebase deploy --only firestore --dry-run` compile sans nouvelle erreur, `flutter analyze` propre, `main.py` importé avec succès.

## ⚠️ Incertitude non résolue, à vérifier en PRIORITÉ juste après le premier déploiement

En creusant la faille `uid` de cette passe, une question plus profonde et non résolue est apparue : `estParticipant()` (voir tout en haut du fichier) a une structure CONDITIONNELLE (`'participantsUids' in data ? ... : ...`), pas un simple OU. Les requêtes de LISTE côté app (`_filtreParticipant` dans `firestore_service.dart`) utilisent un `Filter.or(uid==moi, participantsUids array-contains moi)`. **Il n'est pas certain que Firestore accepte une requête `Filter.or()` dont la structure ne correspond pas EXACTEMENT à une règle elle-même écrite comme un simple OU** — la documentation Firestore sur la compatibilité requête/règles pour les requêtes OR est peu précise sur les règles conditionnelles (ternaires basées sur la présence d'un champ). Si Firestore rejette ces requêtes (`PERMISSION_DENIED`), TOUT Phase 1 (tâches/journal des dossiers partagés) ne fonctionnerait pas du tout pour personne — pas une faille silencieuse, mais un échec bruyant et immédiat.
**Impossible à tester depuis cet environnement** (pas d'accès à un vrai compte Firebase connecté). **Recommandation forte** : dès le premier déploiement, tester en conditions réelles AVANT toute autre chose — ouvrir un dossier partagé à deux vrais comptes et vérifier que les écrans "À traiter"/Bilan/Journal se chargent sans erreur de permission pour le participant non-propriétaire. Si ça échoue, la piste de correction la plus probable est de revenir à un `estParticipant()` en simple OU (`uid==moi OR participantsUids contains moi`, sans condition sur la présence du champ) et de fermer autrement la faille "auteur retiré garde l'accès" du tout premier correctif critique (par exemple via une vraie migration plutôt qu'un repli conditionnel).

## Septième passe — encore /code-review, sur les correctifs uid/tacheCoherente

Nouvelle demande ("on continue"). 6 trouvailles cette fois — 4 corrigées, 1 (déjà examinée en passe 3, ré-ouverte avec un angle nouveau) posée en question à Tobie, 1 écartée après analyse (coût jugé négligeable, déjà anticipé).

### 🟢 Corrigé — le filtre par dossierId avait REMPLACÉ le filtre `uid==` au lieu de s'y ajouter
En corrigeant le point "entrées orphelines" de la passe précédente, le filtre `uid==` d'origine sur `taches`/`journalDossier` dans `supprimer_compte_definitivement` a été supprimé au lieu d'être gardé EN PLUS du nouveau filtre par dossierId. Un document DÉJÀ orphelin (dossier supprimé par un autre moyen avant que `journalDossier` soit inclus dans `FirestoreService.supprimerDossier`, par exemple) ne serait plus jamais retrouvé — le filtre par dossierId ne retrouve que le contenu des dossiers ACTUELLEMENT possédés.
**Corrigé** : les deux filtres coexistent maintenant (dossierId pour le contenu des dossiers possédés quel qu'en soit l'auteur, `uid==` en complément pour les propres documents de ce compte même orphelins).

### 🟢 Corrigé — le créateur pouvait encore contourner `gerer_participant_dossier` en écriture directe
La règle `update` des dossiers laissait encore le CRÉATEUR écrire `participantsUids`/`roles`/`participantsEmails` directement (décision du 30/08 : "réservé au créateur seul" — mais "réservé au créateur" laissait justement le créateur passer par la porte de derrière). Un accès direct à l'API aurait contourné TOUTES les validations de la fonction serveur (email résolu, déjà-participant, valeurs de rôle valides, restriction administrateur/administrateur) ET sa synchronisation en cascade vers les tâches/entrées de journal — un dossier modifié ainsi serait durablement incohérent avec son propre contenu.
**Corrigé** : ces trois champs sont maintenant figés pour TOUT LE MONDE à l'update, y compris le créateur — seule la fonction serveur peut les changer. Vérifié : aucun chemin légitime de l'app n'écrit jamais ces champs directement.

### 🟢 Corrigé — petite fragilité et duplication de code (pas une faille)
`FirebaseAuth.instance.currentUser!.uid` (force-unwrap, pourrait planter si null) et l'expression de résolution de rôle dupliquée mot pour mot dans deux écrans (`dossier_detail_screen.dart` et `participants_dossier_screen.dart`) — risque de divergence future si le repli change un jour dans une seule des deux copies.
**Corrigé** : nouvelle méthode `Dossier.roleDe(uid)` centralisant la logique, utilisée dans les deux écrans ; `currentUser?.uid` avec repli `VueAccesRevoque` (déjà utilisé pour l'accès révoqué) au lieu d'un force-unwrap qui planterait.

### 🟢 Écarté après analyse — appel `get_user()` dans la boucle de retry de la transaction
Le calcul du backfill `participantsEmails[proprietaire_uid]` (appel externe à l'API Auth) tourne à l'intérieur de la fonction transactionnelle, donc se relance à chaque nouvelle tentative en cas de conflit réel. Déjà anticipé et jugé acceptable au moment d'écrire ce code (appel rare, idempotent, coût négligeable à l'échelle de cette app) — pas de changement.

### 🟠 Question ré-ouverte et TRANCHÉE — n'importe quel participant pouvait modifier/supprimer l'entrée de journal d'un AUTRE
Déjà examiné en passe 3 ("cohérent avec accès complet, pas une incohérence") — mais en le revoyant, la vision initiale de Tobie pour le journal partagé (verbatim, session précédente) disait vouloir "un journal en commun où on **distingue bien les entrées de chaque collaborateur**" — DISTINGUER par auteur suggère que l'auteur devrait rester protégé, pas que n'importe qui puisse éditer/supprimer le travail de quelqu'un d'autre.

**Décision de Tobie** : "auteur et créateurs et administrateur seul" — l'auteur de l'entrée, OU le créateur, OU un administrateur (moderation possible même sans être l'auteur), mais pas un simple contributeur sur l'entrée d'un autre.

**Corrigé sur deux niveaux** :
- **`firestore.rules`** : nouvelle fonction `estAuteurOuGestionnaire(data)` — auteur (`data.uid == request.auth.uid`, toujours vrai pour son propre uid depuis le figeage plus haut) OU rôle créateur/administrateur sur le dossier référencé (lu via `get()`, comme `role()` déjà utilisée ailleurs). Appliquée aux règles `delete`/`update` de `journalDossier`.
- **Écran** : `_SectionJournal` reçoit maintenant `monUid`/`monRole` (déjà calculés dans le `StreamBuilder<Dossier>` parent, réutilisés) ; `_ligneEntree` calcule `peutGererCetteEntree` et masque les boutons modifier/supprimer pour qui n'y a pas droit. `_supprimer` protégée par `try/catch` en défense en profondeur (`_editer` l'était déjà).

**Vérifié** : `firebase deploy --only firestore --dry-run` compile sans nouvelle erreur, `flutter analyze` propre, `main.py` importé avec succès.

## Décisions de roadmap (hors red team du code) — séquencement et futurs groupes multi-dossiers

En répondant à la question sur les permissions administrateur, Tobie a soulevé trois sujets structurants de plus grande ampleur :
1. Toute action d'un contributeur doit être approuvée par un administrateur ou le créateur (refonte du modèle "accès complet" actuel).
2. Un administrateur doit avoir la confirmation du créateur avant de supprimer un dossier ou des tâches.
3. Une nouvelle idée : regrouper plusieurs dossiers liés dans un "groupe"/"communauté" pour une équipe qui travaille sur plusieurs dossiers à la fois, pas un seul.

Les points 1 et 2 correspondent exactement à ce qui avait été catalogué "Phase 2" lors de l'exploration à 74 angles du 29/08 (workflow d'approbation à plusieurs, déjà noté comme différé). Le point 3 est entièrement nouveau, jamais exploré.

**Séquencement tranché par Tobie** : déployer la Phase 1 actuelle D'ABORD (accès complet, déjà passée au crible sur 8 tours de red team dans ce document) pour un premier vrai test en conditions réelles, plutôt que de tout construire avant le premier déploiement. Les points 1, 2 et 3 deviennent la prochaine version, à concevoir sur une base validée.

**Principe d'accès pour les groupes, tranché avec l'aide d'un raisonnement structuré (Tobie : "aide moi à prendre une décision logique")** :
- Option A (accès automatique à tous les dossiers du groupe) vs Option B (groupe purement organisationnel, accès toujours décidé dossier par dossier) — comparées explicitement.
- Recommandation donnée : Option B, pour trois raisons — cohérence avec le principe fondateur de Vigie (minimisation des données, accès au cas par cas, présent depuis les toutes premières notes de conception du 06/08) ; aucun changement requis au modèle d'accès par dossier tout juste validé aujourd'hui ; extension naturelle de `collaborateursParDefaut` (déjà à moitié conçu) plutôt qu'un concept entièrement nouveau.
- **Tobie a validé l'option B.**
- **Pas encore conçu en détail** — une vraie exploration (dans l'esprit de celle du 29/08 pour la collaboration par dossier) reste à faire avant tout code : structure du groupe, qui peut créer/gérer un groupe, comment un groupe facilite l'invitation à un dossier sans lui donner d'accès automatique, etc.

## Huitième passe — encore /code-review, sur le retrait volontaire et estAuteurOuGestionnaire

Nouvelle demande ("on continue le red team"). 2 trouvailles, toutes deux sérieuses, toutes deux corrigées.

### 🔴 Critique, corrigé — le repli "solo" des règles create pouvait être "activé" plus tard par la synchronisation en cascade
`participantsCoherents()`/`tacheCoherente()` autorisaient un repli "solo" (`participantsUids == [soi-même]`) SANS vérifier que `dossierId` ne pointe pas vers le VRAI dossier de quelqu'un d'autre. Résultat : n'importe qui pouvait créer une tâche/entrée solo (invisible au début, puisque `participantsUids` ne contient que l'attaquant) en pointant `dossierId` vers un dossier réel connu (typiquement le sien propre, ou celui d'un ancien dossier partagé). Le document restait dormant — jusqu'à ce que N'IMPORTE QUELLE action de gestion légitime sur ce dossier (ajouter/retirer un participant, une action de routine) déclenche `_synchroniser_participants_dossier`, qui écrase AVEUGLÉMENT `participantsUids` sur TOUS les documents portant ce `dossierId` — y compris le document forgé — avec la vraie liste de participants. Le document forgé devenait alors visible de tous, avec un contenu entièrement contrôlé par l'attaquant, sans jamais avoir été un vrai participant.
**Corrigé** : le repli solo n'est plus autorisé QUE si le dossier référencé N'EXISTE PAS ENCORE (`!exists(...)`) — cas réel unique : la création "dossier + première tâche" dans le même batch. Dès que le dossier existe (même s'il est solo, jamais partagé), il faut passer par la branche `get()` qui exige une correspondance EXACTE avec son vrai état actuel. Vérifié : ne casse aucun chemin légitime (nouveau dossier solo, ajout à un dossier existant solo OU partagé — tous passent maintenant par la comparaison `get()`, qui les valide correctement dans les trois cas).

### 🟠 Élevé, corrigé — un auteur retiré du dossier gardait un droit d'écriture permanent sur ses propres entrées
`estAuteurOuGestionnaire()` (ajoutée cette même journée pour la restriction "auteur ou créateur/administrateur") vérifiait `data.uid == request.auth.uid` SANS jamais vérifier `estParticipant()` — puisque `uid` est figé pour toujours sur une entrée de journal (jamais réécrit), un auteur RETIRÉ du dossier gardait un droit de modifier/supprimer SES PROPRES anciennes entrées indéfiniment, en ciblant le document directement par son identifiant (pas via une requête de liste, qui elle est déjà correctement bloquée). Défaisait tout l'intérêt de retirer quelqu'un.
**Corrigé** : `estParticipant(data)` exigé en préalable, pour les deux branches (auteur ET créateur/administrateur) — un utilisateur qui n'est plus participant ne peut plus rien modifier, quelle que soit la raison invoquée.

**Vérifié** : `firebase deploy --only firestore --dry-run` compile sans nouvelle erreur, `flutter analyze` propre.

## Neuvième passe (2026-08-31) — encore /code-review

Nouvelle demande ("on continue le red team"). 4 trouvailles, toutes corrigées — aucune critique cette fois, plutôt des affinages de fiabilité/cohérence.

### 🟠 Élevé, corrigé — course entre l'ouverture du formulaire "ajouter une tâche" et son envoi
`_ajouterTache` capture le dossier UNE SEULE FOIS (`.first`) avant d'ouvrir la boîte de dialogue, qui peut rester ouverte un moment (temps de remplir le formulaire). Si les participants changent PENDANT ce temps, `tacheCoherente()` (qui exige désormais une correspondance EXACTE avec l'état ACTUEL du dossier) refuserait l'envoi — un utilisateur parfaitement légitime aurait vu un `PERMISSION_DENIED` confus. Même classe de course déjà corrigée pour le journal (passe précédente), oubliée ici.
**Corrigé** : le dossier est relu juste avant l'envoi réel, pas capturé à l'ouverture du formulaire.

### 🟡 Corrigé — `auteurUid` pas figé à l'update du journal
Contrairement à `uid`/`dossierId`/`creeLe`/`participantsUids`, `auteurUid` restait librement réécrivable par créateur/administrateur. Sans conséquence sur l'AUTORISATION réelle (qui vérifie `uid`, jamais `auteurUid`), mais l'écran affiche les boutons modifier/supprimer selon `auteurUid` — un administrateur aurait pu faire croire à tort qu'une entrée appartient à quelqu'un d'autre, de façon indétectable pour les autres participants.
**Corrigé** : `auteurUid` figé aussi. Aucun chemin légitime ne le modifie jamais.

### 🟢 Corrigé — repli client plus permissif que le repli serveur
`Dossier.roleDe()` (créée passe précédente) repliait sur `'contributeur'` pour un uid absent de `roles` et non-propriétaire — mais le `role()` équivalent côté `firestore.rules` renvoie `null` (aucun droit) dans ce même cas. Actuellement inatteignable en pratique (`participantsUids`/`roles` toujours synchronisés ensemble), mais un repli client plus optimiste que le serveur est le genre d'écart qui peut mordre plus tard si cette garantie change.
**Corrigé** : repli sur une valeur qui ne correspond à AUCUN rôle réel plutôt que 'contributeur' par optimisme.

### 🟡 Corrigé — synchronisation en cascade totalement silencieuse en cas d'échec
`_synchroniser_participants_dossier` (best-effort, hors transaction par nécessité — un dossier peut avoir plus de documents que la limite d'une transaction Firestore) n'avait aucune gestion d'erreur : une panne partielle (dépassement de délai sur un très gros dossier, erreur transitoire) laissait certains documents avec une liste de participants périmée, sans qu'aucune trace n'en reste nulle part.
**Corrigé** : échec journalisé (même schéma que `digest_quotidien`), sans faire échouer l'appel entier — l'action principale (ajout/retrait) a déjà réussi au moment où la synchronisation se déclenche, elle se rattrapera à la prochaine gestion de participants sur ce dossier. Vraie atomicité complète non recherchée (architecturalement impossible ici), mais l'échec devient au moins visible.

**Vérifié** : `firebase deploy --only firestore --dry-run` compile sans nouvelle erreur, `flutter analyze` propre, `main.py` importé avec succès.

## Sujet ouvert par Tobie, pas encore traité — granularité des permissions administrateur

Tobie a soulevé, en répondant à la question ci-dessus : "il faut qu'on parle aussi des autorisations qu'un créateur peut donner à ses administrateurs." Pas encore de décision ni de correctif — sujet à creuser séparément (quel périmètre exact : un administrateur "complet" par défaut comme aujourd'hui, ou un créateur pourrait-il cocher des permissions précises par administrateur — gérer les participants oui/non, supprimer le dossier oui/non, modérer le journal oui/non... ? Question posée à Tobie pour cadrer avant de concevoir quoi que ce soit).

## Décision sur le point 6 (énumération de comptes par email) — risque accepté

Pas corrigé par un changement de code — décision documentée plutôt que correctif technique, après avoir pesé les options :
- Fermer complètement la faille demanderait de ne plus jamais révéler en direct si un email a un compte (ex. remplacer "aucun compte" par un système de invitation en attente jusqu'à inscription) — un changement de fonctionnement bien plus large que "avant le déploiement", et qui dégraderait l'expérience (l'invitant ne saurait plus dire à la personne "tu n'as pas encore de compte, inscris-toi d'abord").
- Le risque réel aujourd'hui est faible : Vigie compte une poignée d'utilisateurs (3 notifiés au dernier déploiement), tous des professionnels invités individuellement — pas un service grand public où l'énumération de comptes serait significative à l'échelle.
- **Si le nombre d'utilisateurs grandit**, ce point est à reconsidérer sérieusement avant d'ouvrir l'app plus largement — noté explicitement pour ne pas être oublié.

## Correctifs 1, 2 et 3 — appliqués le 2026-08-30

- **`estParticipant()`** : le repli `data.uid == moi` ne s'applique plus que si `participantsUids` est totalement absent du document — dès qu'il existe, seul lui compte. Ferme définitivement la faille critique (auteur retiré qui gardait accès à ses propres notes).
- **`taches`/`journalDossier`, règle `update`** : `participantsUids` est maintenant figé (comme `dossierId`/`creeLe` l'étaient déjà) — seule la fonction serveur (SDK Admin) peut encore le changer.
- **`dossiers`, règle `create`** : n'autorise plus qu'un dossier soit créé qu'avec SOI-MÊME comme unique participant (`participantsUids`/`roles`, s'ils sont envoyés, doivent être exactement `[soi]`/`{soi: 'createur'}`) — toute invitation doit désormais obligatoirement passer par `gerer_participant_dossier`.
- **Vérifié** : `firebase deploy --only firestore:rules --dry-run` (validation seule, aucun déploiement réel) — compile sans nouvelle erreur/avertissement (seul l'avertissement bénin déjà connu sur `role()` reste, inchangé).
- **Pas encore déployé en production** — reste à regrouper avec le reste de la Phase 1 (index, fonctions Cloud, écran) au moment du build/déploiement.
