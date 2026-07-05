class AppConfig {
  final String apiUrl;
  final String accountId;
  final String mgmtUsername;
  final String mgmtPassword;
  final bool showAlbumArtInList;

  const AppConfig({
    this.apiUrl = '',
    this.accountId = '',
    this.mgmtUsername = 'admin',
    this.mgmtPassword = 'change_me!',
    this.showAlbumArtInList = true,
  });

  AppConfig copyWith({
    String? apiUrl,
    String? accountId,
    String? mgmtUsername,
    String? mgmtPassword,
    bool? showAlbumArtInList,
  }) =>
      AppConfig(
        apiUrl: apiUrl ?? this.apiUrl,
        accountId: accountId ?? this.accountId,
        mgmtUsername: mgmtUsername ?? this.mgmtUsername,
        mgmtPassword: mgmtPassword ?? this.mgmtPassword,
        showAlbumArtInList: showAlbumArtInList ?? this.showAlbumArtInList,
      );

  Map<String, dynamic> toJson() => {
        'apiUrl': apiUrl,
        'accountId': accountId,
        'mgmtUsername': mgmtUsername,
        'mgmtPassword': mgmtPassword,
        'showAlbumArtInList': showAlbumArtInList,
      };

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        apiUrl: json['apiUrl'] as String? ?? '',
        accountId: json['accountId'] as String? ?? '',
        mgmtUsername: json['mgmtUsername'] as String? ?? 'admin',
        mgmtPassword: json['mgmtPassword'] as String? ?? 'change_me!',
        showAlbumArtInList: json['showAlbumArtInList'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppConfig &&
        other.apiUrl == apiUrl &&
        other.accountId == accountId &&
        other.mgmtUsername == mgmtUsername &&
        other.mgmtPassword == mgmtPassword &&
        other.showAlbumArtInList == showAlbumArtInList;
  }

  @override
  int get hashCode {
    return Object.hash(
      apiUrl,
      accountId,
      mgmtUsername,
      mgmtPassword,
      showAlbumArtInList,
    );
  }
}
