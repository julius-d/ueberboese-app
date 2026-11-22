import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/device_event.dart';
import 'package:ueberboese_app/pages/device_events_page.dart';
import 'package:ueberboese_app/services/management_api_service.dart';

import 'device_events_page_test.mocks.dart';

@GenerateMocks([ManagementApiService])
void main() {
  group('DeviceEventsPage', () {
    late MockManagementApiService mockApiService;
    late MyAppState mockAppState;
    const testSpeaker = Speaker(
      id: '1',
      name: 'Test Speaker',
      emoji: '🔊',
      ipAddress: '192.168.1.100',
      type: 'SoundTouch 10',
      deviceId: 'device-123',
    );

    const testConfig = AppConfig(
      apiUrl: 'http://localhost:3000',
      accountId: 'test-account',
      mgmtUsername: 'testuser',
      mgmtPassword: 'testpass',
    );

    setUp(() {
      mockApiService = MockManagementApiService();
      mockAppState = MyAppState();
      mockAppState.updateConfig(testConfig);
    });

    Widget createWidgetUnderTest() {
      return ChangeNotifierProvider<MyAppState>.value(
        value: mockAppState,
        child: MaterialApp(
          home: DeviceEventsPage(
            speaker: testSpeaker,
            apiService: mockApiService,
          ),
        ),
      );
    }

    testWidgets('shows loading indicator initially', (
      WidgetTester tester,
    ) async {
      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => <DeviceEvent>[]);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays "No events found" when list is empty', (
      WidgetTester tester,
    ) async {
      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => <DeviceEvent>[]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('No events found'), findsOneWidget);
    });

    testWidgets('displays events list when data is loaded', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'volume': 50},
          monoTime: 12345,
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          type: 'volume-changed',
        ),
        DeviceEvent(
          data: {'playState': 'PLAY_STATE'},
          monoTime: 12346,
          time: DateTime.now().subtract(const Duration(hours: 2)),
          type: 'play-state-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('volume-changed'), findsOneWidget);
      expect(find.text('play-state-changed'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('displays error message and retry button on error', (
      WidgetTester tester,
    ) async {
      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => throw Exception('Failed to fetch device events: HTTP 500'),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Failed to load events'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('retry button reloads events', (WidgetTester tester) async {
      // First call fails
      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => throw Exception('Failed to fetch device events: HTTP 500'),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Failed to load events'), findsOneWidget);

      // Second call succeeds
      final testEvents = [
        DeviceEvent(
          data: {'volume': 50},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'volume-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('volume-changed'), findsOneWidget);
      expect(find.text('Failed to load events'), findsNothing);
    });

    testWidgets(
      'displays speaker emoji and name in app bar and Device Events title on page',
      (WidgetTester tester) async {
        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => <DeviceEvent>[]);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('🔊'), findsOneWidget);
        expect(find.text('Test Speaker'), findsOneWidget);
        expect(find.text('Device Events'), findsOneWidget);
      },
    );

    testWidgets('calls fetchDeviceEvents with correct parameters', (
      WidgetTester tester,
    ) async {
      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => <DeviceEvent>[]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      verify(
        mockApiService.fetchDeviceEvents(
          'http://localhost:3000',
          'device-123',
          'testuser',
          'testpass',
        ),
      ).called(1);
    });

    testWidgets('displays volume icon for volume events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'volume': 50},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'volume-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });

    testWidgets('displays play icon for playback events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'playState': 'PLAY_STATE'},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'play-state-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('displays source icon for source events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'source': 'SPOTIFY'},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'source-state-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.input), findsOneWidget);
    });

    testWidgets('displays speaker group icon for zone-state-changed events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {
            'masterDeviceId': 'AABBCCDDEEFF',
            'roles': [
              {'deviceId': 'AABBCCDDEEFF', 'role': 'MASTER'},
              {'deviceId': 'BBCCDDEEFF00', 'role': 'SLAVE'},
            ],
          },
          monoTime: 12345,
          time: DateTime.now(),
          type: 'zone-state-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.speaker_group), findsOneWidget);
    });

    testWidgets('displays shuffle icon for shuffle-state-changed events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'shuffle-state': 'SHUFFLE_ON'},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'shuffle-state-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shuffle), findsOneWidget);
    });

    testWidgets('displays settings icon for system events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'system-state-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('displays default icon for unknown events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'unknown-event-type',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.event), findsOneWidget);
    });

    testWidgets('formats timestamp as "Just now" for recent events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'volume': 50},
          monoTime: 12345,
          time: DateTime.now().subtract(const Duration(seconds: 30)),
          type: 'volume-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('formats timestamp as minutes ago', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'volume': 50},
          monoTime: 12345,
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          type: 'volume-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('5 minutes ago'), findsOneWidget);
    });

    testWidgets('displays event data summary', (WidgetTester tester) async {
      final testEvents = [
        DeviceEvent(
          data: {'volume': 50},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'volume-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Volume: 50'), findsOneWidget);
    });

    testWidgets('displays volume change with old and new values', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {
            'volume-change': [17, 22],
            'startTime': '2026-02-08T14:21:15.672788+00:00',
          },
          monoTime: 1703612394,
          time: DateTime.now(),
          type: 'volume-change',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Volume: 17 → 22'), findsOneWidget);
    });

    testWidgets(
      'displays volume change with first and last values for multi-step changes',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {
              'volume-change': [33, 32, 31, 30, 29, 28, 27, 26, 25, 24],
              'startTime': '2026-01-01T00:00:00.000000+00:00',
            },
            monoTime: 12345,
            time: DateTime.now(),
            type: 'volume-change',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Volume: 33 → 24'), findsOneWidget);
      },
    );

    testWidgets('displays volume change with single value', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {
            'volume-change': [30],
          },
          monoTime: 1703612394,
          time: DateTime.now(),
          type: 'volume-change',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Volume: 30'), findsOneWidget);
    });

    testWidgets('displays "No additional data" for empty event data', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'unknown-event',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('No additional data'), findsOneWidget);
    });

    testWidgets('displays play/pause summary for playpause-pressed events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'buttonId': 'PLAY_PAUSE', 'origin': 'ir-remote'},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'playpause-pressed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Play/Pause via ir-remote'), findsOneWidget);
    });

    testWidgets('displays album art for art-changed events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {
            'art-status': 'IMAGE_PRESENT',
            'art-uri': 'https://example.com/album-art.jpg',
          },
          monoTime: 1702908329,
          time: DateTime.now(),
          type: 'art-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify Image widget is present
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('displays skip next icon for skip-forward events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'skip-forward-pressed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.skip_next), findsOneWidget);
    });

    testWidgets('displays skip previous icon for skip-backward events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'skip-backward-pressed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.skip_previous), findsOneWidget);
    });

    testWidgets('displays volume off icon for mute events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'mute-pressed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.volume_off), findsOneWidget);
    });

    testWidgets('displays star icon for preset events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'preset-pressed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('displays heart icon for favorite events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'favorite-value': 'true'},
          monoTime: 1703310240,
          time: DateTime.now(),
          type: 'favorite-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('Marked as favorite'), findsOneWidget);
    });

    testWidgets('displays icon when art-uri is missing', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'art-status': 'IMAGE_PRESENT'},
          monoTime: 1702908329,
          time: DateTime.now(),
          type: 'art-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify icon is shown instead of image
      expect(find.byIcon(Icons.image), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('displays context info for playable events', (
      WidgetTester tester,
    ) async {
      // Base64 encoded XML with TUNEIN source
      const contentItemBase64 =
          'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiID8+CjxDb250ZW50SXRlbSBzb3VyY2U9IlRVTkVJTiIgdHlwZT0ic3RhdGlvbnVybCIgbG9jYXRpb249Ii92MS9wbGF5YmFjay9zdGF0aW9uL3M4MDA0NCIgaXNQcmVzZXRhYmxlPSJ0cnVlIj4KICAgIDxpdGVtTmFtZT5SYWRpbyBURUREWTwvaXRlbU5hbWU+CjwvQ29udGVudEl0ZW0+Cg==';

      final testEvents = [
        DeviceEvent(
          data: {
            'contentItem': contentItemBase64,
            'origin': 'device',
            'preset': '1',
          },
          monoTime: 1813254115,
          time: DateTime.now(),
          type: 'content-selected',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Should display context info with source, origin, and preset
      expect(find.textContaining('TUNEIN'), findsOneWidget);
      expect(find.textContaining('via device'), findsOneWidget);
      expect(find.textContaining('Preset 1'), findsOneWidget);
    });

    testWidgets('displays event with contentItem as playable', (
      WidgetTester tester,
    ) async {
      // Base64 encoded XML: <ContentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s80044" isPresetable="true"><itemName>Radio TEDDY</itemName></ContentItem>
      const contentItemBase64 =
          'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiID8+CjxDb250ZW50SXRlbSBzb3VyY2U9IlRVTkVJTiIgdHlwZT0ic3RhdGlvbnVybCIgbG9jYXRpb249Ii92MS9wbGF5YmFjay9zdGF0aW9uL3M4MDA0NCIgaXNQcmVzZXRhYmxlPSJ0cnVlIj4KICAgIDxpdGVtTmFtZT5SYWRpbyBURUREWTwvaXRlbU5hbWU+CjwvQ29udGVudEl0ZW0+Cg==';

      final testEvents = [
        DeviceEvent(
          data: {
            'contentItem': contentItemBase64,
            'origin': 'device',
            'preset': 'none',
          },
          monoTime: 1813254115,
          time: DateTime.now(),
          type: 'content-selected',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Should display as playable with title from contentItem
      expect(find.text('Radio TEDDY'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget); // Play button
      expect(find.byType(IconButton), findsOneWidget); // Has play button
    });

    testWidgets('displays item-started with empty data as regular event', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {
            'contentItem': '',
            'nowPlaying': {
              'track': {'text': ''},
              'artist': {'text': ''},
              'source': 'SPOTIFY',
            },
            'play-state': '',
          },
          monoTime: 1704633186,
          time: DateTime.now(),
          type: 'item-started',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Should display as regular event, not as playable
      expect(find.text('Playback stopped'), findsOneWidget);
      expect(
        find.byIcon(Icons.play_arrow),
        findsOneWidget,
      ); // Icon, not play button
      expect(find.byType(IconButton), findsNothing); // No play button
    });

    testWidgets(
      'displays Bluetooth device name and status for item-started Bluetooth events',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {
              'contentItem': '',
              'nowPlaying': {
                'track': {'text': ''},
                'artist': {'text': ''},
                'source': 'BLUETOOTH',
                'connectionStatusInfo': {
                  'deviceName': 'Test Phone',
                  'status': 'CONNECTING',
                },
              },
              'play-state': 'INVALID_PLAY_STATUS',
            },
            monoTime: 12345,
            time: DateTime.now(),
            type: 'item-started',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Bluetooth: Test Phone (Connecting)'), findsOneWidget);
        expect(find.byType(IconButton), findsNothing); // Not playable
      },
    );

    testWidgets(
      'displays Bluetooth device name without status when status is empty for item-started Bluetooth events',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {
              'contentItem': '',
              'nowPlaying': {
                'track': {'text': ''},
                'source': 'BLUETOOTH',
                'connectionStatusInfo': {
                  'deviceName': 'My Speaker',
                  'status': '',
                },
              },
              'play-state': '',
            },
            monoTime: 12345,
            time: DateTime.now(),
            type: 'item-started',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Bluetooth: My Speaker'), findsOneWidget);
      },
    );

    testWidgets('displays album name for item-started events with album info', (
      WidgetTester tester,
    ) async {
      // Base64 encoded XML with SPOTIFY source
      const contentItemBase64 =
          'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiID8+CjxDb250ZW50SXRlbSBzb3VyY2U9IlNQT1RJRlkiIHR5cGU9InRyYWNrIiBsb2NhdGlvbj0ic3BvdGlmeTp0cmFjazo0NklrbzdBNkhldGJBcDlZaWE2N1lwIiBpc1ByZXNldGFibGU9InRydWUiPgogICAgPGl0ZW1OYW1lPldlc3RlcmxhbmQ8L2l0ZW1OYW1lPgo8L0NvbnRlbnRJdGVtPgo=';

      final testEvents = [
        DeviceEvent(
          data: {
            'contentItem': contentItemBase64,
            'nowPlaying': {
              'track': {'text': 'Westerland'},
              'artist': {'text': 'Die Ärzte'},
              'album': {'text': 'Das Ist Nicht Die Ganze Wahrheit...'},
              'art': {'text': 'https://example.com/album-art.jpg'},
            },
            'play-state': 'PLAY_STATE',
          },
          monoTime: 1813254115,
          time: DateTime.now(),
          type: 'item-started',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Should display track, artist, and album
      expect(find.text('Westerland'), findsOneWidget);
      expect(find.text('Die Ärzte'), findsOneWidget);
      expect(find.text('Das Ist Nicht Die Ganze Wahrheit...'), findsOneWidget);
    });

    testWidgets('displays formatted play state for play-state-changed events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'play-state': 'PLAY_STATE'},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'play-state-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Playing'), findsOneWidget);
    });

    testWidgets('displays formatted play state for paused state', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'play-state': 'PAUSE_STATE'},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'play-state-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Paused'), findsOneWidget);
    });

    testWidgets('displays formatted play state for buffering state', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'play-state': 'BUFFERING_STATE'},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'play-state-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Buffering'), findsOneWidget);
    });

    testWidgets(
      'displays formatted source name for source-state-changed events',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {'source-state': 'SPOTIFY'},
            monoTime: 12345,
            time: DateTime.now(),
            type: 'source-state-changed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Source: Spotify'), findsOneWidget);
      },
    );

    testWidgets('displays formatted source name for TuneIn', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'source-state': 'TUNEIN'},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'source-state-changed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Source: TuneIn'), findsOneWidget);
    });

    testWidgets(
      'displays art status message for art-changed events with IMAGE_PRESENT',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {
              'art-status': 'IMAGE_PRESENT',
              'art-uri': 'https://example.com/album-art.jpg',
            },
            monoTime: 1702908329,
            time: DateTime.now(),
            type: 'art-changed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Album art updated'), findsOneWidget);
      },
    );

    testWidgets(
      'displays art status message for art-changed events with SHOW_DEFAULT_IMAGE',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {'art-status': 'SHOW_DEFAULT_IMAGE'},
            monoTime: 1702908329,
            time: DateTime.now(),
            type: 'art-changed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Using default image'), findsOneWidget);
      },
    );

    testWidgets(
      'displays balance icon and summary for balance-changed events',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {'balance': 0},
            monoTime: 12345,
            time: DateTime.now(),
            type: 'balance-changed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.tune), findsOneWidget);
        expect(find.text('Balance: 0'), findsOneWidget);
      },
    );

    testWidgets(
      'displays language icon and summary for language-changed events',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {'language': 'DISPLAY_LANGUAGE_GERMAN'},
            monoTime: 12345,
            time: DateTime.now(),
            type: 'language-changed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.language), findsOneWidget);
        expect(find.text('Language: German'), findsOneWidget);
      },
    );

    testWidgets(
      'displays settings icon and master device summary for masterdevice-changed events',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {'masterDeviceId': 'AABBCCDDEEFF'},
            monoTime: 12345,
            time: DateTime.now(),
            type: 'masterdevice-changed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.settings), findsOneWidget);
        expect(find.text('Master: AABBCCDDEEFF'), findsOneWidget);
      },
    );

    testWidgets('displays play icon for play-item events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'origin': 'device', 'preset': 'none'},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'play-item',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('Played from device'), findsOneWidget);
    });

    testWidgets('displays power icon and summary for power-pressed events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'buttonId': 'POWER', 'origin': 'console'},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'power-pressed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
      expect(find.text('Power via console'), findsOneWidget);
    });

    testWidgets(
      'displays preset number from buttonId for preset-pressed events',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {'buttonId': 'PRESET_6', 'origin': 'console'},
            monoTime: 12345,
            time: DateTime.now(),
            type: 'preset-pressed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Preset 6'), findsOneWidget);
      },
    );

    testWidgets(
      'displays shuffle on summary for shuffle-state-changed events',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {'shuffle-state': 'SHUFFLE_ON'},
            monoTime: 12345,
            time: DateTime.now(),
            type: 'shuffle-state-changed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Shuffle on'), findsOneWidget);
      },
    );

    testWidgets(
      'displays skip forward summary for skip-forward-pressed events',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {},
            monoTime: 12345,
            time: DateTime.now(),
            type: 'skip-forward-pressed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Skip forward'), findsOneWidget);
      },
    );

    testWidgets(
      'displays skip backward summary for skip-backward-pressed events',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {},
            monoTime: 12345,
            time: DateTime.now(),
            type: 'skip-backward-pressed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Skip backward'), findsOneWidget);
      },
    );

    testWidgets(
      'displays system state summary for system-state-changed events',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {'system-state': 'Standby'},
            monoTime: 12345,
            time: DateTime.now(),
            type: 'system-state-changed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('System: Standby'), findsOneWidget);
      },
    );

    testWidgets(
      'displays master device id and device count for zone-state-changed events with multiple devices',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {
              'masterDeviceId': 'MASTER000001',
              'roles': [
                {'deviceId': 'MASTER000001', 'role': 'MASTER'},
                {'deviceId': 'SLAVE0000001', 'role': 'SLAVE'},
              ],
            },
            monoTime: 12345,
            time: DateTime.now(),
            type: 'zone-state-changed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Master: MASTER000001 (2 devices)'), findsOneWidget);
      },
    );

    testWidgets(
      'displays master device id without count for zone-state-changed events with single device',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {
              'masterDeviceId': 'MASTER000001',
              'roles': [
                {'deviceId': 'MASTER000001', 'role': 'MASTER'},
              ],
            },
            monoTime: 12345,
            time: DateTime.now(),
            type: 'zone-state-changed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Master: MASTER000001'), findsOneWidget);
      },
    );

    testWidgets(
      'displays "Zone disbanded" for zone-state-changed events with no master',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {'masterDeviceId': '', 'roles': <Map<String, String>>[]},
            monoTime: 12345,
            time: DateTime.now(),
            type: 'zone-state-changed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Zone disbanded'), findsOneWidget);
      },
    );

    testWidgets('displays thumb up icon and summary for like-pressed events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'buttonId': 'THUMBS_UP', 'origin': 'ir-remote'},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'like-pressed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
      expect(find.text('Like via ir-remote'), findsOneWidget);
    });

    testWidgets(
      'displays thumb down icon and summary for dislike-pressed events',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {'buttonId': 'THUMBS_DOWN', 'origin': 'ir-remote'},
            monoTime: 12345,
            time: DateTime.now(),
            type: 'dislike-pressed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.thumb_down), findsOneWidget);
        expect(find.text('Dislike via ir-remote'), findsOneWidget);
      },
    );

    testWidgets('displays AUX icon and summary for aux-pressed events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'buttonId': 'AUX_INPUT', 'origin': 'ir-remote'},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'aux-pressed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings_input_component), findsOneWidget);
      expect(find.text('AUX via ir-remote'), findsOneWidget);
    });

    testWidgets(
      'displays star icon and preset names for presets-changed events',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {
              'presets': [
                {'id': 'P1', 'name': 'Preset One', 'contentItem': ''},
                {'id': 'P2', 'name': 'Preset Two', 'contentItem': ''},
                {'id': 'P3', 'name': 'Preset Three', 'contentItem': ''},
              ],
            },
            monoTime: 12345,
            time: DateTime.now(),
            type: 'presets-changed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(
          find.text(
            'P1: Preset One \u2013 P2: Preset Two \u2013 P3: Preset Three',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays fallback summary for presets-changed event with no presets',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {'presets': <dynamic>[]},
            monoTime: 12345,
            time: DateTime.now(),
            type: 'presets-changed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.text('Presets updated'), findsOneWidget);
      },
    );

    testWidgets(
      'displays equalizer icon and bass value for bass-changed events',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {'bass': -1},
            monoTime: 12345,
            time: DateTime.now(),
            type: 'bass-changed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.equalizer), findsOneWidget);
        expect(find.text('Bass: -1'), findsOneWidget);
      },
    );

    testWidgets(
      'displays clock icon and timezone/format for clock-changed events',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {
              'brightness': 100,
              'enabled': 'true',
              'timeformat': 24,
              'timezone': 'Europe/Berlin',
              'useroffset': 0,
              'usertime': 0,
            },
            monoTime: 12345,
            time: DateTime.now(),
            type: 'clock-changed',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.access_time), findsOneWidget);
        expect(
          find.text(
            'Europe/Berlin • 24h • Brightness: 100 • Display: on • Offset: 0 • User time: 0',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('displays pause icon and origin for pause-pressed events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'buttonId': 'PAUSE', 'origin': 'gabbo'},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'pause-pressed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.text('Pause via gabbo'), findsOneWidget);
    });

    testWidgets(
      'displays star icon and preset/origin for preset-assigned events',
      (WidgetTester tester) async {
        final testEvents = [
          DeviceEvent(
            data: {'preset': 'P1', 'origin': 'device'},
            monoTime: 12345,
            time: DateTime.now(),
            type: 'preset-assigned',
          ),
        ];

        when(
          mockApiService.fetchDeviceEvents(any, any, any, any),
        ).thenAnswer((_) async => testEvents);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.text('P1 assigned via device'), findsOneWidget);
      },
    );

    testWidgets('displays stop icon and origin for stop-pressed events', (
      WidgetTester tester,
    ) async {
      final testEvents = [
        DeviceEvent(
          data: {'buttonId': 'STOP', 'origin': 'gabbo'},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'stop-pressed',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.text('Stop via gabbo'), findsOneWidget);
    });

    testWidgets('sorts events by newest first', (WidgetTester tester) async {
      final now = DateTime.now();
      final testEvents = [
        DeviceEvent(
          data: {'volume': 30},
          monoTime: 12345,
          time: now.subtract(const Duration(hours: 2)),
          type: 'old-event',
        ),
        DeviceEvent(
          data: {'volume': 50},
          monoTime: 12347,
          time: now,
          type: 'newest-event',
        ),
        DeviceEvent(
          data: {'volume': 40},
          monoTime: 12346,
          time: now.subtract(const Duration(hours: 1)),
          type: 'middle-event',
        ),
      ];

      when(
        mockApiService.fetchDeviceEvents(any, any, any, any),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find all ListTile widgets
      final listTiles = find.byType(ListTile);
      expect(listTiles, findsNWidgets(3));

      // Verify the order: newest should be first
      expect(find.text('newest-event'), findsOneWidget);
      expect(find.text('middle-event'), findsOneWidget);
      expect(find.text('old-event'), findsOneWidget);

      // The newest event should appear before the older ones in the widget tree
      final newestEventFinder = find.text('newest-event');
      final oldestEventFinder = find.text('old-event');

      expect(
        tester.getTopLeft(newestEventFinder).dy <
            tester.getTopLeft(oldestEventFinder).dy,
        isTrue,
        reason: 'Newest event should be displayed before oldest event',
      );
    });
  });
}
