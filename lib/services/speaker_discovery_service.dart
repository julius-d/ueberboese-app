import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ueberboese_app/models/possible_speaker.dart';

class SpeakerDiscoveryService {
  static const _multicastAddress = '239.255.255.250';
  static const _multicastPort = 1900;
  static const _discoverMessage =
      'M-SEARCH * HTTP/1.1\r\n'
      'ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n'
      'MX: 3\r\n'
      'MAN: "ssdp:discover"\r\n'
      'HOST: 239.255.255.250:1900\r\n\r\n';

  /// Sends an SSDP M-SEARCH and streams the speakers that answer.
  ///
  /// [target] and [targetPort] default to the SSDP multicast group and are
  /// only overridden in tests.
  Stream<PossibleSpeaker> discover({
    Duration timeout = const Duration(seconds: 10),
    InternetAddress? target,
    int targetPort = _multicastPort,
  }) async* {
    final seenIps = <String>{};

    // Bind to port 0 so the OS picks an ephemeral port.
    // On Windows, port 1900 is held by the system SSDP service (ssdpsrv),
    // which would block the bind or swallow responses. SSDP devices reply
    // unicast to our source port, so an ephemeral port works fine and
    // requires no firewall rule.
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    StreamSubscription<RawSocketEvent>? sub;
    Timer? timer;
    late final StreamController<PossibleSpeaker> controller;

    void cleanup() {
      timer?.cancel();
      sub?.cancel();
      socket.close();
    }

    controller = StreamController<PossibleSpeaker>(onCancel: cleanup);

    try {
      final bytesSent = socket.send(
        utf8.encode(_discoverMessage),
        target ?? InternetAddress(_multicastAddress),
        targetPort,
      );
      if (bytesSent == 0) {
        throw const SocketException('Failed to send SSDP discovery request');
      }
    } catch (_) {
      cleanup();
      unawaited(controller.close());
      rethrow;
    }

    sub = socket.listen((event) {
      if (event != RawSocketEvent.read || controller.isClosed) return;
      final datagram = socket.receive();
      if (datagram == null) return;
      final str = String.fromCharCodes(datagram.data);
      final parsed = parseResponse(str, datagram.address.address);
      if (parsed != null && seenIps.add(parsed.ip)) {
        controller.add(parsed);
      }
    }, onError: (Object e) {
      cleanup();
      if (!controller.isClosed) {
        controller.addError(e);
        controller.close();
      }
    }, onDone: () {
      cleanup();
      if (!controller.isClosed) controller.close();
    });

    timer = Timer(timeout, () {
      cleanup();
      if (!controller.isClosed) controller.close();
    });

    yield* controller.stream;
  }

  static PossibleSpeaker? parseResponse(String response, String senderIp) {
    final lines = response.split('\r\n');
    if (lines.isEmpty || !lines.first.startsWith('HTTP/1.1 200 OK')) {
      return null;
    }
    String? location;
    for (final line in lines) {
      if (line.toLowerCase().startsWith('location:')) {
        location = line.substring(9).trim();
        break;
      }
    }
    if (location == null) return null;
    return PossibleSpeaker(ip: senderIp, location: location);
  }
}
