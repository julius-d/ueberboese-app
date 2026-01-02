import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/pages/edit_speaker_page.dart';

void main() {
  group('EditSpeakerPage', () {
    late Speaker testSpeaker;

    setUp(() {
      testSpeaker = const Speaker(
        id: '1',
        name: 'Test Speaker',
        emoji: '🔊',
        ipAddress: '192.168.1.100',
        type: 'Bose Home Speaker',
        deviceId: 'ABC123',
      );
    });

    testWidgets('displays all fields correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: MaterialApp(
            home: EditSpeakerPage(speaker: testSpeaker),
          ),
        ),
      );

      expect(find.text('Edit Speaker'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Tap to change emoji'), findsOneWidget);
    });

    testWidgets('displays current speaker emoji', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: MaterialApp(
            home: EditSpeakerPage(speaker: testSpeaker),
          ),
        ),
      );

      // Should show the current emoji in large size
      expect(find.text('🔊'), findsOneWidget);
    });

    testWidgets('displays editable speaker name', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: MaterialApp(
            home: EditSpeakerPage(speaker: testSpeaker),
          ),
        ),
      );

      expect(find.text('Speaker Name'), findsOneWidget);
      // Check that it's a TextField with the correct initial value
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Test Speaker');
    });

    testWidgets('displays read-only speaker type', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: MaterialApp(
            home: EditSpeakerPage(speaker: testSpeaker),
          ),
        ),
      );

      expect(find.text('Speaker Type'), findsOneWidget);
      expect(find.text('Bose Home Speaker'), findsOneWidget);
    });

    testWidgets('displays read-only IP address', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: MaterialApp(
            home: EditSpeakerPage(speaker: testSpeaker),
          ),
        ),
      );

      expect(find.text('IP Address'), findsOneWidget);
      expect(find.text('192.168.1.100'), findsOneWidget);
    });

    testWidgets('displays read-only device ID', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: MaterialApp(
            home: EditSpeakerPage(speaker: testSpeaker),
          ),
        ),
      );

      // Scroll down to see the Device ID field
      await tester.dragUntilVisible(
        find.text('Device ID'),
        find.byType(ListView),
        const Offset(0, -100),
      );

      expect(find.text('Device ID'), findsOneWidget);
      expect(find.text('ABC123'), findsOneWidget);
    });

    testWidgets('shows emoji selector when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: MaterialApp(
            home: EditSpeakerPage(speaker: testSpeaker),
          ),
        ),
      );

      // Initially emoji selector should not be visible
      expect(find.text('Choose an emoji'), findsNothing);

      // Tap the emoji card to show selector
      await tester.tap(find.text('Tap to change emoji'));
      await tester.pumpAndSettle();

      // Now emoji selector should be visible
      expect(find.text('Choose an emoji'), findsOneWidget);
    });

    testWidgets('can select different emoji', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: MaterialApp(
            home: EditSpeakerPage(speaker: testSpeaker),
          ),
        ),
      );

      // Show emoji selector
      await tester.tap(find.text('Tap to change emoji'));
      await tester.pumpAndSettle();

      // Select a different emoji (🎵)
      await tester.tap(find.text('🎵').last);
      await tester.pumpAndSettle();

      // Verify the large emoji display changed
      expect(find.text('🎵'), findsOneWidget);
      // Original emoji should not be displayed in large size anymore
      expect(find.text('🔊'), findsNothing);
    });

    testWidgets('hides emoji selector after selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: MaterialApp(
            home: EditSpeakerPage(speaker: testSpeaker),
          ),
        ),
      );

      // Show emoji selector
      await tester.tap(find.text('Tap to change emoji'));
      await tester.pumpAndSettle();

      expect(find.text('Choose an emoji'), findsOneWidget);

      // Select a different emoji
      await tester.tap(find.text('🎵').last);
      await tester.pumpAndSettle();

      // Emoji selector should be hidden
      expect(find.text('Choose an emoji'), findsNothing);
    });

    testWidgets('saves updated speaker with new emoji',
        (WidgetTester tester) async {
      final appState = MyAppState();

      // Add the test speaker to the state
      appState.addSpeaker(testSpeaker);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: EditSpeakerPage(speaker: testSpeaker),
          ),
        ),
      );

      // Show emoji selector and select a different emoji
      await tester.tap(find.text('Tap to change emoji'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🎵').last);
      await tester.pumpAndSettle();

      // Tap save button
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Verify the speaker was updated in the app state
      final updatedSpeaker = appState.speakers.firstWhere((s) => s.id == testSpeaker.id);
      expect(updatedSpeaker.emoji, '🎵');
      expect(updatedSpeaker.name, testSpeaker.name);
      expect(updatedSpeaker.ipAddress, testSpeaker.ipAddress);
      expect(updatedSpeaker.type, testSpeaker.type);
      expect(updatedSpeaker.deviceId, testSpeaker.deviceId);
    });

    testWidgets('preserves all fields except emoji when saving',
        (WidgetTester tester) async {
      final appState = MyAppState();
      appState.addSpeaker(testSpeaker);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: EditSpeakerPage(speaker: testSpeaker),
          ),
        ),
      );

      // Change emoji and save
      await tester.tap(find.text('Tap to change emoji'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🎧').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      final updatedSpeaker = appState.speakers.firstWhere((s) => s.id == testSpeaker.id);

      // Only emoji should change
      expect(updatedSpeaker.emoji, '🎧');

      // All other fields should remain the same
      expect(updatedSpeaker.id, testSpeaker.id);
      expect(updatedSpeaker.name, testSpeaker.name);
      expect(updatedSpeaker.ipAddress, testSpeaker.ipAddress);
      expect(updatedSpeaker.type, testSpeaker.type);
      expect(updatedSpeaker.deviceId, testSpeaker.deviceId);
    });

    testWidgets('back button works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => EditSpeakerPage(speaker: testSpeaker),
                      ),
                    );
                  },
                  child: const Text('Open Edit'),
                ),
              ),
            ),
          ),
        ),
      );

      // Navigate to edit page
      await tester.tap(find.text('Open Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Speaker'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Should be back to the previous page
      expect(find.text('Edit Speaker'), findsNothing);
      expect(find.text('Open Edit'), findsOneWidget);
    });

    testWidgets('allows editing speaker name', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: MaterialApp(
            home: EditSpeakerPage(speaker: testSpeaker),
          ),
        ),
      );

      // Find the TextField and change the text
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'New Speaker Name');
      await tester.pumpAndSettle();

      // Verify the text was changed
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, 'New Speaker Name');
    });

    testWidgets('validates name is not empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: MaterialApp(
            home: EditSpeakerPage(speaker: testSpeaker),
          ),
        ),
      );

      // Clear the name field
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '');
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Should show a snackbar with error message
      expect(find.text('Speaker name cannot be empty'), findsOneWidget);

      // Should not navigate back
      expect(find.text('Edit Speaker'), findsOneWidget);
    });

    testWidgets('updates emoji without API call', (WidgetTester tester) async {
      final appState = MyAppState();
      appState.addSpeaker(testSpeaker);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: EditSpeakerPage(speaker: testSpeaker),
          ),
        ),
      );

      // Change emoji (no name change, so no API call needed)
      await tester.tap(find.text('Tap to change emoji'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🎵').last);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Verify the speaker was updated
      final updatedSpeaker = appState.speakers.firstWhere((s) => s.id == testSpeaker.id);
      expect(updatedSpeaker.name, 'Test Speaker'); // Name unchanged
      expect(updatedSpeaker.emoji, '🎵'); // Emoji changed
    });

  });
}
