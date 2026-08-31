# Fiche de note — Red Team : comment Vigie peut servir le travail de groupe

**Date :** 2026-08-29
**Déclencheur :** son père délègue le remplissage de son agenda à un collaborateur — Tobie veut que Vigie couvre TOUS les usages de groupe possibles, pas juste ce cas précis, et sur **toutes les professions que Vigie supporte**, pas seulement le droit.

---

## ⚠️ Piège dans lequel on est tombé une fois pendant cette réflexion, à ne jamais refaire

Vigie n'est **pas** une app pour juristes — `lib/models/profession.dart` liste déjà 12 métiers supportés dès l'inscription (médecin, enseignant, avocat/juriste, magistrat, comptable, consultant, commercial, architecte/ingénieur, agent immobilier, artisan du bâtiment, beauté/bien-être, entrepreneur), avec un commentaire dans le code qui dit explicitement : *"l'app ne doit pas sembler réservée aux juristes"* — une correction déjà faite une fois avant cette session. En listant les angles de collaboration ci-dessous, la première version de cette fiche s'est réenfermée dans du vocabulaire 100% juridique (audience, greffier, confrère, procureur) — corrigé après remarque de Tobie. **Toujours vérifier qu'un exemple donné se transpose à au moins 2-3 métiers différents avant de le considérer solide.**

## Pourquoi cette fiche

Avant de coder quoi que ce soit, on a listé tous les angles sous lesquels Vigie pourrait servir plusieurs personnes travaillant ensemble — pour ne pas construire une seule fonctionnalité étroite puis devoir tout refaire quand un autre cas de figure arrive.

## Les angles trouvés

### Angle 1 — Principal + délégué (le cas validé, réel, aujourd'hui)
Une seule personne responsable, un collaborateur qui exécute en son nom. Autorité hiérarchique claire. Ex : médecin + secrétaire médicale qui gère les rappels de suivi patient ; architecte + assistant qui suit les échéances de permis ; comptable + collaborateur qui saisit les échéances fiscales des clients.

### Angle 2 — Structure avec plusieurs pairs
Plusieurs professionnels de rang égal (associés), des juniors, des dossiers qui n'impliquent pas tout le monde. Aucun n'est seul décideur. Ex : cabinet comptable à plusieurs experts-comptables associés ; cabinet médical de groupe.

### Angle 3 — Un délégué pour plusieurs principaux
Un même assistant sert plusieurs professionnels, pas un seul. **Encore plus fréquent en médecine qu'ailleurs** : une secrétaire médicale gérant l'agenda de plusieurs médecins dans une même clinique.

### Angle 4 — Co-titulaires égaux
Deux professionnels de rang égal sur le même dossier, aucun n'est "responsable principal". Ex : deux médecins co-traitants d'un patient complexe ; deux architectes associés sur un même projet. Vraie copropriété — aucun ne devrait pouvoir supprimer unilatéralement.

### Angle 5 — Partage ponctuel, sans compte lié
Partager UN dossier précis avec un expert externe, sans lui donner accès à tout le reste du compte.

### Angle 6 — La vraie valeur ajoutée du travail de groupe (au-delà des permissions)
- Continuité : un collaborateur part, un autre reprend sans rien perdre.
- Redevabilité : savoir qui a fait quoi (champ "auteur" nécessaire sur chaque donnée).
- Le Bilan devient un outil de supervision d'équipe ("combien de tâches traitées par qui") — argument de vente naturel pour un futur palier payant collectif.

### Angle 7 — Supervision sans délégation
Un senior qui veut *surveiller* le travail d'un junior (formation, contrôle qualité) sans faire le travail à sa place — accès lecture seule. Ex : médecin senior supervisant un interne. Différent de l'Angle 1 où le délégué agit POUR le principal.

### Angle 8 — Suppléance temporaire
Un collègue reprend TOUT le travail pendant une absence (congé, maladie), pour une durée limitée, puis le titulaire reprend la main. Doit expirer automatiquement. **Pratique standard et courante en médecine** ("médecin remplaçant"), pas juste un cas juridique exotique.

