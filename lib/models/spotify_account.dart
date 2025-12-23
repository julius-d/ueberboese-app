class SpotifyAccount {
  final String displayName;
  final DateTime createdAt;

  const SpotifyAccount({
    required this.displayName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SpotifyAccount.fromJson(Map<String, dynamic> json) => SpotifyAccount(
        displayName: json['displayName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpotifyAccount &&
          runtimeType == other.runtimeType &&
          displayName == other.displayName &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(displayName, createdAt);
}
