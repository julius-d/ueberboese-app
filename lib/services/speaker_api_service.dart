import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:ueberboese_app/models/bass.dart';
import 'package:ueberboese_app/models/clock_display.dart';
import 'package:ueberboese_app/models/speaker_info.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/volume.dart';
import 'package:ueberboese_app/models/now_playing.dart';
import 'package:ueberboese_app/models/zone.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/models/recent.dart';
import 'package:ueberboese_app/models/speaker_source.dart';

class SpeakerApiService {
  final http.Client? httpClient;
  final Duration timeout;

  SpeakerApiService({
    this.httpClient,
    this.timeout = const Duration(seconds: 10),
  });

  Future<SpeakerInfo> fetchSpeakerInfo(String ipAddress) async {
    final url = Uri.parse('http://$ipAddress:8090/info');
    final client = httpClient ?? http.Client();

    try {
      final response = await client
          .get(url)
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch speaker info: HTTP ${response.statusCode}',
        );
      }

      // Decode response body as UTF-8
      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      // Find info element and extract deviceID attribute
      final infoElements = document.findAllElements('info');
      if (infoElements.isEmpty) {
        throw Exception('Info element not found in response');
      }
      final deviceId = infoElements.first.getAttribute('deviceID');
      if (deviceId == null || deviceId.isEmpty) {
        throw Exception('Device ID not found in response');
      }

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

      // Find margeAccountUUID element (optional)
      String? accountId;
      final margeAccountUUIDElements = document.findAllElements('margeAccountUUID');
      if (margeAccountUUIDElements.isNotEmpty) {
        accountId = margeAccountUUIDElements.first.innerText;
      }

