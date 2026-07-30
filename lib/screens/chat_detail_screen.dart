import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../services/chat_service.dart';
import '../services/theme_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_context_menu.dart';

class ChatDetailScreen extends StatefulWidget {
  final UserProfile currentUser;
  final UserProfile peerUser;

  const ChatDetailScreen({
    super.key,
    required this.currentUser,
    required this.peerUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final _theme = ThemeService();
  final _focusNode = FocusNode();
  late AnimationController _entranceController;

  ChatMessage? _replyingToMessage;
  OverlayEntry? _contextMenuOverlay;

  @override
  void initState() {
    super.initState();
    _chatService.addListener(_onChatUpdated);
    _theme.addListener(_onChatUpdated);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _removeContextMenu();
    _chatService.removeListener(_onChatUpdated);
    _theme.removeListener(_onChatUpdated);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _onChatUpdated() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(
      text: text,
      receiverId: widget.peerUser.id,
      replyToText: _replyingToMessage?.text,
      replyToSender: _replyingToMessage?.senderNickname,
    );

    _messageController.clear();
    setState(() {
      _replyingToMessage = null;
    });
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  void _removeContextMenu() {
    _contextMenuOverlay?.remove();
    _contextMenuOverlay = null;
  }

  void _showContextMenu(ChatMessage message, bool isMe, Offset position, Size size) {
    _removeContextMenu();

    _contextMenuOverlay = OverlayEntry(
      builder: (context) {
        return MessageContextMenu(
          message: message,
          isMe: isMe,
          tapPosition: position,
          bubbleSize: size,
          onDismiss: _removeContextMenu,
          onReactionSelect: (emoji) {
            _chatService.toggleReaction(
              messageId: message.id,
              userId: widget.currentUser.id,
              emoji: emoji,
            );
          },
          onCopy: () {
            Clipboard.setData(ClipboardData(text: message.text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Copied to clipboard 📋")),
            );
          },
          onReply: () {
            setState(() {
              _replyingToMessage = message;
            });
            _focusNode.requestFocus();
          },
          onDelete: isMe
              ? () {
                  _chatService.deleteMessage(message.id);
                }
              : null,
        );
      },
    );

    Overlay.of(context).insert(_contextMenuOverlay!);
  }

  void _showReactionsBottomSheet(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final entries = message.reactions.entries.toList();

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Reactions",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text("No reactions yet", style: TextStyle(color: Colors.white38)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final userId = entries[index].key;
                      final emoji = entries[index].value;
                      final isMyReaction = userId == widget.currentUser.id;
                      final displayName = isMyReaction
                          ? "You"
                          : (userId == widget.peerUser.id ? widget.peerUser.nickname : "Friend");

                      return ListTile(
                        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
                        title: Text(
                          displayName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        subtitle: isMyReaction
                            ? const Text("Tap to remove your reaction", style: TextStyle(color: Colors.white54, fontSize: 12))
                            : null,
                        trailing: isMyReaction
                            ? const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18)
                            : null,
                        onTap: () {
                          if (isMyReaction) {
                            _chatService.toggleReaction(
                              messageId: message.id,
                              userId: widget.currentUser.id,
                              emoji: emoji,
                            );
                            Navigator.pop(context);
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = _chatService.getConversationWith(widget.peerUser.id);
    final accent = _theme.primary;
    final isAdmin = widget.currentUser.role == UserRole.admin;

    return Scaffold(
      backgroundColor: _theme.bg,
      appBar: AppBar(
        backgroundColor: _theme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.peerUser.nickname.isNotEmpty
                      ? widget.peerUser.nickname[0].toUpperCase()
                      : "?",
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.peerUser.nickname,
              style: TextStyle(
                color: _theme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(height: 1, color: accent.withOpacity(0.06)),

          // Messages List
          Expanded(
            child: messages.isEmpty
                ? FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _entranceController,
                      curve: Curves.easeOut,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("💬", style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 10),
                          Text(
                            "say something!",
                            style: TextStyle(
                              color: _theme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == widget.currentUser.id;
                      return ChatBubble(
                        message: msg,
                        isMe: isMe,
                        isAdmin: isAdmin,
                        onLongPress: (position, size) =>
                            _showContextMenu(msg, isMe, position, size),
                        onReactionBadgeTap: () => _showReactionsBottomSheet(msg),
                      );
                    },
                  ),
          ),

          // Reply Preview Banner
          if (_replyingToMessage != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _theme.surface,
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Replying to ${_replyingToMessage!.senderNickname}",
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _replyingToMessage!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _theme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: _theme.textMuted),
                    onPressed: () {
                      setState(() {
                        _replyingToMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Input bar
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _entranceController,
              curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
            ),
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 8,
                top: 10,
                bottom: MediaQuery.of(context).padding.bottom + 10,
              ),
              decoration: BoxDecoration(
                color: _theme.bg,
                border: Border(top: BorderSide(color: _theme.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: _theme.textPrimary,
                        fontSize: 14,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: _replyingToMessage != null
                            ? "Type your reply..."
                            : "type something...",
                        hintStyle: TextStyle(color: _theme.textMuted),
                        filled: true,
                        fillColor: _theme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
