import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/models/network_stats.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/wireless_network.dart';
import 'package:ueberboese_app/pages/speaker_wifi_page.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/speaker_setup_service.dart';

class _FakeApi extends SpeakerApiService {
  NetworkStats? stats;
  Object? error;
  int calls = 0;

  @override
  Future<NetworkStats> getNetworkStats(String ipAddress) async {
    calls++;
    if (error != null) throw error!;
    return stats!;
  }
}

class _FakeSetup extends SpeakerSetupService {
  List<WirelessNetwork> networks = [];
  Object? scanError;
  Object? addError;
  final added = <List<String>>[];
  String? lastIp;

  @override
  Future<List<WirelessNetwork>> performWirelessSiteSurvey({
    String speakerIp = kSetupSpeakerIp,
  }) async {
    lastIp = speakerIp;
    if (scanError != null) throw scanError!;
    return networks;
  }

  @override
  Future<void> addWirelessProfile(
    String ssid,
    String password,
    String securityType, {
    String speakerIp = kSetupSpeakerIp,
  }) async {
    if (addError != null) throw addError!;
    lastIp = speakerIp;
    added.add([ssid, password, securityType]);
  }
}

void main() {
  const speaker = Speaker(
    id: '1',
    name: 'Test',
    emoji: '🔊',
    ipAddress: '192.168.1.100',
    type: 'SoundTouch 10',
    deviceId: 'd',
  );
  const wireless = NetworkStats(
    kind: 'Wireless',
    ssid: 'YAWL6',
    rssi: 'Good',
    frequencyKHz: 5180000,
    ipAddress: '192.168.1.100',
    macAddress: 'AABBCC',
  );

  late _FakeApi api;
  late _FakeSetup setup;

  setUp(() {
    api = _FakeApi()..stats = wireless;
    setup = _FakeSetup();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SpeakerWifiPage(
          speaker: speaker,
          apiService: api,
          setupService: setup,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the current wireless network', (tester) async {
    await pump(tester);

    expect(find.text('YAWL6'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('5 GHz'), findsOneWidget);
    expect(find.text('192.168.1.100'), findsOneWidget);
    expect(find.text('AABBCC'), findsOneWidget);
  });

  testWidgets('shows Ethernet for a wired speaker', (tester) async {
    api.stats = const NetworkStats(kind: 'Wired', macAddress: 'AA');
    await pump(tester);

    expect(find.text('Connected via Ethernet'), findsOneWidget);
    expect(find.text('Signal'), findsNothing);
  });

  testWidgets('shows error and retries', (tester) async {
    api.error = Exception('boom');
    await pump(tester);
    expect(
      find.textContaining('Failed to load network information'),
      findsOneWidget,
    );

    api.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('YAWL6'), findsOneWidget);
  });

  testWidgets('refresh reloads stats', (tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(api.calls, 2);
  });

  testWidgets('scan lists networks and marks the connected one', (
    tester,
  ) async {
    setup.networks = const [
      WirelessNetwork(
        ssid: 'YAWL6',
        signalStrength: -40,
        secure: true,
        securityType: 'wpa2aes',
      ),
      WirelessNetwork(
        ssid: 'Open',
        signalStrength: -75,
        secure: false,
        securityType: 'none',
      ),
    ];
    await pump(tester);

    await tester.tap(find.text('Scan for networks'));
    await tester.pumpAndSettle();

    expect(setup.lastIp, '192.168.1.100');
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });

  testWidgets('scan error is shown', (tester) async {
    setup.scanError = Exception('nope');
    await pump(tester);

    await tester.tap(find.text('Scan for networks'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Scan failed'), findsOneWidget);
  });

  testWidgets('connecting to a secure network asks for the password', (
    tester,
  ) async {
    setup.networks = const [
      WirelessNetwork(
        ssid: 'Home',
        signalStrength: -40,
        secure: true,
        securityType: 'wpa2aes',
      ),
    ];
    await pump(tester);
    await tester.tap(find.text('Scan for networks'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'secret');
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(setup.added, [
      ['Home', 'secret', 'wpa2aes'],
    ]);
    expect(setup.lastIp, '192.168.1.100');
    expect(find.text('Wi-Fi profile saved'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(api.calls, 2);
  });

  testWidgets('open network connects without a password', (tester) async {
    setup.networks = const [
      WirelessNetwork(
        ssid: 'Open',
        signalStrength: -40,
        secure: false,
        securityType: 'none',
      ),
    ];
    await pump(tester);
    await tester.tap(find.text('Scan for networks'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(setup.added, [
      ['Open', '', 'none'],
    ]);
  });

  testWidgets('cancelling the password dialog does nothing', (tester) async {
    setup.networks = const [
      WirelessNetwork(
        ssid: 'Home',
        signalStrength: -40,
        secure: true,
        securityType: 'wpa2aes',
      ),
    ];
    await pump(tester);
    await tester.tap(find.text('Scan for networks'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(setup.added, isEmpty);
  });

  testWidgets('shows an error dialog when connecting fails', (tester) async {
    setup.addError = Exception('bad password');
    setup.networks = const [
      WirelessNetwork(
        ssid: 'Open',
        signalStrength: -40,
        secure: false,
        securityType: 'none',
      ),
    ];
    await pump(tester);
    await tester.tap(find.text('Scan for networks'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Failed to configure Wi-Fi'), findsOneWidget);
  });

  testWidgets('manual network defaults to wpa_or_wpa2 and needs input', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Manual network…'));
    await tester.pumpAndSettle();

    final connect = find.widgetWithText(TextButton, 'Connect');
    expect(tester.widget<TextButton>(connect).onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'SSID'), ' Hidden ');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'pw');
    await tester.pump();
    await tester.tap(connect);
    await tester.pumpAndSettle();

    expect(setup.added, [
      ['Hidden', 'pw', 'wpa_or_wpa2'],
    ]);
  });

  testWidgets('manual network with None security hides the password', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Manual network…'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('None').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Password'), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, 'SSID'), 'Cafe');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Connect'));
    await tester.pumpAndSettle();

    expect(setup.added, [
      ['Cafe', '', 'none'],
    ]);
  });
}
