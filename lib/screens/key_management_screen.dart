import 'package:flutter/material.dart';
import '../models/access_key.dart';
import '../services/chat_service.dart';
import '../widgets/key_badge.dart';

class KeyManagementScreen extends StatefulWidget {
  const KeyManagementScreen({super.key});

  @override
  State<KeyManagementScreen> createState() => _KeyManagementScreenState();
}

class _KeyManagementScreenState extends State<KeyManagementScreen> {
  final _chatService = ChatService();
  final _customKeyPrefixController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chatService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _chatService.removeListener(_onStateChanged);
    _customKeyPrefixController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showGenerateKeyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text("Generate New Access Key", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Optional custom prefix or friend's name:",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customKeyPrefixController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              onPressed: () async {
                final newKey = await _chatService.generateNewKey(_customKeyPrefixController.text);
                _customKeyPrefixController.clear();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Generated Key: ${newKey.key}")),
                  );
                }
              },
              child: const Text("Generate", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = _chatService.keys;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Key Management",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _showGenerateKeyDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Generate New Access Key", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: keys.isEmpty
                ? const Center(
                    child: Text("No access keys created yet.", style: TextStyle(color: Colors.white38)),
                  )
                : ListView.builder(
                    itemCount: keys.length,
                    itemBuilder: (context, index) {
                      final k = keys[index];
                      return KeyBadge(
                        accessKey: k,
                        onDelete: () => _chatService.deleteKey(k.key),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
