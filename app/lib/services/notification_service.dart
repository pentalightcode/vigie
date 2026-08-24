import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Identifiant du canal de rappels — doit correspondre exactement à celui
/// utilisé côté serveur (functions/main.py, _envoyer). Sur Android, le son
/// et la vibration d'un canal ne peuvent être fixés que par l'app elle-même,
/// au moment où elle le crée — les préciser seulement côté serveur ne suffit
/// pas (trouvé en testant avec Tobie le 2026-08-14 : notification reçue mais
/// muette). "_v2" pour éviter tout canal déjà créé silencieusement avant ce
/// correctif — les réglages d'un canal existant sont figés, un nouvel id
/// garantit un départ propre.
const _idCanalRappels = 'rappels_vigie_v2';

/// Enregistre l'appareil pour recevoir les rappels quotidiens (matin/soir).
/// Le token FCM est stocké dans le document utilisateur ; c'est la fonction
/// serveur planifiée (Cloud Functions) qui s'en sert pour envoyer le digest.
///
/// La configuration complète pour le Web (clé VAPID + service worker) n'est
/// pas encore faite — priorité donnée à Android, la cible réelle du père.
/// Sur Web/desktop, un échec ici ne doit jamais bloquer le reste de l'app.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;
  final _notificationsLocales = FlutterLocalNotificationsPlugin();

  /// Dossier à ouvrir dès que l'app est déverrouillée — jamais ouvert
  /// directement depuis ce service pour ne pas court-circuiter l'écran de
  /// verrou PIN/biométrique (l'app reste confidentielle même via une
  /// notification). Rempli au tap sur une notification de rappel (app
  /// relancée à froid ou ramenée au premier plan) ; c'est `_EcranPrincipal`
  /// (main.dart), qui n'existe qu'une fois déverrouillé, qui écoute et
  /// navigue réellement — demandé par Tobie le 2026-08-14, resté en attente
  /// jusqu'ici.
  final dossierAOuvrir = ValueNotifier<String?>(null);

  Future<void> demarrer() async {
    // Isolé du reste : la lecture du message qui a lancé l'app ne doit
    // jamais être bloquée par un souci sur les étapes suivantes (permission,
    // jeton FCM, écriture Firestore...) — bug trouvé par Tobie le
    // 2026-08-22 ("reste bloqué sur À traiter" après un tap, app fermée) :
    // ces étapes réseau étaient avant dans le même bloc try/catch, donc un
    // échec au tout premier lancement à froid (fréquent : Play Services ou
    // réseau pas encore prêts) avalait silencieusement l'exception et
    // empêchait d'atteindre getInitialMessage.
    try {
      // App relancée à froid par un tap sur la notification (elle était
      // fermée) : le message qui l'a ouverte, s'il y en a un.
      _extraireDossier(await _messaging.getInitialMessage());
      // App déjà ouverte (au premier plan ou en arrière-plan) et ramenée au
      // premier plan par un tap sur la notification.
      FirebaseMessaging.onMessageOpenedApp.listen(_extraireDossier);
    } catch (e) {
      debugPrint('DEBUG lecture du message initial impossible : $e');
    }

    try {
      await _creerCanalAndroid();

      final autorisation = await _messaging.requestPermission();
      if (autorisation.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await _messaging.getToken();
      if (token != null) await _enregistrerToken(token);

      _messaging.onTokenRefresh.listen(_enregistrerToken);

      await _demanderExemptionBatterie();
    } catch (e) {
      debugPrint('DEBUG notifications non disponibles sur cette plateforme : $e');
    }
  }

  /// Vraie autorisation Android (pas un réglage propre à une marque) pour
  /// exempter Vigie de la mise en veille forcée (Doze/optimisation
  /// batterie) — demandée via la fenêtre système standard, une seule fois,
  /// au même endroit que l'autorisation de notifications. Certains
  /// téléphones (MIUI, trouvé le 2026-08-14 ; Tecno/HiOS, trouvé le
  /// 2026-08-22) mettent l'app en veille assez fort pour bloquer soit la
  /// réception d'un rappel, soit son ouverture au tap — contrairement aux
  /// réglages "démarrage automatique" propres à chaque marque (aucune
  /// fenêtre système n'existe pour ceux-là, y compris pour Google
  /// Tasks/Todoist), celle-ci est une vraie API Android standard.
  Future<void> _demanderExemptionBatterie() async {
    final statut = await Permission.ignoreBatteryOptimizations.status;
    if (statut.isGranted) return;
    await Permission.ignoreBatteryOptimizations.request();
  }

  void _extraireDossier(RemoteMessage? message) {
    final dossierId = message?.data['dossierId'] as String?;
    if (dossierId != null && dossierId.isNotEmpty) {
      dossierAOuvrir.value = dossierId;
    }
  }

  Future<void> _creerCanalAndroid() async {
    const canal = AndroidNotificationChannel(
      _idCanalRappels,
      'Rappels Vigie',
      description: 'Rappels quotidiens des tâches à traiter (matin/soir).',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await _notificationsLocales
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(canal);
  }

  Future<void> _enregistrerToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('utilisateurs').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }
}