### Angle 9 — Collaboration entre structures différentes
Deux professionnels de structures DIFFÉRENTES (cabinets/cliniques distincts) partageant un accès limité — frontière de confiance différente d'un collègue de la même structure. Implique une vraie notion "d'organisation" qui n'existe pas du tout dans Vigie aujourd'hui. **Le plus gros chantier de tous les angles.**

### Angle 10 — Accès d'urgence
Le titulaire du compte est injoignable (accident, maladie grave) et quelqu'un doit accéder en urgence pour ne pas rater une échéance critique. Sensible — question de gouvernance autant que technique.

### Angle 11 — Transparence côté client (externe, pas un collaborateur)
La personne concernée par le dossier (patient, client) qui veut juste voir "où ça en est" — pas un accès de travail, un lien de suivi en lecture seule, limité à SON dossier, sans forcément avoir de compte Vigie. Ex : patient voulant voir son prochain rendez-vous de suivi ; client d'un expert-comptable voulant voir sa prochaine échéance fiscale.

### Angle 12 — Transmission séquentielle entre rôles différents
Un dossier qui passe par plusieurs mains à des moments différents (pas une collaboration simultanée, une vraie passation dans le temps, potentiellement entre structures différentes). Complexe, probablement lointain.

### Angle 13 — Annonces d'équipe
Une note visible par toute l'équipe, pas liée à un dossier précis. Différent structurellement — plus proche d'un panneau d'affichage que du suivi de dossier. Risque de faire dériver Vigie vers autre chose que son cœur de métier.

### Angle 14 — Délégation avec validation (déjà à moitié construit !)
Entre "délégué complet" et "supervision lecture seule" : le collaborateur PROPOSE, le principal VALIDE avant que ça devienne officiel. **Le mécanisme existe déjà** — c'est exactement comment fonctionnent les "Propositions" pour les détections automatiques par email. Réutilisable pour un collaborateur junior dont les ajouts doivent être validés, plutôt que d'inventer un nouveau système.

### Angle 15 — Comparaison institutionnelle anonymisée
Des statistiques agrégées entre plusieurs professionnels d'une même structure, sans exposer les dossiers individuels — plus un angle "produit analytique" que "collaboration" au sens strict, mais reste "utile au travail de groupe" au sens large.

### Angle 16 — Tension de fond à garder en tête (pas une fonctionnalité à construire)
Détecter si un même client/patient apparaît chez plusieurs collaborateurs d'une même structure (doublon, conflit d'intérêt) nécessiterait de relier des dossiers à de vraies informations identifiantes — ce qui **contredit directement** le principe fondateur "aucune vraie info, juste des noms de code". Le travail de groupe à l'échelle d'une structure demande parfois exactement ce que la confidentialité individuelle a été conçue pour éviter.

### Angle 17 — Équipe multi-métiers sur un même dossier
Certains dossiers impliquent nativement plusieurs métiers différents en même temps — un projet de construction où l'architecte, l'ingénieur ET le notaire ont chacun besoin de voir des échéances partagées (permis, inspections, signature). Pas "une équipe de collègues du même métier", une vraie collaboration inter-métiers sur UNE même affaire.

### Angle 18 — Accès familial/non-institutionnel
Un indépendant (artisan, agent immobilier) qui veut que son conjoint ait accès "au cas où", sans lien employeur-employé formel. Proche de l'Angle 10 (urgence) mais différent : un arrangement PLANIFIÉ et durable, pas une urgence ponctuelle.

### Angle 19 — Mode formation/intégration
Un nouveau junior qui a besoin de voir COMMENT la pratique fonctionne — accès à des dossiers CLOS/anciens comme matériel d'apprentissage, sans être un collaborateur actif sur les dossiers en cours. Usage de la donnée passée, pas collaboration en temps réel.

### Angle 20 — Garde tournante (permanence)
Très présent en médecine : un roulement où une seule personne parmi plusieurs est "active" à un instant donné, l'accès doit suivre automatiquement qui est de garde. Différent de la suppléance (Angle 8, dates fixées manuellement) : un vrai planning tournant, automatique.

