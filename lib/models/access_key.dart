class AccessKey {
  final String key;
  final DateTime createdAt;
  bool isClaimed;
  String? claimedByUserId;
  String? claimedByNickname;
  DateTime? claimedAt;

  AccessKey({
    required this.key,
    required this.createdAt,
    this.isClaimed = false,
    this.claimedByUserId,
    this.claimedByNickname,
    this.claimedAt,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'createdAt': createdAt.toIso8601String(),
        'isClaimed': isClaimed,
        'claimedByUserId': claimedByUserId,
        'claimedByNickname': claimedByNickname,
        'claimedAt': claimedAt?.toIso8601String(),
      };

  factory AccessKey.fromJson(Map<String, dynamic> json) => AccessKey(
        key: json['key'] as String,
        createdAt: _parseDate(json['createdAt']),
        isClaimed: json['isClaimed'] as bool? ?? false,
        claimedByUserId: json['claimedByUserId'] as String?,
        claimedByNickname: json['claimedByNickname'] as String?,
        claimedAt: json['claimedAt'] != null ? _parseDate(json['claimedAt']) : null,
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

