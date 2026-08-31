import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/dossier.dart';
import '../services/dossier_participants_service.dart';
import '../services/firestore_service.dart';
import '../utils/confirmation.dart';
import '../widgets/vue_acces_revoque.dart';

/// Gestion des participants d'un dossier partagé (ajouté le 2026-08-29,
/// refonte "travail de groupe" — voir
/// Notes/2026-08-29-redteam-collaboration-multi-angles.md). Toute action
/// passe par la fonction serveur `gerer_participant_dossier` (voir
/// DossierParticipantsService) : c'est elle qui résout l'email en compte
/// Vigie, vérifie le rôle du demandeur, et synchronise participantsUids sur
/// les tâches/entrées de journal déjà existantes du dossier.
class ParticipantsDossierScreen extends StatefulWidget {
  const ParticipantsDossierScreen({super.key, required this.dossierId});
  final String dossierId;

  @override
  State<ParticipantsDossierScreen> createState() => _ParticipantsDossierScreenState();
}

class _ParticipantsDossierScreenState extends State<ParticipantsDossierScreen> {
  bool _actionEnCours = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.participantsTitre)),
      body: StreamBuilder<Dossier>(
        stream: FirestoreService.instance.dossier(widget.dossierId),
        builder: (context, snapshot) {
          // Accès révoqué pendant la consultation — voir VueAccesRevoque.
          if (snapshot.hasError) {
            return VueAccesRevoque(erreur: snapshot.error);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final dossier = snapshot.data!;
          // Repli défensif plutôt qu'un `!.uid` (trouvé en Red Team le
          // 2026-08-30, via /code-review — même raison que dans
          // dossier_detail_screen.dart).
          final monUid = FirebaseAuth.instance.currentUser?.uid;
          if (monUid == null) {
            return const VueAccesRevoque();
          }
          final monRole = dossier.roleDe(monUid);
          final jeSuisCreateur = monRole == 'createur';
          final jePeuxGerer = monRole == 'createur' || monRole == 'administrateur';

          final participants = dossier.roles.entries.toList()
            ..sort((a, b) => _ordreRole(a.value).compareTo(_ordreRole(b.value)));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!jePeuxGerer)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.participantsLectureSeuleInfo,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ...participants.map(
                (entree) => _LigneParticipant(
                  uid: entree.key,
                  role: entree.value,
                  email: dossier.participantsEmails[entree.key],
                  estMoi: entree.key == monUid,
                  // Un administrateur ne gère que des contributeurs — seul le
                  // créateur peut toucher à un autre administrateur (décision
                  // du 2026-08-30, en continuant le Red Team). Oubli corrigé
                  // via /code-review : le `jePeuxGerer` du viewer lui-même
                  // n'était plus vérifié ici — un simple contributeur voyait
                  // le menu de gestion sur les autres contributeurs.
                  peutGerer: jePeuxGerer && entree.value != 'createur' && (jeSuisCreateur || entree.value != 'administrateur'),
                  jeSuisCreateur: jeSuisCreateur,
                  enCours: _actionEnCours,
                  onChangerRole: (nouveauRole) => _changerRole(dossier.id, entree.key, nouveauRole),
                  onRetirer: () => _retirer(
                    dossier.id,
                    entree.key,
                    dossier.participantsEmails[entree.key] ?? entree.key,
                  ),
                  onQuitter: () => _quitter(dossier.id, entree.key),
                ),
              ),
              if (jePeuxGerer) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _actionEnCours ? null : () => _ajouter(dossier.id, jeSuisCreateur),
                  icon: const Icon(Icons.person_add),
                  label: Text(l10n.participantsAjouterBouton),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  int _ordreRole(String role) => switch (role) {
        'createur' => 0,
        'administrateur' => 1,
        _ => 2,
      };

  String _messageErreur(Object e) {
    final l10n = AppLocalizations.of(context)!;
    if (e is FirebaseFunctionsException) {
      return switch (e.code) {
        'not-found' => l10n.participantsErreurAucunCompte,
        'already-exists' => l10n.participantsErreurDejaParticipant,
        'permission-denied' => l10n.participantsErreurPermission,
        // Le texte brut envoyé par la fonction (e.message) est toujours en
        // français — on ne s'appuie plus dessus pour l'affichage (trouvé en
        // Red Team le 2026-08-30) : la fonction envoie plutôt un code stable
        // dans `details`, traduit ici selon la langue de l'appareil.
        'failed-precondition' => switch (e.details) {
            'createurNonRetirable' => l10n.participantsErreurCreateurNonRetirable,
            'createurRoleFixe' => l10n.participantsErreurCreateurRoleFixe,
            _ => l10n.participantsErreurGenerique,
          },
        _ => l10n.participantsErreurGenerique,
      };
    }
    return l10n.participantsErreurGenerique;
  }

  /// Renvoie `true` en cas de succès — utile pour `_quitter`, qui doit
  /// revenir en arrière seulement si l'action a réellement abouti.
  Future<bool> _executer(Future<void> Function() action) async {
    setState(() => _actionEnCours = true);
    var succes = false;
    try {
      await action();
      succes = true;
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.participantsErreur(_messageErreur(e)))),
        );
      }
    } finally {
      if (mounted) setState(() => _actionEnCours = false);
    }
    return succes;
  }

  Future<void> _ajouter(String dossierId, bool jeSuisCreateur) async {
    final resultat = await showDialog<({String email, String role})>(
      context: context,
      builder: (context) => _DialogueAjouterParticipant(jeSuisCreateur: jeSuisCreateur),
    );
    if (resultat == null || !mounted) return;
    await _executer(
      () => DossierParticipantsService.instance.ajouter(
        dossierId: dossierId,
        email: resultat.email,
        role: resultat.role,
      ),
    );
  }

  Future<void> _retirer(String dossierId, String uid, String affichage) async {
    final l10n = AppLocalizations.of(context)!;
    final confirme = await demanderDoubleConfirmation(
      context,
      titre: l10n.participantsRetirerTitre,
      message: l10n.participantsRetirerMessage(affichage),
      texteBouton: l10n.commonRetirer,
      destructif: true,
    );
    if (!confirme || !mounted) return;
    await _executer(() => DossierParticipantsService.instance.retirer(dossierId: dossierId, uid: uid));
  }

  Future<void> _changerRole(String dossierId, String uid, String role) async {
    await _executer(() => DossierParticipantsService.instance.changerRole(dossierId: dossierId, uid: uid, role: role));
  }

  /// Quitter un dossier partagé — décidé par Tobie le 2026-08-30 ("tranchons
  /// alors") : jusqu'ici, seuls créateur/administrateur pouvaient appeler
  /// "retirer", donc même se retirer SOI-MÊME était bloqué pour tout le
  /// monde. Réutilise la même action serveur, ciblée sur soi-même — la
  /// fonction l'autorise maintenant sans exiger le rôle habituel.
  Future<void> _quitter(String dossierId, String uid) async {
    final l10n = AppLocalizations.of(context)!;
    final confirme = await demanderDoubleConfirmation(
      context,
      titre: l10n.participantsQuitterTitre,
      message: l10n.participantsQuitterMessage,
      texteBouton: l10n.participantsQuitterBouton,
      destructif: true,
    );
    if (!confirme || !mounted) return;
    final succes = await _executer(() => DossierParticipantsService.instance.retirer(dossierId: dossierId, uid: uid));
    if (succes && mounted) Navigator.of(context).pop();
  }
}

