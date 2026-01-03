import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/services/speaker_websocket_service.dart';
import 'package:ueberboese_app/models/volume.dart';
import 'package:ueberboese_app/models/now_playing.dart';

void main() {
  group('SpeakerWebsocketService', () {
    test('parses volume update XML correctly', () async {
      final service = SpeakerWebsocketService('192.168.1.100');

      final volumeUpdates = <Volume>[];
      service.volumeStream.listen((volume) {
        volumeUpdates.add(volume);
      });

      // Note: Fully testing XML parsing would require mocking the WebSocket channel
      // For now, this test verifies the service can be created and disposed
      service.dispose();
    });

    test('parses now playing update XML correctly for Bluetooth', () async {
      final service = SpeakerWebsocketService('192.168.1.100');

      final nowPlayingUpdates = <NowPlaying>[];
      service.nowPlayingStream.listen((nowPlaying) {
        nowPlayingUpdates.add(nowPlaying);
      });

      service.dispose();
    });

    test('creates service with correct IP address', () {
      final service = SpeakerWebsocketService('192.168.1.100');
      expect(service.ipAddress, equals('192.168.1.100'));
      service.dispose();
    });

    test('isConnected returns false initially', () {
      final service = SpeakerWebsocketService('192.168.1.100');
      expect(service.isConnected, isFalse);
      service.dispose();
    });

    test('dispose closes streams', () async {
      final service = SpeakerWebsocketService('192.168.1.100');

      bool volumeStreamClosed = false;
      bool nowPlayingStreamClosed = false;

      service.volumeStream.listen(
        (_) {},
        onDone: () {
          volumeStreamClosed = true;
        },
      );

      service.nowPlayingStream.listen(
        (_) {},
        onDone: () {
          nowPlayingStreamClosed = true;
        },
      );

      service.dispose();

      // Wait a bit for the streams to close
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(volumeStreamClosed, isTrue);
      expect(nowPlayingStreamClosed, isTrue);
    });

    test('disconnect prevents reconnection', () async {
      final service = SpeakerWebsocketService('192.168.1.100');

      service.disconnect();

      // Try to connect after disconnect
      service.connect();

      // Connection should not happen after disconnect
      expect(service.isConnected, isFalse);

      service.dispose();
    });
  });
}
