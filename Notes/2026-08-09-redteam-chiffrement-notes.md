# Fiche de note — Red Team du chiffrement des notes privées

**Date :** 2026-08-09
**Sujet :** avant de coder le chiffrement du champ `notePrivee`, on vérifie qu'on chiffre la bonne chose, de la bonne façon, et qu'on ne crée pas un problème pire que celui qu'on résout.

---

## 1. Pourquoi on fait ça (rappel du vrai risque couvert)

Le PIN + biométrie (déjà en place) protège contre : **quelqu'un prend le téléphone déjà déverrouillé** et ouvre l'app.

Le chiffrement, lui, protège contre un risque différent : **quelqu'un accède directement à la base de données Firestore**, sans passer par l'app — par exemple si les identifiants Google du projet fuitent, si Google se fait pirater, ou en cas de réquisition judiciaire. Sans chiffrement, cette personne lirait les notes privées en clair. Avec chiffrement, elle ne voit que du texte illisible — comme un coffre-fort dont seul ton père a la combinaison, que même nous (toi et moi) ne connaissons pas.

**Point important :** ça ne remplace pas le PIN, ça couvre un trou différent. On garde les deux.

## 2. Comment ça marche, en clair

- Ton père choisit une **phrase secrète** (différente du code PIN — le PIN ouvre l'app, la phrase secrète déverrouille les notes).
- Cette phrase n'est **jamais envoyée ni stockée nulle part** — ni sur Firestore, ni chez nous. Elle sert uniquement, sur son téléphone, à fabriquer une clé de chiffrement.
- Chaque note privée est chiffrée avec cette clé avant de partir vers Firestore. Firestore ne stocke que le résultat chiffré.
- Pour relire une note, l'app refait la même opération en sens inverse, avec la même phrase.

## 3. Red Team — les 4 trous à colmater avant de coder

### Trou n°1 — La phrase oubliée = perte définitive, pour de vrai
C'est la conséquence directe du principe "même nous, on ne peut pas la récupérer" : **si ton père oublie sa phrase secrète, les notes déjà chiffrées sont perdues pour toujours**. Pas de "mot de passe oublié" possible ici, contrairement au PIN (qui peut se réinitialiser sans perte de données parce qu'il ne sert pas à chiffrer). Vu que le projet part du constat que ton père est débordé et oublieux, ce risque est réel et doit lui être présenté très clairement, avec un avertissement fort au moment où il choisit sa phrase.

### Trou n°2 — Est-ce qu'on chiffre uniquement `notePrivee` ?
Si on chiffrait aussi le nom de code (`nomCode`) ou les dates, l'app devrait tout déchiffrer juste pour afficher la liste des dossiers — lent, et compliqué pour rien. Le nom de code est déjà protégé par le principe du pseudonyme (fiche du 6 août). Je propose de garder le chiffrement **uniquement sur le contenu de la note privée**, qui est le seul champ vraiment sensible en texte libre.

### Trou n°3 — Combien de temps on garde la clé "déverrouillée" en mémoire ?
Si on redemande la phrase secrète à chaque note ouverte, c'est trop lourd pour quelqu'un déjà débordé. Si on la garde en mémoire indéfiniment, le chiffrement ne sert plus à rien dès que le téléphone est déverrouillé. Compromis proposé : la phrase est redemandée **une fois par session** (comme le PIN), puis la clé reste en mémoire (jamais sauvegardée sur le disque) jusqu'à ce que l'app se reverrouille.

### Trou n°4 — Les notes déjà écrites en clair
Certaines notes privées existent peut-être déjà en clair dans Firestore (avant qu'on ajoute le chiffrement). Il faudra un passage unique qui les chiffre au moment où ton père définit sa phrase secrète pour la première fois — sinon elles restent lisibles alors que les nouvelles sont protégées, ce qui donnerait un faux sentiment de sécurité.

## 4. Question pour trancher avant que je code

- **Sur le Trou n°1** : je prévois un écran d'avertissement explicite ("si tu oublies cette phrase, ces notes seront perdues pour toujours, personne ne peut les récupérer, pas même nous") + une option "réinitialiser mes notes chiffrées" qui efface uniquement les notes (pas les dossiers/tâches) si la phrase est vraiment perdue. Ça te va ?
- **Sur le Trou n°2** : on chiffre uniquement `notePrivee`, rien d'autre. D'accord ?
- **Sur le Trou n°3** : une phrase demandée une fois par session (comme le PIN), pas à chaque note. D'accord ?

## 5. Décision finale (2026-08-09)

Tobie a refusé la version "clé générée à sauvegarder en dehors du téléphone" — trop de responsabilité et de risque de perte pour lui/son père. Une alternative "chiffrement récupérable" (clé restaurable via re-connexion, comme le PIN) a été proposée, mais **Tobie a choisi d'abandonner complètement le chiffrement du champ `notePrivee`**.

**Ce qui protège les notes privées, en l'absence de chiffrement :**
- Règles de sécurité Firestore (chaque utilisateur ne peut lire que ses propres données).
- PIN + biométrie côté téléphone (déjà en place).
- Noms de code pseudonymisés pour les dossiers eux-mêmes.

**Risque assumé, en connaissance de cause :** en cas de fuite directe de la base Firestore (piratage du compte Google, faille chez Firebase, réquisition judiciaire), le contenu des notes privées serait lisible en clair. Ce risque a été expliqué clairement avant la décision — pas de chiffrement supplémentaire prévu pour l'instant.

**Item fermé.** Ne pas revenir sur ce sujet sauf si Tobie le demande explicitement (ex: si le produit évolue vers plus d'utilisateurs payants avec des exigences de confidentialité plus strictes — à réévaluer à ce moment-là, pas avant).
