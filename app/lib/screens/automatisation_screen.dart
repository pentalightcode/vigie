import 'package:flutter/material.dart';
import '../models/connexion_google.dart';
import '../models/etat_sync.dart';
import '../models/proposition_dossier.dart';
import '../models/reglages_utilisateur.dart';
import '../services/gmail_service.dart';
import '../services/utilisateur_service.dart';
import '../utils/confirmation.dart';
import '../utils/dates_fr.dart';
import 'propositions_screen.dart';

/// Écran "Automatisation" (Profil) : connecter un ou plusieurs comptes
/// Google pour détecter automatiquement les nouvelles dates d'audience,
/// gérer les expéditeurs de confiance, et choisir la méthode d'extraction
/// (motif de texte, gratuit et recommandé, ou IA, payant avec avertissement
/// — décision du 2026-08-15).
///
/// Aucun rôle prédéfini par compte (revu le 2026-08-21, sur retour de Tobie
/// après test réel) : l'utilisateur connecte autant de comptes qu'il veut
/// (typiquement 1 à quelques-uns) et peut leur donner un libellé personnel,
/// purement pour s'y retrouver — chaque compte est scanné de la même façon.
class AutomatisationScreen extends StatefulWidget {
  const AutomatisationScreen({super.key});

  @override
  State<AutomatisationScreen> createState() => _AutomatisationScreenState();
}

class _AutomatisationScreenState extends State<AutomatisationScreen> {
  bool _actionEnCours = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Automatisation')),
      body: StreamBuilder<ReglagesUtilisateur>(
        stream: UtilisateurService.instance.reglages(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reglages = snapshot.data!;
          // Les connexions Google sont indépendantes de "reglages" (document
          // distinct) — flux séparé, même principe que _SectionEtatSync.
          return StreamBuilder<List<ConnexionGoogle>>(
            stream: GmailService.instance.connexionsGoogle(),
            builder: (context, snapshotConnexions) {
              final connexions = snapshotConnexions.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Comptes Google', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  const Text(
                    'Connecte autant de comptes que tu veux (perso, secondaire...) — '
                    'donne-leur un nom pour t\'y retrouver, si tu veux.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ...connexions.map((c) => _LigneConnexion(
                        connexion: c,
                        enCours: _actionEnCours,
                        onRenommer: _renommer,
                        onDeconnecter: _deconnecter,
                      )),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: OutlinedButton.icon(
                      onPressed: _actionEnCours ? null : _connecter,
                      icon: _actionEnCours
                          ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_link, size: 18),
                      label: Text(connexions.isEmpty ? 'Connecter un compte Google' : 'Connecter un autre compte'),
                    ),
                  ),
                  if (connexions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    StreamBuilder<List<PropositionDossier>>(
                      stream: GmailService.instance.propositions(),
                      builder: (context, snapshot) {
                        final nombre = snapshot.data?.length ?? 0;
                        return OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PropositionsScreen()),
                          ),
                          icon: const Icon(Icons.fact_check_outlined),
                          label: Text(
                            nombre > 0 ? 'Propositions à valider ($nombre)' : 'Propositions à valider',
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const _SectionEtatSync(),
                  ],
                  const Divider(height: 32),
                  _SectionMethode(reglages: reglages),
                  const Divider(height: 32),
                  _SectionExpediteurs(reglages: reglages, connecteEmail: connexions.isNotEmpty),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _connecter() async {
    setState(() => _actionEnCours = true);
    try {
      final email = await GmailService.instance.connecter();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compte connecté : $email')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connexion impossible : $e'), duration: const Duration(seconds: 10)),
        );
      }
    } finally {
      if (mounted) setState(() => _actionEnCours = false);
    }
  }

  Future<void> _deconnecter(ConnexionGoogle connexion) async {
    final confirme = await demanderDoubleConfirmation(
      context,
      titre: 'Déconnecter ce compte Google ?',
      message: '"${connexion.affichage}" ne sera plus scanné automatiquement '
          '(emails, tâches, agenda).',
    );
    if (!confirme) return;
    setState(() => _actionEnCours = true);
    try {
      await GmailService.instance.deconnecter(connexion.id);
    } finally {
      if (mounted) setState(() => _actionEnCours = false);
    }
  }

  Future<void> _renommer(ConnexionGoogle connexion) async {
    final controleur = TextEditingController(text: connexion.libelle);
    final nouveauLibelle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer ce compte'),
        content: TextField(
          controller: controleur,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nom (facultatif)',
            hintText: connexion.emailConnecte,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controleur.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (nouveauLibelle == null) return;
    await GmailService.instance.renommerConnexion(connexion.id, nouveauLibelle);
  }
}