### Angle 21 — Attribution de tâches précises dans un dossier partagé
Dans un même dossier partagé, certaines tâches sont la responsabilité d'une personne précise, d'autres d'une autre — pas "tout le monde voit tout pareil".

### Angle 22 — Vue unifiée pour un délégué au service de plusieurs principaux
Si un assistant sert plusieurs professionnels (Angle 3), veut-il une seule liste "à traiter" combinant tout, ou doit-il basculer d'un espace à l'autre ? Sans réponse à ça, quelqu'un qui sert 3 personnes se retrouve avec 3 apps à vérifier séparément.

### Angle 23 — Consentement du tiers concerné (patient/client)
Dans certains métiers (surtout la médecine), partager le dossier d'un patient avec un deuxième soignant peut légalement nécessiter **le consentement du patient lui-même**, pas juste une décision entre professionnels. Différent de tout le reste : pas "qui a accès en interne", mais "faut-il la permission de la personne concernée avant même de partager". Contrainte réglementaire, probablement variable par métier et par pays.

### Angle 24 — Ce qui reste après le départ d'un collaborateur
Au-delà de retirer l'accès, qu'est-ce qui arrive au travail déjà fait ? Un collaborateur qui part voudrait peut-être garder une trace de sa propre contribution (utile pour son parcours professionnel) — question de portabilité individuelle, pas juste de révocation d'accès.

### Angle 25 — Discussion ponctuelle sur une tâche précise
Le journal documente l'avancement global d'un dossier ; est-ce qu'il faut aussi un espace pour une question rapide entre deux personnes sur UNE tâche précise ("j'ai un doute sur cette échéance, tu confirmes ?") — besoin de communication, différent d'une trace d'avancement.

### Angle 26 — Le seuil de taille change tout
Gérer 2-3 collaborateurs depuis un écran Profil sur téléphone, ça passe. Gérer une vraie structure de 20 personnes, probablement pas — ça demanderait une console d'administration différente (web, imports en masse). À quelle taille Vigie a-t-il besoin d'une interface de gestion d'équipe complètement différente ?

### Angle 27 — Rupture de confiance entre collaborateurs
Si le principal et le collaborateur se séparent en mauvais termes, qui a le droit de garder une copie des données du dossier partagé une fois séparés ? Question de gouvernance/juridique plus que technique, mais réelle vu le sujet (confidentialité).

### Angle 28 — Pièces jointes / partage de fichiers (rouvre une décision volontaire du MVP)
Quand plusieurs personnes travaillent sur un même dossier, il y a presque toujours des fichiers à partager (contrat scanné, radio, plan). `Notes/2026-08-07-mvp-scope.md` excluait ça volontairement du MVP, sans raison documentée au-delà de "garder le MVP simple". **Vraie tension** : un fichier réel contient presque toujours de vraies informations identifiantes — à l'opposé du principe "aucune vraie info, juste des noms de code".

**Décision prise après discussion** : Vigie héberge les fichiers lui-même (pas juste des liens externes type Google Drive) — testé et écarté l'option "lien Google Drive" car le premier vrai utilisateur (le père de Tobie) n'a pas la maîtrise technique pour ça (exemple concret du jour : ne savait pas faire un copier-coller de PDF). L'ajout doit passer par deux réflexes déjà connus : **bouton "Prendre une photo"** directement dans l'écran du dossier, et **Vigie apparaît dans le menu "Partager" natif du téléphone** (comme WhatsApp). Mêmes standards de sécurité que le reste de l'app (chiffré, protégé par le système de permissions collaborateur), pas une zone moins protégée.

**Décision de Tobie, non négociable** : comme l'hébergement de fichiers a un coût réel (stockage), cette fonctionnalité **doit être payante** — se branche directement sur la grille tarifaire déjà esquissée.

