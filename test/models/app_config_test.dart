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
      expect(config.showAlbumArtInList, true);
    });

    test('creates config with provided values', () {
      const config = AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: 'abc123',
        mgmtUsername: 'testadmin',
        mgmtPassword: 'testpass',
        showAlbumArtInList: false,
      );
      expect(config.apiUrl, 'https://api.example.com');
      expect(config.accountId, 'abc123');
      expect(config.mgmtUsername, 'testadmin');
      expect(config.mgmtPassword, 'testpass');
      expect(config.showAlbumArtInList, false);
    });

    test('toJson converts config to JSON', () {
      const config = AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: 'abc123',
        mgmtUsername: 'testadmin',
        mgmtPassword: 'testpass',
        showAlbumArtInList: false,
      );
      final json = config.toJson();
      expect(json['apiUrl'], 'https://api.example.com');
      expect(json['accountId'], 'abc123');
      expect(json['mgmtUsername'], 'testadmin');
      expect(json['mgmtPassword'], 'testpass');
      expect(json['showAlbumArtInList'], false);
    });

    test('fromJson creates config from JSON', () {
      final json = {
        'apiUrl': 'https://api.example.com',
        'accountId': 'abc123',
        'mgmtUsername': 'testadmin',
        'mgmtPassword': 'testpass',
        'showAlbumArtInList': false,
      };
      final config = AppConfig.fromJson(json);
      expect(config.apiUrl, 'https://api.example.com');
      expect(config.accountId, 'abc123');
      expect(config.mgmtUsername, 'testadmin');
      expect(config.mgmtPassword, 'testpass');
      expect(config.showAlbumArtInList, false);
    });

    test('fromJson defaults showAlbumArtInList to true when missing', () {
      final json = {
        'apiUrl': 'https://api.example.com',
        'accountId': 'abc123',
        'mgmtUsername': 'admin',
        'mgmtPassword': 'change_me!',
      };
      final config = AppConfig.fromJson(json);
      expect(config.showAlbumArtInList, true);
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
      expect(config.showAlbumArtInList, true);
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

    test('roundtrip toJson and fromJson preserves all values', () {
      const originalConfig = AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: 'abc123',
        mgmtUsername: 'testadmin',
        mgmtPassword: 'testpass',
        showAlbumArtInList: false,
      );
      final json = originalConfig.toJson();
      final restoredConfig = AppConfig.fromJson(json);
      expect(restoredConfig.apiUrl, originalConfig.apiUrl);
      expect(restoredConfig.accountId, originalConfig.accountId);
      expect(restoredConfig.mgmtUsername, originalConfig.mgmtUsername);
      expect(restoredConfig.mgmtPassword, originalConfig.mgmtPassword);
      expect(restoredConfig.showAlbumArtInList, originalConfig.showAlbumArtInList);
    });

    group('copyWith', () {
      test('returns same values when no overrides given', () {
        const config = AppConfig(
          apiUrl: 'https://api.example.com',
          accountId: 'abc123',
          mgmtUsername: 'admin',
          mgmtPassword: 'pass',
          showAlbumArtInList: false,
        );
        final copy = config.copyWith();
        expect(copy, equals(config));
      });

      test('overrides showAlbumArtInList', () {
        const config = AppConfig(showAlbumArtInList: true);
        final copy = config.copyWith(showAlbumArtInList: false);
        expect(copy.showAlbumArtInList, false);
        expect(copy.apiUrl, config.apiUrl);
        expect(copy.accountId, config.accountId);
      });

      test('overrides apiUrl only', () {
        const config = AppConfig(
          apiUrl: 'https://old.example.com',
          accountId: 'abc',
        );
        final copy = config.copyWith(apiUrl: 'https://new.example.com');
        expect(copy.apiUrl, 'https://new.example.com');
        expect(copy.accountId, 'abc');
      });
    });

    group('equality', () {
      test('equal configs are equal', () {
        const a = AppConfig(
          apiUrl: 'https://api.example.com',
          accountId: 'abc',
          showAlbumArtInList: false,
        );
        const b = AppConfig(
          apiUrl: 'https://api.example.com',
          accountId: 'abc',
          showAlbumArtInList: false,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('configs differing in showAlbumArtInList are not equal', () {
        const a = AppConfig(showAlbumArtInList: true);
        const b = AppConfig(showAlbumArtInList: false);
        expect(a, isNot(equals(b)));
      });
    });
  });
}
