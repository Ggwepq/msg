import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/access_key.dart';
import '../models/chat_message.dart';
import '../models/connection_request.dart';
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
  final List<ConnectionRequest> _connectionRequests = [];
  bool _initialized = false;

  StreamSubscription? _keysSub;
  StreamSubscription? _messagesSub;
  StreamSubscription? _requestsSub;
  StreamSubscription? _adminSub;

  bool get isFirebaseReady => Firebase.apps.isNotEmpty;
  UserProfile? get currentUser => _currentUser;
  String get adminNickname => _adminNickname;
  List<AccessKey> get keys => List.unmodifiable(_keys);
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ConnectionRequest> get connectionRequests => List.unmodifiable(_connectionRequests);

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();

    // Load active user session from local preferences
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      try {
        _currentUser = UserProfile.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }

    if (isFirebaseReady) {
      try {
        _setupFirestoreListeners();
      } catch (e) {
        debugPrint('Firestore init fallback: $e');
        await _loadFromSharedPreferences(prefs);
      }
    } else {
      await _loadFromSharedPreferences(prefs);
    }

    _initialized = true;
    notifyListeners();
  }

  void _setupFirestoreListeners() {
    if (!isFirebaseReady) return;
    final firestore = FirebaseFirestore.instance;

    // Listen to admin nickname
    _adminSub = firestore.collection('app_config').doc('admin').snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        _adminNickname = doc.data()!['nickname'] as String? ?? "Host";
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Admin nickname stream error: $e');
    });

    // Listen to Access Keys
    _keysSub = firestore.collection('access_keys').snapshots().listen((snapshot) {
      _keys.clear();
      for (var doc in snapshot.docs) {
        _keys.add(AccessKey.fromJson(doc.data()));
      }
      if (_keys.isEmpty) {
        _seedDefaultKeysFirestore();
      }
      notifyListeners();
    }, onError: (e) {
      debugPrint('Keys stream error: $e');
    });

    // Listen to Messages
    _messagesSub = firestore.collection('chat_messages').orderBy('timestamp').snapshots().listen((snapshot) {
      _messages.clear();
      for (var doc in snapshot.docs) {
        _messages.add(ChatMessage.fromJson(doc.data()));
      }
      if (_messages.isEmpty) {
        _seedInitialMessagesFirestore();
      }
      notifyListeners();
    }, onError: (e) {
      debugPrint('Messages stream error: $e');
    });

    // Listen to Connection Requests
    _requestsSub = firestore.collection('connection_requests').snapshots().listen((snapshot) {
      _connectionRequests.clear();
      for (var doc in snapshot.docs) {
        _connectionRequests.add(ConnectionRequest.fromJson(doc.data()));
      }
      notifyListeners();
    }, onError: (e) {
      debugPrint('Connection requests stream error: $e');
    });
  }

  Future<void> _loadFromSharedPreferences(SharedPreferences prefs) async {
    final storedAdminName = prefs.getString('admin_nickname');
    if (storedAdminName != null && storedAdminName.isNotEmpty) {
      _adminNickname = storedAdminName;
    }

    final keysJson = prefs.getStringList('access_keys');
    if (keysJson != null && keysJson.isNotEmpty) {
      _keys.clear();
      for (var k in keysJson) {
        _keys.add(AccessKey.fromJson(jsonDecode(k)));
      }
    } else {
      _seedDefaultKeys();
      await _saveKeysLocal();
    }

    final msgsJson = prefs.getStringList('chat_messages');
    if (msgsJson != null && msgsJson.isNotEmpty) {
      _messages.clear();
      for (var m in msgsJson) {
        _messages.add(ChatMessage.fromJson(jsonDecode(m)));
      }
    } else {
      _seedInitialMessages();
      await _saveMessagesLocal();
    }

    final reqsJson = prefs.getStringList('connection_requests');
    if (reqsJson != null && reqsJson.isNotEmpty) {
      _connectionRequests.clear();
      for (var r in reqsJson) {
        _connectionRequests.add(ConnectionRequest.fromJson(jsonDecode(r)));
      }
    }
  }

  Future<void> _seedDefaultKeysFirestore() async {
    if (!isFirebaseReady) return;
    final firestore = FirebaseFirestore.instance;
    final defaults = [
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
    ];

    for (var k in defaults) {
      try {
        await firestore.collection('access_keys').doc(k.key).set(k.toJson());
      } catch (_) {}
    }
  }

  Future<void> _seedInitialMessagesFirestore() async {
    if (!isFirebaseReady) return;
    final firestore = FirebaseFirestore.instance;
    final defaults = [
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
    ];

    for (var m in defaults) {
      try {
        await firestore.collection('chat_messages').doc(m.id).set(m.toJson());
      } catch (_) {}
    }
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

  AccessKeyValidation validateKey(String rawKey) {
    final cleanKey = rawKey.trim().toUpperCase();
    if (cleanKey.isEmpty) {
      throw Exception("Please enter your key.");
    }

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
    final isReturning = matchedKey.isClaimed && matchedKey.claimedByUserId != null;
    return AccessKeyValidation(
      key: matchedKey.key,
      isMasterKey: false,
      existingNickname: matchedKey.claimedByNickname,
      isReturning: isReturning,
    );
  }

  Future<UserProfile> completeLogin({
    required String keyInput,
    String? nickname,
  }) async {
    final cleanKey = keyInput.trim().toUpperCase();
    final prefs = await SharedPreferences.getInstance();

    if (cleanKey == adminMasterKey) {
      final nameToUse = (nickname != null && nickname.trim().isNotEmpty)
          ? nickname.trim()
          : _adminNickname;

      _adminNickname = nameToUse;
      await prefs.setString('admin_nickname', nameToUse);

      if (isFirebaseReady) {
        try {
          await FirebaseFirestore.instance
              .collection('app_config')
              .doc('admin')
              .set({'nickname': nameToUse});
        } catch (_) {}
      }

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

    final keyIndex = _keys.indexWhere((k) => k.key.toUpperCase() == cleanKey);
    if (keyIndex == -1) {
      throw Exception("Key invalid.");
    }

    final matchedKey = _keys[keyIndex];
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

    if (isFirebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('access_keys')
            .doc(matchedKey.key)
            .set(matchedKey.toJson());

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userProfile.id)
            .set(userProfile.toJson());
      } catch (_) {}
    }

    await _saveKeysLocal();
    await _saveUserSession(userProfile);
    notifyListeners();
    return userProfile;
  }

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
      if (isFirebaseReady) {
        try {
          await FirebaseFirestore.instance
              .collection('app_config')
              .doc('admin')
              .set({'nickname': cleanName});
        } catch (_) {}
      }
    } else if (_currentUser!.accessKey != null) {
      final keyIndex = _keys.indexWhere((k) => k.key == _currentUser!.accessKey);
      if (keyIndex != -1) {
        _keys[keyIndex].claimedByNickname = cleanName;
        if (isFirebaseReady) {
          try {
            await FirebaseFirestore.instance
                .collection('access_keys')
                .doc(_keys[keyIndex].key)
                .set(_keys[keyIndex].toJson());
          } catch (_) {}
        }
      }
    }

    if (isFirebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.id)
            .set(_currentUser!.toJson());
      } catch (_) {}
    }

    await _saveUserSession(_currentUser!);
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    notifyListeners();
  }

  Future<AccessKey> generateNewKey([String? customPrefix]) async {
    final rawPrefix = (customPrefix ?? "").trim();
    final prefix = rawPrefix.isNotEmpty
        ? rawPrefix.toUpperCase().replaceAll(' ', '-')
        : "KEY";
    final randomSuffix = (1000 + (DateTime.now().microsecondsSinceEpoch % 9000)).toString();
    final newKeyCode = "$prefix-$randomSuffix";

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

    if (isFirebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('access_keys')
            .doc(newKey.key)
            .set(newKey.toJson());
      } catch (_) {}
    }

    await _saveKeysLocal();
    notifyListeners();
    return newKey;
  }

  Future<void> deleteKey(String keyCode) async {
    _keys.removeWhere((k) => k.key == keyCode);
    if (isFirebaseReady) {
      try {
        await FirebaseFirestore.instance.collection('access_keys').doc(keyCode).delete();
      } catch (_) {}
    }
    await _saveKeysLocal();
    notifyListeners();
  }

  Future<void> deleteMessage(String messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index].isDeleted = true;
      if (isFirebaseReady) {
        try {
          await FirebaseFirestore.instance
              .collection('chat_messages')
              .doc(messageId)
              .update({'isDeleted': true});
        } catch (_) {}
      }
      await _saveMessagesLocal();
      notifyListeners();
    }
  }

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

      if (isFirebaseReady) {
        try {
          await FirebaseFirestore.instance
              .collection('chat_messages')
              .doc(messageId)
              .update({'reactions': msg.reactions});
        } catch (_) {}
      }

      await _saveMessagesLocal();
      notifyListeners();
    }
  }

  final Map<String, double> _uploadProgress = {};

  double? getUploadProgress(String messageId) => _uploadProgress[messageId];

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

    final String messageId = "msg_${DateTime.now().millisecondsSinceEpoch}";
    final String localMediaPath = mediaPath ?? '';

    // 1. Immediately create message with local path for instant UI feedback
    final newMessage = ChatMessage(
      id: messageId,
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
    await _saveMessagesLocal();
    notifyListeners();

    // 2. Perform background upload if media file exists and Firebase is active
    if (isFirebaseReady && localMediaPath.isNotEmpty && !localMediaPath.startsWith('http')) {
      final file = File(localMediaPath);
      if (await file.exists()) {
        _uploadProgress[messageId] = 0.01;
        notifyListeners();

        try {
          final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
          final storageRef = FirebaseStorage.instance.ref().child('chat_media/$fileName');
          final uploadTask = storageRef.putFile(file);

          final sub = uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            if (snapshot.totalBytes > 0) {
              _uploadProgress[messageId] = snapshot.bytesTransferred / snapshot.totalBytes;
              notifyListeners();
            }
          });

          final TaskSnapshot completedSnapshot = await uploadTask;
          final downloadUrl = await completedSnapshot.ref.getDownloadURL();
          await sub.cancel();
          _uploadProgress.remove(messageId);

          // Update message with public cloud URL
          final index = _messages.indexWhere((m) => m.id == messageId);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: newMessage.id,
              senderId: newMessage.senderId,
              senderNickname: newMessage.senderNickname,
              receiverId: newMessage.receiverId,
              text: newMessage.text,
              timestamp: newMessage.timestamp,
              isRead: newMessage.isRead,
              replyToText: newMessage.replyToText,
              replyToSender: newMessage.replyToSender,
              messageType: newMessage.messageType,
              mediaPath: downloadUrl,
              isDeleted: newMessage.isDeleted,
              reactions: newMessage.reactions,
            );

            await FirebaseFirestore.instance
                .collection('chat_messages')
                .doc(messageId)
                .set(_messages[index].toJson());

            await _saveMessagesLocal();
            notifyListeners();
          }
          return;
        } catch (e) {
          debugPrint('Firebase Storage upload notice: $e');
          _uploadProgress.remove(messageId);
          notifyListeners();
        }
      }
    }

    // Write to Firestore if not uploading media or if upload was skipped
    if (isFirebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('chat_messages')
            .doc(newMessage.id)
            .set(newMessage.toJson());
      } catch (_) {}
    }
  }


  List<ChatMessage> getConversationWith(String otherUserId) {
    if (_currentUser == null) return [];

    return _messages.where((m) {
      return (m.senderId == _currentUser!.id && m.receiverId == otherUserId) ||
          (m.senderId == otherUserId && m.receiverId == _currentUser!.id);
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<ConnectionRequest> requestConnectionByKey(String rawKey) async {
    if (_currentUser == null) throw Exception("Not logged in.");

    final cleanKey = rawKey.trim().toUpperCase();
    if (cleanKey.isEmpty) throw Exception("Please enter a key.");

    if (cleanKey == adminMasterKey) {
      throw Exception("That's the Admin key. Admin is already in your chat list!");
    }

    final keyIndex = _keys.indexWhere((k) => k.key.toUpperCase() == cleanKey);
    if (keyIndex == -1) {
      throw Exception("Key not recognized. Please check the key!");
    }

    final matchedKey = _keys[keyIndex];

    if (!matchedKey.isClaimed || matchedKey.claimedByUserId == null) {
      throw Exception("This key hasn't been claimed by anyone yet! Ask your friend to log in with this key first.");
    }

    if (matchedKey.claimedByUserId == _currentUser!.id) {
      throw Exception("That's your own key!");
    }

    final targetUserId = matchedKey.claimedByUserId!;
    final targetNickname = matchedKey.claimedByNickname ?? matchedKey.key;

    final isAlreadyConnected = _connectionRequests.any((r) =>
        r.status == 'accepted' &&
        ((r.senderUserId == _currentUser!.id && r.receiverUserId == targetUserId) ||
            (r.senderUserId == targetUserId && r.receiverUserId == _currentUser!.id)));

    if (isAlreadyConnected) {
      throw Exception("You are already connected with $targetNickname!");
    }

    final existingPending = _connectionRequests.firstWhere(
      (r) =>
          r.status == 'pending' &&
          ((r.senderUserId == _currentUser!.id && r.receiverUserId == targetUserId) ||
              (r.senderUserId == targetUserId && r.receiverUserId == _currentUser!.id)),
      orElse: () => ConnectionRequest(
          id: '', senderUserId: '', senderNickname: '', receiverUserId: '', receiverNickname: '', timestamp: DateTime.now()),
    );

    if (existingPending.id.isNotEmpty) {
      if (existingPending.senderUserId == _currentUser!.id) {
        throw Exception("Connection request already sent to $targetNickname! Waiting for them to accept.");
      } else {
        existingPending.status = 'accepted';
        if (isFirebaseReady) {
          try {
            await FirebaseFirestore.instance
                .collection('connection_requests')
                .doc(existingPending.id)
                .update({'status': 'accepted'});
          } catch (_) {}
        }
        await _saveConnectionRequestsLocal();
        notifyListeners();
        return existingPending;
      }
    }

    final request = ConnectionRequest(
      id: "req_${DateTime.now().millisecondsSinceEpoch}",
      senderUserId: _currentUser!.id,
      senderNickname: _currentUser!.nickname,
      receiverUserId: targetUserId,
      receiverNickname: targetNickname,
      timestamp: DateTime.now(),
      status: 'pending',
    );

    _connectionRequests.add(request);

    if (isFirebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('connection_requests')
            .doc(request.id)
            .set(request.toJson());
      } catch (_) {}
    }

    await _saveConnectionRequestsLocal();
    notifyListeners();
    return request;
  }

  List<ConnectionRequest> getPendingRequestsForUser() {
    if (_currentUser == null) return [];
    return _connectionRequests
        .where((r) => r.receiverUserId == _currentUser!.id && r.status == 'pending')
        .toList();
  }

  Future<void> acceptConnectionRequest(String requestId) async {
    final index = _connectionRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _connectionRequests[index].status = 'accepted';
      if (isFirebaseReady) {
        try {
          await FirebaseFirestore.instance
              .collection('connection_requests')
              .doc(requestId)
              .update({'status': 'accepted'});
        } catch (_) {}
      }
      await _saveConnectionRequestsLocal();
      notifyListeners();
    }
  }

  Future<void> declineConnectionRequest(String requestId) async {
    final index = _connectionRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _connectionRequests[index].status = 'declined';
      if (isFirebaseReady) {
        try {
          await FirebaseFirestore.instance
              .collection('connection_requests')
              .doc(requestId)
              .update({'status': 'declined'});
        } catch (_) {}
      }
      await _saveConnectionRequestsLocal();
      notifyListeners();
    }
  }

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
      final Map<String, UserProfile> chatsMap = {};

      chatsMap[adminId] = UserProfile(
        id: adminId,
        nickname: _adminNickname,
        role: UserRole.admin,
        accessKey: adminMasterKey,
        lastSeen: DateTime.now(),
      );

      for (var req in _connectionRequests) {
        if (req.status == 'accepted') {
          if (req.senderUserId == _currentUser!.id) {
            chatsMap[req.receiverUserId] = UserProfile(
              id: req.receiverUserId,
              nickname: req.receiverNickname,
              role: UserRole.friend,
              lastSeen: req.timestamp,
            );
          } else if (req.receiverUserId == _currentUser!.id) {
            chatsMap[req.senderUserId] = UserProfile(
              id: req.senderUserId,
              nickname: req.senderNickname,
              role: UserRole.friend,
              lastSeen: req.timestamp,
            );
          }
        }
      }

      return chatsMap.values.toList();
    }
  }

  Future<void> _saveKeysLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _keys.map((k) => jsonEncode(k.toJson())).toList();
    await prefs.setStringList('access_keys', jsonList);
  }

  Future<void> _saveMessagesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _messages.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList('chat_messages', jsonList);
  }

  Future<void> _saveConnectionRequestsLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _connectionRequests.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList('connection_requests', jsonList);
  }

  Future<void> _saveUserSession(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user.toJson()));
  }

  @override
  void dispose() {
    _keysSub?.cancel();
    _messagesSub?.cancel();
    _requestsSub?.cancel();
    _adminSub?.cancel();
    super.dispose();
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
