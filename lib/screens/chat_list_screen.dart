import 'package:flutter/material.dart';
import '../models/connection_request.dart';
import '../models/user_profile.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
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

  int _lastMessageCount = 0;
  String? _lastNotifiedMessageId;

  void _onStateChanged() {
    if (!mounted) return;

    final currentMessages = _chatService.messages;
    if (_lastMessageCount > 0 && currentMessages.length > _lastMessageCount) {
      final latest = currentMessages.last;
      final user = _chatService.currentUser ?? widget.currentUser;
      if (latest.receiverId == user.id &&
          latest.senderId != user.id &&
          latest.id != _lastNotifiedMessageId) {
        _lastNotifiedMessageId = latest.id;
        _showInAppNotificationBanner(latest);
      }
    }
    _lastMessageCount = currentMessages.length;
    setState(() {});
  }

  void _showInAppNotificationBanner(dynamic msg) {

    final accent = _theme.primary;
    final user = _chatService.currentUser ?? widget.currentUser;

    String previewText = msg.text ?? '';
    if (msg.messageType == 'image') {
      previewText = (msg.text != null && msg.text.isNotEmpty) ? "📷 ${msg.text}" : "📷 Sent a photo";
    } else if (msg.messageType == 'video') {
      previewText = (msg.text != null && msg.text.isNotEmpty) ? "🎥 ${msg.text}" : "🎥 Sent a video";
    }

    // Trigger system-level native notification (lock screen & system tray)
    NotificationService().showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: msg.senderNickname,
      body: previewText,
    );


    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accent.withOpacity(0.4), width: 1.5),
        ),
        content: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            final peer = _chatService.getAvailableChats().firstWhere(
                  (u) => u.id == msg.senderId,
                  orElse: () => UserProfile(
                    id: msg.senderId,
                    nickname: msg.senderNickname,
                    role: UserRole.friend,
                    lastSeen: DateTime.now(),
                  ),
                );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  currentUser: user,
                  peerUser: peer,
                ),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    msg.senderNickname.isNotEmpty ? msg.senderNickname[0].toUpperCase() : "?",
                    style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          msg.senderNickname,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text("• now", style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      previewText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
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
                "add friend by key",
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
                    "enter a claimed key code to send a connection request",
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
                      hintText: "e.g. SECRET-ALICE-123",
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
                      final req = await _chatService.requestConnectionByKey(_keyInputController.text);
                      _keyInputController.clear();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              req.status == 'accepted'
                                  ? "Connected with ${req.receiverNickname} ✨"
                                  : "Request sent to ${req.receiverNickname}! Waiting for them to accept.",
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
                  child: const Text("send request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPendingRequestsSection(List<ConnectionRequest> pendingRequests, Color accent) {
    if (pendingRequests.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_add_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                "connection requests (${pendingRequests.length})",
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: pendingRequests.map((req) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _theme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          req.senderNickname.isNotEmpty ? req.senderNickname[0].toUpperCase() : "?",
                          style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.senderNickname,
                            style: TextStyle(
                              color: _theme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "wants to connect with you",
                            style: TextStyle(color: _theme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Accept Button
                    GestureDetector(
                      onTap: () => _chatService.acceptConnectionRequest(req.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Accept",
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Decline Button
                    GestureDetector(
                      onTap: () => _chatService.declineConnectionRequest(req.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: _theme.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close, color: Colors.white54, size: 16),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableChats = _chatService.getAvailableChats();
    final pendingRequests = _chatService.getPendingRequestsForUser();
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

          // Pending Connection Requests (if any)
          if (pendingRequests.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildPendingRequestsSection(pendingRequests, accent),
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
                    final conversation = _chatService.getConversationWith(chatUser.id);
                    final unreadCount = _chatService.getUnreadCountFrom(chatUser.id);
                    final isUnread = unreadCount > 0;

                    String lastMsgSnippet = "tap to say hi";
                    if (conversation.isNotEmpty) {
                      final last = conversation.last;
                      if (last.isDeleted) {
                        lastMsgSnippet = "message deleted";
                      } else if (last.messageType == 'image') {
                        lastMsgSnippet = last.text.isNotEmpty ? "📷 ${last.text}" : "📷 Photo";
                      } else if (last.messageType == 'video') {
                        lastMsgSnippet = last.text.isNotEmpty ? "🎥 ${last.text}" : "🎥 Video";
                      } else {
                        lastMsgSnippet = last.text;
                      }
                    }

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
                                decoration: isUnread
                                    ? BoxDecoration(
                                        color: accent.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(16),
                                      )
                                    : null,
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: isUnread ? accent.withOpacity(0.2) : accent.withOpacity(0.12),
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
                                        if (isUnread)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: accent,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: _theme.bg, width: 2),
                                              ),
                                            ),
                                          ),
                                      ],
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
                                              fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            lastMsgSnippet,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isUnread ? accent : _theme.textSecondary,
                                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (lastTime.isNotEmpty)
                                          Text(
                                            lastTime,
                                            style: TextStyle(
                                              color: isUnread ? accent : _theme.textMuted,
                                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 11,
                                            ),
                                          ),
                                        if (isUnread) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: accent,
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: accent.withOpacity(0.4),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              "$unreadCount",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
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