class _LigneParticipant extends StatelessWidget {
  const _LigneParticipant({
    required this.uid,
    required this.role,
    required this.email,
    required this.estMoi,
    required this.peutGerer,
    required this.jeSuisCreateur,
    required this.enCours,
    required this.onChangerRole,
    required this.onRetirer,
    required this.onQuitter,
  });

  final String uid;
  final String role;
  final String? email;
  final bool estMoi;
  final bool peutGerer;
  final bool jeSuisCreateur;
  final bool enCours;
  final void Function(String nouveauRole) onChangerRole;
  final VoidCallback onRetirer;
  final VoidCallback onQuitter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final libelleRole = switch (role) {
      'createur' => l10n.participantsRoleCreateur,
      'administrateur' => l10n.participantsRoleAdministrateur,
      _ => l10n.participantsRoleContributeur,
    };
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(email ?? uid),
      subtitle: Text(estMoi ? l10n.participantsSousTitreMoi(libelleRole) : libelleRole),
      // Se retirer soi-même : possible pour tout le monde sauf le créateur
      // (décision de Tobie le 2026-08-30, "tranchons alors") — prioritaire
      // sur le menu de gestion habituel, qui ne s'applique jamais à sa
      // propre ligne de toute façon (peutGerer exclut déjà "soi-même
      // administrateur", voir le calcul côté écran).
      trailing: estMoi && role != 'createur'
          ? IconButton(
              icon: const Icon(Icons.logout),
              tooltip: l10n.participantsQuitterBouton,
              onPressed: enCours ? null : onQuitter,
            )
          : peutGerer
          ? PopupMenuButton<String>(
              enabled: !enCours,
              onSelected: (choix) => choix == 'retirer' ? onRetirer() : onChangerRole(choix),
              itemBuilder: (context) => [
                // Promouvoir administrateur : réservé au créateur (décision
                // du 2026-08-30) — un administrateur ne peut créer un pair.
                if (role != 'administrateur' && jeSuisCreateur)
                  PopupMenuItem(value: 'administrateur', child: Text(l10n.participantsMenuPasserAdministrateur)),
                if (role != 'contributeur')
                  PopupMenuItem(value: 'contributeur', child: Text(l10n.participantsMenuPasserContributeur)),
                PopupMenuItem(value: 'retirer', child: Text(l10n.commonRetirer)),
              ],
            )
          : null,
    );
  }
}

class _DialogueAjouterParticipant extends StatefulWidget {
  const _DialogueAjouterParticipant({required this.jeSuisCreateur});
  final bool jeSuisCreateur;

  @override
  State<_DialogueAjouterParticipant> createState() => _DialogueAjouterParticipantState();
}

class _DialogueAjouterParticipantState extends State<_DialogueAjouterParticipant> {
  final _controleurEmail = TextEditingController();
  String _role = 'contributeur';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.participantsDialogueAjouterTitre),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controleurEmail,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.participantsDialogueAjouterChampEmail,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: InputDecoration(
              labelText: l10n.participantsDialogueAjouterChampRole,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'contributeur', child: Text(l10n.participantsRoleContributeur)),
              // Inviter directement en administrateur : réservé au créateur
              // (décision du 2026-08-30) — un administrateur ne peut créer un pair.
              if (widget.jeSuisCreateur)
                DropdownMenuItem(value: 'administrateur', child: Text(l10n.participantsRoleAdministrateur)),
            ],
            onChanged: (valeur) => setState(() => _role = valeur ?? 'contributeur'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonAnnuler)),
        FilledButton(
          onPressed: () {
            final email = _controleurEmail.text.trim();
            if (email.isEmpty) return;
            Navigator.pop(context, (email: email, role: _role));
          },
          child: Text(l10n.participantsAjouterBouton),
        ),
      ],
    );
  }
}
