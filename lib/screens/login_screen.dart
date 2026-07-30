import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/user_profile.dart';

class LoginScreen extends StatefulWidget {
  final Function(UserProfile) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _keyController = TextEditingController();
  final _nicknameController = TextEditingController();

  int _step = 1;
  bool _isLoading = false;
  String? _errorMessage;
  AccessKeyValidation? _validatedKeyInfo;

  @override
  void dispose() {
    _keyController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleValidateKey() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final chatService = ChatService();
      final validated = chatService.validateKey(_keyController.text);

      _validatedKeyInfo = validated;

      // If key ALREADY has a nickname, log in directly without asking!
      if (validated.existingNickname != null && validated.existingNickname!.isNotEmpty) {
        setState(() {
          _isLoading = true;
        });

        final user = await chatService.completeLogin(
          keyInput: validated.key,
          nickname: validated.existingNickname,
        );

        widget.onLoginSuccess(user);
        return;
      }

      // New key without nickname -> move to step 2
      setState(() {
        _step = 2;
      });
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  size: 46,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Welcome!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _step == 1
                    ? "Enter your secret key to step inside"
                    : "Set your nickname for this space",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Card Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_step == 1) ...[
                      // STEP 1: Key Input (No Placeholders)
                      const Text(
                        "Key Here!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _keyController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          fontSize: 16,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (_) => _handleValidateKey(),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.key, color: Color(0xFF6366F1)),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ] else ...[
                      // STEP 2: Nickname Input (No Placeholders)
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Color(0xFF34D399), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Key: ${_validatedKeyInfo?.key}",
                            style: const TextStyle(
                              color: Color(0xFF34D399),
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Set your nickname",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nicknameController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        onSubmitted: (_) => _handleCompleteLogin(),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF6366F1)),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _isLoading
                          ? null
                          : (_step == 1 ? _handleValidateKey : _handleCompleteLogin),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _step == 1 ? "Unlock" : "Let's Go!",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Your key stays active on this device until you log out.",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
