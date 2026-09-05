import re

with open('app/lib/screens/dossier_detail_screen.dart', 'r') as f:
    content = f.read()

# 1. Imports
content = re.sub(r"import '\.\./services/chiffrement_notes_service\.dart';\n", "", content)
content = re.sub(r"import '\.\./widgets/dialogue_phrase_secrete\.dart';\n", "", content)

# 2. _EntreeAffichable
content = re.sub(r"/// Une entrée prête à afficher :.*?class _EntreeAffichable \{.*?\n\}\n\n", "", content, flags=re.DOTALL)

# 3. _SectionJournalState initState
content = re.sub(r"  @override\n  void initState\(\) \{.*?  \}\n\n", "", content, flags=re.DOTALL)

# 4. _ajouter
ajouter_old = """  Future<void> _ajouter() async {
    final texte = _controleur.text.trim();
    if (texte.isEmpty) return;
    // Chiffrement désactivé dès qu'un dossier est partagé (décision de
    // Tobie le 2026-08-30, Red Team) : la clé dérivée de la phrase secrète
    // est strictement personnelle à celui qui écrit, jamais partagée — un
    // autre participant ne pourrait JAMAIS déchiffrer une entrée chiffrée
    // avec la clé de quelqu'un d'autre (voir _dechiffrerToutes, qui affiche
    // alors l'entrée comme verrouillée pour toujours, même après avoir
    // déverrouillé SA PROPRE phrase secrète). Reste actif pour un dossier
    // strictement solo, où ce problème ne se pose pas.
    if (widget.dossier.participantsUids.length <= 1) {
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
        );
      } else {
        await FirestoreService.instance.ajouterEntreeJournal(
          widget.dossier.id,
          texteAEcrire,
          _typeSelectionne,
          chiffre: !estPartage,
          participantsUids: dossierActuel.participantsUids,
          proposerSeulement: true,
        );"""

ajouter_new = """  Future<void> _ajouter() async {
    final texte = _controleur.text.trim();
    if (texte.isEmpty) return;
    setState(() => _enCours = true);
    try {
      final dossierActuel = await FirestoreService.instance.dossierDepuisServeur(widget.dossier.id);
      if (dossierActuel.estGestionnaireContenu(widget.monUid)) {
        await FirestoreService.instance.ajouterEntreeJournal(
          widget.dossier.id,
          texte,
          _typeSelectionne,
          participantsUids: dossierActuel.participantsUids,
        );
      } else {
        await FirestoreService.instance.ajouterEntreeJournal(
          widget.dossier.id,
          texte,
          _typeSelectionne,
          participantsUids: dossierActuel.participantsUids,
          proposerSeulement: true,
        );"""
content = content.replace(ajouter_old, ajouter_new)

# 5. _editer (1/2)
editer_old_1 = """    if (entree.chiffre) {
      final deverrouille = await demanderPhraseSecrete(context);
      if (!deverrouille || !context.mounted) return;
    }
    final controleur = TextEditingController(text: entree.texte);"""
editer_new_1 = """    final controleur = TextEditingController(text: entree.texte);"""
content = content.replace(editer_old_1, editer_new_1)

# 5. _editer (2/2)
editer_old_2 = """    final texte = controleur.text.trim();
    if (texte.isEmpty) return;
    try {
      final texteAEcrire = entree.chiffre ? await ChiffrementNotesService.instance.chiffrer(texte) : texte;
      if (direct) {
        await FirestoreService.instance.modifierEntreeJournal(entree.id, texteAEcrire, type);
      } else {
        await FirestoreService.instance.proposerModificationEntreeJournal(
          entree.copierAvec(texte: texteAEcrire, type: type),
        );
      }"""
editer_new_2 = """    final texte = controleur.text.trim();
    if (texte.isEmpty) return;
    try {
      if (direct) {
        await FirestoreService.instance.modifierEntreeJournal(entree.id, texte, type);
      } else {
        await FirestoreService.instance.proposerModificationEntreeJournal(
          entree.copierAvec(texte: texte, type: type),
        );
      }"""
content = content.replace(editer_old_2, editer_new_2)

# 6. _dechiffrerToutes
content = re.sub(r"  /// Déchiffre chaque entrée marquée.*?Future<List<_EntreeAffichable>> _dechiffrerToutes\(List<EntreeJournal> entrees\) async \{.*?\n  \}\n\n", "", content, flags=re.DOTALL)

# 7. Button deverrouiller
dev_btn_old = """              if (!ChiffrementNotesService.instance.estDeverrouille) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final deverrouille = await demanderPhraseSecrete(context);
                    if (deverrouille && mounted) setState(() {});
                  },
                  icon: const Icon(Icons.lock_open_outlined, size: 16),
                  label: Text(l10n.dossierDetailBoutonDeverrouillerNotes),
                ),
              ],
"""
content = content.replace(dev_btn_old, "")

# 8. FutureBuilder
fb_old = """                  // Le déchiffrement est asynchrone (AES-GCM) — imbriqué dans un
                  // second FutureBuilder plutôt que de bloquer le StreamBuilder
                  // parent, pour que les nouvelles entrées Firestore continuent
                  // d'arriver en direct pendant qu'une entrée se déchiffre.
                  return FutureBuilder<List<_EntreeAffichable>>(
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
                          : affichables.where((a) => a.entree.type == _filtreType).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: ["""
