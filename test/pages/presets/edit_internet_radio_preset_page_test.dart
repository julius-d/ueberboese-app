import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/tunein_station.dart';
import 'package:ueberboese_app/pages/presets/edit_internet_radio_preset_page.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/tunein_api_service.dart';

@GenerateMocks([SpeakerApiService, TuneInApiService])
import 'edit_internet_radio_preset_page_test.mocks.dart';

void main() {
  group('EditInternetRadioPresetPage', () {
    late MyAppState appState;
    late MockSpeakerApiService mockSpeakerApiService;
    late MockTuneInApiService mockTuneInApiService;

    setUp(() {
      appState = MyAppState();
      mockSpeakerApiService = MockSpeakerApiService();
      mockTuneInApiService = MockTuneInApiService();

      // Add a test speaker
      appState.addSpeaker(
        const Speaker(
          id: '1',
          name: 'Test Speaker',
          emoji: '🔊',
          ipAddress: '192.168.1.100',
          type: 'SoundTouch 10',
          deviceId: 'test123',
        ),
      );

      // Add test config with API URL
      appState.updateConfig(
        const AppConfig(
          apiUrl: 'https://ueberboese.example.com',
          accountId: 'test123',
          mgmtUsername: 'admin',
          mgmtPassword: 'test',
        ),
      );
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
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
          ),
        ),
      );

      expect(find.text('Edit Internet Radio Preset'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays all required text fields', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
          ),
        ),
      );

      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.text('Station Name *'), findsOneWidget);
      expect(find.text('Stream URL *'), findsOneWidget);
      expect(find.text('Cover Art URL'), findsOneWidget);
    });

    testWidgets('displays save button', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
          ),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, 'Save'), findsOneWidget);
    });

    testWidgets('validates URL format in real-time', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
          ),
        ),
      );

      // Find the URL text field
      final urlField = find.widgetWithText(TextField, 'Stream URL *');

      // Enter invalid URL
      await tester.enterText(urlField, 'not-a-valid-url');
      await tester.pump();

      expect(
        find.text('Please enter a valid URL starting with http:// or https://'),
        findsAtLeastNWidgets(1),
      );

      // Enter valid URL
      await tester.enterText(urlField, 'https://stream.example.com/radio');
      await tester.pump();

      expect(
        find.text('Please enter a valid URL starting with http:// or https://'),
        findsNothing,
      );
    });

    testWidgets('shows error dialog when name is empty', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
          ),
        ),
      );

      // Enter URL but leave name empty
      await tester.enterText(
        find.widgetWithText(TextField, 'Stream URL *'),
        'https://stream.example.com/radio',
      );

      // Tap save button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Station name cannot be empty'), findsOneWidget);
    });

    testWidgets('shows error dialog when URL is empty', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
          ),
        ),
      );

      // Enter name but leave URL empty
      await tester.enterText(
        find.widgetWithText(TextField, 'Station Name *'),
        'My Radio',
      );

      // Tap save button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Stream URL cannot be empty'), findsOneWidget);
    });

    testWidgets('shows error dialog when URL is invalid', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
          ),
        ),
      );

      // Enter name and invalid URL
      await tester.enterText(
        find.widgetWithText(TextField, 'Station Name *'),
        'My Radio',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Stream URL *'),
        'not-a-url',
      );

      // Tap save button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter a valid URL starting with http:// or https://'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('saves preset successfully with valid data', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      when(
        mockSpeakerApiService.storeInternetRadioPreset(
          any,
          any,
          any,
          any,
          any,
          any,
        ),
      ).thenAnswer((_) async => [testPreset]);

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
          ),
        ),
      );

      // Enter valid data
      await tester.enterText(
        find.widgetWithText(TextField, 'Station Name *'),
        'My Radio Station',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Stream URL *'),
        'https://stream.example.com/radio',
      );

      // Tap save button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pump();

      verify(
        mockSpeakerApiService.storeInternetRadioPreset(
          '192.168.1.100',
          '1',
          'https://stream.example.com/radio',
          'My Radio Station',
          null,
          'https://ueberboese.example.com',
        ),
      ).called(1);
    });

    testWidgets('saves preset with container art URL', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      when(
        mockSpeakerApiService.storeInternetRadioPreset(
          any,
          any,
          any,
          any,
          any,
          any,
        ),
      ).thenAnswer((_) async => [testPreset]);

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
          ),
        ),
      );

      // Enter valid data including container art
      await tester.enterText(
        find.widgetWithText(TextField, 'Station Name *'),
        'My Radio Station',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Stream URL *'),
        'https://stream.example.com/radio',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Cover Art URL'),
        'https://example.com/art.png',
      );

      // Tap save button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pump();

      verify(
        mockSpeakerApiService.storeInternetRadioPreset(
          '192.168.1.100',
          '1',
          'https://stream.example.com/radio',
          'My Radio Station',
          'https://example.com/art.png',
          'https://ueberboese.example.com',
        ),
      ).called(1);
    });

    testWidgets('shows error dialog when save fails', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      when(
        mockSpeakerApiService.storeInternetRadioPreset(
          any,
          any,
          any,
          any,
          any,
          any,
        ),
      ).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
          ),
        ),
      );

      // Enter valid data
      await tester.enterText(
        find.widgetWithText(TextField, 'Station Name *'),
        'My Radio Station',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Stream URL *'),
        'https://stream.example.com/radio',
      );

      // Tap save button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to save preset: Exception: Network error'),
        findsOneWidget,
      );
    });

    testWidgets('uses the provided speakerIp when saving', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      when(
        mockSpeakerApiService.storeInternetRadioPreset(
          any,
          any,
          any,
          any,
          any,
          any,
        ),
      ).thenAnswer((_) async => [testPreset]);

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '10.0.0.42',
            speakerApiService: mockSpeakerApiService,
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Station Name *'),
        'My Radio Station',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Stream URL *'),
        'https://stream.example.com/radio',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pump();

      verify(
        mockSpeakerApiService.storeInternetRadioPreset(
          '10.0.0.42',
          '1',
          'https://stream.example.com/radio',
          'My Radio Station',
          null,
          'https://ueberboese.example.com',
        ),
      ).called(1);
    });

    testWidgets('search button is visible', (WidgetTester tester) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
            tuneInApiService: mockTuneInApiService,
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('search button disabled when name is empty', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
            tuneInApiService: mockTuneInApiService,
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('successful search populates containerArt field', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      const testStation = TuneInStation(
        guideId: 's123',
        text: 'BBC Radio 1',
        image: 'https://example.com/image.png',
      );

      when(
        mockTuneInApiService.searchStations(any),
      ).thenAnswer((_) async => [testStation]);

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
            tuneInApiService: mockTuneInApiService,
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Station Name *'),
        'BBC Radio 1',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final containerArtField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Cover Art URL'),
      );
      expect(
        containerArtField.controller?.text,
        'https://example.com/image.png',
      );
    });

    testWidgets('search shows error when no results found', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      when(
        mockTuneInApiService.searchStations(any),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
            tuneInApiService: mockTuneInApiService,
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Station Name *'),
        'Unknown Station',
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(
        find.text('No stations found for "Unknown Station"'),
        findsOneWidget,
      );
    });

    testWidgets('image preview shown when containerArt has value', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
            tuneInApiService: mockTuneInApiService,
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextField, 'Cover Art URL'),
        'https://example.com/image.png',
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('search uses case-insensitive matching', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      const testStations = [
        TuneInStation(
          guideId: 's123',
          text: 'BBC Radio 1',
          image: 'https://example.com/bbc.png',
        ),
        TuneInStation(
          guideId: 's124',
          text: 'BBC Radio 2',
          image: 'https://example.com/bbc2.png',
        ),
      ];

      when(
        mockTuneInApiService.searchStations(any),
      ).thenAnswer((_) async => testStations);

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
            tuneInApiService: mockTuneInApiService,
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Station Name *'),
        'bbc radio 1',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final containerArtField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Cover Art URL'),
      );
      expect(containerArtField.controller?.text, 'https://example.com/bbc.png');
    });

    testWidgets('search falls back to first result if no exact match', (
      WidgetTester tester,
    ) async {
      const testPreset = Preset(
        id: '1',
        itemName: 'Test Station',
        source: 'LOCAL_INTERNET_RADIO',
        location: 'https://stream.example.com/radio',
        type: 'stationurl',
        isPresetable: false,
      );

      const testStations = [
        TuneInStation(
          guideId: 's123',
          text: 'BBC Radio 1 Extra',
          image: 'https://example.com/bbc-extra.png',
        ),
        TuneInStation(
          guideId: 's124',
          text: 'BBC Radio 2',
          image: 'https://example.com/bbc2.png',
        ),
      ];

      when(
        mockTuneInApiService.searchStations(any),
      ).thenAnswer((_) async => testStations);

      await tester.pumpWidget(
        createWidgetWithProvider(
          EditInternetRadioPresetPage(
            preset: testPreset,
            speakerIp: '192.168.1.100',
            speakerApiService: mockSpeakerApiService,
            tuneInApiService: mockTuneInApiService,
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Station Name *'),
        'BBC Radio 1',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final containerArtField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Cover Art URL'),
      );
      expect(
        containerArtField.controller?.text,
        'https://example.com/bbc-extra.png',
      );
    });
  });
}