      return SpeakerInfo(
        name: name,
        type: type,
        deviceId: deviceId,
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

  Future<Speaker> createSpeakerFromIp(String ipAddress, String emoji) async {
    final speakerInfo = await fetchSpeakerInfo(ipAddress);
    return Speaker(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: speakerInfo.name,
      emoji: emoji,
      ipAddress: ipAddress,
      type: speakerInfo.type,
      deviceId: speakerInfo.deviceId,
    );
  }

  Future<Volume> getVolume(String ipAddress) async {
    final url = Uri.parse('http://$ipAddress:8090/volume');
    final client = httpClient ?? http.Client();

    try {
      final response = await client
          .get(url)
          .timeout(timeout);

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
          .timeout(timeout);

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
          .timeout(timeout);

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

      // Extract location and source from ContentItem if present
      String? location;
      String? source;
      String? sourceAccount;
      final contentItemElements = document.findAllElements('ContentItem');
      if (contentItemElements.isNotEmpty) {
        final contentItem = contentItemElements.first;
        location = contentItem.getAttribute('location');
        source = contentItem.getAttribute('source');
        sourceAccount = contentItem.getAttribute('sourceAccount');
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
        location: location,
        source: source,
        sourceAccount: sourceAccount,
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
          .timeout(timeout);

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
          .timeout(timeout);

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
          .timeout(timeout);

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
          .timeout(timeout);

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
          .timeout(timeout);

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

  Future<List<Preset>> getPresets(String ipAddress) async {
    final url = Uri.parse('http://$ipAddress:8090/presets');
    final client = httpClient ?? http.Client();

    try {
      final response = await client
          .get(url)
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch presets: HTTP ${response.statusCode}',
        );
      }

      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      // Find all preset elements
      final presetElements = document.findAllElements('preset');

      // Parse each preset
      final presets = presetElements
          .map((element) => Preset.fromXml(element))
          .toList();

      return presets;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch presets: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<List<Recent>> getRecents(String ipAddress) async {
    final url = Uri.parse('http://$ipAddress:8090/recents');
    final client = httpClient ?? http.Client();

    try {
      final response = await client
          .get(url)
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch recents: HTTP ${response.statusCode}',
        );
      }

      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      // Find all recent elements
      final recentElements = document.findAllElements('recent');

      // Parse each recent
      final recents = recentElements
          .map((element) => Recent.fromXml(element))
          .toList();

      // Sort by utcTime descending (newest first)
      recents.sort((a, b) => b.utcTime.compareTo(a.utcTime));

      return recents;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch recents: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<List<Preset>> removePreset(String ipAddress, String presetId) async {
    final url = Uri.parse('http://$ipAddress:8090/removePreset');
    final client = httpClient ?? http.Client();

    try {
      final body = '<preset id="$presetId"></preset>';
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'text/xml'},
            body: body,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to remove preset: HTTP ${response.statusCode}',
        );
      }

      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      // Find all preset elements in the updated list
      final presetElements = document.findAllElements('preset');

      // Parse each preset
      final presets = presetElements
          .map((element) => Preset.fromXml(element))
          .toList();

      return presets;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to remove preset: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<void> standby(String ipAddress) async {
    final url = Uri.parse('http://$ipAddress:8090/standby');
    final client = httpClient ?? http.Client();

    try {
      final response = await client
          .get(url)
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to set standby: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to set standby: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<List<Preset>> storePreset(
    String ipAddress,
    String presetId,
    String spotifyUri,
    String spotifyUserId,
    String itemName,
    String? containerArt,
  ) async {
    final url = Uri.parse('http://$ipAddress:8090/storePreset');
    final client = httpClient ?? http.Client();

    try {
      // Construct location by base64 encoding the Spotify URI
      final location = '/playback/container/${base64Encode(utf8.encode(spotifyUri))}';

      // Get current timestamp in seconds
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Build XML body
      final containerArtElement = containerArt != null
          ? '<containerArt>$containerArt</containerArt>'
          : '';

      final body = '''<preset id="$presetId" createdOn="$timestamp" updatedOn="$timestamp">
  <ContentItem source="SPOTIFY" type="tracklisturl" location="$location" sourceAccount="$spotifyUserId" isPresetable="true">
    <itemName>$itemName</itemName>$containerArtElement
  </ContentItem>
</preset>''';

      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'text/xml'},
            body: body,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to store preset: HTTP ${response.statusCode}',
        );
      }

      // Parse response XML
      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      // Find all preset elements in the updated list
      final presetElements = document.findAllElements('preset');

      // Parse each preset
      final presets = presetElements
          .map((element) => Preset.fromXml(element))
          .toList();

      return presets;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to store preset: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<List<Preset>> storeTuneInPreset(
    String ipAddress,
    String presetId,
    String stationId,
    String itemName,
    String? containerArt,
  ) async {
    final url = Uri.parse('http://$ipAddress:8090/storePreset');
    final client = httpClient ?? http.Client();

    try {
      // Construct location with station ID
      final location = '/v1/playback/station/$stationId';

      // Get current timestamp in seconds
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Build XML body
      final containerArtElement = containerArt != null
          ? '<containerArt>$containerArt</containerArt>'
          : '';

      final body = '''<preset id="$presetId" createdOn="$timestamp" updatedOn="$timestamp">
  <ContentItem source="TUNEIN" type="stationurl" location="$location" isPresetable="true">
    <itemName>$itemName</itemName>$containerArtElement
  </ContentItem>
</preset>''';

      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'text/xml'},
            body: body,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to store TuneIn preset: HTTP ${response.statusCode}',
        );
      }

      // Parse response XML
      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      // Find all preset elements in the updated list
      final presetElements = document.findAllElements('preset');

      // Parse each preset
      final presets = presetElements
          .map((element) => Preset.fromXml(element))
          .toList();

      return presets;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to store TuneIn preset: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<List<Preset>> storeInternetRadioPreset(
    String ipAddress,
    String presetId,
    String url,
    String itemName,
    String? containerArt,
    String apiUrl,
  ) async {
    final presetUrl = Uri.parse('http://$ipAddress:8090/storePreset');
    final client = httpClient ?? http.Client();

    try {
      // Get current timestamp in seconds
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Create JSON object with radio station data
      final radioData = {
        'name': itemName,
        'imageUrl': containerArt ?? '',
        'streamUrl': url,
      };
      final jsonString = jsonEncode(radioData);

      // Base64 encode the JSON
      final base64Data = base64Encode(utf8.encode(jsonString));

      // Build location URL with encoded data
      final location = '$apiUrl/core02/svc-bmx-adapter-orion/prod/orion/station?data=$base64Data';

      // Build XML body
      final containerArtElement = containerArt != null && containerArt.isNotEmpty
          ? '<containerArt>$containerArt</containerArt>'
          : '';

      final body = '''<preset id="$presetId" createdOn="$timestamp" updatedOn="$timestamp">
  <ContentItem source="LOCAL_INTERNET_RADIO" type="stationurl" location="$location" isPresetable="true">
    <itemName>$itemName</itemName>$containerArtElement
  </ContentItem>
</preset>''';

      final response = await client
          .post(
            presetUrl,
            headers: {'Content-Type': 'text/xml'},
            body: body,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to store Internet Radio preset: HTTP ${response.statusCode}',
        );
      }

      // Parse response XML
      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      // Find all preset elements in the updated list
      final presetElements = document.findAllElements('preset');

      // Parse each preset
      final presets = presetElements
          .map((element) => Preset.fromXml(element))
          .toList();

      return presets;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to store Internet Radio preset: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<void> sendKey(String ipAddress, String keyValue, String state) async {
    // Valid key values (case sensitive)
    const validKeys = [
      'ADD_FAVORITE',
      'AUX_INPUT',
      'BOOKMARK',
      'MUTE',
      'NEXT_TRACK',
      'PAUSE',
      'PLAY',
      'PLAY_PAUSE',
      'POWER',
      'PRESET_1',
      'PRESET_2',
      'PRESET_3',
      'PRESET_4',
      'PRESET_5',
      'PRESET_6',
      'PREV_TRACK',
      'REMOVE_FAVORITE',
      'REPEAT_ALL',
      'REPEAT_OFF',
      'REPEAT_ONE',
      'SHUFFLE_OFF',
      'SHUFFLE_ON',
      'STOP',
      'THUMBS_DOWN',
      'THUMBS_UP',
      'VOLUME_DOWN',
      'VOLUME_UP',
    ];

    // Valid state values (case sensitive)
    const validStates = ['press', 'release', 'repeat'];

    if (!validKeys.contains(keyValue)) {
      throw ArgumentError('Invalid key value: $keyValue. Must be one of: ${validKeys.join(", ")}');
    }

    if (!validStates.contains(state)) {
      throw ArgumentError('Invalid state: $state. Must be one of: ${validStates.join(", ")}');
    }

    final url = Uri.parse('http://$ipAddress:8090/key');
    final client = httpClient ?? http.Client();

    try {
      final body = '<key state="$state" sender="Gabbo">$keyValue</key>';
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'text/xml'},
            body: body,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to send key: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to send key: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<void> setSpeakerName(String ipAddress, String name) async {
    final url = Uri.parse('http://$ipAddress:8090/name');
    final client = httpClient ?? http.Client();

    try {
      final body = '<name>$name</name>';
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'text/xml'},
            body: body,
          )
          .timeout(Duration(seconds: timeout.inSeconds * 3));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to set speaker name: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to set speaker name: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<void> selectContentItem(String ipAddress, Recent recent) async {
    final url = Uri.parse('http://$ipAddress:8090/select');
    final client = httpClient ?? http.Client();

    try {
      // Build ContentItem XML using XmlBuilder for proper escaping
      final builder = XmlBuilder();
      builder.element('ContentItem', nest: () {
        builder.attribute('source', recent.source);
        builder.attribute('type', recent.type);
        builder.attribute('location', recent.location);
        final sourceAccount = recent.sourceAccount;
        if (sourceAccount != null && sourceAccount.isNotEmpty) {
          builder.attribute('sourceAccount', sourceAccount);
        }
        builder.attribute('isPresetable', 'true');
        builder.element('itemName', nest: recent.itemName);
      });

      final body = builder.buildDocument().toXmlString();

      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'text/xml'},
            body: body,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to select content: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to select content: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<void> selectPreset(String ipAddress, Preset preset) async {
    final url = Uri.parse('http://$ipAddress:8090/select');
    final client = httpClient ?? http.Client();

    try {
      // Build ContentItem XML using XmlBuilder for proper escaping
      final builder = XmlBuilder();
      builder.element('ContentItem', nest: () {
        builder.attribute('source', preset.source);
        builder.attribute('type', preset.type);
        builder.attribute('location', preset.location);
        final sourceAccount = preset.sourceAccount;
        if (sourceAccount != null && sourceAccount.isNotEmpty) {
          builder.attribute('sourceAccount', sourceAccount);
        }
        builder.attribute('isPresetable', 'true');
        builder.element('itemName', nest: preset.itemName);
      });

      final body = builder.buildDocument().toXmlString();

      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'text/xml'},
            body: body,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        final responseBody = response.body.trim();
        final errorMessage = responseBody.isNotEmpty
            ? 'Failed to select preset: HTTP ${response.statusCode} - $responseBody'
            : 'Failed to select preset: HTTP ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to select preset: $e');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<int> getLanguage(String ipAddress) async {
    final url = Uri.parse('http://$ipAddress:8090/language');
    final client = httpClient ?? http.Client();

    try {
      final response = await client.get(url).timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to get language: HTTP ${response.statusCode}',
        );
      }

      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);
      final elements = document.findAllElements('sysLanguage');
      if (elements.isEmpty) {
        throw Exception('sysLanguage element not found in response');
      }
      final value = int.tryParse(elements.first.innerText.trim());
      if (value == null) {
        throw Exception('Invalid language code in response');
      }
      return value;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to get language: $e');
    } finally {
      if (httpClient == null) client.close();
    }
  }

  Future<BassCapabilities> getBassCapabilities(String ipAddress) async {
    final url = Uri.parse('http://$ipAddress:8090/bassCapabilities');
    final client = httpClient ?? http.Client();

    try {
      final response = await client.get(url).timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to get bass capabilities: HTTP ${response.statusCode}',
        );
      }

      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      bool bassAvailable = false;
      final bassAvailableElements = document.findAllElements('bassAvailable');
      if (bassAvailableElements.isNotEmpty) {
        bassAvailable = bassAvailableElements.first.innerText.toLowerCase() == 'true';
      }

      int bassMin = -9;
      final bassMinElements = document.findAllElements('bassMin');
      if (bassMinElements.isNotEmpty) {
        bassMin = int.parse(bassMinElements.first.innerText);
      }

      int bassMax = 0;
      final bassMaxElements = document.findAllElements('bassMax');
      if (bassMaxElements.isNotEmpty) {
        bassMax = int.parse(bassMaxElements.first.innerText);
      }

      int bassDefault = 0;
      final bassDefaultElements = document.findAllElements('bassDefault');
      if (bassDefaultElements.isNotEmpty) {
        bassDefault = int.parse(bassDefaultElements.first.innerText);
      }

      return BassCapabilities(
        bassAvailable: bassAvailable,
        bassMin: bassMin,
        bassMax: bassMax,
        bassDefault: bassDefault,
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to get bass capabilities: $e');
    } finally {
      if (httpClient == null) client.close();
    }
  }

  Future<Bass> getBass(String ipAddress) async {
    final url = Uri.parse('http://$ipAddress:8090/bass');
    final client = httpClient ?? http.Client();

    try {
      final response = await client.get(url).timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to get bass: HTTP ${response.statusCode}',
        );
      }

      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      final targetBassElements = document.findAllElements('targetbass');
      if (targetBassElements.isEmpty) {
        throw Exception('targetbass element not found in response');
      }
      final targetBass = int.parse(targetBassElements.first.innerText);

      final actualBassElements = document.findAllElements('actualbass');
      if (actualBassElements.isEmpty) {
        throw Exception('actualbass element not found in response');
      }
      final actualBass = int.parse(actualBassElements.first.innerText);

      return Bass(targetBass: targetBass, actualBass: actualBass);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to get bass: $e');
    } finally {
      if (httpClient == null) client.close();
    }
  }

