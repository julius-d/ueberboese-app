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

    test('fetchAccountSpeakers returns list of IP addresses on success', () async {
      final responseBody = json.encode({
        'speakers': [
          {'ipAddress': '192.168.1.100'},
          {'ipAddress': '192.168.1.101'},
        ],
      });

      when(mockClient.get(
        Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
        headers: anyNamed('headers'),
      )).thenAnswer(
        (_) async => http.Response(responseBody, 200),
      );

      final result = await service.fetchAccountSpeakers(
        apiUrl,
        accountId,
        username,
        password,
      );

      expect(result, ['192.168.1.100', '192.168.1.101']);
    });

    test('fetchAccountSpeakers handles trailing slash in API URL', () async {
      final responseBody = json.encode({
        'speakers': [
          {'ipAddress': '192.168.1.100'},
        ],
      });

      when(mockClient.get(
        Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
        headers: anyNamed('headers'),
      )).thenAnswer(
        (_) async => http.Response(responseBody, 200),
      );

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

      when(mockClient.get(
        Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
        headers: anyNamed('headers'),
      )).thenAnswer(
        (_) async => http.Response(responseBody, 200),
      );

      await service.fetchAccountSpeakers(
        apiUrl,
        accountId,
        username,
        password,
      );

      verify(mockClient.get(
        Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
        headers: argThat(
          contains('Authorization'),
          named: 'headers',
        ),
      ));
    });

    test('fetchAccountSpeakers returns empty list when no speakers', () async {
      final responseBody = json.encode({'speakers': <String>[]});

      when(mockClient.get(
        Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
        headers: anyNamed('headers'),
      )).thenAnswer(
        (_) async => http.Response(responseBody, 200),
      );

      final result = await service.fetchAccountSpeakers(
        apiUrl,
        accountId,
        username,
        password,
      );

      expect(result, isEmpty);
    });

    test('fetchAccountSpeakers throws exception on 401 Unauthorized', () async {
      when(mockClient.get(
        Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
        headers: anyNamed('headers'),
      )).thenAnswer(
        (_) async => http.Response('Unauthorized', 401),
      );

      expect(
        () => service.fetchAccountSpeakers(apiUrl, accountId, username, password),
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
      when(mockClient.get(
        Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
        headers: anyNamed('headers'),
      )).thenAnswer(
        (_) async => http.Response('Forbidden', 403),
      );

      expect(
        () => service.fetchAccountSpeakers(apiUrl, accountId, username, password),
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
      when(mockClient.get(
        Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
        headers: anyNamed('headers'),
      )).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      expect(
        () => service.fetchAccountSpeakers(apiUrl, accountId, username, password),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Account not found'),
          ),
        ),
      );
    });

    test('fetchAccountSpeakers throws exception on other HTTP errors', () async {
      when(mockClient.get(
        Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
        headers: anyNamed('headers'),
      )).thenAnswer(
        (_) async => http.Response('Server Error', 500),
      );

      expect(
        () => service.fetchAccountSpeakers(apiUrl, accountId, username, password),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('HTTP 500'),
          ),
        ),
      );
    });

    test('fetchAccountSpeakers throws exception on invalid JSON', () async {
      when(mockClient.get(
        Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
        headers: anyNamed('headers'),
      )).thenAnswer(
        (_) async => http.Response('not valid json', 200),
      );

      expect(
        () => service.fetchAccountSpeakers(apiUrl, accountId, username, password),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid JSON response'),
          ),
        ),
      );
    });

    test('fetchAccountSpeakers throws exception when speakers field is missing', () async {
      final responseBody = json.encode({'data': <String>[]});

      when(mockClient.get(
        Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
        headers: anyNamed('headers'),
      )).thenAnswer(
        (_) async => http.Response(responseBody, 200),
      );

      expect(
        () => service.fetchAccountSpeakers(apiUrl, accountId, username, password),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('missing speakers field'),
          ),
        ),
      );
    });

    test('fetchAccountSpeakers handles network errors', () async {
      when(mockClient.get(
        Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
        headers: anyNamed('headers'),
      )).thenThrow(Exception('Network error'));

      expect(
        () => service.fetchAccountSpeakers(apiUrl, accountId, username, password),
        throwsException,
      );
    });

    test('fetchAccountSpeakers filters out speakers without IP addresses', () async {
      final responseBody = json.encode({
        'speakers': [
          {'ipAddress': '192.168.1.100'},
          {'name': 'Speaker without IP'},
          {'ipAddress': ''},
          {'ipAddress': '192.168.1.101'},
        ],
      });

      when(mockClient.get(
        Uri.parse('$apiUrl/mgmt/accounts/$accountId/speakers'),
        headers: anyNamed('headers'),
      )).thenAnswer(
        (_) async => http.Response(responseBody, 200),
      );

      final result = await service.fetchAccountSpeakers(
        apiUrl,
        accountId,
        username,
        password,
      );

      expect(result, ['192.168.1.100', '192.168.1.101']);
    });
  });
}
