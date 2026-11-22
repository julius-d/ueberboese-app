import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/models/wireless_network.dart';
import 'package:ueberboese_app/models/speaker_info.dart';
import 'package:ueberboese_app/pages/speaker_setup_wizard_page.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/speaker_setup_service.dart';

import 'speaker_setup_wizard_page_test.mocks.dart';

@GenerateMocks([SpeakerSetupService, SpeakerApiService])
void main() {
  late MockSpeakerSetupService mockService;
  late MockSpeakerApiService mockApiService;
  late MyAppState appState;

  const fakeSpeakerInfo = SpeakerInfo(
    name: 'Bose Speaker',
    type: 'SoundTouch 10',
    deviceId: 'AABBCCDDEEFF',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockService = MockSpeakerSetupService();
    mockApiService = MockSpeakerApiService();
    appState = MyAppState();
    await appState.initializeSpeakers();
  });

  Widget buildWizard() {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        home: SpeakerSetupWizardPage(
          setupService: mockService,
          apiService: mockApiService,
        ),
      ),
    );
  }

  /// Helper: stub a successful AP connection check.
  void stubConnectionSuccess() {
    when(
      mockApiService.fetchSpeakerInfo(any),
    ).thenAnswer((_) async => fakeSpeakerInfo);
  }

  /// Helper: stub a failing AP connection check.
  void stubConnectionFailure() {
    when(
      mockApiService.fetchSpeakerInfo(any),
    ).thenThrow(Exception('Connection refused'));
  }

  group('SpeakerSetupWizardPage', () {
    testWidgets('shows factory reset step on open', (tester) async {
      await tester.pumpWidget(buildWizard());
      expect(find.text('Step 1: Factory Reset Your Speaker'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('advances to step 2 on Next', (tester) async {
      await tester.pumpWidget(buildWizard());
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2: Connect to Speaker Wi-Fi'), findsOneWidget);
    });

    testWidgets('Continue checks connection and advances on success', (
      tester,
    ) async {
      stubConnectionSuccess();
      when(mockService.performWirelessSiteSurvey()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildWizard());
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      verify(mockApiService.fetchSpeakerInfo('192.0.2.1')).called(1);
      expect(find.text('Step 3: Select Wi-Fi Network'), findsOneWidget);
    });

    testWidgets('Continue shows error when not connected to speaker AP', (
      tester,
    ) async {
      stubConnectionFailure();

      await tester.pumpWidget(buildWizard());
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Could not reach the speaker'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      // Should stay on step 2
      expect(find.text('Step 2: Connect to Speaker Wi-Fi'), findsOneWidget);
    });

    testWidgets('Retry re-checks connection and advances on success', (
      tester,
    ) async {
      // First call fails, second succeeds
      var callCount = 0;
      when(mockApiService.fetchSpeakerInfo(any)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('Not connected');
        return fakeSpeakerInfo;
      });
      when(mockService.performWirelessSiteSurvey()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildWizard());
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Step 3: Select Wi-Fi Network'), findsOneWidget);
    });

    testWidgets('shows networks after site survey', (tester) async {
      stubConnectionSuccess();
      when(mockService.performWirelessSiteSurvey()).thenAnswer(
        (_) async => [
          const WirelessNetwork(
            ssid: 'HomeNet',
            signalStrength: -55,
            secure: true,
            securityType: 'wpa_or_wpa2',
          ),
          const WirelessNetwork(
            ssid: 'GuestNet',
            signalStrength: -70,
            secure: false,
            securityType: 'none',
          ),
        ],
      );

      await tester.pumpWidget(buildWizard());
      // Navigate to step 2 (Wi-Fi selection)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('HomeNet'), findsOneWidget);
      expect(find.text('GuestNet'), findsOneWidget);
    });

    testWidgets('shows error and retry button when site survey fails', (
      tester,
    ) async {
      stubConnectionSuccess();
      when(
        mockService.performWirelessSiteSurvey(),
      ).thenThrow(Exception('Connection refused'));

      await tester.pumpWidget(buildWizard());
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining('Failed to scan networks'), findsOneWidget);
    });

    testWidgets('shows password dialog for secure networks', (tester) async {
      stubConnectionSuccess();
      when(mockService.performWirelessSiteSurvey()).thenAnswer(
        (_) async => [
          const WirelessNetwork(
            ssid: 'SecureNet',
            signalStrength: -60,
            secure: true,
            securityType: 'wpa_or_wpa2',
          ),
        ],
      );

      await tester.pumpWidget(buildWizard());
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SecureNet'));
      await tester.pumpAndSettle();

      expect(find.text('Password for "SecureNet"'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('advances to envswitch step after successful Wi-Fi setup', (
      tester,
    ) async {
      stubConnectionSuccess();
      when(mockService.performWirelessSiteSurvey()).thenAnswer(
        (_) async => [
          const WirelessNetwork(
            ssid: 'OpenNet',
            signalStrength: -60,
            secure: false,
            securityType: 'none',
          ),
        ],
      );
      when(
        mockService.addWirelessProfile(any, any, any),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildWizard());
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OpenNet'));
      await tester.pumpAndSettle();

      expect(
        find.text('Step 4: Connect to your Überböse Server'),
        findsOneWidget,
      );
    });

    testWidgets('envswitch step skip button advances to Marge account step', (
      tester,
    ) async {
      stubConnectionSuccess();
      when(mockService.performWirelessSiteSurvey()).thenAnswer(
        (_) async => [
          const WirelessNetwork(
            ssid: 'Net',
            signalStrength: -50,
            secure: false,
            securityType: 'none',
          ),
        ],
      );
      when(
        mockService.addWirelessProfile(any, any, any),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildWizard());
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Net'));
      await tester.pumpAndSettle();

      // Now on envswitch step — skip it
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Step 5: Link Marge Account'), findsOneWidget);
    });

    testWidgets('Marge account step shows pre-filled fields', (tester) async {
      stubConnectionSuccess();
      appState.updateConfig(
        const AppConfig(
          apiUrl: 'https://api.example.com',
          accountId: 'myaccount123',
          mgmtUsername: 'admin',
          mgmtPassword: 'pass',
        ),
      );

      when(mockService.performWirelessSiteSurvey()).thenAnswer(
        (_) async => [
          const WirelessNetwork(
            ssid: 'Net',
            signalStrength: -50,
            secure: false,
            securityType: 'none',
          ),
        ],
      );
      when(
        mockService.addWirelessProfile(any, any, any),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildWizard());
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Net'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Account ID pre-filled from config
      expect(find.text('myaccount123'), findsOneWidget);
      // Default auth token
      expect(find.text('auth1234'), findsOneWidget);
    });

    testWidgets(
      'Marge account confirm calls setMargeAccount and advances to rename step',
      (tester) async {
        stubConnectionSuccess();
        when(mockService.performWirelessSiteSurvey()).thenAnswer(
          (_) async => [
            const WirelessNetwork(
              ssid: 'Net',
              signalStrength: -50,
              secure: false,
              securityType: 'none',
            ),
          ],
        );
        when(
          mockService.addWirelessProfile(any, any, any),
        ).thenAnswer((_) async {});
        when(
          mockService.setMargeAccount(any, any, any),
        ).thenAnswer((_) async {});

        // Set config with non-empty accountId so pre-fill works
        appState.updateConfig(
          const AppConfig(
            apiUrl: '',
            accountId: 'testaccount',
            mgmtUsername: 'admin',
            mgmtPassword: 'pass',
          ),
        );

        await tester.pumpWidget(buildWizard());
        // Step 0 → 1
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        // Step 1 → 2
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        // Step 2: tap network (triggers loading dialog + addWirelessProfile)
        await tester.tap(find.text('Net'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Should be on envswitch step now
        expect(
          find.text('Step 4: Connect to your Überböse Server'),
          findsOneWidget,
          reason: 'Should be on envswitch step after Wi-Fi setup',
        );

        // Skip envswitch → step 4
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        // Should be on Marge account step now
        expect(
          find.text('Step 5: Link Marge Account'),
          findsOneWidget,
          reason: 'Should be on Marge step after skipping envswitch',
        );

        await tester.tap(find.text('Confirm'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        verify(mockService.setMargeAccount(any, any, any)).called(1);
        expect(find.text('Step 6: Name Your Speaker'), findsOneWidget);
      },
    );

    testWidgets(
      'rename step shows pre-filled name and save calls setSpeakerName',
      (tester) async {
        stubConnectionSuccess();
        when(mockService.performWirelessSiteSurvey()).thenAnswer(
          (_) async => [
            const WirelessNetwork(
              ssid: 'Net',
              signalStrength: -50,
              secure: false,
              securityType: 'none',
            ),
          ],
        );
        when(
          mockService.addWirelessProfile(any, any, any),
        ).thenAnswer((_) async {});
        when(mockApiService.setSpeakerName(any, any)).thenAnswer((_) async {});
        when(mockService.leaveSetupMode()).thenAnswer((_) async {});

        await tester.pumpWidget(buildWizard());
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Net'));
        await tester.pumpAndSettle();
        // Skip envswitch step
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
        // Skip Marge step
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        expect(find.text('Step 6: Name Your Speaker'), findsOneWidget);
        // Name pre-filled from fetchSpeakerInfo
        expect(find.text('Bose Speaker'), findsOneWidget);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        verify(
          mockApiService.setSpeakerName('192.0.2.1', 'Bose Speaker'),
        ).called(1);
        expect(find.text('Setup Complete'), findsOneWidget);
      },
    );

    testWidgets('finish step shows done button that pops', (tester) async {
      stubConnectionSuccess();
      when(mockService.performWirelessSiteSurvey()).thenAnswer(
        (_) async => [
          const WirelessNetwork(
            ssid: 'Net',
            signalStrength: -50,
            secure: false,
            securityType: 'none',
          ),
        ],
      );
      when(
        mockService.addWirelessProfile(any, any, any),
      ).thenAnswer((_) async {});
      when(mockService.leaveSetupMode()).thenAnswer((_) async {});

      await tester.pumpWidget(buildWizard());
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Net'));
      await tester.pumpAndSettle();
      // Skip envswitch step
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      // Skip Marge step
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      // Skip rename step
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Setup Complete'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('speaker list page shows Set up new speaker FAB option', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: SpeakerSetupWizardPage()),
          ),
        ),
      );

      expect(find.text('Set Up New Speaker'), findsOneWidget);
    });
  });
}
