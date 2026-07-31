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
  String _adminNickname = "Host";
  final List<AccessKey> _keys = [];
  final List<ChatMessage> _messages = [];
  bool _initialized = false;

  UserProfile? get currentUser => _currentUser;
  String get adminNickname => _adminNickname;
  List<AccessKey> get keys => List.unmodifiable(_keys);
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    
    // Load admin nickname
    final storedAdminName = prefs.getString('admin_nickname');
    if (storedAdminName != null && storedAdminName.isNotEmpty) {
      _adminNickname = storedAdminName;
    }

    // Load stored keys
    final keysJson = prefs.getStringList('access_keys');
    if (keysJson != null && keysJson.isNotEmpty) {
      _keys.clear();
      for (var k in keysJson) {
        _keys.add(AccessKey.fromJson(jsonDecode(k)));
      }
    } else {
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

    // Load active session user
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      _currentUser = UserProfile.fromJson(jsonDecode(userJson));
      await _loadAddedFriendKeys();
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
        text: "Hey! Glad I got your invite key. How are you doing?",
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatMessage(
        id: "msg_2",
        senderId: adminId,
        senderNickname: _adminNickname,
        receiverId: "user_alice",
        text: "Hey Alice! Welcome to our private messaging space!",
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      ),
    ]);
  }

  // Validate Key
  AccessKeyValidation validateKey(String rawKey) {
    final cleanKey = rawKey.trim().toUpperCase();
    if (cleanKey.isEmpty) {
      throw Exception("Please enter your key.");
    }

    // Check Master Key
    if (cleanKey == adminMasterKey) {
      final hasSetName = _adminNickname != "Host";
      return AccessKeyValidation(
        key: adminMasterKey,
        isMasterKey: true,
        existingNickname: hasSetName ? _adminNickname : null,
        isReturning: hasSetName,
      );
    }

    final keyIndex = _keys.indexWhere((k) => k.key.toUpperCase() == cleanKey);
    if (keyIndex == -1) {
      throw Exception("Key not recognized. Please check your key!");
    }

    final matchedKey = _keys[keyIndex];
    // isReturning = key has been claimed before (has a userId)
    final isReturning = matchedKey.isClaimed && matchedKey.claimedByUserId != null;
    return AccessKeyValidation(
      key: matchedKey.key,
      isMasterKey: false,
      existingNickname: matchedKey.claimedByNickname,
      isReturning: isReturning,
    );
  }

  // Complete Login
  Future<UserProfile> completeLogin({
    required String keyInput,
    String? nickname,
  }) async {
    final cleanKey = keyInput.trim().toUpperCase();
    final prefs = await SharedPreferences.getInstance();

    // Check Master Key
    if (cleanKey == adminMasterKey) {
      final nameToUse = (nickname != null && nickname.trim().isNotEmpty)
          ? nickname.trim()
          : _adminNickname;

      _adminNickname = nameToUse;
      await prefs.setString('admin_nickname', nameToUse);

      final adminProfile = UserProfile(
        id: adminId,
        nickname: nameToUse,
        role: UserRole.admin,
        accessKey: adminMasterKey,
        lastSeen: DateTime.now(),
      );
      _currentUser = adminProfile;
      await _saveUserSession(adminProfile);
      notifyListeners();
      return adminProfile;
    }

    // Friend Key
    final keyIndex = _keys.indexWhere((k) => k.key.toUpperCase() == cleanKey);
    if (keyIndex == -1) {
      throw Exception("Key invalid.");
    }

    final matchedKey = _keys[keyIndex];

    // Use provided nickname if given, else fall back to pre-set, else error
    final finalNickname = (nickname != null && nickname.trim().isNotEmpty)
        ? nickname.trim()
        : (matchedKey.claimedByNickname ?? "").trim();

    if (finalNickname.isEmpty) {
      throw Exception("Please set your nickname.");
    }

    final userId = matchedKey.claimedByUserId ??
        "user_${finalNickname.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}";

    matchedKey.isClaimed = true;
    matchedKey.claimedByUserId = userId;
    matchedKey.claimedByNickname = finalNickname;
    matchedKey.claimedAt ??= DateTime.now();

    final userProfile = UserProfile(
      id: userId,
      nickname: finalNickname,
      role: UserRole.friend,
      accessKey: matchedKey.key,
      lastSeen: DateTime.now(),
    );

    _currentUser = userProfile;
    await _loadAddedFriendKeys();
    await _saveKeys();
    await _saveUserSession(userProfile);
    notifyListeners();
    return userProfile;
  }

  // Update current user's nickname dynamically across app & message history
  Future<void> updateNickname(String newNickname) async {
    if (_currentUser == null) return;
    final cleanName = newNickname.trim();
    if (cleanName.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    _currentUser = UserProfile(
      id: _currentUser!.id,
      nickname: cleanName,
      role: _currentUser!.role,
      accessKey: _currentUser!.accessKey,
      lastSeen: DateTime.now(),
    );

    if (_currentUser!.role == UserRole.admin) {
      _adminNickname = cleanName;
      await prefs.setString('admin_nickname', cleanName);
    } else if (_currentUser!.accessKey != null) {
      final keyIndex = _keys.indexWhere((k) => k.key == _currentUser!.accessKey);
      if (keyIndex != -1) {
        _keys[keyIndex].claimedByNickname = cleanName;
        await _saveKeys();
      }
    }

    // Update sender nickname in message history
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].senderId == _currentUser!.id) {
        _messages[i] = ChatMessage(
          id: _messages[i].id,
          senderId: _messages[i].senderId,
          senderNickname: cleanName,
          receiverId: _messages[i].receiverId,
          text: _messages[i].text,
          timestamp: _messages[i].timestamp,
          isRead: _messages[i].isRead,
        );
      }
    }
    await _saveMessages();

    await _saveUserSession(_currentUser!);
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    notifyListeners();
  }

  // Generate new key — prefix becomes default nickname for the friend
  Future<AccessKey> generateNewKey([String? customPrefix]) async {
    final rawPrefix = (customPrefix ?? "").trim();
    final prefix = rawPrefix.isNotEmpty
        ? rawPrefix.toUpperCase().replaceAll(' ', '-')
        : "KEY";
    final randomSuffix = (1000 + (DateTime.now().microsecondsSinceEpoch % 9000)).toString();
    final newKeyCode = "$prefix-$randomSuffix";

    // Title-case the raw prefix for use as default nickname
    String? defaultNickname;
    if (rawPrefix.isNotEmpty) {
      defaultNickname = rawPrefix
          .split(RegExp(r'[\s\-_]'))
          .where((w) => w.isNotEmpty)
          .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
          .join(' ');
    }

    final newKey = AccessKey(
      key: newKeyCode,
      createdAt: DateTime.now(),
      claimedByNickname: defaultNickname,
    );

    _keys.insert(0, newKey);
    await _saveKeys();
    notifyListeners();
    return newKey;
  }

  // Delete key
  Future<void> deleteKey(String keyCode) async {
    _keys.removeWhere((k) => k.key == keyCode);
    await _saveKeys();
    notifyListeners();
  }

  // Delete message (marks as deleted so placeholder remains)
  Future<void> deleteMessage(String messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index].isDeleted = true;
      await _saveMessages();
      notifyListeners();
    }
  }

  // Toggle Emoji Reaction on a message
  Future<void> toggleReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final msg = _messages[index];
      if (msg.reactions[userId] == emoji) {
        msg.reactions.remove(userId);
      } else {
        msg.reactions[userId] = emoji;
      }
      await _saveMessages();
      notifyListeners();
    }
  }

  // Send message
  Future<void> sendMessage({
    required String text,
    required String receiverId,
    String? replyToText,
    String? replyToSender,
    String messageType = 'text',
    String? mediaPath,
  }) async {
    if (_currentUser == null) return;
    if (text.trim().isEmpty && mediaPath == null) return;

    final newMessage = ChatMessage(
      id: "msg_${DateTime.now().millisecondsSinceEpoch}",
      senderId: _currentUser!.id,
      senderNickname: _currentUser!.nickname,
      receiverId: receiverId,
      text: text.trim(),
      timestamp: DateTime.now(),
      replyToText: replyToText,
      replyToSender: replyToSender,
      messageType: messageType,
      mediaPath: mediaPath,
    );

    _messages.add(newMessage);
    await _saveMessages();
    notifyListeners();
  }

  // Get conversation with another user
  List<ChatMessage> getConversationWith(String otherUserId) {
    if (_currentUser == null) return [];
    
    return _messages.where((m) {
      return (m.senderId == _currentUser!.id && m.receiverId == otherUserId) ||
          (m.senderId == otherUserId && m.receiverId == _currentUser!.id);
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  final List<String> _addedFriendKeys = [];

  List<String> get addedFriendKeys => List.unmodifiable(_addedFriendKeys);

  // Add friend by entering their key
  Future<UserProfile> addFriendByKey(String rawKey) async {
    if (_currentUser == null) throw Exception("Not logged in.");

    final cleanKey = rawKey.trim().toUpperCase();
    if (cleanKey.isEmpty) throw Exception("Please enter a key.");

    if (cleanKey == _currentUser!.accessKey?.toUpperCase()) {
      throw Exception("That's your own key!");
    }

    if (cleanKey == adminMasterKey) {
      return UserProfile(
        id: adminId,
        nickname: _adminNickname,
        role: UserRole.admin,
        accessKey: adminMasterKey,
        lastSeen: DateTime.now(),
      );
    }

    final keyIndex = _keys.indexWhere((k) => k.key.toUpperCase() == cleanKey);
    if (keyIndex == -1) {
      throw Exception("Key not recognized. Please check the key!");
    }

    final matchedKey = _keys[keyIndex];

    if (!_addedFriendKeys.contains(matchedKey.key.toUpperCase())) {
      _addedFriendKeys.add(matchedKey.key.toUpperCase());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('added_friend_keys_${_currentUser!.id}', _addedFriendKeys);
    }

    final targetUserId = matchedKey.claimedByUserId ?? "user_${matchedKey.key.toLowerCase()}";
    final targetNickname = matchedKey.claimedByNickname ?? matchedKey.key;

    final profile = UserProfile(
      id: targetUserId,
      nickname: targetNickname,
      role: UserRole.friend,
      accessKey: matchedKey.key,
      lastSeen: matchedKey.claimedAt ?? DateTime.now(),
    );

    notifyListeners();
    return profile;
  }

  // Load added friend keys for current user
  Future<void> _loadAddedFriendKeys() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('added_friend_keys_${_currentUser!.id}');
    _addedFriendKeys.clear();
    if (list != null) {
      _addedFriendKeys.addAll(list);
    }
  }

  // Get list of conversations for current user
  List<UserProfile> getAvailableChats() {
    if (_currentUser == null) return [];

    if (_currentUser!.role == UserRole.admin) {
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
    } else {
      // Non-Admin Friend: ONLY sees Admin (Host), plus friends whose keys were explicitly added by them
      final Map<String, UserProfile> chatsMap = {};

      // 1. Admin/Host profile (always accessible)
      chatsMap[adminId] = UserProfile(
        id: adminId,
        nickname: _adminNickname,
        role: UserRole.admin,
        accessKey: adminMasterKey,
        lastSeen: DateTime.now(),
      );

      // 2. ONLY friends whose key was added explicitly by the current user
      for (var key in _keys) {
        final isAddedByMe = _addedFriendKeys.contains(key.key.toUpperCase());
        if (isAddedByMe) {
          final targetId = key.claimedByUserId ?? "user_${key.key.toLowerCase()}";
          if (targetId != _currentUser!.id) {
            chatsMap[targetId] = UserProfile(
              id: targetId,
              nickname: key.claimedByNickname ?? key.key,
              role: UserRole.friend,
              accessKey: key.key,
              lastSeen: key.claimedAt ?? DateTime.now(),
            );
          }
        }
      }

      return chatsMap.values.toList();
    }
  }

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

class AccessKeyValidation {
  final String key;
  final bool isMasterKey;
  final String? existingNickname;
  final bool isReturning;

  AccessKeyValidation({
    required this.key,
    required this.isMasterKey,
    this.existingNickname,
    this.isReturning = false,
  });
}
