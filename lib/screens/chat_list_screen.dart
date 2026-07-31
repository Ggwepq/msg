import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/chat_service.dart';
import '../services/theme_service.dart';
import 'chat_detail_screen.dart';
import 'settings_screen.dart';

class ChatListScreen extends StatefulWidget {
  final UserProfile currentUser;

  const ChatListScreen({super.key, required this.currentUser});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  final _chatService = ChatService();
  final _theme = ThemeService();
  final _keyInputController = TextEditingController();
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _chatService.addListener(_onStateChanged);
    _theme.addListener(_onStateChanged);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _chatService.removeListener(_onStateChanged);
    _theme.removeListener(_onStateChanged);
    _keyInputController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _showAddFriendDialog(UserProfile currentUser) {
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        final accent = _theme.primary;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _theme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                "add friend",
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
                    "enter your friend's key code to start chatting",
                    style: TextStyle(color: _theme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _keyInputController,
                    style: TextStyle(
                      color: _theme.textPrimary,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: "e.g. ALICE-1234",
                      filled: true,
                      fillColor: _theme.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Color(0xFFFF6F6F), fontSize: 13),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _keyInputController.clear();
                    Navigator.pop(context);
                  },
                  child: Text("cancel", style: TextStyle(color: _theme.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final friendProfile = await _chatService.addFriendByKey(_keyInputController.text);
                      _keyInputController.clear();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Connected with ${friendProfile.nickname} ✨")),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              currentUser: currentUser,
                              peerUser: friendProfile,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      setDialogState(() {
                        errorText = e.toString().replaceAll("Exception: ", "");
                      });
                    }
                  },
                  child: const Text("connect", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableChats = _chatService.getAvailableChats();
    final accent = _theme.primary;
    final user = _chatService.currentUser ?? widget.currentUser;

    return Scaffold(
      backgroundColor: _theme.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: accent,
        elevation: 4,
        onPressed: () => _showAddFriendDialog(user),
        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entranceController,
                  curve: Curves.easeOut,
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _entranceController,
                    curve: Curves.easeOutCubic,
                  )),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "hey, ${user.nickname} 👋",
                                style: TextStyle(
                                  color: _theme.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                availableChats.isEmpty
                                    ? "no conversations yet"
                                    : "${availableChats.length} conversation${availableChats.length == 1 ? '' : 's'}",
                                style: TextStyle(
                                  color: _theme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, anim, _) =>
                                    SettingsScreen(currentUser: user),
                                transitionsBuilder: (context, anim, _, child) {
                                  return FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.05, 0),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeOutCubic,
                                      )),
                                      child: child,
                                    ),
                                  );
                                },
                                transitionDuration:
                                    const Duration(milliseconds: 300),
                              ),
                            ).then((_) {
                              if (mounted) setState(() {});
                            });
                          },
                          child: Hero(
                            tag: "avatar_${user.id}",
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  user.nickname.isNotEmpty
                                      ? user.nickname[0].toUpperCase()
                                      : "?",
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Chat list
          if (availableChats.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _entranceController,
                    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("🫥", style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        "pretty quiet in here",
                        style: TextStyle(
                          color: _theme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final chatUser = availableChats[index];
                    final conversation =
                        _chatService.getConversationWith(chatUser.id);
                    final lastMsg = conversation.isNotEmpty
                        ? conversation.last.text
                        : "tap to say hi";
                    final lastTime = conversation.isNotEmpty
                        ? _formatTime(conversation.last.timestamp)
                        : "";

                    // Staggered entrance
                    final delay = (index * 0.08).clamp(0.0, 0.5);
                    final itemAnim = CurvedAnimation(
                      parent: _entranceController,
                      curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0),
                          curve: Curves.easeOutCubic),
                    );

                    return FadeTransition(
                      opacity: itemAnim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(itemAnim),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              splashColor: accent.withOpacity(0.08),
                              highlightColor: accent.withOpacity(0.04),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, anim, _) =>
                                        ChatDetailScreen(
                                      currentUser: user,
                                      peerUser: chatUser,
                                    ),
                                    transitionsBuilder:
                                        (context, anim, _, child) {
                                      return FadeTransition(
                                        opacity: anim,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.04, 0),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: anim,
                                            curve: Curves.easeOutCubic,
                                          )),
                                          child: child,
                                        ),
                                      );
                                    },
                                    transitionDuration:
                                        const Duration(milliseconds: 280),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: accent.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          chatUser.nickname.isNotEmpty
                                              ? chatUser.nickname[0]
                                                  .toUpperCase()
                                              : "?",
                                          style: TextStyle(
                                            color: accent,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chatUser.nickname,
                                            style: TextStyle(
                                              color: _theme.textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            lastMsg,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: _theme.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (lastTime.isNotEmpty)
                                      Text(
                                        lastTime,
                                        style: TextStyle(
                                          color: _theme.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: availableChats.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return "${diff.inDays}d";
    return "${dt.month}/${dt.day}";
  }
}
