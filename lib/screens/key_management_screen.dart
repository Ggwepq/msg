import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/theme_service.dart';
import '../widgets/key_badge.dart';

class KeyManagementScreen extends StatefulWidget {
  const KeyManagementScreen({super.key});

  @override
  State<KeyManagementScreen> createState() => _KeyManagementScreenState();
}

class _KeyManagementScreenState extends State<KeyManagementScreen> {
  final _chatService = ChatService();
  final _theme = ThemeService();
  final _customKeyPrefixController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chatService.addListener(_onStateChanged);
    _theme.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _chatService.removeListener(_onStateChanged);
    _theme.removeListener(_onStateChanged);
    _customKeyPrefixController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _showGenerateKeyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final accent = _theme.primary;

        return AlertDialog(
          backgroundColor: _theme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "new key",
            style: TextStyle(
              color: _theme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "friend's name — becomes their default nickname",
                style: TextStyle(color: _theme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customKeyPrefixController,
                style: TextStyle(color: _theme.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _theme.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("nah",
                  style: TextStyle(color: _theme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final newKey = await _chatService
                    .generateNewKey(_customKeyPrefixController.text);
                _customKeyPrefixController.clear();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("created ${newKey.key} 🔑")),
                  );
                }
              },
              child: const Text("create",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = _chatService.keys;
    final accent = _theme.primary;

    return Scaffold(
      backgroundColor: _theme.bg,
      appBar: AppBar(
        backgroundColor: _theme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "invite keys",
          style: TextStyle(
            color: _theme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showGenerateKeyDialog,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text("generate new key",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: keys.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("🔐", style: const TextStyle(fontSize: 40)),
                        const SizedBox(height: 10),
                        Text(
                          "no keys yet — create one above",
                          style: TextStyle(
                            color: _theme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
