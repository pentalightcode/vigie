# Fiche de note — Décision : boîte mail secondaire pour l'automatisation Gmail

**Date :** 2026-08-12
**Décision prise par le père de Tobie, après explication simple du fonctionnement de l'automatisation.**

---

## Ce qui a été décidé

Le père ne va **pas** connecter sa boîte mail professionnelle courante à Vigie. Il va utiliser une **adresse email secondaire dédiée** : il transfère lui-même, à la main, les emails du tribunal qu'il veut voir traités automatiquement vers cette boîte secondaire. C'est cette boîte-là, et uniquement elle, qui sera connectée à l'app.

## Pourquoi c'est une excellente idée (même si elle vient de lui, pas de nous)

Ça réduit le risque à presque rien, par construction :
- Même si un bug ou un problème de sécurité touchait un jour la connexion Gmail, ça ne toucherait qu'une boîte qui ne contient QUE ce qu'il a choisi d'y transférer — jamais l'intégralité de sa correspondance professionnelle réelle.
- Il garde un contrôle manuel total sur ce qui entre dans le système : lui seul décide quoi transférer, email par email.
- Ça évite complètement le débat sur les autorisations larges (lecture de toute une boîte pro) — l'app ne voit qu'une boîte "tampon", conçue pour ça dès le départ.

## Conséquence pour les autres utilisateurs (futurs clients payants)

Ils n'auront pas forcément la même prudence ou la même boîte secondaire disponible. Décision actée avec Tobie : pour les autres utilisateurs, on ne les oblige pas à faire pareil, mais on les **avertit clairement des risques** au moment d'activer la connexion Gmail (accès en lecture seule, contenu qui transite par le service, etc.) — charge à chacun de décider en connaissance de cause, éventuellement en suivant l'exemple du père (créer une boîte secondaire dédiée) si l'écran de consentement le suggère.

## Prochaine étape technique
- On démarre par les **notifications quotidiennes** (Cloud Functions + FCM), qui ne dépendent ni de Gmail ni de l'IA — indépendant de cette décision.
- L'automatisation Gmail viendra après, une fois : (1) le compte IA payant configuré (carte valide), (2) l'accès à la boîte secondaire du père mis en place côté Google.
