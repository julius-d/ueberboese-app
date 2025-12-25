class AppConfig {
  final String apiUrl;
  final String accountId;
  final String mgmtUsername;
  final String mgmtPassword;

  const AppConfig({
    this.apiUrl = '',
    this.accountId = '',
    this.mgmtUsername = 'admin',
    this.mgmtPassword = 'change_me!',
  });

  Map<String, dynamic> toJson() => {
        'apiUrl': apiUrl,
        'accountId': accountId,
        'mgmtUsername': mgmtUsername,
        'mgmtPassword': mgmtPassword,
      };

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        apiUrl: json['apiUrl'] as String? ?? '',
        accountId: json['accountId'] as String? ?? '',
        mgmtUsername: json['mgmtUsername'] as String? ?? 'admin',
        mgmtPassword: json['mgmtPassword'] as String? ?? 'change_me!',
      );
}