### Angle 29 — Historique des versions d'un fichier partagé
Si plusieurs personnes peuvent remplacer/mettre à jour un même fichier, faut-il garder les anciennes versions (qui a uploadé quoi, retour en arrière possible) ?

### Angle 30 — Quota de stockage par palier
Se branche directement sur la grille tarifaire : un quota par palier (rien ou très peu en gratuit, X Mo en payant).

### Angle 31 — Sécurité des fichiers uploadés
Nouvelle surface de risque jamais couverte par l'audit de sécurité (qui n'avait rien à couvrir, Firebase Storage n'était pas utilisé) : types de fichiers autorisés, taille maximale, éventuel scan antivirus.

### Angle 32 — Qui peut supprimer une pièce jointe
Même question de gouvernance que la suppression d'un dossier (Angles 2/4) — probablement à trancher de la même façon plus tard.

### Angle 33 — Nettoyage à la suppression
`supprimer_compte_definitivement` (fonction déjà construite le 2026-08-29) ne gère pas encore de fichiers. Si les pièces jointes arrivent, il faudra l'étendre pour ne pas laisser de fichiers orphelins dans Firebase Storage.

### Angle 34 — Compression automatique des photos
Directement lié au souci de coût de Tobie : une photo de téléphone peut faire plusieurs Mo ; sans compression automatique à l'envoi, les coûts grimpent pour rien (un document papier photographié n'a pas besoin d'une résolution énorme pour rester lisible).

### Angle 35 — Consultation hors-ligne
Un professionnel dans un lieu sans réseau peut-il revoir une pièce jointe déjà consultée récemment, ou faut-il obligatoirement une connexion à chaque fois ?

### Angle 36 — Preuve d'authenticité / horodatage inviolable
En contexte judiciaire ou médical, un document peut devoir prouver qu'il n'a pas été modifié après coup. Un simple fichier uploadé ne garantit pas ça — pourrait nécessiter une empreinte cryptographique du fichier au moment de l'ajout.

### Angle 37 — Web vs mobile, pas la même expérience possible
Prendre une photo ou utiliser le menu "Partager" du téléphone n'existe pas pareil dans un navigateur — il faudra une façon différente d'ajouter un fichier sur le site (un "choisir un fichier" classique).

### Angle 38 — Notification à l'ajout d'un document
Se branche sur le système de notifications déjà en place — à doser pour ne pas noyer l'utilisateur.

### Angle 39 — Au-delà de l'écrit : dicter plutôt que taper
Même constat que le copier-coller PDF du père de Tobie : quelqu'un peu à l'aise avec l'écrit pourrait préférer dicter une entrée de journal à l'oral plutôt que la taper.

### Angle 40 — Flouter avant de partager
Pouvoir cacher une partie d'une photo avant de l'ajouter (un nom qui apparaît par erreur dans le cadre) — cohérent avec toute la philosophie confidentialité de l'app, directement utile vu l'Angle 28.

### Angle 41 — Suivi qui ne se referme jamais, autour d'une personne (pas d'une affaire)
Un enseignant, un conseiller d'orientation, la direction d'un établissement suivent collectivement UN élève sur toute une année scolaire. Le "dossier" ne se termine pas comme une affaire classée — il continue en continu, et les intervenants changent chaque année (nouveau prof en septembre). Structurellement différent : pas de fin, un roulement de personnes prévisible et récurrent.

### Angle 42 — Transfert en masse d'un portefeuille entier
Un commercial qui change de poste doit transférer TOUS ses dossiers clients d'un coup à quelqu'un d'autre — pas un dossier à la fois comme la suppléance (Angle 8), un vrai transfert en bloc, définitif, sur un gros volume.

### Angle 43 — Le client comme coordinateur, pas le professionnel
Sur un chantier avec plusieurs corps de métier indépendants (électricien, plombier, maçon), c'est parfois le CLIENT (propriétaire) qui coordonne plusieurs pros indépendants, chacun ne voyant que sa portion — inversion complète du modèle vu jusqu'ici, où c'est toujours le professionnel qui invite.

