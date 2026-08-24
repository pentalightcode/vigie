import 'package:flutter/material.dart';
import '../models/nature_dossier.dart';
import '../services/nature_dossier_service.dart';

/// Panneau de gestion des types de dossier personnalisés — utilisé
/// depuis l'écran "Ajouter" et depuis le Profil.
class GestionNaturesSheet extends StatefulWidget {
  const GestionNaturesSheet({super.key});

  @override
  State<GestionNaturesSheet> createState() => _GestionNaturesSheetState();

  static void ouvrir(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const GestionNaturesSheet(),
    );
  }
}

class _GestionNaturesSheetState extends State<GestionNaturesSheet> {
  final _nomController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Mes types de dossier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          StreamBuilder<List<NatureDossier>>(
            stream: NatureDossierService.instance.natures(),
            builder: (context, snapshot) {
              final natures = snapshot.data ?? [];
              return Column(
                children: natures
                    .map((n) => ListTile(
                          title: Text(n.nom),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => NatureDossierService.instance.supprimerNature(n.id),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const Divider(),
          TextField(
            controller: _nomController,
            decoration: const InputDecoration(labelText: 'Nouveau type (ex: Consultation)'),
          ),
          FilledButton(
            onPressed: () {
              final nom = _nomController.text.trim();
              if (nom.isEmpty) return;
              NatureDossierService.instance.ajouterNature(nom);
              _nomController.clear();
            },
            child: const Text('Ajouter ce type'),
          ),
        ],
      ),
    );
  }
}
