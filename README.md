# Vigie

Application de suivi d'échéances et de rappels, pensée pour rester **confidentielle** — pour les professions où chaque dossier compte et où la discrétion n'est pas négociable (magistrats, avocats, médecins, et plus largement toute activité indépendante).

**Vous rejoignez ce projet sans avoir participé aux échanges précédents ?** Lisez [`HANDOVER.md`](HANDOVER.md) en premier — méthode de travail, histoire du projet, installation pas à pas, architecture, état de sécurité, ce qui reste ouvert. Ce README reste volontairement court (présentation publique du projet).

Par [PENTALIGHTCODE](https://pentalightcode.com).

🔗 [vigie.pentalightcode.com](https://vigie.pentalightcode.com) · 📄 [CGU & confidentialité](https://vigie.pentalightcode.com/confidentialite/)

## Le principe

Vigie suit des échéances (audiences, rendez-vous, dates limites...) et relance jusqu'à confirmation que c'est fait. Contrairement à un agenda classique, les dossiers ne sont jamais désignés par leur vrai nom : l'utilisateur choisit lui-même un nom de code pour chacun. Aucune information réelle n'est requise pour que l'app fonctionne.

- **Suivi par noms de code** — jamais de vraies informations stockées côté dossier.
- **Rappels automatiques** avec délai configurable avant l'échéance.
- **Connexion Google optionnelle** (Gmail/Tasks/Calendar), toujours en lecture seule, jamais d'écriture ni de suppression.
- **Bilan périodique** avec résumé et recommandations IA (optionnel, désactivé par défaut).
- **Verrouillage par code/biométrie** à l'ouverture de l'app.

## Stack technique

- **App** : Flutter (Android/iOS/Web)
- **Backend** : Firebase — Auth (connexion par lien magique), Firestore, Cloud Functions (Python 3.14, 2ᵉ génération), Hosting, Cloud Messaging
- **IA** : Groq (résumé du Bilan, extraction Gmail optionnelle)

## Structure du dépôt

```
HANDOVER.md     Document de transfert — à lire en premier pour rejoindre le projet
app/            Application Flutter (lib/, android/, web/...)
app/functions/  Cloud Functions Python (scan Gmail/Calendar/Tasks, rappels, publication de version)
Notes/          Journal de décisions et recherches du projet
PROGRESS.md     Journal de bord complet du développement
```

## Développement

```bash
cd app
flutter pub get
flutter run
```

`firebase_options.dart` et `google-services.json` (identifiants client Firebase publics, pas des secrets) sont **déjà inclus dans ce dépôt** — rien à régénérer. Seuls les secrets serveur des Cloud Functions (`firebase functions:secrets:set`) ne sont pas inclus, nécessaires uniquement pour déployer/exécuter les fonctions avec leur comportement réel (connexion Google, IA Groq...). Voir [`HANDOVER.md`](HANDOVER.md) pour la procédure d'installation complète.
