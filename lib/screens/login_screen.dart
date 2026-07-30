import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/theme_service.dart';
import '../models/user_profile.dart';

class LoginScreen extends StatefulWidget {
  final Function(UserProfile) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _keyController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _theme = ThemeService();

  int _step = 1;
  bool _isLoading = false;
  String? _errorMessage;
  AccessKeyValidation? _validatedKeyInfo;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _keyController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleValidateKey() async {
    setState(() => _errorMessage = null);

    try {
      final chatService = ChatService();
      final validated = chatService.validateKey(_keyController.text);
      _validatedKeyInfo = validated;

      // Existing nickname → direct login
      if (validated.existingNickname != null &&
          validated.existingNickname!.isNotEmpty) {
        setState(() => _isLoading = true);
        final user = await chatService.completeLogin(
          keyInput: validated.key,
          nickname: validated.existingNickname,
        );
        widget.onLoginSuccess(user);
        return;
      }

      setState(() => _step = 2);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCompleteLogin() async {
    if (_validatedKeyInfo == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final chatService = ChatService();
      final user = await chatService.completeLogin(
        keyInput: _validatedKeyInfo!.key,
        nickname: _nicknameController.text,
      );
      widget.onLoginSuccess(user);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _theme.primary;

    return Scaffold(
      backgroundColor: _theme.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing key icon
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withOpacity(0.12),
                      ),
                      child: Center(
                        child: Text(
                          "🔑",
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                _step == 1 ? "got a key?" : "who are you?",
                style: TextStyle(
                  color: _theme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _step == 1
                    ? "paste it below and let's go"
                    : "pick a name — make it fun",
                style: TextStyle(color: _theme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 36),

              // Input area
              if (_step == 1) ...[
                TextField(
                  controller: _keyController,
                  style: TextStyle(
                    color: _theme.textPrimary,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  onSubmitted: (_) => _handleValidateKey(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _theme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: accent.withOpacity(0.5), width: 1.5),
                    ),
                  ),
                ),
              ] else ...[
                // Verified key chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, size: 16, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        _validatedKeyInfo?.key ?? "",
                        style: TextStyle(
                          color: accent,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nicknameController,
                  style: TextStyle(
                    color: _theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  autofocus: true,
                  onSubmitted: (_) => _handleCompleteLogin(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _theme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: accent.withOpacity(0.5), width: 1.5),
                    ),
                  ),
                ),
              ],

              // Error
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFFF6F6F), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : (_step == 1 ? _handleValidateKey : _handleCompleteLogin),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _theme.textPrimary,
                          ),
                        )
                      : Text(
                          _step == 1 ? "unlock →" : "let's go! →",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
              Text(
                "your key stays saved on this device",
                style: TextStyle(color: _theme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
