import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/pages/presets/empty_preset_detail_page.dart';
import 'package:ueberboese_app/pages/presets/presets_page.dart';
import 'package:ueberboese_app/pages/presets/spotify_preset_detail_page.dart';
import '../../helpers/test_my_app_state.dart';

void main() {
  group('PresetsPage', () {
    late TestMyAppState appState;
    const testSpeakerIp = '192.168.1.100';

    setUp(() {
      appState = TestMyAppState();
      appState.config = const AppConfig(
        apiUrl: 'https://api.example.com',
        mgmtUsername: 'admin',
        mgmtPassword: 'password',
      );
    });

    Widget createWidgetWithProvider(Widget child) {
      return ChangeNotifierProvider<MyAppState>.value(
        value: appState,
        child: MaterialApp(home: child),
      );
    }

    testWidgets('shows loading indicator initially', (
      WidgetTester tester,
    ) async {
      appState.setTestPresets(testSpeakerIp, []);

      await tester.pumpWidget(
        createWidgetWithProvider(const PresetsPage(speakerIp: testSpeakerIp)),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Clean up by waiting for the async operation to complete
      await tester.pumpAndSettle();
    });

    testWidgets('displays correct app bar title', (WidgetTester tester) async {
      appState.setTestPresets(testSpeakerIp, []);

      await tester.pumpWidget(
        createWidgetWithProvider(const PresetsPage(speakerIp: testSpeakerIp)),
      );

      // Should have "Manage Presets" title in app bar
      expect(find.text('Manage Presets'), findsOneWidget);
    });

    testWidgets('page builds without error', (WidgetTester tester) async {
      appState.setTestPresets(testSpeakerIp, []);

      await tester.pumpWidget(
        createWidgetWithProvider(const PresetsPage(speakerIp: testSpeakerIp)),
      );

      // Widget should build successfully
      expect(find.byType(PresetsPage), findsOneWidget);
    });

    testWidgets('displays all 6 preset slots when some are empty', (
      WidgetTester tester,
    ) async {
      // Only return presets for slots 1 and 3
      final presets = [
        const Preset(
          id: '1',
          itemName: 'Preset 1',
          source: 'SPOTIFY',
          location: '/test',
          type: 'playlist',
          isPresetable: true,
        ),
        const Preset(
          id: '3',
          itemName: 'Preset 3',
          source: 'TUNEIN',
          location: '/test',
          type: 'station',
          isPresetable: true,
        ),
      ];

      appState.setTestPresets(testSpeakerIp, presets);

      await tester.pumpWidget(
        createWidgetWithProvider(const PresetsPage(speakerIp: testSpeakerIp)),
      );

      await tester.pumpAndSettle();

      // Should display all 6 preset cards
      expect(find.byType(Card), findsNWidgets(6));

      // Check for preset IDs 1-6
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('displays empty preset cards with correct UI', (
      WidgetTester tester,
    ) async {
      // Return only one preset, leaving 5 empty
      final presets = [
        const Preset(
          id: '1',
          itemName: 'Preset 1',
          source: 'SPOTIFY',
          location: '/test',
          type: 'playlist',
          isPresetable: true,
        ),
      ];

      appState.setTestPresets(testSpeakerIp, presets);

      await tester.pumpWidget(
        createWidgetWithProvider(const PresetsPage(speakerIp: testSpeakerIp)),
      );

      await tester.pumpAndSettle();

      // Should find "Empty Preset" text for 5 empty slots
      expect(find.text('Empty Preset'), findsNWidgets(5));

      // Should find "No content assigned" text for 5 empty slots
      expect(find.text('No content assigned'), findsNWidgets(5));

      // Should find add icons for empty presets (5 empty slots)
      expect(find.byIcon(Icons.add), findsNWidgets(5));
    });

    testWidgets('navigates to EmptyPresetDetailPage when tapping empty card', (
      WidgetTester tester,
    ) async {
      // All presets empty
      appState.setTestPresets(testSpeakerIp, []);

      await tester.pumpWidget(
        createWidgetWithProvider(const PresetsPage(speakerIp: testSpeakerIp)),
      );

      await tester.pumpAndSettle();

      // Tap the first empty preset card
      await tester.tap(find.text('Empty Preset').first);
      await tester.pumpAndSettle();

      // Should navigate to EmptyPresetDetailPage
      expect(find.byType(EmptyPresetDetailPage), findsOneWidget);
      expect(find.text('Preset 1'), findsOneWidget);
    });

    testWidgets(
      'navigates to appropriate detail page when tapping existing preset',
      (WidgetTester tester) async {
        final presets = [
          const Preset(
            id: '1',
            itemName: 'My Spotify Playlist',
            source: 'SPOTIFY',
            location: '/test',
            type: 'playlist',
            isPresetable: true,
          ),
        ];

        appState.setTestPresets(testSpeakerIp, presets);

        await tester.pumpWidget(
          createWidgetWithProvider(const PresetsPage(speakerIp: testSpeakerIp)),
        );

        await tester.pumpAndSettle();

        // Tap the Spotify preset card
        await tester.tap(find.text('My Spotify Playlist'));
        await tester.pumpAndSettle();

        // Should navigate to SpotifyPresetDetailPage
        expect(find.byType(SpotifyPresetDetailPage), findsOneWidget);
      },
    );

    testWidgets('displays all 6 preset slots when all are assigned', (
      WidgetTester tester,
    ) async {
      final presets = List.generate(
        6,
        (index) => Preset(
          id: '${index + 1}',
          itemName: 'Preset ${index + 1}',
          source: 'SPOTIFY',
          location: '/test',
          type: 'playlist',
          isPresetable: true,
        ),
      );

      appState.setTestPresets(testSpeakerIp, presets);

      await tester.pumpWidget(
        createWidgetWithProvider(const PresetsPage(speakerIp: testSpeakerIp)),
      );

      await tester.pumpAndSettle();

      // Should display all 6 preset cards
      expect(find.byType(Card), findsNWidgets(6));

      // Should not find any "Empty Preset" text
      expect(find.text('Empty Preset'), findsNothing);
    });
  });
}
