import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/models/spotify_entity.dart';
import 'package:ueberboese_app/pages/edit_spotify_preset_page.dart';
import 'package:ueberboese_app/services/spotify_api_service.dart';

@GenerateMocks([SpotifyApiService])
import 'edit_spotify_preset_page_test.mocks.dart';

void main() {
  group('EditSpotifyPresetPage', () {
    late MyAppState appState;
    late MockSpotifyApiService mockApiService;

    setUp(() {
      appState = MyAppState();
      appState.config = const AppConfig(
        apiUrl: 'https://api.example.com',
        mgmtUsername: 'admin',
        mgmtPassword: 'password',
      );
      mockApiService = MockSpotifyApiService();
    });

    Widget createWidgetWithProvider(Widget child) {
      return ChangeNotifierProvider<MyAppState>.value(
        value: appState,
        child: MaterialApp(
          home: child,
        ),
      );
    }

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
        createWidgetWithProvider(
          EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
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
        createWidgetWithProvider(
          EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
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
        createWidgetWithProvider(
          EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
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
        createWidgetWithProvider(
          EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
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
        createWidgetWithProvider(
          EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
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
        createWidgetWithProvider(
          EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
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
        createWidgetWithProvider(
          EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
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
        createWidgetWithProvider(
          EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('spotify:playlist:23SMdyOHA6KkzHoPOJ5KQ9'));
    });

    testWidgets('displays Open in Spotify button', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
      );

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
        ),
      );

      expect(find.widgetWithText(OutlinedButton, 'Open in Spotify'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('Open in Spotify button is disabled when there is a decoding error', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/invalid/path/abc123',
        type: 'playlist',
        isPresetable: true,
      );

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
        ),
      );

      final openButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Open in Spotify'),
      );
      expect(openButton.onPressed, isNull);
    });

    testWidgets('Open in Spotify button is enabled when decoding succeeds', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
      );

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
        ),
      );

      final openButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Open in Spotify'),
      );
      expect(openButton.onPressed, isNotNull);
    });

    group('Entity Display', () {
      testWidgets('displays entity with image on successful fetch', (WidgetTester tester) async {
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

        const entity = SpotifyEntity(
          name: 'Bohemian Rhapsody',
          imageUrl: 'https://i.scdn.co/image/test.jpg',
        );

        when(mockApiService.getSpotifyEntity(any, any))
            .thenAnswer((_) async => entity);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        // Wait for async operations
        await tester.pumpAndSettle();

        // Should display entity name
        expect(find.text('Bohemian Rhapsody'), findsOneWidget);
        expect(find.text('Spotify Entity'), findsOneWidget);

        // Should display image
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('displays entity without image on successful fetch', (WidgetTester tester) async {
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

        const entity = SpotifyEntity(
          name: 'My Private Playlist',
          imageUrl: null,
        );

        when(mockApiService.getSpotifyEntity(any, any))
            .thenAnswer((_) async => entity);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        // Should display entity name
        expect(find.text('My Private Playlist'), findsOneWidget);
        expect(find.text('Spotify Entity'), findsOneWidget);

        // Should display placeholder icon instead of image
        expect(find.byIcon(Icons.music_note), findsWidgets);
        expect(find.byType(Image), findsNothing);
      });

      testWidgets('displays error message on fetch failure', (WidgetTester tester) async {
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

        when(mockApiService.getSpotifyEntity(any, any))
            .thenThrow(Exception('Spotify entity not found'));

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        // Should display error message
        expect(find.text('Spotify entity not found'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);

        // Save button should still be enabled despite entity fetch error
        final saveButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(saveButton.onPressed, isNotNull);
      });

      testWidgets('fetches entity info on URI change with debouncing', (WidgetTester tester) async {
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

        const initialEntity = SpotifyEntity(
          name: 'Initial Playlist',
          imageUrl: null,
        );

        const newEntity = SpotifyEntity(
          name: 'New Playlist',
          imageUrl: null,
        );

        when(mockApiService.getSpotifyEntity(any, spotifyUri))
            .thenAnswer((_) async => initialEntity);

        when(mockApiService.getSpotifyEntity(any, 'spotify:playlist:new456'))
            .thenAnswer((_) async => newEntity);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        // Initial entity should be displayed
        expect(find.text('Initial Playlist'), findsOneWidget);

        // Change the URI
        await tester.enterText(find.byType(TextField), 'spotify:playlist:new456');

        // Wait for debounce timer (500ms)
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // New entity should be displayed
        expect(find.text('New Playlist'), findsOneWidget);
        expect(find.text('Initial Playlist'), findsNothing);
      });

      testWidgets('does not fetch entity when URI is empty', (WidgetTester tester) async {
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

        const entity = SpotifyEntity(
          name: 'Test Playlist',
          imageUrl: null,
        );

        when(mockApiService.getSpotifyEntity(any, any))
            .thenAnswer((_) async => entity);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        // Clear the URI
        await tester.enterText(find.byType(TextField), '');

        // Wait for debounce
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // No entity display should be visible
        expect(find.text('Test Playlist'), findsNothing);
        expect(find.text('Spotify Entity'), findsNothing);
        expect(find.text('Loading entity information...'), findsNothing);
      });

      testWidgets('does not fetch entity on page load if decoding fails', (WidgetTester tester) async {
        final testPreset = Preset(
          id: '1',
          itemName: 'Test Playlist',
          source: 'SPOTIFY',
          location: '/invalid/path/abc123',
          type: 'playlist',
          isPresetable: true,
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        // Should not have called the API
        verifyNever(mockApiService.getSpotifyEntity(any, any));

        // Should show decoding error
        expect(find.text('Invalid location format'), findsOneWidget);

        // Should not show entity loading or display
        expect(find.text('Loading entity information...'), findsNothing);
        expect(find.text('Spotify Entity'), findsNothing);
      });
    });
  });
}
