import 'package:flutter/material.dart';
import 'screens/chat_list_screen.dart';
import 'screens/login_screen.dart';
import 'services/chat_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final chatService = ChatService();
  final themeService = ThemeService();
  await chatService.init();
  await themeService.init();
  runApp(const KeyMsgApp());
}

class KeyMsgApp extends StatefulWidget {
  const KeyMsgApp({super.key});

  @override
  State<KeyMsgApp> createState() => _KeyMsgAppState();
}

class _KeyMsgAppState extends State<KeyMsgApp> {
  final _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeyMsg',
      debugShowCheckedModeBanner: false,
      theme: _themeService.buildTheme(),
      home: const RootNavigationHandler(),
    );
  }
}

class RootNavigationHandler extends StatefulWidget {
  const RootNavigationHandler({super.key});

  @override
  State<RootNavigationHandler> createState() => _RootNavigationHandlerState();
}

class _RootNavigationHandlerState extends State<RootNavigationHandler> {
  final _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _chatService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _chatService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = _chatService.currentUser;
    if (user == null) {
      return LoginScreen(onLoginSuccess: (_) => setState(() {}));
    }
    return ChatListScreen(currentUser: user);
  }
}
