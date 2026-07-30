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

enum _LoginStep { key, welcomeNew, welcomeBack }

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _keyController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _theme = ThemeService();

  _LoginStep _step = _LoginStep.key;
  bool _isLoading = false;
  String? _errorMessage;
  AccessKeyValidation? _validatedKeyInfo;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _entranceController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

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

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entranceController.dispose();
    _keyController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _animateStepChange(_LoginStep newStep) {
    _entranceController.reset();
    setState(() => _step = newStep);
    _entranceController.forward();
  }

  Future<void> _handleValidateKey() async {
    setState(() => _errorMessage = null);

    try {
      final chatService = ChatService();
      final validated = chatService.validateKey(_keyController.text);
      _validatedKeyInfo = validated;

      if (validated.existingNickname != null &&
          validated.existingNickname!.isNotEmpty) {
        _nicknameController.text = validated.existingNickname!;
      }

      if (validated.isReturning) {
        _animateStepChange(_LoginStep.welcomeBack);
      } else {
        _animateStepChange(_LoginStep.welcomeNew);
      }
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
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: _buildCurrentStep(accent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(Color accent) {
    switch (_step) {
      case _LoginStep.key:
        return _buildKeyStep(accent);
      case _LoginStep.welcomeNew:
        return _buildWelcomeNewStep(accent);
      case _LoginStep.welcomeBack:
        return _buildWelcomeBackStep(accent);
    }
  }

  // ─── Step 1: Enter Key ──────────────────────────────────────────
  Widget _buildKeyStep(Color accent) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
                child: const Center(
                  child: Text("🔑", style: TextStyle(fontSize: 40)),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        Text(
          "got a key?",
          style: TextStyle(
            color: _theme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "paste it below and let's go",
          style: TextStyle(color: _theme.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 36),
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
              borderSide:
                  BorderSide(color: accent.withOpacity(0.5), width: 1.5),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Color(0xFFFF6F6F), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
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
            onPressed: _isLoading ? null : _handleValidateKey,
            child: const Text(
              "unlock →",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          "your key stays saved on this device",
          style: TextStyle(color: _theme.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  // ─── Step 2a: Welcome (First Time) ───────────────────────────────
  Widget _buildWelcomeNewStep(Color accent) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withOpacity(0.12),
          ),
          child: const Center(
            child: Text("🎉", style: TextStyle(fontSize: 42)),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          "welcome!",
          style: TextStyle(
            color: _theme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "pick a nickname — make it fun",
          style: TextStyle(color: _theme.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 36),
        TextField(
          controller: _nicknameController,
          style: TextStyle(
            color: _theme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
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
              borderSide:
                  BorderSide(color: accent.withOpacity(0.5), width: 1.5),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Color(0xFFFF6F6F), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 28),
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
            onPressed: _isLoading ? null : _handleCompleteLogin,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _theme.textPrimary,
                    ),
                  )
                : const Text(
                    "jump in! →",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _animateStepChange(_LoginStep.key),
          child: Text(
            "← different key",
            style: TextStyle(color: _theme.textMuted, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ─── Step 2b: Welcome Back (Returning) ───────────────────────────
  Widget _buildWelcomeBackStep(Color accent) {
    final name = _nicknameController.text.isNotEmpty
        ? _nicknameController.text
        : "there";

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withOpacity(0.14),
          ),
          child: Center(
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(
                color: accent,
                fontSize: 42,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          "hey, $name!",
          style: TextStyle(
            color: _theme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "welcome back 👋",
          style: TextStyle(color: _theme.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _isLoading ? null : _handleCompleteLogin,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _theme.textPrimary,
                    ),
                  )
                : const Text(
                    "yey! 🎉",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _animateStepChange(_LoginStep.key),
          child: Text(
            "← different key",
            style: TextStyle(color: _theme.textMuted, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
