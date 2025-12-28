import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/models/spotify_account.dart';
import 'package:ueberboese_app/pages/spotify_preset_detail_page.dart';
import 'package:ueberboese_app/pages/edit_spotify_preset_page.dart';
import 'package:ueberboese_app/services/spotify_api_service.dart';

@GenerateMocks([SpotifyApiService])
import 'spotify_preset_detail_page_test.mocks.dart';

void main() {
  group('SpotifyPresetDetailPage', () {
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

    testWidgets('displays correct title', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
        sourceAccount: 'user123',
      );

      when(mockSpotifyApiService.listSpotifyAccounts(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createWidgetWithProvider(
          SpotifyPresetDetailPage(
            preset: testPreset,
            spotifyApiService: mockSpotifyApiService,
          ),
        ),
      );

      expect(find.text('Spotify Preset 1'), findsOneWidget);
    });

    testWidgets('displays preset image and name', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'My Awesome Playlist',
        containerArt: 'http://example.com/art.jpg',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
        sourceAccount: 'user123',
      );

      when(mockSpotifyApiService.listSpotifyAccounts(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createWidgetWithProvider(
          SpotifyPresetDetailPage(
            preset: testPreset,
            spotifyApiService: mockSpotifyApiService,
          ),
        ),
      );

      expect(find.text('My Awesome Playlist'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('displays preset number', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '3',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
      );

      when(mockSpotifyApiService.listSpotifyAccounts(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createWidgetWithProvider(
          SpotifyPresetDetailPage(
            preset: testPreset,
            spotifyApiService: mockSpotifyApiService,
          ),
        ),
      );

      expect(find.text('Preset Number'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('displays decoded Spotify URI', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
      );

      when(mockSpotifyApiService.listSpotifyAccounts(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createWidgetWithProvider(
          SpotifyPresetDetailPage(
            preset: testPreset,
            spotifyApiService: mockSpotifyApiService,
          ),
        ),
      );

      expect(find.text('Spotify URI'), findsOneWidget);
      expect(find.text('spotify:playlist:test'), findsOneWidget);
    });

    testWidgets('displays Spotify account when available', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
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
          SpotifyPresetDetailPage(
            preset: testPreset,
            spotifyApiService: mockSpotifyApiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Spotify Account'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('displays sourceAccount ID when fetch fails', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
        sourceAccount: 'user123',
      );

      when(mockSpotifyApiService.listSpotifyAccounts(any))
          .thenThrow(Exception('Failed to fetch accounts'));

      await tester.pumpWidget(
        createWidgetWithProvider(
          SpotifyPresetDetailPage(
            preset: testPreset,
            spotifyApiService: mockSpotifyApiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Spotify Account'), findsOneWidget);
      expect(find.text('user123'), findsOneWidget);
    });

    testWidgets('does not display Spotify account field when sourceAccount is null', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
        sourceAccount: null,
      );

      when(mockSpotifyApiService.listSpotifyAccounts(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createWidgetWithProvider(
          SpotifyPresetDetailPage(
            preset: testPreset,
            spotifyApiService: mockSpotifyApiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Spotify Account'), findsNothing);
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

      when(mockSpotifyApiService.listSpotifyAccounts(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createWidgetWithProvider(
          SpotifyPresetDetailPage(
            preset: testPreset,
            spotifyApiService: mockSpotifyApiService,
          ),
        ),
      );

      expect(find.text('Open in Spotify'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('displays error when URI decoding fails', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/invalid/location',
        type: 'playlist',
        isPresetable: true,
      );

      when(mockSpotifyApiService.listSpotifyAccounts(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createWidgetWithProvider(
          SpotifyPresetDetailPage(
            preset: testPreset,
            spotifyApiService: mockSpotifyApiService,
          ),
        ),
      );

      expect(find.text('Invalid location format'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays FAB with edit icon', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
      );

      when(mockSpotifyApiService.listSpotifyAccounts(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createWidgetWithProvider(
          SpotifyPresetDetailPage(
            preset: testPreset,
            spotifyApiService: mockSpotifyApiService,
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('tapping FAB navigates to EditSpotifyPresetPage', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
      );

      when(mockSpotifyApiService.listSpotifyAccounts(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createWidgetWithProvider(
          SpotifyPresetDetailPage(
            preset: testPreset,
            spotifyApiService: mockSpotifyApiService,
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(EditSpotifyPresetPage), findsOneWidget);
      expect(find.text('Edit Spotify Preset'), findsOneWidget);
    });

    testWidgets('has delete option in menu', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Playlist',
        source: 'SPOTIFY',
        location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDp0ZXN0',
        type: 'playlist',
        isPresetable: true,
      );

      when(mockSpotifyApiService.listSpotifyAccounts(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createWidgetWithProvider(
          SpotifyPresetDetailPage(
            preset: testPreset,
            spotifyApiService: mockSpotifyApiService,
          ),
        ),
      );

      // Open the popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Delete preset'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });
  });
}
