import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/pages/presets_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PresetsPage', () {
    testWidgets('displays "No speakers available" when no speakers', (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initializeSpeakers();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: PresetsPage()),
          ),
        ),
      );

      expect(find.text('No speakers available'), findsOneWidget);
    });

    testWidgets('shows loading indicator when speakers exist', (WidgetTester tester) async {
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
            home: Scaffold(body: PresetsPage()),
          ),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('page builds without error when speaker exists', (WidgetTester tester) async {
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
            home: Scaffold(body: PresetsPage()),
          ),
        ),
      );

      // Widget should build successfully
      expect(find.byType(PresetsPage), findsOneWidget);
    });
  });
}
