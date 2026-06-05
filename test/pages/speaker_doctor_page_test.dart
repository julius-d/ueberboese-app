import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/speaker_info.dart';
import 'package:ueberboese_app/pages/speaker_doctor_page.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/speaker_setup_service.dart';
import 'package:ueberboese_app/widgets/async_filled_button.dart';
import 'package:ueberboese_app/widgets/envswitch_log_view.dart';

const _testSpeaker = Speaker(
  id: '1',
  name: 'Living Room',
  emoji: '🔊',
  ipAddress: '192.168.1.50',
  type: 'Bose Home Speaker',
  deviceId: 'ABC123',
);

const _configResponse = '''
margeServerUrl {
  text: "https://api.example.com"
}
bmxRegistryUrl {
  text: "https://api.example.com/bmx/registry/v1/services"
}
isZeroconfEnabled {
  text: true
}
''';

/// Config response where margeServerUrl is wrong (doesn't match the api URL).
const _wrongConfigResponse = '''
margeServerUrl {
  text: "https://old.server.com"
}
bmxRegistryUrl {
  text: "https://api.example.com/bmx/registry/v1/services"
}
isZeroconfEnabled {
  text: true
}
''';

const _testInfo = SpeakerInfo(
  name: 'Test Speaker',
  type: 'SoundTouch 10',
  deviceId: 'AABBCCDDEEFF',
  accountId: '1234567',
);

class _FakeApiService extends SpeakerApiService {
  final Future<SpeakerInfo> Function(String) _fetch;

  _FakeApiService(this._fetch);

  @override
  Future<SpeakerInfo> fetchSpeakerInfo(String ipAddress) => _fetch(ipAddress);
}

SpeakerApiService _successApiService() =>
    _FakeApiService((_) async => _testInfo);

SpeakerApiService _failingApiService() =>
    _FakeApiService((_) => Future.error(Exception('HTTP 503')));

Widget _wrap(Widget child, {MyAppState? appState}) {
  return ChangeNotifierProvider.value(
    value: appState ?? MyAppState(),
    child: MaterialApp(home: child),
  );
}

/// Builds a service that simulates the speaker's telnet protocol.
///
/// `getSystemConfiguration` (first connect): sends config text and closes
/// the stream so the idle-timer resolves immediately.
///
/// `configureEnvswitch` / `rebootSpeaker` (subsequent connects): sends the
/// initial "->" prompt and then responds "ok\n->" to each written command.
SpeakerSetupService _buildService({required String configResponseText}) {
  int callCount = 0;
  return SpeakerSetupService(
    envswitchDelay: Duration.zero,
    socketConnect: (host, port, {timeout}) async {
      callCount++;
      final controller = StreamController<Uint8List>();
      final isFirstCall = callCount == 1;

      if (!isFirstCall) {
        // Send initial ready-prompt for configureEnvswitch / rebootSpeaker.
        controller.add(Uint8List.fromList('->'.codeUnits));
      }

      return _FakeSocket(
        stream: controller.stream,
        onWriteln: (_) {
          if (isFirstCall) {
            controller.add(Uint8List.fromList(configResponseText.codeUnits));
            controller.close();
          } else {
            controller.add(Uint8List.fromList('ok\n->'.codeUnits));
          }
        },
        onClose: () {
          if (!controller.isClosed) controller.close();
          return Future<void>.value();
        },
      );
    },
  );
}

SpeakerSetupService _failingService() {
  return SpeakerSetupService(
    envswitchDelay: Duration.zero,
    socketConnect: (host, port, {timeout}) =>
        Future.error(Exception('connection refused')),
  );
}

