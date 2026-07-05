import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/pages/settings_page.dart';
import 'package:ueberboese_app/pages/ueberboese_api_setup_page.dart';

void main() {
  group('SettingsPage', () {
    late MyAppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      appState = MyAppState();
      await appState.initialize();
    });

    Future<void> pumpSettingsPage(WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );
    }

    testWidgets('displays Settings title', (WidgetTester tester) async {
      await pumpSettingsPage(tester);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('displays both cards', (WidgetTester tester) async {
      await pumpSettingsPage(tester);
      expect(find.text('Überböse API Setup'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
    });

    testWidgets('API card shows URL, account ID and username',
        (WidgetTester tester) async {
      appState.updateConfig(const AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: 'myaccount',
        mgmtUsername: 'myadmin',
        mgmtPassword: 's3cr3t',
      ));

      await pumpSettingsPage(tester);

      expect(find.text('https://api.example.com'), findsOneWidget);
      expect(find.text('myaccount'), findsOneWidget);
      expect(find.text('myadmin'), findsOneWidget);
    });

    testWidgets('API card shows masked password, not plaintext',
        (WidgetTester tester) async {
      appState.updateConfig(const AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: 'myaccount',
        mgmtUsername: 'myadmin',
        mgmtPassword: 'supersecret',
      ));

      await pumpSettingsPage(tester);

      expect(find.text('supersecret'), findsNothing);
      // 'supersecret' is 11 chars → 11 bullet dots
      expect(find.text('•' * 11), findsOneWidget);
    });

    testWidgets('shows (not set) when API URL is empty',
        (WidgetTester tester) async {
      await pumpSettingsPage(tester);
      expect(find.text('(not set)'), findsOneWidget);
    });

    testWidgets('edit pencil navigates to UeberboesApiSetupPage',
        (WidgetTester tester) async {
      appState.updateConfig(const AppConfig(
        accountId: 'user',
        mgmtUsername: 'admin',
        mgmtPassword: 'pass',
      ));

      await pumpSettingsPage(tester);

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      expect(find.byType(UeberboesApiSetupPage), findsOneWidget);
    });

    testWidgets('album art toggle is on by default',
        (WidgetTester tester) async {
      await pumpSettingsPage(tester);

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.value, isTrue);
    });

    testWidgets('album art toggle reflects config state',
        (WidgetTester tester) async {
      appState.updateConfig(
        appState.config.copyWith(showAlbumArtInList: false),
      );

      await pumpSettingsPage(tester);

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.value, isFalse);
    });

    testWidgets('toggling album art updates config',
        (WidgetTester tester) async {
      await pumpSettingsPage(tester);

      expect(appState.config.showAlbumArtInList, isTrue);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      expect(appState.config.showAlbumArtInList, isFalse);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      expect(appState.config.showAlbumArtInList, isTrue);
    });
  });
}
