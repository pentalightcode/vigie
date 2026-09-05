import re
import os

filepath = 'app/lib/screens/dossier_detail_screen.dart'
with open(filepath, 'r') as f:
    content = f.read()

# 1. Remove encryption imports
content = re.sub(r"import '\.\./services/chiffrement_notes_service\.dart';\n", "", content)
content = re.sub(r"import '\.\./widgets/dialogue_phrase_secrete\.dart';\n", "", content)

# Add IA screen import
if "import 'assistant_ia_screen.dart';" not in content:
    content = content.replace("import 'participants_dossier_screen.dart';", "import 'assistant_ia_screen.dart';\nimport 'participants_dossier_screen.dart';")

# 2. Add Assistant IA Button in SliverAppBar
ia_button = """                  IconButton(
                    icon: const Icon(Icons.auto_awesome),
                    tooltip: 'Assistant IA',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AssistantIaScreen(
                          dossierId: dossier.id,
                          nomCodeDossier: dossier.nomCode,
                        ),
                      ),
                    ),
                  ),\n"""
if "Icons.auto_awesome" not in content:
    content = content.replace(
        "                actions: [\n                  if (role == 'administrateur')",
        "                actions: [\n" + ia_button + "                  if (role == 'administrateur')"
    )

# 3. Remove _EntreeAffichable class entirely
content = re.sub(r"/// Une entrée prête à afficher.*?\nclass _EntreeAffichable \{.*?\n\}\n", "", content, flags=re.DOTALL)

# 4. Remove _dechiffrerToutes function entirely (from _SectionJournalState)
content = re.sub(r"  /// Déchiffre chaque entrée marquée.*?Future<List<_EntreeAffichable>> _dechiffrerToutes\(List<EntreeJournal> entrees\) async \{.*?\n  \}\n", "", content, flags=re.DOTALL)

# 5. Remove initState from _SectionJournalState
content = re.sub(r"  @override\n  void initState\(\) \{.*?\n  \}\n", "", content, flags=re.DOTALL)

# 6. Replace _EntreeAffichable with EntreeJournal in method signatures
content = content.replace("List<_EntreeAffichable>", "List<EntreeJournal>")
content = content.replace("<_EntreeAffichable>", "<EntreeJournal>")
content = content.replace("_EntreeAffichable affichable", "EntreeJournal entree")
content = content.replace("Iterable<_EntreeAffichable>", "Iterable<EntreeJournal>")

# 7. Fix _ajouter method
ajouter_old = """    if (widget.dossier.participantsUids.length <= 1) {
      final deverrouille = await demanderPhraseSecrete(context);
      if (!deverrouille || !mounted) return;
    }
    setState(() => _enCours = true);
    try {
      // Relu ICI, pas avant l'attente ci-dessus (trouvé en Red Team le
      // 2026-08-30, via /code-review) : le dossier peut avoir été partagé
      // PENDANT que l'utilisateur saisissait sa phrase secrète — utiliser
      // une valeur capturée avant l'attente aurait pu chiffrer une entrée
      // qui atterrit dans un dossier déjà devenu partagé entre-temps.
      //
      // Lu depuis le SERVEUR, pas `widget.participantsUids` (trouvé en
      // re-vérifiant ce correctif, via /code-review, le 2026-08-31) : même
      // raison que pour l'ajout de tâche (voir dossierDepuisServeur) — un
      // prop mis en cache par le dernier instantané reçu peut être périmé
      // de deux façons ici, l'écriture ET la décision de chiffrement.
      final dossierActuel = await FirestoreService.instance.dossierDepuisServeur(widget.dossier.id);
      final estPartage = dossierActuel.participantsUids.length > 1;
      final texteAEcrire = estPartage ? texte : await ChiffrementNotesService.instance.chiffrer(texte);
      if (dossierActuel.estGestionnaireContenu(widget.monUid)) {
        await FirestoreService.instance.ajouterEntreeJournal(
          widget.dossier.id,
          texteAEcrire,
          _typeSelectionne,
          chiffre: !estPartage,
          participantsUids: dossierActuel.participantsUids,
          mentionsUids: _mentionsUids.toList(),
        );
      } else {
        await FirestoreService.instance.ajouterEntreeJournal(
          widget.dossier.id,
          texteAEcrire,
          _typeSelectionne,
          chiffre: !estPartage,
          participantsUids: dossierActuel.participantsUids,
          proposerSeulement: true,
          mentionsUids: _mentionsUids.toList(),
        );"""
