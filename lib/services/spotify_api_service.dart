import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/spotify_account.dart';

class SpotifyApiService {
  final http.Client? httpClient;

  SpotifyApiService({this.httpClient});

  Future<String> initSpotifyAuth(String apiUrl) async {
    final url = Uri.parse('$apiUrl/mgmt/spotify/init');
    final client = httpClient ?? http.Client();

    try {
      final body = jsonEncode({});
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
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
      final response = await client
          .post(url)
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
      final response = await client
          .get(url)
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
}
