import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/chat_service.dart';
import '../services/theme_service.dart';
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
  final _theme = ThemeService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.text =
        _chatService.currentUser?.nickname ?? widget.currentUser.nickname;
    _theme.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _theme.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _saveNickname() async {
    final newName = _nicknameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isSaving = true);
    await _chatService.updateNickname(newName);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("nickname updated ✨")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _theme.primary;
    final isMasterKeyHolder = widget.currentUser.role == UserRole.admin;

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
          "settings",
          style: TextStyle(
            color: _theme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.currentUser.nickname.isNotEmpty
                            ? widget.currentUser.nickname[0].toUpperCase()
                            : "?",
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.currentUser.nickname,
                    style: TextStyle(
                      color: _theme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.currentUser.accessKey ?? "",
                    style: TextStyle(
                      color: _theme.textMuted,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Nickname
            _sectionLabel("nickname"),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nicknameController,
                    style: TextStyle(
                      color: _theme.textPrimary,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _theme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isSaving ? null : _saveNickname,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _theme.textPrimary,
                            ),
                          )
                        : Text(
                            "save",
                            style: TextStyle(
                              color: _theme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Accent color
            _sectionLabel("accent color"),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(
                ThemeService.accentOptions.length,
                (index) {
                  final option = ThemeService.accentOptions[index];
                  final isSelected = index == _theme.accentIndex;

                  return GestureDetector(
                    onTap: () => _theme.setAccent(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: option.primary,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2.5)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: option.primary.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Center(
                              child: Icon(Icons.check_rounded,
                                  color: Colors.white, size: 20),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Key Management (Master Key Holder Only)
            if (isMasterKeyHolder) ...[
              _sectionLabel("invite keys"),
              const SizedBox(height: 8),
              _settingsTile(
                icon: Icons.vpn_key_rounded,
                title: "manage keys",
                subtitle: "create & share access keys",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KeyManagementScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            // Logout
            _settingsTile(
              icon: Icons.arrow_back_rounded,
              title: "log out",
              subtitle: "clear session from this device",
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _chatService.logout();
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: _theme.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final accent = _theme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _theme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive
                  ? const Color(0xFFFF6F6F)
                  : accent.withOpacity(0.7),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive
                          ? const Color(0xFFFF6F6F)
                          : _theme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _theme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: _theme.textMuted),
          ],
        ),
      ),
    );
  }
}
