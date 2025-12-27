import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/pages/configuration_page.dart';

void main() {
  group('ConfigurationPage', () {
    late MyAppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      appState = MyAppState();
      await appState.initialize();
    });

    Future<void> pumpConfigurationPage(WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            home: ConfigurationPage(),
          ),
        ),
      );
    }

    testWidgets('displays configuration form', (WidgetTester tester) async {
      await pumpConfigurationPage(tester);

      expect(find.text('Configuration'), findsOneWidget);
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

      await pumpConfigurationPage(tester);

      expect(find.text('https://test.example.com'), findsOneWidget);
      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('customadmin'), findsOneWidget);
      expect(find.text('custompass'), findsOneWidget);
    });

    testWidgets('validates empty account ID', (WidgetTester tester) async {
      await pumpConfigurationPage(tester);

      // Find the account ID text field and enter empty string
      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, '');

      // Tap save button
      await tester.tap(find.text('Save Configuration'));
      await tester.pump();

      expect(find.text('Please enter an account ID'), findsOneWidget);
    });

    testWidgets('validates non-alphanumeric account ID',
        (WidgetTester tester) async {
      await pumpConfigurationPage(tester);

      // Find the account ID text field and enter invalid value
      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'test@user!');

      // Tap save button
      await tester.tap(find.text('Save Configuration'));
      await tester.pump();

      expect(
        find.text('Account ID must contain only letters and numbers'),
        findsOneWidget,
      );
    });

    testWidgets('accepts valid alphanumeric account ID',
        (WidgetTester tester) async {
      await pumpConfigurationPage(tester);

      // Enter valid values
      final apiUrlField = find.widgetWithText(
        TextFormField,
        'Überböse API URL',
      );
      await tester.enterText(apiUrlField, 'https://api.example.com');

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'abc123XYZ');

      // Tap save button
      await tester.tap(find.text('Save Configuration'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Check that config was updated
      expect(appState.config.apiUrl, 'https://api.example.com');
      expect(appState.config.accountId, 'abc123XYZ');
    });

    testWidgets('validates invalid URL format', (WidgetTester tester) async {
      await pumpConfigurationPage(tester);

      // Enter invalid URL
      final apiUrlField = find.widgetWithText(
        TextFormField,
        'Überböse API URL',
      );
      await tester.enterText(apiUrlField, 'not-a-valid-url');

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'testuser');

      // Tap save button
      await tester.tap(find.text('Save Configuration'));
      await tester.pump();

      expect(
        find.text('Please enter a valid HTTP or HTTPS URL'),
        findsOneWidget,
      );
    });

    testWidgets('accepts empty API URL (optional field)',
        (WidgetTester tester) async {
      await pumpConfigurationPage(tester);

      // Leave API URL empty but fill account ID
      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'testuser');

      // Tap save button
      await tester.tap(find.text('Save Configuration'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Check that config was updated
      expect(appState.config.apiUrl, '');
      expect(appState.config.accountId, 'testuser');
    });

    testWidgets('accepts valid HTTPS URL', (WidgetTester tester) async {
      await pumpConfigurationPage(tester);

      final apiUrlField = find.widgetWithText(
        TextFormField,
        'Überböse API URL',
      );
      await tester.enterText(apiUrlField, 'https://api.example.com');

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'testuser');

      await tester.tap(find.text('Save Configuration'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(appState.config.apiUrl, 'https://api.example.com');
    });

    testWidgets('accepts valid HTTP URL', (WidgetTester tester) async {
      await pumpConfigurationPage(tester);

      final apiUrlField = find.widgetWithText(
        TextFormField,
        'Überböse API URL',
      );
      await tester.enterText(apiUrlField, 'http://api.example.com');

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'testuser');

      await tester.tap(find.text('Save Configuration'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(appState.config.apiUrl, 'http://api.example.com');
    });

    testWidgets('shows success message after saving',
        (WidgetTester tester) async {
      await pumpConfigurationPage(tester);

      final apiUrlField = find.widgetWithText(
        TextFormField,
        'Überböse API URL',
      );
      await tester.enterText(apiUrlField, 'https://api.example.com');

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'testuser');

      await tester.tap(find.text('Save Configuration'));
      await tester.pump();

      expect(find.text('Configuration saved successfully'), findsOneWidget);

      // Wait for the delayed config update to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    });

    testWidgets('validates empty management username',
        (WidgetTester tester) async {
      await pumpConfigurationPage(tester);

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
      await pumpConfigurationPage(tester);

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
      await pumpConfigurationPage(tester);

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
      await pumpConfigurationPage(tester);

      // Find and tap the visibility toggle button (initially shows visibility icon)
      final visibilityIcon = find.byIcon(Icons.visibility);
      expect(visibilityIcon, findsOneWidget);
      await tester.tap(visibilityIcon);
      await tester.pump();

      // After toggling, should show visibility_off icon
      final visibilityOffIcon = find.byIcon(Icons.visibility_off);
      expect(visibilityOffIcon, findsOneWidget);

      // Tap again to toggle back
      await tester.tap(visibilityOffIcon);
      await tester.pump();

      // Should show visibility icon again
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('loads default values for management credentials',
        (WidgetTester tester) async {
      await pumpConfigurationPage(tester);

      // Default values should be loaded from AppConfig defaults
      expect(find.text('admin'), findsOneWidget);
      expect(find.text('change_me!'), findsOneWidget);
    });

    testWidgets('initializes without errors when config is loaded',
        (WidgetTester tester) async {
      // Set up a pre-existing config
      appState.updateConfig(const AppConfig(
        apiUrl: 'https://existing.example.com',
        accountId: 'existinguser',
        mgmtUsername: 'existingadmin',
        mgmtPassword: 'existingpass',
      ));

      // This should not throw an error or cause a black screen
      await pumpConfigurationPage(tester);
      await tester.pump(); // Additional pump to ensure state is settled

      // Verify page rendered correctly
      expect(find.text('Configuration'), findsOneWidget);
      expect(find.text('https://existing.example.com'), findsOneWidget);
      expect(find.text('existinguser'), findsOneWidget);
      expect(find.text('existingadmin'), findsOneWidget);
      expect(find.text('existingpass'), findsOneWidget);
    });

    testWidgets('initializes correctly with empty config',
        (WidgetTester tester) async {
      // Use default empty config
      await pumpConfigurationPage(tester);
      await tester.pump(); // Additional pump to ensure state is settled

      // Verify page rendered correctly with default values
      expect(find.text('Configuration'), findsOneWidget);
      expect(find.text('admin'), findsOneWidget);
      expect(find.text('change_me!'), findsOneWidget);
    });

    testWidgets('handles save and update without crashing',
        (WidgetTester tester) async {
      await pumpConfigurationPage(tester);

      // Enter valid values
      final apiUrlField = find.widgetWithText(
        TextFormField,
        'Überböse API URL',
      );
      await tester.enterText(apiUrlField, 'https://api.example.com');

      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'testuser');

      final mgmtUsernameField =
          find.widgetWithText(TextFormField, 'Management Username');
      await tester.enterText(mgmtUsernameField, 'admin');

      final mgmtPasswordField =
          find.widgetWithText(TextFormField, 'Management Password');
      await tester.enterText(mgmtPasswordField, 'password123');

      // Tap save button
      await tester.tap(find.text('Save Configuration'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify config was saved successfully
      expect(appState.config.apiUrl, 'https://api.example.com');
      expect(appState.config.accountId, 'testuser');
      expect(appState.config.mgmtUsername, 'admin');
      expect(appState.config.mgmtPassword, 'password123');

      // Verify no black screen or crash - page should still be visible
      expect(find.text('Configuration'), findsOneWidget);
    });

    testWidgets(
        'saves configuration and shows success message',
        (WidgetTester tester) async {
      await pumpConfigurationPage(tester);

      // Enter valid values
      final accountIdField = find.widgetWithText(TextFormField, 'Account ID');
      await tester.enterText(accountIdField, 'testuser');

      final mgmtUsernameField =
          find.widgetWithText(TextFormField, 'Management Username');
      await tester.enterText(mgmtUsernameField, 'admin');

      final mgmtPasswordField =
          find.widgetWithText(TextFormField, 'Management Password');
      await tester.enterText(mgmtPasswordField, 'password123');

      // Tap save button
      await tester.tap(find.text('Save Configuration'));
      await tester.pump(); // Pump once to process the save

      // Success message should appear
      expect(find.text('Configuration saved successfully'), findsOneWidget);

      // Finish animations
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify no errors occurred and config was saved
      expect(appState.config.accountId, 'testuser');
    });
  });
}
