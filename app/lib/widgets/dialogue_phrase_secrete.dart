import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/chiffrement_notes_service.dart';

/// Ouvre le dialogue de phrase secrète — création la toute première fois,
/// déverrouillage les fois suivantes. Renvoie true si les notes sont
/// déverrouillées à la sortie (y compris si elles l'étaient déjà avant
/// l'appel, ou après une création réussie).
Future<bool> demanderPhraseSecrete(BuildContext context) async {
  if (await ChiffrementNotesService.instance.tenterDeverrouillageAutomatique()) return true;
  final dejaDefinie = await ChiffrementNotesService.instance.phraseDejaDefinie();
  if (!context.mounted) return false;
  final resultat = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _DialoguePhraseSecrete(creation: !dejaDefinie),
  );
  return resultat ?? false;
}

class _DialoguePhraseSecrete extends StatefulWidget {
  const _DialoguePhraseSecrete({required this.creation});
  final bool creation;

  @override
  State<_DialoguePhraseSecrete> createState() => _DialoguePhraseSecreteState();
}

class _DialoguePhraseSecreteState extends State<_DialoguePhraseSecrete> {
  final _phraseControleur = TextEditingController();
  final _confirmationControleur = TextEditingController();
  bool _enCours = false;
  bool _visible = false;
  String? _erreur;

  Future<void> _valider() async {
    final l10n = AppLocalizations.of(context)!;
    final phrase = _phraseControleur.text;
    if (phrase.length < 8) {
      setState(() => _erreur = l10n.phraseSecreteErreurTropCourte);
      return;
    }
    if (widget.creation && phrase != _confirmationControleur.text) {
      setState(() => _erreur = l10n.phraseSecreteErreurNeCorrespondentPas);
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      if (widget.creation) {
        await ChiffrementNotesService.instance.definirPhrase(phrase);
        if (mounted) Navigator.pop(context, true);
      } else {
        final correcte = await ChiffrementNotesService.instance.deverrouillerAvecPhrase(phrase);
        if (!mounted) return;
        if (correcte) {
          Navigator.pop(context, true);
        } else {
          setState(() {
            _erreur = l10n.phraseSecreteErreurIncorrecte;
            _enCours = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _erreur = l10n.phraseSecreteErreurGenerique;
          _enCours = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _phraseControleur.dispose();
    _confirmationControleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.creation ? l10n.phraseSecreteTitreCreation : l10n.phraseSecreteTitreDeverrouillage),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.creation) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.onErrorContainer, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.phraseSecreteAvertissement,
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Text(l10n.phraseSecreteInstructionsDeverrouillage),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _phraseControleur,
              obscureText: !_visible,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.phraseSecreteChamp,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _visible = !_visible),
                ),
              ),
              onSubmitted: widget.creation ? null : (_) => _valider(),
            ),
            if (widget.creation) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _confirmationControleur,
                obscureText: !_visible,
                decoration: InputDecoration(
                  labelText: l10n.phraseSecreteChampConfirmation,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _visible = !_visible),
                  ),
                ),
                onSubmitted: (_) => _valider(),
              ),
            ],
            if (_erreur != null) ...[
              const SizedBox(height: 8),
              Text(_erreur!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enCours ? null : () => Navigator.pop(context, false),
          child: Text(l10n.commonAnnuler),
        ),
        FilledButton(
          onPressed: _enCours ? null : _valider,
          child: _enCours
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.creation ? l10n.phraseSecreteBoutonCreer : l10n.phraseSecreteBoutonDeverrouiller),
        ),
      ],
    );
  }
}
