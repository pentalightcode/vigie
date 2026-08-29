import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/lock_service.dart';

/// Écran de verrou affiché à chaque ouverture de l'app une fois connecté.
/// Propose la biométrie automatiquement si disponible, sinon le code PIN.
class VerrouScreen extends StatefulWidget {
  const VerrouScreen({super.key, required this.onDeverrouille});

  final VoidCallback onDeverrouille;

  @override
  State<VerrouScreen> createState() => _VerrouScreenState();
}

class _VerrouScreenState extends State<VerrouScreen> {
  final _pinController = TextEditingController();
  String? _erreur;
  bool _biometrieProposee = false;

  @override
  void initState() {
    super.initState();
    _tenterBiometrie();
  }

  Future<void> _tenterBiometrie() async {
    final disponible = await LockService.instance.biometrieDisponible();
    if (!disponible || !mounted) return;
    setState(() => _biometrieProposee = true);
    final reussi = await LockService.instance.authentifierAvecBiometrie();
    if (reussi) widget.onDeverrouille();
  }

  Future<void> _validerPin() async {
    final l10n = AppLocalizations.of(context)!;
    final resultat = await LockService.instance.verifierPin(_pinController.text);
    if (resultat.correct) {
      widget.onDeverrouille();
      return;
    }
    if (!mounted) return;
    final attente = resultat.secondesAvantProchainEssai;
    setState(() => _erreur = attente != null ? l10n.verrouTropDeTentatives(attente) : l10n.verrouCodeIncorrect);
    _pinController.clear();
  }

  /// En cas d'oubli : on ne peut pas "retrouver" le code (il n'est pas
  /// stocké en clair nulle part), donc on repasse par l'email pour prouver
  /// l'identité, puis on repart sur la création d'un nouveau code.
  /// Les dossiers/tâches ne sont pas affectés : ils sont liés au compte,
  /// pas au PIN.
  Future<void> _codeOublie() async {
    final l10n = AppLocalizations.of(context)!;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.verrouCodeOublieTitre),
        content: Text(l10n.verrouCodeOublieMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonAnnuler)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.commonContinuer)),
        ],
      ),
    );
    if (confirme != true) return;

    await LockService.instance.reinitialiserPin();
    await AuthService.instance.seDeconnecter();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  _biometrieProposee ? l10n.verrouConfirmeIdentite : l10n.verrouEntreCodePin,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: l10n.verrouChampCodePin,
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                  onSubmitted: (_) => _validerPin(),
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 8),
                  Text(_erreur!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                FilledButton(onPressed: _validerPin, child: Text(l10n.verrouBoutonDeverrouiller)),
                if (_biometrieProposee)
                  TextButton(
                    onPressed: _tenterBiometrie,
                    child: Text(l10n.verrouReessayerBiometrie),
                  ),
                TextButton(
                  onPressed: _codeOublie,
                  child: Text(l10n.verrouCodeOublieTitre),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