ajouter_new = """    setState(() => _enCours = true);
    try {
      final dossierActuel = await FirestoreService.instance.dossierDepuisServeur(widget.dossier.id);
      if (dossierActuel.estGestionnaireContenu(widget.monUid)) {
        await FirestoreService.instance.ajouterEntreeJournal(
          widget.dossier.id,
          texte,
          _typeSelectionne,
          participantsUids: dossierActuel.participantsUids,
          mentionsUids: _mentionsUids.toList(),
        );
      } else {
        await FirestoreService.instance.ajouterEntreeJournal(
          widget.dossier.id,
          texte,
          _typeSelectionne,
          participantsUids: dossierActuel.participantsUids,
          proposerSeulement: true,
          mentionsUids: _mentionsUids.toList(),
        );"""
content = content.replace(ajouter_old, ajouter_new)
content = re.sub(r"    // Chiffrement désactivé dès qu'un dossier est partagé.*?\n    // strictement solo, où ce problème ne se pose pas\.\n", "", content, flags=re.DOTALL)

# 8. Fix _editer method
editer_old = """    if (entree.chiffre) {
      final deverrouille = await demanderPhraseSecrete(context);
      if (!deverrouille || !context.mounted) return;
    }
    final controleur = TextEditingController(text: entree.texte);"""
editer_new = """    final controleur = TextEditingController(text: entree.texte);"""
content = content.replace(editer_old, editer_new)

editer_old2 = """    try {
      final texteAEcrire = entree.chiffre ? await ChiffrementNotesService.instance.chiffrer(texte) : texte;
      if (direct) {
        await FirestoreService.instance.modifierEntreeJournal(entree.id, texteAEcrire, type);
      } else {
        await FirestoreService.instance.proposerModificationEntreeJournal(
          entree.copierAvec(texte: texteAEcrire, type: type),
        );
      }"""
editer_new2 = """    try {
      if (direct) {
        await FirestoreService.instance.modifierEntreeJournal(entree.id, texte, type);
      } else {
        await FirestoreService.instance.proposerModificationEntreeJournal(
          entree.copierAvec(texte: texte, type: type),
        );
      }"""
content = content.replace(editer_old2, editer_new2)

# 9. Remove FutureBuilder from journal stream
fb_old = """                  // Le déchiffrement est asynchrone (AES-GCM) — imbriqué dans un
                  // second FutureBuilder plutôt que de bloquer le StreamBuilder
                  // parent, pour que les nouvelles entrées Firestore continuent
                  // d'arriver en direct pendant qu'une entrée se déchiffre.
                  return FutureBuilder<List<EntreeJournal>>(
                    future: _dechiffrerToutes(entrees),
                    builder: (context, snapshotAffichables) {
                      if (!snapshotAffichables.hasData) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final affichables = snapshotAffichables.data!;
                      final affichablesFiltres = _filtreType == null
                          ? affichables
                          : affichables.where((a) => a.entree.type == _filtreType).toList();"""
fb_new = """                  final affichablesFiltres = _filtreType == null
                      ? entrees
                      : entrees.where((a) => a.type == _filtreType).toList();"""
content = content.replace(fb_old, fb_new)

# Fix the end brackets of the StreamBuilder
content = re.sub(r"                        \],?\n                      \);\n                    \},?\n                  \);", "                        ],\n                      );", content)

# 10. In build, remove the deverrouiller button section
dev_old = """              if (!ChiffrementNotesService.instance.estDeverrouille) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final deverrouille = await demanderPhraseSecrete(context);
                    if (deverrouille && mounted) setState(() {});
                  },
                  icon: const Icon(Icons.lock_open_outlined, size: 16),
                  label: Text(l10n.dossierDetailBoutonDeverrouillerNotes),
                ),
              ],"""
content = content.replace(dev_old, "")

# 11. Update _ligneEntree 
content = content.replace("final entree = affichable.entree;", "")
content = content.replace("a.entree", "a")
content = content.replace("affichable.entree", "entree")
content = content.replace("affichable.verrouillee", "false")
content = content.replace("affichable", "entree")

