import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/version_service.dart';
import '../utils/confirmation.dart';

/// Bannière affichée en haut de l'écran principal quand une nouvelle version
/// de l'app est disponible — volontairement distincte des notifications
/// habituelles (pas dans l'historique /notifications), pour qu'on ne puisse
/// pas la manquer ni la confondre avec un simple rappel de dossier.
///
/// Purement informative, sans aucun élément cliquable : sur au moins un
/// téléphone réel (Xiaomi/MIUI), toute tentative d'ouvrir un navigateur ou
/// un lien depuis l'app a échoué silencieusement, cause jamais identifiée
/// malgré plusieurs tentatives (2026-08-17) — décision actée avec Tobie
/// d'arrêter d'essayer plutôt que de faire croire à un lien qui ne
/// fonctionne pas. La vraie notification push envoyée à chaque publication
/// (voir `publier_version_admin` côté serveur) et le site (toujours fiable,
/// testé à chaque fois) restent le chemin réel de mise à jour.
class BanniereMiseAJour extends StatefulWidget {
  const BanniereMiseAJour({super.key});

  @override
  State<BanniereMiseAJour> createState() => _BanniereMiseAJourState();
}

class _BanniereMiseAJourState extends State<BanniereMiseAJour> {
  InfosMiseAJour? _infos;

  @override
  void initState() {
    super.initState();
    VersionService.instance.verifierMiseAJour().then((infos) {
      if (mounted) setState(() => _infos = infos);
    });
  }

  @override
  Widget build(BuildContext context) {
    final infos = _infos;
    if (infos == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final couleurTexte = Theme.of(context).colorScheme.onPrimaryContainer;

    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.system_update, color: couleurTexte),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${infos.version.isNotEmpty ? l10n.banniereNouvelleVersionAvecNumero(infos.version) : l10n.banniereNouvelleVersionSansNumero} '
                  '${l10n.banniereInstructionTelechargement}',
                  style: TextStyle(color: couleurTexte),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.commonFermer,
                onPressed: () => _fermer(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fermer(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    // Double confirmation demandée par Tobie (2026-08-17) : un clic accidentel
    // ne doit pas faire disparaître l'alerte de mise à jour. Elle réapparaîtra
    // de toute façon au prochain lancement complet de l'app tant que la
    // version installée n'aura pas rattrapé celle publiée.
    final confirme = await demanderDoubleConfirmation(
      context,
      titre: l10n.banniereIgnorerTitre,
      message: l10n.banniereIgnorerMessage,
      texteBouton: l10n.banniereIgnorerBouton,
    );
    if (confirme && mounted) setState(() => _infos = null);
  }
}