/// Une ligne par compte Google connecté — nom (personnalisé ou adresse),
/// bouton renommer et déconnecter (bug corrigé le 2026-08-21 : le design à
/// deux cartes fixes du même jour rendait la déconnexion peu visible/confuse).
class _LigneConnexion extends StatelessWidget {
  const _LigneConnexion({
    required this.connexion,
    required this.enCours,
    required this.onRenommer,
    required this.onDeconnecter,
  });

  final ConnexionGoogle connexion;
  final bool enCours;
  final void Function(ConnexionGoogle) onRenommer;
  final void Function(ConnexionGoogle) onDeconnecter;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(connexion.affichage, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: connexion.libelle.isNotEmpty ? Text(connexion.emailConnecte) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Renommer',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: enCours ? null : () => onRenommer(connexion),
            ),
            IconButton(
              tooltip: 'Déconnecter',
              icon: const Icon(Icons.link_off, size: 20),
              onPressed: enCours ? null : () => onDeconnecter(connexion),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionMethode extends StatelessWidget {
  const _SectionMethode({required this.reglages});

  final ReglagesUtilisateur reglages;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Méthode d'extraction des dates", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: reglages.methodeExtraction,
          onChanged: (v) => _choisir(context, v!),
          child: const Column(
            children: [
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: 'motif',
                title: Text('Recherche de motif (recommandé)'),
                subtitle: Text('Gratuit — reste entièrement dans nos serveurs, rien envoyé ailleurs.'),
              ),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: 'ia',
                title: Text('Intelligence artificielle'),
                subtitle: Text('Plus fiable sur des emails mal formatés — voir les risques avant d\'activer.'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _choisir(BuildContext context, String methode) async {
    if (methode == 'ia') {
      final confirme = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Avant d\'activer l\'IA'),
          content: const Text(
            "Avec cette option, le contenu complet de chaque email reçu d'un "
            "expéditeur de confiance est envoyé à un service d'intelligence "
            "artificielle tiers pour y être lu — pas seulement la date trouvée. "
            "Pour des emails judiciaires réels, c'est une exposition à prendre "
            "au sérieux. La recherche de motif (option recommandée) ne fait "
            'jamais sortir aucune donnée de nos serveurs.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Activer quand même'),
            ),
          ],
        ),
      );
      if (confirme != true) return;
    }
    await GmailService.instance.definirMethodeExtraction(methode);
  }
}

class _SectionExpediteurs extends StatefulWidget {
  const _SectionExpediteurs({required this.reglages, required this.connecteEmail});

  final ReglagesUtilisateur reglages;
  /// Spécifiquement la connexion "email" (Gmail) — pas "agenda" : le
  /// catalogue d'expéditeurs lit la boîte mail, pas Tasks/Calendar.
  final bool connecteEmail;

  @override
  State<_SectionExpediteurs> createState() => _SectionExpediteursState();
}

class _SectionExpediteursState extends State<_SectionExpediteurs> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Expéditeurs favoris', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          'Seuls les emails venant de ces adresses seront lus (ex : celle du tribunal).',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        if (widget.connecteEmail) ...[
          OutlinedButton.icon(
            onPressed: () => _choisirDepuisBoite(context),
            icon: const Icon(Icons.checklist),
            label: const Text('Choisir depuis ma boîte mail'),
          ),
          const SizedBox(height: 12),
          const Text('Ou ajoute une adresse manuellement :', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Adresse email',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _ajouter(context),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.reglages.expediteursConfiance.map((email) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline),
              title: Text(email),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _retirer(context, email),
              ),
            )),
        if (widget.reglages.expediteursConfiance.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucun expéditeur ajouté pour l\'instant.', style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }

  Future<void> _choisirDepuisBoite(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FeuilleChoixExpediteurs(deja: widget.reglages.expediteursConfiance),
    );
  }

  static final _formatEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> _retirer(BuildContext context, String email) async {
    final confirme = await demanderDoubleConfirmation(
      context,
      titre: 'Retirer cet expéditeur ?',
      message: 'Les emails de "$email" ne seront plus lus automatiquement.',
      texteBouton: 'Retirer',
      destructif: true,
    );
    if (confirme) {
      await GmailService.instance.retirerExpediteurConfiance(email);
    }
  }

  Future<void> _ajouter(BuildContext context) async {
    final email = _controller.text.trim();
    if (!_formatEmail.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresse email invalide.')),
      );
      return;
    }

    // Vérification technique : le domaine a-t-il des serveurs mail
    // configurés ? Ça attrape une faute de frappe dans le domaine — mais ne
    // garantit pas qu'une boîte précise existe (Gmail bloque cette sonde).
    final domaineValide = await GmailService.instance.domaineValide(email);
    if (!context.mounted) return;
    if (!domaineValide) {
      final confirme = await demanderDoubleConfirmation(
        context,
        titre: 'Ce domaine semble introuvable',
        message:
            'Aucun serveur mail trouvé pour "${email.split('@').last}" — '
            'vérifie qu\'il n\'y a pas de faute de frappe.\n\nAjouter quand même : $email ?',
        texteBouton: 'Ajouter quand même',
        destructif: true,
      );
      if (!confirme) return;
      if (!context.mounted) return;
    }

    // Relecture, en plus de la vérification technique — rattrape une bonne
    // adresse mais destinataire différent de ce qu'on croyait taper.
    final confirme = await demanderDoubleConfirmation(
      context,
      titre: 'Ajouter cet expéditeur ?',
      message: 'Vérifie bien qu\'il n\'y a pas de faute de frappe :\n\n$email',
      texteBouton: 'Ajouter',
    );
    if (!confirme) return;
    await GmailService.instance.ajouterExpediteurConfiance(email);
    if (context.mounted) _controller.clear();
  }
}

