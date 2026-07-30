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
        createdAt: DateTime.parse(json['createdAt'] as String),
        isClaimed: json['isClaimed'] as bool? ?? false,
        claimedByUserId: json['claimedByUserId'] as String?,
        claimedByNickname: json['claimedByNickname'] as String?,
        claimedAt: json['claimedAt'] != null
            ? DateTime.parse(json['claimedAt'] as String)
            : null,
      );
}
