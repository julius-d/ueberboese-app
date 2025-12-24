import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/speaker.dart';
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
      expect(find.text('Speaker Details'), findsOneWidget);
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
  });
}
