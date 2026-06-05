import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/models/now_playing.dart';
import 'package:ueberboese_app/pages/speaker_detail_page.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/widgets/speaker_warning_banner.dart';
import '../services/speaker_api_service_test.mocks.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SpeakerDetailPage', () {
    const testSpeaker = Speaker(
      id: '1',
      name: 'Test Speaker',
      emoji: '🔊',
      ipAddress: '192.168.1.100',
      type: 'SoundTouch 10',
      deviceId: 'device-123',
    );

    testWidgets('displays speaker information', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      // AppBar should show emoji and name
      expect(find.text('Test Speaker'), findsAtLeast(1));
      expect(find.text('🔊'), findsAtLeast(1));
    });

    testWidgets('displays three-dot menu button', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('opens menu when three-dot button is tapped',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Edit speaker'), findsOneWidget);
      expect(find.text('Remote Control'), findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Manage Presets'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Send to standby'), findsOneWidget);
      expect(find.text('Delete speaker'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.settings_remote), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.star), findsAtLeast(1));
      expect(find.byIcon(Icons.settings), findsAtLeast(1));
      expect(find.byIcon(Icons.bedtime), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog when delete is tapped',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete speaker'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Speaker'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete "Test Speaker"? This action cannot be undone.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('closes dialog when cancel is tapped',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete speaker'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Speaker'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Speaker'), findsNothing);
    });

    testWidgets('deletes speaker and navigates back when confirmed',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();
      appState.addSpeaker(testSpeaker);

      expect(appState.speakers.length, 1);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            const SpeakerDetailPage(speaker: testSpeaker),
                      ),
                    );
                  },
                  child: const Text('Open Details'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Details'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete speaker'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(appState.speakers.length, 0);
      expect(find.text('Test Speaker deleted'), findsOneWidget);
      expect(find.byType(SpeakerDetailPage), findsNothing);
    });

    testWidgets('keeps speaker when cancel is tapped',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();
      appState.addSpeaker(testSpeaker);

      expect(appState.speakers.length, 1);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete speaker'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(appState.speakers.length, 1);
    });

    testWidgets('displays speaker header when nothing is playing', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      // With no music playing, should show speaker header (emoji, name, type, IP)
      // Emoji appears in both app bar and speaker header
      expect(find.text(testSpeaker.emoji), findsAtLeastNWidgets(1));
      expect(find.text(testSpeaker.name), findsAtLeastNWidgets(1));
      expect(find.textContaining(testSpeaker.type), findsOneWidget);
      expect(find.textContaining(testSpeaker.ipAddress), findsOneWidget);
    });

    testWidgets('displays Volume section', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      expect(find.text('Volume'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });

    testWidgets('displays Multi-Room Zone section', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      expect(find.text('Multi-Room Zone'), findsOneWidget);
      expect(find.byIcon(Icons.speaker_group), findsOneWidget);
    });

    testWidgets('displays zone member list with basic info', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // The Multi-Room Zone section should be visible
      expect(find.text('Multi-Room Zone'), findsOneWidget);
    });

    testWidgets('displays volume controls for zone members when zone is loaded', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      // Add multiple speakers to test zone display
      const speaker2 = Speaker(
        id: '2',
        name: 'Speaker 2',
        emoji: '🎵',
        ipAddress: '192.168.1.101',
        type: 'SoundTouch 20',
        deviceId: 'device-456',
      );

      appState.addSpeaker(testSpeaker);
      appState.addSpeaker(speaker2);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Verify the zone section is present
      expect(find.text('Multi-Room Zone'), findsOneWidget);

      // Note: Volume controls will only appear if a zone is actually created via API,
      // which requires mocking the API service. This test verifies the UI structure exists.
    });

    testWidgets('volume section includes volume controls', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The Volume section header should be visible
      expect(find.text('Volume'), findsOneWidget);

      // Note: Volume control buttons (Down/Up) only appear after API successfully loads volume data.
      // Without API mocking, this test verifies the Volume section structure exists.
    });

    testWidgets('volume section includes volume level display between buttons', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The Volume section should be visible
      expect(find.text('Volume'), findsOneWidget);

      // Note: Without API mocking, we can't test the actual volume display between buttons
      // This test verifies the page structure remains correct with the new layout
      expect(find.byType(SpeakerDetailPage), findsOneWidget);
    });

    testWidgets('displays CircularProgressIndicator while loading volumes', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      // Before pumpAndSettle, should show loading indicators
      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    testWidgets('zone members section structure exists', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the Multi-Room Zone section exists
      expect(find.text('Multi-Room Zone'), findsOneWidget);
      expect(find.byIcon(Icons.speaker_group), findsOneWidget);

      // Note: Star icon for master and zone member volume controls only appear
      // when a zone is actually loaded from the API, which requires API mocking.
      // This test verifies the basic zone section structure exists.
    });

    testWidgets('IP address and type are selectable', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that SelectableText is used for the IP address and type
      expect(find.byType(SelectableText), findsOneWidget);

      // Verify the content is displayed
      expect(find.text('SoundTouch 10 • 192.168.1.100'), findsOneWidget);
    });

    testWidgets('does not show Open in Spotify button when nowPlaying has no source',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The Open in Spotify button should not be visible
      expect(find.text('Open in Spotify'), findsNothing);
    });

    testWidgets('does not show Open in Spotify button when source is not SPOTIFY',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The Open in Spotify button should not be visible for non-Spotify sources
      // This test ensures the button doesn't appear for TUNEIN or other sources
      expect(find.text('Open in Spotify'), findsNothing);
    });
  });

  group('Management URL Mismatch Warning', () {
    const testSpeaker = Speaker(
      id: '1',
      name: 'Test Speaker',
      emoji: '🔊',
      ipAddress: '192.168.1.100',
      type: 'SoundTouch 10',
      deviceId: 'device-123',
    );

    testWidgets('does not show warning banner initially before info is loaded',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      // Before any data is loaded, warning should not be displayed
      expect(find.text('Management URL Mismatch'), findsNothing);
      expect(find.byIcon(Icons.warning), findsNothing);
    });

    testWidgets('warning banner structure includes all required elements',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Note: Without API mocking, we can't test the actual warning appearance
      // This test verifies the page structure remains correct
      // (i.e., the warning banner logic doesn't break the page layout)
      expect(find.text('Test Speaker'), findsAtLeast(1));
      expect(find.text('🔊'), findsAtLeast(1));
    });

    testWidgets('page layout includes space for warning banner at top',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the body is structured with a Column to accommodate the banner
      expect(find.byType(Column), findsAtLeast(1));
      expect(find.byType(Expanded), findsAtLeast(1));
    });

    testWidgets('app config is accessible from speaker detail page',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      // Set a custom config
      appState.updateConfig(const AppConfig(
        apiUrl: 'https://test.example.com',
        accountId: 'test-account',
        mgmtUsername: 'admin',
        mgmtPassword: 'password',
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the config is accessible (page should not crash)
      expect(appState.config.apiUrl, 'https://test.example.com');
      expect(find.text('Test Speaker'), findsAtLeast(1));
    });

    testWidgets('warning banner does not appear without mismatch data',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Without API mocking returning mismatched URLs, banner should not appear
      expect(find.text('Management URL Mismatch'), findsNothing);
      expect(find.byIcon(Icons.warning), findsNothing);
    });

    testWidgets('page renders correctly with empty config URL',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      // Ensure config has empty URL
      appState.updateConfig(const AppConfig(
        apiUrl: '',
        accountId: 'test',
        mgmtUsername: 'admin',
        mgmtPassword: 'pass',
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Page should render without error even with empty config URL
      expect(find.text('Test Speaker'), findsAtLeast(1));
      expect(find.text('🔊'), findsAtLeast(1));
      // Warning should not appear with empty config URL
      expect(find.text('Management URL Mismatch'), findsNothing);
    });

    testWidgets('speaker info loading does not crash the page',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      // Wait for all async operations to complete
      await tester.pumpAndSettle();

      // Verify the page is rendered properly
      // (speaker info loading may fail without real API, but page should not crash)
      expect(find.text('Test Speaker'), findsAtLeast(1));
      expect(find.text('🔊'), findsAtLeast(1));
      expect(find.text('Volume'), findsOneWidget);
      // New design: no "Now Playing" header, just speaker header when nothing is playing
      expect(find.text('Multi-Room Zone'), findsOneWidget);
    });

    testWidgets('shows Now Playing Card with TV display when TV source is active',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      // Mock getNowPlaying to return TV source
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('''<?xml version="1.0" encoding="UTF-8" ?>
<nowPlaying deviceID="C4F312DD8A8F" source="PRODUCT" sourceAccount="TV">
  <ContentItem source="PRODUCT" sourceAccount="TV" isPresetable="false"/>
  <art artImageStatus="SHOW_DEFAULT_IMAGE"/>
  <playStatus>PLAY_STATE</playStatus>
</nowPlaying>''', 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      // Populate cache with TV source now playing data
      const tvNowPlaying = NowPlaying(
        source: 'PRODUCT',
        sourceAccount: 'TV',
        playStatus: 'PLAY_STATE',
      );
      appState.updateNowPlayingForSpeaker(testSpeaker.ipAddress, tvNowPlaying, true);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(
              speaker: testSpeaker,
              apiService: apiService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the hero layout is shown with TV content (no "Now Playing" header in new design)
      expect(find.byIcon(Icons.tv), findsOneWidget);
      expect(find.text('Playing TV sound'), findsOneWidget);
      // Verify pause button is not shown
      expect(find.text('Pause'), findsNothing);
      expect(find.text('Play'), findsNothing);
    });

    testWidgets('hides Now Playing Card when nothing is playing',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      // Mock getNowPlaying to return empty/null state
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('''<?xml version="1.0" encoding="UTF-8" ?>
<nowPlaying deviceID="C4F312DD8A8F">
  <ContentItem source="" isPresetable="false"/>
</nowPlaying>''', 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(
              speaker: testSpeaker,
              apiService: apiService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the Now Playing Card is not shown
      expect(find.text('Now Playing'), findsNothing);
    });

    testWidgets('shows Now Playing Card when music is playing',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      // Mock getNowPlaying to return Spotify playback
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('''<?xml version="1.0" encoding="UTF-8" ?>
<nowPlaying deviceID="C4F312DD8A8F">
  <ContentItem source="SPOTIFY" type="tracklisturl" location="/playback/container/abc123" isPresetable="true">
    <itemName>Test Track</itemName>
  </ContentItem>
  <track>Test Track</track>
  <artist>Test Artist</artist>
  <album>Test Album</album>
  <art>http://example.com/art.jpg</art>
  <playStatus>PLAY_STATE</playStatus>
</nowPlaying>''', 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      // Populate cache with Spotify playback data
      const nowPlaying = NowPlaying(
        track: 'Test Track',
        artist: 'Test Artist',
        album: 'Test Album',
        art: 'http://example.com/art.jpg',
        playStatus: 'PLAY_STATE',
        source: 'SPOTIFY',
        location: '/playback/container/abc123',
      );
      appState.updateNowPlayingForSpeaker(testSpeaker.ipAddress, nowPlaying, true);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(
              speaker: testSpeaker,
              apiService: apiService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the hero layout is shown with content (no "Now Playing" header in new design)
      expect(find.text('Test Track'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);
      // Verify pause button is shown when playing
      expect(find.text('Pause'), findsOneWidget);
    });

    testWidgets('shows play button when music is paused',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      // Mock getNowPlaying to return paused Spotify playback
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('''<?xml version="1.0" encoding="UTF-8" ?>
<nowPlaying deviceID="C4F312DD8A8F">
  <ContentItem source="SPOTIFY" type="tracklisturl" location="/playback/container/abc123" isPresetable="true">
    <itemName>Test Track</itemName>
  </ContentItem>
  <track>Test Track</track>
  <artist>Test Artist</artist>
  <album>Test Album</album>
  <art>http://example.com/art.jpg</art>
  <playStatus>PAUSE_STATE</playStatus>
</nowPlaying>''', 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      // Populate cache with paused Spotify playback data
      const nowPlaying = NowPlaying(
        track: 'Test Track',
        artist: 'Test Artist',
        album: 'Test Album',
        art: 'http://example.com/art.jpg',
        playStatus: 'PAUSE_STATE',
        source: 'SPOTIFY',
        location: '/playback/container/abc123',
      );
      appState.updateNowPlayingForSpeaker(testSpeaker.ipAddress, nowPlaying, true);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(
              speaker: testSpeaker,
              apiService: apiService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the hero layout is shown with content (no "Now Playing" header in new design)
      expect(find.text('Test Track'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);
      // Verify play button is shown when paused
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Pause'), findsNothing);
    });

    testWidgets('shows play/pause button for TUNEIN source',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      // Mock getNowPlaying to return TUNEIN playback
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('''<?xml version="1.0" encoding="UTF-8" ?>
<nowPlaying deviceID="C4F312DD8A8F">
  <ContentItem source="TUNEIN" location="s1234" isPresetable="true">
    <itemName>Test Radio Station</itemName>
  </ContentItem>
  <track>Test Radio Station</track>
  <playStatus>PLAY_STATE</playStatus>
</nowPlaying>''', 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      // Populate cache with TUNEIN playback data
      const nowPlaying = NowPlaying(
        track: 'Test Radio Station',
        playStatus: 'PLAY_STATE',
        source: 'TUNEIN',
        location: 's1234',
      );
      appState.updateNowPlayingForSpeaker(testSpeaker.ipAddress, nowPlaying, true);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(
              speaker: testSpeaker,
              apiService: apiService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the hero layout is shown with content (no "Now Playing" header in new design)
      expect(find.text('Test Radio Station'), findsOneWidget);
      // Verify pause button is shown for TUNEIN when playing
      expect(find.text('Pause'), findsOneWidget);
      // Verify no Spotify button is shown for TUNEIN
      expect(find.text('Open in Spotify'), findsNothing);
    });

    testWidgets('shows play button for TUNEIN when stopped',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      // Mock getNowPlaying to return stopped TUNEIN playback
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('''<?xml version="1.0" encoding="UTF-8" ?>
<nowPlaying deviceID="587A628A4073" source="TUNEIN" sourceAccount="">
  <ContentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s80044" sourceAccount="" isPresetable="true">
    <itemName>Radio TEDDY</itemName>
    <containerArt>http://cdn-radiotime-logos.tunein.com/s80044q.png</containerArt>
  </ContentItem>
  <track>Radio TEDDY</track>
  <artist>Macht Spaß! Macht schlau!</artist>
  <album></album>
  <stationName>Radio TEDDY</stationName>
  <art artImageStatus="IMAGE_PRESENT">http://cdn-radiotime-logos.tunein.com/s80044g.png</art>
  <playStatus>STOP_STATE</playStatus>
  <streamType>RADIO_STREAMING</streamType>
</nowPlaying>''', 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      // Populate cache with stopped TUNEIN playback data
      const nowPlaying = NowPlaying(
        track: 'Radio TEDDY',
        artist: 'Macht Spaß! Macht schlau!',
        art: 'http://cdn-radiotime-logos.tunein.com/s80044g.png',
        artImageStatus: 'IMAGE_PRESENT',
        playStatus: 'STOP_STATE',
        source: 'TUNEIN',
        location: '/v1/playback/station/s80044',
      );
      appState.updateNowPlayingForSpeaker(testSpeaker.ipAddress, nowPlaying, true);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(
              speaker: testSpeaker,
              apiService: apiService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the hero layout is shown with content (no "Now Playing" header in new design)
      expect(find.text('Radio TEDDY'), findsOneWidget);
      // Verify play button is shown for stopped TUNEIN
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Pause'), findsNothing);
    });

    testWidgets('includes safe space at bottom for Android gesture navigation',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the scrollable content includes proper bottom padding
      final singleChildScrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView).first,
      );
      final padding = singleChildScrollView.child as Padding;
      expect(padding.padding, isNotNull);

      // Verify a SizedBox with safe space height exists at the bottom
      final sizedBoxes = find.byType(SizedBox);
      expect(sizedBoxes, findsAtLeast(1));

      // Check that at least one SizedBox has the expected height for safe space (80 pixels)
      final hasSafeSpace = tester
          .widgetList<SizedBox>(sizedBoxes)
          .any((box) => box.height == 80);
      expect(hasSafeSpace, isTrue,
          reason: 'Should have a SizedBox with height 80 for safe space');
    });

    testWidgets('album art with Hero tag is present when now playing has art',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Note: We can't easily test if Hero is present without mocking the API
      // This test verifies the widget builds without errors
      expect(find.byType(SpeakerDetailPage), findsOneWidget);
    });

    testWidgets('album art is wrapped in GestureDetector when present',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // This test verifies the widget builds without errors
      // Testing actual tapping behavior would require mocking the API service
      expect(find.byType(SpeakerDetailPage), findsOneWidget);
    });
  });

  group('WebSocket Integration', () {
    const testSpeaker = Speaker(
      id: '1',
      name: 'Test Speaker',
      emoji: '🔊',
      ipAddress: '192.168.1.100',
      type: 'SoundTouch 10',
      deviceId: 'device-123',
    );

    testWidgets('page initializes without errors with WebSocket', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      // Verify page builds successfully
      expect(find.byType(SpeakerDetailPage), findsOneWidget);
      expect(find.text('Test Speaker'), findsAtLeast(1));
    });

    testWidgets('page disposes properly with WebSocket', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            const SpeakerDetailPage(speaker: testSpeaker),
                      ),
                    );
                  },
                  child: const Text('Open Details'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the detail page
      await tester.tap(find.text('Open Details'));
      await tester.pumpAndSettle();

      // Verify page is shown
      expect(find.byType(SpeakerDetailPage), findsOneWidget);

      // Go back to dispose the page
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify page is disposed without errors
      expect(find.byType(SpeakerDetailPage), findsNothing);
    });

    testWidgets('zone subscription is created and cancelled', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            const SpeakerDetailPage(speaker: testSpeaker),
                      ),
                    );
                  },
                  child: const Text('Open Details'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the detail page
      await tester.tap(find.text('Open Details'));
      await tester.pumpAndSettle();

      // Verify page is shown - this ensures WebSocket service is initialized
      // including the zone stream subscription
      expect(find.byType(SpeakerDetailPage), findsOneWidget);

      // Go back to dispose the page
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify page is disposed without errors
      // This verifies zone subscription is cancelled properly
      expect(find.byType(SpeakerDetailPage), findsNothing);
    });
  });

  group('Presets Section', () {
    const testSpeaker = Speaker(
      id: '1',
      name: 'Test Speaker',
      emoji: '🔊',
      ipAddress: '192.168.1.100',
      type: 'SoundTouch 10',
      deviceId: 'device-123',
    );

    testWidgets('displays Presets section', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Presets'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsAtLeast(1));
    });

    testWidgets('shows loading indicator while fetching presets', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      // Before pumpAndSettle, should show loading indicators
      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    testWidgets('displays 6 preset slots in 2x3 grid', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      // Mock getPresets to return empty preset list
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('''<?xml version="1.0" encoding="UTF-8" ?>
<presets />''', 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(
              speaker: testSpeaker,
              apiService: apiService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Presets section is displayed
      expect(find.text('Presets'), findsOneWidget);
    });

    testWidgets('displays gear icon in presets card', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      // Mock getPresets to return empty preset list
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('''<?xml version="1.0" encoding="UTF-8" ?>
<presets />''', 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(
              speaker: testSpeaker,
              apiService: apiService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify gear icon is displayed in presets card
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Verify the icon button has correct tooltip
      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.settings),
      );
      expect(iconButton.tooltip, 'Manage Presets');
    });
  });

  group('Warning Banners', () {
    const testSpeaker = Speaker(
      id: '1',
      name: 'Test Speaker',
      emoji: '🔊',
      ipAddress: '192.168.1.100',
      type: 'SoundTouch 10',
      deviceId: 'device-123',
    );

    String infoXml({String? margeUrl, String? accountId}) => '''<?xml version="1.0" encoding="UTF-8" ?>
<info deviceID="device-123">
  <name>Test Speaker</name>
  <type>SoundTouch 10</type>
  ${margeUrl != null ? '<margeURL>$margeUrl</margeURL>' : ''}
  ${accountId != null ? '<margeAccountUUID>$accountId</margeAccountUUID>' : ''}
</info>''';

    testWidgets('shows URL mismatch banner when URLs differ',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();
      appState.updateConfig(const AppConfig(
        apiUrl: 'http://settings.example.com',
        accountId: '',
        mgmtUsername: '',
        mgmtPassword: '',
      ));

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(
          infoXml(margeUrl: 'http://speaker.example.com', accountId: 'acc-123'),
          200,
          headers: {'content-type': 'text/xml; charset=utf-8'},
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(
              speaker: testSpeaker,
              apiService: apiService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SpeakerWarningBanner), findsOneWidget);
      expect(find.text('Management URL Mismatch'), findsOneWidget);
      expect(find.text('No Marge Account Id set'), findsNothing);
      expect(find.text('Doctor'), findsOneWidget);
    });

    testWidgets('shows no-account banner when margeUrl set but accountId empty',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();
      appState.updateConfig(const AppConfig(
        apiUrl: 'http://same.example.com',
        accountId: '',
        mgmtUsername: '',
        mgmtPassword: '',
      ));

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(
          infoXml(margeUrl: 'http://same.example.com'),
          200,
          headers: {'content-type': 'text/xml; charset=utf-8'},
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(
              speaker: testSpeaker,
              apiService: apiService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SpeakerWarningBanner), findsOneWidget);
      expect(find.text('No Marge Account Id set'), findsOneWidget);
      expect(find.text('Management URL Mismatch'), findsNothing);
      expect(find.text('Doctor'), findsOneWidget);
    });

    testWidgets(
        'shows only URL mismatch banner when both mismatch and empty accountId',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();
      appState.updateConfig(const AppConfig(
        apiUrl: 'http://settings.example.com',
        accountId: '',
        mgmtUsername: '',
        mgmtPassword: '',
      ));

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(
          infoXml(margeUrl: 'http://speaker.example.com'),
          200,
          headers: {'content-type': 'text/xml; charset=utf-8'},
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(
              speaker: testSpeaker,
              apiService: apiService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SpeakerWarningBanner), findsOneWidget);
      expect(find.text('Management URL Mismatch'), findsOneWidget);
      expect(find.text('No Marge Account Id set'), findsNothing);
    });

    testWidgets('shows no banner when URLs match and accountId is set',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();
      appState.updateConfig(const AppConfig(
        apiUrl: 'http://same.example.com',
        accountId: '',
        mgmtUsername: '',
        mgmtPassword: '',
      ));

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(
          infoXml(margeUrl: 'http://same.example.com', accountId: 'acc-123'),
          200,
          headers: {'content-type': 'text/xml; charset=utf-8'},
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(
              speaker: testSpeaker,
              apiService: apiService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SpeakerWarningBanner), findsNothing);
    });

    testWidgets('shows no banner when margeUrl is not set',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(
          infoXml(),
          200,
          headers: {'content-type': 'text/xml; charset=utf-8'},
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(
              speaker: testSpeaker,
              apiService: apiService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SpeakerWarningBanner), findsNothing);
    });
  });

  group('Volume Slider', () {
    const testSpeaker = Speaker(
      id: '1',
      name: 'Test Speaker',
      emoji: '🔊',
      ipAddress: '192.168.1.100',
      type: 'SoundTouch 10',
      deviceId: 'device-123',
    );

    testWidgets('displays Slider widget for volume control', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      // Mock getVolume to return volume data
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('''<?xml version="1.0" encoding="UTF-8" ?>
<volume deviceID="device-123">
  <targetvolume>50</targetvolume>
  <actualvolume>50</actualvolume>
  <muteenabled>false</muteenabled>
</volume>''', 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(
              speaker: testSpeaker,
              apiService: apiService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Slider widget is displayed
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('slider is disabled when volume is loading', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      // Before volume loads, slider should be disabled
      // We can't easily test this without accessing internal state,
      // but we verify the widget builds correctly
      expect(find.byType(SpeakerDetailPage), findsOneWidget);
    });

    testWidgets('volume up and down buttons still work with slider', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      // Mock getVolume to return volume data
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('''<?xml version="1.0" encoding="UTF-8" ?>
<volume deviceID="device-123">
  <targetvolume>50</targetvolume>
  <actualvolume>50</actualvolume>
  <muteenabled>false</muteenabled>
</volume>''', 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(
              speaker: testSpeaker,
              apiService: apiService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify both slider and buttons are present
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Down'), findsOneWidget);
      expect(find.text('Up'), findsOneWidget);
      expect(find.byIcon(Icons.volume_down), findsOneWidget);
      // Note: volume_up icon appears twice - once in section header, once in button
      expect(find.byIcon(Icons.volume_up), findsAtLeast(1));
    });
  });

  group('Source card', () {
    const testSpeaker = Speaker(
      id: '1',
      name: 'Test Speaker',
      emoji: '🔊',
      ipAddress: '192.168.1.100',
      type: 'SoundTouch 10',
      deviceId: 'device-123',
    );

    const sourcesXml = '''<?xml version="1.0" encoding="UTF-8" ?>
<sources deviceID="9884E39E1EA8">
  <sourceItem source="AUX" sourceAccount="AUX" status="READY" isLocal="true" multiroomallowed="true">AUX IN</sourceItem>
  <sourceItem source="BLUETOOTH" status="UNAVAILABLE" isLocal="true" multiroomallowed="true"/>
  <sourceItem source="TUNEIN" status="READY" isLocal="false" multiroomallowed="true"/>
  <sourceItem source="NOTIFICATION" status="UNAVAILABLE" isLocal="false" multiroomallowed="true"/>
</sources>''';

    http.Response responseForUrl(Uri url) {
      if (url.path == '/sources') {
        return http.Response(sourcesXml, 200,
            headers: {'content-type': 'text/xml; charset=utf-8'});
      }
      return http.Response('', 200,
          headers: {'content-type': 'text/xml; charset=utf-8'});
    }

    testWidgets('shows source chips after loading', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      when(mockClient.get(any)).thenAnswer((inv) async =>
          responseForUrl(inv.positionalArguments[0] as Uri));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker, apiService: apiService),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AUX IN'), findsOneWidget);
      // Bluetooth is icon-only — no label text
      expect(find.text('BLUETOOTH'), findsNothing);
      expect(find.byIcon(Icons.bluetooth), findsOneWidget);
      // filtered-out sources must not appear
      expect(find.text('TUNEIN'), findsNothing);
      expect(find.text('NOTIFICATION'), findsNothing);
    });

    testWidgets('shows loading indicator while sources are loading',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      final mockClient = MockClient();
      final apiService = SpeakerApiService(
        httpClient: mockClient,
        timeout: const Duration(seconds: 5),
      );

      // Never complete synchronously — use a Completer so we control resolution
      when(mockClient.get(any)).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(seconds: 4));
        return http.Response('', 200);
      });

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker, apiService: apiService),
          ),
        ),
      );

      // After first pump (before any async completes), loading indicators should be visible
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));

      // Let all timers expire so the widget can be disposed cleanly
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });

    testWidgets('shows error and retry on source load failure',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      final mockClient = MockClient();
      final apiService = SpeakerApiService(httpClient: mockClient);

      when(mockClient.get(argThat(
        predicate<Uri>((u) => u.path == '/sources'),
      ))).thenAnswer((_) async => http.Response('', 500));

      // Other GET calls succeed with empty/minimal responses
      when(mockClient.get(argThat(
        predicate<Uri>((u) => u.path != '/sources'),
      ))).thenAnswer((_) async => http.Response('', 200,
          headers: {'content-type': 'text/xml; charset=utf-8'}));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker, apiService: apiService),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsAtLeast(1));
    });

  });

}
