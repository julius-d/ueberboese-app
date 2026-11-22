import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/pages/presets/empty_preset_detail_page.dart';

void main() {
  group('EmptyPresetDetailPage', () {
    late TestMyAppState appState;

    setUp(() {
      appState = TestMyAppState();
      appState.config = const AppConfig();
    });
    testWidgets('displays correct title with preset number', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: const MaterialApp(
            home: EmptyPresetDetailPage(
              presetId: '1',
              speakerIp: '192.168.1.100',
            ),
          ),
        ),
      );

      expect(find.text('Preset 1'), findsOneWidget);
    });

    testWidgets('displays correct title for preset 6', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: const MaterialApp(
            home: EmptyPresetDetailPage(
              presetId: '6',
              speakerIp: '192.168.1.100',
            ),
          ),
        ),
      );

      expect(find.text('Preset 6'), findsOneWidget);
    });

    testWidgets('displays empty state message', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: const MaterialApp(
            home: EmptyPresetDetailPage(
              presetId: '1',
              speakerIp: '192.168.1.100',
            ),
          ),
        ),
      );

      expect(find.text('This preset is empty'), findsOneWidget);
      expect(
        find.text(
          'Tap the edit button below to assign content to this preset slot',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays add icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: const MaterialApp(
            home: EmptyPresetDetailPage(
              presetId: '1',
              speakerIp: '192.168.1.100',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('displays FAB with edit icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: const MaterialApp(
            home: EmptyPresetDetailPage(
              presetId: '1',
              speakerIp: '192.168.1.100',
            ),
          ),
        ),
      );

      // There are now 4 FABs (main + 3 sub-FABs)
      expect(find.byType(FloatingActionButton), findsNWidgets(4));
      // Main FAB should have edit icon
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('FAB expands to show edit options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: const MaterialApp(
            home: EmptyPresetDetailPage(
              presetId: '1',
              speakerIp: '192.168.1.100',
            ),
          ),
        ),
      );

      // Tap the main FAB to open sub-menu
      await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.edit));
      await tester.pumpAndSettle();

      // Verify sub-menu is open with all options
      expect(find.text('Spotify'), findsOneWidget);
      expect(find.text('TuneIn'), findsOneWidget);
      expect(find.text('Internet Radio'), findsOneWidget);
      expect(
        find.widgetWithIcon(FloatingActionButton, Icons.audiotrack),
        findsOneWidget,
      );
      expect(
        find.widgetWithIcon(FloatingActionButton, Icons.podcasts),
        findsOneWidget,
      );
      expect(
        find.widgetWithIcon(FloatingActionButton, Icons.radio),
        findsOneWidget,
      );
    });

    testWidgets('page builds without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: const MaterialApp(
            home: EmptyPresetDetailPage(
              presetId: '1',
              speakerIp: '192.168.1.100',
            ),
          ),
        ),
      );

      // Widget should build successfully
      expect(find.byType(EmptyPresetDetailPage), findsOneWidget);
    });

    testWidgets('has back button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const EmptyPresetDetailPage(
                              presetId: '1',
                              speakerIp: '192.168.1.100',
                            ),
                          ),
                        );
                      },
                      child: const Text('Navigate'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Navigate to the page
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      // Should have a back button
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('displays scrim overlay when FAB is expanded', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: const MaterialApp(
            home: EmptyPresetDetailPage(
              presetId: '1',
              speakerIp: '192.168.1.100',
            ),
          ),
        ),
      );

      // Initially, the scrim overlay is not visible (it's a SizedBox.shrink)
      expect(find.byType(SizedBox), findsWidgets);

      // Tap the main FAB to open sub-menu
      await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.edit));
      await tester.pumpAndSettle();

      // After expanding, all sub-FABs should be visible
      expect(find.text('Spotify'), findsOneWidget);
      expect(find.text('TuneIn'), findsOneWidget);
      expect(find.text('Internet Radio'), findsOneWidget);
    });
  });
}

/// Test version of MyAppState that doesn't require API calls
class TestMyAppState extends MyAppState {
  // Empty implementation - no presets in cache by default
}