### Angle 44 — Accès accueil/réception, encore plus restreint que la supervision
Dans un salon avec plusieurs praticiens indépendants, un poste d'accueil doit voir les CRÉNEAUX de rendez-vous de tout le monde pour prendre des réservations, sans jamais voir le contenu des dossiers clients. Accès à une seule donnée précise (la disponibilité), encore plus limité que la lecture seule complète (Angle 7).

### Angle 45 — Tuteur légal/parent, un troisième type de partie prenante
Quand le "client" est mineur (élève chez un enseignant), le parent a souvent un droit de regard légal distinct — ni professionnel, ni collaborateur. Un accès avec ses propres règles, souvent imposées par la loi.

### Angle 46 — Contrôle externe ponctuel
Un ordre professionnel ou une assurance qui doit vérifier la conformité d'une pratique — un accès en lecture, très limité dans le temps, donné à quelqu'un d'extérieur à l'équipe habituelle.

### Angle 47 — Rachat/fusion d'une structure entière
Quand un cabinet, une agence ou un salon est vendu ou fusionné, TOUS les dossiers actifs de TOUTE la structure basculent d'un coup vers une nouvelle organisation — encore plus gros que le transfert de portefeuille d'une seule personne (Angle 42).

### Angle 48 — Désaccord entre collaborateurs
Deux personnes qui ne sont pas d'accord sur comment catégoriser un dossier — un besoin de trancher un désaccord, pas juste une question de qui a accès à quoi.

## L'insight structurant : ne pas construire 48 fonctionnalités séparées

Ces angles se décomposent en un petit nombre de **dimensions combinables** plutôt qu'en cas particuliers à coder un par un :

| Dimension | Valeurs possibles |
|---|---|
| **Périmètre** | Tout le compte, ou un seul dossier précis |
| **Niveau d'accès** | Lecture seule / Peut modifier / Administrateur (gère qui a accès, peut supprimer) |
| **Durée** | Permanent, ou expire à une date donnée |
| **Multiplicité** | Un collaborateur lié à un seul principal, ou à plusieurs |

En construisant l'architecture autour de ces 4 briques plutôt que des angles nommés, les cas 1, 2, 3, 4, 7, 8 sortent naturellement de leur combinaison — pas besoin de systèmes séparés pour chacun.

