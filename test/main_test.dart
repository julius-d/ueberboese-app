import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/speaker.dart';

void main() {
  group('MyAppState', () {
    test('addSpeaker adds speaker to list', () {
      final appState = MyAppState();
      final initialCount = appState.speakers.length;

      const newSpeaker = Speaker(
        id: 'test-1',
        name: 'Test Speaker',
        emoji: '🎵',
        ipAddress: '192.168.1.200',
      );

      appState.addSpeaker(newSpeaker);

      expect(appState.speakers.length, initialCount + 1);
      expect(appState.speakers.last, newSpeaker);
    });

    test('addSpeaker notifies listeners', () {
      final appState = MyAppState();
      var notified = false;

      appState.addListener(() {
        notified = true;
      });

      const newSpeaker = Speaker(
        id: 'test-1',
        name: 'Test Speaker',
        emoji: '🎵',
        ipAddress: '192.168.1.200',
      );

      appState.addSpeaker(newSpeaker);

      expect(notified, true);
    });
  });
}
