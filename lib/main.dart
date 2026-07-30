import 'package:flutter/material.dart';
import 'screens/chat_list_screen.dart';
import 'screens/login_screen.dart';
import 'services/chat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final chatService = ChatService();
  await chatService.init();
  runApp(const KeyMsgApp());
}

class KeyMsgApp extends StatelessWidget {
  const KeyMsgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Key Private Messaging',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF8B5CF6),
          surface: Color(0xFF1E293B),
          background: Color(0xFF0F172A),
        ),
        fontFamily: 'Roboto',
      ),
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
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _chatService.currentUser;

    if (user == null) {
      return LoginScreen(
        onLoginSuccess: (userProfile) {
          setState(() {});
        },
      );
    }

    return ChatListScreen(currentUser: user);
  }
}
