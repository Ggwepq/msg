import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/access_key.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';

class ChatService extends ChangeNotifier {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  static const String adminMasterKey = "ADMIN-MASTER-88";
  static const String adminId = "admin_user_id";

  UserProfile? _currentUser;
  final List<AccessKey> _keys = [];
  final List<ChatMessage> _messages = [];
  bool _initialized = false;

  UserProfile? get currentUser => _currentUser;
  List<AccessKey> get keys => List.unmodifiable(_keys);
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    
    // Load stored keys
    final keysJson = prefs.getStringList('access_keys');
    if (keysJson != null && keysJson.isNotEmpty) {
      _keys.clear();
      for (var k in keysJson) {
        _keys.add(AccessKey.fromJson(jsonDecode(k)));
      }
    } else {
      // Seed default initial keys for testing
      _seedDefaultKeys();
      await _saveKeys();
    }

    // Load messages
    final msgsJson = prefs.getStringList('chat_messages');
    if (msgsJson != null && msgsJson.isNotEmpty) {
      _messages.clear();
      for (var m in msgsJson) {
        _messages.add(ChatMessage.fromJson(jsonDecode(m)));
      }
    } else {
      _seedInitialMessages();
      await _saveMessages();
    }

    // Load active session user if any
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      _currentUser = UserProfile.fromJson(jsonDecode(userJson));
    }

    _initialized = true;
    notifyListeners();
  }

  void _seedDefaultKeys() {
    _keys.addAll([
      AccessKey(
        key: "SECRET-ALICE-123",
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isClaimed: true,
        claimedByUserId: "user_alice",
        claimedByNickname: "Alice",
        claimedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      AccessKey(
        key: "KEY-BOB-999",
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        isClaimed: false,
      ),
      AccessKey(
        key: "KEY-VIP-FRIEND",
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isClaimed: false,
      ),
    ]);
  }

  void _seedInitialMessages() {
    _messages.addAll([
      ChatMessage(
        id: "msg_1",
        senderId: "user_alice",
        senderNickname: "Alice",
        receiverId: adminId,
        text: "Hey! Glad I got your invite key. How are you doing after deactivating FB?",
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatMessage(
        id: "msg_2",
        senderId: adminId,
        senderNickname: "You (Admin)",
        receiverId: "user_alice",
        text: "Hey Alice! Feeling much better without all the FB noise. Glad you made it here!",
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      ),
    ]);
  }

  // Login via Access Key & Nickname
  Future<UserProfile> loginWithKey({
    required String keyInput,
    required String nickname,
  }) async {
    final cleanKey = keyInput.trim().toUpperCase();
    final cleanNickname = nickname.trim();

    if (cleanNickname.isEmpty) {
      throw Exception("Please provide a nickname/name.");
    }

    // Check Admin Master Key
    if (cleanKey == adminMasterKey) {
      final adminProfile = UserProfile(
        id: adminId,
        nickname: "Admin (You)",
        role: UserRole.admin,
        lastSeen: DateTime.now(),
      );
      _currentUser = adminProfile;
      await _saveUserSession(adminProfile);
      notifyListeners();
      return adminProfile;
    }

    // Validate Friend Key
    final keyIndex = _keys.indexWhere((k) => k.key.toUpperCase() == cleanKey);
    if (keyIndex == -1) {
      throw Exception("Invalid Access Key. Please check with the app owner.");
    }

    final matchedKey = _keys[keyIndex];

    // If key is already claimed by someone else with different user ID
    final existingUserId = matchedKey.claimedByUserId ?? "user_${cleanNickname.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}";

    matchedKey.isClaimed = true;
    matchedKey.claimedByUserId = existingUserId;
    matchedKey.claimedByNickname = cleanNickname;
    matchedKey.claimedAt ??= DateTime.now();

    final friendProfile = UserProfile(
      id: existingUserId,
      nickname: cleanNickname,
      role: UserRole.friend,
      accessKey: matchedKey.key,
      lastSeen: DateTime.now(),
    );

    _currentUser = friendProfile;
    await _saveKeys();
    await _saveUserSession(friendProfile);
    notifyListeners();
    return friendProfile;
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    notifyListeners();
  }

  // Generate new access key (Admin only)
  Future<AccessKey> generateNewKey([String? customPrefix]) async {
    final prefix = (customPrefix != null && customPrefix.isNotEmpty)
        ? customPrefix.toUpperCase().replaceAll(' ', '-')
        : "KEY";
    final randomSuffix = (1000 + (DateTime.now().microsecondsSinceEpoch % 9000)).toString();
    final newKeyCode = "$prefix-$randomSuffix";

    final newKey = AccessKey(
      key: newKeyCode,
      createdAt: DateTime.now(),
    );

    _keys.insert(0, newKey);
    await _saveKeys();
    notifyListeners();
    return newKey;
  }

  // Delete Access Key (Admin only)
  Future<void> deleteKey(String keyCode) async {
    _keys.removeWhere((k) => k.key == keyCode);
    await _saveKeys();
    notifyListeners();
  }

  // Send a message
  Future<void> sendMessage({
    required String text,
    required String receiverId,
  }) async {
    if (_currentUser == null) return;
    if (text.trim().isEmpty) return;

    final newMessage = ChatMessage(
      id: "msg_${DateTime.now().millisecondsSinceEpoch}",
      senderId: _currentUser!.id,
      senderNickname: _currentUser!.nickname,
      receiverId: receiverId,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    _messages.add(newMessage);
    await _saveMessages();
    notifyListeners();
  }

  // Get conversation messages between current user and a friend
  List<ChatMessage> getConversationWith(String otherUserId) {
    if (_currentUser == null) return [];
    
    return _messages.where((m) {
      final isBetween = (m.senderId == _currentUser!.id && m.receiverId == otherUserId) ||
          (m.senderId == otherUserId && m.receiverId == _currentUser!.id);
      return isBetween;
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // Get list of friends who have chatted or claimed keys (for Admin view)
  List<UserProfile> getActiveFriendList() {
    final Map<String, UserProfile> friendsMap = {};

    for (var key in _keys) {
      if (key.isClaimed && key.claimedByUserId != null) {
        friendsMap[key.claimedByUserId!] = UserProfile(
          id: key.claimedByUserId!,
          nickname: key.claimedByNickname ?? "Friend",
          role: UserRole.friend,
          accessKey: key.key,
          lastSeen: key.claimedAt ?? DateTime.now(),
        );
      }
    }

    // Add any users present in message history
    for (var m in _messages) {
      if (m.senderId != adminId && !friendsMap.containsKey(m.senderId)) {
        friendsMap[m.senderId] = UserProfile(
          id: m.senderId,
          nickname: m.senderNickname,
          role: UserRole.friend,
          lastSeen: m.timestamp,
        );
      }
    }

    return friendsMap.values.toList();
  }

  // Persistence helpers
  Future<void> _saveKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _keys.map((k) => jsonEncode(k.toJson())).toList();
    await prefs.setStringList('access_keys', jsonList);
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _messages.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList('chat_messages', jsonList);
  }

  Future<void> _saveUserSession(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user.toJson()));
  }
}
