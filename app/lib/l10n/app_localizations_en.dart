// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navATraiter => 'To Do';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navBilan => 'Summary';

  @override
  String get navProfil => 'Profile';

  @override
  String get professionMedecin => 'Doctor / Healthcare professional';

  @override
  String get professionEnseignant => 'Teacher / Professor';

  @override
  String get professionAvocatJuriste => 'Lawyer / Legal counsel';

  @override
  String get professionMagistrat => 'Magistrate';

  @override
  String get professionComptable => 'Accountant / Chartered accountant';

  @override
  String get professionConsultant => 'Consultant / Freelancer';

  @override
  String get professionCommercial => 'Sales / Account manager';

  @override
  String get professionArchitecteIngenieur => 'Architect / Engineer';

  @override
  String get professionAgentImmobilier => 'Real estate agent';

  @override
  String get professionArtisanBatiment => 'Craftsman / Building contractor';

  @override
  String get professionBeauteBienEtre => 'Hairdresser / Beautician / Wellness';

  @override
  String get professionEntrepreneur => 'Entrepreneur / Business owner';

  @override
  String get professionAutre => 'Other';

  @override
  String joursAvant(int jours) {
    return '$jours days before';
  }

  @override
  String get profilPreciseProfessionLabel => 'Specify your profession';

  @override
  String get onboardingBienvenue => 'Welcome!';

  @override
  String get onboardingSousTitre =>
      'A few details to personalize your assistant.';

  @override
  String get onboardingChampPrenom => 'First name';

  @override
  String get onboardingChampPseudo => 'Nickname (what the app calls you)';

  @override
  String get onboardingChampProfession => 'Your profession';

  @override
  String get onboardingNoteNaturesPreremplies =>
      'We\'ll pre-fill case types suited to your profession — editable afterwards.';

  @override
  String get onboardingChampDelaiRappel =>
      'How many days ahead do you want to be notified?';

  @override
  String get onboardingBoutonCommencer => 'Get started';

  @override
  String get onboardingErreurPrenomPseudo =>
      'Enter at least your first name and a nickname.';

  @override
  String get onboardingErreurProfession =>
      'Specify the name of your profession.';

  @override
  String get onboardingErreurConnexion =>
      'Couldn\'t save. Check your connection.';

  @override
  String get commonAnnuler => 'Cancel';

  @override
  String get commonContinuer => 'Continue';

  @override
  String get commonEnregistrer => 'Save';

  @override
  String get profilTitre => 'Profile';

  @override
  String get profilPourquoiVigieTitre => 'Why Vigie?';

  @override
  String get profilPourquoiVigieSousTitre => 'What makes Vigie different';

  @override
  String profilConnecteEnTantQue(String email) {
    return 'Signed in as $email';
  }

  @override
  String get profilEmailInconnu => 'unknown';

  @override
  String get profilPseudoNonDefini => 'Nickname not set';

  @override
  String get profilProfessionNonDefinie => 'Profession not set';

  @override
  String get profilDelaiRappelTitre => 'Reminder delay';

  @override
  String profilDelaiRappelSousTitre(int jours) {
    return '$jours days before the deadline';
  }

  @override
  String get profilTypesDossierTitre => 'My case types';

  @override
  String get profilTypesDossierSousTitre =>
      'Add or remove your custom categories';

  @override
  String get profilThemeTitre => 'Theme';

  @override
  String get profilThemeSousTitre => 'Color and light/dark mode';

  @override
  String get profilLangueTitre => 'Language';

  @override
  String get profilLangueSousTitre => 'Français / English';

  @override
  String get profilThemeCouleurLabel => 'Color';

  @override
  String get profilThemeModeLabel => 'Mode';

  @override
  String get profilThemeModeSysteme => 'System';

  @override
  String get profilThemeModeClair => 'Light';

  @override
  String get profilThemeModeSombre => 'Dark';

  @override
  String get couleurIndigo => 'Indigo';

  @override
  String get couleurBleu => 'Blue';

  @override
  String get couleurSarcelle => 'Teal';

  @override
  String get couleurVert => 'Green';

  @override
  String get couleurViolet => 'Purple';

  @override
  String get couleurOrange => 'Orange';

  @override
  String get profilAutomatisationTitre => 'Automation';

  @override
  String get profilAutomatisationAucunCompte =>
      'Connect a Google account to detect dates automatically';

  @override
  String get profilAutomatisationUnCompte => '1 Google account connected';

  @override
  String get profilAutomatisationDeuxComptes => '2 Google accounts connected';

  @override
  String get profilSeDeconnecterTitre => 'Sign out';

  @override
  String get profilSupprimerCompteTitre => 'Delete my account';

  @override
  String get profilSeDeconnecterConfirmationTitre => 'Sign out?';

  @override
  String get profilSeDeconnecterConfirmationMessage =>
      'You\'ll need to sign in again by email to reopen the app.';

  @override
  String get profilSupprimerCompteMessage1 =>
      'All your cases and tasks will be permanently deleted. There is no way to recover them afterwards.';

  @override
  String get profilSupprimerCompteMessage2 =>
      'Your login account will also be deleted — you won\'t be able to sign in again with this email without creating a brand new, empty account.';

  @override
  String get profilSupprimerCompteMessage3 =>
      'Final warning: this action is irreversible and immediate. Are you absolutely sure you want to delete your account?';

  @override
  String get profilSupprimerCompteDialogueTitre => 'Delete account';

  @override
  String get profilModifierPseudoTitre => 'Edit nickname';

  @override
  String get profilPseudoLabel => 'Nickname';

  @override
  String get profilModifierProfessionTitre => 'Edit profession';

  @override
  String get creerPinErreurTropCourt => 'The code must be at least 4 digits.';

  @override
  String get creerPinErreurNeCorrespondentPas => 'The two codes don\'t match.';

  @override
  String get creerPinInstructions =>
      'Create a PIN code to protect the app.\nYou\'ll be asked for it (or your fingerprint/Face ID) every time you open the app.';

  @override
  String get creerPinChampNouveauCode => 'New PIN code';

  @override
  String get creerPinChampRetaperCode => 'Retype the code';

  @override
  String get creerPinBoutonValider => 'Confirm';

  @override
  String get verrouCodeIncorrect => 'Incorrect code.';

  @override
  String verrouTropDeTentatives(int secondes) {
    return 'Too many attempts. Try again in ${secondes}s.';
  }

  @override
  String get verrouCodeOublieTitre => 'Forgot your PIN?';

  @override
  String get verrouCodeOublieMessage =>
      'You\'ll need to sign in again by email to prove it\'s really you, then create a new code. Your cases and tasks won\'t be affected.';

  @override
  String get verrouConfirmeIdentite =>
      'Confirm your identity, or enter your PIN code.';

  @override
  String get verrouEntreCodePin => 'Enter your PIN code to open the app.';

  @override
  String get verrouChampCodePin => 'PIN code';

  @override
  String get verrouBoutonDeverrouiller => 'Unlock';

  @override
  String get verrouReessayerBiometrie => 'Try again with fingerprint / Face ID';

  @override
  String get natureChampNouveauType => 'New type (e.g. Consultation)';

  @override
  String get natureBoutonAjouter => 'Add this type';

  @override
  String get creationDossierTitre => 'Add to a case';

  @override
  String get creationDossierChampNomCode => 'Code name';

  @override
  String get creationDossierExempleNomCode => 'e.g.: Case Alpha';

  @override
  String get creationDossierChampType => 'Case type';

  @override
  String get creationDossierNotesTitre => 'Notes';

  @override
  String get creationDossierChampResteAVerifier => 'Still to check';

  @override
  String get creationDossierChampEnAttenteDe => 'Waiting on';

  @override
  String get creationDossierChampAutre => 'Other';

  @override
  String get creationDossierAvertissementSensible =>
      'As with the case\'s code name, avoid writing actual sensitive information here.';

  @override
  String get creationDossierBoutonCreer => 'Create';

  @override
  String get commonFermer => 'Close';

  @override
  String banniereNouvelleVersionAvecNumero(String version) {
    return 'New version available ($version).';
  }

  @override
  String get banniereNouvelleVersionSansNumero =>
      'A new version of the app is available.';

  @override
  String get banniereInstructionTelechargement =>
      'Go to vigie.pentalightcode.com to download it.';

  @override
  String get banniereIgnorerTitre => 'Dismiss this update?';

  @override
  String get banniereIgnorerMessage =>
      'The banner will reappear the next time you open the app until you update.';

  @override
  String get banniereIgnorerBouton => 'Dismiss';

  @override
  String get aTraiterNotificationsTooltip => 'Notifications';

  @override
  String aTraiterPropositionsTooltip(int nombre) {
    return '$nombre case proposal(s) to review';
  }

  @override
  String aTraiterErreur(String erreur) {
    return 'Error: $erreur';
  }

  @override
  String get aTraiterRienAFaire => 'Nothing to do for now.';

  @override
  String get aTraiterEnAttenteTitre => 'Waiting (not active yet)';

  @override
  String get aTraiterEnAttenteExplication =>
      'These cases already exist — no need to recreate them. They\'ll automatically move to the list above once their time comes.';

  @override
  String get aTraiterAjouterTooltip => 'Add';

  @override
  String aTraiterProgressionDossier(int faites, int total, int pourcentage) {
    return '$faites/$total tasks done ($pourcentage%)';
  }

  @override
  String aTraiterEnAttenteEcheance(String date, int jours) {
    return 'Due on $date — will appear in \"To Do\" in $jours days';
  }

  @override
  String get aTraiterEnRetard => 'Overdue';

  @override
  String get aTraiterAujourdhui => 'Today';

  @override
  String get aTraiterDemain => 'Tomorrow';

  @override
  String aTraiterDansJours(int jours) {
    return 'In $jours d';
  }

  @override
  String get aTraiterCestFait => 'Done';

  @override
  String get aTraiterMarquerFaitTitre => 'Mark as done?';

  @override
  String aTraiterMarquerFaitMessage(String description) {
    return '\"$description\" will be marked as done.';
  }

  @override
  String agendaErreurLecture(String erreur) {
    return 'Couldn\'t read the calendar: $erreur';
  }

  @override
  String get agendaAucunCompteConnecte =>
      'First connect a Google account in Automation to see your agenda here.';

  @override
  String get agendaAjouterTache => 'Add a task';

  @override
  String agendaRienCeJour(String date) {
    return 'Nothing on $date.';
  }

  @override
  String get agendaJourneeEntiere => 'All day';

  @override
  String get bilanPeriodeSemaine => 'Week';

  @override
  String get bilanPeriodeMois => 'Month';

  @override
  String get bilanPeriodeTrimestre => 'Quarter';

  @override
  String get bilanPeriodeSemestre => 'Half-year';

  @override
  String get bilanPeriodeAnnee => 'Year';

  @override
  String bilanLibellePeriodeTrimestre(int numero, int annee) {
    return 'Q$numero $annee';
  }

  @override
  String bilanLibellePeriodeSemestre(int numero, int annee) {
    return 'H$numero $annee';
  }

  @override
  String get bilanPartagerTooltip => 'Share this summary';

  @override
  String get bilanRienAAfficher => 'Nothing to show for now.';

  @override
  String get bilanFait => 'Done';

  @override
  String get bilanEnRetard => 'Overdue';

  @override
  String get bilanAVenir => 'Upcoming';

  @override
  String get bilanNoteEnRetardPeriodePassee =>
      '\"Overdue\" is only shown for the current period — it doesn\'t make sense for a period that\'s already past.';

  @override
  String get bilanStatistiquesTitre => 'Statistics';

  @override
  String get bilanResumeIaTitre => 'Summary & recommendations';

  @override
  String get bilanResumeIaDesactiverTooltip => 'Turn off';

  @override
  String get bilanResumeIaDescription =>
      'A summary and recommendations generated by AI (Groq), based on the same anonymized figures used for sharing the summary — off by default.';

  @override
  String get bilanResumeIaActiverBouton => 'Turn on';

  @override
  String get bilanResumeIaGenererBouton => 'Generate';

  @override
  String get bilanResumeIaRegenererBouton => 'Regenerate';

  @override
  String get bilanResumeIaConfirmationTitre =>
      'Before turning on the AI summary';

  @override
  String get bilanResumeIaConfirmationMessage =>
      'The summary\'s text (figures and code names, never real information — the same content already used for sharing) is sent to a third-party AI service (Groq) to generate a summary.';

  @override
  String bilanResumeIaErreurGeneration(String erreur) {
    return 'Couldn\'t generate the summary: $erreur';
  }

  @override
  String bilanTexteEnTete(String periode) {
    return 'Vigie Summary — $periode';
  }

  @override
  String bilanTexteTotalAvecRetard(int fait, int enRetard, int aVenir) {
    return 'Total: $fait done, $enRetard overdue, $aVenir upcoming';
  }

  @override
  String bilanTexteTotalSansRetard(int fait, int aVenir) {
    return 'Total: $fait done, $aVenir upcoming';
  }

  @override
  String bilanTexteDossierAvecRetard(
    String nom,
    int fait,
    int enRetard,
    int aVenir,
  ) {
    return '$nom: $fait done, $enRetard overdue, $aVenir upcoming';
  }

  @override
  String bilanTexteDossierSansRetard(String nom, int fait, int aVenir) {
    return '$nom: $fait done, $aVenir upcoming';
  }

  @override
  String get bilanTextePartageSignature =>
      'Generated by Vigie — code names chosen by the user, no sensitive information.';

  @override
  String get statistiquesAucuneTacheEnRetard =>
      'No task completed late so far.';

  @override
  String statistiquesJoursSansRetard(int jours) {
    return '$jours day(s) without a late-completed task.';
  }

  @override
  String get statistiquesRienSurPeriode => 'Nothing for this period.';

  @override
  String statistiquesTauxAchevement(int pourcentage) {
    return '$pourcentage% completion rate';
  }

  @override
  String get statistiquesRepartitionParType => 'Breakdown by type';

  @override
  String get statistiquesTachesParJour => 'Tasks completed by day of the week';

  @override
  String get statistiquesActiviteSemaines => 'Activity over the last 12 weeks';

  @override
  String statistiquesTooltipJour(int jour, int mois, int compte) {
    return '$jour/$mois: $compte task(s)';
  }

  @override
  String get automatisationComptesGoogleTitre => 'Google accounts';

  @override
  String get automatisationComptesGoogleDescription =>
      'Connect as many accounts as you want (personal, secondary...) — give them a name to keep track of them, if you want.';

  @override
  String get automatisationConnecterCompte => 'Connect a Google account';

  @override
  String get automatisationConnecterAutreCompte => 'Connect another account';

  @override
  String automatisationPropositionsAValiderAvecNombre(int nombre) {
    return 'Proposals to review ($nombre)';
  }

  @override
  String get automatisationPropositionsAValider => 'Proposals to review';

  @override
  String automatisationCompteConnecte(String email) {
    return 'Account connected: $email';
  }

  @override
  String automatisationConnexionImpossible(String erreur) {
    return 'Couldn\'t connect: $erreur';
  }

  @override
  String get automatisationDeconnecterTitre =>
      'Disconnect this Google account?';

  @override
  String automatisationDeconnecterMessage(String compte) {
    return '\"$compte\" will no longer be scanned automatically (emails, tasks, calendar).';
  }

  @override
  String get automatisationRenommerTitre => 'Rename this account';

  @override
  String get automatisationRenommerChampNom => 'Name (optional)';

  @override
  String get automatisationRenommerTooltip => 'Rename';

  @override
  String get automatisationDeconnecterTooltip => 'Disconnect';

  @override
  String get automatisationMethodeTitre => 'Date extraction method';

  @override
  String get automatisationMethodeMotifTitre =>
      'Pattern matching (recommended)';

  @override
  String get automatisationMethodeMotifDescription =>
      'Free — stays entirely on our servers, nothing sent elsewhere.';

  @override
  String get automatisationMethodeIaTitre => 'Artificial intelligence';

  @override
  String get automatisationMethodeIaDescription =>
      'More reliable on poorly formatted emails — see the risks before enabling.';

  @override
  String get automatisationAvantActiverIaTitre => 'Before enabling AI';

  @override
  String get automatisationAvantActiverIaMessage =>
      'With this option, the full content of every email received from a trusted sender is sent to a third-party AI service to be read — not just the date found. For real judicial emails, this is an exposure to take seriously. Pattern matching (the recommended option) never lets any data leave our servers.';

  @override
  String get automatisationActiverQuandMeme => 'Enable anyway';

  @override
  String get automatisationExpediteursTitre => 'Favorite senders';

  @override
  String get automatisationExpediteursDescription =>
      'Only emails from these addresses will be read (e.g. the court\'s).';

  @override
  String get automatisationChoisirDepuisBoite => 'Choose from my mailbox';

  @override
  String get automatisationOuAjouteManuellement =>
      'Or add an address manually:';

  @override
  String get automatisationChampAdresseEmail => 'Email address';

  @override
  String get automatisationAucunExpediteur => 'No sender added yet.';

  @override
  String get automatisationRetirerTitre => 'Remove this sender?';

  @override
  String automatisationRetirerMessage(String email) {
    return 'Emails from \"$email\" will no longer be read automatically.';
  }

  @override
  String get automatisationRetirerBouton => 'Remove';

  @override
  String get automatisationAdresseInvalide => 'Invalid email address.';

  @override
  String get automatisationDomaineIntrouvableTitre =>
      'This domain seems unreachable';

  @override
  String automatisationDomaineIntrouvableMessage(String domaine, String email) {
    return 'No mail server found for \"$domaine\" — check for a typo.\n\nAdd anyway: $email?';
  }

  @override
  String get automatisationAjouterQuandMeme => 'Add anyway';

  @override
  String get automatisationAjouterExpediteurTitre => 'Add this sender?';

  @override
  String automatisationAjouterExpediteurMessage(String email) {
    return 'Double-check for a typo:\n\n$email';
  }

  @override
  String get automatisationAjouterBouton => 'Add';

  @override
  String automatisationErreurLectureBoite(String erreur) {
    return 'Couldn\'t read the mailbox: $erreur';
  }

  @override
  String get automatisationAucunNouvelExpediteur =>
      'No new sender found in recent emails.';

  @override
  String get automatisationExpediteursTrouvesTitre => 'Senders found';

  @override
  String get automatisationCocheConfiance =>
      'Check the ones you trust (e.g. the court).';

  @override
  String automatisationEmailsRecents(int nombre) {
    return '$nombre recent email(s)';
  }

  @override
  String automatisationAjouterAvecNombre(int nombre) {
    return 'Add ($nombre)';
  }

  @override
  String get automatisationVerificationAutoTitre => 'Automatic check';

  @override
  String automatisationEtatPasEncoreVerifie(String service) {
    return '$service: not checked yet';
  }

  @override
  String automatisationEtatAvecDate(
    String service,
    String statut,
    String date,
  ) {
    return '$service: $statut — $date';
  }

  @override
  String automatisationEtatSansDate(String service, String statut) {
    return '$service: $statut';
  }

  @override
  String get automatisationEtatOk => 'OK';

  @override
  String get automatisationEtatErreur => 'Error';

  @override
  String get propositionsTitre => 'Proposals';

  @override
  String get propositionsAucunePourLInstant =>
      'No proposals yet. As soon as a date is found in an email, a Google Tasks task, or a Google Calendar event, it will appear here.';

  @override
  String get propositionsFiltreTout => 'All';

  @override
  String get propositionsDateInconnue => 'Unknown date';

  @override
  String propositionsDeExpediteur(String expediteur) {
    return 'From: $expediteur';
  }

  @override
  String get propositionsIgnorerBouton => 'Ignore';

  @override
  String get propositionsCreerDossierBouton => 'Create the case';

  @override
  String get propositionsIgnorerTitre => 'Ignore this proposal?';

  @override
  String propositionsIgnorerMessage(String sujet) {
    return 'No case will be created for \"$sujet\".';
  }

  @override
  String get ajouterErreurNomCode => 'Give the case a code name.';

  @override
  String get ajouterErreurNature => 'Choose a case type.';

  @override
  String get ajouterDossierAjoute => 'Case added.';

  @override
  String get ajouterTitre => 'Add a case';

  @override
  String get ajouterAjoutGroupeTooltip => 'Bulk add (several cases at once)';

  @override
  String get ajouterTypeDossierLabel => 'Case type';

  @override
  String get ajouterGererTypesBouton => 'Manage my case types';

  @override
  String get ajouterDetailLabel => 'Detail (to tell several tasks apart)';

  @override
  String get ajouterDetailExemple => 'e.g.: Defense submissions';

  @override
  String get ajouterDans2Semaines => 'In 2 weeks';

  @override
  String get ajouterDans1Mois => 'In 1 month';

  @override
  String get ajouterChoisirDate => 'Choose a date';

  @override
  String get ajouterRetirerDate => 'Remove';

  @override
  String get ajouterAucuneDateChoisie => 'No date chosen (optional).';

  @override
  String ajouterEcheanceAvecDate(String date) {
    return 'Due date: $date';
  }

  @override
  String get ajouterNoteTitre => 'Add a note';

  @override
  String get ajoutGroupeTitre => 'Bulk add';

  @override
  String get ajoutGroupeTousTypeLabel => 'All these cases are of type:';

  @override
  String get ajoutGroupeInstructions =>
      'Fill in one line per case — the date is optional.';

  @override
  String ajoutGroupeNomCodeHint(int numero) {
    return 'Case $numero';
  }

  @override
  String get ajoutGroupeDateBouton => 'Date';

  @override
  String get ajoutGroupeAjouterLigne => 'Add a line';

  @override
  String ajoutGroupeEnregistrerBouton(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: 'Save ($nombre cases)',
      one: 'Save (1 case)',
      zero: 'Save',
    );
    return '$_temp0';
  }

  @override
  String get confirmerEmailErreurVide =>
      'Enter the email address used to request the link.';

  @override
  String get confirmerEmailErreurLienInvalide =>
      'This link doesn\'t match this address, or it has expired.';

  @override
  String get confirmerEmailInstructions =>
      'Confirm your email address to finish signing in.';

  @override
  String get confirmerEmailBouton => 'Confirm';

  @override
  String get accueilPage1Titre => 'Vigie';

  @override
  String get accueilPage1Texte =>
      'Deadline tracking that stays confidential — for professions where every case matters.';

  @override
  String get accueilPage2Titre => 'Add';

  @override
  String get accueilPage2Texte =>
      'Create a case with a code name and a date, and let Vigie work out when to remind you.';

  @override
  String get accueilPage3Titre => 'Follow up';

  @override
  String get accueilPage3Texte =>
      'Vigie keeps reminding you until you confirm it\'s done — never a task forgotten in silence.';

  @override
  String get accueilPage4Titre => 'Review';

  @override
  String get accueilPage4Texte =>
      'A summary of your activity, case by case, to keep an overview.';

  @override
  String get accueilConfidentialiteNote =>
      'No real information about your cases is ever required — you choose your own code name for each one.';

  @override
  String get accueilBoutonPasser => 'Skip';

  @override
  String get accueilBoutonSuivant => 'Next';

  @override
  String get accueilBoutonSeConnecter => 'Sign in';

  @override
  String get connexionChampEmail => 'Email address';

  @override
  String get connexionErreurEmailInvalide => 'Enter a valid email address.';

  @override
  String get connexionErreurEnvoiLien =>
      'Couldn\'t send the link. Check your connection.';

  @override
  String connexionTelechargerAvecVersion(String version) {
    return 'Download the Android app (v$version)';
  }

  @override
  String get connexionTelechargerSansVersion =>
      'Download the Android app (recommended)';

  @override
  String get connexionVersionInstalleeMeilleure =>
      'The installed version works better than the website (notifications, Gmail...).';

  @override
  String get connexionInstructions =>
      'Enter your email address, you\'ll receive a sign-in link — no password needed.';

  @override
  String get connexionRecevoirLienBouton => 'Receive the sign-in link';

  @override
  String connexionLienEnvoye(String email) {
    return 'A link was sent to $email.\nOpen your mailbox and click the link to sign in.';
  }

  @override
  String get connexionMauvaiseAdresse => 'Wrong address? Start over';

  @override
  String get notificationsTitre => 'Notifications';

  @override
  String get notificationsAucunePourLInstant => 'No notifications yet.';

  @override
  String get notificationsAucunePourCeType => 'No notifications for this type.';

  @override
  String get notificationsFiltreTous => 'All';

  @override
  String notificationsChipTypeCompte(String type, int valeur) {
    return '$type: $valeur';
  }

  @override
  String get pourquoiVigieAppBarTitre => 'Why Vigie';

  @override
  String get pourquoiVigieTitre1 => 'Reminders that adapt, not a fixed message';

  @override
  String get pourquoiVigieTexte1 =>
      'The tone hardens with the delay — neutral, then firm, then urgent — instead of repeating the same sentence forever. An approaching deadline is flagged even without a delay.';

  @override
  String get pourquoiVigieTitre2 => 'Privacy by design';

  @override
  String get pourquoiVigieTexte2 =>
      'Cases are identified by code names you choose, never by real sensitive information — from the case name all the way to the log and the exported summary.';

  @override
  String get pourquoiVigieTitre3 => 'All your sources, one single review';

  @override
  String get pourquoiVigieTexte3 =>
      'Gmail, Google Tasks, and Google Calendar feed the same proposals screen, color-coded by origin — you choose what becomes a real case. The status of every check is visible, not a black box.';

  @override
  String get pourquoiVigieTitre4 => 'A summary that tells a story';

  @override
  String get pourquoiVigieTexte4 =>
      'Activity heat map, breakdown by case type, busiest day, completion rate, and a reliability indicator — not just raw counters.';

  @override
  String get pourquoiVigieTitre5 => 'A log, not checkboxes';

  @override
  String get pourquoiVigieTexte5 =>
      'Documents a case\'s progress step by step: each note is appended, nothing is ever overwritten — a real memory of the progress, not a simple status.';

  @override
  String get pourquoiVigieTitre6 => 'A report that\'s safe to share, by design';

  @override
  String get pourquoiVigieTexte6 =>
      'The summary exports in one click — and since everything is already in code names, there\'s never anything sensitive in it, wherever it\'s shared.';

  @override
  String get commonSupprimer => 'Delete';

  @override
  String get dossierDetailModifierTooltip => 'Edit the case';

  @override
  String get dossierDetailSupprimerTooltip => 'Delete the case';

  @override
  String dossierDetailDateAvecValeur(String date) {
    return 'Date: $date';
  }

  @override
  String get dossierDetailPasDeDate => 'No date given';

  @override
  String get dossierDetailTachesLieesTitre => 'Related tasks';

  @override
  String get dossierDetailAucuneTache => 'No tasks yet.';

  @override
  String get dossierDetailAjouterTacheBouton => 'Add a task';

  @override
  String get dossierDetailSupprimerDossierTitre => 'Delete this case?';

  @override
  String dossierDetailSupprimerDossierMessage(String nom) {
    return 'The case \"$nom\" and all its tasks will be permanently deleted.';
  }

  @override
  String dossierDetailNatureEtDate(String nature, String date) {
    return '$nature — $date';
  }

  @override
  String get dossierDetailConfirmerTitre => 'Confirm?';

  @override
  String get dossierDetailBasculerMarquerFait => 'mark this task as done';

  @override
  String get dossierDetailBasculerRemettreAFaire =>
      'set this task back to \"to do\"';

  @override
  String dossierDetailBasculerMessage(String action, String description) {
    return 'You want to $action: \"$description\".';
  }

  @override
  String get dossierDetailSupprimerTacheTitre => 'Delete this task?';

  @override
  String dossierDetailSupprimerTacheMessage(String description) {
    return '\"$description\" will be permanently deleted.';
  }

  @override
  String get dossierDetailAjouterTacheTitre => 'Add a task';

  @override
  String get dossierDetailModifierTacheTitre => 'Edit the task';

  @override
  String get dossierDetailDetailTacheLabel => 'Task detail';

  @override
  String get journalTypeAvancement => 'Progress';

  @override
  String get journalTypeBlocage => 'Blocker';

  @override
  String get journalTypeDecision => 'Decision';

  @override
  String get dossierDetailJournalTitre => 'Log';

  @override
  String get dossierDetailJournalDescription =>
      'Documents the case\'s progress step by step — each note is appended, nothing is overwritten. As with the case name, avoid writing actual sensitive information here.';

  @override
  String get dossierDetailJournalHint =>
      'E.g.: called X, waiting for their reply...';

  @override
  String get dossierDetailAjouterJournalBouton => 'Add to the log';

  @override
  String get dossierDetailBoutonDeverrouillerNotes => 'Unlock my notes';

  @override
  String get dossierDetailEntreeVerrouillee =>
      'Encrypted entry — unlock your notes to read it.';

  @override
  String get phraseSecreteTitreCreation => 'Protect your case notes';

  @override
  String get phraseSecreteTitreDeverrouillage => 'Unlock notes';

  @override
  String get phraseSecreteAvertissement =>
      'If you forget this password, these notes will be lost forever, for everyone — not even we can recover them. This is not your PIN — don\'t write it down anywhere on this phone.';

  @override
  String get phraseSecreteInstructionsDeverrouillage =>
      'Enter your password to view and write in this case\'s journal.';

  @override
  String get phraseSecreteChamp => 'Password';

  @override
  String get phraseSecreteChampConfirmation => 'Retype the password';

  @override
  String get phraseSecreteErreurTropCourte =>
      'Choose a password of at least 8 characters.';

  @override
  String get phraseSecreteErreurNeCorrespondentPas =>
      'The two passwords don\'t match.';

  @override
  String get phraseSecreteErreurIncorrecte => 'Incorrect password.';

  @override
  String get phraseSecreteErreurGenerique => 'Something went wrong. Try again.';

  @override
  String get phraseSecreteBoutonCreer => 'Create';

  @override
  String get phraseSecreteBoutonDeverrouiller => 'Unlock';

  @override
  String dossierDetailErreurAjoutJournal(String erreur) {
    return 'Couldn\'t add this entry: $erreur';
  }

  @override
  String dossierDetailErreurModifJournal(String erreur) {
    return 'Couldn\'t edit this entry: $erreur';
  }

  @override
  String get dossierDetailSupprimerEntreeTitre => 'Delete this log entry?';

  @override
  String dossierDetailSupprimerEntreeMessage(String date) {
    return 'This note from $date will be permanently deleted.';
  }

  @override
  String get dossierDetailModifierEntreeTitre => 'Edit this entry';

  @override
  String get dossierDetailHistoriqueTitre => 'History';

  @override
  String get dossierDetailAucuneEntree => 'No entries yet.';

  @override
  String get dossierDetailAucuneEntreeType => 'No entries of this type.';

  @override
  String dossierDetailErreurLectureJournal(String erreur) {
    return 'Couldn\'t read the log: $erreur';
  }

  @override
  String get dossierDetailHier => 'Yesterday';

  @override
  String get dossierDetailModifieSuffixe => '· edited';

  @override
  String get commonConfirmer => 'Confirm';

  @override
  String get commonTuEsSur => 'Are you sure?';

  @override
  String commonDerniereConfirmation(String message) {
    return 'Final confirmation: $message';
  }

  @override
  String get connexionGoogleAdresseInconnue =>
      'Connected account (reconnect to see the address)';
}
