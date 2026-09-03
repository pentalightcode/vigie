import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'models/reglages_utilisateur.dart';
import 'screens/a_traiter_screen.dart';
import 'screens/accueil_screen.dart';
import 'screens/agenda_screen.dart';
import 'screens/bilan_screen.dart';
import 'screens/confirmer_email_screen.dart';
import 'screens/connexion_screen.dart';
import 'screens/creer_pin_screen.dart';
import 'screens/dossier_detail_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profil_screen.dart';
import 'screens/verrou_screen.dart';
import 'services/auth_service.dart';
import 'services/deep_link_service.dart';
import 'services/lock_service.dart';
import 'services/locale_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'services/utilisateur_service.dart';
import 'widgets/banniere_installation_ios.dart';
import 'widgets/banniere_mise_a_jour.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('fr_FR');
  await initializeDateFormatting('en_US');
  await ThemeService.instance.charger();
  await LocaleService.instance.charger();
  runApp(const SecretaireAjeApp());
}

/// Thème personnalisable (demandé par Tobie le 2026-08-20) : écoute les deux
/// préférences (couleur, mode clair/sombre) et reconstruit le MaterialApp
/// dès qu'elles changent, où qu'on soit dans l'app (y compris l'écran de
/// connexion, avant authentification).
class SecretaireAjeApp extends StatelessWidget {
  const SecretaireAjeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
        [ThemeService.instance.couleur, ThemeService.instance.mode, LocaleService.instance.locale],
      ),
      builder: (context, _) {
        final seed = ThemeService.instance.couleur.value;
        return MaterialApp(
          title: 'Vigie',
          theme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.light, useMaterial3: true),
          darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark, useMaterial3: true),
          themeMode: ThemeService.instance.mode.value,
          locale: LocaleService.instance.locale.value,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const _PorteDEntree(),
        );
      },
    );
  }
}

/// Décide quoi afficher : écran de connexion, ou l'app une fois connecté.
/// Écoute aussi les liens magiques reçus pour terminer la connexion.
class _PorteDEntree extends StatefulWidget {
  const _PorteDEntree();

  @override
  State<_PorteDEntree> createState() => _PorteDEntreeState();
}

class _PorteDEntreeState extends State<_PorteDEntree> {
  String? _lienEnAttenteDeConfirmation;
  bool? _accueilVu;

  @override
  void initState() {
    super.initState();
    accueilDejaVu().then((vu) {
      if (mounted) setState(() => _accueilVu = vu);
    });

    // Sur le web, la source la plus fiable pour l'URL qui a chargé la page
    // est Uri.base (fournie par le navigateur) — on la vérifie en priorité.
    _traiterLien(Uri.base.toString());

    // Lien qui a éventuellement ouvert l'app (utile sur mobile).
    DeepLinkService.instance.lienInitial().then((lien) {
      if (lien != null) _traiterLien(lien);
    });

    // Puis les liens reçus plus tard, si l'app reste ouverte en arrière-plan.
    DeepLinkService.instance.demarrer();
    DeepLinkService.instance.liens.listen(_traiterLien);
  }

  Future<void> _traiterLien(String lien) async {
    if (!AuthService.instance.estUnLienDeConnexion(lien)) return;

    final email = await AuthService.instance.emailEnAttente();
    if (email != null) {
      await AuthService.instance.terminerConnexionAvecLienEtEmail(lien, email);
      return;
    }
    // Lien ouvert sur un autre appareil/navigateur : on redemande l'email.
    if (mounted) {
      setState(() => _lienEnAttenteDeConfirmation = lien);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lienEnAttenteDeConfirmation != null) {
      return ConfirmerEmailScreen(
        lien: _lienEnAttenteDeConfirmation!,
        onConnecte: () => setState(() => _lienEnAttenteDeConfirmation = null),
      );
    }

    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final connecte = snapshot.data != null;
        if (!connecte) {
          if (_accueilVu == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (_accueilVu == false) {
            return AccueilScreen(onTermine: () => setState(() => _accueilVu = true));
          }
          return const Scaffold(body: ConnexionScreen());
        }
        return const _ZoneApresConnexion();
      },
    );
  }
}

