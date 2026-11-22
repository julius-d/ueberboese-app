import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/recent.dart';
import 'package:ueberboese_app/pages/recents_page.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';

import 'recents_page_test.mocks.dart';

@GenerateMocks([SpeakerApiService])
void main() {
  group('RecentsPage', () {
    late MockSpeakerApiService mockApiService;
    const testSpeaker = Speaker(
      id: '1',
      name: 'Test Speaker',
      emoji: '🔊',
      ipAddress: '192.168.1.100',
      type: 'SoundTouch 10',
      deviceId: 'device-123',
    );

    setUp(() {
      mockApiService = MockSpeakerApiService();
    });

    testWidgets('shows loading indicator initially', (
      WidgetTester tester,
    ) async {
      when(mockApiService.getRecents(any)).thenAnswer((_) async => <Recent>[]);

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(speaker: testSpeaker, apiService: mockApiService),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays "No recent items" when list is empty', (
      WidgetTester tester,
    ) async {
      when(mockApiService.getRecents(any)).thenAnswer((_) async => <Recent>[]);

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(speaker: testSpeaker, apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No recent items'), findsOneWidget);
    });

    testWidgets('displays recents list when data is loaded', (
      WidgetTester tester,
    ) async {
      final testRecents = [
        const Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Radio TEDDY',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        ),
        const Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768304677,
          id: '4',
          itemName: 'Komplett Entspannt',
          source: 'SPOTIFY',
          location:
              '/playback/container/c3BvdGlmeTpwbGF5bGlzdDoybjZXMnA1QzBNQUQ5YTR6NXhUVDdu',
          type: 'tracklisturl',
          isPresetable: true,
          sourceAccount: 'z5zt8py3wuxytbza4cxa431ge',
        ),
      ];

      when(mockApiService.getRecents(any)).thenAnswer((_) async => testRecents);

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(speaker: testSpeaker, apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Radio TEDDY'), findsOneWidget);
      expect(find.text('Komplett Entspannt'), findsOneWidget);
      expect(find.text('TUNEIN'), findsOneWidget);
      expect(find.text('SPOTIFY'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('displays error message and retry button on error', (
      WidgetTester tester,
    ) async {
      when(mockApiService.getRecents(any)).thenAnswer(
        (_) async => throw Exception('Failed to fetch recents: HTTP 500'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(speaker: testSpeaker, apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load recents'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('retry button reloads recents', (WidgetTester tester) async {
      // First call fails
      when(mockApiService.getRecents(any)).thenAnswer(
        (_) async => throw Exception('Failed to fetch recents: HTTP 500'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(speaker: testSpeaker, apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load recents'), findsOneWidget);

      // Second call succeeds
      final testRecents = [
        const Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Radio TEDDY',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        ),
      ];

      when(mockApiService.getRecents(any)).thenAnswer((_) async => testRecents);

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Radio TEDDY'), findsOneWidget);
      expect(find.text('Failed to load recents'), findsNothing);
    });

    testWidgets(
      'displays speaker emoji and name in app bar and Recent title on page',
      (WidgetTester tester) async {
        when(
          mockApiService.getRecents(any),
        ).thenAnswer((_) async => <Recent>[]);

        await tester.pumpWidget(
          MaterialApp(
            home: RecentsPage(speaker: testSpeaker, apiService: mockApiService),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('🔊'), findsOneWidget);
        expect(find.text('Test Speaker'), findsOneWidget);
        expect(find.text('Recent'), findsOneWidget);
      },
    );

    testWidgets('calls getRecents with correct IP address', (
      WidgetTester tester,
    ) async {
      when(mockApiService.getRecents(any)).thenAnswer((_) async => <Recent>[]);

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(speaker: testSpeaker, apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

      verify(mockApiService.getRecents('192.168.1.100')).called(1);
    });

    testWidgets('displays containerArt when available', (
      WidgetTester tester,
    ) async {
      final testRecents = [
        const Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Radio TEDDY',
          containerArt: 'http://cdn.example.com/logo.png',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        ),
      ];

      when(mockApiService.getRecents(any)).thenAnswer((_) async => testRecents);

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(speaker: testSpeaker, apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('tapping play button calls selectContentItem', (
      WidgetTester tester,
    ) async {
      final testRecents = [
        const Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Radio TEDDY',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        ),
      ];

      when(mockApiService.getRecents(any)).thenAnswer((_) async => testRecents);

      when(
        mockApiService.selectContentItem(any, any),
      ).thenAnswer((_) async => Future<void>.value());

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(speaker: testSpeaker, apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the play button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Verify selectContentItem was called
      verify(
        mockApiService.selectContentItem('192.168.1.100', testRecents[0]),
      ).called(1);
    });

    testWidgets('shows loading indicator while playing', (
      WidgetTester tester,
    ) async {
      final testRecents = [
        const Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Radio TEDDY',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        ),
      ];

      when(mockApiService.getRecents(any)).thenAnswer((_) async => testRecents);

      when(mockApiService.selectContentItem(any, any)).thenAnswer(
        (_) async => Future.delayed(const Duration(milliseconds: 100)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(speaker: testSpeaker, apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

      // Verify play icon is shown initially
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Tap on the play button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);

      // Wait for completion
      await tester.pumpAndSettle();

      // Verify play icon returns
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows success SnackBar after playing', (
      WidgetTester tester,
    ) async {
      final testRecents = [
        const Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Radio TEDDY',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        ),
      ];

      when(mockApiService.getRecents(any)).thenAnswer((_) async => testRecents);

      when(
        mockApiService.selectContentItem(any, any),
      ).thenAnswer((_) async => Future<void>.value());

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(speaker: testSpeaker, apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the play button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Verify success SnackBar appears
      expect(find.text('Playing "Radio TEDDY"'), findsOneWidget);
    });

    testWidgets('shows error SnackBar on failure', (WidgetTester tester) async {
      final testRecents = [
        const Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Radio TEDDY',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        ),
      ];

      when(mockApiService.getRecents(any)).thenAnswer((_) async => testRecents);

      when(mockApiService.selectContentItem(any, any)).thenAnswer(
        (_) async => throw Exception('Failed to select content: HTTP 500'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(speaker: testSpeaker, apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the play button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Verify error SnackBar appears
      expect(find.textContaining('Failed to play:'), findsOneWidget);
    });

    testWidgets('ListTile has no onTap handler', (WidgetTester tester) async {
      final testRecents = [
        const Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Radio TEDDY',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        ),
      ];

      when(mockApiService.getRecents(any)).thenAnswer((_) async => testRecents);

      when(
        mockApiService.selectContentItem(any, any),
      ).thenAnswer((_) async => Future<void>.value());

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(speaker: testSpeaker, apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

      // Verify ListTile exists
      expect(find.byType(ListTile), findsOneWidget);

      // Tap on the title text (not the button)
      await tester.tap(find.text('Radio TEDDY'));
      await tester.pump();

      // Verify selectContentItem was NOT called (since ListTile has no onTap)
      verifyNever(mockApiService.selectContentItem(any, any));
    });

    testWidgets('IconButton exists as trailing widget', (
      WidgetTester tester,
    ) async {
      final testRecents = [
        const Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Radio TEDDY',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        ),
      ];

      when(mockApiService.getRecents(any)).thenAnswer((_) async => testRecents);

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(speaker: testSpeaker, apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

      // Verify IconButton exists
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('disables items while playing', (WidgetTester tester) async {
      final testRecents = [
        const Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Radio TEDDY',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        ),
        const Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768304677,
          id: '4',
          itemName: 'Komplett Entspannt',
          source: 'SPOTIFY',
          location:
              '/playback/container/c3BvdGlmeTpwbGF5bGlzdDoybjZXMnA1QzBNQUQ5YTR6NXhUVDdu',
          type: 'tracklisturl',
          isPresetable: true,
        ),
      ];

      when(mockApiService.getRecents(any)).thenAnswer((_) async => testRecents);

      when(mockApiService.selectContentItem(any, any)).thenAnswer(
        (_) async => Future.delayed(const Duration(milliseconds: 100)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(speaker: testSpeaker, apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

      // Find all play buttons
      final playButtons = find.byIcon(Icons.play_arrow);
      expect(playButtons, findsNWidgets(2));

      // Tap on the first play button
      await tester.tap(playButtons.first);
      await tester.pump();

      // Try to tap on the second play button (should be disabled)
      await tester.tap(playButtons.last);
      await tester.pump();

      // Verify only one call was made (to the first item)
      verify(
        mockApiService.selectContentItem('192.168.1.100', testRecents[0]),
      ).called(1);
      verifyNever(
        mockApiService.selectContentItem('192.168.1.100', testRecents[1]),
      );

      // Wait for completion
      await tester.pumpAndSettle();
    });
  });
}
