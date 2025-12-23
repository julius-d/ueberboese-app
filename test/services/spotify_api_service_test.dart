import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ueberboese_app/services/spotify_api_service.dart';
import 'dart:convert';

@GenerateMocks([http.Client])
import 'spotify_api_service_test.mocks.dart';

void main() {
  group('SpotifyApiService', () {
    late MockClient mockClient;
    late SpotifyApiService service;

    setUp(() {
      mockClient = MockClient();
      service = SpotifyApiService(httpClient: mockClient);
    });

    group('initSpotifyAuth', () {
      const apiUrl = 'https://api.example.com';
      const redirectUrl = 'https://spotify.com/oauth?token=abc123';

      test('should return redirectUrl on successful init', () async {
        final response = http.Response(
          jsonEncode({'redirectUrl': redirectUrl}),
          200,
        );

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/init'),
          headers: {'Content-Type': 'application/json'},
          body: '{}',
        )).thenAnswer((_) async => response);

        final result = await service.initSpotifyAuth(apiUrl);

        expect(result, redirectUrl);
        verify(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/init'),
          headers: {'Content-Type': 'application/json'},
          body: '{}',
        )).called(1);
      });

      test('should throw exception on non-200 status code', () async {
        final response = http.Response('Not Found', 404);

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/init'),
          headers: {'Content-Type': 'application/json'},
          body: '{}',
        )).thenAnswer((_) async => response);

        expect(
          () => service.initSpotifyAuth(apiUrl),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception when redirectUrl is missing', () async {
        final response = http.Response(
          jsonEncode({'error': 'no redirect'}),
          200,
        );

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/init'),
          headers: {'Content-Type': 'application/json'},
          body: '{}',
        )).thenAnswer((_) async => response);

        expect(
          () => service.initSpotifyAuth(apiUrl),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception when redirectUrl is empty', () async {
        final response = http.Response(
          jsonEncode({'redirectUrl': ''}),
          200,
        );

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/init'),
          headers: {'Content-Type': 'application/json'},
          body: '{}',
        )).thenAnswer((_) async => response);

        expect(
          () => service.initSpotifyAuth(apiUrl),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on malformed JSON', () async {
        final response = http.Response('not valid json', 200);

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/init'),
          headers: {'Content-Type': 'application/json'},
          body: '{}',
        )).thenAnswer((_) async => response);

        expect(
          () => service.initSpotifyAuth(apiUrl),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on timeout', () async {
        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/init'),
          headers: {'Content-Type': 'application/json'},
          body: '{}',
        )).thenAnswer(
          (_) => Future.delayed(
            const Duration(seconds: 11),
            () => http.Response('{}', 200),
          ),
        );

        expect(
          () => service.initSpotifyAuth(apiUrl),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('confirmSpotifyAuth', () {
      const apiUrl = 'https://api.example.com';
      const code = 'auth_code_123';

      test('should complete successfully on 200 status', () async {
        final response = http.Response('', 200);

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/confirm?code=$code'),
        )).thenAnswer((_) async => response);

        await service.confirmSpotifyAuth(apiUrl, code);

        verify(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/confirm?code=$code'),
        )).called(1);
      });

      test('should throw exception on non-200 status code', () async {
        final response = http.Response('Unauthorized', 401);

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/confirm?code=$code'),
        )).thenAnswer((_) async => response);

        expect(
          () => service.confirmSpotifyAuth(apiUrl, code),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on timeout', () async {
        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/confirm?code=$code'),
        )).thenAnswer(
          (_) => Future.delayed(
            const Duration(seconds: 11),
            () => http.Response('', 200),
          ),
        );

        expect(
          () => service.confirmSpotifyAuth(apiUrl, code),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('listSpotifyAccounts', () {
      const apiUrl = 'https://api.example.com';

      test('should return list of accounts on successful request', () async {
        final responseBody = jsonEncode({
          'accounts': [
            {
              'displayName': 'John Doe',
              'createdAt': '2025-12-23T10:30:00Z',
            },
            {
              'displayName': 'Jane Smith',
              'createdAt': '2025-12-22T14:15:00Z',
            },
          ],
        });
        final response = http.Response(responseBody, 200);

        when(mockClient.get(
          Uri.parse('$apiUrl/mgmt/spotify/accounts'),
        )).thenAnswer((_) async => response);

        final result = await service.listSpotifyAccounts(apiUrl);

        expect(result.length, 2);
        expect(result[0].displayName, 'John Doe');
        expect(result[1].displayName, 'Jane Smith');
        verify(mockClient.get(
          Uri.parse('$apiUrl/mgmt/spotify/accounts'),
        )).called(1);
      });

      test('should return empty list when no accounts', () async {
        final responseBody = jsonEncode({'accounts': []});
        final response = http.Response(responseBody, 200);

        when(mockClient.get(
          Uri.parse('$apiUrl/mgmt/spotify/accounts'),
        )).thenAnswer((_) async => response);

        final result = await service.listSpotifyAccounts(apiUrl);

        expect(result, isEmpty);
      });

      test('should return empty list when accounts is null', () async {
        final responseBody = jsonEncode({});
        final response = http.Response(responseBody, 200);

        when(mockClient.get(
          Uri.parse('$apiUrl/mgmt/spotify/accounts'),
        )).thenAnswer((_) async => response);

        final result = await service.listSpotifyAccounts(apiUrl);

        expect(result, isEmpty);
      });

      test('should throw exception on non-200 status code', () async {
        final response = http.Response('Internal Server Error', 500);

        when(mockClient.get(
          Uri.parse('$apiUrl/mgmt/spotify/accounts'),
        )).thenAnswer((_) async => response);

        expect(
          () => service.listSpotifyAccounts(apiUrl),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on malformed JSON', () async {
        final response = http.Response('not valid json', 200);

        when(mockClient.get(
          Uri.parse('$apiUrl/mgmt/spotify/accounts'),
        )).thenAnswer((_) async => response);

        expect(
          () => service.listSpotifyAccounts(apiUrl),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on timeout', () async {
        when(mockClient.get(
          Uri.parse('$apiUrl/mgmt/spotify/accounts'),
        )).thenAnswer(
          (_) => Future.delayed(
            const Duration(seconds: 11),
            () => http.Response('{"accounts": []}', 200),
          ),
        );

        expect(
          () => service.listSpotifyAccounts(apiUrl),
          throwsA(isA<Exception>()),
        );
      });

      test('should parse dates correctly', () async {
        final responseBody = jsonEncode({
          'accounts': [
            {
              'displayName': 'Test User',
              'createdAt': '2025-12-23T10:30:00.000Z',
            },
          ],
        });
        final response = http.Response(responseBody, 200);

        when(mockClient.get(
          Uri.parse('$apiUrl/mgmt/spotify/accounts'),
        )).thenAnswer((_) async => response);

        final result = await service.listSpotifyAccounts(apiUrl);

        expect(result.length, 1);
        expect(result[0].createdAt.year, 2025);
        expect(result[0].createdAt.month, 12);
        expect(result[0].createdAt.day, 23);
      });
    });
  });
}
