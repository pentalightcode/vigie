# Fiche de note — Décisions sur l'automatisation, la sécurité, et les confirmations

**Date :** 2026-08-07

---

## 1. La logique d'autorisation Gmail est-elle sûre ?

**Le principe de base est le bon** (jeton OAuth, jamais le mot de passe, stocké côté serveur seulement) — c'est exactement comme ça que Zapier, IFTTT, ou n'importe quel "Connecter mon Gmail" fonctionne dans l'industrie. Mais "le principe est bon" ne veut pas dire "sans risque". Pour que ce soit vraiment solide, il faudra :
- Stocker le jeton **chiffré** (pas en clair dans Firestore).
- Utiliser le **droit le plus restreint possible** côté Google (lecture seule, jamais écriture/suppression).
- Ne jamais laisser ce jeton transiter côté téléphone — uniquement le serveur (Cloud Function) y touche.
- Journaliser les accès pour pouvoir détecter un usage anormal.

Le risque résiduel réel, même bien fait : **quiconque contrôle ce jeton côté serveur a un accès de lecture à la boîte mail**. Ce n'est pas négociable à zéro, juste réduit au minimum.

## 2. Émetteurs favoris plutôt que mots-clés — excellente idée

Tu as raison, c'est nettement mieux : au lieu de chercher des mots-clés dans toute la boîte (risque de rater des choses, ou de lire des emails sans rapport), on demande au père de renseigner lui-même l'adresse exacte du tribunal (et toute autre adresse de confiance). La recherche Gmail devient alors *"uniquement les emails venant de cette adresse précise"* — ça réduit radicalement ce que le système lit, et lui donne le contrôle. **Retenu pour la conception future.**

## 3. Nom réel à la création automatique, puis recodé — à ajuster légèrement

Tu acceptes que l'automatisation mette le vrai nom au départ. Une nuance technique importante : si ce vrai nom va dans le champ `nomCode` (celui qui n'est **jamais chiffré**, pensé pour ne contenir qu'un pseudonyme), il resterait **en clair dans la base de données** tant que le père n'a pas pensé à le recoder — et pour toujours s'il oublie.

**Proposition qui garde ton idée mais évite ce trou :** l'automatisation crée le dossier avec un nom provisoire neutre ("Dossier auto-1"), et met le **vrai nom extrait dans la note privée chiffrée** (celle qu'on va construire ensuite). Le père ouvre la note pour voir de quoi il s'agit, et choisit son propre nom de code quand il veut — le vrai nom n'est alors **jamais en clair**, même temporairement. Objectif identique au tien (peu de travail manuel), sans réintroduire une fuite.

## 4. L'automatisation reste une pièce maîtresse — mais elle ne couvre qu'une partie

Point important que tu as rappelé : le père reçoit **beaucoup de dossiers physiquement**, pas par email. Donc même avec Gmail automatisé à 100%, la saisie manuelle pour les dossiers papier restera nécessaire. **Conséquence :** le rappel "pense à ajouter tes dossiers" (Phase 2) reste utile et nécessaire *même après* l'automatisation Gmail — l'un ne remplace pas l'autre, ils sont complémentaires.

## 5. Sur la façon de présenter le consentement

Je comprends l'idée (expliquer clairement les bénéfices pour qu'il consente en connaissance de cause) — mais une nuance à garder en tête : vu que c'est un magistrat avec des obligations déontologiques sur le secret professionnel, l'écran de consentement doit **informer honnêtement des deux côtés** (bénéfices ET risques réels), pas "convaincre" comme on pousserait une vente. La différence est fine mais importante : lui donner tous les éléments pour qu'IL décide librement, plutôt que d'orienter sa décision. Je le note pour quand on construira cet écran (Phase 3).

## 6. Confirmations — décisions actées
- **Marquer "fait"** et **supprimer une tâche** : double confirmation (deux étapes), comme demandé. Remplace ma proposition initiale (bandeau "Annuler").
- **Déconnexion** : double confirmation.
- **Suppression du compte** (nouveau, Phase 3) : fonctionnalité à ajouter — triple confirmation avec 3 messages d'alerte distincts sur les risques. Techniquement : supprime le compte Firebase ET tous les dossiers/tâches associés (irréversible, donc c'est ici, bien plus que sur "marquer fait", que le niveau de friction maximal est justifié).
