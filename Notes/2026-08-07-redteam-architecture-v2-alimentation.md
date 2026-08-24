# Fiche de note — Le vrai problème de fond : qui alimente le système ?

**Date :** 2026-08-07
**Trouvé par :** Tobie. C'est la meilleure prise de la journée — un vrai problème de logique qu'on n'avait pas vu venir, malgré 3 rounds de Red Team.

---

## Le problème, reformulé simplement

Toute l'app repose sur un principe : **aujourd'hui, on doit voir ce qui se passera dans 2 semaines**, pour avoir le temps de s'y préparer. Mais pour que ça marche, il faut que les dossiers/tâches/audiences **soient déjà entrés dans l'app 2 semaines avant** qu'ils n'arrivent.

Question de Tobie : **qui fait ce travail de saisie, et quand ?** Si c'est le père qui doit y penser tout seul chaque semaine, sans que rien ne le lui rappelle... alors :
- Le jour où il oublie de saisir le nouveau "rôle" reçu du tribunal, le pipeline des 2 semaines s'assèche silencieusement.
- L'app affichera "Rien à faire" alors qu'en réalité, plein de choses arrivent — juste jamais saisies.
- **Le rappel le plus important de tous n'est pas "fais ta diligence" — c'est "as-tu pensé à nourrir le système ?"** Sans ce rappel-là, tout le reste ne sert à rien.

C'est un vrai trou de conception, pas juste un détail. Bien vu.

## Solution proposée (simple, pas chère, pas de nouveau risque de confidentialité)

Ajouter une règle au digest quotidien (le futur système de notifications) : **si aucun nouveau dossier n'a été ajouté depuis 7 jours, le rappel du jour inclut une ligne spéciale** : *"Pense à ajouter les dossiers/audiences de la semaine."*

- Techniquement simple : une seule requête ("quand a été créé le dossier le plus récent ?") en plus de ce qu'on doit déjà construire pour les notifications.
- Aucune nouvelle donnée sensible, aucun nouveau risque de confidentialité.
- Résout directement le problème : le système se rappelle lui-même de se faire nourrir.

## La proposition de Tobie : automatiser via Gmail

Tobie propose de lier la boîte Gmail du père pour détecter automatiquement les nouveaux dossiers/audiences reçus par email, plutôt que de compter sur la saisie manuelle + un rappel.

### Est-ce possible techniquement ? Oui.
- Lire une boîte Gmail via l'API Gmail de Google : technique connue, pas de souci de faisabilité en soi.
- Extraire les informations utiles (nom, date) d'un email : deux approches possibles —
  - **Analyse simple par motif** (chercher une date, un numéro de dossier dans un format toujours identique) : gratuit, mais **fragile** — si le tribunal change un jour la mise en forme de son email, ça casse.
  - **Analyse par IA** (envoyer le texte de l'email à une IA type Claude pour qu'elle en extraie les infos) : beaucoup plus robuste aux changements de format, mais a un coût d'usage (voir plus bas) et nécessite un petit service côté serveur (qu'on doit de toute façon construire pour les notifications — donc pas un coût de mise en place complètement nouveau).

### ⚠️ Le vrai problème : ça entre en conflit direct avec tout ce qu'on a construit sur la confidentialité
On a passé plusieurs rounds à s'assurer qu'**aucune vraie information sensible** (vrais noms, détails d'affaires) ne rentre jamais dans le système — seulement des noms de code choisis par le père. **Lire sa boîte mail automatiquement casse ce principe à la racine** : une boîte mail de magistrat contient potentiellement des échanges avec des avocats, des greffiers, des détails d'affaires bien plus sensibles que le simple "rôle" hebdomadaire. Un accès automatique (script ou IA) à **toute la boîte** exposerait exactement ce qu'on a voulu éviter depuis le début.

**Nuance importante :** si on limitait ça **uniquement** à l'email précis du "rôle" hebdomadaire (envoyé par une adresse connue du tribunal, avec un contenu qui ressemble à un calendrier d'audiences déjà semi-public), le risque serait beaucoup plus faible qu'un accès à toute la boîte. Mais ça reste un changement d'architecture sérieux, pas un ajustement mineur.

### Combien ça coûterait ?
- L'API Gmail elle-même : gratuite pour ce volume d'usage (une poignée d'emails par semaine, un seul utilisateur).
- Si on utilise une IA pour l'extraction : coût réel mais **minime** — de l'ordre de quelques centimes à 1-2 dollars par mois pour ce volume, pas un poste de dépense significatif.
- Le vrai coût n'est pas financier — c'est le **risque de confidentialité**, et le temps de développement (mise en place de l'accès Gmail sécurisé, vérification Google pour l'usage de l'API Gmail — j'aurais besoin de vérifier précisément les règles actuelles de Google là-dessus avant de m'engager sur un délai).

### Ma recommandation
**Ne pas trancher ça maintenant.** Le rappel "pense à ajouter tes dossiers" (solution simple ci-dessus) résout le vrai problème (le système qui s'assèche silencieusement) sans prendre de risque de confidentialité ni de temps de développement conséquent. L'automatisation Gmail reste une **vraie bonne idée à garder de côté**, à ressortir plus tard comme une évolution — à condition d'en reparler sérieusement avec ton père aussi, puisque c'est sa boîte mail professionnelle et sa responsabilité déontologique qui seraient engagées, pas juste un choix technique.
