class ChatMessage {
  final String id;
  final String senderId;
  final String senderNickname;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String? replyToText;
  final String? replyToSender;
  bool isDeleted;
  Map<String, String> reactions; // userId -> emoji

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderNickname,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.replyToText,
    this.replyToSender,
    this.isDeleted = false,
    Map<String, String>? reactions,
  }) : reactions = reactions ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderNickname': senderNickname,
        'receiverId': receiverId,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'replyToText': replyToText,
        'replyToSender': replyToSender,
        'isDeleted': isDeleted,
        'reactions': reactions,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        senderNickname: json['senderNickname'] as String,
        receiverId: json['receiverId'] as String,
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isRead: json['isRead'] as bool? ?? false,
        replyToText: json['replyToText'] as String?,
        replyToSender: json['replyToSender'] as String?,
        isDeleted: json['isDeleted'] as bool? ?? false,
        reactions: json['reactions'] != null
            ? Map<String, String>.from(json['reactions'] as Map)
            : {},
      );
}
