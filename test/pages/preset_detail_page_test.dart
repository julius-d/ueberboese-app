import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/pages/preset_detail_page.dart';

void main() {
  group('PresetDetailPage', () {
    testWidgets('displays preset information correctly', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        const MaterialApp(
          home: PresetDetailPage(preset: testPreset),
        ),
      );

      // Check that the preset information is displayed
      expect(find.text('Preset 1'), findsOneWidget);
      expect(find.text('Test Radio Station'), findsOneWidget);
      expect(find.text('TUNEIN'), findsOneWidget);
      expect(find.text('stationurl'), findsOneWidget);
      expect(find.text('/v1/playback/station/s12345'), findsOneWidget);
    });

    testWidgets('displays preset without optional fields', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '2',
        itemName: 'Simple Preset',
        source: 'SPOTIFY',
        location: '/v1/spotify/playlist/abc',
        type: 'playlist',
        isPresetable: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: PresetDetailPage(preset: testPreset),
        ),
      );

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

      await tester.pumpWidget(
        const MaterialApp(
          home: PresetDetailPage(preset: testPreset),
        ),
      );

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

      await tester.pumpWidget(
        const MaterialApp(
          home: PresetDetailPage(preset: testPreset),
        ),
      );

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

      await tester.pumpWidget(
        const MaterialApp(
          home: PresetDetailPage(preset: testPreset),
        ),
      );

      // Check all sections are present
      expect(find.text('Preset Number'), findsOneWidget);
      expect(find.text('Source'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
    });
  });
}
