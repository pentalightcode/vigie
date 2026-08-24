# Fiche de note — Recherche ciblée (v2) après l'interview approfondie

**Date :** 2026-08-06
**Contexte :** après la vraie interview du père, le besoin est beaucoup plus précis. On revérifie s'il existe déjà une solution (comme demandé par Tobie, "avant de se jeter à l'eau").

---

## 1. Ce qu'on a compris précisément de l'interview

Ce n'est PAS un logiciel de gestion de dossiers (classement, archivage). C'est un **moteur de rappels intelligents** avec 3 mécanismes précis :

1. **Anticipation à 2 semaines** : à partir des infos qu'il remplit (dossier → date d'audience), le système doit faire remonter automatiquement, 2 semaines avant l'échéance, les diligences/écritures à préparer. Chaque semaine qui passe, ça se resserre (S-2, S-1, jour J).
2. **Boucle de relance ("garde-fou")** : chaque rappel doit être **confirmé** par lui ("c'est bon" = fait). Tant qu'il n'a pas confirmé, l'assistant **le relance chaque jour** (correction du 2026-08-07 : pas chaque semaine, chaque jour) — pas une seule notification passive comme Google Agenda aujourd'hui.
3. **Bilan hebdomadaire automatique** : à la fin de la semaine, le système liste ce qui a été fait vs ce qui reste — et ce qui reste est reporté à la semaine suivante.

Il compare lui-même ça à "un Google Agenda plus actif, un vrai assistant" — pas un simple calendrier passif.
Le classement/rangement physique des dossiers n'est **pas** demandé.

## 2. Ce qui existe déjà (recherche ciblée)

### a) Logiciels juridiques avec "calendrier basé sur des règles" (rules-based calendaring)
**Clio, PracticePanther, Filevine, CARET Legal, MyCase** proposent exactement le mécanisme n°1 : tu entres une date déclenchante (date d'audience), le logiciel calcule automatiquement toutes les échéances en amont (ex : 30 jours, 7 jours, 1 jour avant), et **recalcule tout si la date change** — ce qui correspond exactement à "le rôle qui change, je dois modifier". Des moteurs de règles dédiés existent même (LawToolBox, Aderant CompuLaw) couvrant des milliers de juridictions (mais US/Occident, pas adaptées au Bénin).
[Sources : clio.com/blog/rules-based-calendaring-software-law-firms, mycase.com/blog/legal-case-management/court-calendaring-software]

**Limite :** conçu pour des cabinets d'avocats facturant des clients, hébergement à l'étranger (souci de confidentialité déjà identifié), aucune notion de "relance jusqu'à confirmation" ni de "bilan hebdo".

### b) Apps de rappels "insistants" avec confirmation obligatoire
**NagMe, Againly, Nag, Until Done, Todof** : exactement le mécanisme n°2 — elles **relancent sans arrêt tant que la tâche n'est pas marquée faite**, certaines (Todof) s'adaptent même et deviennent "plus insistantes" si on retarde.
[Sources : startnagging.me, apps.apple.com/until-done, apps.apple.com/todof]

**Limite :** ce sont des apps de productivité personnelle générique (pas de notion de "dossier", "audience", "diligence"), et aucune confidentialité pensée pour des données judiciaires.

### c) Bilan hebdomadaire avec report des tâches non faites
**Sunsama** fait exactement le mécanisme n°3 : review guidée en fin de journée/semaine, les tâches non terminées sont automatiquement proposées au report, bilan hebdomadaire structuré.
[Source : sunsama.com/features/guided-planning-and-reviews]

**Limite :** même chose — outil généraliste, pas de vocabulaire juridique, pas de garantie de confidentialité stricte, abonnement mensuel occidental.

## 3. Conclusion

**Chacun des 3 mécanismes qu'il demande existe déjà séparément**, dans des outils différents :
- Mécanisme 1 (échéances légales en cascade) → outils juridiques US (Clio...)
- Mécanisme 2 (relance jusqu'à confirmation) → apps de nagging (NagMe, Todof...)
- Mécanisme 3 (bilan hebdo + report) → Sunsama

**Mais aucun outil ne combine les 3 en même temps**, et surtout aucun ne le fait :
- dans le contexte judiciaire précis (dossiers, audiences, diligences, "rôle" hebdomadaire),
- avec les garanties de confidentialité qu'exige la fonction de magistrat,
- adapté à la réalité béninoise (pas de solution locale identifiée).

→ **Il n'existe pas de solution toute faite pour ce cas précis.** Ce n'est donc pas réinventer la roue : c'est assembler un mécanisme précis (3 briques déjà validées ailleurs) dans un outil simple, confidentiel, et pensé pour son métier. Bonne nouvelle : comme le besoin est maintenant très précis, ce n'est **pas** un projet énorme — pas besoin de construire un "logiciel de gestion de tribunal" complet, juste ce moteur de rappels + bilan.

## 4. Ce qu'il reste à trancher avec Tobie (ne pas décider seul)
- Est-ce qu'on part sur une petite app sur-mesure, ou est-ce qu'on teste d'abord le mécanisme avec des outils existants bricolés ensemble (ex : Google Sheets + rappels programmés) avant de coder quoi que ce soit ?
- Où les données doivent-elles vivre (téléphone du père uniquement / petit serveur perso / cloud chiffré) ?
