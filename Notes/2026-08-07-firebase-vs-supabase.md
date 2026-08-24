# Fiche de note — Firebase vs Supabase

**Date :** 2026-08-07
**Rappel du besoin technique clé :** le cœur de l'app, c'est la **relance quotidienne** (notification chaque jour tant que ce n'est pas confirmé). Donc le critère n°1 n'est pas "lequel est le plus joli", c'est "lequel gère le mieux les notifications push et fonctionne mal réseau".

---

## Firebase (Google)
- **FCM (Firebase Cloud Messaging)** : service de notifications push, **gratuit**, conçu justement pour ça — envoyer un rappel chaque jour sur le téléphone, même hors connexion (les messages sont mis en attente et livrés au retour du réseau). C'est exactement notre mécanisme "relance quotidienne".
- **Firestore** (la base de données) fonctionne **hors-ligne** : le téléphone garde une copie locale, et resynchronise automatiquement dès que le réseau revient — utile si le réseau au tribunal n'est pas fiable.
- Région **Europe** disponible (plutôt que USA par défaut).
- Beaucoup de tutoriels, association naturelle avec **Flutter** (une seule appli qui marche sur Android ET iPhone).
[Sources : firebase.google.com/docs/cloud-messaging, firebase.google.com/docs/firestore/manage-data/enable-offline]

## Supabase
- Base de données **Postgres** (relationnelle) — plus proche de ce que tu apprendras en cours probablement, open-source, **auto-hébergeable plus tard** si on veut un jour rapatrier les données sur un serveur au Bénin (cohérent avec ta vision long terme sécurité/souveraineté).
- ⚠️ **Piège du plan gratuit** : le projet **se met en pause après 7 jours sans activité sur la base de données**. Si personne n'interagit avec l'app pendant une semaine (vacances du père par ex.), le projet peut se figer et il faut le relancer manuellement.
- Pas de service de notifications push intégré — il faudrait quand même brancher Firebase (FCM) ou un service tiers (OneSignal) à côté, donc **deux services à gérer** au lieu d'un.
[Sources : itpathsolutions.com/supabase-free-tier-limits, supabase docs]

## Recommandation

**Firebase**, pour une raison simple : le cœur du produit, c'est la relance quotidienne fiable — et Firebase a l'outil fait exactement pour ça (FCM), gratuit, plus le mode hors-ligne. Avec Supabase, il faudrait de toute façon rajouter Firebase (ou équivalent) juste pour les notifications, donc gérer deux systèmes pour rien.

**Point à garder en tête pour plus tard** : Supabase reste une meilleure option si un jour on veut rapatrier les données sur un serveur au Bénin (auto-hébergement) pour la souveraineté des données — mais rien n'empêche de migrer plus tard si le besoin se confirme. Le chiffrement côté téléphone (décidé plus tôt) rend ce choix moins critique de toute façon, puisque le fournisseur ne voit jamais les données en clair.
