class ConnectionRequest {
  final String id;
  final String senderUserId;
  final String senderNickname;
  final String receiverUserId;
  final String receiverNickname;
  final DateTime timestamp;
  String status; // 'pending', 'accepted', 'declined'

  ConnectionRequest({
    required this.id,
    required this.senderUserId,
    required this.senderNickname,
    required this.receiverUserId,
    required this.receiverNickname,
    required this.timestamp,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderUserId': senderUserId,
        'senderNickname': senderNickname,
        'receiverUserId': receiverUserId,
        'receiverNickname': receiverNickname,
        'timestamp': timestamp.toIso8601String(),
        'status': status,
      };

  factory ConnectionRequest.fromJson(Map<String, dynamic> json) =>
      ConnectionRequest(
        id: json['id'] as String,
        senderUserId: json['senderUserId'] as String,
        senderNickname: json['senderNickname'] as String,
        receiverUserId: json['receiverUserId'] as String,
        receiverNickname: json['receiverNickname'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        status: json['status'] as String? ?? 'pending',
      );
}
