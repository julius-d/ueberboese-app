import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/possible_speaker.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/speaker_info.dart';
import 'package:ueberboese_app/pages/discover_speakers_page.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/speaker_discovery_service.dart';

import 'discover_speakers_page_test.mocks.dart';

@GenerateMocks([SpeakerDiscoveryService, SpeakerApiService])
void main() {
  late MockSpeakerDiscoveryService mockDiscovery;
  late MockSpeakerApiService mockApiService;
  late MyAppState appState;

  const fakeSpeakerInfo = SpeakerInfo(
    name: 'Living Room',
    type: 'SoundTouch 10',
    deviceId: 'AABBCCDDEEFF',
  );

  const fakeSpeaker = Speaker(
    id: '1',
    name: 'Living Room',
    emoji: '🔊',
    ipAddress: '192.168.1.42',
    type: 'SoundTouch 10',
    deviceId: 'AABBCCDDEEFF',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockDiscovery = MockSpeakerDiscoveryService();
    mockApiService = MockSpeakerApiService();
    appState = MyAppState();
    await appState.initializeSpeakers();
  });

  Widget buildPage() {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        home: DiscoverSpeakersPage(
          discoveryService: mockDiscovery,
          apiService: mockApiService,
        ),
      ),
    );
  }

  group('DiscoverSpeakersPage', () {
    testWidgets('shows app bar title', (tester) async {
      when(
        mockDiscovery.discover(timeout: anyNamed('timeout')),
      ).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildPage());
      await tester.pump();

      expect(find.text('Discover Speakers'), findsOneWidget);
    });

    testWidgets('shows linear progress indicator while searching', (
      tester,
    ) async {
      final controller = StreamController<PossibleSpeaker>();
      when(
        mockDiscovery.discover(timeout: anyNamed('timeout')),
      ).thenAnswer((_) => controller.stream);

      await tester.pumpWidget(buildPage());
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      controller.close();
    });

    testWidgets('hides progress and shows rescan when done', (tester) async {
      when(
        mockDiscovery.discover(timeout: anyNamed('timeout')),
      ).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildPage());
      // Stream emits nothing and completes
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows no speakers found when stream is empty', (tester) async {
      when(
        mockDiscovery.discover(timeout: anyNamed('timeout')),
      ).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('No speakers found'), findsOneWidget);
    });

    testWidgets('shows discovered speaker after stream emits', (tester) async {
      final possible = PossibleSpeaker(
        ip: '192.168.1.42',
        location: 'http://192.168.1.42:8090/info',
      );

      when(
        mockDiscovery.discover(timeout: anyNamed('timeout')),
      ).thenAnswer((_) => Stream.value(possible));
      when(
        mockApiService.fetchSpeakerInfo('192.168.1.42'),
      ).thenAnswer((_) async => fakeSpeakerInfo);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Living Room'), findsOneWidget);
      expect(find.text('192.168.1.42'), findsOneWidget);
    });

    testWidgets('shows IP when speaker info fetch fails', (tester) async {
      final possible = PossibleSpeaker(
        ip: '192.168.1.99',
        location: 'http://192.168.1.99:8090/info',
      );

      when(
        mockDiscovery.discover(timeout: anyNamed('timeout')),
      ).thenAnswer((_) => Stream.value(possible));
      when(
        mockApiService.fetchSpeakerInfo('192.168.1.99'),
      ).thenThrow(Exception('unreachable'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('192.168.1.99'), findsWidgets);
    });

    testWidgets('shows Add Selected FAB when a speaker is checked', (
      tester,
    ) async {
      final possible = PossibleSpeaker(
        ip: '192.168.1.42',
        location: 'http://192.168.1.42:8090/info',
      );

      when(
        mockDiscovery.discover(timeout: anyNamed('timeout')),
      ).thenAnswer((_) => Stream.value(possible));
      when(
        mockApiService.fetchSpeakerInfo('192.168.1.42'),
      ).thenAnswer((_) async => fakeSpeakerInfo);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(find.text('Add 1 Speaker'), findsOneWidget);
    });

    testWidgets('adds selected speakers and pops on confirm', (tester) async {
      final possible = PossibleSpeaker(
        ip: '192.168.1.42',
        location: 'http://192.168.1.42:8090/info',
      );

      when(
        mockDiscovery.discover(timeout: anyNamed('timeout')),
      ).thenAnswer((_) => Stream.value(possible));
      when(
        mockApiService.fetchSpeakerInfo('192.168.1.42'),
      ).thenAnswer((_) async => fakeSpeakerInfo);
      when(
        mockApiService.createSpeakerFromIp('192.168.1.42', any),
      ).thenAnswer((_) async => fakeSpeaker);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add 1 Speaker'));
      await tester.pumpAndSettle();

      verify(mockApiService.createSpeakerFromIp('192.168.1.42', any)).called(1);
      expect(appState.speakers, contains(fakeSpeaker));
    });

    testWidgets('shows already added badge for existing speaker', (
      tester,
    ) async {
      appState.addSpeaker(fakeSpeaker);

      final possible = PossibleSpeaker(
        ip: '192.168.1.42',
        location: 'http://192.168.1.42:8090/info',
      );

      when(
        mockDiscovery.discover(timeout: anyNamed('timeout')),
      ).thenAnswer((_) => Stream.value(possible));
      when(
        mockApiService.fetchSpeakerInfo('192.168.1.42'),
      ).thenAnswer((_) async => fakeSpeakerInfo);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Already added'), findsOneWidget);
    });

    testWidgets('shows configured emoji for already added speaker', (
      tester,
    ) async {
      const configuredSpeaker = Speaker(
        id: '1',
        name: 'Living Room',
        emoji: '🏠',
        ipAddress: '192.168.1.42',
        type: 'SoundTouch 10',
        deviceId: 'AABBCCDDEEFF',
      );
      appState.addSpeaker(configuredSpeaker);

      final possible = PossibleSpeaker(
        ip: '192.168.1.42',
        location: 'http://192.168.1.42:8090/info',
      );

      when(
        mockDiscovery.discover(timeout: anyNamed('timeout')),
      ).thenAnswer((_) => Stream.value(possible));
      when(
        mockApiService.fetchSpeakerInfo('192.168.1.42'),
      ).thenAnswer((_) async => fakeSpeakerInfo);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('🏠'), findsOneWidget);
    });

    testWidgets('rescan restarts discovery', (tester) async {
      when(
        mockDiscovery.discover(timeout: anyNamed('timeout')),
      ).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // Rescan button visible after initial search completes
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      verify(mockDiscovery.discover(timeout: anyNamed('timeout'))).called(2);
    });
  });
}
