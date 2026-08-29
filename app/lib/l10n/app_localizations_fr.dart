// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navATraiter => 'À traiter';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navBilan => 'Bilan';

  @override
  String get navProfil => 'Profil';

  @override
  String get professionMedecin => 'Médecin / Professionnel de santé';

  @override
  String get professionEnseignant => 'Enseignant / Professeur';

  @override
  String get professionAvocatJuriste => 'Avocat / Juriste';

  @override
  String get professionMagistrat => 'Magistrat';

  @override
  String get professionComptable => 'Comptable / Expert-comptable';

  @override
  String get professionConsultant => 'Consultant / Indépendant';

  @override
  String get professionCommercial => 'Commercial / Chargé de clientèle';

  @override
  String get professionArchitecteIngenieur => 'Architecte / Ingénieur';

  @override
  String get professionAgentImmobilier => 'Agent immobilier';

  @override
  String get professionArtisanBatiment => 'Artisan / Entrepreneur du bâtiment';

  @override
  String get professionBeauteBienEtre => 'Coiffeur / Esthéticienne / Bien-être';

  @override
  String get professionEntrepreneur => 'Entrepreneur / Chef d\'entreprise';

  @override
  String get professionAutre => 'Autre';

  @override
  String joursAvant(int jours) {
    return '$jours jours avant';
  }

  @override
  String get profilPreciseProfessionLabel => 'Précise ta profession';

  @override
  String get onboardingBienvenue => 'Bienvenue !';

  @override
  String get onboardingSousTitre =>
      'Quelques infos pour personnaliser ton assistant.';

  @override
  String get onboardingChampPrenom => 'Prénom';

  @override
  String get onboardingChampPseudo => 'Pseudo (comment l\'app t\'appelle)';

  @override
  String get onboardingChampProfession => 'Ta profession';

  @override
  String get onboardingNoteNaturesPreremplies =>
      'On pré-remplira des types de dossier adaptés à ton métier — modifiables ensuite.';

  @override
  String get onboardingChampDelaiRappel =>
      'Être prévenu combien de jours à l\'avance ?';

  @override
  String get onboardingBoutonCommencer => 'Commencer';

  @override
  String get onboardingErreurPrenomPseudo =>
      'Renseigne au moins ton prénom et un pseudo.';

  @override
  String get onboardingErreurProfession => 'Précise le nom de ta profession.';

  @override
  String get onboardingErreurConnexion =>
      'Impossible d\'enregistrer. Vérifie ta connexion.';

  @override
  String get commonAnnuler => 'Annuler';

  @override
  String get commonContinuer => 'Continuer';

  @override
  String get commonEnregistrer => 'Enregistrer';

  @override
  String get profilTitre => 'Profil';

  @override
  String get profilPourquoiVigieTitre => 'Pourquoi Vigie ?';

  @override
  String get profilPourquoiVigieSousTitre => 'Ce qui rend Vigie différent';

  @override
  String profilConnecteEnTantQue(String email) {
    return 'Connecté en tant que $email';
  }

  @override
  String get profilEmailInconnu => 'inconnu';

  @override
  String get profilPseudoNonDefini => 'Pseudo non défini';

  @override
  String get profilProfessionNonDefinie => 'Profession non définie';

  @override
  String get profilDelaiRappelTitre => 'Délai de rappel';

  @override
  String profilDelaiRappelSousTitre(int jours) {
    return '$jours jours avant l\'échéance';
  }

  @override
  String get profilTypesDossierTitre => 'Mes types de dossier';

  @override
  String get profilTypesDossierSousTitre =>
      'Ajouter ou supprimer tes catégories personnalisées';

  @override
  String get profilThemeTitre => 'Thème';

  @override
  String get profilThemeSousTitre => 'Couleur et mode clair/sombre';

  @override
  String get profilLangueTitre => 'Langue';

  @override
  String get profilLangueSousTitre => 'Français / English';

  @override
  String get profilThemeCouleurLabel => 'Couleur';

  @override
  String get profilThemeModeLabel => 'Mode';

  @override
  String get profilThemeModeSysteme => 'Système';

  @override
  String get profilThemeModeClair => 'Clair';

  @override
  String get profilThemeModeSombre => 'Sombre';

  @override
  String get couleurIndigo => 'Indigo';

  @override
  String get couleurBleu => 'Bleu';

  @override
  String get couleurSarcelle => 'Sarcelle';

  @override
  String get couleurVert => 'Vert';

  @override
  String get couleurViolet => 'Violet';

  @override
  String get couleurOrange => 'Orange';

  @override
  String get profilAutomatisationTitre => 'Automatisation';

  @override
  String get profilAutomatisationAucunCompte =>
      'Connecter un compte Google pour détecter les dates automatiquement';

  @override
  String get profilAutomatisationUnCompte => '1 compte Google connecté';

  @override
  String get profilAutomatisationDeuxComptes => '2 comptes Google connectés';

  @override
  String get profilSeDeconnecterTitre => 'Se déconnecter';

  @override
  String get profilSupprimerCompteTitre => 'Supprimer mon compte';

  @override
  String get profilSeDeconnecterConfirmationTitre => 'Se déconnecter ?';

  @override
  String get profilSeDeconnecterConfirmationMessage =>
      'Tu devras te reconnecter par email pour rouvrir l\'app.';

  @override
  String get profilSupprimerCompteMessage1 =>
      'Tous tes dossiers et toutes tes tâches seront supprimés définitivement. Il n\'y a aucun moyen de les récupérer ensuite.';

  @override
  String get profilSupprimerCompteMessage2 =>
      'Ton compte de connexion sera lui aussi supprimé — tu ne pourras plus te reconnecter avec cet email sans recréer un compte, vide, à zéro.';

  @override
  String get profilSupprimerCompteMessage3 =>
      'Dernière alerte : cette action est irréversible et immédiate. Es-tu vraiment certain de vouloir supprimer ton compte ?';

  @override
  String get profilSupprimerCompteDialogueTitre => 'Supprimer le compte';

  @override
  String get profilModifierPseudoTitre => 'Modifier le pseudo';

  @override
  String get profilPseudoLabel => 'Pseudo';

  @override
  String get profilModifierProfessionTitre => 'Modifier la profession';

  @override
  String get creerPinErreurTropCourt =>
      'Le code doit faire au moins 4 chiffres.';

  @override
  String get creerPinErreurNeCorrespondentPas =>
      'Les deux codes ne correspondent pas.';

  @override
  String get creerPinInstructions =>
      'Crée un code PIN pour protéger l\'app.\nÀ chaque ouverture, ce code (ou ton empreinte/Face ID) sera demandé.';

  @override
  String get creerPinChampNouveauCode => 'Nouveau code PIN';

  @override
  String get creerPinChampRetaperCode => 'Retape le code';

  @override
  String get creerPinBoutonValider => 'Valider';

  @override
  String get verrouCodeIncorrect => 'Code incorrect.';

  @override
  String verrouTropDeTentatives(int secondes) {
    return 'Trop d\'essais. Réessaie dans $secondes s.';
  }

  @override
  String get verrouCodeOublieTitre => 'Code PIN oublié ?';

  @override
  String get verrouCodeOublieMessage =>
      'Tu vas devoir te reconnecter par email pour prouver que c\'est bien toi, puis créer un nouveau code. Tes dossiers et tâches ne seront pas touchés.';

  @override
  String get verrouConfirmeIdentite =>
      'Confirme ton identité, ou entre ton code PIN.';

  @override
  String get verrouEntreCodePin => 'Entre ton code PIN pour ouvrir l\'app.';

  @override
  String get verrouChampCodePin => 'Code PIN';

  @override
  String get verrouBoutonDeverrouiller => 'Déverrouiller';

  @override
  String get verrouReessayerBiometrie =>
      'Réessayer avec l\'empreinte / Face ID';

  @override
  String get natureChampNouveauType => 'Nouveau type (ex: Consultation)';

  @override
  String get natureBoutonAjouter => 'Ajouter ce type';

  @override
  String get creationDossierTitre => 'Ajouter à un dossier';

  @override
  String get creationDossierChampNomCode => 'Nom de code';

  @override
  String get creationDossierExempleNomCode => 'ex : Dossier Alpha';

  @override
  String get creationDossierChampType => 'Type de dossier';

  @override
  String get creationDossierNotesTitre => 'Notes';

  @override
  String get creationDossierChampResteAVerifier => 'Reste à vérifier';

  @override
  String get creationDossierChampEnAttenteDe => 'En attente de';

  @override
  String get creationDossierChampAutre => 'Autre';

  @override
  String get creationDossierAvertissementSensible =>
      'Comme pour le nom du dossier, évite d\'écrire de vraies informations sensibles ici.';

  @override
  String get creationDossierBoutonCreer => 'Créer';

  @override
  String get commonFermer => 'Fermer';

  @override
  String banniereNouvelleVersionAvecNumero(String version) {
    return 'Nouvelle version disponible ($version).';
  }

  @override
  String get banniereNouvelleVersionSansNumero =>
      'Une nouvelle version de l\'app est disponible.';

  @override
  String get banniereInstructionTelechargement =>
      'Va sur vigie.pentalightcode.com pour la télécharger.';

  @override
  String get banniereIgnorerTitre => 'Ignorer cette mise à jour ?';

  @override
  String get banniereIgnorerMessage =>
      'La bannière réapparaîtra au prochain lancement de l\'app tant que tu n\'auras pas mis à jour.';

  @override
  String get banniereIgnorerBouton => 'Ignorer';

  @override
  String get aTraiterNotificationsTooltip => 'Notifications';

  @override
  String aTraiterPropositionsTooltip(int nombre) {
    return '$nombre proposition(s) de dossier à valider';
  }

  @override
  String aTraiterErreur(String erreur) {
    return 'Erreur : $erreur';
  }

  @override
  String get aTraiterRienAFaire => 'Rien à faire pour l\'instant.';

  @override
  String get aTraiterEnAttenteTitre => 'En attente (pas encore actif)';

  @override
  String get aTraiterEnAttenteExplication =>
      'Ces dossiers existent déjà — inutile de les recréer. Ils passeront automatiquement dans la liste ci-dessus quand leur moment arrivera.';

  @override
  String get aTraiterAjouterTooltip => 'Ajouter';

  @override
  String aTraiterProgressionDossier(int faites, int total, int pourcentage) {
    return '$faites/$total tâches faites ($pourcentage%)';
  }

  @override
  String aTraiterEnAttenteEcheance(String date, int jours) {
    return 'Échéance le $date — apparaîtra dans \"À traiter\" dans $jours jours';
  }

  @override
  String get aTraiterEnRetard => 'En retard';

  @override
  String get aTraiterAujourdhui => 'Aujourd\'hui';

  @override
  String get aTraiterDemain => 'Demain';

  @override
  String aTraiterDansJours(int jours) {
    return 'Dans $jours j';
  }

  @override
  String get aTraiterCestFait => 'C\'est fait';

  @override
  String get aTraiterMarquerFaitTitre => 'Marquer comme fait ?';

  @override
  String aTraiterMarquerFaitMessage(String description) {
    return '\"$description\" sera marquée comme faite.';
  }

  @override
  String agendaErreurLecture(String erreur) {
    return 'Impossible de lire le calendrier : $erreur';
  }

  @override
  String get agendaAucunCompteConnecte =>
      'Connecte d\'abord un compte Google dans Automatisation pour voir ton agenda ici.';

  @override
  String get agendaAjouterTache => 'Ajouter une tâche';

  @override
  String agendaRienCeJour(String date) {
    return 'Rien le $date.';
  }

  @override
  String get agendaJourneeEntiere => 'Journée entière';

  @override
  String get bilanPeriodeSemaine => 'Semaine';

  @override
  String get bilanPeriodeMois => 'Mois';

  @override
  String get bilanPeriodeTrimestre => 'Trimestre';

  @override
  String get bilanPeriodeSemestre => 'Semestre';

  @override
  String get bilanPeriodeAnnee => 'Année';

  @override
  String bilanLibellePeriodeTrimestre(int numero, int annee) {
    return 'T$numero $annee';
  }

  @override
  String bilanLibellePeriodeSemestre(int numero, int annee) {
    return 'S$numero $annee';
  }

  @override
  String get bilanPartagerTooltip => 'Partager ce bilan';

  @override
  String get bilanRienAAfficher => 'Rien à afficher pour l\'instant.';

  @override
  String get bilanFait => 'Fait';

  @override
  String get bilanEnRetard => 'En retard';

  @override
  String get bilanAVenir => 'À venir';

  @override
  String get bilanNoteEnRetardPeriodePassee =>
      '\"En retard\" n\'est affiché que sur la période en cours — ça n\'a pas de sens pour une période déjà passée.';

  @override
  String get bilanStatistiquesTitre => 'Statistiques';

  @override
  String get bilanResumeIaTitre => 'Résumé & recommandations';

  @override
  String get bilanResumeIaDesactiverTooltip => 'Désactiver';

  @override
  String get bilanResumeIaDescription =>
      'Un résumé et des recommandations générés par une IA (Groq), à partir des mêmes chiffres anonymisés que le partage du Bilan — désactivé par défaut.';

  @override
  String get bilanResumeIaActiverBouton => 'Activer';

  @override
  String get bilanResumeIaGenererBouton => 'Générer';

  @override
  String get bilanResumeIaRegenererBouton => 'Régénérer';

  @override
  String get bilanResumeIaConfirmationTitre => 'Avant d\'activer le résumé IA';

  @override
  String get bilanResumeIaConfirmationMessage =>
      'Le texte du Bilan (chiffres et noms de code, jamais de vraies informations — le même contenu déjà utilisé pour le partage) est envoyé à un service d\'intelligence artificielle tiers (Groq) pour générer un résumé.';

  @override
  String bilanResumeIaErreurGeneration(String erreur) {
    return 'Impossible de générer le résumé : $erreur';
  }

  @override
  String bilanTexteEnTete(String periode) {
    return 'Bilan Vigie — $periode';
  }

  @override
  String bilanTexteTotalAvecRetard(int fait, int enRetard, int aVenir) {
    return 'Total : $fait fait, $enRetard en retard, $aVenir à venir';
  }

  @override
  String bilanTexteTotalSansRetard(int fait, int aVenir) {
    return 'Total : $fait fait, $aVenir à venir';
  }

  @override
  String bilanTexteDossierAvecRetard(
    String nom,
    int fait,
    int enRetard,
    int aVenir,
  ) {
    return '$nom : $fait fait, $enRetard en retard, $aVenir à venir';
  }

  @override
  String bilanTexteDossierSansRetard(String nom, int fait, int aVenir) {
    return '$nom : $fait fait, $aVenir à venir';
  }

  @override
  String get bilanTextePartageSignature =>
      'Généré par Vigie — noms de code choisis par l\'utilisateur, aucune information sensible.';

  @override
  String get statistiquesAucuneTacheEnRetard =>
      'Aucune tâche terminée en retard pour l\'instant.';

  @override
  String statistiquesJoursSansRetard(int jours) {
    return '$jours jour(s) sans tâche terminée en retard.';
  }

  @override
  String get statistiquesRienSurPeriode => 'Rien sur cette période.';

  @override
  String statistiquesTauxAchevement(int pourcentage) {
    return '$pourcentage% de taux d\'achèvement';
  }

  @override
  String get statistiquesRepartitionParType => 'Répartition par type';

  @override
  String get statistiquesTachesParJour =>
      'Tâches terminées par jour de la semaine';

  @override
  String get statistiquesActiviteSemaines =>
      'Activité des 12 dernières semaines';

  @override
  String statistiquesTooltipJour(int jour, int mois, int compte) {
    return '$jour/$mois : $compte tâche(s)';
  }

  @override
  String get automatisationComptesGoogleTitre => 'Comptes Google';

  @override
  String get automatisationComptesGoogleDescription =>
      'Connecte autant de comptes que tu veux (perso, secondaire...) — donne-leur un nom pour t\'y retrouver, si tu veux.';

  @override
  String get automatisationConnecterCompte => 'Connecter un compte Google';

  @override
  String get automatisationConnecterAutreCompte => 'Connecter un autre compte';

  @override
  String automatisationPropositionsAValiderAvecNombre(int nombre) {
    return 'Propositions à valider ($nombre)';
  }

  @override
  String get automatisationPropositionsAValider => 'Propositions à valider';

  @override
  String automatisationCompteConnecte(String email) {
    return 'Compte connecté : $email';
  }

  @override
  String automatisationConnexionImpossible(String erreur) {
    return 'Connexion impossible : $erreur';
  }

  @override
  String get automatisationDeconnecterTitre => 'Déconnecter ce compte Google ?';

  @override
  String automatisationDeconnecterMessage(String compte) {
    return '\"$compte\" ne sera plus scanné automatiquement (emails, tâches, agenda).';
  }

  @override
  String get automatisationRenommerTitre => 'Renommer ce compte';

  @override
  String get automatisationRenommerChampNom => 'Nom (facultatif)';

  @override
  String get automatisationRenommerTooltip => 'Renommer';

  @override
  String get automatisationDeconnecterTooltip => 'Déconnecter';

  @override
  String get automatisationMethodeTitre => 'Méthode d\'extraction des dates';

  @override
  String get automatisationMethodeMotifTitre =>
      'Recherche de motif (recommandé)';

  @override
  String get automatisationMethodeMotifDescription =>
      'Gratuit — reste entièrement dans nos serveurs, rien envoyé ailleurs.';

  @override
  String get automatisationMethodeIaTitre => 'Intelligence artificielle';

  @override
  String get automatisationMethodeIaDescription =>
      'Plus fiable sur des emails mal formatés — voir les risques avant d\'activer.';

  @override
  String get automatisationAvantActiverIaTitre => 'Avant d\'activer l\'IA';

  @override
  String get automatisationAvantActiverIaMessage =>
      'Avec cette option, le contenu complet de chaque email reçu d\'un expéditeur de confiance est envoyé à un service d\'intelligence artificielle tiers pour y être lu — pas seulement la date trouvée. Pour des emails judiciaires réels, c\'est une exposition à prendre au sérieux. La recherche de motif (option recommandée) ne fait jamais sortir aucune donnée de nos serveurs.';

  @override
  String get automatisationActiverQuandMeme => 'Activer quand même';

  @override
  String get automatisationExpediteursTitre => 'Expéditeurs favoris';

  @override
  String get automatisationExpediteursDescription =>
      'Seuls les emails venant de ces adresses seront lus (ex : celle du tribunal).';

  @override
  String get automatisationChoisirDepuisBoite => 'Choisir depuis ma boîte mail';

  @override
  String get automatisationOuAjouteManuellement =>
      'Ou ajoute une adresse manuellement :';

  @override
  String get automatisationChampAdresseEmail => 'Adresse email';

  @override
  String get automatisationAucunExpediteur =>
      'Aucun expéditeur ajouté pour l\'instant.';

  @override
  String get automatisationRetirerTitre => 'Retirer cet expéditeur ?';

  @override
  String automatisationRetirerMessage(String email) {
    return 'Les emails de \"$email\" ne seront plus lus automatiquement.';
  }

  @override
  String get automatisationRetirerBouton => 'Retirer';

  @override
  String get automatisationAdresseInvalide => 'Adresse email invalide.';

  @override
  String get automatisationDomaineIntrouvableTitre =>
      'Ce domaine semble introuvable';

  @override
  String automatisationDomaineIntrouvableMessage(String domaine, String email) {
    return 'Aucun serveur mail trouvé pour \"$domaine\" — vérifie qu\'il n\'y a pas de faute de frappe.\n\nAjouter quand même : $email ?';
  }

  @override
  String get automatisationAjouterQuandMeme => 'Ajouter quand même';

  @override
  String get automatisationAjouterExpediteurTitre => 'Ajouter cet expéditeur ?';

  @override
  String automatisationAjouterExpediteurMessage(String email) {
    return 'Vérifie bien qu\'il n\'y a pas de faute de frappe :\n\n$email';
  }

  @override
  String get automatisationAjouterBouton => 'Ajouter';

  @override
  String automatisationErreurLectureBoite(String erreur) {
    return 'Impossible de lire la boîte mail : $erreur';
  }

  @override
  String get automatisationAucunNouvelExpediteur =>
      'Aucun nouvel expéditeur trouvé dans les emails récents.';

  @override
  String get automatisationExpediteursTrouvesTitre => 'Expéditeurs trouvés';

  @override
  String get automatisationCocheConfiance =>
      'Coche ceux à qui tu fais confiance (ex : le tribunal).';

  @override
  String automatisationEmailsRecents(int nombre) {
    return '$nombre email(s) récent(s)';
  }

  @override
  String automatisationAjouterAvecNombre(int nombre) {
    return 'Ajouter ($nombre)';
  }

  @override
  String get automatisationVerificationAutoTitre => 'Vérification automatique';

  @override
  String automatisationEtatPasEncoreVerifie(String service) {
    return '$service : pas encore vérifié';
  }

  @override
  String automatisationEtatAvecDate(
    String service,
    String statut,
    String date,
  ) {
    return '$service : $statut — $date';
  }

  @override
  String automatisationEtatSansDate(String service, String statut) {
    return '$service : $statut';
  }

  @override
  String get automatisationEtatOk => 'OK';

  @override
  String get automatisationEtatErreur => 'Erreur';

  @override
  String get propositionsTitre => 'Propositions';

  @override
  String get propositionsAucunePourLInstant =>
      'Aucune proposition pour l\'instant. Dès qu\'une date sera trouvée dans un email, une tâche Google Tasks ou un événement Google Calendar, elle apparaîtra ici.';

  @override
  String get propositionsFiltreTout => 'Tout';

  @override
  String get propositionsDateInconnue => 'Date inconnue';

  @override
  String propositionsDeExpediteur(String expediteur) {
    return 'De : $expediteur';
  }

  @override
  String get propositionsIgnorerBouton => 'Ignorer';

  @override
  String get propositionsCreerDossierBouton => 'Créer le dossier';

  @override
  String get propositionsIgnorerTitre => 'Ignorer cette proposition ?';

  @override
  String propositionsIgnorerMessage(String sujet) {
    return 'Aucun dossier ne sera créé pour \"$sujet\".';
  }

  @override
  String get ajouterErreurNomCode => 'Donne un nom de code au dossier.';

  @override
  String get ajouterErreurNature => 'Choisis une nature de dossier.';

  @override
  String get ajouterDossierAjoute => 'Dossier ajouté.';

  @override
  String get ajouterTitre => 'Ajouter un dossier';

  @override
  String get ajouterAjoutGroupeTooltip =>
      'Ajout groupé (plusieurs dossiers d\'un coup)';

  @override
  String get ajouterTypeDossierLabel => 'Type de dossier';

  @override
  String get ajouterGererTypesBouton => 'Gérer mes types de dossier';

  @override
  String get ajouterDetailLabel => 'Détail (pour distinguer plusieurs tâches)';

  @override
  String get ajouterDetailExemple => 'ex : Conclusions en défense';

  @override
  String get ajouterDans2Semaines => 'Dans 2 semaines';

  @override
  String get ajouterDans1Mois => 'Dans 1 mois';

  @override
  String get ajouterChoisirDate => 'Choisir une date';

  @override
  String get ajouterRetirerDate => 'Retirer';

  @override
  String get ajouterAucuneDateChoisie => 'Aucune date choisie (optionnel).';

  @override
  String ajouterEcheanceAvecDate(String date) {
    return 'Échéance : $date';
  }

  @override
  String get ajouterNoteTitre => 'Ajouter une note';

  @override
  String get ajoutGroupeTitre => 'Ajout groupé';

  @override
  String get ajoutGroupeTousTypeLabel => 'Tous ces dossiers sont de type :';

  @override
  String get ajoutGroupeInstructions =>
      'Remplis une ligne par dossier — la date est optionnelle.';

  @override
  String ajoutGroupeNomCodeHint(int numero) {
    return 'Dossier $numero';
  }

  @override
  String get ajoutGroupeDateBouton => 'Date';

  @override
  String get ajoutGroupeAjouterLigne => 'Ajouter une ligne';

  @override
  String ajoutGroupeEnregistrerBouton(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: 'Enregistrer ($nombre dossiers)',
      one: 'Enregistrer (1 dossier)',
      zero: 'Enregistrer',
    );
    return '$_temp0';
  }

  @override
  String get confirmerEmailErreurVide =>
      'Entre l\'adresse email utilisée pour demander le lien.';

  @override
  String get confirmerEmailErreurLienInvalide =>
      'Ce lien ne correspond pas à cette adresse, ou il a expiré.';

  @override
  String get confirmerEmailInstructions =>
      'Confirme ton adresse email pour terminer la connexion.';

  @override
  String get confirmerEmailBouton => 'Confirmer';

  @override
  String get accueilPage1Titre => 'Vigie';

  @override
  String get accueilPage1Texte =>
      'Le suivi d\'échéances qui reste confidentiel — pour les professions où chaque dossier compte.';

  @override
  String get accueilPage2Titre => 'Ajouter';

  @override
  String get accueilPage2Texte =>
      'Crée un dossier avec un nom de code, une date, et laisse Vigie calculer quand te rappeler.';

  @override
  String get accueilPage3Titre => 'Suivre';

  @override
  String get accueilPage3Texte =>
      'Vigie te relance jusqu\'à confirmation que c\'est fait — jamais de tâche oubliée en silence.';

  @override
  String get accueilPage4Titre => 'Faire le bilan';

  @override
  String get accueilPage4Texte =>
      'Un résumé de ton activité, dossier par dossier, pour garder une vue d\'ensemble.';

  @override
  String get accueilConfidentialiteNote =>
      'Aucune vraie information sur tes affaires n\'est jamais requise — tu choisis toi-même un nom de code pour chaque dossier.';

  @override
  String get accueilBoutonPasser => 'Passer';

  @override
  String get accueilBoutonSuivant => 'Suivant';

  @override
  String get accueilBoutonSeConnecter => 'Se connecter';

  @override
  String get connexionChampEmail => 'Adresse email';

  @override
  String get connexionErreurEmailInvalide => 'Entre une adresse email valide.';

  @override
  String get connexionErreurEnvoiLien =>
      'Impossible d\'envoyer le lien. Vérifie ta connexion.';

  @override
  String connexionTelechargerAvecVersion(String version) {
    return 'Télécharger l\'app Android (v$version)';
  }

  @override
  String get connexionTelechargerSansVersion =>
      'Télécharger l\'app Android (recommandé)';

  @override
  String get connexionVersionInstalleeMeilleure =>
      'La version installée fonctionne mieux que le site (notifications, Gmail...).';

  @override
  String get connexionInstructions =>
      'Entre ton adresse email, tu recevras un lien de connexion — pas besoin de mot de passe.';

  @override
  String get connexionRecevoirLienBouton => 'Recevoir le lien de connexion';

  @override
  String connexionLienEnvoye(String email) {
    return 'Un lien a été envoyé à $email.\nOuvre ta boîte mail et clique sur le lien pour te connecter.';
  }

  @override
  String get connexionMauvaiseAdresse => 'Mauvaise adresse ? Recommencer';

  @override
  String get notificationsTitre => 'Notifications';

  @override
  String get notificationsAucunePourLInstant =>
      'Aucune notification pour l\'instant.';

  @override
  String get notificationsAucunePourCeType =>
      'Aucune notification pour ce type.';

  @override
  String get notificationsFiltreTous => 'Tous';

  @override
  String notificationsChipTypeCompte(String type, int valeur) {
    return '$type : $valeur';
  }

  @override
  String get pourquoiVigieAppBarTitre => 'Pourquoi Vigie';

  @override
  String get pourquoiVigieTitre1 =>
      'Des rappels qui s\'adaptent, pas un message figé';

  @override
  String get pourquoiVigieTexte1 =>
      'Le ton se durcit avec le retard — neutre, puis ferme, puis prioritaire — au lieu de répéter éternellement la même phrase. Une échéance qui approche est signalée même sans retard.';

  @override
  String get pourquoiVigieTitre2 => 'Confidentialité par conception';

  @override
  String get pourquoiVigieTexte2 =>
      'Les dossiers sont désignés par des noms de code choisis par toi, jamais par les vraies informations sensibles — du nom du dossier jusqu\'au journal de bord et au bilan exporté.';

  @override
  String get pourquoiVigieTitre3 => 'Toutes tes sources, une seule validation';

  @override
  String get pourquoiVigieTexte3 =>
      'Gmail, Google Tasks et Google Calendar alimentent le même écran de propositions, codées par couleur selon leur origine — tu choisis ce qui devient un vrai dossier. L\'état de chaque vérification est visible, pas une boîte noire.';

  @override
  String get pourquoiVigieTitre4 => 'Un bilan qui raconte une histoire';

  @override
  String get pourquoiVigieTexte4 =>
      'Carte de chaleur d\'activité, répartition par type de dossier, jour le plus chargé, taux d\'achèvement, et un indicateur de fiabilité — pas juste des compteurs bruts.';

  @override
  String get pourquoiVigieTitre5 =>
      'Un journal de bord, pas des cases à cocher';

  @override
  String get pourquoiVigieTexte5 =>
      'Documente l\'avancement d\'un dossier étape par étape : chaque note s\'ajoute à la suite, rien n\'est jamais écrasé — une vraie mémoire de la progression, pas un simple statut.';

  @override
  String get pourquoiVigieTitre6 =>
      'Un rapport sûr à partager, par construction';

  @override
  String get pourquoiVigieTexte6 =>
      'Le bilan s\'exporte en un clic — et comme tout est déjà en noms de code, il n\'y a jamais rien de sensible dedans, où qu\'il soit partagé.';

  @override
  String get commonSupprimer => 'Supprimer';

  @override
  String get dossierDetailModifierTooltip => 'Modifier le dossier';

  @override
  String get dossierDetailSupprimerTooltip => 'Supprimer le dossier';

  @override
  String dossierDetailDateAvecValeur(String date) {
    return 'Date : $date';
  }

  @override
  String get dossierDetailPasDeDate => 'Pas de date renseignée';

  @override
  String get dossierDetailTachesLieesTitre => 'Tâches liées';

  @override
  String get dossierDetailAucuneTache => 'Aucune tâche pour l\'instant.';

  @override
  String get dossierDetailAjouterTacheBouton => 'Ajouter une tâche';

  @override
  String get dossierDetailSupprimerDossierTitre => 'Supprimer ce dossier ?';

  @override
  String dossierDetailSupprimerDossierMessage(String nom) {
    return 'Le dossier \"$nom\" et toutes ses tâches seront supprimés définitivement.';
  }

  @override
  String dossierDetailNatureEtDate(String nature, String date) {
    return '$nature — $date';
  }

  @override
  String get dossierDetailConfirmerTitre => 'Confirmer ?';

  @override
  String get dossierDetailBasculerMarquerFait =>
      'marquer cette tâche comme faite';

  @override
  String get dossierDetailBasculerRemettreAFaire =>
      'remettre cette tâche à \"à faire\"';

  @override
  String dossierDetailBasculerMessage(String action, String description) {
    return 'Tu veux $action : \"$description\".';
  }

  @override
  String get dossierDetailSupprimerTacheTitre => 'Supprimer cette tâche ?';

  @override
  String dossierDetailSupprimerTacheMessage(String description) {
    return '\"$description\" sera supprimée définitivement.';
  }

  @override
  String get dossierDetailAjouterTacheTitre => 'Ajouter une tâche';

  @override
  String get dossierDetailModifierTacheTitre => 'Modifier la tâche';

  @override
  String get dossierDetailDetailTacheLabel => 'Détail de la tâche';

  @override
  String get journalTypeAvancement => 'Avancement';

  @override
  String get journalTypeBlocage => 'Blocage';

  @override
  String get journalTypeDecision => 'Décision';

  @override
  String get dossierDetailJournalTitre => 'Journal de bord';

  @override
  String get dossierDetailJournalDescription =>
      'Documente l\'avancement étape par étape — chaque note s\'ajoute à la suite, rien n\'est écrasé. Comme pour le nom du dossier, évite d\'y écrire de vraies informations sensibles.';

  @override
  String get dossierDetailJournalHint =>
      'Ex : appelé X, en attente de sa réponse...';

  @override
  String get dossierDetailAjouterJournalBouton => 'Ajouter au journal';

  @override
  String get dossierDetailBoutonDeverrouillerNotes => 'Déverrouiller mes notes';

  @override
  String get dossierDetailEntreeVerrouillee =>
      'Entrée chiffrée — déverrouille tes notes pour la lire.';

  @override
  String get phraseSecreteTitreCreation => 'Protéger tes notes de dossier';

  @override
  String get phraseSecreteTitreDeverrouillage => 'Déverrouiller les notes';

  @override
  String get phraseSecreteAvertissement =>
      'Si tu oublies ce mot de passe, ces notes seront perdues pour toujours, pour tout le monde — même nous ne pourrons pas les récupérer. Ce n\'est pas ton code PIN, ne le note nulle part sur ce téléphone.';

  @override
  String get phraseSecreteInstructionsDeverrouillage =>
      'Entre ton mot de passe pour voir et écrire dans le journal de ce dossier.';

  @override
  String get phraseSecreteChamp => 'Mot de passe';

  @override
  String get phraseSecreteChampConfirmation => 'Retape le mot de passe';

  @override
  String get phraseSecreteErreurTropCourte =>
      'Choisis un mot de passe d\'au moins 8 caractères.';

  @override
  String get phraseSecreteErreurNeCorrespondentPas =>
      'Les deux mots de passe ne correspondent pas.';

  @override
  String get phraseSecreteErreurIncorrecte => 'Mot de passe incorrect.';

  @override
  String get phraseSecreteErreurGenerique =>
      'Une erreur est survenue. Réessaie.';

  @override
  String get phraseSecreteBoutonCreer => 'Créer';

  @override
  String get phraseSecreteBoutonDeverrouiller => 'Déverrouiller';

  @override
  String dossierDetailErreurAjoutJournal(String erreur) {
    return 'Impossible d\'ajouter cette entrée : $erreur';
  }

  @override
  String dossierDetailErreurModifJournal(String erreur) {
    return 'Impossible de modifier cette entrée : $erreur';
  }

  @override
  String get dossierDetailSupprimerEntreeTitre =>
      'Supprimer cette entrée du journal ?';

  @override
  String dossierDetailSupprimerEntreeMessage(String date) {
    return 'Cette note du $date sera supprimée définitivement.';
  }

  @override
  String get dossierDetailModifierEntreeTitre => 'Modifier cette entrée';

  @override
  String get dossierDetailHistoriqueTitre => 'Historique';

  @override
  String get dossierDetailAucuneEntree => 'Aucune entrée pour l\'instant.';

  @override
  String get dossierDetailAucuneEntreeType => 'Aucune entrée de ce type.';

  @override
  String dossierDetailErreurLectureJournal(String erreur) {
    return 'Impossible de lire le journal : $erreur';
  }

  @override
  String get dossierDetailHier => 'Hier';

  @override
  String get dossierDetailModifieSuffixe => '· modifié';

  @override
  String get commonConfirmer => 'Confirmer';

  @override
  String get commonTuEsSur => 'Tu es sûr ?';

  @override
  String commonDerniereConfirmation(String message) {
    return 'Dernière confirmation : $message';
  }

  @override
  String get connexionGoogleAdresseInconnue =>
      'Compte connecté (reconnecte-toi pour voir l\'adresse)';
}
