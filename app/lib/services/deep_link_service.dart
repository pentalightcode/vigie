import 'dart:async';
import 'package:app_links/app_links.dart';

/// Écoute les liens ouverts depuis l'extérieur de l'app (ex: le lien magique
/// cliqué dans l'email) et les redistribue sous forme de flux de textes (URI).
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  final _controller = StreamController<String>.broadcast();
  Stream<String> get liens => _controller.stream;

  /// Ne fait qu'écouter les liens reçus APRÈS le démarrage (app déjà ouverte).
  /// Le lien qui a éventuellement servi à lancer l'app (premier chargement)
  /// est géré séparément par [lienInitial], pour éviter qu'il soit émis dans
  /// le flux avant que quiconque ne l'écoute (un StreamController broadcast
  /// jette silencieusement les événements sans abonné).
  void demarrer() {
    _subscription = _appLinks.uriLinkStream.listen((uri) {
      _controller.add(uri.toString());
    });
  }

  /// À appeler une fois l'écran prêt (ex: dans initState), pour récupérer
  /// le lien qui a éventuellement ouvert l'app la première fois.
  Future<String?> lienInitial() async {
    final uri = await _appLinks.getInitialLink();
    return uri?.toString();
  }

  void arreter() {
    _subscription?.cancel();
  }
}
