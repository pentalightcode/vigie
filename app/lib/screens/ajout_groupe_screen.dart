import 'package:flutter/material.dart';
import '../models/nature_dossier.dart';
import '../services/firestore_service.dart';
import '../services/nature_dossier_service.dart';

/// Ajout groupé — refait en formulaire (une ligne = nom + date), plus simple
/// et intuitif qu'un texte à coller dans un format précis à mémoriser
/// (retour de Tobie après test réel : le format texte n'était pas clair).
class AjoutGroupeScreen extends StatefulWidget {
  const AjoutGroupeScreen({super.key});

  @override
  State<AjoutGroupeScreen> createState() => _AjoutGroupeScreenState();
}

class _LigneSaisie {
  final controller = TextEditingController();
  DateTime? date;
}

class _AjoutGroupeScreenState extends State<AjoutGroupeScreen> {
  final _lignes = List.generate(3, (_) => _LigneSaisie());
  NatureDossier? _nature;
  bool _enCours = false;

  void _ajouterLigne() => setState(() => _lignes.add(_LigneSaisie()));

  void _supprimerLigne(int index) => setState(() => _lignes.removeAt(index));

  Future<void> _choisirDate(_LigneSaisie ligne) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => ligne.date = date);
  }

  Future<void> _enregistrer() async {
    final entrees = _lignes
        .where((l) => l.controller.text.trim().isNotEmpty)
        .map((l) => (nomCode: l.controller.text.trim(), dateAudience: l.date))
        .toList();
    if (entrees.isEmpty || _nature == null) return;

    setState(() => _enCours = true);
    try {
      await FirestoreService.instance.creerPlusieursDossiers(
        entrees,
        nature: _nature!.nom,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreValide = _lignes.where((l) => l.controller.text.trim().isNotEmpty).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajout groupé')),
      body: Column(
        children: [
          StreamBuilder<List<NatureDossier>>(
            stream: NatureDossierService.instance.natures(),
            builder: (context, snapshot) {
              final natures = snapshot.data ?? [];
              if (_nature == null && natures.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => setState(() => _nature = natures.first),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Tous ces dossiers sont de type :'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<NatureDossier>(
                      initialValue: _nature,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: natures
                          .map((n) => DropdownMenuItem(value: n, child: Text(n.nom)))
                          .toList(),
                      onChanged: (n) => setState(() => _nature = n!),
                    ),
                  ],
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Remplis une ligne par dossier — la date est optionnelle.'),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _lignes.length,
              itemBuilder: (context, i) {
                final ligne = _lignes[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: ligne.controller,
                          decoration: InputDecoration(
                            labelText: 'Nom de code',
                            hintText: 'Dossier ${i + 1}',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: () => _choisirDate(ligne),
                          icon: const Icon(Icons.event, size: 18),
                          label: Text(
                            ligne.date == null
                                ? 'Date'
                                : '${ligne.date!.day}/${ligne.date!.month}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _lignes.length > 1 ? () => _supprimerLigne(i) : null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _ajouterLigne,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une ligne'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: nombreValide == 0 || _enCours ? null : _enregistrer,
                  child: _enCours
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(nombreValide == 0
                          ? 'Enregistrer'
                          : 'Enregistrer ($nombreValide dossier${nombreValide > 1 ? 's' : ''})'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
