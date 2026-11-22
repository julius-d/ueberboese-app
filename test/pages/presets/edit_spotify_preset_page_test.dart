import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/models/spotify_account.dart';
import 'package:ueberboese_app/models/spotify_entity.dart';
import 'package:ueberboese_app/pages/presets/edit_spotify_preset_page.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/spotify_api_service.dart';

@GenerateMocks([SpotifyApiService, SpeakerApiService])
import 'edit_spotify_preset_page_test.mocks.dart';

void main() {
  group('EditSpotifyPresetPage', () {
    late MyAppState appState;
    late MockSpotifyApiService mockApiService;
    late MockSpeakerApiService mockSpeakerApiService;

    setUp(() {
      appState = MyAppState();
      appState.config = const AppConfig(
        apiUrl: 'https://api.example.com',
        mgmtUsername: 'admin',
        mgmtPassword: 'password',
      );
      mockApiService = MockSpotifyApiService();
      mockSpeakerApiService = MockSpeakerApiService();
    });

    Widget createWidgetWithProvider(Widget child) {
      return ChangeNotifierProvider<MyAppState>.value(
        value: appState,
        child: MaterialApp(home: child),
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
          EditSpotifyPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            apiService: mockApiService,
          ),
        ),
      );

      expect(find.text('Edit Spotify Preset'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays TextField with correct label', (
      WidgetTester tester,
    ) async {
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
          EditSpotifyPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            apiService: mockApiService,
          ),
        ),
      );

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Spotify URI'), findsOneWidget);
      expect(find.text('Preset name'), findsOneWidget);
    });

    testWidgets('prefills TextField with decoded Spotify URI', (
      WidgetTester tester,
    ) async {
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
          EditSpotifyPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            apiService: mockApiService,
          ),
        ),
      );

      final uriField = tester.widget<TextField>(
        find.ancestor(
          of: find.text('Spotify URI'),
          matching: find.byType(TextField),
        ),
      );
      expect(uriField.controller?.text, equals(spotifyUri));
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
          EditSpotifyPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            apiService: mockApiService,
          ),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, 'Save'), findsOneWidget);
    });

    // Test removed: Save functionality is now implemented
    // To properly test the save functionality, we would need to mock SpeakerApiService
    // and verify that storePreset is called with the correct parameters

    testWidgets('shows error for invalid location format', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/invalid/path/abc123',
        type: 'playlist',
        isPresetable: true,
      );

      when(mockApiService.listSpotifyAccounts(any)).thenAnswer((_) async => []);

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditSpotifyPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            apiService: mockApiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Invalid location format'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Both TextFields should be disabled
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      for (final tf in textFields) {
        expect(tf.enabled, isFalse);
      }

      // Save button should be disabled
      await tester.ensureVisible(find.byType(ElevatedButton));
      final saveButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
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

      when(mockApiService.listSpotifyAccounts(any)).thenAnswer((_) async => []);

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditSpotifyPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            apiService: mockApiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.textContaining('Failed to decode Spotify URI'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Both TextFields should be disabled
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      for (final tf in textFields) {
        expect(tf.enabled, isFalse);
      }
    });

    testWidgets('correctly decodes example from requirements', (
      WidgetTester tester,
    ) async {
      // Using the example from the requirements
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location:
            '/playback/container/c3BvdGlmeTpwbGF5bGlzdDoyM1NNZHlPSEE2S2t6SG9QT0o1S1E5',
        type: 'playlist',
        isPresetable: true,
      );

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditSpotifyPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            apiService: mockApiService,
          ),
        ),
      );

      final uriField = tester.widget<TextField>(
        find.ancestor(
          of: find.text('Spotify URI'),
          matching: find.byType(TextField),
        ),
      );
      expect(
        uriField.controller?.text,
        equals('spotify:playlist:23SMdyOHA6KkzHoPOJ5KQ9'),
      );
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
          EditSpotifyPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            apiService: mockApiService,
          ),
        ),
      );

      expect(
        find.widgetWithText(OutlinedButton, 'Open in Spotify'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets(
      'Open in Spotify button is disabled when there is a decoding error',
      (WidgetTester tester) async {
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
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        final openButton = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Open in Spotify'),
        );
        expect(openButton.onPressed, isNull);
      },
    );

    testWidgets('Open in Spotify button is enabled when decoding succeeds', (
      WidgetTester tester,
    ) async {
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
          EditSpotifyPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            apiService: mockApiService,
          ),
        ),
      );

      final openButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Open in Spotify'),
      );
      expect(openButton.onPressed, isNotNull);
    });

    group('Entity Display', () {
      testWidgets('displays entity with larger image and selectable name', (
        WidgetTester tester,
      ) async {
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => []);

        when(
          mockApiService.getSpotifyEntity(any, any),
        ).thenAnswer((_) async => entity);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify image is 200x200 (larger size)
        final image = tester.widget<Image>(find.byType(Image));
        expect(image.width, equals(200));
        expect(image.height, equals(200));

        // Verify name is pre-filled in the name TextField
        final nameField = tester.widget<TextField>(
          find.ancestor(
            of: find.text('Preset name'),
            matching: find.byType(TextField),
          ),
        );
        expect(nameField.controller?.text, equals('My Favorite Songs'));
      });

      testWidgets('displays entity with image on successful fetch', (
        WidgetTester tester,
      ) async {
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => []);

        when(
          mockApiService.getSpotifyEntity(any, any),
        ).thenAnswer((_) async => entity);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        // Wait for async operations
        await tester.pumpAndSettle();

        // Should pre-fill name TextField
        final nameField = tester.widget<TextField>(
          find.ancestor(
            of: find.text('Preset name'),
            matching: find.byType(TextField),
          ),
        );
        expect(nameField.controller?.text, equals('Bohemian Rhapsody'));

        // Should display image
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('displays entity without image on successful fetch', (
        WidgetTester tester,
      ) async {
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => []);

        when(
          mockApiService.getSpotifyEntity(any, any),
        ).thenAnswer((_) async => entity);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should pre-fill name TextField
        final nameField = tester.widget<TextField>(
          find.ancestor(
            of: find.text('Preset name'),
            matching: find.byType(TextField),
          ),
        );
        expect(nameField.controller?.text, equals('My Private Playlist'));

        // Should display placeholder icon instead of image
        expect(find.byIcon(Icons.music_note), findsWidgets);
        expect(find.byType(Image), findsNothing);
      });

      testWidgets('displays error message on fetch failure', (
        WidgetTester tester,
      ) async {
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => accounts);

        when(
          mockApiService.getSpotifyEntity(any, any),
        ).thenThrow(Exception('Spotify entity not found'));

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should display error message
        expect(find.text('Spotify entity not found'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);

        // Select an account
        await tester.ensureVisible(
          find.byType(DropdownButtonFormField<SpotifyAccount>),
        );
        await tester.tap(find.byType(DropdownButtonFormField<SpotifyAccount>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('John Doe').last);
        await tester.pumpAndSettle();

        // Name field is empty → save still disabled
        await tester.ensureVisible(find.byType(ElevatedButton));
        final saveButtonBefore = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(saveButtonBefore.onPressed, isNull);

        // Typing a name enables save
        await tester.enterText(
          find.ancestor(
            of: find.text('Preset name'),
            matching: find.byType(TextField),
          ),
          'My Custom Name',
        );
        await tester.pump();

        final saveButtonAfter = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(saveButtonAfter.onPressed, isNotNull);
      });

      testWidgets('fetches entity info on URI change with debouncing', (
        WidgetTester tester,
      ) async {
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

        const newEntity = SpotifyEntity(name: 'New Playlist', imageUrl: null);

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => []);

        when(
          mockApiService.getSpotifyEntity(any, spotifyUri),
        ).thenAnswer((_) async => initialEntity);

        when(
          mockApiService.getSpotifyEntity(any, 'spotify:playlist:new456'),
        ).thenAnswer((_) async => newEntity);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initial entity name should be pre-filled in the name field
        final nameField = tester.widget<TextField>(
          find.ancestor(
            of: find.text('Preset name'),
            matching: find.byType(TextField),
          ),
        );
        expect(nameField.controller?.text, equals('Initial Playlist'));

        // Change the URI
        await tester.enterText(
          find.ancestor(
            of: find.text('Spotify URI'),
            matching: find.byType(TextField),
          ),
          'spotify:playlist:new456',
        );

        // Wait for debounce timer (500ms)
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // New entity name should be pre-filled
        expect(nameField.controller?.text, equals('New Playlist'));
      });

      testWidgets('does not fetch entity when URI is empty', (
        WidgetTester tester,
      ) async {
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

        const entity = SpotifyEntity(name: 'Test Playlist', imageUrl: null);

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => []);

        when(
          mockApiService.getSpotifyEntity(any, any),
        ).thenAnswer((_) async => entity);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Clear the URI
        await tester.enterText(
          find.ancestor(
            of: find.text('Spotify URI'),
            matching: find.byType(TextField),
          ),
          '',
        );

        // Wait for debounce
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // Name field should be cleared, no image displayed
        final nameField = tester.widget<TextField>(
          find.ancestor(
            of: find.text('Preset name'),
            matching: find.byType(TextField),
          ),
        );
        expect(nameField.controller?.text, isEmpty);
        expect(find.text('Loading entity information...'), findsNothing);
      });

      testWidgets('does not fetch entity on page load if decoding fails', (
        WidgetTester tester,
      ) async {
        const testPreset = Preset(
          id: '1',
          itemName: 'Test Playlist',
          source: 'SPOTIFY',
          location: '/invalid/path/abc123',
          type: 'playlist',
          isPresetable: true,
        );

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not have called the API
        verifyNever(mockApiService.getSpotifyEntity(any, any));

        // Should show decoding error
        expect(find.text('Invalid location format'), findsOneWidget);

        // Should not show entity loading
        expect(find.text('Loading entity information...'), findsNothing);
        // Name field should be empty and disabled
        final nameField = tester.widget<TextField>(
          find.ancestor(
            of: find.text('Preset name'),
            matching: find.byType(TextField),
          ),
        );
        expect(nameField.controller?.text, isEmpty);
        expect(nameField.enabled, isFalse);
      });
    });

    group('Spotify Account Selection', () {
      testWidgets('displays loading state while fetching accounts', (
        WidgetTester tester,
      ) async {
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
        when(mockApiService.listSpotifyAccounts(any)).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return [];
        });

        when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
          (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        // Should show loading state
        expect(find.text('Loading Spotify accounts...'), findsOneWidget);
        expect(
          find.byType(CircularProgressIndicator),
          findsNWidgets(2),
        ); // One for accounts, one for entity

        // Wait for loading to complete
        await tester.pumpAndSettle();

        // Loading state should be gone
        expect(find.text('Loading Spotify accounts...'), findsNothing);
      });

      testWidgets('displays dropdown with accounts after successful fetch', (
        WidgetTester tester,
      ) async {
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => accounts);

        when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
          (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should display dropdown
        expect(
          find.byType(DropdownButtonFormField<SpotifyAccount>),
          findsOneWidget,
        );
        expect(find.text('Spotify Account'), findsOneWidget);
      });

      testWidgets(
        'displays "No Spotify accounts connected" when list is empty',
        (WidgetTester tester) async {
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

          when(
            mockApiService.listSpotifyAccounts(any),
          ).thenAnswer((_) async => []);

          when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
            (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
          );

          await tester.pumpWidget(
            createWidgetWithProvider(
              EditSpotifyPresetPage(
                preset: testPreset,
                speakerIp: '192.168.1.100',
                apiService: mockApiService,
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Should show empty state message
          expect(find.text('No Spotify accounts connected'), findsOneWidget);
        },
      );

      testWidgets('displays error message on fetch failure', (
        WidgetTester tester,
      ) async {
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenThrow(Exception('Failed to fetch accounts'));

        when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
          (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should display error message
        expect(find.text('Failed to fetch accounts'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsWidgets);
      });

      testWidgets('updates selected account on dropdown change', (
        WidgetTester tester,
      ) async {
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => accounts);

        when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
          (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
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

      testWidgets('save button is disabled when no account is selected', (
        WidgetTester tester,
      ) async {
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => accounts);

        when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
          (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Save button should be disabled
        final saveButton = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(saveButton.onPressed, isNull);
      });

      testWidgets('save button is enabled when account is selected', (
        WidgetTester tester,
      ) async {
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => accounts);

        when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
          (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Select an account
        await tester.tap(find.byType(DropdownButtonFormField<SpotifyAccount>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('John Doe').last);
        await tester.pumpAndSettle();

        // Save button should be enabled
        final saveButton = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(saveButton.onPressed, isNotNull);
      });

      testWidgets('dropdown is disabled when decoding error exists', (
        WidgetTester tester,
      ) async {
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => accounts);
        when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
          (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => []);

        when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
          (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify API was called
        verify(
          mockApiService.listSpotifyAccounts('https://api.example.com'),
        ).called(1);
      });

      testWidgets(
        'save button is disabled when both decoding error and no account',
        (WidgetTester tester) async {
          const testPreset = Preset(
            id: '1',
            itemName: 'Test Playlist',
            source: 'SPOTIFY',
            location: '/invalid/path/abc123',
            type: 'playlist',
            isPresetable: true,
          );

          when(
            mockApiService.listSpotifyAccounts(any),
          ).thenAnswer((_) async => []);

          await tester.pumpWidget(
            createWidgetWithProvider(
              EditSpotifyPresetPage(
                preset: testPreset,
                speakerIp: '192.168.1.100',
                apiService: mockApiService,
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Save button should be disabled
          final saveButton = tester.widget<ElevatedButton>(
            find.byType(ElevatedButton),
          );
          expect(saveButton.onPressed, isNull);
        },
      );

      testWidgets(
        'preselects account when sourceAccount matches available account',
        (WidgetTester tester) async {
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
            sourceAccount: 'user123',
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

          when(
            mockApiService.listSpotifyAccounts(any),
          ).thenAnswer((_) async => accounts);

          when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
            (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
          );

          await tester.pumpWidget(
            createWidgetWithProvider(
              EditSpotifyPresetPage(
                preset: testPreset,
                speakerIp: '192.168.1.100',
                apiService: mockApiService,
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Should preselect the matching account
          final dropdown = tester
              .widget<DropdownButtonFormField<SpotifyAccount>>(
                find.byType(DropdownButtonFormField<SpotifyAccount>),
              );
          expect(dropdown.initialValue?.spotifyUserId, 'user123');
          expect(dropdown.initialValue?.displayName, 'John Doe');
        },
      );

      testWidgets(
        'does not preselect when sourceAccount does not match any account',
        (WidgetTester tester) async {
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
            sourceAccount: 'unknown_user',
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

          when(
            mockApiService.listSpotifyAccounts(any),
          ).thenAnswer((_) async => accounts);

          when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
            (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
          );

          await tester.pumpWidget(
            createWidgetWithProvider(
              EditSpotifyPresetPage(
                preset: testPreset,
                speakerIp: '192.168.1.100',
                apiService: mockApiService,
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Should not preselect any account
          final dropdown = tester
              .widget<DropdownButtonFormField<SpotifyAccount>>(
                find.byType(DropdownButtonFormField<SpotifyAccount>),
              );
          expect(dropdown.initialValue, isNull);
        },
      );

      testWidgets('does not preselect when sourceAccount is null', (
        WidgetTester tester,
      ) async {
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
          sourceAccount: null,
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => accounts);

        when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
          (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not preselect any account
        final dropdown = tester.widget<DropdownButtonFormField<SpotifyAccount>>(
          find.byType(DropdownButtonFormField<SpotifyAccount>),
        );
        expect(dropdown.initialValue, isNull);
      });
    });

    group('URL to URI Conversion', () {
      testWidgets('converts Spotify URL to URI automatically on text change', (
        WidgetTester tester,
      ) async {
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => []);

        when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
          (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter a Spotify URL
        final uriFinder = find.ancestor(
          of: find.text('Spotify URI'),
          matching: find.byType(TextField),
        );
        await tester.enterText(
          uriFinder,
          'https://open.spotify.com/playlist/23SMdyOHA6KkzHoPOJ5KQ9',
        );

        await tester.pump();

        // Should automatically convert to URI
        final textField = tester.widget<TextField>(uriFinder);
        expect(
          textField.controller?.text,
          equals('spotify:playlist:23SMdyOHA6KkzHoPOJ5KQ9'),
        );
      });

      testWidgets('handles URL with query parameters', (
        WidgetTester tester,
      ) async {
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => []);

        when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
          (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter a Spotify URL with query parameters
        final uriFinder = find.ancestor(
          of: find.text('Spotify URI'),
          matching: find.byType(TextField),
        );
        await tester.enterText(
          uriFinder,
          'https://open.spotify.com/playlist/23SMdyOHA6KkzHoPOJ5KQ9?si=abc123xyz',
        );

        await tester.pump();

        // Should convert to URI without query params
        final textField = tester.widget<TextField>(uriFinder);
        expect(
          textField.controller?.text,
          equals('spotify:playlist:23SMdyOHA6KkzHoPOJ5KQ9'),
        );
      });

      testWidgets('keeps URI format unchanged', (WidgetTester tester) async {
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => []);

        when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
          (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter a Spotify URI
        final uriFinder = find.ancestor(
          of: find.text('Spotify URI'),
          matching: find.byType(TextField),
        );
        await tester.enterText(uriFinder, 'spotify:playlist:newPlaylist123');

        await tester.pump();

        // Should stay as URI
        final textField = tester.widget<TextField>(uriFinder);
        expect(
          textField.controller?.text,
          equals('spotify:playlist:newPlaylist123'),
        );
      });

      testWidgets('supports different content types', (
        WidgetTester tester,
      ) async {
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => []);

        when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
          (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        final uriFinder = find.ancestor(
          of: find.text('Spotify URI'),
          matching: find.byType(TextField),
        );

        // Test track
        await tester.enterText(
          uriFinder,
          'https://open.spotify.com/track/6rqhFgbbKwnb9MLmUQDhG6',
        );
        await tester.pump();
        var textField = tester.widget<TextField>(uriFinder);
        expect(
          textField.controller?.text,
          equals('spotify:track:6rqhFgbbKwnb9MLmUQDhG6'),
        );

        // Test album
        await tester.enterText(
          uriFinder,
          'https://open.spotify.com/album/1DFixLWuPkv3KT3TnV35m3',
        );
        await tester.pump();
        textField = tester.widget<TextField>(uriFinder);
        expect(
          textField.controller?.text,
          equals('spotify:album:1DFixLWuPkv3KT3TnV35m3'),
        );

        // Test artist
        await tester.enterText(
          uriFinder,
          'https://open.spotify.com/artist/1vCWHaC5f2uS3yhpwWbIA6',
        );
        await tester.pump();
        textField = tester.widget<TextField>(uriFinder);
        expect(
          textField.controller?.text,
          equals('spotify:artist:1vCWHaC5f2uS3yhpwWbIA6'),
        );

        // Test show
        await tester.enterText(
          uriFinder,
          'https://open.spotify.com/show/6ups0LMt1G8n81XLlkbsPo',
        );
        await tester.pump();
        textField = tester.widget<TextField>(uriFinder);
        expect(
          textField.controller?.text,
          equals('spotify:show:6ups0LMt1G8n81XLlkbsPo'),
        );

        // Test episode
        await tester.enterText(
          uriFinder,
          'https://open.spotify.com/episode/512ojhOuo1ktJprKbVcKyQ',
        );
        await tester.pump();
        textField = tester.widget<TextField>(uriFinder);
        expect(
          textField.controller?.text,
          equals('spotify:episode:512ojhOuo1ktJprKbVcKyQ'),
        );
      });

      testWidgets('handles invalid URLs gracefully', (
        WidgetTester tester,
      ) async {
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

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => []);

        when(mockApiService.getSpotifyEntity(any, any)).thenAnswer(
          (_) async => const SpotifyEntity(name: 'Test', imageUrl: null),
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        final uriFinder = find.ancestor(
          of: find.text('Spotify URI'),
          matching: find.byType(TextField),
        );

        // Enter an invalid URL (not a Spotify URL)
        await tester.enterText(uriFinder, 'https://example.com/playlist/123');

        await tester.pump();

        // Should remain unchanged (no conversion)
        final textField = tester.widget<TextField>(uriFinder);
        expect(
          textField.controller?.text,
          equals('https://example.com/playlist/123'),
        );

        // Enter an invalid Spotify URL (missing ID)
        await tester.enterText(uriFinder, 'https://open.spotify.com/playlist/');

        await tester.pump();

        // Should remain unchanged
        final textField2 = tester.widget<TextField>(uriFinder);
        expect(
          textField2.controller?.text,
          equals('https://open.spotify.com/playlist/'),
        );
      });
    });

    group('Empty/new preset', () {
      testWidgets(
        'shows no error and enables controls when location is empty (new preset)',
        (WidgetTester tester) async {
          const testPreset = Preset(
            id: '1',
            itemName: 'Empty Preset',
            source: 'NONE',
            location: '',
            type: 'none',
            isPresetable: true,
          );

          when(
            mockApiService.listSpotifyAccounts(any),
          ).thenAnswer((_) async => []);

          await tester.pumpWidget(
            createWidgetWithProvider(
              EditSpotifyPresetPage(
                preset: testPreset,
                speakerIp: '192.168.1.100',
                apiService: mockApiService,
              ),
            ),
          );

          await tester.pumpAndSettle();

          // No decoding error should be shown
          expect(find.text('Invalid location format'), findsNothing);
          expect(find.textContaining('Failed to decode'), findsNothing);

          // Both TextFields should be enabled and empty
          final uriField = tester.widget<TextField>(
            find.ancestor(
              of: find.text('Spotify URI'),
              matching: find.byType(TextField),
            ),
          );
          expect(uriField.enabled, isTrue);
          expect(uriField.controller?.text, isEmpty);
          final nameField = tester.widget<TextField>(
            find.ancestor(
              of: find.text('Preset name'),
              matching: find.byType(TextField),
            ),
          );
          expect(nameField.enabled, isTrue);
          expect(nameField.controller?.text, isEmpty);
        },
      );

      testWidgets('accounts are fetched when location is empty', (
        WidgetTester tester,
      ) async {
        const testPreset = Preset(
          id: '1',
          itemName: 'Empty Preset',
          source: 'NONE',
          location: '',
          type: 'none',
          isPresetable: true,
        );

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        verify(
          mockApiService.listSpotifyAccounts('https://api.example.com'),
        ).called(1);
      });

      testWidgets('accounts are fetched even when location is invalid', (
        WidgetTester tester,
      ) async {
        const testPreset = Preset(
          id: '1',
          itemName: 'Test Playlist',
          source: 'SPOTIFY',
          location: '/invalid/path/abc123',
          type: 'playlist',
          isPresetable: true,
        );

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '192.168.1.100',
              apiService: mockApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        verify(
          mockApiService.listSpotifyAccounts('https://api.example.com'),
        ).called(1);
      });
    });

    group('Save', () {
      testWidgets('uses provided speakerIp when saving preset', (
        WidgetTester tester,
      ) async {
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

        const entity = SpotifyEntity(name: 'Test Playlist', imageUrl: null);

        when(
          mockApiService.listSpotifyAccounts(any),
        ).thenAnswer((_) async => accounts);
        when(
          mockApiService.getSpotifyEntity(any, any),
        ).thenAnswer((_) async => entity);
        when(
          mockSpeakerApiService.storePreset(any, any, any, any, any, any),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(
          createWidgetWithProvider(
            EditSpotifyPresetPage(
              preset: testPreset,
              speakerIp: '10.0.0.42',
              apiService: mockApiService,
              speakerApiService: mockSpeakerApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Select account
        await tester.tap(find.byType(DropdownButtonFormField<SpotifyAccount>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('John Doe').last);
        await tester.pumpAndSettle();

        // Tap save
        await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Save'));
        await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
        await tester.pump();

        verify(
          mockSpeakerApiService.storePreset(
            '10.0.0.42',
            '1',
            spotifyUri,
            'user123',
            'Test Playlist',
            null,
          ),
        ).called(1);
      });

      testWidgets(
        'uses edited name field value instead of entity name when saving',
        (WidgetTester tester) async {
          const spotifyUri = 'spotify:playlist:test123';
          final base64Encoded = base64Encode(utf8.encode(spotifyUri));
          final location = '/playback/container/$base64Encoded';

          final testPreset = Preset(
            id: '2',
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

          const entity = SpotifyEntity(
            name: 'Auto Fetched Name',
            imageUrl: null,
          );

          when(
            mockApiService.listSpotifyAccounts(any),
          ).thenAnswer((_) async => accounts);
          when(
            mockApiService.getSpotifyEntity(any, any),
          ).thenAnswer((_) async => entity);
          when(
            mockSpeakerApiService.storePreset(any, any, any, any, any, any),
          ).thenAnswer((_) async => []);

          await tester.pumpWidget(
            createWidgetWithProvider(
              EditSpotifyPresetPage(
                preset: testPreset,
                speakerIp: '192.168.1.1',
                apiService: mockApiService,
                speakerApiService: mockSpeakerApiService,
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Edit the name field
          await tester.enterText(
            find.ancestor(
              of: find.text('Preset name'),
              matching: find.byType(TextField),
            ),
            'My Custom Name',
          );
          await tester.pump();

          // Select account
          await tester.tap(
            find.byType(DropdownButtonFormField<SpotifyAccount>),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('John Doe').last);
          await tester.pumpAndSettle();

          // Tap save
          await tester.ensureVisible(
            find.widgetWithText(ElevatedButton, 'Save'),
          );
          await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
          await tester.pump();

          verify(
            mockSpeakerApiService.storePreset(
              '192.168.1.1',
              '2',
              spotifyUri,
              'user123',
              'My Custom Name',
              null,
            ),
          ).called(1);
        },
      );

      testWidgets(
        'fetch failure — saves with manually typed name and null imageUrl',
        (WidgetTester tester) async {
          const spotifyUri = 'spotify:playlist:test123';
          final base64Encoded = base64Encode(utf8.encode(spotifyUri));
          final location = '/playback/container/$base64Encoded';

          final testPreset = Preset(
            id: '3',
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

          when(
            mockApiService.listSpotifyAccounts(any),
          ).thenAnswer((_) async => accounts);
          when(
            mockApiService.getSpotifyEntity(any, any),
          ).thenThrow(Exception('Network error'));
          when(
            mockSpeakerApiService.storePreset(any, any, any, any, any, any),
          ).thenAnswer((_) async => []);

          await tester.pumpWidget(
            createWidgetWithProvider(
              EditSpotifyPresetPage(
                preset: testPreset,
                speakerIp: '192.168.1.1',
                apiService: mockApiService,
                speakerApiService: mockSpeakerApiService,
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Select account
          await tester.tap(
            find.byType(DropdownButtonFormField<SpotifyAccount>),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('John Doe').last);
          await tester.pumpAndSettle();

          // Name field is empty → save disabled
          var saveButton = tester.widget<ElevatedButton>(
            find.byType(ElevatedButton),
          );
          expect(saveButton.onPressed, isNull);

          // Type a name
          await tester.enterText(
            find.ancestor(
              of: find.text('Preset name'),
              matching: find.byType(TextField),
            ),
            'Typed Name',
          );
          await tester.pump();

          // Save should now be enabled
          saveButton = tester.widget<ElevatedButton>(
            find.byType(ElevatedButton),
          );
          expect(saveButton.onPressed, isNotNull);

          // Tap save
          await tester.ensureVisible(
            find.widgetWithText(ElevatedButton, 'Save'),
          );
          await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
          await tester.pump();

          verify(
            mockSpeakerApiService.storePreset(
              '192.168.1.1',
              '3',
              spotifyUri,
              'user123',
              'Typed Name',
              null,
            ),
          ).called(1);
        },
      );
    });
  });
}
