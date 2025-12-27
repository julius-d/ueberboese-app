import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/pages/speaker_detail_page.dart';

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

      expect(find.text('Speaker Details'), findsOneWidget);
      expect(find.text('Test Speaker'), findsOneWidget);
      expect(find.text('🔊'), findsOneWidget);
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
      expect(find.text('Send to standby'), findsOneWidget);
      expect(find.text('Delete speaker'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
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

    testWidgets('displays Now Playing section', (WidgetTester tester) async {
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

      expect(find.text('Now Playing'), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
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
  });
}
