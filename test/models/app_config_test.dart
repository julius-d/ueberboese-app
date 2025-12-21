import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/models/app_config.dart';

void main() {
  group('AppConfig', () {
    test('creates config with default values', () {
      const config = AppConfig();
      expect(config.apiUrl, '');
      expect(config.accountId, '');
    });

    test('creates config with provided values', () {
      const config = AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: 'abc123',
      );
      expect(config.apiUrl, 'https://api.example.com');
      expect(config.accountId, 'abc123');
    });

    test('toJson converts config to JSON', () {
      const config = AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: 'abc123',
      );
      final json = config.toJson();
      expect(json['apiUrl'], 'https://api.example.com');
      expect(json['accountId'], 'abc123');
    });

    test('fromJson creates config from JSON', () {
      final json = {
        'apiUrl': 'https://api.example.com',
        'accountId': 'abc123',
      };
      final config = AppConfig.fromJson(json);
      expect(config.apiUrl, 'https://api.example.com');
      expect(config.accountId, 'abc123');
    });

    test('fromJson handles missing apiUrl with default value', () {
      final json = {
        'accountId': 'abc123',
      };
      final config = AppConfig.fromJson(json);
      expect(config.apiUrl, '');
      expect(config.accountId, 'abc123');
    });

    test('fromJson handles missing accountId with default value', () {
      final json = {
        'apiUrl': 'https://api.example.com',
      };
      final config = AppConfig.fromJson(json);
      expect(config.apiUrl, 'https://api.example.com');
      expect(config.accountId, '');
    });

    test('fromJson handles empty JSON with default values', () {
      final json = <String, dynamic>{};
      final config = AppConfig.fromJson(json);
      expect(config.apiUrl, '');
      expect(config.accountId, '');
    });

    test('roundtrip toJson and fromJson preserves values', () {
      const originalConfig = AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: 'abc123',
      );
      final json = originalConfig.toJson();
      final restoredConfig = AppConfig.fromJson(json);
      expect(restoredConfig.apiUrl, originalConfig.apiUrl);
      expect(restoredConfig.accountId, originalConfig.accountId);
    });
  });
}
