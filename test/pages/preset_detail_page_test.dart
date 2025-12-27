import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/models/spotify_account.dart';
import 'package:ueberboese_app/pages/preset_detail_page.dart';
import 'package:ueberboese_app/pages/edit_spotify_preset_page.dart';
import 'package:ueberboese_app/services/spotify_api_service.dart';

@GenerateMocks([SpotifyApiService])
import 'preset_detail_page_test.mocks.dart';

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

      final appState = MyAppState();
      appState.config = const AppConfig();

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: const MaterialApp(
            home: PresetDetailPage(preset: testPreset),
          ),
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

      final appState = MyAppState();
      appState.config = const AppConfig();

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: const MaterialApp(
            home: PresetDetailPage(preset: testPreset),
          ),
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

      final appState = MyAppState();
      appState.config = const AppConfig();

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: const MaterialApp(
            home: PresetDetailPage(preset: testPreset),
          ),
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

      final appState = MyAppState();
      appState.config = const AppConfig();

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: const MaterialApp(
            home: PresetDetailPage(preset: testPreset),
          ),
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

      final appState = MyAppState();
      appState.config = const AppConfig();

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: const MaterialApp(
            home: PresetDetailPage(preset: testPreset),
          ),
        ),
      );

      // Check all sections are present
      expect(find.text('Preset Number'), findsOneWidget);
      expect(find.text('Source'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('displays FAB with edit icon', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
      );

      final appState = MyAppState();
      appState.config = const AppConfig();

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: const MaterialApp(
            home: PresetDetailPage(preset: testPreset),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('tapping FAB with Spotify preset navigates to edit page', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
      );

      final appState = MyAppState();
      appState.config = const AppConfig(
        apiUrl: 'http://test.example.com',
        mgmtUsername: 'test',
        mgmtPassword: 'test',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: const MaterialApp(
            home: PresetDetailPage(preset: testPreset),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(EditSpotifyPresetPage), findsOneWidget);
      expect(find.text('Edit Spotify Preset'), findsOneWidget);
    });

    testWidgets('tapping FAB with non-Spotify preset shows error dialog', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'TUNEIN',
        location: '/v1/playback/station/s12345',
        type: 'stationurl',
        isPresetable: true,
      );

      final appState = MyAppState();
      appState.config = const AppConfig();

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: const MaterialApp(
            home: PresetDetailPage(preset: testPreset),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Editing TUNEIN presets is not yet supported'), findsOneWidget);
    });

    group('Spotify Account Display', () {
      late MyAppState appState;
      late MockSpotifyApiService mockSpotifyApiService;

      setUp(() {
        appState = MyAppState();
        appState.config = const AppConfig(
          apiUrl: 'https://api.example.com',
          mgmtUsername: 'admin',
          mgmtPassword: 'password',
        );
        mockSpotifyApiService = MockSpotifyApiService();
      });

      Widget createWidgetWithProvider(Widget child) {
        return ChangeNotifierProvider<MyAppState>.value(
          value: appState,
          child: MaterialApp(
            home: child,
          ),
        );
      }

      testWidgets('displays Spotify account name when sourceAccount is present and fetch succeeds', (WidgetTester tester) async {
        const testPreset = Preset(
          id: '1',
          itemName: 'Test Playlist',
          source: 'SPOTIFY',
          location: '/playback/container/xyz',
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
        ];

        when(mockSpotifyApiService.listSpotifyAccounts(any))
            .thenAnswer((_) async => accounts);

        await tester.pumpWidget(
          createWidgetWithProvider(
            PresetDetailPage(
              preset: testPreset,
              spotifyApiService: mockSpotifyApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should display the account display name
        expect(find.text('Spotify Account'), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
      });

      testWidgets('displays sourceAccount ID when fetch fails', (WidgetTester tester) async {
        const testPreset = Preset(
          id: '1',
          itemName: 'Test Playlist',
          source: 'SPOTIFY',
          location: '/playback/container/xyz',
          type: 'playlist',
          isPresetable: true,
          sourceAccount: 'user123',
        );

        when(mockSpotifyApiService.listSpotifyAccounts(any))
            .thenThrow(Exception('Failed to fetch accounts'));

        await tester.pumpWidget(
          createWidgetWithProvider(
            PresetDetailPage(
              preset: testPreset,
              spotifyApiService: mockSpotifyApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should display the sourceAccount ID as fallback
        expect(find.text('Spotify Account'), findsOneWidget);
        expect(find.text('user123'), findsOneWidget);
      });

      testWidgets('does not display Spotify account field when sourceAccount is null', (WidgetTester tester) async {
        const testPreset = Preset(
          id: '1',
          itemName: 'Test Playlist',
          source: 'SPOTIFY',
          location: '/playback/container/xyz',
          type: 'playlist',
          isPresetable: true,
          sourceAccount: null,
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            PresetDetailPage(
              preset: testPreset,
              spotifyApiService: mockSpotifyApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not display the Spotify Account field
        expect(find.text('Spotify Account'), findsNothing);
      });

      testWidgets('does not display Spotify account field for non-Spotify presets', (WidgetTester tester) async {
        const testPreset = Preset(
          id: '1',
          itemName: 'Test Station',
          source: 'TUNEIN',
          location: '/v1/playback/station/s12345',
          type: 'stationurl',
          isPresetable: true,
          sourceAccount: 'user123', // Has account but not Spotify
        );

        await tester.pumpWidget(
          createWidgetWithProvider(
            PresetDetailPage(
              preset: testPreset,
              spotifyApiService: mockSpotifyApiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not display the Spotify Account field
        expect(find.text('Spotify Account'), findsNothing);
      });
    });
  });
}
