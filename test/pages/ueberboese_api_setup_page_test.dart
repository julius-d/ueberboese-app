import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/pages/ueberboese_api_setup_page.dart';

void main() {
  group('UeberboesApiSetupPage', () {
    late MyAppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      appState = MyAppState();
      await appState.initialize();
    });

    Future<void> pumpPage(WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: UeberboesApiSetupPage(),
          ),
        ),
      );
    }

    testWidgets('displays correct title', (WidgetTester tester) async {
      await pumpPage(tester);
      expect(find.text('Überböse API Setup'), findsOneWidget);
    });

    testWidgets('displays configuration form', (WidgetTester tester) async {
      await pumpPage(tester);

      expect(find.text('Überböse API URL'), findsOneWidget);
      expect(find.text('Account ID'), findsOneWidget);
      expect(find.text('Management API Credentials'), findsOneWidget);
      expect(find.text('Management Username'), findsOneWidget);
      expect(find.text('Management Password'), findsOneWidget);
      expect(find.text('Save Configuration'), findsOneWidget);
    });

    testWidgets('loads current config values', (WidgetTester tester) async {
      appState.updateConfig(const AppConfig(
        apiUrl: 'https://test.example.com',
        accountId: 'testuser',
        mgmtUsername: 'customadmin',
        mgmtPassword: 'custompass',
      ));

      await pumpPage(tester);

      expect(find.text('https://test.example.com'), findsOneWidget);
      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('customadmin'), findsOneWidget);
      expect(find.text('custompass'), findsOneWidget);
    });

    testWidgets('validates empty account ID', (WidgetTester tester) async {
      await pumpPage(tester);

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, '');

      await tester.tap(find.text('Save Configuration'));
      await tester.pump();

      expect(find.text('Please enter an account ID'), findsOneWidget);
    });

    testWidgets('validates non-alphanumeric account ID',
        (WidgetTester tester) async {
      await pumpPage(tester);

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'test@user!');

      await tester.tap(find.text('Save Configuration'));
      await tester.pump();

      expect(
        find.text('Account ID must contain only letters and numbers'),
        findsOneWidget,
      );
    });

    testWidgets('accepts valid alphanumeric account ID',
        (WidgetTester tester) async {
      await pumpPage(tester);

      final apiUrlField = find.widgetWithText(TextFormField, 'Überböse API URL');
      await tester.enterText(apiUrlField, 'https://api.example.com');

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'abc123XYZ');

      await tester.tap(find.text('Save Configuration'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(appState.config.apiUrl, 'https://api.example.com');
      expect(appState.config.accountId, 'abc123XYZ');
    });

    testWidgets('validates invalid URL format', (WidgetTester tester) async {
      await pumpPage(tester);

      final apiUrlField = find.widgetWithText(TextFormField, 'Überböse API URL');
      await tester.enterText(apiUrlField, 'not-a-valid-url');

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'testuser');

      await tester.tap(find.text('Save Configuration'));
      await tester.pump();

      expect(
        find.text('Please enter a valid HTTP or HTTPS URL'),
        findsOneWidget,
      );
    });

    testWidgets('accepts empty API URL (optional field)',
        (WidgetTester tester) async {
      await pumpPage(tester);

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'testuser');

      await tester.tap(find.text('Save Configuration'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(appState.config.apiUrl, '');
      expect(appState.config.accountId, 'testuser');
    });

    testWidgets('accepts valid HTTPS URL', (WidgetTester tester) async {
      await pumpPage(tester);

      final apiUrlField = find.widgetWithText(TextFormField, 'Überböse API URL');
      await tester.enterText(apiUrlField, 'https://api.example.com');

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'testuser');

      await tester.tap(find.text('Save Configuration'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(appState.config.apiUrl, 'https://api.example.com');
    });

    testWidgets('accepts valid HTTP URL', (WidgetTester tester) async {
      await pumpPage(tester);

      final apiUrlField = find.widgetWithText(TextFormField, 'Überböse API URL');
      await tester.enterText(apiUrlField, 'http://api.example.com');

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'testuser');

      await tester.tap(find.text('Save Configuration'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(appState.config.apiUrl, 'http://api.example.com');
    });

    testWidgets('shows success message after saving',
        (WidgetTester tester) async {
      await pumpPage(tester);

      final apiUrlField = find.widgetWithText(TextFormField, 'Überböse API URL');
      await tester.enterText(apiUrlField, 'https://api.example.com');

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'testuser');

      await tester.tap(find.text('Save Configuration'));
      await tester.pump();

      expect(find.text('Configuration saved successfully'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    });

    testWidgets('validates empty management username',
        (WidgetTester tester) async {
      await pumpPage(tester);

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'testuser');

      final mgmtUsernameField =
          find.widgetWithText(TextFormField, 'Management Username');
      await tester.enterText(mgmtUsernameField, '');

      await tester.tap(find.text('Save Configuration'));
      await tester.pump();

      expect(find.text('Please enter a management username'), findsOneWidget);
    });

    testWidgets('validates empty management password',
        (WidgetTester tester) async {
      await pumpPage(tester);

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'testuser');

      final mgmtPasswordField =
          find.widgetWithText(TextFormField, 'Management Password');
      await tester.enterText(mgmtPasswordField, '');

      await tester.tap(find.text('Save Configuration'));
      await tester.pump();

      expect(find.text('Please enter a management password'), findsOneWidget);
    });

    testWidgets('saves management credentials', (WidgetTester tester) async {
      await pumpPage(tester);

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'testuser');

      final mgmtUsernameField =
          find.widgetWithText(TextFormField, 'Management Username');
      await tester.enterText(mgmtUsernameField, 'myadmin');

      final mgmtPasswordField =
          find.widgetWithText(TextFormField, 'Management Password');
      await tester.enterText(mgmtPasswordField, 'mypassword');

      await tester.tap(find.text('Save Configuration'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(appState.config.mgmtUsername, 'myadmin');
      expect(appState.config.mgmtPassword, 'mypassword');
    });

    testWidgets('toggles password visibility', (WidgetTester tester) async {
      await pumpPage(tester);

      final visibilityIcon = find.byIcon(Icons.visibility);
      expect(visibilityIcon, findsOneWidget);
      await tester.tap(visibilityIcon);
      await tester.pump();

      final visibilityOffIcon = find.byIcon(Icons.visibility_off);
      expect(visibilityOffIcon, findsOneWidget);

      await tester.tap(visibilityOffIcon);
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('loads default values for management credentials',
        (WidgetTester tester) async {
      await pumpPage(tester);

      expect(find.text('admin'), findsOneWidget);
      expect(find.text('change_me!'), findsOneWidget);
    });

    testWidgets('preserves showAlbumArtInList when saving',
        (WidgetTester tester) async {
      appState.updateConfig(
        appState.config.copyWith(showAlbumArtInList: false),
      );

      await pumpPage(tester);

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'testuser');

      await tester.tap(find.text('Save Configuration'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(appState.config.showAlbumArtInList, false);
    });
  });
}
