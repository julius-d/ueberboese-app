import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/services/speaker_storage_service.dart';

void main() {
  group('SpeakerStorageService', () {
    late SpeakerStorageService service;

    setUp(() {
      service = SpeakerStorageService();
      SharedPreferences.setMockInitialValues({});
    });

    test('saveSpeakers stores speakers as JSON', () async {
      const speakers = [
        Speaker(
          id: '1',
          name: 'Test Speaker 1',
          emoji: '🔊',
          ipAddress: '192.168.1.100',
          type: 'SoundTouch 10',
          deviceId: 'device-100',
        ),
        Speaker(
          id: '2',
          name: 'Test Speaker 2',
          emoji: '🎵',
          ipAddress: '192.168.1.101',
          type: 'SoundTouch 20',
          deviceId: 'device-101',
        ),
      ];

      await service.saveSpeakers(speakers);

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('speakers');

      expect(jsonString, isNotNull);
      expect(jsonString, contains('"id":"1"'));
      expect(jsonString, contains('"name":"Test Speaker 1"'));
      expect(jsonString, contains('"id":"2"'));
      expect(jsonString, contains('"name":"Test Speaker 2"'));
    });

    test('loadSpeakers returns empty list when no data exists', () async {
      final speakers = await service.loadSpeakers();

      expect(speakers, isEmpty);
    });

    test('loadSpeakers deserializes speakers correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'speakers',
        '[{"id":"1","name":"Test Speaker","emoji":"🔊","ipAddress":"192.168.1.100","type":"SoundTouch 10","deviceId":"device-123"}]',
      );

      final speakers = await service.loadSpeakers();

      expect(speakers, hasLength(1));
      expect(speakers[0].id, '1');
      expect(speakers[0].name, 'Test Speaker');
      expect(speakers[0].emoji, '🔊');
      expect(speakers[0].ipAddress, '192.168.1.100');
      expect(speakers[0].type, 'SoundTouch 10');
      expect(speakers[0].deviceId, 'device-123');
    });


    test('loadSpeakers handles empty string', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('speakers', '');

      final speakers = await service.loadSpeakers();

      expect(speakers, isEmpty);
    });

    test('loadSpeakers returns empty list on corrupted data', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('speakers', 'invalid json');

      final speakers = await service.loadSpeakers();

      expect(speakers, isEmpty);
    });

    test('roundtrip save and load preserves data', () async {
      const originalSpeakers = [
        Speaker(
          id: '1',
          name: 'Test Speaker 1',
          emoji: '🔊',
          ipAddress: '192.168.1.100',
          type: 'SoundTouch 10',
          deviceId: 'device-100',
        ),
        Speaker(
          id: '2',
          name: 'Test Speaker 2',
          emoji: '🎵',
          ipAddress: '192.168.1.101',
          type: 'SoundTouch 20',
          deviceId: 'device-101',
        ),
      ];

      await service.saveSpeakers(originalSpeakers);
      final loadedSpeakers = await service.loadSpeakers();

      expect(loadedSpeakers, hasLength(2));
      expect(loadedSpeakers[0].id, originalSpeakers[0].id);
      expect(loadedSpeakers[0].name, originalSpeakers[0].name);
      expect(loadedSpeakers[0].emoji, originalSpeakers[0].emoji);
      expect(loadedSpeakers[0].ipAddress, originalSpeakers[0].ipAddress);
      expect(loadedSpeakers[0].type, originalSpeakers[0].type);
      expect(loadedSpeakers[1].id, originalSpeakers[1].id);
      expect(loadedSpeakers[1].type, originalSpeakers[1].type);
    });
  });
}
