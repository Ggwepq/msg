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
        timestamp: _parseDate(json['timestamp']),
        status: json['status'] as String? ?? 'pending',
      );

  static DateTime _parseDate(dynamic val) {
    if (val is String) return DateTime.parse(val);
    if (val is DateTime) return val;
    if (val != null && val.runtimeType.toString() == 'Timestamp') {
      return (val as dynamic).toDate() as DateTime;
    }
    return DateTime.now();
  }
}

