class Profile {
  final String id;
  final String username;
  final String? avatarUrl;
  final double mannerTemp;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.mannerTemp = 36.5,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      mannerTemp: (json['manner_temp'] as num?)?.toDouble() ?? 36.5,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'manner_temp': mannerTemp,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? username,
    String? avatarUrl,
    double? mannerTemp,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      mannerTemp: mannerTemp ?? this.mannerTemp,
      createdAt: createdAt,
    );
  }
}
