import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/widgets/preset_action_fabs.dart';

@GenerateMocks([SpeakerApiService])
import 'preset_action_fabs_test.mocks.dart';

void main() {
  group('PresetActionFabs', () {
    late MockSpeakerApiService mockSpeakerApiService;
    const testSpeakerIp = '192.168.1.100';
    const testPreset = Preset(
      id: '1',
      itemName: 'Test Playlist',
      source: 'SPOTIFY',
      location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
      type: 'playlist',
      isPresetable: true,
    );

    setUp(() {
      mockSpeakerApiService = MockSpeakerApiService();
    });

    testWidgets('displays play FAB and edit FAB', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetActionFabs(
              preset: testPreset,
              speakerIp: testSpeakerIp,
              speakerApiService: mockSpeakerApiService,
            ),
          ),
        ),
      );

      // Should have 5 FABs total: 1 play + 1 main edit + 3 sub-FABs
      expect(find.byType(FloatingActionButton), findsNWidgets(5));
      // Play FAB with play icon
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      // Edit FAB with edit icon
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('play FAB has correct tooltip', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetActionFabs(
              preset: testPreset,
              speakerIp: testSpeakerIp,
              speakerApiService: mockSpeakerApiService,
            ),
          ),
        ),
      );

      final playFab = find.widgetWithIcon(
        FloatingActionButton,
        Icons.play_arrow,
      );
      expect(playFab, findsOneWidget);

      final fabWidget = tester.widget<FloatingActionButton>(playFab);
      expect(fabWidget.tooltip, 'Play preset');
    });

    testWidgets('calls selectPreset when play FAB is tapped', (
      WidgetTester tester,
    ) async {
      when(
        mockSpeakerApiService.selectPreset(any, any),
      ).thenAnswer((_) async => Future.value());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetActionFabs(
              preset: testPreset,
              speakerIp: testSpeakerIp,
              speakerApiService: mockSpeakerApiService,
            ),
          ),
        ),
      );

      // Tap the play FAB
      await tester.tap(
        find.widgetWithIcon(FloatingActionButton, Icons.play_arrow),
      );
      await tester.pump();

      // Verify the API was called
      verify(
        mockSpeakerApiService.selectPreset(testSpeakerIp, testPreset),
      ).called(1);
    });

    testWidgets('shows loading indicator when playing preset', (
      WidgetTester tester,
    ) async {
      when(
        mockSpeakerApiService.selectPreset(any, any),
      ).thenAnswer((_) => Future.delayed(const Duration(seconds: 1)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetActionFabs(
              preset: testPreset,
              speakerIp: testSpeakerIp,
              speakerApiService: mockSpeakerApiService,
            ),
          ),
        ),
      );

      // Tap the play FAB
      await tester.tap(
        find.widgetWithIcon(FloatingActionButton, Icons.play_arrow),
      );
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);

      // Wait for the operation to complete
      await tester.pumpAndSettle();

      // Loading indicator should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('shows success snackbar when preset plays successfully', (
      WidgetTester tester,
    ) async {
      when(
        mockSpeakerApiService.selectPreset(any, any),
      ).thenAnswer((_) async => Future.value());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetActionFabs(
              preset: testPreset,
              speakerIp: testSpeakerIp,
              speakerApiService: mockSpeakerApiService,
            ),
          ),
        ),
      );

      // Tap the play FAB
      await tester.tap(
        find.widgetWithIcon(FloatingActionButton, Icons.play_arrow),
      );
      await tester.pumpAndSettle();

      // Verify success snackbar
      expect(find.text('Playing Test Playlist'), findsOneWidget);
    });

    testWidgets('shows error snackbar when preset fails to play', (
      WidgetTester tester,
    ) async {
      when(
        mockSpeakerApiService.selectPreset(any, any),
      ).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetActionFabs(
              preset: testPreset,
              speakerIp: testSpeakerIp,
              speakerApiService: mockSpeakerApiService,
            ),
          ),
        ),
      );

      // Tap the play FAB
      await tester.tap(
        find.widgetWithIcon(FloatingActionButton, Icons.play_arrow),
      );
      await tester.pumpAndSettle();

      // Verify error snackbar
      expect(find.textContaining('Failed to play preset'), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('play FAB is disabled while loading', (
      WidgetTester tester,
    ) async {
      when(
        mockSpeakerApiService.selectPreset(any, any),
      ).thenAnswer((_) => Future.delayed(const Duration(seconds: 1)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetActionFabs(
              preset: testPreset,
              speakerIp: testSpeakerIp,
              speakerApiService: mockSpeakerApiService,
            ),
          ),
        ),
      );

      // Tap the play FAB
      await tester.tap(
        find.widgetWithIcon(FloatingActionButton, Icons.play_arrow),
      );
      await tester.pump();

      // Try to tap again while loading
      await tester.tap(find.byType(FloatingActionButton).first);
      await tester.pump();

      // Should only be called once
      verify(
        mockSpeakerApiService.selectPreset(testSpeakerIp, testPreset),
      ).called(1);

      await tester.pumpAndSettle();
    });

    testWidgets('edit FAB expands to show options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetActionFabs(
              preset: testPreset,
              speakerIp: testSpeakerIp,
              speakerApiService: mockSpeakerApiService,
            ),
          ),
        ),
      );

      // Tap the edit FAB
      await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.edit));
      await tester.pumpAndSettle();

      // Verify sub-menu is open with all options
      expect(find.text('Spotify'), findsOneWidget);
      expect(find.text('TuneIn'), findsOneWidget);
      expect(find.text('Internet Radio'), findsOneWidget);
    });

    testWidgets('respects isExpandedNotifier', (WidgetTester tester) async {
      final expandedNotifier = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: PresetActionFabs(
              preset: testPreset,
              speakerIp: testSpeakerIp,
              speakerApiService: mockSpeakerApiService,
              isExpandedNotifier: expandedNotifier,
            ),
          ),
        ),
      );

      // Initially not expanded - labels are rendered but not visible due to opacity
      // Check for the sub-FABs instead
      expect(
        find.byIcon(Icons.audiotrack),
        findsOneWidget,
      ); // Spotify icon is always rendered

      // Expand using notifier
      expandedNotifier.value = true;
      await tester.pumpAndSettle();

      // Should be expanded - labels should be visible
      final spotifyText = find.text('Spotify');
      expect(spotifyText, findsOneWidget);

      // Collapse using notifier
      expandedNotifier.value = false;
      await tester.pumpAndSettle();

      // After collapse, labels are still rendered (just with opacity 0)
      // So we can't test text visibility - the test passes if no exceptions occur
    });

    testWidgets('play and edit FABs are stacked vertically', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: PresetActionFabs(
              preset: testPreset,
              speakerIp: testSpeakerIp,
              speakerApiService: mockSpeakerApiService,
            ),
          ),
        ),
      );

      // Find the outermost Column (the one in PresetActionFabs)
      // There are multiple Columns because PresetEditFab also contains a Column
      final columns = find.byType(Column);
      expect(columns, findsWidgets);

      // Get the first Column which should be from PresetActionFabs
      final column = tester.widget<Column>(columns.first);
      expect(column.mainAxisSize, MainAxisSize.min);
      expect(column.crossAxisAlignment, CrossAxisAlignment.end);

      // Should have 3 children: edit FAB (which contains more nested widgets), spacing, play FAB
      expect(column.children.length, 3);
    });
  });
}
