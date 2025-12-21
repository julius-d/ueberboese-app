import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/pages/add_speaker_page.dart';

void main() {
  group('AddSpeakerPage', () {
    testWidgets('displays form fields correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: const MaterialApp(
            home: AddSpeakerPage(),
          ),
        ),
      );

      expect(find.text('Add Speaker'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Speaker Name'), findsOneWidget);
      expect(find.text('IP Address'), findsOneWidget);
      expect(find.text('Save Speaker'), findsOneWidget);
    });

    testWidgets('shows default emoji', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: const MaterialApp(
            home: AddSpeakerPage(),
          ),
        ),
      );

      expect(find.text('🔊'), findsOneWidget);
      expect(find.text('Tap to change emoji'), findsOneWidget);
    });

    testWidgets('validates empty name field', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: const MaterialApp(
            home: AddSpeakerPage(),
          ),
        ),
      );

      // Try to save without entering name
      await tester.tap(find.text('Save Speaker'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a speaker name'), findsOneWidget);
    });

    testWidgets('validates empty IP address', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: const MaterialApp(
            home: AddSpeakerPage(),
          ),
        ),
      );

      // Enter name but not IP
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Speaker Name'),
        'Test Speaker',
      );

      await tester.tap(find.text('Save Speaker'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an IP address'), findsOneWidget);
    });

    testWidgets('validates invalid IP address format',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: const MaterialApp(
            home: AddSpeakerPage(),
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Speaker Name'),
        'Test Speaker',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'IP Address'),
        '999.999.999.999',
      );

      await tester.tap(find.text('Save Speaker'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid IP address'), findsOneWidget);
    });

    testWidgets('shows emoji selector when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: const MaterialApp(
            home: AddSpeakerPage(),
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

    testWidgets('adds speaker with valid input', (WidgetTester tester) async {
      final appState = MyAppState();
      final initialCount = appState.speakers.length;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: AddSpeakerPage(),
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Speaker Name'),
        'New Speaker',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'IP Address'),
        '192.168.1.200',
      );

      await tester.tap(find.text('Save Speaker'));
      await tester.pumpAndSettle();

      expect(appState.speakers.length, initialCount + 1);
      expect(appState.speakers.last.name, 'New Speaker');
      expect(appState.speakers.last.ipAddress, '192.168.1.200');
      expect(appState.speakers.last.emoji, '🔊');
    });

    testWidgets('can select different emoji', (WidgetTester tester) async {
      final appState = MyAppState();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: AddSpeakerPage(),
          ),
        ),
      );

      // Show emoji selector
      await tester.tap(find.text('Tap to change emoji'));
      await tester.pumpAndSettle();

      // Select a different emoji (🎵)
      await tester.tap(find.text('🎵').last);
      await tester.pumpAndSettle();

      // Enter form data
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Speaker Name'),
        'Music Speaker',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'IP Address'),
        '192.168.1.201',
      );

      await tester.tap(find.text('Save Speaker'));
      await tester.pumpAndSettle();

      expect(appState.speakers.last.emoji, '🎵');
    });
  });
}
