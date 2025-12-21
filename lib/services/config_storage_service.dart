import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

class ConfigStorageService {
  static const String _configKey = 'app_config';

  Future<void> saveConfig(AppConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(config.toJson());
      await prefs.setString(_configKey, jsonString);
    } catch (e) {
      print('Error saving config: $e');
    }
  }

  Future<AppConfig> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_configKey);

      if (jsonString == null || jsonString.isEmpty) {
        return const AppConfig();
      }

      final Map<String, dynamic> json = jsonDecode(jsonString);
      return AppConfig.fromJson(json);
    } catch (e) {
      print('Error loading config: $e');
      return const AppConfig();
    }
  }
}
