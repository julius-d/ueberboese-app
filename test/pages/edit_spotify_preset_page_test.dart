import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/models/spotify_account.dart';
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
      const spotifyUri = 'spotify:playlist:test123';
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

    // Test removed: Save functionality is now implemented
    // To properly test the save functionality, we would need to mock SpeakerApiService
    // and verify that storePreset is called with the correct parameters

    testWidgets('shows error for invalid location format', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/invalid/path/abc123',
        type: 'playlist',
        isPresetable: true,
      );

      when(mockApiService.listSpotifyAccounts(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Invalid location format'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // TextField should be disabled
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);

      // Save button should be disabled
      await tester.ensureVisible(find.byType(ElevatedButton));
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

      when(mockApiService.listSpotifyAccounts(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

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
      testWidgets('displays entity with larger image and selectable name', (WidgetTester tester) async {
        const spotifyUri = 'spotify:playlist:test123';
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
          name: 'My Favorite Songs',
          imageUrl: 'https://i.scdn.co/image/test.jpg',
        );

        when(mockApiService.listSpotifyAccounts(any))
            .thenAnswer((_) async => []);

        when(mockApiService.getSpotifyEntity(any, any))
            .thenAnswer((_) async => entity);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        // Verify image is 200x200 (larger size)
        final image = tester.widget<Image>(find.byType(Image));
        expect(image.width, equals(200));
        expect(image.height, equals(200));

        // Verify name is displayed as SelectableText (allows copy/paste)
        expect(find.byType(SelectableText), findsOneWidget);
        final selectableText = tester.widget<SelectableText>(find.byType(SelectableText));
        expect(selectableText.data, equals('My Favorite Songs'));

        // Verify centered layout
        final column = tester.widget<Column>(
          find.ancestor(
            of: find.byType(SelectableText),
            matching: find.byType(Column),
          ).first,
        );
        expect(column.crossAxisAlignment, equals(CrossAxisAlignment.center));
      });

      testWidgets('displays entity with image on successful fetch', (WidgetTester tester) async {
        const spotifyUri = 'spotify:playlist:test123';
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

        when(mockApiService.listSpotifyAccounts(any))
            .thenAnswer((_) async => []);

        when(mockApiService.getSpotifyEntity(any, any))
            .thenAnswer((_) async => entity);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        // Wait for async operations
        await tester.pumpAndSettle();

        // Should display entity name as selectable text
        expect(find.byType(SelectableText), findsOneWidget);
        final selectableText = tester.widget<SelectableText>(find.byType(SelectableText));
        expect(selectableText.data, equals('Bohemian Rhapsody'));

        // Should display image
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('displays entity without image on successful fetch', (WidgetTester tester) async {
        const spotifyUri = 'spotify:playlist:test123';
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

        when(mockApiService.listSpotifyAccounts(any))
            .thenAnswer((_) async => []);

        when(mockApiService.getSpotifyEntity(any, any))
            .thenAnswer((_) async => entity);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        // Should display entity name as selectable text
        expect(find.byType(SelectableText), findsOneWidget);
        final selectableText = tester.widget<SelectableText>(find.byType(SelectableText));
        expect(selectableText.data, equals('My Private Playlist'));

        // Should display placeholder icon instead of image
        expect(find.byIcon(Icons.music_note), findsWidgets);
        expect(find.byType(Image), findsNothing);
      });

      testWidgets('displays error message on fetch failure', (WidgetTester tester) async {
        const spotifyUri = 'spotify:playlist:test123';
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

        final accounts = [
          SpotifyAccount(
            displayName: 'John Doe',
            createdAt: DateTime(2024, 1, 1),
            spotifyUserId: 'user123',
          ),
        ];

        when(mockApiService.listSpotifyAccounts(any))
            .thenAnswer((_) async => accounts);

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

        // Select an account so save button can be enabled
        await tester.ensureVisible(find.byType(DropdownButtonFormField<SpotifyAccount>));
        await tester.tap(find.byType(DropdownButtonFormField<SpotifyAccount>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('John Doe').last);
        await tester.pumpAndSettle();

        // Save button should be disabled when entity fetch fails (entity is required for save)
        await tester.ensureVisible(find.byType(ElevatedButton));
        final saveButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(saveButton.onPressed, isNull);
      });

      testWidgets('fetches entity info on URI change with debouncing', (WidgetTester tester) async {
        const spotifyUri = 'spotify:playlist:test123';
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

        when(mockApiService.listSpotifyAccounts(any))
            .thenAnswer((_) async => []);

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
        const spotifyUri = 'spotify:playlist:test123';
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

        when(mockApiService.listSpotifyAccounts(any))
            .thenAnswer((_) async => []);

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
        expect(find.byType(SelectableText), findsNothing);
        expect(find.text('Loading entity information...'), findsNothing);
      });

      testWidgets('does not fetch entity on page load if decoding fails', (WidgetTester tester) async {
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

        await tester.pumpAndSettle();

        // Should not have called the API
        verifyNever(mockApiService.getSpotifyEntity(any, any));

        // Should show decoding error
        expect(find.text('Invalid location format'), findsOneWidget);

        // Should not show entity loading or display
        expect(find.text('Loading entity information...'), findsNothing);
        expect(find.byType(SelectableText), findsNothing);
      });
    });

    group('Spotify Account Selection', () {
      testWidgets('displays loading state while fetching accounts', (WidgetTester tester) async {
        const spotifyUri = 'spotify:playlist:test123';
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

        // Delay the account fetch to simulate loading
        when(mockApiService.listSpotifyAccounts(any))
            .thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return [];
        });

        when(mockApiService.getSpotifyEntity(any, any))
            .thenAnswer((_) async => const SpotifyEntity(name: 'Test', imageUrl: null));

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        // Should show loading state
        expect(find.text('Loading Spotify accounts...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNWidgets(2)); // One for accounts, one for entity

        // Wait for loading to complete
        await tester.pumpAndSettle();

        // Loading state should be gone
        expect(find.text('Loading Spotify accounts...'), findsNothing);
      });

      testWidgets('displays dropdown with accounts after successful fetch', (WidgetTester tester) async {
        const spotifyUri = 'spotify:playlist:test123';
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

        final accounts = [
          SpotifyAccount(
            displayName: 'John Doe',
            createdAt: DateTime(2024, 1, 1),
            spotifyUserId: 'user123',
          ),
          SpotifyAccount(
            displayName: 'Jane Smith',
            createdAt: DateTime(2024, 1, 2),
            spotifyUserId: 'user456',
          ),
        ];

        when(mockApiService.listSpotifyAccounts(any))
            .thenAnswer((_) async => accounts);

        when(mockApiService.getSpotifyEntity(any, any))
            .thenAnswer((_) async => const SpotifyEntity(name: 'Test', imageUrl: null));

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        // Should display dropdown
        expect(find.byType(DropdownButtonFormField<SpotifyAccount>), findsOneWidget);
        expect(find.text('Spotify Account'), findsOneWidget);
      });

      testWidgets('displays "No Spotify accounts connected" when list is empty', (WidgetTester tester) async {
        const spotifyUri = 'spotify:playlist:test123';
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

        when(mockApiService.listSpotifyAccounts(any))
            .thenAnswer((_) async => []);

        when(mockApiService.getSpotifyEntity(any, any))
            .thenAnswer((_) async => const SpotifyEntity(name: 'Test', imageUrl: null));

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        // Should show empty state message
        expect(find.text('No Spotify accounts connected'), findsOneWidget);
      });

      testWidgets('displays error message on fetch failure', (WidgetTester tester) async {
        const spotifyUri = 'spotify:playlist:test123';
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

        when(mockApiService.listSpotifyAccounts(any))
            .thenThrow(Exception('Failed to fetch accounts'));

        when(mockApiService.getSpotifyEntity(any, any))
            .thenAnswer((_) async => const SpotifyEntity(name: 'Test', imageUrl: null));

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        // Should display error message
        expect(find.text('Failed to fetch accounts'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsWidgets);
      });

      testWidgets('updates selected account on dropdown change', (WidgetTester tester) async {
        const spotifyUri = 'spotify:playlist:test123';
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

        final accounts = [
          SpotifyAccount(
            displayName: 'John Doe',
            createdAt: DateTime(2024, 1, 1),
            spotifyUserId: 'user123',
          ),
          SpotifyAccount(
            displayName: 'Jane Smith',
            createdAt: DateTime(2024, 1, 2),
            spotifyUserId: 'user456',
          ),
        ];

        when(mockApiService.listSpotifyAccounts(any))
            .thenAnswer((_) async => accounts);

        when(mockApiService.getSpotifyEntity(any, any))
            .thenAnswer((_) async => const SpotifyEntity(name: 'Test', imageUrl: null));

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        // Open dropdown
        await tester.tap(find.byType(DropdownButtonFormField<SpotifyAccount>));
        await tester.pumpAndSettle();

        // Select first account
        await tester.tap(find.text('John Doe').last);
        await tester.pumpAndSettle();

        // Should show selected account
        expect(find.text('John Doe'), findsWidgets);
      });

      testWidgets('save button is disabled when no account is selected', (WidgetTester tester) async {
        const spotifyUri = 'spotify:playlist:test123';
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

        final accounts = [
          SpotifyAccount(
            displayName: 'John Doe',
            createdAt: DateTime(2024, 1, 1),
            spotifyUserId: 'user123',
          ),
        ];

        when(mockApiService.listSpotifyAccounts(any))
            .thenAnswer((_) async => accounts);

        when(mockApiService.getSpotifyEntity(any, any))
            .thenAnswer((_) async => const SpotifyEntity(name: 'Test', imageUrl: null));

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        // Save button should be disabled
        final saveButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(saveButton.onPressed, isNull);
      });

      testWidgets('save button is enabled when account is selected', (WidgetTester tester) async {
        const spotifyUri = 'spotify:playlist:test123';
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

        final accounts = [
          SpotifyAccount(
            displayName: 'John Doe',
            createdAt: DateTime(2024, 1, 1),
            spotifyUserId: 'user123',
          ),
        ];

        when(mockApiService.listSpotifyAccounts(any))
            .thenAnswer((_) async => accounts);

        when(mockApiService.getSpotifyEntity(any, any))
            .thenAnswer((_) async => const SpotifyEntity(name: 'Test', imageUrl: null));

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        // Select an account
        await tester.tap(find.byType(DropdownButtonFormField<SpotifyAccount>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('John Doe').last);
        await tester.pumpAndSettle();

        // Save button should be enabled
        final saveButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(saveButton.onPressed, isNotNull);
      });

      testWidgets('dropdown is disabled when decoding error exists', (WidgetTester tester) async {
        const testPreset = Preset(
          id: '1',
          itemName: 'Test Playlist',
          source: 'SPOTIFY',
          location: '/invalid/path/abc123',
          type: 'playlist',
          isPresetable: true,
        );

        final accounts = [
          SpotifyAccount(
            displayName: 'John Doe',
            createdAt: DateTime(2024, 1, 1),
            spotifyUserId: 'user123',
          ),
        ];

        when(mockApiService.listSpotifyAccounts(any))
            .thenAnswer((_) async => accounts);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        // Dropdown should be disabled
        final dropdown = tester.widget<DropdownButtonFormField<SpotifyAccount>>(
          find.byType(DropdownButtonFormField<SpotifyAccount>),
        );
        expect(dropdown.onChanged, isNull);
      });

      testWidgets('fetches accounts on page load', (WidgetTester tester) async {
        const spotifyUri = 'spotify:playlist:test123';
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

        when(mockApiService.listSpotifyAccounts(any))
            .thenAnswer((_) async => []);

        when(mockApiService.getSpotifyEntity(any, any))
            .thenAnswer((_) async => const SpotifyEntity(name: 'Test', imageUrl: null));

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        // Verify API was called
        verify(mockApiService.listSpotifyAccounts('https://api.example.com')).called(1);
      });

      testWidgets('save button is disabled when both decoding error and no account', (WidgetTester tester) async {
        const testPreset = Preset(
          id: '1',
          itemName: 'Test Playlist',
          source: 'SPOTIFY',
          location: '/invalid/path/abc123',
          type: 'playlist',
          isPresetable: true,
        );

        when(mockApiService.listSpotifyAccounts(any))
            .thenAnswer((_) async => []);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(preset: testPreset, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        // Save button should be disabled
        final saveButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(saveButton.onPressed, isNull);
      });
    });
  });
}
