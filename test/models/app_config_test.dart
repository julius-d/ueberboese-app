import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/models/app_config.dart';

void main() {
  group('AppConfig', () {
    test('creates config with default values', () {
      const config = AppConfig();
      expect(config.apiUrl, '');
      expect(config.accountId, '');
      expect(config.mgmtUsername, 'admin');
      expect(config.mgmtPassword, 'change_me!');
    });

    test('creates config with provided values', () {
      const config = AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: 'abc123',
        mgmtUsername: 'testadmin',
        mgmtPassword: 'testpass',
      );
      expect(config.apiUrl, 'https://api.example.com');
      expect(config.accountId, 'abc123');
      expect(config.mgmtUsername, 'testadmin');
      expect(config.mgmtPassword, 'testpass');
    });

    test('toJson converts config to JSON', () {
      const config = AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: 'abc123',
        mgmtUsername: 'testadmin',
        mgmtPassword: 'testpass',
      );
      final json = config.toJson();
      expect(json['apiUrl'], 'https://api.example.com');
      expect(json['accountId'], 'abc123');
      expect(json['mgmtUsername'], 'testadmin');
      expect(json['mgmtPassword'], 'testpass');
    });

    test('fromJson creates config from JSON', () {
      final json = {
        'apiUrl': 'https://api.example.com',
        'accountId': 'abc123',
        'mgmtUsername': 'testadmin',
        'mgmtPassword': 'testpass',
      };
      final config = AppConfig.fromJson(json);
      expect(config.apiUrl, 'https://api.example.com');
      expect(config.accountId, 'abc123');
      expect(config.mgmtUsername, 'testadmin');
      expect(config.mgmtPassword, 'testpass');
    });

    test('fromJson handles missing apiUrl with default value', () {
      final json = {
        'accountId': 'abc123',
      };
      final config = AppConfig.fromJson(json);
      expect(config.apiUrl, '');
      expect(config.accountId, 'abc123');
      expect(config.mgmtUsername, 'admin');
      expect(config.mgmtPassword, 'change_me!');
    });

    test('fromJson handles missing accountId with default value', () {
      final json = {
        'apiUrl': 'https://api.example.com',
      };
      final config = AppConfig.fromJson(json);
      expect(config.apiUrl, 'https://api.example.com');
      expect(config.accountId, '');
      expect(config.mgmtUsername, 'admin');
      expect(config.mgmtPassword, 'change_me!');
    });

    test('fromJson handles empty JSON with default values', () {
      final json = <String, dynamic>{};
      final config = AppConfig.fromJson(json);
      expect(config.apiUrl, '');
      expect(config.accountId, '');
      expect(config.mgmtUsername, 'admin');
      expect(config.mgmtPassword, 'change_me!');
    });

    test('fromJson handles missing mgmt credentials with default values', () {
      final json = {
        'apiUrl': 'https://api.example.com',
        'accountId': 'abc123',
      };
      final config = AppConfig.fromJson(json);
      expect(config.apiUrl, 'https://api.example.com');
      expect(config.accountId, 'abc123');
      expect(config.mgmtUsername, 'admin');
      expect(config.mgmtPassword, 'change_me!');
    });

    test('roundtrip toJson and fromJson preserves values', () {
      const originalConfig = AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: 'abc123',
        mgmtUsername: 'testadmin',
        mgmtPassword: 'testpass',
      );
      final json = originalConfig.toJson();
      final restoredConfig = AppConfig.fromJson(json);
      expect(restoredConfig.apiUrl, originalConfig.apiUrl);
      expect(restoredConfig.accountId, originalConfig.accountId);
      expect(restoredConfig.mgmtUsername, originalConfig.mgmtUsername);
      expect(restoredConfig.mgmtPassword, originalConfig.mgmtPassword);
    });
  });
}
