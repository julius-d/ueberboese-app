import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ueberboese_app/models/device_event.dart';

class ManagementApiService {
  final http.Client? httpClient;
  final Duration timeout;

  ManagementApiService({
    this.httpClient,
    this.timeout = const Duration(seconds: 10),
  });

  Future<List<String>> fetchAccountSpeakers(
    String apiUrl,
    String accountId,
    String username,
    String password,
  ) async {
    // Remove trailing slash from API URL if present
    final baseUrl = apiUrl.endsWith('/')
        ? apiUrl.substring(0, apiUrl.length - 1)
        : apiUrl;
    final url = Uri.parse('$baseUrl/mgmt/accounts/$accountId/speakers');
    final client = httpClient ?? http.Client();

    // Create Basic Auth header
    final credentials = base64Encode(utf8.encode('$username:$password'));
    final headers = {
      'Authorization': 'Basic $credentials',
      'Accept': 'application/json',
    };

    try {
      final response = await client.get(url, headers: headers).timeout(timeout);

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
        if (speaker is Map<String, dynamic> &&
            speaker.containsKey('ipAddress')) {
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

  Future<List<DeviceEvent>> fetchDeviceEvents(
    String apiUrl,
    String deviceId,
    String username,
    String password,
  ) async {
    // Remove trailing slash from API URL if present
    final baseUrl = apiUrl.endsWith('/')
        ? apiUrl.substring(0, apiUrl.length - 1)
        : apiUrl;
    final url = Uri.parse('$baseUrl/mgmt/devices/$deviceId/events');
    final client = httpClient ?? http.Client();

    // Create Basic Auth header
    final credentials = base64Encode(utf8.encode('$username:$password'));
    final headers = {
      'Authorization': 'Basic $credentials',
      'Accept': 'application/json',
    };

    try {
      final response = await client.get(url, headers: headers).timeout(timeout);

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
          'Invalid management credentials. Please check your username and password in the configuration.',
        );
      }

      if (response.statusCode == 404) {
        throw Exception('Device not found. Please check the device ID.');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch device events: HTTP ${response.statusCode}',
        );
      }

      // Parse JSON response
      final Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Invalid JSON response from management API: $e');
      }

      // Extract events array
      if (!jsonResponse.containsKey('events')) {
        throw Exception('Invalid response format: missing events field');
      }

      final eventsData = jsonResponse['events'];
      if (eventsData is! List) {
        throw Exception('Invalid response format: events must be an array');
      }

      // Parse events
      final List<DeviceEvent> events = [];
      for (final eventJson in eventsData) {
        if (eventJson is Map<String, dynamic>) {
          try {
            events.add(DeviceEvent.fromJson(eventJson));
          } catch (e) {
            // Skip invalid events but continue processing
            continue;
          }
        }
      }

      return events;
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