void main() {
  group('SpeakerDoctorPage', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final service = SpeakerSetupService(
        envswitchDelay: Duration.zero,
        socketConnect: (host, port, {timeout}) =>
            Completer<Socket>().future,
      );

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(speaker: _testSpeaker, setupService: service, apiService: _successApiService()),
      ));

      // Don't pumpAndSettle — loading spinners should appear before async completes.
      // Both the config and info sections show a spinner simultaneously.
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows config table after successful load', (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(speaker: _testSpeaker, setupService: service, apiService: _successApiService()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('margeServerUrl'), findsOneWidget);
      expect(find.text('https://api.example.com'), findsOneWidget);
      expect(find.text('isZeroconfEnabled'), findsOneWidget);
      expect(find.text('true'), findsOneWidget);
    });

    testWidgets('config table is inside a Card', (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(speaker: _testSpeaker, setupService: service, apiService: _successApiService()),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('config keys are selectable', (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(speaker: _testSpeaker, setupService: service, apiService: _successApiService()),
      ));
      await tester.pumpAndSettle();

      // Keys are rendered as SelectableText.
      final selectableTexts = tester.widgetList<SelectableText>(
        find.byType(SelectableText),
      );
      final texts = selectableTexts.map((w) => w.data).toList();
      expect(texts, contains('margeServerUrl'));
    });

    testWidgets('row with wrong value uses errorContainer color', (tester) async {
      final service = _buildService(configResponseText: _wrongConfigResponse);
      final appState = MyAppState();
      appState.config = const AppConfig(apiUrl: 'https://api.example.com');

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(speaker: _testSpeaker, setupService: service, apiService: _successApiService()),
        appState: appState,
      ));
      await tester.pumpAndSettle();

      // margeServerUrl is "https://old.server.com" but expected "https://api.example.com".
      // The key and value SelectableText widgets for that row get a non-null color
      // (onErrorContainer) applied to their style.
      final keyWidget = tester.widget<SelectableText>(
        find.widgetWithText(SelectableText, 'margeServerUrl'),
      );
      expect(keyWidget.style?.color, isNotNull);
    });

    testWidgets('shows error message on socket failure', (tester) async {
      final service = _failingService();

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(speaker: _testSpeaker, setupService: service, apiService: _successApiService()),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed'), findsWidgets);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('connect button disabled when apiUrl is empty', (tester) async {
      final service = _buildService(configResponseText: _configResponse);
      final appState = MyAppState();
      appState.config = const AppConfig(apiUrl: '');

      await tester.pumpWidget(
          _wrap(SpeakerDoctorPage(speaker: _testSpeaker, setupService: service, apiService: _successApiService()),
              appState: appState));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Connect speaker to Überböse-API'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('connect button enabled when apiUrl is set', (tester) async {
      final service = _buildService(configResponseText: _configResponse);
      final appState = MyAppState();
      appState.config = const AppConfig(apiUrl: 'https://api.example.com');

      await tester.pumpWidget(
          _wrap(SpeakerDoctorPage(speaker: _testSpeaker, setupService: service, apiService: _successApiService()),
              appState: appState));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Connect speaker to Überböse-API'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows EnvswitchLogView after successful connect',
        (tester) async {
      final service = _buildService(configResponseText: _configResponse);
      final appState = MyAppState();
      appState.config = const AppConfig(apiUrl: 'https://api.example.com');

      await tester.pumpWidget(
          _wrap(SpeakerDoctorPage(speaker: _testSpeaker, setupService: service, apiService: _successApiService()),
              appState: appState));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Connect speaker to Überböse-API'));
      await tester.tap(
          find.widgetWithText(FilledButton, 'Connect speaker to Überböse-API'));
      await tester.pumpAndSettle();

      expect(find.byType(EnvswitchLogView), findsOneWidget);
    });

    testWidgets('reboot card is shown', (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(speaker: _testSpeaker, setupService: service, apiService: _successApiService()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Reboot speaker'), findsOneWidget);
    });

    testWidgets('reboot button shows inline spinner while rebooting',
        (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
          speaker: _testSpeaker,
          setupService: service,
          apiService: _successApiService(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Reboot speaker'));
      await tester.tap(find.text('Reboot speaker'));
      await tester.pump();

      // Spinner inside AsyncFilledButton, no modal dialog.
      final button = tester.widget<AsyncFilledButton>(
        find.widgetWithText(AsyncFilledButton, 'Reboot speaker'),
      );
      expect(button.isLoading, isTrue);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Rebooting speaker…'), findsNothing);

      await tester.pumpAndSettle();
    });

    testWidgets('reboot button re-enables and shows snackbar on success',
        (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
          speaker: _testSpeaker,
          setupService: service,
          apiService: _successApiService(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Reboot speaker'));
      await tester.tap(find.text('Reboot speaker'));
      await tester.pumpAndSettle();

      expect(find.text('Speaker is rebooting…'), findsOneWidget);
      final button = tester.widget<AsyncFilledButton>(
        find.widgetWithText(AsyncFilledButton, 'Reboot speaker'),
      );
      expect(button.isLoading, isFalse);
    });

    testWidgets('reboot button shows AlertDialog on failure', (tester) async {
      int callCount = 0;
      final mixedService = SpeakerSetupService(
        envswitchDelay: Duration.zero,
        socketConnect: (host, port, {timeout}) async {
          callCount++;
          if (callCount == 1) {
            // First call: return config data for getSystemConfiguration.
            final controller = StreamController<Uint8List>();
            return _FakeSocket(
              stream: controller.stream,
              onWriteln: (_) {
                controller.add(
                    Uint8List.fromList(_configResponse.codeUnits));
                controller.close();
              },
              onClose: () {
                if (!controller.isClosed) controller.close();
                return Future<void>.value();
              },
            );
          }
          throw Exception('reboot connection refused');
        },
      );

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
          speaker: _testSpeaker,
          setupService: mixedService,
          apiService: _successApiService(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Reboot speaker'));
      await tester.tap(find.text('Reboot speaker'));
      await tester.pumpAndSettle();

      expect(find.text('Reboot failed'), findsOneWidget);
      final button = tester.widget<AsyncFilledButton>(
        find.widgetWithText(AsyncFilledButton, 'Reboot speaker'),
      );
      expect(button.isLoading, isFalse);
    });

    testWidgets('info card shows deviceID, type and accountId', (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
          speaker: _testSpeaker,
          setupService: service,
          apiService: _successApiService(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SelectableText, 'Device ID'), findsOneWidget);
      expect(find.widgetWithText(SelectableText, 'AABBCCDDEEFF'), findsOneWidget);
      expect(find.widgetWithText(SelectableText, 'Type'), findsOneWidget);
      expect(find.widgetWithText(SelectableText, 'SoundTouch 10'), findsOneWidget);
      expect(find.widgetWithText(SelectableText, 'Marge Account ID'), findsOneWidget);
      expect(find.widgetWithText(SelectableText, '1234567'), findsOneWidget);
    });

    testWidgets('info card shows fallback dash when accountId is null',
        (tester) async {
      final service = _buildService(configResponseText: _configResponse);
      final apiService = _FakeApiService((_) async => const SpeakerInfo(
            name: 'Test Speaker',
            type: 'SoundTouch 10',
            deviceId: 'AABBCCDDEEFF',
          ));

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
          speaker: _testSpeaker,
          setupService: service,
          apiService: apiService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('info card shows warning styling when accountId is empty',
        (tester) async {
      final service = _buildService(configResponseText: _configResponse);
      final apiService = _FakeApiService((_) async => const SpeakerInfo(
            name: 'Test Speaker',
            type: 'SoundTouch 10',
            deviceId: 'AABBCCDDEEFF',
          ));

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
          speaker: _testSpeaker,
          setupService: service,
          apiService: apiService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('info card shows no warning icon when accountId is set',
        (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
          speaker: _testSpeaker,
          setupService: service,
          apiService: _successApiService(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning), findsNothing);
    });

    testWidgets('info card shows error and retry on failure', (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
          speaker: _testSpeaker,
          setupService: service,
          apiService: _failingApiService(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load device info:'), findsOneWidget);
      expect(find.text('Retry'), findsWidgets);
    });

    testWidgets('link marge account card renders fields and button',
        (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
            speaker: _testSpeaker,
            setupService: service,
            apiService: _successApiService()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Link Marge Account'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Marge Account ID'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Auth Token'), findsOneWidget);
      expect(find.widgetWithText(AsyncFilledButton, 'Link Account'), findsOneWidget);
    });

    testWidgets('account id field is pre-populated from app config',
        (tester) async {
      final service = _buildService(configResponseText: _configResponse);
      final appState = MyAppState();
      appState.config = const AppConfig(accountId: 'my-account-id');

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
            speaker: _testSpeaker,
            setupService: service,
            apiService: _successApiService()),
        appState: appState,
      ));
      await tester.pumpAndSettle();

      final accountIdField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Marge Account ID'),
      );
      expect(accountIdField.controller?.text, 'my-account-id');
    });

    testWidgets('auth token field is pre-populated with auth123',
        (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
            speaker: _testSpeaker,
            setupService: service,
            apiService: _successApiService()),
      ));
      await tester.pumpAndSettle();

      final authTokenField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Auth Token'),
      );
      expect(authTokenField.controller?.text, 'auth123');
    });

    testWidgets('link account shows inline error when fields are empty',
        (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
            speaker: _testSpeaker,
            setupService: service,
            apiService: _successApiService()),
      ));
      await tester.pumpAndSettle();

      await tester
          .ensureVisible(find.widgetWithText(AsyncFilledButton, 'Link Account'));
      await tester.tap(find.widgetWithText(AsyncFilledButton, 'Link Account'));
      await tester.pump();

      expect(find.text('Account ID and auth token are required.'),
          findsOneWidget);
    });

    testWidgets(
        'link account shows snackbar and reloads info on success',
        (tester) async {
      int fetchInfoCount = 0;
      final apiService = _FakeApiService((_) async {
        fetchInfoCount++;
        return _testInfo;
      });
      bool setMargeAccountCalled = false;
      final service = _FakeSetupService(
        configResponseText: _configResponse,
        onSetMargeAccount: (ip, accountId, authToken) async {
          setMargeAccountCalled = true;
        },
      );

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
            speaker: _testSpeaker,
            setupService: service,
            apiService: apiService),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextField, 'Marge Account ID'), 'acc123');
      await tester.enterText(
          find.widgetWithText(TextField, 'Auth Token'), 'token456');
      await tester
          .ensureVisible(find.widgetWithText(AsyncFilledButton, 'Link Account'));
      await tester.tap(find.widgetWithText(AsyncFilledButton, 'Link Account'));
      await tester.pumpAndSettle();

      expect(setMargeAccountCalled, isTrue);
      expect(find.text('Marge account linked successfully.'), findsOneWidget);
      // fetchSpeakerInfo called once on init, once after successful link.
      expect(fetchInfoCount, 2);
    });

    testWidgets('link account shows inline error on failure', (tester) async {
      final service = _FakeSetupService(
        configResponseText: _configResponse,
        onSetMargeAccount: (ip, accountId, authToken) =>
            Future.error(Exception('HTTP 500')),
      );

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
            speaker: _testSpeaker,
            setupService: service,
            apiService: _successApiService()),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextField, 'Marge Account ID'), 'acc123');
      await tester.enterText(
          find.widgetWithText(TextField, 'Auth Token'), 'token456');
      await tester
          .ensureVisible(find.widgetWithText(AsyncFilledButton, 'Link Account'));
      await tester.tap(find.widgetWithText(AsyncFilledButton, 'Link Account'));
      await tester.pumpAndSettle();

      expect(find.textContaining('HTTP 500'), findsOneWidget);
    });

    testWidgets('account ID field blocks invalid characters',
        (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
            speaker: _testSpeaker,
            setupService: service,
            apiService: _successApiService()),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextField, 'Marge Account ID'), 'abc!@#123');

      final accountIdField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Marge Account ID'),
      );
      expect(accountIdField.controller?.text, 'abc123');
    });

    testWidgets('account ID field allows letters and digits',
        (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
            speaker: _testSpeaker,
            setupService: service,
            apiService: _successApiService()),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextField, 'Marge Account ID'), 'abcXYZ123');

      final accountIdField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Marge Account ID'),
      );
      expect(accountIdField.controller?.text, 'abcXYZ123');
    });

    testWidgets('account ID field rejects input beyond 42 characters',
        (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
            speaker: _testSpeaker,
            setupService: service,
            apiService: _successApiService()),
      ));
      await tester.pumpAndSettle();

      final longInput = 'a' * 50;
      await tester.enterText(
          find.widgetWithText(TextField, 'Marge Account ID'), longInput);

      final accountIdField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Marge Account ID'),
      );
      expect(accountIdField.controller?.text.length, 42);
    });

    testWidgets('link account shows error when account ID is shorter than 3 chars',
        (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(
            speaker: _testSpeaker,
            setupService: service,
            apiService: _successApiService()),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextField, 'Marge Account ID'), 'ab');
      await tester.enterText(
          find.widgetWithText(TextField, 'Auth Token'), 'token456');
      await tester
          .ensureVisible(find.widgetWithText(AsyncFilledButton, 'Link Account'));
      await tester.tap(find.widgetWithText(AsyncFilledButton, 'Link Account'));
      await tester.pump();

      expect(find.text('Account ID must be at least 3 characters.'),
          findsOneWidget);
    });
  });
}

