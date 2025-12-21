import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/services/config_storage_service.dart';

void main() {
  group('ConfigStorageService', () {
    late ConfigStorageService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = ConfigStorageService();
    });

    test('saveConfig saves config to SharedPreferences', () async {
      const config = AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: 'abc123',
      );

      await service.saveConfig(config);

      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('app_config');
      expect(savedJson, isNotNull);
      expect(savedJson, contains('https://api.example.com'));
      expect(savedJson, contains('abc123'));
    });

    test('loadConfig returns saved config', () async {
      const config = AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: 'abc123',
      );

      await service.saveConfig(config);
      final loadedConfig = await service.loadConfig();

      expect(loadedConfig.apiUrl, 'https://api.example.com');
      expect(loadedConfig.accountId, 'abc123');
    });

    test('loadConfig returns default config when no data is saved', () async {
      final config = await service.loadConfig();

      expect(config.apiUrl, '');
      expect(config.accountId, '');
    });

    test('loadConfig returns default config when saved data is empty string',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_config', '');

      final config = await service.loadConfig();

      expect(config.apiUrl, '');
      expect(config.accountId, '');
    });

    test('saveConfig and loadConfig handle empty values', () async {
      const config = AppConfig(
        apiUrl: '',
        accountId: '',
      );

      await service.saveConfig(config);
      final loadedConfig = await service.loadConfig();

      expect(loadedConfig.apiUrl, '');
      expect(loadedConfig.accountId, '');
    });

    test('saveConfig overwrites previous config', () async {
      const firstConfig = AppConfig(
        apiUrl: 'https://api1.example.com',
        accountId: 'user1',
      );
      const secondConfig = AppConfig(
        apiUrl: 'https://api2.example.com',
        accountId: 'user2',
      );

      await service.saveConfig(firstConfig);
      await service.saveConfig(secondConfig);
      final loadedConfig = await service.loadConfig();

      expect(loadedConfig.apiUrl, 'https://api2.example.com');
      expect(loadedConfig.accountId, 'user2');
    });
  });
}
