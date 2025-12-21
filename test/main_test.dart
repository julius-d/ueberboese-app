import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/speaker.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MyAppState', () {
    test('addSpeaker adds speaker to list', () async {
      final appState = MyAppState();
      await appState.initializeSpeakers();
      final initialCount = appState.speakers.length;

      const newSpeaker = Speaker(
        id: 'test-1',
        name: 'Test Speaker',
        emoji: '🎵',
        ipAddress: '192.168.1.200',
        type: 'SoundTouch 10',
      );

      appState.addSpeaker(newSpeaker);

      expect(appState.speakers.length, initialCount + 1);
      expect(appState.speakers.last, newSpeaker);
    });

    test('addSpeaker notifies listeners', () async {
      final appState = MyAppState();
      await appState.initializeSpeakers();
      var notified = false;

      appState.addListener(() {
        notified = true;
      });

      const newSpeaker = Speaker(
        id: 'test-1',
        name: 'Test Speaker',
        emoji: '🎵',
        ipAddress: '192.168.1.200',
        type: 'SoundTouch 10',
      );

      appState.addSpeaker(newSpeaker);

      expect(notified, true);
    });
  });
}
