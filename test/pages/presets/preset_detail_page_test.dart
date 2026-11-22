import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/pages/presets/preset_detail_page.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';

import 'preset_detail_page_test.mocks.dart';

@GenerateMocks([SpeakerApiService])
void main() {
  group('PresetDetailPage', () {
    const testSpeakerIp = '192.168.1.100';
    late MockSpeakerApiService mockSpeakerApiService;
    late TestMyAppState appState;

    setUp(() {
      mockSpeakerApiService = MockSpeakerApiService();
      appState = TestMyAppState();
      appState.config = const AppConfig();
    });

    testWidgets('displays preset information correctly', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Radio Station',
        containerArt: 'http://example.com/art.png',
        source: 'TUNEIN',
        location: '/v1/playback/station/s12345',
        type: 'stationurl',
        isPresetable: true,
        createdOn: 1701220500,
        updatedOn: 1701220600,
      );

      appState.setTestPresets(testSpeakerIp, [testPreset]);

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: MaterialApp(
            home: PresetDetailPage(
              presetId: '1',
              speakerIp: testSpeakerIp,
              apiService: mockSpeakerApiService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check that the preset information is displayed
      expect(find.text('Preset 1'), findsOneWidget);
      expect(find.text('Test Radio Station'), findsOneWidget);
      expect(find.text('TUNEIN'), findsOneWidget);
      expect(find.text('stationurl'), findsOneWidget);
      expect(find.text('/v1/playback/station/s12345'), findsOneWidget);
    });

    testWidgets('displays preset without optional fields', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '2',
        itemName: 'Simple Preset',
        source: 'SPOTIFY',
        location: '/v1/spotify/playlist/abc',
        type: 'playlist',
        isPresetable: false,
      );

      appState.setTestPresets(testSpeakerIp, [testPreset]);

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: MaterialApp(
            home: PresetDetailPage(
              presetId: '2',
              speakerIp: testSpeakerIp,
              apiService: mockSpeakerApiService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check that the basic information is displayed
      expect(find.text('Preset 2'), findsOneWidget);
      expect(find.text('Simple Preset'), findsOneWidget);
      expect(find.text('SPOTIFY'), findsOneWidget);
      expect(find.text('playlist'), findsOneWidget);

      // Optional fields should not be present
      expect(find.text('Created On'), findsNothing);
      expect(find.text('Updated On'), findsNothing);
    });

    testWidgets('displays preset with timestamps', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '3',
        itemName: 'Preset With Timestamps',
        source: 'TUNEIN',
        location: '/test',
        type: 'stationurl',
        isPresetable: true,
        createdOn: 1701220500,
        updatedOn: 1701220600,
      );

      appState.setTestPresets(testSpeakerIp, [testPreset]);

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: MaterialApp(
            home: PresetDetailPage(
              presetId: '3',
              speakerIp: testSpeakerIp,
              apiService: mockSpeakerApiService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check that timestamp fields are present
      expect(find.text('Created On'), findsOneWidget);
      expect(find.text('Updated On'), findsOneWidget);
    });

    testWidgets('has an app bar', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test',
        source: 'TUNEIN',
        location: '/test',
        type: 'stationurl',
        isPresetable: true,
      );

      appState.setTestPresets(testSpeakerIp, [testPreset]);

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: MaterialApp(
            home: PresetDetailPage(
              presetId: '1',
              speakerIp: testSpeakerIp,
              apiService: mockSpeakerApiService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check that AppBar exists
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays all detail sections', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '5',
        itemName: 'Full Preset',
        containerArt: 'http://example.com/image.jpg',
        source: 'TUNEIN',
        location: '/v1/test',
        type: 'stationurl',
        isPresetable: true,
      );

      appState.setTestPresets(testSpeakerIp, [testPreset]);

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: MaterialApp(
            home: PresetDetailPage(
              presetId: '5',
              speakerIp: testSpeakerIp,
              apiService: mockSpeakerApiService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check all sections are present
      expect(find.text('Preset Number'), findsOneWidget);
      expect(find.text('Source'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('displays FABs with play and edit icons', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
      );

      appState.setTestPresets(testSpeakerIp, [testPreset]);

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: MaterialApp(
            home: PresetDetailPage(
              presetId: '1',
              speakerIp: testSpeakerIp,
              apiService: mockSpeakerApiService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // There are now 5 FABs (play + main edit + 3 sub-FABs)
      expect(find.byType(FloatingActionButton), findsNWidgets(5));
      // Should have play icon
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      // Should have edit icon
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('sub-FABs are accessible and can be tapped', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'TUNEIN',
        location: '/v1/playback/station/s12345',
        type: 'stationurl',
        isPresetable: true,
      );

      appState.setTestPresets(testSpeakerIp, [testPreset]);

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: MaterialApp(
            home: PresetDetailPage(
              presetId: '1',
              speakerIp: testSpeakerIp,
              apiService: mockSpeakerApiService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the main FAB to open sub-menu
      await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.edit));
      await tester.pumpAndSettle();

      // Verify sub-menu is open with all options
      expect(find.text('TuneIn'), findsOneWidget);
      expect(find.text('Spotify'), findsOneWidget);
      expect(
        find.widgetWithIcon(FloatingActionButton, Icons.podcasts),
        findsOneWidget,
      );
      expect(
        find.widgetWithIcon(FloatingActionButton, Icons.audiotrack),
        findsOneWidget,
      );
    });

    testWidgets('tapping main FAB opens sub-menu with 2 options', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Preset',
        source: 'PRODUCT',
        location: '/v1/playback/product/xyz',
        type: 'producturl',
        isPresetable: true,
      );

      appState.setTestPresets(testSpeakerIp, [testPreset]);

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: MaterialApp(
            home: PresetDetailPage(
              presetId: '1',
              speakerIp: testSpeakerIp,
              apiService: mockSpeakerApiService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the main FAB to open sub-menu
      await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.edit));
      await tester.pumpAndSettle();

      // Check that all 2 sub-FABs are visible
      expect(
        find.widgetWithIcon(FloatingActionButton, Icons.audiotrack),
        findsOneWidget,
      ); // Spotify
      expect(
        find.widgetWithIcon(FloatingActionButton, Icons.podcasts),
        findsOneWidget,
      ); // TuneIn
      expect(find.text('Spotify'), findsOneWidget);
      expect(find.text('TuneIn'), findsOneWidget);
    });

    testWidgets('shows loading indicator when preset not in cache', (
      WidgetTester tester,
    ) async {
      final emptyAppState = TestMyAppState();
      emptyAppState.config = const AppConfig();
      // Don't populate cache, so preset will be null

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: emptyAppState,
          child: MaterialApp(
            home: PresetDetailPage(
              presetId: '999',
              speakerIp: testSpeakerIp,
              apiService: mockSpeakerApiService,
            ),
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Preset 999'), findsOneWidget);
    });
  });
}

/// Test version of MyAppState that allows setting presets directly
class TestMyAppState extends MyAppState {
  void setTestPresets(String speakerIp, List<Preset> presets) {
    // Directly set the cache for testing
    // ignore: invalid_use_of_protected_member
    super.getPresets(speakerIp).then((_) {}).catchError((_) {});

    // Access private field through a workaround
    // We'll use the fact that we can override getPresetById
    _testPresetsCache[speakerIp] = presets;
  }

  final Map<String, List<Preset>> _testPresetsCache = {};

  @override
  Preset? getPresetById(String speakerIp, String presetId) {
    final testPresets = _testPresetsCache[speakerIp];
    if (testPresets != null) {
      try {
        return testPresets.firstWhere((p) => p.id == presetId);
      } catch (e) {
        return null;
      }
    }
    return super.getPresetById(speakerIp, presetId);
  }
}
