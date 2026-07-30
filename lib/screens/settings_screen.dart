import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/chat_service.dart';
import 'key_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile currentUser;

  const SettingsScreen({super.key, required this.currentUser});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nicknameController = TextEditingController();
  final _chatService = ChatService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.text = widget.currentUser.nickname;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    final newName = _nicknameController.text.trim();
    if (newName.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    await _chatService.updateNickname(newName);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nickname updated successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMasterKeyHolder = widget.currentUser.role == UserRole.admin;

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
          "Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF6366F1),
                    child: Text(
                      widget.currentUser.nickname.isNotEmpty
                          ? widget.currentUser.nickname[0].toUpperCase()
                          : "?",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.currentUser.nickname,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Key: ${widget.currentUser.accessKey ?? 'Active'}",
                          style: const TextStyle(
                            color: Color(0xFF34D399),
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Nickname Section
            const Text(
              "Manage Nickname",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nicknameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.edit, color: Color(0xFF6366F1)),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveNickname,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Save Nickname", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Key Management Button (For Master Key Holder)
            if (isMasterKeyHolder) ...[
              const Text(
                "Access Key Control",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  leading: const Icon(Icons.vpn_key_outlined, color: Color(0xFF6366F1)),
                  title: const Text(
                    "Manage Access Keys",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    "Create, view & share invite keys with friends",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KeyManagementScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Logout Option
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  "Log Out",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Clears key session from this device",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _chatService.logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
