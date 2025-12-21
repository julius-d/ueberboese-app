class AppConfig {
  final String apiUrl;
  final String accountId;

  const AppConfig({
    this.apiUrl = '',
    this.accountId = '',
  });

  Map<String, dynamic> toJson() => {
        'apiUrl': apiUrl,
        'accountId': accountId,
      };

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        apiUrl: json['apiUrl'] as String? ?? '',
        accountId: json['accountId'] as String? ?? '',
      );
}
