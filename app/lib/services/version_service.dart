import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Info sur une mise à jour disponible, quand la version publiée est plus
/// récente que celle installée sur l'appareil.
class InfosMiseAJour {
  InfosMiseAJour({required this.version, required this.urlApk});
  final String version;
  final String urlApk;
}

/// Vérifie si une nouvelle version de l'app a été publiée, en comparant le
/// numéro de build local (pubspec.yaml, ex: 1.0.1+2 → build 2) à la valeur
/// de référence dans /config/version. Ce document est écrit uniquement par
/// le script de publication (scripts/publier_version.py), jamais par un
/// téléphone — voir firestore.rules (décision du 2026-08-17 : bannière
/// dédiée au lancement plutôt qu'une vraie notification push, plus simple
/// et fiable, rien à déclencher manuellement à chaque publication).
class VersionService {
  VersionService._();
  static final VersionService instance = VersionService._();

  Future<InfosMiseAJour?> verifierMiseAJour() async {
    final infosApp = await PackageInfo.fromPlatform();
    final buildActuel = int.tryParse(infosApp.buildNumber) ?? 0;

    final data = await _lireDocVersion();
    if (data == null) return null;

    final buildDisponible = data['build'] as int? ?? 0;
    final urlApk = data['urlApk'] as String?;
    if (buildDisponible <= buildActuel || urlApk == null || urlApk.isEmpty) {
      return null;
    }

    return InfosMiseAJour(
      version: data['version'] as String? ?? '',
      urlApk: urlApk,
    );
  }

  /// Juste le numéro de la dernière version publiée, sans comparaison — pour
  /// l'afficher sur le site (demandé par Tobie le 2026-08-17 : préciser la
  /// version à jour à côté du bouton de téléchargement).
  Future<String?> derniereVersionPubliee() async {
    final data = await _lireDocVersion();
    return data?['version'] as String?;
  }

  Future<Map<String, dynamic>?> _lireDocVersion() async {
    final doc = await FirebaseFirestore.instance.collection('config').doc('version').get();
    return doc.data();
  }
}