fb_new = """                  final entreesFiltrees = _filtreType == null
                      ? entrees
                      : entrees.where((e) => e.type == _filtreType).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ["""
content = content.replace(fb_old, fb_new)

# 9. _construireFrise call
content = content.replace("..._construireFrise(context, affichablesFiltres),", "..._construireFrise(context, entreesFiltrees),")

# 10. Fix brackets of StreamBuilder! The FutureBuilder had an extra level of bracket closing at the end of the StreamBuilder.
brackets_old = """                          // Filtre par type : pour ne pas mélanger visuellement tous les
                          // types quand on veut suivre un seul fil (ex : juste les
                          // blocages) — demandé par Tobie le 2026-08-21 ("mélangé,
                          // trop en désordre").
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              FilterChip(
                                label: Text(l10n.propositionsFiltreTout),
                                selected: _filtreType == null,
                                onSelected: (_) => setState(() => _filtreType = null),
                              ),
                              ...TypeEntreeJournal.values.map((t) {
                                final selectionne = _filtreType == t;
                                return FilterChip(
                                  label: Text(t.libelle(context)),
                                  avatar: Icon(t.icone, size: 14, color: selectionne ? Colors.white : t.couleur),
                                  selected: selectionne,
                                  selectedColor: t.couleur,
                                  labelStyle: TextStyle(color: selectionne ? Colors.white : null, fontSize: 12),
                                  onSelected: (_) => setState(() => _filtreType = selectionne ? null : t),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (affichablesFiltres.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                l10n.dossierDetailAucuneEntreeType,
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            )
                          else
                            ..._construireFrise(context, entreesFiltrees),
                        ],
                      );
                    },
                  );"""

brackets_new = """                          // Filtre par type : pour ne pas mélanger visuellement tous les
                          // types quand on veut suivre un seul fil (ex : juste les
                          // blocages) — demandé par Tobie le 2026-08-21 ("mélangé,
                          // trop en désordre").
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              FilterChip(
                                label: Text(l10n.propositionsFiltreTout),
                                selected: _filtreType == null,
                                onSelected: (_) => setState(() => _filtreType = null),
                              ),
                              ...TypeEntreeJournal.values.map((t) {
                                final selectionne = _filtreType == t;
                                return FilterChip(
                                  label: Text(t.libelle(context)),
                                  avatar: Icon(t.icone, size: 14, color: selectionne ? Colors.white : t.couleur),
                                  selected: selectionne,
                                  selectedColor: t.couleur,
                                  labelStyle: TextStyle(color: selectionne ? Colors.white : null, fontSize: 12),
                                  onSelected: (_) => setState(() => _filtreType = selectionne ? null : t),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (entreesFiltrees.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                l10n.dossierDetailAucuneEntreeType,
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            )
                          else
                            ..._construireFrise(context, entreesFiltrees),
                    ],
                  );"""
content = content.replace(brackets_old, brackets_new)

# 11. _construireFrise definition
content = content.replace("List<Widget> _construireFrise(BuildContext context, List<_EntreeAffichable> entrees) {", "List<Widget> _construireFrise(BuildContext context, List<EntreeJournal> entrees) {")
content = content.replace("final affichable = entrees[i];", "final entree = entrees[i];")
content = content.replace("final creeLe = affichable.entree.creeLe;", "final creeLe = entree.creeLe;")
content = content.replace("DateTime(entrees[i + 1].entree.creeLe.year, entrees[i + 1].entree.creeLe.month, entrees[i + 1].entree.creeLe.day) != jour;", "DateTime(entrees[i + 1].creeLe.year, entrees[i + 1].creeLe.month, entrees[i + 1].creeLe.day) != jour;")
content = content.replace("widgets.add(_ligneEntree(context, affichable, dernierDuJour));", "widgets.add(_ligneEntree(context, entree, dernierDuJour));")

# 12. _ligneEntree definition
content = content.replace("Widget _ligneEntree(BuildContext context, _EntreeAffichable affichable, bool dernierDuJour) {", "Widget _ligneEntree(BuildContext context, EntreeJournal entree, bool dernierDuJour) {")
content = content.replace("    final entree = affichable.entree;\n", "")

lock_icon_old = """                      if (affichable.verrouillee) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                      ],"""
content = content.replace(lock_icon_old, "")

edit_btn_old = """                            onPressed: affichable.verrouillee
                                ? null
                                : () => _editer(context, entree, jeSuisAuteurOuGestionnaire),"""
edit_btn_new = """                            onPressed: () => _editer(context, entree, jeSuisAuteurOuGestionnaire),"""
content = content.replace(edit_btn_old, edit_btn_new)

verrouillee_text_old = """                  if (affichable.verrouillee)
                    Text(
                      affichable.verrouilleeEtrangere
                          ? l10n.dossierDetailEntreeVerrouilleeEtrangere
                          : affichable.verrouilleeErreur
                              ? l10n.dossierDetailEntreeVerrouilleeErreur
                              : l10n.dossierDetailEntreeVerrouillee,
                      style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
                    )
                  else
                    Text(entree.texte),"""
verrouillee_text_new = """                  Text(entree.texte),"""
content = content.replace(verrouillee_text_old, verrouillee_text_new)


with open('app/lib/screens/dossier_detail_screen.dart', 'w') as f:
    f.write(content)

