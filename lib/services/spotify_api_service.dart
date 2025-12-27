import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ueberboese_app/models/spotify_account.dart';
import 'package:ueberboese_app/models/spotify_entity.dart';

class SpotifyApiService {
  final http.Client? httpClient;
  final String? username;
  final String? password;

  SpotifyApiService({
    this.httpClient,
    this.username,
    this.password,
  });

  String _createAuthHeader() {
    if (username == null || password == null) {
      return '';
    }
    final credentials = '$username:$password';
    final encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }

  Future<String> initSpotifyAuth(String apiUrl) async {
    final url = Uri.parse('$apiUrl/mgmt/spotify/init');
    final client = httpClient ?? http.Client();

    try {
      final body = jsonEncode({});
      final headers = {
        'Content-Type': 'application/json',
        if (username != null && password != null)
          'Authorization': _createAuthHeader(),
      };
      final response = await client
          .post(
            url,
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to initialize Spotify auth: HTTP ${response.statusCode}',
        );
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final redirectUrl = responseData['redirectUrl'] as String?;

      if (redirectUrl == null || redirectUrl.isEmpty) {
        throw Exception('No redirectUrl received from server');
      }

      return redirectUrl;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to initialize Spotify auth: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<void> confirmSpotifyAuth(String apiUrl, String code) async {
    final url = Uri.parse('$apiUrl/mgmt/spotify/confirm?code=$code');
    final client = httpClient ?? http.Client();

    try {
      final headers = <String, String>{
        if (username != null && password != null)
          'Authorization': _createAuthHeader(),
      };
      final response = await client
          .post(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to confirm Spotify auth: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to confirm Spotify auth: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<List<SpotifyAccount>> listSpotifyAccounts(String apiUrl) async {
    final url = Uri.parse('$apiUrl/mgmt/spotify/accounts');
    final client = httpClient ?? http.Client();

    try {
      final headers = <String, String>{
        if (username != null && password != null)
          'Authorization': _createAuthHeader(),
      };
      final response = await client
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to list Spotify accounts: HTTP ${response.statusCode}',
        );
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final accountsJson = responseData['accounts'] as List<dynamic>?;

      if (accountsJson == null) {
        return [];
      }

      return accountsJson
          .map((json) => SpotifyAccount.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to list Spotify accounts: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<SpotifyEntity> getSpotifyEntity(String apiUrl, String spotifyUri) async {
    final url = Uri.parse('$apiUrl/mgmt/spotify/entity');
    final client = httpClient ?? http.Client();

    try {
      final body = jsonEncode({'uri': spotifyUri});
      final headers = {
        'Content-Type': 'application/json',
        if (username != null && password != null)
          'Authorization': _createAuthHeader(),
      };

      final response = await client
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['message'] ?? 'Invalid URI');
      }

      if (response.statusCode == 404) {
        throw Exception('Spotify entity not found');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch entity: HTTP ${response.statusCode}');
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return SpotifyEntity.fromJson(responseData);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch Spotify entity: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }
}
