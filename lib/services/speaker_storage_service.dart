import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/speaker.dart';

class SpeakerStorageService {
  static const String _speakersKey = 'speakers';

  Future<void> saveSpeakers(List<Speaker> speakers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final speakersJson = speakers.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(speakersJson);
      await prefs.setString(_speakersKey, jsonString);
    } catch (e) {
      // Log error but don't crash the app
      print('Error saving speakers: $e');
    }
  }

  Future<List<Speaker>> loadSpeakers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_speakersKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Speaker.fromJson(json)).toList();
    } catch (e) {
      // Log error and return empty list if data is corrupted
      print('Error loading speakers: $e');
      return [];
    }
  }
}
