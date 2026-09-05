import 'package:flutter/material.dart';
import '../services/assistant_service.dart';

class AssistantIaScreen extends StatefulWidget {
  final String dossierId;
  final String nomCodeDossier;

  const AssistantIaScreen({
    super.key,
    required this.dossierId,
    required this.nomCodeDossier,
  });

  @override
  State<AssistantIaScreen> createState() => _AssistantIaScreenState();
}

class _AssistantIaScreenState extends State<AssistantIaScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isTyping = false;
  String _contexteDossier = "";

  @override
  void initState() {
    super.initState();
    _chargerContexte();
  }

  Future<void> _chargerContexte() async {
    setState(() => _isTyping = true);
    try {
      _contexteDossier = await AssistantService.instance.assemblerContexteDossier(widget.dossierId);
      setState(() {
        _messages.add({
          "role": "assistant",
          "content": "Bonjour ! Je suis Vigie, l'assistant IA de votre dossier '${widget.nomCodeDossier}'. Comment puis-je vous aider ?"
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement contexte : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
      }
    }
  }

  Future<void> _envoyerMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final historiqueComplet = _messages.where((m) {
        return m["role"] != "system" && 
               !(m["role"] == "assistant" && (m["content"] ?? "").startsWith("Désolé, une erreur est survenue"));
      }).toList();
      
      final historique = historiqueComplet.length > 10 
          ? historiqueComplet.sublist(historiqueComplet.length - 10) 
          : historiqueComplet;

      final reponse = await AssistantService.instance.chatAvecAssistant(
        dossierId: widget.dossierId,
        contexteDossier: _contexteDossier,
        historique: historique,
      );

      if (mounted) {
        setState(() {
          _messages.add({"role": "assistant", "content": reponse});
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({"role": "assistant", "content": "Désolé, une erreur est survenue : $e"});
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Assistant IA - ${widget.nomCodeDossier}"),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "L'IA lit également vos notes chiffrées si votre journal est déverrouillé.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: Text(
                      message["content"] ?? "",
                      style: TextStyle(
                        color: isUser ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Posez votre question...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _envoyerMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: _isTyping ? null : _envoyerMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
