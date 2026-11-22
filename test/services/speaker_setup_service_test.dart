import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ueberboese_app/services/speaker_setup_service.dart';
import 'package:ueberboese_app/models/wireless_network.dart';

import 'speaker_setup_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('SpeakerSetupService', () {
    late MockClient mockClient;
    late SpeakerSetupService service;

    setUp(() {
      mockClient = MockClient();
      service = SpeakerSetupService(httpClient: mockClient);
    });

    group('performWirelessSiteSurvey', () {
      test('parses networks correctly', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<PerformWirelessSiteSurveyResponse error="none">
  <items>
    <item ssid="my_ssid" signalStrength="-58" secure="true">
      <securityTypes>
        <type>wpa_or_wpa2</type>
      </securityTypes>
    </item>
    <item ssid="open_network" signalStrength="-75" secure="false">
      <securityTypes>
        <type>none</type>
      </securityTypes>
    </item>
  </items>
</PerformWirelessSiteSurveyResponse>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(
            xmlResponse,
            200,
            headers: {'content-type': 'text/xml; charset=utf-8'},
          ),
        );

        final networks = await service.performWirelessSiteSurvey();

        expect(networks.length, 2);
        expect(networks[0].ssid, 'my_ssid');
        expect(networks[0].signalStrength, -58);
        expect(networks[0].secure, true);
        expect(networks[0].securityType, 'wpa_or_wpa2');
        expect(networks[1].ssid, 'open_network');
        expect(networks[1].secure, false);
        expect(networks[1].securityType, 'none');
      });

      test('drops hidden networks, merges duplicates and sorts by signal',
          () async {
        const xmlResponse = '''<PerformWirelessSiteSurveyResponse error="none">
  <items>
    <item ssid="weak" signalStrength="-80" secure="false"><securityTypes><type>none</type></securityTypes></item>
    <item ssid="" signalStrength="-30" secure="false"><securityTypes><type>none</type></securityTypes></item>
    <item ssid="mesh" signalStrength="-70" secure="true"><securityTypes><type>wpa2aes</type></securityTypes></item>
    <item ssid="mesh" signalStrength="-50" secure="true"><securityTypes><type>wpa2aes</type></securityTypes></item>
  </items>
</PerformWirelessSiteSurveyResponse>''';
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200),
        );

        final networks = await service.performWirelessSiteSurvey();

        expect(networks.map((n) => n.ssid), ['mesh', 'weak']);
        expect(networks.first.signalStrength, -50);
      });

      test('uses the given speaker IP', () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(
              '<PerformWirelessSiteSurveyResponse error="none"><items></items></PerformWirelessSiteSurveyResponse>',
              200),
        );

        await service.performWirelessSiteSurvey(speakerIp: '192.168.1.5');

        final captured = verify(mockClient.get(captureAny)).captured;
        expect(captured.first.toString(),
            'http://192.168.1.5:8090/performWirelessSiteSurvey');
      });

      test('requests the correct URL', () async {
        const xmlResponse =
            '<PerformWirelessSiteSurveyResponse error="none"><items></items></PerformWirelessSiteSurveyResponse>';
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200),
        );

        await service.performWirelessSiteSurvey();

        final captured = verify(mockClient.get(captureAny)).captured;
        expect(
          captured.first.toString(),
          'http://192.0.2.1:8090/performWirelessSiteSurvey',
        );
      });

      test('throws on non-200 status', () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response('error', 500),
        );

        await expectLater(
          service.performWirelessSiteSurvey(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('addWirelessProfile', () {
      test('uses the given speaker IP', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('', 200));

        await service.addWirelessProfile('net', 'pw', 'wpa_or_wpa2',
            speakerIp: '192.168.1.5');

        final captured = verify(mockClient.post(captureAny,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .captured;
        expect(captured.first.toString(),
            'http://192.168.1.5:8090/addWirelessProfile');
      });

      test('sends correct POST request', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('', 200));

        await service.addWirelessProfile(
            'MySSID', 'mypassword', 'wpa_or_wpa2');

        final captured = verify(mockClient.post(
          captureAny,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;

        expect(
          captured[0].toString(),
          'http://192.0.2.1:8090/addWirelessProfile',
        );
        expect(captured[2], contains('ssid="MySSID"'));
        expect(captured[2], contains('password="mypassword"'));
        expect(captured[2], contains('securityType="wpa_or_wpa2"'));
      });

      test('escapes XML special characters in ssid and password', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('', 200));

        await service.addWirelessProfile(
            'My&SSID', 'pass<word>', 'wpa_or_wpa2');

        final captured = verify(mockClient.post(
          captureAny,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;

        expect(captured[2], contains('ssid="My&amp;SSID"'));
        expect(captured[2], contains('password="pass&lt;word&gt;"'));
      });

      test('throws on non-200 status', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('error', 400));

        await expectLater(
          service.addWirelessProfile('net', 'pw', 'wpa_or_wpa2'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('setMargeAccount', () {
      test('sends correct POST request', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('', 200));

        await service.setMargeAccount(
            '192.168.1.50', '12345678', 'test123');

        final captured = verify(mockClient.post(
          captureAny,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;

        expect(
          captured[0].toString(),
          'http://192.168.1.50:8090/setMargeAccount',
        );
        expect(captured[2], contains('<accountId>12345678</accountId>'));
        expect(captured[2],
            contains('<userAuthToken>Bearer test123</userAuthToken>'));
      });

      test('throws on non-200 status', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('error', 401));

        await expectLater(
          service.setMargeAccount('192.168.1.50', 'acc', 'tok'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('leaveSetupMode', () {
      test('sends correct POST request', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('', 200));

        await service.leaveSetupMode();

        final captured = verify(mockClient.post(
          captureAny,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;

        expect(
          captured[0].toString(),
          'http://192.0.2.1:8090/setup',
        );
        expect(captured[2], contains('SETUP_WIFI_LEAVE'));
      });

      test('throws on non-200 status', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('error', 500));

        await expectLater(
          service.leaveSetupMode(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('configureEnvswitch', () {
      /// Builds a mock socket that simulates the speaker's telnet protocol:
      /// sends an initial "->" prompt on connect, then responds "ok\n->" to
      /// each command (so the service can correctly match responses to commands).
      _MockSocket buildEnvswitchSocket(
          StreamController<Uint8List> ctrl, List<String> writtenLines) {
        return _MockSocket(
          stream: ctrl.stream,
          onWriteln: (line) {
            writtenLines.add(line);
            ctrl.add(Uint8List.fromList('ok\n->'.codeUnits));
          },
          onFlush: () => Future<void>.value(),
          onClose: () {
            ctrl.close();
            return Future<void>.value();
          },
        );
      }

      test('uses custom speakerIp when provided', () async {
        final ctrl = StreamController<Uint8List>();
        final mockSocket = buildEnvswitchSocket(ctrl, []);
        // Send initial prompt so the service can drain it.
        ctrl.add(Uint8List.fromList('->'.codeUnits));

        String? connectedHost;

        final svc = SpeakerSetupService(
          httpClient: mockClient,
          envswitchDelay: Duration.zero,
          socketConnect: (host, port, {timeout}) async {
            connectedHost = host;
            return mockSocket;
          },
        );

        await svc.configureEnvswitch('https://api.example.com',
            speakerIp: '10.0.0.42');

        expect(connectedHost, '10.0.0.42');
      });

      test('connects to port 17000 and sends envswitch command', () async {
        final writtenLines = <String>[];
        final ctrl = StreamController<Uint8List>();
        final mockSocket = buildEnvswitchSocket(ctrl, writtenLines);
        // Send initial prompt so the service can drain it.
        ctrl.add(Uint8List.fromList('->'.codeUnits));

        String? connectedHost;
        int? connectedPort;

        final setupServiceWithSocket = SpeakerSetupService(
          httpClient: mockClient,
          envswitchDelay: Duration.zero,
          socketConnect: (host, port, {timeout}) async {
            connectedHost = host;
            connectedPort = port;
            return mockSocket;
          },
        );

        final log = await setupServiceWithSocket
            .configureEnvswitch('https://api.example.com');

        expect(connectedHost, '192.0.2.1');
        expect(connectedPort, 17000);
        expect(writtenLines, contains('envswitch boseurls set https://api.example.com https://api.example.com/updates/soundtouch'));
        expect(writtenLines, contains('sys configuration bmxRegistryUrl https://api.example.com/bmx/registry/v1/services'));
        expect(writtenLines, contains('sys configuration statsServerUrl https://api.example.com'));
        expect(writtenLines, contains('getpdo CurrentSystemConfiguration'));
        expect(writtenLines, contains('sys reboot'));
        expect(writtenLines, isNot(contains('exit')));
        // Log should contain sent lines prefixed with '>' and received with '<'
        expect(log.any((l) => l.startsWith('> envswitch')), isTrue);
        expect(log.any((l) => l.startsWith('> sys reboot')), isTrue);
        expect(log.any((l) => l.startsWith('< ok')), isTrue);
      });
    });
    group('getSystemConfiguration', () {
      test('connects to correct host and port and sends command', () async {
        final responseController = StreamController<Uint8List>();
        final writtenLines = <String>[];

        final mockSocket = _MockSocket(
          stream: responseController.stream,
          onWriteln: (line) {
            writtenLines.add(line);
            // Send the response followed by the prompt so the idle timer fires.
            responseController
                .add(Uint8List.fromList('response\n'.codeUnits));
            responseController.close();
          },
          onFlush: () => Future<void>.value(),
          onClose: () {
            if (!responseController.isClosed) responseController.close();
            return Future<void>.value();
          },
        );

        String? connectedHost;
        int? connectedPort;

        final svc = SpeakerSetupService(
          httpClient: mockClient,
          envswitchDelay: Duration.zero,
          socketConnect: (host, port, {timeout}) async {
            connectedHost = host;
            connectedPort = port;
            return mockSocket;
          },
        );

        await svc.getSystemConfiguration('192.168.1.10');

        expect(connectedHost, '192.168.1.10');
        expect(connectedPort, 17000);
        expect(writtenLines, contains('getpdo CurrentSystemConfiguration'));
      });
    });
  });

  group('parseSystemConfiguration', () {
    test('parses quoted string values', () {
      const input = '''
margeServerUrl {
  text: "https://example.com"
}
statsServerUrl {
  text: "https://stats.example.com"
}
''';
      final result = SpeakerSetupService.parseSystemConfiguration(input);
      expect(result['margeServerUrl'], 'https://example.com');
      expect(result['statsServerUrl'], 'https://stats.example.com');
    });

    test('parses unquoted boolean and number values', () {
      const input = '''
isZeroconfEnabled {
  text: true
}
usePandoraProductionServer {
  text: false
}
''';
      final result = SpeakerSetupService.parseSystemConfiguration(input);
      expect(result['isZeroconfEnabled'], 'true');
      expect(result['usePandoraProductionServer'], 'false');
    });

    test('skips echo lines starting with ->', () {
      const input = '''->getpdo CurrentSystemConfiguration
margeServerUrl {
  text: "https://example.com"
}
''';
      final result = SpeakerSetupService.parseSystemConfiguration(input);
      expect(result.containsKey('->getpdo'), isFalse);
      expect(result['margeServerUrl'], 'https://example.com');
    });

    test('returns empty map for empty input', () {
      final result = SpeakerSetupService.parseSystemConfiguration('');
      expect(result, isEmpty);
    });
  });

  group('WirelessNetwork', () {
    test('equality', () {
      const n1 = WirelessNetwork(
          ssid: 'net', signalStrength: -60, secure: true, securityType: 'wpa_or_wpa2');
      const n2 = WirelessNetwork(
          ssid: 'net', signalStrength: -60, secure: true, securityType: 'wpa_or_wpa2');
      expect(n1, equals(n2));
    });

    test('inequality on different ssid', () {
      const n1 = WirelessNetwork(
          ssid: 'net1', signalStrength: -60, secure: true, securityType: 'wpa_or_wpa2');
      const n2 = WirelessNetwork(
          ssid: 'net2', signalStrength: -60, secure: true, securityType: 'wpa_or_wpa2');
      expect(n1, isNot(equals(n2)));
    });
  });
}

/// Minimal mock Socket for testing configureEnvswitch without dart:io.
class _MockSocket extends Stream<Uint8List> implements Socket {
  final Stream<Uint8List> stream;
  final void Function(String line) onWriteln;
  final Future<void> Function() onFlush;
  final Future<void> Function() onClose;

  _MockSocket({
    required this.stream,
    required this.onWriteln,
    required this.onFlush,
    required this.onClose,
  });

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  void writeln([Object? object = '']) {
    onWriteln(object?.toString() ?? '');
  }

  @override
  void write(Object? object) {}

  @override
  Future<void> flush() => onFlush();

  @override
  Future<void> close() => onClose();

  @override
  void destroy() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
