import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/services/speaker_discovery_service.dart';

void main() {
  group('SpeakerDiscoveryService.parseResponse', () {
    test('returns null for non-200 response', () {
      const response = 'HTTP/1.1 404 Not Found\r\n\r\n';
      expect(
        SpeakerDiscoveryService.parseResponse(response, '192.168.1.1'),
        isNull,
      );
    });

    test('returns null when LOCATION header is missing', () {
      const response =
          'HTTP/1.1 200 OK\r\nST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n\r\n';
      expect(
        SpeakerDiscoveryService.parseResponse(response, '192.168.1.1'),
        isNull,
      );
    });

    test('returns null for empty response', () {
      expect(SpeakerDiscoveryService.parseResponse('', '192.168.1.1'), isNull);
    });

    test('parses valid 200 OK response with LOCATION header', () {
      const response =
          'HTTP/1.1 200 OK\r\n'
          'CACHE-CONTROL: max-age=1800\r\n'
          'LOCATION: http://192.168.1.42:8090/info\r\n'
          'ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n'
          '\r\n';
      final result = SpeakerDiscoveryService.parseResponse(
        response,
        '192.168.1.42',
      );
      expect(result, isNotNull);
      expect(result!.ip, '192.168.1.42');
      expect(result.location, 'http://192.168.1.42:8090/info');
    });

    test('is case-insensitive for LOCATION header', () {
      const response =
          'HTTP/1.1 200 OK\r\n'
          'Location: http://192.168.1.55:8090/info\r\n'
          '\r\n';
      final result = SpeakerDiscoveryService.parseResponse(
        response,
        '192.168.1.55',
      );
      expect(result, isNotNull);
      expect(result!.location, 'http://192.168.1.55:8090/info');
    });

    test('trims whitespace from location value', () {
      const response =
          'HTTP/1.1 200 OK\r\n'
          'location:  http://192.168.1.10:8090/info  \r\n'
          '\r\n';
      final result = SpeakerDiscoveryService.parseResponse(
        response,
        '192.168.1.10',
      );
      expect(result!.location, 'http://192.168.1.10:8090/info');
    });
  });

  group('SpeakerDiscoveryService.discover', () {
    const okResponse =
        'HTTP/1.1 200 OK\r\n'
        'LOCATION: http://127.0.0.1:8090/info\r\n'
        '\r\n';

    late RawDatagramSocket responder;
    late int requests;

    Future<void> startResponder(List<String> replies) async {
      requests = 0;
      responder = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      responder.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = responder.receive();
        if (datagram == null) return;
        requests++;
        for (final reply in replies) {
          responder.send(utf8.encode(reply), datagram.address, datagram.port);
        }
      });
    }

    tearDown(() => responder.close());

    test(
      'sends M-SEARCH and emits parsed speaker, deduplicated by IP',
      () async {
        await startResponder([okResponse, okResponse]);

        final speakers = await SpeakerDiscoveryService()
            .discover(
              timeout: const Duration(milliseconds: 500),
              target: InternetAddress.loopbackIPv4,
              targetPort: responder.port,
            )
            .toList();

        expect(requests, 1);
        expect(speakers, hasLength(1));
        expect(speakers.single.ip, '127.0.0.1');
        expect(speakers.single.location, 'http://127.0.0.1:8090/info');
      },
    );

    test('ignores responses that are not valid speakers', () async {
      await startResponder(['HTTP/1.1 404 Not Found\r\n\r\n']);

      final speakers = await SpeakerDiscoveryService()
          .discover(
            timeout: const Duration(milliseconds: 300),
            target: InternetAddress.loopbackIPv4,
            targetPort: responder.port,
          )
          .toList();

      expect(speakers, isEmpty);
    });

    test('completes after timeout when nobody answers', () async {
      await startResponder([]);

      final speakers = await SpeakerDiscoveryService()
          .discover(
            timeout: const Duration(milliseconds: 200),
            target: InternetAddress.loopbackIPv4,
            targetPort: responder.port,
          )
          .toList();

      expect(speakers, isEmpty);
    });

    test('stops when the listener cancels', () async {
      await startResponder([okResponse]);

      final first = await SpeakerDiscoveryService()
          .discover(
            timeout: const Duration(seconds: 30),
            target: InternetAddress.loopbackIPv4,
            targetPort: responder.port,
          )
          .first;

      expect(first.ip, '127.0.0.1');
    });
  });
}
