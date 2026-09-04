import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @navATraiter.
  ///
  /// In fr, this message translates to:
  /// **'À traiter'**
  String get navATraiter;

  /// No description provided for @navAgenda.
  ///
  /// In fr, this message translates to:
  /// **'Agenda'**
  String get navAgenda;

  /// No description provided for @navBilan.
  ///
  /// In fr, this message translates to:
  /// **'Bilan'**
  String get navBilan;

  /// No description provided for @navProfil.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfil;

  /// No description provided for @professionMedecin.
  ///
  /// In fr, this message translates to:
  /// **'Médecin / Professionnel de santé'**
  String get professionMedecin;

  /// No description provided for @professionEnseignant.
  ///
  /// In fr, this message translates to:
  /// **'Enseignant / Professeur'**
  String get professionEnseignant;

  /// No description provided for @professionAvocatJuriste.
  ///
  /// In fr, this message translates to:
  /// **'Avocat / Juriste'**
  String get professionAvocatJuriste;

  /// No description provided for @professionMagistrat.
  ///
  /// In fr, this message translates to:
  /// **'Magistrat'**
  String get professionMagistrat;

  /// No description provided for @professionComptable.
  ///
  /// In fr, this message translates to:
  /// **'Comptable / Expert-comptable'**
  String get professionComptable;

  /// No description provided for @professionConsultant.
  ///
  /// In fr, this message translates to:
  /// **'Consultant / Indépendant'**
  String get professionConsultant;

  /// No description provided for @professionCommercial.
  ///
  /// In fr, this message translates to:
  /// **'Commercial / Chargé de clientèle'**
  String get professionCommercial;

  /// No description provided for @professionArchitecteIngenieur.
  ///
  /// In fr, this message translates to:
  /// **'Architecte / Ingénieur'**
  String get professionArchitecteIngenieur;

  /// No description provided for @professionAgentImmobilier.
  ///
  /// In fr, this message translates to:
  /// **'Agent immobilier'**
  String get professionAgentImmobilier;

  /// No description provided for @professionArtisanBatiment.
  ///
  /// In fr, this message translates to:
  /// **'Artisan / Entrepreneur du bâtiment'**
  String get professionArtisanBatiment;

  /// No description provided for @professionBeauteBienEtre.
  ///
  /// In fr, this message translates to:
  /// **'Coiffeur / Esthéticienne / Bien-être'**
  String get professionBeauteBienEtre;

  /// No description provided for @professionEntrepreneur.
  ///
  /// In fr, this message translates to:
  /// **'Entrepreneur / Chef d\'entreprise'**
  String get professionEntrepreneur;

  /// No description provided for @professionAutre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get professionAutre;

  /// No description provided for @joursAvant.
  ///
  /// In fr, this message translates to:
  /// **'{jours} jours avant'**
  String joursAvant(int jours);

  /// No description provided for @profilPreciseProfessionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Précise ta profession'**
  String get profilPreciseProfessionLabel;

  /// No description provided for @onboardingBienvenue.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue !'**
  String get onboardingBienvenue;

  /// No description provided for @onboardingSousTitre.
  ///
  /// In fr, this message translates to:
  /// **'Quelques infos pour personnaliser ton assistant.'**
  String get onboardingSousTitre;

  /// No description provided for @onboardingChampPrenom.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get onboardingChampPrenom;

  /// No description provided for @onboardingChampPseudo.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo (comment l\'app t\'appelle)'**
  String get onboardingChampPseudo;

  /// No description provided for @onboardingChampProfession.
  ///
  /// In fr, this message translates to:
  /// **'Ta profession'**
  String get onboardingChampProfession;

  /// No description provided for @onboardingNoteNaturesPreremplies.
  ///
  /// In fr, this message translates to:
  /// **'On pré-remplira des types de dossier adaptés à ton métier — modifiables ensuite.'**
  String get onboardingNoteNaturesPreremplies;

  /// No description provided for @onboardingChampDelaiRappel.
  ///
  /// In fr, this message translates to:
  /// **'Être prévenu combien de jours à l\'avance ?'**
  String get onboardingChampDelaiRappel;

  /// No description provided for @onboardingBoutonCommencer.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingBoutonCommencer;

  /// No description provided for @onboardingErreurPrenomPseudo.
  ///
  /// In fr, this message translates to:
  /// **'Renseigne au moins ton prénom et un pseudo.'**
  String get onboardingErreurPrenomPseudo;

  /// No description provided for @onboardingErreurProfession.
  ///
  /// In fr, this message translates to:
  /// **'Précise le nom de ta profession.'**
  String get onboardingErreurProfession;

  /// No description provided for @onboardingErreurConnexion.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer. Vérifie ta connexion.'**
  String get onboardingErreurConnexion;

  /// No description provided for @commonAnnuler.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonAnnuler;

  /// No description provided for @commonContinuer.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get commonContinuer;

  /// No description provided for @commonEnregistrer.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commonEnregistrer;

  /// No description provided for @profilTitre.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profilTitre;

  /// No description provided for @profilPourquoiVigieTitre.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi Vigie ?'**
  String get profilPourquoiVigieTitre;

  /// No description provided for @profilPourquoiVigieSousTitre.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui rend Vigie différent'**
  String get profilPourquoiVigieSousTitre;

  /// No description provided for @profilConnecteEnTantQue.
  ///
  /// In fr, this message translates to:
  /// **'Connecté en tant que {email}'**
  String profilConnecteEnTantQue(String email);

  /// No description provided for @profilEmailInconnu.
  ///
  /// In fr, this message translates to:
  /// **'inconnu'**
  String get profilEmailInconnu;

  /// No description provided for @profilPseudoNonDefini.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo non défini'**
  String get profilPseudoNonDefini;

  /// No description provided for @profilProfessionNonDefinie.
  ///
  /// In fr, this message translates to:
  /// **'Profession non définie'**
  String get profilProfessionNonDefinie;

  /// No description provided for @profilDelaiRappelTitre.
  ///
  /// In fr, this message translates to:
  /// **'Délai de rappel'**
  String get profilDelaiRappelTitre;

  /// No description provided for @profilDelaiRappelSousTitre.
  ///
  /// In fr, this message translates to:
  /// **'{jours} jours avant l\'échéance'**
  String profilDelaiRappelSousTitre(int jours);

  /// No description provided for @profilTypesDossierTitre.
  ///
  /// In fr, this message translates to:
  /// **'Mes types de dossier'**
  String get profilTypesDossierTitre;

  /// No description provided for @profilTypesDossierSousTitre.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter ou supprimer tes catégories personnalisées'**
  String get profilTypesDossierSousTitre;

  /// No description provided for @profilThemeTitre.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get profilThemeTitre;

  /// No description provided for @profilThemeSousTitre.
  ///
  /// In fr, this message translates to:
  /// **'Couleur et mode clair/sombre'**
  String get profilThemeSousTitre;

  /// No description provided for @profilLangueTitre.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get profilLangueTitre;

  /// No description provided for @profilLangueSousTitre.
  ///
  /// In fr, this message translates to:
  /// **'Français / English'**
  String get profilLangueSousTitre;

  /// No description provided for @profilThemeCouleurLabel.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get profilThemeCouleurLabel;

  /// No description provided for @profilThemeModeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mode'**
  String get profilThemeModeLabel;

  /// No description provided for @profilThemeModeSysteme.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get profilThemeModeSysteme;

  /// No description provided for @profilThemeModeClair.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get profilThemeModeClair;

  /// No description provided for @profilThemeModeSombre.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get profilThemeModeSombre;

  /// No description provided for @couleurIndigo.
  ///
  /// In fr, this message translates to:
  /// **'Indigo'**
  String get couleurIndigo;

  /// No description provided for @couleurBleu.
  ///
  /// In fr, this message translates to:
  /// **'Bleu'**
  String get couleurBleu;

  /// No description provided for @couleurSarcelle.
  ///
  /// In fr, this message translates to:
  /// **'Sarcelle'**
  String get couleurSarcelle;

  /// No description provided for @couleurVert.
  ///
  /// In fr, this message translates to:
  /// **'Vert'**
  String get couleurVert;

  /// No description provided for @couleurViolet.
  ///
  /// In fr, this message translates to:
  /// **'Violet'**
  String get couleurViolet;

  /// No description provided for @couleurOrange.
  ///
  /// In fr, this message translates to:
  /// **'Orange'**
  String get couleurOrange;

  /// No description provided for @profilAutomatisationTitre.
  ///
  /// In fr, this message translates to:
  /// **'Automatisation'**
  String get profilAutomatisationTitre;

  /// No description provided for @profilAutomatisationAucunCompte.
  ///
  /// In fr, this message translates to:
  /// **'Connecter un compte Google pour détecter les dates automatiquement'**
  String get profilAutomatisationAucunCompte;

  /// No description provided for @profilAutomatisationUnCompte.
  ///
  /// In fr, this message translates to:
  /// **'1 compte Google connecté'**
  String get profilAutomatisationUnCompte;

  /// No description provided for @profilAutomatisationDeuxComptes.
  ///
  /// In fr, this message translates to:
  /// **'2 comptes Google connectés'**
  String get profilAutomatisationDeuxComptes;

  /// No description provided for @profilSeDeconnecterTitre.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get profilSeDeconnecterTitre;

  /// No description provided for @profilSupprimerCompteTitre.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get profilSupprimerCompteTitre;

  /// No description provided for @profilSeDeconnecterConfirmationTitre.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter ?'**
  String get profilSeDeconnecterConfirmationTitre;

  /// No description provided for @profilSeDeconnecterConfirmationMessage.
  ///
  /// In fr, this message translates to:
  /// **'Tu devras te reconnecter par email pour rouvrir l\'app.'**
  String get profilSeDeconnecterConfirmationMessage;

  /// No description provided for @profilSupprimerCompteMessage1.
  ///
  /// In fr, this message translates to:
  /// **'Tous tes dossiers et toutes tes tâches seront supprimés définitivement. Il n\'y a aucun moyen de les récupérer ensuite.'**
  String get profilSupprimerCompteMessage1;

  /// No description provided for @profilSupprimerCompteMessage2.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte de connexion sera lui aussi supprimé — tu ne pourras plus te reconnecter avec cet email sans recréer un compte, vide, à zéro.'**
  String get profilSupprimerCompteMessage2;

  /// No description provided for @profilSupprimerCompteMessage3.
  ///
  /// In fr, this message translates to:
  /// **'Dernière alerte : cette action est irréversible et immédiate. Es-tu vraiment certain de vouloir supprimer ton compte ?'**
  String get profilSupprimerCompteMessage3;

  /// No description provided for @profilSupprimerCompteDialogueTitre.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get profilSupprimerCompteDialogueTitre;

  /// No description provided for @profilModifierPseudoTitre.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le pseudo'**
  String get profilModifierPseudoTitre;

  /// No description provided for @profilPseudoLabel.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo'**
  String get profilPseudoLabel;

  /// No description provided for @profilModifierProfessionTitre.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la profession'**
  String get profilModifierProfessionTitre;

  /// No description provided for @creerPinErreurTropCourt.
  ///
  /// In fr, this message translates to:
  /// **'Le code doit faire au moins 4 chiffres.'**
  String get creerPinErreurTropCourt;

  /// No description provided for @creerPinErreurNeCorrespondentPas.
  ///
  /// In fr, this message translates to:
  /// **'Les deux codes ne correspondent pas.'**
  String get creerPinErreurNeCorrespondentPas;

  /// No description provided for @creerPinInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Crée un code PIN pour protéger l\'app.\nÀ chaque ouverture, ce code (ou ton empreinte/Face ID) sera demandé.'**
  String get creerPinInstructions;

  /// No description provided for @creerPinChampNouveauCode.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code PIN'**
  String get creerPinChampNouveauCode;

  /// No description provided for @creerPinChampRetaperCode.
  ///
  /// In fr, this message translates to:
  /// **'Retape le code'**
  String get creerPinChampRetaperCode;

  /// No description provided for @creerPinBoutonValider.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get creerPinBoutonValider;

  /// No description provided for @verrouCodeIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect.'**
  String get verrouCodeIncorrect;

  /// No description provided for @verrouTropDeTentatives.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais. Réessaie dans {secondes} s.'**
  String verrouTropDeTentatives(int secondes);

  /// No description provided for @verrouCodeOublieTitre.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN oublié ?'**
  String get verrouCodeOublieTitre;

  /// No description provided for @verrouCodeOublieMessage.
  ///
  /// In fr, this message translates to:
  /// **'Tu vas devoir te reconnecter par email pour prouver que c\'est bien toi, puis créer un nouveau code. Tes dossiers et tâches ne seront pas touchés.'**
  String get verrouCodeOublieMessage;

  /// No description provided for @verrouConfirmeIdentite.
  ///
  /// In fr, this message translates to:
  /// **'Confirme ton identité, ou entre ton code PIN.'**
  String get verrouConfirmeIdentite;

  /// No description provided for @verrouEntreCodePin.
  ///
  /// In fr, this message translates to:
  /// **'Entre ton code PIN pour ouvrir l\'app.'**
  String get verrouEntreCodePin;

  /// No description provided for @verrouChampCodePin.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN'**
  String get verrouChampCodePin;

  /// No description provided for @verrouBoutonDeverrouiller.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller'**
  String get verrouBoutonDeverrouiller;

  /// No description provided for @verrouReessayerBiometrie.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer avec l\'empreinte / Face ID'**
  String get verrouReessayerBiometrie;

  /// No description provided for @natureChampNouveauType.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau type (ex: Consultation)'**
  String get natureChampNouveauType;

  /// No description provided for @natureBoutonAjouter.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter ce type'**
  String get natureBoutonAjouter;

  /// No description provided for @creationDossierTitre.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à un dossier'**
  String get creationDossierTitre;

  /// No description provided for @creationDossierChampNomCode.
  ///
  /// In fr, this message translates to:
  /// **'Nom de code'**
  String get creationDossierChampNomCode;

  /// No description provided for @creationDossierExempleNomCode.
  ///
  /// In fr, this message translates to:
  /// **'ex : Dossier Alpha'**
  String get creationDossierExempleNomCode;

  /// No description provided for @creationDossierChampType.
  ///
  /// In fr, this message translates to:
  /// **'Type de dossier'**
  String get creationDossierChampType;

  /// No description provided for @creationDossierNotesTitre.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get creationDossierNotesTitre;

  /// No description provided for @creationDossierChampResteAVerifier.
  ///
  /// In fr, this message translates to:
  /// **'Reste à vérifier'**
  String get creationDossierChampResteAVerifier;

  /// No description provided for @creationDossierChampEnAttenteDe.
  ///
  /// In fr, this message translates to:
  /// **'En attente de'**
  String get creationDossierChampEnAttenteDe;

  /// No description provided for @creationDossierChampAutre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get creationDossierChampAutre;

  /// No description provided for @creationDossierAvertissementSensible.
  ///
  /// In fr, this message translates to:
  /// **'Comme pour le nom du dossier, évite d\'écrire de vraies informations sensibles ici.'**
  String get creationDossierAvertissementSensible;

  /// No description provided for @creationDossierBoutonCreer.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get creationDossierBoutonCreer;

  /// No description provided for @commonFermer.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get commonFermer;

  /// No description provided for @banniereNouvelleVersionAvecNumero.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle version disponible ({version}).'**
  String banniereNouvelleVersionAvecNumero(String version);

  /// No description provided for @banniereNouvelleVersionSansNumero.
  ///
  /// In fr, this message translates to:
  /// **'Une nouvelle version de l\'app est disponible.'**
  String get banniereNouvelleVersionSansNumero;

  /// No description provided for @banniereInstructionTelechargement.
  ///
  /// In fr, this message translates to:
  /// **'Va sur vigie.pentalightcode.com pour la télécharger.'**
  String get banniereInstructionTelechargement;

  /// No description provided for @banniereIgnorerTitre.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer cette mise à jour ?'**
  String get banniereIgnorerTitre;

  /// No description provided for @banniereIgnorerMessage.
  ///
  /// In fr, this message translates to:
  /// **'La bannière réapparaîtra au prochain lancement de l\'app tant que tu n\'auras pas mis à jour.'**
  String get banniereIgnorerMessage;

  /// No description provided for @banniereIgnorerBouton.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get banniereIgnorerBouton;

  /// No description provided for @aTraiterNotificationsTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get aTraiterNotificationsTooltip;

  /// No description provided for @aTraiterPropositionsTooltip.
  ///
  /// In fr, this message translates to:
  /// **'{nombre} proposition(s) de dossier à valider'**
  String aTraiterPropositionsTooltip(int nombre);

  /// No description provided for @aTraiterErreur.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {erreur}'**
  String aTraiterErreur(String erreur);

  /// No description provided for @aTraiterRienAFaire.
  ///
  /// In fr, this message translates to:
  /// **'Rien à faire pour l\'instant.'**
  String get aTraiterRienAFaire;

  /// No description provided for @aTraiterEnAttenteTitre.
  ///
  /// In fr, this message translates to:
  /// **'En attente (pas encore actif)'**
  String get aTraiterEnAttenteTitre;

  /// No description provided for @aTraiterEnAttenteExplication.
  ///
  /// In fr, this message translates to:
  /// **'Ces dossiers existent déjà — inutile de les recréer. Ils passeront automatiquement dans la liste ci-dessus quand leur moment arrivera.'**
  String get aTraiterEnAttenteExplication;

  /// No description provided for @aTraiterAjouterTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get aTraiterAjouterTooltip;

  /// No description provided for @aTraiterProgressionDossier.
  ///
  /// In fr, this message translates to:
  /// **'{faites}/{total} tâches faites ({pourcentage}%)'**
  String aTraiterProgressionDossier(int faites, int total, int pourcentage);

  /// No description provided for @aTraiterEnAttenteEcheance.
  ///
  /// In fr, this message translates to:
  /// **'Échéance le {date} — apparaîtra dans \"À traiter\" dans {jours} jours'**
  String aTraiterEnAttenteEcheance(String date, int jours);

  /// No description provided for @aTraiterEnRetard.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get aTraiterEnRetard;

  /// No description provided for @aTraiterAujourdhui.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get aTraiterAujourdhui;

  /// No description provided for @aTraiterDemain.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get aTraiterDemain;

  /// No description provided for @aTraiterDansJours.
  ///
  /// In fr, this message translates to:
  /// **'Dans {jours} j'**
  String aTraiterDansJours(int jours);

  /// No description provided for @aTraiterCestFait.
  ///
  /// In fr, this message translates to:
  /// **'C\'est fait'**
  String get aTraiterCestFait;

  /// No description provided for @aTraiterMarquerFaitTitre.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme fait ?'**
  String get aTraiterMarquerFaitTitre;

  /// No description provided for @aTraiterMarquerFaitMessage.
  ///
  /// In fr, this message translates to:
  /// **'\"{description}\" sera marquée comme faite.'**
  String aTraiterMarquerFaitMessage(String description);

  /// No description provided for @agendaErreurLecture.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire le calendrier : {erreur}'**
  String agendaErreurLecture(String erreur);

  /// No description provided for @agendaAucunCompteConnecte.
  ///
  /// In fr, this message translates to:
  /// **'Connecte d\'abord un compte Google dans Automatisation pour voir ton agenda ici.'**
  String get agendaAucunCompteConnecte;

  /// No description provided for @agendaAjouterTache.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une tâche'**
  String get agendaAjouterTache;

  /// No description provided for @agendaRienCeJour.
  ///
  /// In fr, this message translates to:
  /// **'Rien le {date}.'**
  String agendaRienCeJour(String date);

  /// No description provided for @agendaJourneeEntiere.
  ///
  /// In fr, this message translates to:
  /// **'Journée entière'**
  String get agendaJourneeEntiere;

  /// No description provided for @bilanPeriodeSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get bilanPeriodeSemaine;

  /// No description provided for @bilanPeriodeMois.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get bilanPeriodeMois;

  /// No description provided for @bilanPeriodeTrimestre.
  ///
  /// In fr, this message translates to:
  /// **'Trimestre'**
  String get bilanPeriodeTrimestre;

  /// No description provided for @bilanPeriodeSemestre.
  ///
  /// In fr, this message translates to:
  /// **'Semestre'**
  String get bilanPeriodeSemestre;

  /// No description provided for @bilanPeriodeAnnee.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get bilanPeriodeAnnee;

  /// No description provided for @bilanLibellePeriodeTrimestre.
  ///
  /// In fr, this message translates to:
  /// **'T{numero} {annee}'**
  String bilanLibellePeriodeTrimestre(int numero, int annee);

  /// No description provided for @bilanLibellePeriodeSemestre.
  ///
  /// In fr, this message translates to:
  /// **'S{numero} {annee}'**
  String bilanLibellePeriodeSemestre(int numero, int annee);

  /// No description provided for @bilanPartagerTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Partager ce bilan'**
  String get bilanPartagerTooltip;

  /// No description provided for @bilanRienAAfficher.
  ///
  /// In fr, this message translates to:
  /// **'Rien à afficher pour l\'instant.'**
  String get bilanRienAAfficher;

  /// No description provided for @bilanFait.
  ///
  /// In fr, this message translates to:
  /// **'Fait'**
  String get bilanFait;

  /// No description provided for @bilanEnRetard.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get bilanEnRetard;

  /// No description provided for @bilanAVenir.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get bilanAVenir;

  /// No description provided for @bilanNoteEnRetardPeriodePassee.
  ///
  /// In fr, this message translates to:
  /// **'\"En retard\" n\'est affiché que sur la période en cours — ça n\'a pas de sens pour une période déjà passée.'**
  String get bilanNoteEnRetardPeriodePassee;

  /// No description provided for @bilanStatistiquesTitre.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get bilanStatistiquesTitre;

  /// No description provided for @bilanResumeIaTitre.
  ///
  /// In fr, this message translates to:
  /// **'Résumé & recommandations'**
  String get bilanResumeIaTitre;

  /// No description provided for @bilanResumeIaDesactiverTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get bilanResumeIaDesactiverTooltip;

  /// No description provided for @bilanResumeIaDescription.
  ///
  /// In fr, this message translates to:
  /// **'Un résumé et des recommandations générés par une IA (Groq), à partir des mêmes chiffres anonymisés que le partage du Bilan — désactivé par défaut.'**
  String get bilanResumeIaDescription;

  /// No description provided for @bilanResumeIaActiverBouton.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get bilanResumeIaActiverBouton;

  /// No description provided for @bilanResumeIaGenererBouton.
  ///
  /// In fr, this message translates to:
  /// **'Générer'**
  String get bilanResumeIaGenererBouton;

  /// No description provided for @bilanResumeIaRegenererBouton.
  ///
  /// In fr, this message translates to:
  /// **'Régénérer'**
  String get bilanResumeIaRegenererBouton;

  /// No description provided for @bilanResumeIaConfirmationTitre.
  ///
  /// In fr, this message translates to:
  /// **'Avant d\'activer le résumé IA'**
  String get bilanResumeIaConfirmationTitre;

  /// No description provided for @bilanResumeIaConfirmationMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le texte du Bilan (chiffres et noms de code, jamais de vraies informations — le même contenu déjà utilisé pour le partage) est envoyé à un service d\'intelligence artificielle tiers (Groq) pour générer un résumé.'**
  String get bilanResumeIaConfirmationMessage;

  /// No description provided for @bilanResumeIaErreurGeneration.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer le résumé : {erreur}'**
  String bilanResumeIaErreurGeneration(String erreur);

  /// No description provided for @bilanTexteEnTete.
  ///
  /// In fr, this message translates to:
  /// **'Bilan Vigie — {periode}'**
  String bilanTexteEnTete(String periode);

  /// No description provided for @bilanTexteTotalAvecRetard.
  ///
  /// In fr, this message translates to:
  /// **'Total : {fait} fait, {enRetard} en retard, {aVenir} à venir'**
  String bilanTexteTotalAvecRetard(int fait, int enRetard, int aVenir);

  /// No description provided for @bilanTexteTotalSansRetard.
  ///
  /// In fr, this message translates to:
  /// **'Total : {fait} fait, {aVenir} à venir'**
  String bilanTexteTotalSansRetard(int fait, int aVenir);

  /// No description provided for @bilanTexteDossierAvecRetard.
  ///
  /// In fr, this message translates to:
  /// **'{nom} : {fait} fait, {enRetard} en retard, {aVenir} à venir'**
  String bilanTexteDossierAvecRetard(
    String nom,
    int fait,
    int enRetard,
    int aVenir,
  );

  /// No description provided for @bilanTexteDossierSansRetard.
  ///
  /// In fr, this message translates to:
  /// **'{nom} : {fait} fait, {aVenir} à venir'**
  String bilanTexteDossierSansRetard(String nom, int fait, int aVenir);

  /// No description provided for @bilanTextePartageSignature.
  ///
  /// In fr, this message translates to:
  /// **'Généré par Vigie — noms de code choisis par l\'utilisateur, aucune information sensible.'**
  String get bilanTextePartageSignature;

  /// No description provided for @statistiquesAucuneTacheEnRetard.
  ///
  /// In fr, this message translates to:
  /// **'Aucune tâche terminée en retard pour l\'instant.'**
  String get statistiquesAucuneTacheEnRetard;

  /// No description provided for @statistiquesJoursSansRetard.
  ///
  /// In fr, this message translates to:
  /// **'{jours} jour(s) sans tâche terminée en retard.'**
  String statistiquesJoursSansRetard(int jours);

  /// No description provided for @statistiquesRienSurPeriode.
  ///
  /// In fr, this message translates to:
  /// **'Rien sur cette période.'**
  String get statistiquesRienSurPeriode;

  /// No description provided for @statistiquesTauxAchevement.
  ///
  /// In fr, this message translates to:
  /// **'{pourcentage}% de taux d\'achèvement'**
  String statistiquesTauxAchevement(int pourcentage);

  /// No description provided for @statistiquesRepartitionParType.
  ///
  /// In fr, this message translates to:
  /// **'Répartition par type'**
  String get statistiquesRepartitionParType;

  /// No description provided for @statistiquesTachesParJour.
  ///
  /// In fr, this message translates to:
  /// **'Tâches terminées par jour de la semaine'**
  String get statistiquesTachesParJour;

  /// No description provided for @statistiquesActiviteSemaines.
  ///
  /// In fr, this message translates to:
  /// **'Activité des 12 dernières semaines'**
  String get statistiquesActiviteSemaines;

  /// No description provided for @statistiquesTooltipJour.
  ///
  /// In fr, this message translates to:
  /// **'{jour}/{mois} : {compte} tâche(s)'**
  String statistiquesTooltipJour(int jour, int mois, int compte);

  /// No description provided for @automatisationComptesGoogleTitre.
  ///
  /// In fr, this message translates to:
  /// **'Comptes Google'**
  String get automatisationComptesGoogleTitre;

  /// No description provided for @automatisationComptesGoogleDescription.
  ///
  /// In fr, this message translates to:
  /// **'Connecte autant de comptes que tu veux (perso, secondaire...) — donne-leur un nom pour t\'y retrouver, si tu veux.'**
  String get automatisationComptesGoogleDescription;

  /// No description provided for @automatisationConnecterCompte.
  ///
  /// In fr, this message translates to:
  /// **'Connecter un compte Google'**
  String get automatisationConnecterCompte;

  /// No description provided for @automatisationConnecterAutreCompte.
  ///
  /// In fr, this message translates to:
  /// **'Connecter un autre compte'**
  String get automatisationConnecterAutreCompte;

  /// No description provided for @automatisationPropositionsAValiderAvecNombre.
  ///
  /// In fr, this message translates to:
  /// **'Propositions à valider ({nombre})'**
  String automatisationPropositionsAValiderAvecNombre(int nombre);

  /// No description provided for @automatisationPropositionsAValider.
  ///
  /// In fr, this message translates to:
  /// **'Propositions à valider'**
  String get automatisationPropositionsAValider;

  /// No description provided for @automatisationCompteConnecte.
  ///
  /// In fr, this message translates to:
  /// **'Compte connecté : {email}'**
  String automatisationCompteConnecte(String email);

  /// No description provided for @automatisationConnexionImpossible.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible : {erreur}'**
  String automatisationConnexionImpossible(String erreur);

  /// No description provided for @automatisationDeconnecterTitre.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter ce compte Google ?'**
  String get automatisationDeconnecterTitre;

  /// No description provided for @automatisationDeconnecterMessage.
  ///
  /// In fr, this message translates to:
  /// **'\"{compte}\" ne sera plus scanné automatiquement (emails, tâches, agenda).'**
  String automatisationDeconnecterMessage(String compte);

  /// No description provided for @automatisationRenommerTitre.
  ///
  /// In fr, this message translates to:
  /// **'Renommer ce compte'**
  String get automatisationRenommerTitre;

  /// No description provided for @automatisationRenommerChampNom.
  ///
  /// In fr, this message translates to:
  /// **'Nom (facultatif)'**
  String get automatisationRenommerChampNom;

  /// No description provided for @automatisationRenommerTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get automatisationRenommerTooltip;

  /// No description provided for @automatisationDeconnecterTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter'**
  String get automatisationDeconnecterTooltip;

  /// No description provided for @automatisationMethodeTitre.
  ///
  /// In fr, this message translates to:
  /// **'Méthode d\'extraction des dates'**
  String get automatisationMethodeTitre;

  /// No description provided for @automatisationMethodeMotifTitre.
  ///
  /// In fr, this message translates to:
  /// **'Recherche de motif (recommandé)'**
  String get automatisationMethodeMotifTitre;

  /// No description provided for @automatisationMethodeMotifDescription.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit — reste entièrement dans nos serveurs, rien envoyé ailleurs.'**
  String get automatisationMethodeMotifDescription;

  /// No description provided for @automatisationMethodeIaTitre.
  ///
  /// In fr, this message translates to:
  /// **'Intelligence artificielle'**
  String get automatisationMethodeIaTitre;

  /// No description provided for @automatisationMethodeIaDescription.
  ///
  /// In fr, this message translates to:
  /// **'Plus fiable sur des emails mal formatés — voir les risques avant d\'activer.'**
  String get automatisationMethodeIaDescription;

  /// No description provided for @automatisationAvantActiverIaTitre.
  ///
  /// In fr, this message translates to:
  /// **'Avant d\'activer l\'IA'**
  String get automatisationAvantActiverIaTitre;

  /// No description provided for @automatisationAvantActiverIaMessage.
  ///
  /// In fr, this message translates to:
  /// **'Avec cette option, le contenu complet de chaque email reçu d\'un expéditeur de confiance est envoyé à un service d\'intelligence artificielle tiers pour y être lu — pas seulement la date trouvée. Pour des emails judiciaires réels, c\'est une exposition à prendre au sérieux. La recherche de motif (option recommandée) ne fait jamais sortir aucune donnée de nos serveurs.'**
  String get automatisationAvantActiverIaMessage;

  /// No description provided for @automatisationActiverQuandMeme.
  ///
  /// In fr, this message translates to:
  /// **'Activer quand même'**
  String get automatisationActiverQuandMeme;

  /// No description provided for @automatisationExpediteursTitre.
  ///
  /// In fr, this message translates to:
  /// **'Expéditeurs favoris'**
  String get automatisationExpediteursTitre;

  /// No description provided for @automatisationExpediteursDescription.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les emails venant de ces adresses seront lus (ex : celle du tribunal).'**
  String get automatisationExpediteursDescription;

  /// No description provided for @automatisationChoisirDepuisBoite.
  ///
  /// In fr, this message translates to:
  /// **'Choisir depuis ma boîte mail'**
  String get automatisationChoisirDepuisBoite;

  /// No description provided for @automatisationOuAjouteManuellement.
  ///
  /// In fr, this message translates to:
  /// **'Ou ajoute une adresse manuellement :'**
  String get automatisationOuAjouteManuellement;

  /// No description provided for @automatisationChampAdresseEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get automatisationChampAdresseEmail;

  /// No description provided for @automatisationAucunExpediteur.
  ///
  /// In fr, this message translates to:
  /// **'Aucun expéditeur ajouté pour l\'instant.'**
  String get automatisationAucunExpediteur;

  /// No description provided for @automatisationRetirerTitre.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cet expéditeur ?'**
  String get automatisationRetirerTitre;

  /// No description provided for @automatisationRetirerMessage.
  ///
  /// In fr, this message translates to:
  /// **'Les emails de \"{email}\" ne seront plus lus automatiquement.'**
  String automatisationRetirerMessage(String email);

  /// No description provided for @automatisationRetirerBouton.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get automatisationRetirerBouton;

  /// No description provided for @automatisationAdresseInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email invalide.'**
  String get automatisationAdresseInvalide;

  /// No description provided for @automatisationDomaineIntrouvableTitre.
  ///
  /// In fr, this message translates to:
  /// **'Ce domaine semble introuvable'**
  String get automatisationDomaineIntrouvableTitre;

  /// No description provided for @automatisationDomaineIntrouvableMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun serveur mail trouvé pour \"{domaine}\" — vérifie qu\'il n\'y a pas de faute de frappe.\n\nAjouter quand même : {email} ?'**
  String automatisationDomaineIntrouvableMessage(String domaine, String email);

  /// No description provided for @automatisationAjouterQuandMeme.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter quand même'**
  String get automatisationAjouterQuandMeme;

  /// No description provided for @automatisationAjouterExpediteurTitre.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter cet expéditeur ?'**
  String get automatisationAjouterExpediteurTitre;

  /// No description provided for @automatisationAjouterExpediteurMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie bien qu\'il n\'y a pas de faute de frappe :\n\n{email}'**
  String automatisationAjouterExpediteurMessage(String email);

  /// No description provided for @automatisationAjouterBouton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get automatisationAjouterBouton;

  /// No description provided for @automatisationErreurLectureBoite.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire la boîte mail : {erreur}'**
  String automatisationErreurLectureBoite(String erreur);

  /// No description provided for @automatisationAucunNouvelExpediteur.
  ///
  /// In fr, this message translates to:
  /// **'Aucun nouvel expéditeur trouvé dans les emails récents.'**
  String get automatisationAucunNouvelExpediteur;

  /// No description provided for @automatisationExpediteursTrouvesTitre.
  ///
  /// In fr, this message translates to:
  /// **'Expéditeurs trouvés'**
  String get automatisationExpediteursTrouvesTitre;

  /// No description provided for @automatisationCocheConfiance.
  ///
  /// In fr, this message translates to:
  /// **'Coche ceux à qui tu fais confiance (ex : le tribunal).'**
  String get automatisationCocheConfiance;

  /// No description provided for @automatisationEmailsRecents.
  ///
  /// In fr, this message translates to:
  /// **'{nombre} email(s) récent(s)'**
  String automatisationEmailsRecents(int nombre);

  /// No description provided for @automatisationAjouterAvecNombre.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter ({nombre})'**
  String automatisationAjouterAvecNombre(int nombre);

  /// No description provided for @automatisationVerificationAutoTitre.
  ///
  /// In fr, this message translates to:
  /// **'Vérification automatique'**
  String get automatisationVerificationAutoTitre;

  /// No description provided for @automatisationEtatPasEncoreVerifie.
  ///
  /// In fr, this message translates to:
  /// **'{service} : pas encore vérifié'**
  String automatisationEtatPasEncoreVerifie(String service);

  /// No description provided for @automatisationEtatAvecDate.
  ///
  /// In fr, this message translates to:
  /// **'{service} : {statut} — {date}'**
  String automatisationEtatAvecDate(String service, String statut, String date);

  /// No description provided for @automatisationEtatSansDate.
  ///
  /// In fr, this message translates to:
  /// **'{service} : {statut}'**
  String automatisationEtatSansDate(String service, String statut);

  /// No description provided for @automatisationEtatOk.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get automatisationEtatOk;

  /// No description provided for @automatisationEtatErreur.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get automatisationEtatErreur;

  /// No description provided for @propositionsTitre.
  ///
  /// In fr, this message translates to:
  /// **'Propositions'**
  String get propositionsTitre;

  /// No description provided for @propositionsAucunePourLInstant.
  ///
  /// In fr, this message translates to:
  /// **'Aucune proposition pour l\'instant. Dès qu\'une date sera trouvée dans un email, une tâche Google Tasks ou un événement Google Calendar, elle apparaîtra ici.'**
  String get propositionsAucunePourLInstant;

  /// No description provided for @propositionsFiltreTout.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get propositionsFiltreTout;

  /// No description provided for @propositionsDateInconnue.
  ///
  /// In fr, this message translates to:
  /// **'Date inconnue'**
  String get propositionsDateInconnue;

  /// No description provided for @propositionsDeExpediteur.
  ///
  /// In fr, this message translates to:
  /// **'De : {expediteur}'**
  String propositionsDeExpediteur(String expediteur);

  /// No description provided for @propositionsIgnorerBouton.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get propositionsIgnorerBouton;

  /// No description provided for @propositionsCreerDossierBouton.
  ///
  /// In fr, this message translates to:
  /// **'Créer le dossier'**
  String get propositionsCreerDossierBouton;

  /// No description provided for @propositionsIgnorerTitre.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer cette proposition ?'**
  String get propositionsIgnorerTitre;

  /// No description provided for @propositionsIgnorerMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun dossier ne sera créé pour \"{sujet}\".'**
  String propositionsIgnorerMessage(String sujet);

  /// No description provided for @ajouterErreurNomCode.
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom de code au dossier.'**
  String get ajouterErreurNomCode;

  /// No description provided for @ajouterErreurNature.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une nature de dossier.'**
  String get ajouterErreurNature;

  /// No description provided for @ajouterDossierAjoute.
  ///
  /// In fr, this message translates to:
  /// **'Dossier ajouté.'**
  String get ajouterDossierAjoute;

  /// No description provided for @ajouterTitre.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un dossier'**
  String get ajouterTitre;

  /// No description provided for @ajouterAjoutGroupeTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Ajout groupé (plusieurs dossiers d\'un coup)'**
  String get ajouterAjoutGroupeTooltip;

  /// No description provided for @ajouterTypeDossierLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type de dossier'**
  String get ajouterTypeDossierLabel;

  /// No description provided for @ajouterGererTypesBouton.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mes types de dossier'**
  String get ajouterGererTypesBouton;

  /// No description provided for @ajouterDetailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Détail (pour distinguer plusieurs tâches)'**
  String get ajouterDetailLabel;

  /// No description provided for @ajouterDetailExemple.
  ///
  /// In fr, this message translates to:
  /// **'ex : Conclusions en défense'**
  String get ajouterDetailExemple;

  /// No description provided for @ajouterDans2Semaines.
  ///
  /// In fr, this message translates to:
  /// **'Dans 2 semaines'**
  String get ajouterDans2Semaines;

  /// No description provided for @ajouterDans1Mois.
  ///
  /// In fr, this message translates to:
  /// **'Dans 1 mois'**
  String get ajouterDans1Mois;

  /// No description provided for @ajouterChoisirDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get ajouterChoisirDate;

  /// No description provided for @ajouterRetirerDate.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get ajouterRetirerDate;

  /// No description provided for @ajouterAucuneDateChoisie.
  ///
  /// In fr, this message translates to:
  /// **'Aucune date choisie (optionnel).'**
  String get ajouterAucuneDateChoisie;

  /// No description provided for @ajouterEcheanceAvecDate.
  ///
  /// In fr, this message translates to:
  /// **'Échéance : {date}'**
  String ajouterEcheanceAvecDate(String date);

  /// No description provided for @ajouterNoteTitre.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une note'**
  String get ajouterNoteTitre;

  /// No description provided for @ajoutGroupeTitre.
  ///
  /// In fr, this message translates to:
  /// **'Ajout groupé'**
  String get ajoutGroupeTitre;

  /// No description provided for @ajoutGroupeTousTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tous ces dossiers sont de type :'**
  String get ajoutGroupeTousTypeLabel;

  /// No description provided for @ajoutGroupeInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Remplis une ligne par dossier — la date est optionnelle.'**
  String get ajoutGroupeInstructions;

  /// No description provided for @ajoutGroupeNomCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Dossier {numero}'**
  String ajoutGroupeNomCodeHint(int numero);

  /// No description provided for @ajoutGroupeDateBouton.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get ajoutGroupeDateBouton;

  /// No description provided for @ajoutGroupeAjouterLigne.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une ligne'**
  String get ajoutGroupeAjouterLigne;

  /// No description provided for @ajoutGroupeEnregistrerBouton.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, =0{Enregistrer} =1{Enregistrer (1 dossier)} other{Enregistrer ({nombre} dossiers)}}'**
  String ajoutGroupeEnregistrerBouton(int nombre);

  /// No description provided for @confirmerEmailErreurVide.
  ///
  /// In fr, this message translates to:
  /// **'Entre l\'adresse email utilisée pour demander le lien.'**
  String get confirmerEmailErreurVide;

  /// No description provided for @confirmerEmailErreurLienInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Ce lien ne correspond pas à cette adresse, ou il a expiré.'**
  String get confirmerEmailErreurLienInvalide;

  /// No description provided for @confirmerEmailInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Confirme ton adresse email pour terminer la connexion.'**
  String get confirmerEmailInstructions;

  /// No description provided for @confirmerEmailBouton.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirmerEmailBouton;

  /// No description provided for @accueilPage1Titre.
  ///
  /// In fr, this message translates to:
  /// **'Vigie'**
  String get accueilPage1Titre;

  /// No description provided for @accueilPage1Texte.
  ///
  /// In fr, this message translates to:
  /// **'Le suivi d\'échéances qui reste confidentiel — pour les professions où chaque dossier compte.'**
  String get accueilPage1Texte;

  /// No description provided for @accueilPage2Titre.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get accueilPage2Titre;

  /// No description provided for @accueilPage2Texte.
  ///
  /// In fr, this message translates to:
  /// **'Crée un dossier avec un nom de code, une date, et laisse Vigie calculer quand te rappeler.'**
  String get accueilPage2Texte;

  /// No description provided for @accueilPage3Titre.
  ///
  /// In fr, this message translates to:
  /// **'Suivre'**
  String get accueilPage3Titre;

  /// No description provided for @accueilPage3Texte.
  ///
  /// In fr, this message translates to:
  /// **'Vigie te relance jusqu\'à confirmation que c\'est fait — jamais de tâche oubliée en silence.'**
  String get accueilPage3Texte;

  /// No description provided for @accueilPage4Titre.
  ///
  /// In fr, this message translates to:
  /// **'Faire le bilan'**
  String get accueilPage4Titre;

  /// No description provided for @accueilPage4Texte.
  ///
  /// In fr, this message translates to:
  /// **'Un résumé de ton activité, dossier par dossier, pour garder une vue d\'ensemble.'**
  String get accueilPage4Texte;

  /// No description provided for @accueilConfidentialiteNote.
  ///
  /// In fr, this message translates to:
  /// **'Aucune vraie information sur tes affaires n\'est jamais requise — tu choisis toi-même un nom de code pour chaque dossier.'**
  String get accueilConfidentialiteNote;

  /// No description provided for @accueilBoutonPasser.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get accueilBoutonPasser;

  /// No description provided for @accueilBoutonSuivant.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get accueilBoutonSuivant;

  /// No description provided for @accueilBoutonSeConnecter.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get accueilBoutonSeConnecter;

  /// No description provided for @connexionChampEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get connexionChampEmail;

  /// No description provided for @connexionErreurEmailInvalide.
  ///
  /// In fr, this message translates to:
  /// **'Entre une adresse email valide.'**
  String get connexionErreurEmailInvalide;

  /// No description provided for @connexionErreurEnvoiLien.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer le lien. Vérifie ta connexion.'**
  String get connexionErreurEnvoiLien;

  /// No description provided for @connexionTelechargerAvecVersion.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger l\'app Android (v{version})'**
  String connexionTelechargerAvecVersion(String version);

  /// No description provided for @connexionTelechargerSansVersion.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger l\'app Android (recommandé)'**
  String get connexionTelechargerSansVersion;

  /// No description provided for @connexionVersionInstalleeMeilleure.
  ///
  /// In fr, this message translates to:
  /// **'La version installée fonctionne mieux que le site (notifications, Gmail...).'**
  String get connexionVersionInstalleeMeilleure;

  /// No description provided for @connexionInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Entre ton adresse email, tu recevras un lien de connexion — pas besoin de mot de passe.'**
  String get connexionInstructions;

  /// No description provided for @connexionRecevoirLienBouton.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir le lien de connexion'**
  String get connexionRecevoirLienBouton;

  /// No description provided for @connexionInstructionsIosTitre.
  ///
  /// In fr, this message translates to:
  /// **'Installer sur iPhone / iPad'**
  String get connexionInstructionsIosTitre;

  /// No description provided for @connexionInstructionsIos.
  ///
  /// In fr, this message translates to:
  /// **'1. Touchez l\'icône Partager en bas de Safari.\n2. Choisissez « Sur l\'écran d\'accueil ».'**
  String get connexionInstructionsIos;

  /// No description provided for @connexionLienEnvoye.
  ///
  /// In fr, this message translates to:
  /// **'Un lien a été envoyé à {email}.\nOuvre ta boîte mail et clique sur le lien pour te connecter.'**
  String connexionLienEnvoye(String email);

  /// No description provided for @connexionMauvaiseAdresse.
  ///
  /// In fr, this message translates to:
  /// **'Mauvaise adresse ? Recommencer'**
  String get connexionMauvaiseAdresse;

  /// No description provided for @notificationsTitre.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitre;

  /// No description provided for @notificationsAucunePourLInstant.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification pour l\'instant.'**
  String get notificationsAucunePourLInstant;

  /// No description provided for @notificationsAucunePourCeType.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification pour ce type.'**
  String get notificationsAucunePourCeType;

  /// No description provided for @notificationsFiltreTous.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get notificationsFiltreTous;

  /// No description provided for @notificationsChipTypeCompte.
  ///
  /// In fr, this message translates to:
  /// **'{type} : {valeur}'**
  String notificationsChipTypeCompte(String type, int valeur);

  /// No description provided for @pourquoiVigieAppBarTitre.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi Vigie'**
  String get pourquoiVigieAppBarTitre;

  /// No description provided for @pourquoiVigieTitre1.
  ///
  /// In fr, this message translates to:
  /// **'Des rappels qui s\'adaptent, pas un message figé'**
  String get pourquoiVigieTitre1;

  /// No description provided for @pourquoiVigieTexte1.
  ///
  /// In fr, this message translates to:
  /// **'Le ton se durcit avec le retard — neutre, puis ferme, puis prioritaire — au lieu de répéter éternellement la même phrase. Une échéance qui approche est signalée même sans retard.'**
  String get pourquoiVigieTexte1;

  /// No description provided for @pourquoiVigieTitre2.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité par conception'**
  String get pourquoiVigieTitre2;

  /// No description provided for @pourquoiVigieTexte2.
  ///
  /// In fr, this message translates to:
  /// **'Les dossiers sont désignés par des noms de code choisis par toi, jamais par les vraies informations sensibles — du nom du dossier jusqu\'au journal de bord et au bilan exporté.'**
  String get pourquoiVigieTexte2;

  /// No description provided for @pourquoiVigieTitre3.
  ///
  /// In fr, this message translates to:
  /// **'Toutes tes sources, une seule validation'**
  String get pourquoiVigieTitre3;

  /// No description provided for @pourquoiVigieTexte3.
  ///
  /// In fr, this message translates to:
  /// **'Gmail, Google Tasks et Google Calendar alimentent le même écran de propositions, codées par couleur selon leur origine — tu choisis ce qui devient un vrai dossier. L\'état de chaque vérification est visible, pas une boîte noire.'**
  String get pourquoiVigieTexte3;

  /// No description provided for @pourquoiVigieTitre4.
  ///
  /// In fr, this message translates to:
  /// **'Un bilan qui raconte une histoire'**
  String get pourquoiVigieTitre4;

  /// No description provided for @pourquoiVigieTexte4.
  ///
  /// In fr, this message translates to:
  /// **'Carte de chaleur d\'activité, répartition par type de dossier, jour le plus chargé, taux d\'achèvement, et un indicateur de fiabilité — pas juste des compteurs bruts.'**
  String get pourquoiVigieTexte4;

  /// No description provided for @pourquoiVigieTitre5.
  ///
  /// In fr, this message translates to:
  /// **'Un journal de bord, pas des cases à cocher'**
  String get pourquoiVigieTitre5;

  /// No description provided for @pourquoiVigieTexte5.
  ///
  /// In fr, this message translates to:
  /// **'Documente l\'avancement d\'un dossier étape par étape : chaque note s\'ajoute à la suite, rien n\'est jamais écrasé — une vraie mémoire de la progression, pas un simple statut.'**
  String get pourquoiVigieTexte5;

  /// No description provided for @pourquoiVigieTitre6.
  ///
  /// In fr, this message translates to:
  /// **'Un rapport sûr à partager, par construction'**
  String get pourquoiVigieTitre6;

  /// No description provided for @pourquoiVigieTexte6.
  ///
  /// In fr, this message translates to:
  /// **'Le bilan s\'exporte en un clic — et comme tout est déjà en noms de code, il n\'y a jamais rien de sensible dedans, où qu\'il soit partagé.'**
  String get pourquoiVigieTexte6;

  /// No description provided for @commonSupprimer.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get commonSupprimer;

  /// No description provided for @dossierDetailModifierTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le dossier'**
  String get dossierDetailModifierTooltip;

  /// No description provided for @dossierDetailSupprimerTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le dossier'**
  String get dossierDetailSupprimerTooltip;

  /// No description provided for @dossierDetailDateAvecValeur.
  ///
  /// In fr, this message translates to:
  /// **'Date : {date}'**
  String dossierDetailDateAvecValeur(String date);

  /// No description provided for @dossierDetailPasDeDate.
  ///
  /// In fr, this message translates to:
  /// **'Pas de date renseignée'**
  String get dossierDetailPasDeDate;

  /// No description provided for @dossierDetailTachesLieesTitre.
  ///
  /// In fr, this message translates to:
  /// **'Tâches liées'**
  String get dossierDetailTachesLieesTitre;

  /// No description provided for @dossierDetailAucuneTache.
  ///
  /// In fr, this message translates to:
  /// **'Aucune tâche pour l\'instant.'**
  String get dossierDetailAucuneTache;

  /// No description provided for @dossierDetailAjouterTacheBouton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une tâche'**
  String get dossierDetailAjouterTacheBouton;

  /// No description provided for @dossierDetailSupprimerDossierTitre.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce dossier ?'**
  String get dossierDetailSupprimerDossierTitre;

  /// No description provided for @dossierDetailSupprimerDossierMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le dossier \"{nom}\" et toutes ses tâches seront supprimés définitivement.'**
  String dossierDetailSupprimerDossierMessage(String nom);

  /// No description provided for @dossierDetailNatureEtDate.
  ///
  /// In fr, this message translates to:
  /// **'{nature} — {date}'**
  String dossierDetailNatureEtDate(String nature, String date);

  /// No description provided for @dossierDetailConfirmerTitre.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer ?'**
  String get dossierDetailConfirmerTitre;

  /// No description provided for @dossierDetailBasculerMarquerFait.
  ///
  /// In fr, this message translates to:
  /// **'marquer cette tâche comme faite'**
  String get dossierDetailBasculerMarquerFait;

  /// No description provided for @dossierDetailBasculerRemettreAFaire.
  ///
  /// In fr, this message translates to:
  /// **'remettre cette tâche à \"à faire\"'**
  String get dossierDetailBasculerRemettreAFaire;

  /// No description provided for @dossierDetailBasculerMessage.
  ///
  /// In fr, this message translates to:
  /// **'Tu veux {action} : \"{description}\".'**
  String dossierDetailBasculerMessage(String action, String description);

  /// No description provided for @dossierDetailSupprimerTacheTitre.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette tâche ?'**
  String get dossierDetailSupprimerTacheTitre;

  /// No description provided for @dossierDetailSupprimerTacheMessage.
  ///
  /// In fr, this message translates to:
  /// **'\"{description}\" sera supprimée définitivement.'**
  String dossierDetailSupprimerTacheMessage(String description);

  /// No description provided for @dossierDetailAjouterTacheTitre.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une tâche'**
  String get dossierDetailAjouterTacheTitre;

  /// No description provided for @dossierDetailModifierTacheTitre.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la tâche'**
  String get dossierDetailModifierTacheTitre;

  /// No description provided for @dossierDetailDetailTacheLabel.
  ///
  /// In fr, this message translates to:
  /// **'Détail de la tâche'**
  String get dossierDetailDetailTacheLabel;

  /// No description provided for @journalTypeAvancement.
  ///
  /// In fr, this message translates to:
  /// **'Avancement'**
  String get journalTypeAvancement;

  /// No description provided for @journalTypeBlocage.
  ///
  /// In fr, this message translates to:
  /// **'Blocage'**
  String get journalTypeBlocage;

  /// No description provided for @journalTypeDecision.
  ///
  /// In fr, this message translates to:
  /// **'Décision'**
  String get journalTypeDecision;

  /// No description provided for @dossierDetailJournalTitre.
  ///
  /// In fr, this message translates to:
  /// **'Journal de bord'**
  String get dossierDetailJournalTitre;

  /// No description provided for @dossierDetailJournalDescription.
  ///
  /// In fr, this message translates to:
  /// **'Documente l\'avancement étape par étape — chaque note s\'ajoute à la suite, rien n\'est écrasé. Comme pour le nom du dossier, évite d\'y écrire de vraies informations sensibles.'**
  String get dossierDetailJournalDescription;

  /// No description provided for @dossierDetailJournalHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : appelé X, en attente de sa réponse...'**
  String get dossierDetailJournalHint;

  /// No description provided for @dossierDetailAjouterJournalBouton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au journal'**
  String get dossierDetailAjouterJournalBouton;

  /// No description provided for @dossierDetailBoutonDeverrouillerNotes.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller mes notes'**
  String get dossierDetailBoutonDeverrouillerNotes;

  /// No description provided for @dossierDetailEntreeVerrouillee.
  ///
  /// In fr, this message translates to:
  /// **'Entrée chiffrée — déverrouille tes notes pour la lire.'**
  String get dossierDetailEntreeVerrouillee;

  /// No description provided for @phraseSecreteTitreCreation.
  ///
  /// In fr, this message translates to:
  /// **'Protéger tes notes de dossier'**
  String get phraseSecreteTitreCreation;

  /// No description provided for @phraseSecreteTitreDeverrouillage.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller les notes'**
  String get phraseSecreteTitreDeverrouillage;

  /// No description provided for @phraseSecreteAvertissement.
  ///
  /// In fr, this message translates to:
  /// **'Si tu oublies ce mot de passe, ces notes seront perdues pour toujours, pour tout le monde — même nous ne pourrons pas les récupérer. Ce n\'est pas ton code PIN, ne le note nulle part sur ce téléphone.'**
  String get phraseSecreteAvertissement;

  /// No description provided for @phraseSecreteInstructionsDeverrouillage.
  ///
  /// In fr, this message translates to:
  /// **'Entre ton mot de passe pour voir et écrire dans le journal de ce dossier.'**
  String get phraseSecreteInstructionsDeverrouillage;

  /// No description provided for @phraseSecreteChamp.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get phraseSecreteChamp;

  /// No description provided for @phraseSecreteChampConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Retape le mot de passe'**
  String get phraseSecreteChampConfirmation;

  /// No description provided for @phraseSecreteErreurTropCourte.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un mot de passe d\'au moins 8 caractères.'**
  String get phraseSecreteErreurTropCourte;

  /// No description provided for @phraseSecreteErreurNeCorrespondentPas.
  ///
  /// In fr, this message translates to:
  /// **'Les deux mots de passe ne correspondent pas.'**
  String get phraseSecreteErreurNeCorrespondentPas;

  /// No description provided for @phraseSecreteErreurIncorrecte.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect.'**
  String get phraseSecreteErreurIncorrecte;

  /// No description provided for @phraseSecreteErreurGenerique.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessaie.'**
  String get phraseSecreteErreurGenerique;

  /// No description provided for @phraseSecreteBoutonCreer.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get phraseSecreteBoutonCreer;

  /// No description provided for @phraseSecreteBoutonDeverrouiller.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller'**
  String get phraseSecreteBoutonDeverrouiller;

  /// No description provided for @dossierDetailErreurAjoutJournal.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ajouter cette entrée : {erreur}'**
  String dossierDetailErreurAjoutJournal(String erreur);

  /// No description provided for @dossierDetailErreurModifJournal.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier cette entrée : {erreur}'**
  String dossierDetailErreurModifJournal(String erreur);

  /// No description provided for @dossierDetailSupprimerEntreeTitre.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette entrée du journal ?'**
  String get dossierDetailSupprimerEntreeTitre;

  /// No description provided for @dossierDetailSupprimerEntreeMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette note du {date} sera supprimée définitivement.'**
  String dossierDetailSupprimerEntreeMessage(String date);

  /// No description provided for @dossierDetailModifierEntreeTitre.
  ///
  /// In fr, this message translates to:
  /// **'Modifier cette entrée'**
  String get dossierDetailModifierEntreeTitre;

  /// No description provided for @dossierDetailHistoriqueTitre.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get dossierDetailHistoriqueTitre;

  /// No description provided for @dossierDetailAucuneEntree.
  ///
  /// In fr, this message translates to:
  /// **'Aucune entrée pour l\'instant.'**
  String get dossierDetailAucuneEntree;

  /// No description provided for @dossierDetailAucuneEntreeType.
  ///
  /// In fr, this message translates to:
  /// **'Aucune entrée de ce type.'**
  String get dossierDetailAucuneEntreeType;

  /// No description provided for @dossierDetailErreurLectureJournal.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire le journal : {erreur}'**
  String dossierDetailErreurLectureJournal(String erreur);

  /// No description provided for @dossierDetailHier.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get dossierDetailHier;

  /// No description provided for @dossierDetailModifieSuffixe.
  ///
  /// In fr, this message translates to:
  /// **'· modifié'**
  String get dossierDetailModifieSuffixe;

  /// No description provided for @commonConfirmer.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get commonConfirmer;

  /// No description provided for @commonTuEsSur.
  ///
  /// In fr, this message translates to:
  /// **'Tu es sûr ?'**
  String get commonTuEsSur;

  /// No description provided for @commonDerniereConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Dernière confirmation : {message}'**
  String commonDerniereConfirmation(String message);

  /// No description provided for @connexionGoogleAdresseInconnue.
  ///
  /// In fr, this message translates to:
  /// **'Compte connecté (reconnecte-toi pour voir l\'adresse)'**
  String get connexionGoogleAdresseInconnue;

  /// No description provided for @commonRetirer.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get commonRetirer;

  /// No description provided for @dossierDetailParticipantsTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Participants'**
  String get dossierDetailParticipantsTooltip;

  /// No description provided for @participantsTitre.
  ///
  /// In fr, this message translates to:
  /// **'Participants'**
  String get participantsTitre;

  /// No description provided for @participantsInvitationsEnAttente.
  ///
  /// In fr, this message translates to:
  /// **'Invitations en attente'**
  String get participantsInvitationsEnAttente;

  /// No description provided for @participantsAnnulerInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Annuler l\'invitation'**
  String get participantsAnnulerInvitation;

  /// No description provided for @participantsAnnulerInvitationTitre.
  ///
  /// In fr, this message translates to:
  /// **'Annuler l\'invitation ?'**
  String get participantsAnnulerInvitationTitre;

  /// No description provided for @participantsAnnulerInvitationMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment annuler l\'invitation envoyée à {email} ?'**
  String participantsAnnulerInvitationMessage(String email);

  /// No description provided for @participantsLectureSeuleInfo.
  ///
  /// In fr, this message translates to:
  /// **'Seuls le créateur et les administrateurs peuvent gérer les participants.'**
  String get participantsLectureSeuleInfo;

  /// No description provided for @participantsAjouterBouton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un participant'**
  String get participantsAjouterBouton;

  /// No description provided for @participantsRoleCreateur.
  ///
  /// In fr, this message translates to:
  /// **'Créateur'**
  String get participantsRoleCreateur;

  /// No description provided for @participantsRoleAdministrateur.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get participantsRoleAdministrateur;

  /// No description provided for @participantsRoleContributeur.
  ///
  /// In fr, this message translates to:
  /// **'Contributeur'**
  String get participantsRoleContributeur;

  /// No description provided for @participantsSousTitreMoi.
  ///
  /// In fr, this message translates to:
  /// **'{role} · toi'**
  String participantsSousTitreMoi(String role);

  /// No description provided for @dossierAccesRevoqueMessage.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'as plus accès à ce dossier. Un administrateur t\'a peut-être retiré pendant que tu le consultais.'**
  String get dossierAccesRevoqueMessage;

  /// No description provided for @dossierErreurChargementMessage.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ce dossier pour l\'instant. Vérifie ta connexion et réessaie.'**
  String get dossierErreurChargementMessage;

  /// No description provided for @participantsMenuPasserAdministrateur.
  ///
  /// In fr, this message translates to:
  /// **'Passer administrateur'**
  String get participantsMenuPasserAdministrateur;

  /// No description provided for @participantsMenuPasserContributeur.
  ///
  /// In fr, this message translates to:
  /// **'Passer contributeur'**
  String get participantsMenuPasserContributeur;

  /// No description provided for @participantsRetirerTitre.
  ///
  /// In fr, this message translates to:
  /// **'Retirer ce participant ?'**
  String get participantsRetirerTitre;

  /// No description provided for @participantsRetirerMessage.
  ///
  /// In fr, this message translates to:
  /// **'{affichage} n\'aura plus accès à ce dossier.'**
  String participantsRetirerMessage(String affichage);

  /// No description provided for @participantsQuitterBouton.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get participantsQuitterBouton;

  /// No description provided for @participantsQuitterTitre.
  ///
  /// In fr, this message translates to:
  /// **'Quitter ce dossier ?'**
  String get participantsQuitterTitre;

  /// No description provided for @participantsQuitterMessage.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'auras plus accès à ce dossier ni à son contenu. Tu peux redemander à être invité plus tard.'**
  String get participantsQuitterMessage;

  /// No description provided for @participantsErreur.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'effectuer cette action : {erreur}'**
  String participantsErreur(String erreur);

  /// No description provided for @participantsErreurAucunCompte.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte Vigie n\'existe avec cet email.'**
  String get participantsErreurAucunCompte;

  /// No description provided for @participantsErreurDossierIntrouvable.
  ///
  /// In fr, this message translates to:
  /// **'Ce dossier n\'existe plus.'**
  String get participantsErreurDossierIntrouvable;

  /// No description provided for @participantsErreurPasParticipant.
  ///
  /// In fr, this message translates to:
  /// **'Cette personne n\'est déjà plus participante de ce dossier.'**
  String get participantsErreurPasParticipant;

  /// No description provided for @participantsErreurDejaParticipant.
  ///
  /// In fr, this message translates to:
  /// **'Cette personne est déjà participante de ce dossier.'**
  String get participantsErreurDejaParticipant;

  /// No description provided for @participantsErreurPermission.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'as pas le droit de gérer les participants de ce dossier.'**
  String get participantsErreurPermission;

  /// No description provided for @participantsErreurCreateurNonRetirable.
  ///
  /// In fr, this message translates to:
  /// **'Le créateur du dossier ne peut pas être retiré.'**
  String get participantsErreurCreateurNonRetirable;

  /// No description provided for @participantsErreurCreateurRoleFixe.
  ///
  /// In fr, this message translates to:
  /// **'Le rôle du créateur ne peut pas être changé.'**
  String get participantsErreurCreateurRoleFixe;

  /// No description provided for @participantsErreurGenerique.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessaie.'**
  String get participantsErreurGenerique;

  /// No description provided for @participantsDialogueAjouterTitre.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un participant'**
  String get participantsDialogueAjouterTitre;

  /// No description provided for @participantsDialogueAjouterChampEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email du compte Vigie'**
  String get participantsDialogueAjouterChampEmail;

  /// No description provided for @participantsDialogueAjouterChampRole.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get participantsDialogueAjouterChampRole;

  /// No description provided for @propositionTypeCreer.
  ///
  /// In fr, this message translates to:
  /// **'Création'**
  String get propositionTypeCreer;

  /// No description provided for @propositionTypeModifier.
  ///
  /// In fr, this message translates to:
  /// **'Modification'**
  String get propositionTypeModifier;

  /// No description provided for @propositionTypeMarquerFait.
  ///
  /// In fr, this message translates to:
  /// **'Marquage comme fait'**
  String get propositionTypeMarquerFait;

  /// No description provided for @propositionTypeMarquerNonFait.
  ///
  /// In fr, this message translates to:
  /// **'Remise à faire'**
  String get propositionTypeMarquerNonFait;

  /// No description provided for @propositionTypeSupprimer.
  ///
  /// In fr, this message translates to:
  /// **'Suppression'**
  String get propositionTypeSupprimer;

  /// No description provided for @propositionBadgeTexte.
  ///
  /// In fr, this message translates to:
  /// **'{type} proposée par {personne}, en attente d\'approbation.'**
  String propositionBadgeTexte(String type, String personne);

  /// No description provided for @propositionBoutonApprouver.
  ///
  /// In fr, this message translates to:
  /// **'Approuver'**
  String get propositionBoutonApprouver;

  /// No description provided for @propositionBoutonRejeter.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter'**
  String get propositionBoutonRejeter;

  /// No description provided for @propositionBoutonRetirer.
  ///
  /// In fr, this message translates to:
  /// **'Retirer ma proposition'**
  String get propositionBoutonRetirer;

  /// No description provided for @dossierDetailAttributionTache.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutée par {personne}'**
  String dossierDetailAttributionTache(String personne);

  /// No description provided for @dossierDetailAttributionEntree.
  ///
  /// In fr, this message translates to:
  /// **'Écrite par {personne}'**
  String dossierDetailAttributionEntree(String personne);

  /// No description provided for @participantsPermissionsDialogueTitre.
  ///
  /// In fr, this message translates to:
  /// **'Permissions de {personne}'**
  String participantsPermissionsDialogueTitre(String personne);

  /// No description provided for @participantsPermissionGererParticipants.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter/retirer des participants, changer leur rôle'**
  String get participantsPermissionGererParticipants;

  /// No description provided for @participantsPermissionSupprimerDossier.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le dossier'**
  String get participantsPermissionSupprimerDossier;

  /// No description provided for @participantsPermissionModererContenu.
  ///
  /// In fr, this message translates to:
  /// **'Modifier/supprimer le contenu des autres sans validation'**
  String get participantsPermissionModererContenu;

  /// No description provided for @participantsMenuPermissions.
  ///
  /// In fr, this message translates to:
  /// **'Permissions…'**
  String get participantsMenuPermissions;

  /// No description provided for @aTraiterOngletMesDossiers.
  ///
  /// In fr, this message translates to:
  /// **'Mes dossiers'**
  String get aTraiterOngletMesDossiers;

  /// No description provided for @aTraiterOngletPartages.
  ///
  /// In fr, this message translates to:
  /// **'Dossiers partagés'**
  String get aTraiterOngletPartages;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
