import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/models/speaker.dart';

void main() {
  group('Speaker', () {
    test('creates speaker with all required fields', () {
      const speaker = Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
      );

      expect(speaker.id, '1');
      expect(speaker.name, 'Test Speaker');
      expect(speaker.emoji, '🔊');
      expect(speaker.ipAddress, '192.168.1.100');
    });

    test('equality is based on id', () {
      const speaker1 = Speaker(
        id: '1',
        name: 'Speaker 1',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
      );

      const speaker2 = Speaker(
        id: '1',
        name: 'Different Name',
        emoji: '🎵',
        ipAddress: '192.168.1.200',
      );

      const speaker3 = Speaker(
        id: '2',
        name: 'Speaker 1',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
      );

      expect(speaker1, equals(speaker2));
      expect(speaker1, isNot(equals(speaker3)));
    });

    test('hashCode is based on id', () {
      const speaker1 = Speaker(
        id: '1',
        name: 'Speaker 1',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
      );

      const speaker2 = Speaker(
        id: '1',
        name: 'Different Name',
        emoji: '🎵',
        ipAddress: '192.168.1.200',
      );

      expect(speaker1.hashCode, equals(speaker2.hashCode));
    });
  });
}
