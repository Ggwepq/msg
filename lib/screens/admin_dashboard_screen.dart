import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/key_badge.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatService = ChatService();
  final _customKeyPrefixController = TextEditingController();

  UserProfile? _selectedFriendChat;
  final _adminMsgController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chatService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _chatService.removeListener(_onStateChanged);
    _tabController.dispose();
    _customKeyPrefixController.dispose();
    _adminMsgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _generateKeyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text("Generate New Invite Key", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Optionally enter a prefix or name for the key (e.g., 'BOB', 'VIP'):",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customKeyPrefixController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "e.g. KEY-SARAH",
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              onPressed: () async {
                final newKey = await _chatService.generateNewKey(_customKeyPrefixController.text);
                _customKeyPrefixController.clear();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Generated Key: ${newKey.key}")),
                  );
                }
              },
              child: const Text("Generate", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _sendAdminMessage() {
    if (_selectedFriendChat == null) return;
    final text = _adminMsgController.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(
      text: text,
      receiverId: _selectedFriendChat!.id,
    );

    _adminMsgController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If Admin tapped into a friend's chat thread
    if (_selectedFriendChat != null) {
      final messages = _chatService.getConversationWith(_selectedFriendChat!.id);

      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedFriendChat = null;
              });
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedFriendChat!.nickname,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "Key: ${_selectedFriendChat!.accessKey ?? 'Invite Key'}",
                style: const TextStyle(color: Color(0xFF34D399), fontSize: 11),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Text("No messages yet in this conversation.", style: TextStyle(color: Colors.white38)),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == ChatService.adminId;
                        return ChatBubble(message: msg, isMe: isMe);
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _adminMsgController,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendAdminMessage(),
                      decoration: InputDecoration(
                        hintText: "Reply to ${_selectedFriendChat!.nickname}...",
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF6366F1),
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _sendAdminMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Main Admin Dashboard
    final friends = _chatService.getActiveFriendList();
    final keys = _chatService.keys;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "Admin Command Center",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: "Logout Admin",
            onPressed: () => _chatService.logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(
              icon: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 18),
                  const SizedBox(width: 6),
                  Text("Inbox (${friends.length})"),
                ],
              ),
            ),
            Tab(
              icon: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.vpn_key_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text("Keys (${keys.length})"),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Inbox Tab
          friends.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.inbox, size: 48, color: Colors.white24),
                      SizedBox(height: 12),
                      Text("No friends have logged in yet.", style: TextStyle(color: Colors.white38)),
                      SizedBox(height: 4),
                      Text("Generate a key in the Keys tab and send it to a friend!",
                          style: TextStyle(color: Colors.white24, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    final conversation = _chatService.getConversationWith(friend.id);
                    final lastMsg = conversation.isNotEmpty ? conversation.last.text : "No messages yet";

                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF6366F1),
                          child: Text(
                            friend.nickname.isNotEmpty ? friend.nickname[0].toUpperCase() : "?",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          friend.nickname,
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
                          setState(() {
                            _selectedFriendChat = friend;
                          });
                        },
                      ),
                    );
                  },
                ),

          // Keys Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: ElevatedButton.icon(
                  onPressed: _generateKeyDialog,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Generate New Access Key", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: keys.length,
                  itemBuilder: (context, index) {
                    final k = keys[index];
                    return KeyBadge(
                      accessKey: k,
                      onDelete: () => _chatService.deleteKey(k.key),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
