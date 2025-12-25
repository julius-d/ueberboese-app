import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/speaker_info.dart';
import '../models/volume.dart';
import '../models/now_playing.dart';
import '../models/zone.dart';

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

  Future<Volume> getVolume(String ipAddress) async {
    final url = Uri.parse('http://$ipAddress:8090/volume');
    final client = httpClient ?? http.Client();

    try {
      final response = await client
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch volume: HTTP ${response.statusCode}',
        );
      }

      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      // Find targetvolume element
      final targetVolumeElements = document.findAllElements('targetvolume');
      if (targetVolumeElements.isEmpty) {
        throw Exception('Target volume not found in response');
      }
      final targetVolume = int.parse(targetVolumeElements.first.innerText);

      // Find actualvolume element
      final actualVolumeElements = document.findAllElements('actualvolume');
      if (actualVolumeElements.isEmpty) {
        throw Exception('Actual volume not found in response');
      }
      final actualVolume = int.parse(actualVolumeElements.first.innerText);

      // Find muteenabled element
      final muteEnabledElements = document.findAllElements('muteenabled');
      if (muteEnabledElements.isEmpty) {
        throw Exception('Mute enabled not found in response');
      }
      final muteEnabled = muteEnabledElements.first.innerText.toLowerCase() == 'true';

      return Volume(
        targetVolume: targetVolume,
        actualVolume: actualVolume,
        muteEnabled: muteEnabled,
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch volume: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<Volume> setVolume(String ipAddress, int volume) async {
    if (volume < 0 || volume > 100) {
      throw ArgumentError('Volume must be between 0 and 100');
    }

    final url = Uri.parse('http://$ipAddress:8090/volume');
    final client = httpClient ?? http.Client();

    try {
      final body = '<volume>$volume</volume>';
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'text/xml'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to set volume: HTTP ${response.statusCode}',
        );
      }

      // Some speakers return empty body, so fetch the current volume instead
      if (response.body.trim().isEmpty) {
        return await getVolume(ipAddress);
      }

      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      // Try to parse response, if it fails, fetch volume
      try {
        final targetVolumeElements = document.findAllElements('targetvolume');
        if (targetVolumeElements.isEmpty) {
          // Response doesn't have volume info, fetch it
          return await getVolume(ipAddress);
        }
        final targetVolume = int.parse(targetVolumeElements.first.innerText);

        final actualVolumeElements = document.findAllElements('actualvolume');
        if (actualVolumeElements.isEmpty) {
          return await getVolume(ipAddress);
        }
        final actualVolume = int.parse(actualVolumeElements.first.innerText);

        final muteEnabledElements = document.findAllElements('muteenabled');
        if (muteEnabledElements.isEmpty) {
          return await getVolume(ipAddress);
        }
        final muteEnabled = muteEnabledElements.first.innerText.toLowerCase() == 'true';

        return Volume(
          targetVolume: targetVolume,
          actualVolume: actualVolume,
          muteEnabled: muteEnabled,
        );
      } catch (e) {
        // If parsing fails, fetch volume
        return await getVolume(ipAddress);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to set volume: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<NowPlaying> getNowPlaying(String ipAddress) async {
    final url = Uri.parse('http://$ipAddress:8090/nowPlaying');
    final client = httpClient ?? http.Client();

    try {
      final response = await client
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch now playing: HTTP ${response.statusCode}',
        );
      }

      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      // Extract optional fields
      String? track;
      final trackElements = document.findAllElements('track');
      if (trackElements.isNotEmpty) {
        track = trackElements.first.innerText;
      }

      String? artist;
      final artistElements = document.findAllElements('artist');
      if (artistElements.isNotEmpty) {
        artist = artistElements.first.innerText;
      }

      String? album;
      final albumElements = document.findAllElements('album');
      if (albumElements.isNotEmpty) {
        album = albumElements.first.innerText;
      }

      String? art;
      final artElements = document.findAllElements('art');
      if (artElements.isNotEmpty) {
        art = artElements.first.innerText;
      }

      String? artImageStatus;
      if (artElements.isNotEmpty) {
        artImageStatus = artElements.first.getAttribute('artImageStatus');
      }

      String? shuffleSetting;
      final shuffleElements = document.findAllElements('shuffleSetting');
      if (shuffleElements.isNotEmpty) {
        shuffleSetting = shuffleElements.first.innerText;
      }

      String? repeatSetting;
      final repeatElements = document.findAllElements('repeatSetting');
      if (repeatElements.isNotEmpty) {
        repeatSetting = repeatElements.first.innerText;
      }

      String? playStatus;
      final playStatusElements = document.findAllElements('playStatus');
      if (playStatusElements.isNotEmpty) {
        playStatus = playStatusElements.first.innerText;
      }

      return NowPlaying(
        track: track,
        artist: artist,
        album: album,
        art: art,
        artImageStatus: artImageStatus,
        shuffleSetting: shuffleSetting,
        repeatSetting: repeatSetting,
        playStatus: playStatus,
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch now playing: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<Zone?> getZone(String ipAddress) async {
    final url = Uri.parse('http://$ipAddress:8090/getZone');
    final client = httpClient ?? http.Client();

    try {
      final response = await client
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch zone: HTTP ${response.statusCode}',
        );
      }

      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      // Find zone element
      final zoneElements = document.findAllElements('zone');
      if (zoneElements.isEmpty) {
        return null;
      }

      final zoneElement = zoneElements.first;
      final masterId = zoneElement.getAttribute('master');

      // If no master attribute, the device is not part of a zone
      if (masterId == null || masterId.isEmpty) {
        return null;
      }

      // Parse members
      final memberElements = zoneElement.findElements('member');
      final members = memberElements
          .map((element) => ZoneMember.fromXml(element))
          .toList();

      // Optional attributes
      final senderIpAddress = zoneElement.getAttribute('senderIPAddress');
      final senderIsMasterStr = zoneElement.getAttribute('senderIsMaster');
      final senderIsMaster = senderIsMasterStr != null
          ? senderIsMasterStr.toLowerCase() == 'true'
          : null;

      return Zone(
        masterId: masterId,
        members: members,
        senderIpAddress: senderIpAddress,
        senderIsMaster: senderIsMaster,
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch zone: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<void> createZone(String ipAddress, String masterId, List<ZoneMember> members) async {
    final url = Uri.parse('http://$ipAddress:8090/setZone');
    final client = httpClient ?? http.Client();

    try {
      // Build XML body
      final membersXml = members.map((m) => m.toXml()).join('\n  ');
      final body = '<zone master="$masterId">\n  $membersXml\n</zone>';

      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'text/xml'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to create zone: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to create zone: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<void> addZoneMembers(String ipAddress, String masterId, List<ZoneMember> members) async {
    final url = Uri.parse('http://$ipAddress:8090/addZoneSlave');
    final client = httpClient ?? http.Client();

    try {
      // Build XML body
      final membersXml = members.map((m) => m.toXml()).join('\n  ');
      final body = '<zone master="$masterId">\n  $membersXml\n</zone>';

      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'text/xml'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to add zone members: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to add zone members: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<void> removeZoneMembers(String ipAddress, String masterId, List<ZoneMember> members) async {
    final url = Uri.parse('http://$ipAddress:8090/removeZoneSlave');
    final client = httpClient ?? http.Client();

    try {
      // Build XML body
      final membersXml = members.map((m) => m.toXml()).join('\n  ');
      final body = '<zone master="$masterId">\n  $membersXml\n</zone>';

      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'text/xml'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to remove zone members: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to remove zone members: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<void> userPlayControl(String ipAddress, String controlType) async {
    final validControls = ['PAUSE_CONTROL', 'PLAY_CONTROL', 'PLAY_PAUSE_CONTROL', 'STOP_CONTROL'];
    if (!validControls.contains(controlType)) {
      throw ArgumentError('Invalid control type. Must be one of: ${validControls.join(", ")}');
    }

    final url = Uri.parse('http://$ipAddress:8090/userPlayControl');
    final client = httpClient ?? http.Client();

    try {
      final body = '<PlayControl>$controlType</PlayControl>';
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'text/xml'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to send play control: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to send play control: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }
}
