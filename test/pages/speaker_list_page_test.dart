import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/now_playing.dart';
import 'package:ueberboese_app/pages/speaker_list_page.dart';
import 'package:ueberboese_app/pages/speaker_detail_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SpeakerListPage', () {
    testWidgets('displays list of speakers', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      // Add a test speaker
      const testSpeaker = Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      );
      appState.addSpeaker(testSpeaker);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      expect(find.text('Test Speaker'), findsOneWidget);
      expect(find.text('SoundTouch 10'), findsOneWidget);
      expect(find.text('🔊'), findsOneWidget);
    });

    testWidgets('shows all speakers from state', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      // Add multiple test speakers
      appState.addSpeaker(const Speaker(
        id: '1',
        name: 'Speaker 1',
        emoji: '🔊',
        ipAddress: '192.168.1.101',
        type: 'SoundTouch 10',
        deviceId: 'device-101',
      ));
      appState.addSpeaker(const Speaker(
        id: '2',
        name: 'Speaker 2',
        emoji: '🎵',
        ipAddress: '192.168.1.102',
        type: 'SoundTouch 20',
        deviceId: 'device-102',
      ));
      appState.addSpeaker(const Speaker(
        id: '3',
        name: 'Speaker 3',
        emoji: '🎶',
        ipAddress: '192.168.1.103',
        type: 'SoundTouch 30',
        deviceId: 'device-103',
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      expect(find.text('Speaker 1'), findsOneWidget);
      expect(find.text('Speaker 2'), findsOneWidget);
      expect(find.text('Speaker 3'), findsOneWidget);
    });

    testWidgets('navigates to detail page on tap', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      // Add a test speaker
      appState.addSpeaker(const Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      await tester.tap(find.text('Test Speaker'));
      await tester.pump(); // Trigger navigation
      await tester.pump(const Duration(seconds: 1)); // Allow animation

      expect(find.byType(SpeakerDetailPage), findsOneWidget);
      // AppBar shows speaker name and emoji, not "Speaker Details"
      expect(find.text('Test Speaker'), findsAtLeast(1));
      expect(find.text('🔊'), findsAtLeast(1));
    });

    testWidgets('displays speaker emoji with correct size',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      // Add a test speaker
      appState.addSpeaker(const Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      final emojiText = tester.widget<Text>(
        find.text('🔊').first,
      );

      // Using theme typography now (headlineMedium) instead of explicit fontSize
      expect(emojiText.style?.fontSize, 28);
    });

    testWidgets('has FAB with add icon', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsWidgets);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('FAB expands to show speed dial options on tap',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      // Initially, only main FAB is visible (mini FABs are scaled to 0)
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Tap main FAB
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Speed dial options should now be visible
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('Add by IP'), findsOneWidget);
      expect(find.byIcon(Icons.router), findsOneWidget);
    });

    testWidgets('backdrop closes speed dial when tapped',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      // Expand speed dial
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('Add by IP'), findsOneWidget);

      // Tap backdrop (the semi-transparent overlay)
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Speed dial should be closed
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('Add by IP option navigates to AddSpeakerPage',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      // Expand speed dial
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Tap "Add by IP"
      await tester.tap(find.byIcon(Icons.router));
      await tester.pumpAndSettle();

      // Should navigate to AddSpeakerPage (check for the page title)
      expect(find.text('Add Speaker'), findsOneWidget);
    });

    testWidgets('displays disconnected chip when speaker status is not loaded',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      appState.addSpeaker(const Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      // Wait for initial render
      await tester.pump();

      // Initially, speakers should show disconnected chip with wifi_off icon
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('displays disconnected icon for disconnected speakers',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      appState.addSpeaker(const Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      await tester.pump();

      // Verify type text is displayed
      expect(find.text('SoundTouch 10'), findsOneWidget);

      // Verify disconnected icon
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('applies error container background to disconnected speaker cards',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      appState.addSpeaker(const Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      await tester.pump();

      // Find the Card that should have errorContainer background
      final cardFinder = find.ancestor(
        of: find.text('Test Speaker'),
        matching: find.byType(Card),
      );

      expect(cardFinder, findsOneWidget);

      // Verify the card has a color set (errorContainer for disconnected state)
      final card = tester.widget<Card>(cardFinder);
      expect(card.color, isNotNull);
    });

    testWidgets('card uses Stack for layering',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      appState.addSpeaker(const Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      await tester.pump();

      // Verify Stack is used in the card structure
      // Find the card containing the speaker
      final cardFinder = find.ancestor(
        of: find.text('Test Speaker'),
        matching: find.byType(Card),
      );

      expect(cardFinder, findsOneWidget);

      // Verify this card contains at least one Stack (used for layering background)
      final stackInCard = find.descendant(
        of: cardFinder,
        matching: find.byType(Stack),
      );

      expect(stackInCard, findsAtLeastNWidgets(1));
    });

    testWidgets('displays Hero widget when speaker is playing with artwork',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      // Add a speaker and set it as playing with artwork
      const testSpeaker = Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      );
      appState.addSpeaker(testSpeaker);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      // Set the speaker state to playing with artwork after widget is built
      appState.updateNowPlayingForSpeaker(
        testSpeaker.ipAddress,
        const NowPlaying(
          source: 'SPOTIFY',
          track: 'Test Track',
          artist: 'Test Artist',
          album: 'Test Album',
          art: 'https://example.com/art.jpg',
          artImageStatus: 'IMAGE_PRESENT',
          playStatus: 'PLAY_STATE',
        ),
        true, // isConnected
      );

      // Pump to rebuild with the new state
      await tester.pumpAndSettle();

      // Verify Hero widget with album art tag is present in the widget tree
      final albumArtHeroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'album-art-1',
      );
      expect(albumArtHeroFinder, findsOneWidget);

      // Verify the Hero tag matches the expected format
      final heroWidget = tester.widget<Hero>(albumArtHeroFinder);
      expect(heroWidget.tag, equals('album-art-1'));
    });

    testWidgets('does not display Hero widget when speaker is not playing',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      appState.addSpeaker(const Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      ));

      // Don't set any now playing state (speaker is not playing)

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      await tester.pump();

      // Verify no Hero widget with album art tag is present when speaker is not playing
      final albumArtHeroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag.toString().startsWith('album-art-'),
      );
      expect(albumArtHeroFinder, findsNothing);
    });

    testWidgets('Hero tag format matches speaker ID',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      // Add multiple speakers with different IDs
      const speakerA = Speaker(
        id: 'speaker-a',
        name: 'Speaker A',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      );
      const speakerB = Speaker(
        id: 'speaker-b',
        name: 'Speaker B',
        emoji: '🎵',
        ipAddress: '192.168.1.101',
        type: 'SoundTouch 20',
        deviceId: 'device-456',
      );

      appState.addSpeaker(speakerA);
      appState.addSpeaker(speakerB);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      // Set first speaker as playing with artwork after widget is built
      appState.updateNowPlayingForSpeaker(
        speakerA.ipAddress,
        const NowPlaying(
          source: 'SPOTIFY',
          track: 'Test Track',
          artist: 'Test Artist',
          album: 'Test Album',
          art: 'https://example.com/art.jpg',
          artImageStatus: 'IMAGE_PRESENT',
          playStatus: 'PLAY_STATE',
        ),
        true, // isConnected
      );

      // Pump to rebuild with the new state
      await tester.pumpAndSettle();

      // Verify Hero widget exists with correct tag for speaker-a
      final albumArtHeroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'album-art-speaker-a',
      );
      expect(albumArtHeroFinder, findsOneWidget);

      final heroWidget = tester.widget<Hero>(albumArtHeroFinder);
      expect(heroWidget.tag, equals('album-art-speaker-a'));
    });

    testWidgets('displays speaker info Hero widget when no artwork',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      // Add a speaker without any now playing state (no artwork)
      const testSpeaker = Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      );
      appState.addSpeaker(testSpeaker);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify speaker info Hero widget is present
      final speakerInfoHeroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'speaker-info-1',
      );
      expect(speakerInfoHeroFinder, findsOneWidget);

      // Verify the Hero tag is correct
      final heroWidget = tester.widget<Hero>(speakerInfoHeroFinder);
      expect(heroWidget.tag, equals('speaker-info-1'));
    });

    testWidgets('speaker info Hero is not present when artwork is showing',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      const testSpeaker = Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      );
      appState.addSpeaker(testSpeaker);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      // Set the speaker as playing with artwork
      appState.updateNowPlayingForSpeaker(
        testSpeaker.ipAddress,
        const NowPlaying(
          source: 'SPOTIFY',
          track: 'Test Track',
          artist: 'Test Artist',
          album: 'Test Album',
          art: 'https://example.com/art.jpg',
          artImageStatus: 'IMAGE_PRESENT',
          playStatus: 'PLAY_STATE',
        ),
        true, // isConnected
      );

      await tester.pumpAndSettle();

      // Verify speaker info Hero widget is NOT present when artwork is showing
      // (because album art hero takes precedence)
      final speakerInfoHeroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'speaker-info-1',
      );
      expect(speakerInfoHeroFinder, findsNothing);
    });

    testWidgets('displays album art Hero even when paused',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      const testSpeaker = Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      );
      appState.addSpeaker(testSpeaker);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      // Set the speaker as PAUSED with artwork (not playing)
      appState.updateNowPlayingForSpeaker(
        testSpeaker.ipAddress,
        const NowPlaying(
          source: 'SPOTIFY',
          track: 'Test Track',
          artist: 'Test Artist',
          album: 'Test Album',
          art: 'https://example.com/art.jpg',
          artImageStatus: 'IMAGE_PRESENT',
          playStatus: 'PAUSE_STATE', // Paused, not playing
        ),
        true, // isConnected
      );

      await tester.pumpAndSettle();

      // Verify album art Hero widget is present even when paused
      final albumArtHeroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'album-art-1',
      );
      expect(albumArtHeroFinder, findsOneWidget);

      // Verify speaker info Hero is NOT present (album art takes precedence)
      final speakerInfoHeroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'speaker-info-1',
      );
      expect(speakerInfoHeroFinder, findsNothing);
    });

    testWidgets('hides album art Hero when showAlbumArtInList is false',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();
      appState.updateConfig(
        appState.config.copyWith(showAlbumArtInList: false),
      );

      const testSpeaker = Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      );
      appState.addSpeaker(testSpeaker);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      appState.updateNowPlayingForSpeaker(
        testSpeaker.ipAddress,
        const NowPlaying(
          source: 'SPOTIFY',
          track: 'Test Track',
          artist: 'Test Artist',
          album: 'Test Album',
          art: 'https://example.com/art.jpg',
          artImageStatus: 'IMAGE_PRESENT',
          playStatus: 'PLAY_STATE',
        ),
        true,
      );

      await tester.pumpAndSettle();

      // Album art hero should NOT appear when toggle is off
      final albumArtHeroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag.toString().startsWith('album-art-'),
      );
      expect(albumArtHeroFinder, findsNothing);

      // Speaker info hero should be shown instead
      final speakerInfoHeroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'speaker-info-1',
      );
      expect(speakerInfoHeroFinder, findsOneWidget);
    });

    testWidgets('shows album art Hero when showAlbumArtInList is true',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();
      appState.updateConfig(
        appState.config.copyWith(showAlbumArtInList: true),
      );

      const testSpeaker = Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'SoundTouch 10',
        deviceId: 'device-123',
      );
      appState.addSpeaker(testSpeaker);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      appState.updateNowPlayingForSpeaker(
        testSpeaker.ipAddress,
        const NowPlaying(
          source: 'SPOTIFY',
          track: 'Test Track',
          artist: 'Test Artist',
          album: 'Test Album',
          art: 'https://example.com/art.jpg',
          artImageStatus: 'IMAGE_PRESENT',
          playStatus: 'PLAY_STATE',
        ),
        true,
      );

      await tester.pumpAndSettle();

      final albumArtHeroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'album-art-1',
      );
      expect(albumArtHeroFinder, findsOneWidget);
    });
  });
}
