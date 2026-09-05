import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'firestore_service.dart';
import '../models/tache.dart';

class AssistantService {
  AssistantService._();
  static final AssistantService instance = AssistantService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  /// Assemble le contexte texte complet du dossier (tâches et journal) 
  /// pour l'envoyer au RAG de l'Assistant IA.
  Future<String> assemblerContexteDossier(String dossierId) async {
    final buffer = StringBuffer();
    
    try {
      // 1. Récupérer le dossier (pour le nom de code)
      final dossier = await FirestoreService.instance.dossierDepuisServeur(dossierId);
      buffer.writeln("Dossier : ${dossier.nomCode}");
      if (dossier.dateEvenement != null) {
        buffer.writeln("Date événement : ${_dateFormat.format(dossier.dateEvenement!)}");
      }
      buffer.writeln("");
      
      // 2. Récupérer les tâches (via first sur le stream)
      final taches = await FirestoreService.instance.tachesDuDossier(dossierId).first;
      buffer.writeln("=== TÂCHES ===");
      if (taches.isEmpty) {
        buffer.writeln("Aucune tâche.");
      } else {
        for (final t in taches) {
          final statut = t.statut == StatutTache.fait ? "Fait" : "À faire";
          buffer.writeln("- [$statut] ${t.nature} : ${t.descriptionCourte}");
          buffer.writeln("  Déclenchante : ${_dateFormat.format(t.dateDeclenchante)}");
          if (t.notesDetaillees?.isNotEmpty ?? false) {
            buffer.writeln("  Notes : ${t.notesDetaillees}");
          }
        }
      }
      buffer.writeln("");

      // 3. Récupérer le journal
      final entreesJournal = await FirestoreService.instance.journalDossier(dossierId).first;
      buffer.writeln("=== JOURNAL DU DOSSIER ===");
      if (entreesJournal.isEmpty) {
        buffer.writeln("Aucune entrée.");
      } else {
        for (final j in entreesJournal) {
          String texteAffiche = j.texte;
          buffer.writeln("- ${_dateFormat.format(j.creeLe)} : $texteAffiche");
        }
      }
      
    } catch (e) {
      buffer.writeln("Erreur lors de la récupération du contexte: $e");
    }

    return buffer.toString();
  }

  /// Appelle la Cloud Function 'chat_assistant_ia'
  Future<String> chatAvecAssistant({
    required String dossierId,
    required String contexteDossier,
    required List<Map<String, String>> historique,
  }) async {
    try {
      final callable = _functions.httpsCallable('chat_assistant_ia');
      final result = await callable.call(<String, dynamic>{
        'contexte_dossier': contexteDossier,
        'historique': historique,
      });

      if (result.data is Map) {
        return (result.data as Map)['reponse'] as String? ?? "Erreur de réponse";
      }
      return "Réponse invalide du serveur.";
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Erreur assistant : ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue : $e');
    }
  }
}
