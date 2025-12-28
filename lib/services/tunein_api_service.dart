import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:ueberboese_app/models/tunein_station.dart';
import 'package:ueberboese_app/models/tunein_station_detail.dart';

class TuneInApiService {
  final http.Client? httpClient;

  TuneInApiService({this.httpClient});

  Future<List<TuneInStation>> searchStations(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse('https://opml.radiotime.com/search.ashx?query=$encodedQuery');
    final client = httpClient ?? http.Client();

    try {
      final response = await client
          .get(
            url,
            headers: {'Accept': 'text/xml'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to search TuneIn stations: HTTP ${response.statusCode}',
        );
      }

      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      // Find all outline elements
      final outlineElements = document.findAllElements('outline');

      // Filter for type="audio" and item="station"
      final stations = outlineElements
          .where((element) {
            final type = element.getAttribute('type');
            final item = element.getAttribute('item');
            return type == 'audio' && item == 'station';
          })
          .map((element) => TuneInStation.fromXml(element))
          .toList();

      return stations;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to search TuneIn stations: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<TuneInStationDetail> getStationDetails(String stationId) async {
    if (stationId.trim().isEmpty) {
      throw ArgumentError('Station ID cannot be empty');
    }

    final url = Uri.parse('https://opml.radiotime.com/describe.ashx?id=$stationId');
    final client = httpClient ?? http.Client();

    try {
      final response = await client
          .get(
            url,
            headers: {'Accept': 'text/xml'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch station details: HTTP ${response.statusCode}',
        );
      }

      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      // Find station element
      final stationElements = document.findAllElements('station');
      if (stationElements.isEmpty) {
        throw Exception('Station not found in response');
      }

      final stationElement = stationElements.first;
      return TuneInStationDetail.fromXml(stationElement);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch station details: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }
}
