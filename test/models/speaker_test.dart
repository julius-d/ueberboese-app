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
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      );

      expect(speaker.id, '1');
      expect(speaker.name, 'Test Speaker');
      expect(speaker.emoji, '🔊');
      expect(speaker.ipAddress, '192.168.1.100');
      expect(speaker.type, 'SoundTouch 10');
      expect(speaker.deviceId, 'device-123');
    });

    test('equality is based on id', () {
      const speaker1 = Speaker(
        id: '1',
        name: 'Speaker 1',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      );

      const speaker2 = Speaker(
        id: '1',
        name: 'Different Name',
        emoji: '🎵',
        ipAddress: '192.168.1.200',
        type: 'SoundTouch 20',
        deviceId: 'device-456',
      );

      const speaker3 = Speaker(
        id: '2',
        name: 'Speaker 1',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
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
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      );

      const speaker2 = Speaker(
        id: '1',
        name: 'Different Name',
        emoji: '🎵',
        ipAddress: '192.168.1.200',
        type: 'SoundTouch 20',
        deviceId: 'device-456',
      );

      expect(speaker1.hashCode, equals(speaker2.hashCode));
    });

    test('toJson serializes speaker correctly', () {
      const speaker = Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      );

      final json = speaker.toJson();

      expect(json['id'], '1');
      expect(json['name'], 'Test Speaker');
      expect(json['emoji'], '🔊');
      expect(json['ipAddress'], '192.168.1.100');
      expect(json['type'], 'SoundTouch 10');
      expect(json['deviceId'], 'device-123');
    });

    test('fromJson deserializes speaker correctly', () {
      final json = {
        'id': '1',
        'name': 'Test Speaker',
        'emoji': '🔊',
        'ipAddress': '192.168.1.100',
        'type': 'SoundTouch 10',
        'deviceId': 'device-123',
      };

      final speaker = Speaker.fromJson(json);

      expect(speaker.id, '1');
      expect(speaker.name, 'Test Speaker');
      expect(speaker.emoji, '🔊');
      expect(speaker.ipAddress, '192.168.1.100');
      expect(speaker.type, 'SoundTouch 10');
      expect(speaker.deviceId, 'device-123');
    });

    test('roundtrip serialization preserves data', () {
      const original = Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      );

      final json = original.toJson();
      final deserialized = Speaker.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.name, original.name);
      expect(deserialized.emoji, original.emoji);
      expect(deserialized.ipAddress, original.ipAddress);
      expect(deserialized.type, original.type);
      expect(deserialized.deviceId, original.deviceId);
    });
  });
}
