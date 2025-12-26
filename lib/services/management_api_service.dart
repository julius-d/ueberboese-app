import 'dart:convert';
import 'package:http/http.dart' as http;

class ManagementApiService {
  final http.Client? httpClient;

  ManagementApiService({this.httpClient});

  Future<List<String>> fetchAccountSpeakers(
    String apiUrl,
    String accountId,
    String username,
    String password,
  ) async {
    // Remove trailing slash from API URL if present
    final baseUrl = apiUrl.endsWith('/') ? apiUrl.substring(0, apiUrl.length - 1) : apiUrl;
    final url = Uri.parse('$baseUrl/mgmt/accounts/$accountId/speakers');
    final client = httpClient ?? http.Client();

    // Create Basic Auth header
    final credentials = base64Encode(utf8.encode('$username:$password'));
    final headers = {
      'Authorization': 'Basic $credentials',
      'Accept': 'application/json',
    };

    try {
      final response = await client
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
          'Invalid management credentials. Please check your username and password in the configuration.',
        );
      }

      if (response.statusCode == 404) {
        throw Exception(
          'Account not found. Please check your Account ID in the configuration.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch speakers from account: HTTP ${response.statusCode}',
        );
      }

      // Parse JSON response
      final Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Invalid JSON response from management API: $e');
      }

      // Extract speakers array
      if (!jsonResponse.containsKey('speakers')) {
        throw Exception('Invalid response format: missing speakers field');
      }

      final speakersData = jsonResponse['speakers'];
      if (speakersData is! List) {
        throw Exception('Invalid response format: speakers must be an array');
      }

      // Extract IP addresses
      final List<String> ipAddresses = [];
      for (final speaker in speakersData) {
        if (speaker is Map<String, dynamic> && speaker.containsKey('ipAddress')) {
          final ipAddress = speaker['ipAddress'];
          if (ipAddress is String && ipAddress.isNotEmpty) {
            ipAddresses.add(ipAddress);
          }
        }
      }

      return ipAddresses;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to connect to management API: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }
}