/// A [SpeakerSetupService] that uses a real telnet socket fake for
/// getSystemConfiguration but routes setMargeAccount through a callback.
class _FakeSetupService extends SpeakerSetupService {
  final Future<void> Function(String ip, String accountId, String authToken)
      onSetMargeAccount;

  _FakeSetupService({
    required String configResponseText,
    required this.onSetMargeAccount,
  }) : super(
          envswitchDelay: Duration.zero,
          socketConnect: (host, port, {timeout}) async {
            final controller = StreamController<Uint8List>();
            return _FakeSocket(
              stream: controller.stream,
              onWriteln: (_) {
                controller
                    .add(Uint8List.fromList(configResponseText.codeUnits));
                controller.close();
              },
              onClose: () {
                if (!controller.isClosed) controller.close();
                return Future<void>.value();
              },
            );
          },
        );

  @override
  Future<void> setMargeAccount(
          String speakerIp, String accountId, String authToken) =>
      onSetMargeAccount(speakerIp, accountId, authToken);
}

class _FakeSocket extends Stream<Uint8List> implements Socket {
  final Stream<Uint8List> stream;
  final void Function(String) onWriteln;
  final Future<void> Function() onClose;

  _FakeSocket({
    required this.stream,
    required this.onWriteln,
    required this.onClose,
  });

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  void writeln([Object? object = '']) => onWriteln(object?.toString() ?? '');

  @override
  void write(Object? object) {}

  @override
  Future<void> flush() => Future<void>.value();

  @override
  Future<void> close() => onClose();

  @override
  void destroy() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