**Mis explicitement à part, PAS couvert par ces 4 briques** (nécessitent soit un vrai mécanisme technique séparé, soit une décision de politique d'usage — pas juste une combinaison des briques) :
- **Angle 9/12 (structures différentes)** : implique une vraie notion d'"organisation"/tenant. Chantier technique séparé.
- **Angle 10 (accès d'urgence)** : question de gouvernance autant que technique.
- **Angle 11 (transparence client)** : nécessite un accès SANS compte Vigie (lien public scopé), mécanisme différent de tout le reste.
- **Angle 13 (annonces d'équipe)** : hors du cœur de métier "suivi de dossier", à évaluer si vraiment souhaité.
- **Angle 16** : tension de fond entre confidentialité individuelle et besoin institutionnel, pas une brique technique.
- **Angle 17 (multi-métiers)** : un dossier partagé entre des professions différentes — testerait si "profession" doit rester un attribut du compte ou pourrait varier par dossier/participant.
- **Angle 19 (formation)** : accès à des dossiers CLOS pour apprentissage — différent d'un accès à des dossiers actifs, presque un mode de lecture séparé.
- **Angle 20 (garde tournante)** : accès qui change automatiquement selon un planning, pas une date de début/fin fixe — brique "durée" à enrichir, pas juste "permanent ou expire".
- **Angle 22 (vue unifiée multi-principaux)** : question d'expérience utilisateur (comment afficher plusieurs espaces à la fois), pas de permission.
- **Angle 23 (consentement du tiers)** : contrainte réglementaire externe, propre à certains métiers — à traiter comme politique d'usage documentée, pas un verrou technique que Vigie peut faire respecter tout seul.
- **Angle 24 (portabilité après départ)**, **Angle 26 (seuil de taille)**, **Angle 27 (rupture de confiance)**, **Angle 42/47 (transfert/fusion en masse)**, **Angle 46 (contrôle externe)** : questions de gouvernance/produit à trancher plus tard, pas de mécanisme à construire maintenant.
- **Angle 28-40 (pièces jointes)** : chantier séparé entier, avec sa propre décision actée (Vigie héberge, paie sa propre place dans la grille tarifaire) — voir détail à l'Angle 28. Ne fait pas partie des 4 briques d'accès, c'est un nouveau TYPE de donnée, pas une question de permission.
- **Angle 41 (suivi continu autour d'une personne)** : remet en question l'idée qu'un "dossier" a toujours un début et une fin — à vérifier si le modèle de données actuel (dossier → tâches) suffit pour un suivi qui dure des années avec des intervenants qui tournent.
- **Angle 43 (client comme coordinateur)** : inversion du sens habituel de l'invitation (le client invite des pros, pas l'inverse) — hors du modèle "principal délègue à un collaborateur" vu partout ailleurs.
- **Angle 44 (accès accueil/réception)** : accès à UNE SEULE information (disponibilité), pas au dossier — un 5ᵉ niveau d'accès à ajouter à la brique "Niveau d'accès" (plus restreint que "lecture seule").
- **Angle 45 (tuteur légal)** : nouveau type de partie prenante externe, avec des règles imposées par la loi plutôt que par Vigie.
- **Angle 48 (désaccord)** : pas un problème de permission, un besoin de résolution de conflit.

## Autres trous déjà identifiés pendant cette réflexion, à ne pas oublier au moment de construire

- Champ "auteur" distinct du champ "propriétaire" nécessaire sur dossiers/tâches/journal — sans ça, impossible de savoir qui a fait quoi une fois plusieurs personnes actives sur les mêmes données.
- Champ "assigné à" (Angle 21) — distinct du champ "auteur" : qui a écrit une tâche vs. qui en est responsable ne sont pas forcément la même personne.
- Journal privé par personne, jamais visible par personne d'autre (même pas son existence) — vraie exception à "l'accès complet" du principal, la vie privée individuelle n'est pas la même chose que l'accès aux dossiers de travail.
- Notifications : aujourd'hui seul le propriétaire du dossier reçoit les rappels — il faut étendre l'envoi aux collaborateurs autorisés.
- Angle 14 : le système de "Propositions" existant peut être réutilisé pour la délégation-avec-validation plutôt que d'inventer un nouveau mécanisme.
- Angle 25 (discussion sur une tâche) : besoin de communication distinct du journal (trace d'avancement) — à garder en tête comme fonctionnalité potentielle séparée, pas à fusionner avec le journal existant.
- Angle 33 : `supprimer_compte_definitivement` (déjà construite) ne gère pas encore de fichiers — à étendre si les pièces jointes arrivent.
- Angle 34 : compression automatique des photos à l'envoi — sinon les coûts de stockage (déjà décidé payant) grimpent inutilement.

## Deux questions structurelles tranchées par Tobie

**Un dossier n'a pas toujours de fin.** Confirme l'Angle 41 : pas de cycle de vie forcé "ouvert → fermé" à imposer. Implication concrète : la liste des personnes ayant accès à UN dossier doit pouvoir changer dans le temps, indépendamment du dossier lui-même (l'enseignant de septembre n'est plus le même que celui de l'an dernier, le dossier continue). Renforce le besoin d'un partage **par dossier**, pas seulement par compte entier (déjà noté dans la brique "Périmètre").

**La profession peut varier par dossier/participant, pas juste par compte.** Confirme l'Angle 17. Aujourd'hui, `Profession` est un attribut fixe du compte (`utilisateurs/{uid}.profession`), qui détermine les "natures de dossier" proposées (`_naturesParProfession` dans `profession.dart`). Si un dossier partagé implique des participants de métiers différents (l'architecte ET le notaire sur le même projet), la liste de "natures" ne peut plus dépendre d'une seule profession fixée au niveau du dossier — chaque participant garde sa propre profession (déjà le cas), mais le dossier lui-même doit rester profession-agnostique ou proposer l'union des natures pertinentes selon qui y participe.

## Relecture des angles déjà trouvés, à la lumière des deux décisions ci-dessus

- **Angle 21 (assignation)** : si un dossier ne se ferme jamais et que les participants tournent (Angle 41), que devient une tâche assignée à quelqu'un qui a quitté le dossier depuis ? Bloquer son retrait tant qu'il a des tâches ouvertes, ou les rendre automatiquement "non assignées" ?
- **Angle 15 (bilan/stats)** : le graphique "par nature" est aujourd'hui pensé pour une seule profession. Avec des participants de métiers différents sur un même dossier, la nature n'est plus liée à un seul métier — le Bilan doit être repensé en conséquence.
- **Angle 3 (un délégué pour plusieurs principaux)** : avec un partage par DOSSIER plutôt que par compte entier, quelqu'un peut avoir accès à certains dossiers de A et certains de B, jamais "tout A + tout B" proprement. Rend la vue unifiée (Angle 22) encore plus nécessaire ET plus complexe à construire.
- **Angle 14 (Propositions réutilisées)** : pensé à l'origine pour des imports ponctuels (un email arrive, une proposition se crée) — avec des dossiers perpétuels et une collaboration continue sur des années, doit tenir dans la durée, pas juste absorber un pic d'usage initial.

### Nouveaux angles trouvés en creusant plus loin

**Angle 49 — Historique des changements de rôle.** Si quelqu'un passe de simple collaborateur à administrateur (ou l'inverse), faut-il tracer CE changement lui-même — qui a promu qui, quand ? Un audit sur les permissions elles-mêmes, pas juste sur les données du dossier.

**Angle 50 — Dossiers oubliés mais jamais fermés.** Avec des dossiers perpétuels par défaut, comment repérer ceux réellement abandonnés depuis des années (élève parti, client perdu) sans mécanisme de fermeture explicite ? Un signal d'inactivité plutôt qu'un état binaire ouvert/fermé.

**Angle 51 — Un participant d'un autre métier rejoint un dossier déjà en cours.** Suite à la décision "profession par dossier" : que se passe-t-il pour un dossier existant quand quelqu'un d'un métier différent le rejoint — ses natures à lui s'ajoutent-elles rétroactivement aux choix disponibles sur ce dossier précis ?

**Angle 52 — "Mes dossiers" vs "dossiers où je participe seulement".** Avec le partage par dossier, faut-il distinguer visuellement dans la liste principale ceux qu'on a créés de ceux où on est juste invité ?

**Angle 53 — Charge cognitive à long terme.** Un délégué au service de plusieurs principaux, avec des dossiers qui ne se ferment jamais, accumule une liste énorme avec le temps. Faut-il un archivage manuel ("je ne veux plus le voir dans ma liste active" sans perdre l'accès), distinct d'une vraie fermeture de dossier ?

## Statut — où on en est après 53 angles

**Ce qui ressort clairement, avec le recul :**
1. **Deux chantiers distincts, pas un seul** : (a) le système de permissions/rôles pour partager un compte ou un dossier (couvre la majorité des angles, se résume aux 4 briques), et (b) les pièces jointes (Angle 28), un vrai nouveau type de donnée avec ses propres questions de coût/sécurité/UX, indépendant du système de permissions.
2. **La majorité des angles récents (36+) sont soit des raffinements des mêmes briques, soit des questions de gouvernance/politique que Vigie ne peut pas résoudre tout seul par du code** (Angles 42, 45, 46, 47, 48) — signe réel qu'on approche du bout du tour.
3. **Deux vraies remises en question structurelles** émergent malgré tout et méritent d'être tranchées avant de coder : l'Angle 41 (un dossier a-t-il toujours une fin ?) et l'Angle 17 (la profession est-elle un attribut du compte ou du dossier ?).

48 angles couverts, sur toutes les professions supportées par Vigie. En attente de la décision de Tobie : continuer à creuser, ou passer à la conception technique des briques identifiées.
