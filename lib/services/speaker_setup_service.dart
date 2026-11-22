import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:ueberboese_app/models/wireless_network.dart';

/// IP address used by the speaker in access-point / setup mode.
const String kSetupSpeakerIp = '192.0.2.1';

typedef SocketConnect = Future<Socket> Function(String host, int port,
    {Duration? timeout});

class SpeakerSetupService {
  final http.Client? httpClient;
  final Duration timeout;
  final SocketConnect? socketConnect;
  final Duration envswitchDelay;

  SpeakerSetupService({
    this.httpClient,
    this.timeout = const Duration(seconds: 15),
    this.socketConnect,
    this.envswitchDelay = const Duration(seconds: 5),
  });

  http.Client _client() => httpClient ?? http.Client();

  bool _ownClient() => httpClient == null;

  Future<List<WirelessNetwork>> performWirelessSiteSurvey(
      {String speakerIp = kSetupSpeakerIp}) async {
    final url =
        Uri.parse('http://$speakerIp:8090/performWirelessSiteSurvey');
    final client = _client();
    try {
      final response = await client.get(url).timeout(timeout);
      if (response.statusCode != 200) {
        throw Exception(
            'Site survey failed: HTTP ${response.statusCode}');
      }
      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);
      final items = document.findAllElements('item');
      final networks = items.map((item) {
        final ssid = item.getAttribute('ssid') ?? '';
        final signalStrength =
            int.tryParse(item.getAttribute('signalStrength') ?? '0') ?? 0;
        final secure = item.getAttribute('secure') == 'true';
        final typeElements = item.findAllElements('type');
        final securityType =
            typeElements.isNotEmpty ? typeElements.first.innerText : 'none';
        return WirelessNetwork(
          ssid: ssid,
          signalStrength: signalStrength,
          secure: secure,
          securityType: securityType,
        );
      }).toList();
      return _cleanUpNetworks(networks);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to perform site survey: $e');
    } finally {
      if (_ownClient()) client.close();
    }
  }

  /// Drops hidden (empty) SSIDs, merges duplicates keeping the strongest
  /// signal and sorts the result strongest first.
  static List<WirelessNetwork> _cleanUpNetworks(
      List<WirelessNetwork> networks) {
    final bySsid = <String, WirelessNetwork>{};
    for (final network in networks) {
      if (network.ssid.isEmpty) continue;
      final existing = bySsid[network.ssid];
      if (existing == null ||
          network.signalStrength > existing.signalStrength) {
        bySsid[network.ssid] = network;
      }
    }
    return bySsid.values.toList()
      ..sort((a, b) => b.signalStrength.compareTo(a.signalStrength));
  }

  Future<void> addWirelessProfile(
      String ssid, String password, String securityType,
      {String speakerIp = kSetupSpeakerIp}) async {
    final url = Uri.parse('http://$speakerIp:8090/addWirelessProfile');
    final client = _client();
    final body =
        '<AddWirelessProfile>'
        '<profile ssid="${_escapeXml(ssid)}" '
        'password="${_escapeXml(password)}" securityType="$securityType" >'
        '</profile></AddWirelessProfile>';
    try {
      // Use a longer timeout: the speaker needs time to attempt connecting
      // to the Wi-Fi network before responding.
      final response = await client
          .post(url, headers: {'Content-Type': 'text/xml'}, body: body)
          .timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        final responseBody = utf8.decode(response.bodyBytes).trim();
        final detail = responseBody.isNotEmpty ? '\n$responseBody' : '';
        throw Exception(
            'Add wireless profile failed: HTTP ${response.statusCode}$detail');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to add wireless profile: $e');
    } finally {
      if (_ownClient()) client.close();
    }
  }

  /// Connects to [speakerIp] on port 17000, sends envswitch commands line by
  /// line, and returns a log of all sent ("> ") and received ("< ") lines.
  Future<List<String>> configureEnvswitch(String apiUrl,
      {String speakerIp = kSetupSpeakerIp}) async {
    final connectFn = socketConnect ?? Socket.connect;
    final socket = await connectFn(
      speakerIp,
      17000,
      timeout: timeout,
    );
    final log = <String>[];
    try {
      final updatesUrl = '$apiUrl/updates/soundtouch';
      final commands = [
        'sys configuration bmxRegistryUrl $apiUrl/bmx/registry/v1/services',
        'sys configuration statsServerUrl $apiUrl',
        'sys configuration margeServerUrl $apiUrl',
        'sys configuration swUpdateUrl $updatesUrl',
        'envswitch boseurls set $apiUrl $updatesUrl',
        'getpdo CurrentSystemConfiguration',
        'sys reboot',
      ];

      // Wait for the speaker to be ready before sending commands.
      await Future<void>.delayed(envswitchDelay);

      // Buffer incoming data. The speaker uses "->" as its command prompt,
      // signalling it is ready for the next command.
      final buffer = StringBuffer();
      // The active completer for the current wait. Using a list so the closure
      // always holds a reference to the same container even as we swap values.
      final pendingBox = <Completer<String>?>[ null ];

      void tryComplete() {
        final c = pendingBox[0];
        if (c != null && !c.isCompleted && _hasPrompt(buffer.toString())) {
          pendingBox[0] = null;
          final s = buffer.toString();
          buffer.clear();
          c.complete(s);
        }
      }

      socket.cast<List<int>>().transform(utf8.decoder).listen((data) {
        buffer.write(data);
        tryComplete();
      });

      Future<String> waitForPrompt(Duration timeLimit) {
        final c = Completer<String>();
        pendingBox[0] = c;
        // If data already arrived and contains the prompt, complete immediately.
        tryComplete();
        return c.future.timeout(timeLimit, onTimeout: () {
          pendingBox[0] = null;
          final s = buffer.toString();
          buffer.clear();
          return s;
        });
      }

      // Drain the initial "->" connection prompt before sending commands.
      await waitForPrompt(const Duration(seconds: 3));

      for (final cmd in commands) {
        log.add('> $cmd');
        socket.writeln(cmd);
        await socket.flush();
        // Wait up to 5 seconds for the speaker's "->" ready prompt.
        final response = await waitForPrompt(const Duration(seconds: 5));
        final cleaned = _stripPrompt(response).trim();
        if (cleaned.isNotEmpty) {
          for (final line in cleaned.split('\n')) {
            final trimmed = line.trim();
            if (trimmed.isNotEmpty) log.add('< $trimmed');
          }
        }
      }

      await socket.close();
      return log;
    } catch (e) {
      socket.destroy();
      if (e is Exception) rethrow;
      throw Exception('Failed to configure envswitch: $e');
    }
  }

  /// Connects to [speakerIp] on port 17000, sends `getpdo CurrentSystemConfiguration`,
  /// and returns the raw multi-line response string.
  Future<String> getSystemConfiguration(String speakerIp) async {
    final connectFn = socketConnect ?? Socket.connect;
    final socket = await connectFn(speakerIp, 17000, timeout: timeout);
    try {
      await Future<void>.delayed(envswitchDelay);
      final responseBuffer = StringBuffer();
      final completer = Completer<String>();
      Timer? idleTimer;

      void complete() {
        idleTimer?.cancel();
        if (!completer.isCompleted) {
          completer.complete(responseBuffer.toString());
        }
      }

      socket.cast<List<int>>().transform(utf8.decoder).listen(
        (data) {
          responseBuffer.write(data);
          // Reset idle timer on each new chunk; resolve after a short pause.
          idleTimer?.cancel();
          idleTimer = Timer(const Duration(milliseconds: 300), complete);
        },
        onDone: complete,
      );

      socket.writeln('getpdo CurrentSystemConfiguration');
      await socket.flush();

      final response = await completer.future
          .timeout(const Duration(seconds: 5), onTimeout: () {
        return responseBuffer.toString();
      });
      await socket.close();
      return response;
    } catch (e) {
      socket.destroy();
      if (e is Exception) rethrow;
      throw Exception('Failed to get system configuration: $e');
    }
  }

  /// Parses the `getpdo CurrentSystemConfiguration` response format into a map.
  ///
  /// Input format:
  /// ```
  /// keyName {
  ///   text: "some value"
  /// }
  /// ```
  static Map<String, String> parseSystemConfiguration(String response) {
    final result = <String, String>{};
    // Match blocks like: keyName {\n  text: "value"\n}
    final blockPattern = RegExp(
      r'(\w+)\s*\{\s*\n\s*text:\s*(.*?)\s*\n\s*\}',
      multiLine: true,
    );
    for (final match in blockPattern.allMatches(response)) {
      final key = match.group(1)!;
      var value = match.group(2)!.trim();
      // Strip surrounding quotes if present.
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      }
      result[key] = value;
    }
    return result;
  }

  /// Connects to [speakerIp] on port 17000 and sends `sys reboot`.
  Future<void> rebootSpeaker(String speakerIp) async {
    final connectFn = socketConnect ?? Socket.connect;
    final socket = await connectFn(speakerIp, 17000, timeout: timeout);
    try {
      await Future<void>.delayed(envswitchDelay);
      socket.writeln('sys reboot');
      await socket.flush();
      await socket.close();
    } catch (e) {
      socket.destroy();
      if (e is Exception) rethrow;
      throw Exception('Failed to reboot speaker: $e');
    }
  }

  Future<void> setMargeAccount(
      String speakerIp, String accountId, String authToken) async {
    final url = Uri.parse('http://$speakerIp:8090/setMargeAccount');
    final client = _client();
    final body = '<PairDeviceWithAccount>'
        '<accountId>${_escapeXml(accountId)}</accountId>'
        '<userAuthToken>Bearer ${_escapeXml(authToken)}</userAuthToken>'
        '</PairDeviceWithAccount>';
    try {
      final response = await client
          .post(
            url,
            headers: {
              'Content-Type': 'application/xml',
              'Accept': 'application/xml',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        throw Exception(
            'Set Marge account failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to set Marge account: $e');
    } finally {
      if (_ownClient()) client.close();
    }
  }

  Future<void> leaveSetupMode() async {
    final url = Uri.parse('http://$kSetupSpeakerIp:8090/setup');
    final client = _client();
    const body = '<setupState state="SETUP_WIFI_LEAVE" />';
    try {
      final response = await client
          .post(url, headers: {'Content-Type': 'text/xml'}, body: body)
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw Exception(
            'Leave setup mode failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to leave setup mode: $e');
    } finally {
      if (_ownClient()) client.close();
    }
  }

  /// Returns true when [s] ends with the speaker's command-prompt marker "->".
  static bool _hasPrompt(String s) {
    final t = s.trimRight();
    return t.endsWith('->');
  }

  /// Removes trailing prompt artifacts ("->", "OK->", etc.) from a response.
  static String _stripPrompt(String s) {
    return s.replaceAll(RegExp(r'\s*->(?:OK)?\s*$'), '').trim();
  }

  String _escapeXml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
