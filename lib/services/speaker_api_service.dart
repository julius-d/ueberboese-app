import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/speaker_info.dart';

class SpeakerApiService {
  final http.Client? httpClient;

  SpeakerApiService({this.httpClient});

  Future<SpeakerInfo> fetchSpeakerInfo(String ipAddress) async {
    final url = Uri.parse('http://$ipAddress:8090/info');
    final client = httpClient ?? http.Client();

    try {
      final response = await client
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch speaker info: HTTP ${response.statusCode}',
        );
      }

      // Decode response body as UTF-8
      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      // Find name element
      final nameElements = document.findAllElements('name');
      if (nameElements.isEmpty) {
        throw Exception('Speaker name not found in response');
      }
      final name = nameElements.first.innerText;

      // Find type element
      final typeElements = document.findAllElements('type');
      if (typeElements.isEmpty) {
        throw Exception('Speaker type not found in response');
      }
      final type = typeElements.first.innerText;

      // Find margeURL element (optional)
      String? margeUrl;
      final margeUrlElements = document.findAllElements('margeURL');
      if (margeUrlElements.isNotEmpty) {
        margeUrl = margeUrlElements.first.innerText;
      }

      // Find macAddress from networkInfo with type="SCM" (optional)
      String? accountId;
      final networkInfoElements = document.findAllElements('networkInfo');
      for (final networkInfo in networkInfoElements) {
        if (networkInfo.getAttribute('type') == 'SCM') {
          final macAddressElements = networkInfo.findElements('macAddress');
          if (macAddressElements.isNotEmpty) {
            accountId = macAddressElements.first.innerText;
            break;
          }
        }
      }

      return SpeakerInfo(
        name: name,
        type: type,
        margeUrl: margeUrl,
        accountId: accountId,
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to connect to speaker: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }
}
