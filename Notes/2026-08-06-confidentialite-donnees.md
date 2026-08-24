# Fiche de note — Où les données doivent-elles vivre ? (confidentialité)

**Date :** 2026-08-06
**⚠️ Sécurité non négociable (règle 4)** : cette décision conditionne toute l'architecture technique, donc on la prend au sérieux avant de coder quoi que ce soit.

---

## 1. Ce que dit la loi béninoise (en langage simple)

Le Bénin a une loi (**Code du numérique, loi n°2017-20**, Livre 5) qui protège les données personnelles, appliquée par une autorité appelée **APDP** (un peu comme la CNIL en France).

Point important : cette loi définit des **"données sensibles"** — et parmi elles, il y a explicitement les données liées à des **"poursuites, condamnations pénales ou administratives"**. Autrement dit : les informations que ton père manipule sur ses dossiers (affaires, parties, procédures) rentrent très probablement dans cette catégorie "sensible" au sens de la loi.

Conséquence pratique : la loi dit que le traitement de ces données doit rester **confidentiel**, fait uniquement par des personnes autorisées, sur instruction du responsable (ici, ton père). Ça veut dire concrètement :
- Toi (développeur) ne dois **jamais voir le contenu réel** des dossiers de ton père.
- Si les données sortent du Bénin (ex : stockées sur un serveur cloud aux USA/Europe), il peut y avoir des règles supplémentaires à respecter.

**Je ne suis pas certain à 100%** des obligations exactes de déclaration auprès de l'APDP pour ce cas précis (magistrat, usage personnel, pas un fichier public) — vu que ton père est magistrat, il a probablement un bon jugement là-dessus ou accès à un collègue juriste. Ce serait sage de lui demander confirmation avant de choisir une solution avec du cloud.

## 2. Les 3 options possibles, en langage simple

### Option A — Tout reste sur son téléphone/ordinateur (rien en ligne)
Comme un carnet fermé à clé qu'il garde toujours sur lui. Rien ne sort jamais de son appareil.
- ✅ Le plus sûr légalement, zéro risque de fuite via un tiers.
- ❌ Si le téléphone est perdu/cassé, tout est perdu (sauf sauvegarde manuelle).
- ❌ Pas d'accès facile depuis un deuxième appareil (ex : ordinateur au bureau).

### Option B — Un petit serveur personnel, hébergé au Bénin
Comme une armoire fermée à clé, mais chez lui (ou chez toi), à laquelle il peut accéder depuis son téléphone ET son ordinateur.
- ✅ Accès multi-appareils, données qui restent au Bénin (conforme à la loi).
- ⚠️ Il faut que quelqu'un (toi) maintienne ce serveur correctement sécurisé — une erreur de config = risque réel.

### Option C — Un service cloud chiffré (hébergé à l'étranger)
Comme confier l'armoire à un coffre-fort dans une banque à l'étranger, même si la banque ne peut théoriquement pas ouvrir la boîte (chiffrement).
- ✅ Simple à mettre en place, sauvegardes automatiques.
- ❌ Question légale à vérifier : transfert de données sensibles hors du Bénin. Risque réputationnel si mal choisi (un magistrat dont les dossiers fuitent, même chiffrés, c'est grave).

## 3. Recommandation prudente (à valider avec le père)

Vu que c'est un magistrat et des données "sensibles" au sens de la loi, la voie la plus prudente est **Option A pour commencer** (tout en local, zéro réseau) — ça permet de tester le mécanisme (rappels + bilan) sans aucun risque légal, pendant qu'on clarifie si Option B devient utile plus tard (accès multi-appareils).

## Prochaine étape
Demander à Tobie/son père : est-ce qu'il a besoin d'accéder à l'outil depuis PLUSIEURS appareils (téléphone + ordinateur), ou juste son téléphone lui suffit pour commencer ? Cette seule réponse tranche entre Option A et Option B.