/// Une fois connecté (Firebase Auth) : verrou PIN/biométrie de l'app,
/// puis le contenu principal.
class _ZoneApresConnexion extends StatefulWidget {
  const _ZoneApresConnexion();

  @override
  State<_ZoneApresConnexion> createState() => _ZoneApresConnexionState();
}

class _ZoneApresConnexionState extends State<_ZoneApresConnexion> {
  bool? _pinDefini;
  bool _deverrouille = false;

  @override
  void initState() {
    super.initState();
    // S'assure que le document de réglages existe (délai de rappel, pseudo...)
    // avant que le reste de l'app n'en ait besoin.
    UtilisateurService.instance.assurerDocumentExiste();
    NotificationService.instance.demarrer();
    LockService.instance.pinDejaDefini().then((defini) {
      if (mounted) setState(() => _pinDefini = defini);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pinDefini == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_pinDefini == false) {
      return CreerPinScreen(onPinDefini: () => setState(() {
            _pinDefini = true;
            _deverrouille = true;
          }));
    }
    if (!_deverrouille) {
      return VerrouScreen(onDeverrouille: () => setState(() => _deverrouille = true));
    }
    return StreamBuilder<ReglagesUtilisateur>(
      stream: UtilisateurService.instance.reglages(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.data!.onboardingTermine) {
          return OnboardingScreen(onTermine: () {}); // le StreamBuilder se met à jour tout seul
        }
        return const _EcranPrincipal();
      },
    );
  }
}

/// Contenu principal une fois connecté et déverrouillé : navigation simple
/// entre les 3 écrans du MVP.
class _EcranPrincipal extends StatefulWidget {
  const _EcranPrincipal();

  @override
  State<_EcranPrincipal> createState() => _EcranPrincipalState();
}

class _EcranPrincipalState extends State<_EcranPrincipal> {
  int _ongletActif = 0;

  static const _ecrans = [
    ATraiterScreen(),
    AgendaScreen(),
    BilanScreen(),
    ProfilScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Cet écran n'existe qu'une fois le verrou PIN/biométrique passé — donc
    // ouvrir un dossier ici, jamais avant, ne contourne jamais le verrou.
    // Écoute continue (pas juste au démarrage) : couvre aussi le cas d'un
    // tap sur une notification pendant que l'app est déjà ouverte ici.
    NotificationService.instance.dossierAOuvrir.addListener(_ouvrirDossierEnAttente);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ouvrirDossierEnAttente());
  }

  @override
  void dispose() {
    NotificationService.instance.dossierAOuvrir.removeListener(_ouvrirDossierEnAttente);
    super.dispose();
  }

  void _ouvrirDossierEnAttente() {
    final dossierId = NotificationService.instance.dossierAOuvrir.value;
    if (dossierId == null || !mounted) return;
    NotificationService.instance.dossierAOuvrir.value = null;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DossierDetailScreen(dossierId: dossierId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Uniquement sur Android/iOS : la version web sert toujours la
          // dernière version dès qu'on recharge la page, pas besoin d'une
          // bannière pour se mettre à jour soi-même.
          if (!kIsWeb) const BanniereMiseAJour(),
          // Uniquement sur le Web iOS : pour guider l'utilisateur à installer la PWA.
          if (kIsWeb) const BanniereInstallationIos(),
          Expanded(child: _ecrans[_ongletActif]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _ongletActif,
        onDestinationSelected: (i) => setState(() => _ongletActif = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.checklist), label: AppLocalizations.of(context)!.navATraiter),
          NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), label: AppLocalizations.of(context)!.navAgenda),
          NavigationDestination(icon: const Icon(Icons.bar_chart), label: AppLocalizations.of(context)!.navBilan),
          NavigationDestination(icon: const Icon(Icons.person_outline), label: AppLocalizations.of(context)!.navProfil),
        ],
      ),
    );
  }
}
