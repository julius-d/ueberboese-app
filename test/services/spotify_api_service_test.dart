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
    late SpotifyApiService serviceWithAuth;

    setUp(() {
      mockClient = MockClient();
      service = SpotifyApiService(httpClient: mockClient);
      serviceWithAuth = SpotifyApiService(
        httpClient: mockClient,
        username: 'admin',
        password: 'testpass',
      );
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

      test('should include Authorization header when credentials are provided', () async {
        final response = http.Response(
          jsonEncode({'redirectUrl': redirectUrl}),
          200,
        );

        // The expected auth header for admin:testpass
        final expectedAuth = 'Basic ${base64Encode(utf8.encode('admin:testpass'))}';

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/init'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': expectedAuth,
          },
          body: '{}',
        )).thenAnswer((_) async => response);

        final result = await serviceWithAuth.initSpotifyAuth(apiUrl);

        expect(result, redirectUrl);
        verify(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/init'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': expectedAuth,
          },
          body: '{}',
        )).called(1);
      });
    });

    group('confirmSpotifyAuth', () {
      const apiUrl = 'https://api.example.com';
      const code = 'auth_code_123';

      test('should complete successfully on 200 status', () async {
        final response = http.Response('', 200);

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/confirm?code=$code'),
          headers: {},
        )).thenAnswer((_) async => response);

        await service.confirmSpotifyAuth(apiUrl, code);

        verify(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/confirm?code=$code'),
          headers: {},
        )).called(1);
      });

      test('should throw exception on non-200 status code', () async {
        final response = http.Response('Unauthorized', 401);

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/confirm?code=$code'),
          headers: {},
        )).thenAnswer((_) async => response);

        expect(
          () => service.confirmSpotifyAuth(apiUrl, code),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on timeout', () async {
        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/confirm?code=$code'),
          headers: {},
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

      test('should include Authorization header when credentials are provided', () async {
        final response = http.Response('', 200);
        final expectedAuth = 'Basic ${base64Encode(utf8.encode('admin:testpass'))}';

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/confirm?code=$code'),
          headers: {'Authorization': expectedAuth},
        )).thenAnswer((_) async => response);

        await serviceWithAuth.confirmSpotifyAuth(apiUrl, code);

        verify(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/confirm?code=$code'),
          headers: {'Authorization': expectedAuth},
        )).called(1);
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
          headers: {},
        )).thenAnswer((_) async => response);

        final result = await service.listSpotifyAccounts(apiUrl);

        expect(result.length, 2);
        expect(result[0].displayName, 'John Doe');
        expect(result[1].displayName, 'Jane Smith');
        verify(mockClient.get(
          Uri.parse('$apiUrl/mgmt/spotify/accounts'),
          headers: {},
        )).called(1);
      });

      test('should return empty list when no accounts', () async {
        final responseBody = jsonEncode({'accounts': []});
        final response = http.Response(responseBody, 200);

        when(mockClient.get(
          Uri.parse('$apiUrl/mgmt/spotify/accounts'),
          headers: {},
        )).thenAnswer((_) async => response);

        final result = await service.listSpotifyAccounts(apiUrl);

        expect(result, isEmpty);
      });

      test('should return empty list when accounts is null', () async {
        final responseBody = jsonEncode({});
        final response = http.Response(responseBody, 200);

        when(mockClient.get(
          Uri.parse('$apiUrl/mgmt/spotify/accounts'),
          headers: {},
        )).thenAnswer((_) async => response);

        final result = await service.listSpotifyAccounts(apiUrl);

        expect(result, isEmpty);
      });

      test('should throw exception on non-200 status code', () async {
        final response = http.Response('Internal Server Error', 500);

        when(mockClient.get(
          Uri.parse('$apiUrl/mgmt/spotify/accounts'),
          headers: {},
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
          headers: {},
        )).thenAnswer((_) async => response);

        expect(
          () => service.listSpotifyAccounts(apiUrl),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on timeout', () async {
        when(mockClient.get(
          Uri.parse('$apiUrl/mgmt/spotify/accounts'),
          headers: {},
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
          headers: {},
        )).thenAnswer((_) async => response);

        final result = await service.listSpotifyAccounts(apiUrl);

        expect(result.length, 1);
        expect(result[0].createdAt.year, 2025);
        expect(result[0].createdAt.month, 12);
        expect(result[0].createdAt.day, 23);
      });

      test('should include Authorization header when credentials are provided', () async {
        final responseBody = jsonEncode({
          'accounts': [
            {
              'displayName': 'Test User',
              'createdAt': '2025-12-23T10:30:00.000Z',
            },
          ],
        });
        final response = http.Response(responseBody, 200);
        final expectedAuth = 'Basic ${base64Encode(utf8.encode('admin:testpass'))}';

        when(mockClient.get(
          Uri.parse('$apiUrl/mgmt/spotify/accounts'),
          headers: {'Authorization': expectedAuth},
        )).thenAnswer((_) async => response);

        final result = await serviceWithAuth.listSpotifyAccounts(apiUrl);

        expect(result.length, 1);
        verify(mockClient.get(
          Uri.parse('$apiUrl/mgmt/spotify/accounts'),
          headers: {'Authorization': expectedAuth},
        )).called(1);
      });
    });

    group('getSpotifyEntity', () {
      const apiUrl = 'https://api.example.com';
      const spotifyUri = 'spotify:track:6rqhFgbbKwnb9MLmUQDhG6';

      test('should return entity with image on successful request', () async {
        final responseBody = jsonEncode({
          'name': 'Bohemian Rhapsody',
          'imageUrl': 'https://i.scdn.co/image/ab67616d00001e02e319baafd16e84f0408af2a0',
        });
        final response = http.Response(responseBody, 200);

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/entity'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'uri': spotifyUri}),
        )).thenAnswer((_) async => response);

        final result = await service.getSpotifyEntity(apiUrl, spotifyUri);

        expect(result.name, 'Bohemian Rhapsody');
        expect(result.imageUrl, 'https://i.scdn.co/image/ab67616d00001e02e319baafd16e84f0408af2a0');
        verify(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/entity'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'uri': spotifyUri}),
        )).called(1);
      });

      test('should return entity without image on successful request', () async {
        final responseBody = jsonEncode({
          'name': 'My Private Playlist',
          'imageUrl': null,
        });
        final response = http.Response(responseBody, 200);

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/entity'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'uri': spotifyUri}),
        )).thenAnswer((_) async => response);

        final result = await service.getSpotifyEntity(apiUrl, spotifyUri);

        expect(result.name, 'My Private Playlist');
        expect(result.imageUrl, isNull);
      });

      test('should throw exception on 400 error with message', () async {
        final responseBody = jsonEncode({
          'error': 'Invalid URI',
          'message': 'The provided URI is not a valid Spotify URI',
        });
        final response = http.Response(responseBody, 400);

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/entity'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'uri': spotifyUri}),
        )).thenAnswer((_) async => response);

        expect(
          () => service.getSpotifyEntity(apiUrl, spotifyUri),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('The provided URI is not a valid Spotify URI'))),
        );
      });

      test('should throw exception on 400 error without message', () async {
        final responseBody = jsonEncode({
          'error': 'Invalid URI',
        });
        final response = http.Response(responseBody, 400);

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/entity'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'uri': spotifyUri}),
        )).thenAnswer((_) async => response);

        expect(
          () => service.getSpotifyEntity(apiUrl, spotifyUri),
          throwsA(predicate((e) =>
              e is Exception && e.toString().contains('Invalid URI'))),
        );
      });

      test('should throw exception on 404 error', () async {
        final response = http.Response('Not Found', 404);

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/entity'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'uri': spotifyUri}),
        )).thenAnswer((_) async => response);

        expect(
          () => service.getSpotifyEntity(apiUrl, spotifyUri),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Spotify entity not found'))),
        );
      });

      test('should throw exception on 500 error', () async {
        final response = http.Response('Internal Server Error', 500);

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/entity'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'uri': spotifyUri}),
        )).thenAnswer((_) async => response);

        expect(
          () => service.getSpotifyEntity(apiUrl, spotifyUri),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Failed to fetch entity: HTTP 500'))),
        );
      });

      test('should throw exception on timeout', () async {
        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/entity'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'uri': spotifyUri}),
        )).thenAnswer(
          (_) => Future.delayed(
            const Duration(seconds: 11),
            () => http.Response('{}', 200),
          ),
        );

        expect(
          () => service.getSpotifyEntity(apiUrl, spotifyUri),
          throwsA(isA<Exception>()),
        );
      });

      test('should include Authorization header when credentials are provided', () async {
        final responseBody = jsonEncode({
          'name': 'Test Track',
          'imageUrl': 'https://example.com/image.jpg',
        });
        final response = http.Response(responseBody, 200);
        final expectedAuth = 'Basic ${base64Encode(utf8.encode('admin:testpass'))}';

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/entity'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': expectedAuth,
          },
          body: jsonEncode({'uri': spotifyUri}),
        )).thenAnswer((_) async => response);

        final result = await serviceWithAuth.getSpotifyEntity(apiUrl, spotifyUri);

        expect(result.name, 'Test Track');
        verify(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/entity'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': expectedAuth,
          },
          body: jsonEncode({'uri': spotifyUri}),
        )).called(1);
      });

      test('should throw exception on malformed JSON', () async {
        final response = http.Response('not valid json', 200);

        when(mockClient.post(
          Uri.parse('$apiUrl/mgmt/spotify/entity'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'uri': spotifyUri}),
        )).thenAnswer((_) async => response);

        expect(
          () => service.getSpotifyEntity(apiUrl, spotifyUri),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
