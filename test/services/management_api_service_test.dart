import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ueberboese_app/services/management_api_service.dart';

@GenerateMocks([http.Client])
import 'management_api_service_test.mocks.dart';

void main() {
  late ManagementApiService service;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    service = ManagementApiService(httpClient: mockClient);
  });

  group('ManagementApiService', () {
    const apiUrl = 'https://api.example.com';
    const accountId = '6921042';
    const username = 'admin';
    const password = 'secret123';

    test(
      'fetchAccountSpeakers returns list of IP addresses on success',
      () async {
        final responseBody = json.encode({
          'speakers': [
            {'ipAddress': '192.168.1.100'},
            {'ipAddress': '192.168.1.101'},
          ],
        });

        when(
          mockClient.get(
            Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        final result = await service.fetchAccountSpeakers(
          apiUrl,
          accountId,
          username,
          password,
        );

        expect(result, ['192.168.1.100', '192.168.1.101']);
      },
    );

    test('fetchAccountSpeakers handles trailing slash in API URL', () async {
      final responseBody = json.encode({
        'speakers': [
          {'ipAddress': '192.168.1.100'},
        ],
      });

      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await service.fetchAccountSpeakers(
        '$apiUrl/',
        accountId,
        username,
        password,
      );

      expect(result, ['192.168.1.100']);
    });

    test('fetchAccountSpeakers sends correct Basic Auth header', () async {
      final responseBody = json.encode({'speakers': <String>[]});

      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response(responseBody, 200));

      await service.fetchAccountSpeakers(apiUrl, accountId, username, password);

      verify(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
          headers: argThat(contains('Authorization'), named: 'headers'),
        ),
      );
    });

    test('fetchAccountSpeakers returns empty list when no speakers', () async {
      final responseBody = json.encode({'speakers': <String>[]});

      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await service.fetchAccountSpeakers(
        apiUrl,
        accountId,
        username,
        password,
      );

      expect(result, isEmpty);
    });

    test('fetchAccountSpeakers throws exception on 401 Unauthorized', () async {
      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('Unauthorized', 401));

      expect(
        () =>
            service.fetchAccountSpeakers(apiUrl, accountId, username, password),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid management credentials'),
          ),
        ),
      );
    });

    test('fetchAccountSpeakers throws exception on 403 Forbidden', () async {
      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('Forbidden', 403));

      expect(
        () =>
            service.fetchAccountSpeakers(apiUrl, accountId, username, password),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid management credentials'),
          ),
        ),
      );
    });

    test('fetchAccountSpeakers throws exception on 404 Not Found', () async {
      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('Not Found', 404));

      expect(
        () =>
            service.fetchAccountSpeakers(apiUrl, accountId, username, password),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Account not found'),
          ),
        ),
      );
    });

    test(
      'fetchAccountSpeakers throws exception on other HTTP errors',
      () async {
        when(
          mockClient.get(
            Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response('Server Error', 500));

        expect(
          () => service.fetchAccountSpeakers(
            apiUrl,
            accountId,
            username,
            password,
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('HTTP 500'),
            ),
          ),
        );
      },
    );

    test('fetchAccountSpeakers throws exception on invalid JSON', () async {
      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('not valid json', 200));

      expect(
        () =>
            service.fetchAccountSpeakers(apiUrl, accountId, username, password),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid JSON response'),
          ),
        ),
      );
    });

    test(
      'fetchAccountSpeakers throws exception when speakers field is missing',
      () async {
        final responseBody = json.encode({'data': <String>[]});

        when(
          mockClient.get(
            Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        expect(
          () => service.fetchAccountSpeakers(
            apiUrl,
            accountId,
            username,
            password,
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('missing speakers field'),
            ),
          ),
        );
      },
    );

    test('fetchAccountSpeakers handles network errors', () async {
      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
          headers: anyNamed('headers'),
        ),
      ).thenThrow(Exception('Network error'));

      expect(
        () =>
            service.fetchAccountSpeakers(apiUrl, accountId, username, password),
        throwsException,
      );
    });

    test(
      'fetchAccountSpeakers filters out speakers without IP addresses',
      () async {
        final responseBody = json.encode({
          'speakers': [
            {'ipAddress': '192.168.1.100'},
            {'name': 'Speaker without IP'},
            {'ipAddress': ''},
            {'ipAddress': '192.168.1.101'},
          ],
        });

        when(
          mockClient.get(
            Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        final result = await service.fetchAccountSpeakers(
          apiUrl,
          accountId,
          username,
          password,
        );

        expect(result, ['192.168.1.100', '192.168.1.101']);
      },
    );
  });

  group('fetchDeviceEvents', () {
    const apiUrl = 'https://api.example.com';
    const deviceId = 'device-123';
    const username = 'admin';
    const password = 'secret123';

    test('returns list of device events on success', () async {
      final responseBody = json.encode({
        'events': [
          {
            'data': {'volume': 50},
            'monoTime': 12345,
            'time': '2024-01-15T10:30:00Z',
            'type': 'volume-changed',
          },
          {
            'data': {'playState': 'PLAY_STATE'},
            'monoTime': 12346,
            'time': '2024-01-15T10:31:00Z',
            'type': 'play-state-changed',
          },
        ],
      });

      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/devices/$deviceId/events'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await service.fetchDeviceEvents(
        apiUrl,
        deviceId,
        username,
        password,
      );

      expect(result, hasLength(2));
      expect(result[0].type, 'volume-changed');
      expect(result[0].data['volume'], 50);
      expect(result[1].type, 'play-state-changed');
    });

    test('handles trailing slash in API URL', () async {
      final responseBody = json.encode({
        'events': [
          {
            'data': {'volume': 50},
            'monoTime': 12345,
            'time': '2024-01-15T10:30:00Z',
            'type': 'volume-changed',
          },
        ],
      });

      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/devices/$deviceId/events'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await service.fetchDeviceEvents(
        '$apiUrl/',
        deviceId,
        username,
        password,
      );

      expect(result, hasLength(1));
      expect(result[0].type, 'volume-changed');
    });

    test('sends correct Basic Auth header', () async {
      final responseBody = json.encode({'events': <Map<String, dynamic>>[]});

      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/devices/$deviceId/events'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response(responseBody, 200));

      await service.fetchDeviceEvents(apiUrl, deviceId, username, password);

      verify(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/devices/$deviceId/events'),
          headers: argThat(contains('Authorization'), named: 'headers'),
        ),
      );
    });

    test('returns empty list when no events', () async {
      final responseBody = json.encode({'events': <Map<String, dynamic>>[]});

      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/devices/$deviceId/events'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await service.fetchDeviceEvents(
        apiUrl,
        deviceId,
        username,
        password,
      );

      expect(result, isEmpty);
    });

    test('throws exception on 401 Unauthorized', () async {
      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/devices/$deviceId/events'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('Unauthorized', 401));

      expect(
        () => service.fetchDeviceEvents(apiUrl, deviceId, username, password),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid management credentials'),
          ),
        ),
      );
    });

    test('throws exception on 403 Forbidden', () async {
      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/devices/$deviceId/events'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('Forbidden', 403));

      expect(
        () => service.fetchDeviceEvents(apiUrl, deviceId, username, password),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid management credentials'),
          ),
        ),
      );
    });

    test('throws exception on 404 Not Found', () async {
      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/devices/$deviceId/events'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('Not Found', 404));

      expect(
        () => service.fetchDeviceEvents(apiUrl, deviceId, username, password),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Device not found'),
          ),
        ),
      );
    });

    test('throws exception on other HTTP errors', () async {
      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/devices/$deviceId/events'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      expect(
        () => service.fetchDeviceEvents(apiUrl, deviceId, username, password),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('HTTP 500'),
          ),
        ),
      );
    });

    test('throws exception on invalid JSON', () async {
      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/devices/$deviceId/events'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response('not valid json', 200));

      expect(
        () => service.fetchDeviceEvents(apiUrl, deviceId, username, password),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid JSON response'),
          ),
        ),
      );
    });

    test('throws exception when events field is missing', () async {
      final responseBody = json.encode({'data': <Map<String, dynamic>>[]});

      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/devices/$deviceId/events'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response(responseBody, 200));

      expect(
        () => service.fetchDeviceEvents(apiUrl, deviceId, username, password),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('missing events field'),
          ),
        ),
      );
    });

    test('handles network errors', () async {
      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/devices/$deviceId/events'),
          headers: anyNamed('headers'),
        ),
      ).thenThrow(Exception('Network error'));

      expect(
        () => service.fetchDeviceEvents(apiUrl, deviceId, username, password),
        throwsException,
      );
    });

    test('skips invalid events and continues processing', () async {
      final responseBody = json.encode({
        'events': [
          {
            'data': {'volume': 50},
            'monoTime': 12345,
            'time': '2024-01-15T10:30:00Z',
            'type': 'volume-changed',
          },
          {
            'data': {'invalid': 'event'},
            // Missing required fields
          },
          {
            'data': {'playState': 'PLAY_STATE'},
            'monoTime': 12346,
            'time': '2024-01-15T10:31:00Z',
            'type': 'play-state-changed',
          },
        ],
      });

      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/devices/$deviceId/events'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await service.fetchDeviceEvents(
        apiUrl,
        deviceId,
        username,
        password,
      );

      // Should return 2 valid events, skipping the invalid one
      expect(result, hasLength(2));
      expect(result[0].type, 'volume-changed');
      expect(result[1].type, 'play-state-changed');
    });

    test('parses ISO 8601 timestamp correctly', () async {
      final responseBody = json.encode({
        'events': [
          {
            'data': {'volume': 50},
            'monoTime': 12345,
            'time': '2024-01-15T10:30:00Z',
            'type': 'volume-changed',
          },
        ],
      });

      when(
        mockClient.get(
          Uri.parse('$apiUrl/mgmt/devices/$deviceId/events'),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await service.fetchDeviceEvents(
        apiUrl,
        deviceId,
        username,
        password,
      );

      expect(result[0].time, isA<DateTime>());
      expect(result[0].time.year, 2024);
      expect(result[0].time.month, 1);
      expect(result[0].time.day, 15);
    });
  });
}
