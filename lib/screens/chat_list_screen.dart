import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';
import 'settings_screen.dart';

class ChatListScreen extends StatefulWidget {
  final UserProfile currentUser;

  const ChatListScreen({super.key, required this.currentUser});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _chatService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _chatService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableChats = _chatService.getAvailableChats();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Messages",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.currentUser.nickname,
              style: const TextStyle(color: Color(0xFF34D399), fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: "Settings",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(currentUser: widget.currentUser),
                ),
              );
            },
          ),
        ],
      ),
      body: availableChats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white24),
                  SizedBox(height: 12),
                  Text(
                    "No conversations yet.",
                    style: TextStyle(color: Colors.white38, fontSize: 15),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: availableChats.length,
              itemBuilder: (context, index) {
                final chatUser = availableChats[index];
                final conversation = _chatService.getConversationWith(chatUser.id);
                final lastMsg = conversation.isNotEmpty
                    ? conversation.last.text
                    : "Tap to start messaging";

                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6366F1),
                      child: Text(
                        chatUser.nickname.isNotEmpty ? chatUser.nickname[0].toUpperCase() : "?",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      chatUser.nickname,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            currentUser: widget.currentUser,
                            peerUser: chatUser,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
