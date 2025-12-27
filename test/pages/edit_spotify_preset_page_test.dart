import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/pages/edit_spotify_preset_page.dart';

void main() {
  group('EditSpotifyPresetPage', () {
    testWidgets('displays correct title', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: EditSpotifyPresetPage(preset: testPreset),
        ),
      );

      expect(find.text('Edit Spotify Preset'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays TextField with correct label', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: EditSpotifyPresetPage(preset: testPreset),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Spotify URI'), findsOneWidget);
    });

    testWidgets('prefills TextField with decoded Spotify URI', (WidgetTester tester) async {
      // Base64 encode "spotify:playlist:test123"
      final spotifyUri = 'spotify:playlist:test123';
      final base64Encoded = base64Encode(utf8.encode(spotifyUri));
      final location = '/playback/container/$base64Encoded';

      final testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: location,
        type: 'playlist',
        isPresetable: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EditSpotifyPresetPage(preset: testPreset),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals(spotifyUri));
    });

    testWidgets('displays save button', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: EditSpotifyPresetPage(preset: testPreset),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, 'Save'), findsOneWidget);
    });

    testWidgets('shows not implemented dialog when save is tapped', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: EditSpotifyPresetPage(preset: testPreset),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Not Implemented'), findsOneWidget);
      expect(find.text('Saving is not yet implemented'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'OK'), findsOneWidget);
    });

    testWidgets('shows error for invalid location format', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/invalid/path/abc123',
        type: 'playlist',
        isPresetable: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: EditSpotifyPresetPage(preset: testPreset),
        ),
      );

      expect(find.text('Invalid location format'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // TextField should be disabled
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);

      // Save button should be disabled
      final saveButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('shows error for invalid Base64', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/invalid@base64!',
        type: 'playlist',
        isPresetable: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: EditSpotifyPresetPage(preset: testPreset),
        ),
      );

      expect(find.textContaining('Failed to decode Spotify URI'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // TextField should be disabled
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('correctly decodes example from requirements', (WidgetTester tester) async {
      // Using the example from the requirements
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDoyM1NNZHlPSEE2S2t6SG9QT0o1S1E5',
        type: 'playlist',
        isPresetable: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: EditSpotifyPresetPage(preset: testPreset),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('spotify:playlist:23SMdyOHA6KkzHoPOJ5KQ9'));
    });
  });
}