ligne_dev_old = """                  if (false)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                entree.verrouilleeEtrangere
                                    ? l10n.dossierDetailEntreeVerrouilleeEtrangere
                                    : entree.verrouilleeErreur
                                        ? l10n.dossierDetailEntreeVerrouilleeErreur
                                        : l10n.dossierDetailEntreeVerrouillee,
                                style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        if (!entree.verrouilleeEtrangere && !entree.verrouilleeErreur) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final deverrouille = await demanderPhraseSecrete(context);
                              if (deverrouille && mounted) setState(() {});
                            },
                            icon: const Icon(Icons.lock_open_outlined, size: 16),
                            label: Text(l10n.dossierDetailBoutonDeverrouillerNotes),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                        ],
                      ],
                    )
                  else
                    Text(entree.texte),"""

# Let's just use regex to remove that big conditional
content = re.sub(r"                  if \(false\).*?else\s+Text\(entree\.texte\),", "                  Text(entree.texte),", content, flags=re.DOTALL)
content = re.sub(r"                      if \(false\) \.\.\.\[\n                        const SizedBox\(width: 4\),\n                        const Icon\(Icons\.lock_outline, size: 12, color: Colors\.grey\),\n                      \],", "", content)

# 12. Add Thread classes if not present
if "class _VueThread" not in content:
    # Need to inject threading logic
    
    # 12a. Modify _construireFrise to handle threads
    frise_old = """  List<Widget> _construireFrise(BuildContext context, List<EntreeJournal> entrees) {
    final widgets = <Widget>[];
    DateTime? dernierJour;
    for (var i = 0; i < entrees.length; i++) {
      final entree = entrees[i];
      final creeLe = entree.creeLe;
      final jour = DateTime(creeLe.year, creeLe.month, creeLe.day);
      if (jour != dernierJour) {
        if (dernierJour != null) widgets.add(const SizedBox(height: 4));
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_libelleJour(context, jour), style: Theme.of(context).textTheme.labelLarge),
          ),
        );
        dernierJour = jour;
      }
      final dernierDuJour = i == entrees.length - 1 ||
          DateTime(entrees[i + 1].creeLe.year, entrees[i + 1].creeLe.month, entrees[i + 1].creeLe.day) != jour;
      widgets.add(_ligneEntree(context, entree, dernierDuJour));
    }
    return widgets;
  }"""
    frise_new = """  List<Widget> _construireFrise(BuildContext context, List<EntreeJournal> entrees) {
    final rootEntrees = entrees.where((e) => e.parentId == null).toList();
    final widgets = <Widget>[];
    DateTime? dernierJour;
    for (var i = 0; i < rootEntrees.length; i++) {
      final entree = rootEntrees[i];
      final creeLe = entree.creeLe;
      final jour = DateTime(creeLe.year, creeLe.month, creeLe.day);
      if (jour != dernierJour) {
        if (dernierJour != null) widgets.add(const SizedBox(height: 4));
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_libelleJour(context, jour), style: Theme.of(context).textTheme.labelLarge),
          ),
        );
        dernierJour = jour;
      }
      final dernierDuJour = i == rootEntrees.length - 1 ||
          DateTime(rootEntrees[i + 1].creeLe.year, rootEntrees[i + 1].creeLe.month, rootEntrees[i + 1].creeLe.day) != jour;
      
      final reponses = entrees.where((e) => e.parentId == entree.id).toList();
      reponses.sort((a, b) => a.creeLe.compareTo(b.creeLe));

      widgets.add(_ligneEntree(context, entree, dernierDuJour, reponses));
    }
    return widgets;
  }"""
    content = content.replace(frise_old, frise_new)
    
    # 12b. Update _ligneEntree signature and reply buttons
    content = content.replace("Widget _ligneEntree(BuildContext context, EntreeJournal entree, bool dernierDuJour) {", "Widget _ligneEntree(BuildContext context, EntreeJournal entree, bool dernierDuJour, List<EntreeJournal> reponses) {")
    
    reply_buttons = """                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (reponses.isNotEmpty)
                        InkWell(
                          onTap: () => _ouvrirThread(context, entree, reponses),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: Text(
                              '${reponses.length} réponse${reponses.length > 1 ? 's' : ''}',
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      if (reponses.isNotEmpty) const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _ouvrirThread(context, entree, reponses),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Text(
                            'Répondre',
                            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),\n"""
    content = content.replace("                  Text(entree.texte),", "                  Text(entree.texte),\n" + reply_buttons)
    
    # 12c. Add thread classes at the end of _SectionJournalState
    thread_code = """
  void _ouvrirThread(BuildContext context, EntreeJournal parent, List<EntreeJournal> reponses) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return _VueThread(
                dossier: widget.dossier,
                monUid: widget.monUid,
                parentEntree: parent,
                reponsesInitiales: reponses,
              );
            },
          ),
        );
      },
    );
  }
}

class _VueThread extends StatefulWidget {
  const _VueThread({
    super.key,
    required this.dossier,
    required this.monUid,
    required this.parentEntree,
    required this.reponsesInitiales,
  });

  final Dossier dossier;
  final String monUid;
  final EntreeJournal parentEntree;
  final List<EntreeJournal> reponsesInitiales;

  @override
  State<_VueThread> createState() => _VueThreadState();
}

class _VueThreadState extends State<_VueThread> {
  final _controleur = TextEditingController();
  bool _enCours = false;
  final Set<String> _mentionsUids = {};

  void _ajouterMention(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('Mentionner un participant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...widget.dossier.participantsUids.map((uid) {
              final email = widget.dossier.participantsEmails[uid] ?? uid;
              return ListTile(
                leading: CircleAvatar(child: Text(email[0].toUpperCase())),
                title: Text(email),
                onTap: () {
                  final nom = email.split('@').first;
                  final textBefore = _controleur.text;
                  _controleur.text = '$textBefore@$nom ';
                  _mentionsUids.add(uid);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _ajouterReponse() async {
    final texte = _controleur.text.trim();
    if (texte.isEmpty) return;

    setState(() => _enCours = true);
    try {
      final dossierActuel = await FirestoreService.instance.dossierDepuisServeur(widget.dossier.id);
      final type = TypeEntreeJournal.autre;

      if (dossierActuel.estGestionnaireContenu(widget.monUid)) {
        await FirestoreService.instance.ajouterEntreeJournal(
          widget.dossier.id,
          texte,
          type,
          participantsUids: dossierActuel.participantsUids,
          parentId: widget.parentEntree.id,
          mentionsUids: _mentionsUids.toList(),
        );
      } else {
        await FirestoreService.instance.ajouterEntreeJournal(
          widget.dossier.id,
          texte,
          type,
          participantsUids: dossierActuel.participantsUids,
          proposerSeulement: true,
          parentId: widget.parentEntree.id,
          mentionsUids: _mentionsUids.toList(),
        );
      }
      _controleur.clear();
      _mentionsUids.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              const Text('Thread', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<EntreeJournal>>(
            stream: FirestoreService.instance.journalDossier(widget.dossier.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final toutesLesEntrees = snapshot.data ?? [];
              final reponses = toutesLesEntrees.where((e) => e.parentId == widget.parentEntree.id).toList();
              reponses.sort((a, b) => a.creeLe.compareTo(b.creeLe));
              
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _LigneThread(entree: widget.parentEntree, dossier: widget.dossier, monUid: widget.monUid, estParent: true),
                  const Divider(height: 32),
                  ...reponses.map((a) => _LigneThread(entree: a, dossier: widget.dossier, monUid: widget.monUid, estParent: false)),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton.outlined(
                onPressed: () => _ajouterMention(context),
                icon: const Icon(Icons.alternate_email),
                tooltip: 'Mentionner un participant',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controleur,
                  decoration: const InputDecoration(
                    hintText: 'Répondre...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _enCours ? null : _ajouterReponse,
                icon: _enCours ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LigneThread extends StatelessWidget {
  const _LigneThread({required this.entree, required this.dossier, required this.monUid, required this.estParent});
  final EntreeJournal entree;
  final Dossier dossier;
  final String monUid;
  final bool estParent;

  @override
  Widget build(BuildContext context) {
    final auteurAffichage = dossier.participantsEmails[entree.auteurUid] ?? entree.auteurUid ?? '';
    final estFrancais = Localizations.localeOf(context).languageCode != 'en';
    final heure = estFrancais
        ? '${entree.creeLe.hour.toString().padLeft(2, '0')}h${entree.creeLe.minute.toString().padLeft(2, '0')}'
        : '${entree.creeLe.hour.toString().padLeft(2, '0')}:${entree.creeLe.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: estParent ? entree.type.couleur.withOpacity(0.2) : Colors.grey.shade200,
            child: estParent ? Icon(entree.type.icone, size: 16, color: entree.type.couleur) : Text(auteurAffichage.isNotEmpty ? auteurAffichage[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(auteurAffichage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(heure, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(entree.texte, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
"""
    # Replace the last brace of the file with the thread code
    content = content.rstrip()
    if content.endswith("}"):
        content = content[:-1] + thread_code
    else:
        content += thread_code

with open('app/lib/screens/dossier_detail_screen.dart', 'w') as f:
    f.write(content)
