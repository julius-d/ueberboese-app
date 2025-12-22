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
          child: MaterialApp(
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
          child: MaterialApp(
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
          child: MaterialApp(
            home: SpeakerDetailPage(speaker: testSpeaker),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Delete speaker'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog when delete is tapped',
        (WidgetTester tester) async {
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
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
          child: MaterialApp(
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
                      MaterialPageRoute(
                        builder: (context) =>
                            SpeakerDetailPage(speaker: testSpeaker),
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
          child: MaterialApp(
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
  });
}
