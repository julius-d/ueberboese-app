import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/app_config.dart';
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
      expect(find.text('Add all from account'), findsOneWidget);
      expect(find.byIcon(Icons.router), findsOneWidget);
      expect(find.byIcon(Icons.cloud_download), findsOneWidget);
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

    testWidgets(
        'Add all from account shows error when API URL not configured',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      // Ensure config has empty API URL
      appState.updateConfig(const AppConfig(
        apiUrl: '',
        accountId: '123',
        mgmtUsername: 'admin',
        mgmtPassword: 'password',
      ));

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

      // Tap "Add all from account"
      await tester.tap(find.byIcon(Icons.cloud_download));
      await tester.pumpAndSettle();

      // Should show error dialog
      expect(find.text('API URL not configured'), findsOneWidget);
      expect(find.text('Go to Settings'), findsOneWidget);
    });

    testWidgets(
        'Add all from account shows error when Account ID not configured',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      // Ensure config has empty Account ID
      appState.updateConfig(const AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: '',
        mgmtUsername: 'admin',
        mgmtPassword: 'password',
      ));

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

      // Tap "Add all from account"
      await tester.tap(find.byIcon(Icons.cloud_download));
      await tester.pumpAndSettle();

      // Should show error dialog
      expect(find.text('Account ID not configured'), findsOneWidget);
    });

    testWidgets(
        'Add all from account shows error when username not configured',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      // Ensure config has empty username
      appState.updateConfig(const AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: '123',
        mgmtUsername: '',
        mgmtPassword: 'password',
      ));

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

      // Tap "Add all from account"
      await tester.tap(find.byIcon(Icons.cloud_download));
      await tester.pumpAndSettle();

      // Should show error dialog
      expect(find.text('Management username not configured'), findsOneWidget);
    });

    testWidgets(
        'Add all from account shows error when password not configured',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      // Ensure config has empty password
      appState.updateConfig(const AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: '123',
        mgmtUsername: 'admin',
        mgmtPassword: '',
      ));

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

      // Tap "Add all from account"
      await tester.tap(find.byIcon(Icons.cloud_download));
      await tester.pumpAndSettle();

      // Should show error dialog
      expect(find.text('Management password not configured'), findsOneWidget);
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

    testWidgets('applies gray background to disconnected speaker cards',
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

      // Find the Container that should have gray background
      final containerFinder = find.descendant(
        of: find.byType(Card),
        matching: find.byType(Container),
      );

      expect(containerFinder, findsWidgets);

      // Verify at least one container has a gray color (disconnected state)
      final containers = tester.widgetList<Container>(containerFinder);
      final hasGrayContainer = containers.any((container) {
        final color = container.color;
        return color != null && (color.a * 255.0).round() > 0;
      });

      expect(hasGrayContainer, isTrue);
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
  });
}