/// Liste à cocher des expéditeurs trouvés dans les emails récents de la
/// boîte connectée — choisis dans de vraies données, pas tapés à la main,
/// donc aucun risque de faute de frappe (demandé par Tobie le 2026-08-15).
class _FeuilleChoixExpediteurs extends StatefulWidget {
  const _FeuilleChoixExpediteurs({required this.deja});

  final List<String> deja;

  @override
  State<_FeuilleChoixExpediteurs> createState() => _FeuilleChoixExpediteursState();
}

class _FeuilleChoixExpediteursState extends State<_FeuilleChoixExpediteurs> {
  late final Future<List<({String email, int nombre})>> _futur =
      GmailService.instance.expediteursRecents();
  final _selectionnes = <String>{};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<({String email, int nombre})>>(
          future: _futur,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Impossible de lire la boîte mail : ${snapshot.error}'));
            }
            final expediteurs = (snapshot.data ?? [])
                .where((e) => !widget.deja.contains(e.email))
                .toList();
            if (expediteurs.isEmpty) {
              return const Center(child: Text('Aucun nouvel expéditeur trouvé dans les emails récents.'));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expéditeurs trouvés', style: Theme.of(context).textTheme.titleMedium),
                const Text(
                  'Coche ceux à qui tu fais confiance (ex : le tribunal).',
                  style: TextStyle(color: Colors.grey),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: expediteurs
                        .map((e) => CheckboxListTile(
                              value: _selectionnes.contains(e.email),
                              title: Text(e.email),
                              subtitle: Text('${e.nombre} email(s) récent(s)'),
                              onChanged: (coche) => setState(() {
                                if (coche ?? false) {
                                  _selectionnes.add(e.email);
                                } else {
                                  _selectionnes.remove(e.email);
                                }
                              }),
                            ))
                        .toList(),
                  ),
                ),
                FilledButton(
                  onPressed: _selectionnes.isEmpty ? null : () => _valider(context),
                  child: Text('Ajouter (${_selectionnes.length})'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _valider(BuildContext context) async {
    for (final email in _selectionnes) {
      await GmailService.instance.ajouterExpediteurConfiance(email);
    }
    if (context.mounted) Navigator.pop(context);
  }
}

/// Transparence de synchronisation (demandé par Tobie le 2026-08-20,
/// inspiré du "Dernière synchronisation" vu sur une autre app) : sans ça,
/// un échec silencieux d'une des 3 vérifications automatiques ne se voyait
/// nulle part — juste une absence de résultat, sans explication.
class _SectionEtatSync extends StatelessWidget {
  const _SectionEtatSync();

  static const _libelles = {'gmail': 'Gmail', 'tasks': 'Google Tasks', 'calendar': 'Google Calendar'};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, EtatSync>>(
      stream: GmailService.instance.etatsSync(),
      builder: (context, snapshot) {
        final etats = snapshot.data ?? {};
        return Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vérification automatique', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                ..._libelles.entries.map((entree) {
                  final etat = etats[entree.key];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          etat == null
                              ? Icons.remove_circle_outline
                              : (etat.succes ? Icons.check_circle : Icons.error),
                          size: 16,
                          color: etat == null
                              ? Colors.grey
                              : (etat.succes ? Colors.green : Colors.red),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            etat == null
                                ? '${entree.value} : pas encore vérifié'
                                : '${entree.value} : ${etat.succes ? 'OK' : 'Erreur'}'
                                    '${etat.derniereExecution != null ? ' — ${formaterDateHeureFr(etat.derniereExecution!)}' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