  Future<void> setBass(String ipAddress, int bass) async {
    final url = Uri.parse('http://$ipAddress:8090/bass');
    final client = httpClient ?? http.Client();

    try {
      final body = '<bass>$bass</bass>';
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'text/xml'},
            body: body,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to set bass: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to set bass: $e');
    } finally {
      if (httpClient == null) client.close();
    }
  }

  Future<void> setLanguage(String ipAddress, int languageCode) async {
    final url = Uri.parse('http://$ipAddress:8090/language');
    final client = httpClient ?? http.Client();

    try {
      final body = '<sysLanguage>$languageCode</sysLanguage>';
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'text/xml'},
            body: body,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to set language: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to set language: $e');
    } finally {
      if (httpClient == null) client.close();
    }
  }

  Future<bool> isClockDisplaySupported(String ipAddress) async {
    final url = Uri.parse('http://$ipAddress:8090/supportedURLs');
    final client = httpClient ?? http.Client();

    try {
      final response = await client.get(url).timeout(timeout);

      if (response.statusCode != 200) {
        return false;
      }

      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);
      return document
          .findAllElements('URL')
          .any((e) => e.getAttribute('location') == '/clockDisplay');
    } catch (e) {
      return false;
    } finally {
      if (httpClient == null) client.close();
    }
  }

  Future<ClockConfig> getClockDisplay(String ipAddress) async {
    final url = Uri.parse('http://$ipAddress:8090/clockDisplay');
    final client = httpClient ?? http.Client();

    try {
      final response = await client.get(url).timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to get clock display: HTTP ${response.statusCode}',
        );
      }

      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);
      final elements = document.findAllElements('clockConfig');
      if (elements.isEmpty) {
        throw Exception('clockConfig element not found in response');
      }
      final el = elements.first;

      final userEnable = el.getAttribute('userEnable')?.toLowerCase() == 'true';
      final timeFormat =
          el.getAttribute('timeFormat') ?? ClockConfig.format12h;
      final brightnessLevel =
          int.tryParse(el.getAttribute('brightnessLevel') ?? '') ?? 0;
      final timezoneInfo = el.getAttribute('timezoneInfo') ?? '';
      final userOffsetMinute =
          int.tryParse(el.getAttribute('userOffsetMinute') ?? '') ?? 0;
      final userUtcTime =
          int.tryParse(el.getAttribute('userUtcTime') ?? '') ?? 0;

      return ClockConfig(
        userEnable: userEnable,
        timeFormat: timeFormat,
        brightnessLevel: brightnessLevel,
        timezoneInfo: timezoneInfo,
        userOffsetMinute: userOffsetMinute,
        userUtcTime: userUtcTime,
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to get clock display: $e');
    } finally {
      if (httpClient == null) client.close();
    }
  }

  Future<void> setClockDisplay(String ipAddress, ClockConfig config) async {
    final url = Uri.parse('http://$ipAddress:8090/clockDisplay');
    final client = httpClient ?? http.Client();

    try {
      final body = '<?xml version="1.0" encoding="UTF-8" ?>'
          '<clockDisplay>'
          '<clockConfig'
          ' timezoneInfo="${config.timezoneInfo}"'
          ' userEnable="${config.userEnable}"'
          ' timeFormat="${config.timeFormat}"'
          ' userOffsetMinute="${config.userOffsetMinute}"'
          ' brightnessLevel="${config.brightnessLevel}"'
          ' userUtcTime="${config.userUtcTime}"'
          '/>'
          '</clockDisplay>';
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'text/xml'},
            body: body,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to set clock display: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to set clock display: $e');
    } finally {
      if (httpClient == null) client.close();
    }
  }

  Future<List<SpeakerSource>> getSources(String ipAddress) async {
    final url = Uri.parse('http://$ipAddress:8090/sources');
    final client = httpClient ?? http.Client();

    try {
      final response = await client.get(url).timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to get sources: HTTP ${response.statusCode}');
      }

      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);

      return document
          .findAllElements('sourceItem')
          .map(SpeakerSource.fromXml)
          .toList();
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to get sources: $e');
    } finally {
      if (httpClient == null) client.close();
    }
  }

  Future<void> selectSource(String ipAddress, SpeakerSource source) async {
    final url = Uri.parse('http://$ipAddress:8090/select');
    final client = httpClient ?? http.Client();

    try {
      final builder = XmlBuilder();
      builder.element('ContentItem', nest: () {
        builder.attribute('source', source.source);
        final account = source.sourceAccount;
        if (account != null && account.isNotEmpty) {
          builder.attribute('sourceAccount', account);
        }
      });
      final body = builder.buildDocument().toXmlString();

      final response = await client
          .post(url, headers: {'Content-Type': 'text/xml'}, body: body)
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to select source: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to select source: $e');
    } finally {
      if (httpClient == null) client.close();
    }
  }
}
