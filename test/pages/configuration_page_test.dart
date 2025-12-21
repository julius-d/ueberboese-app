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
      expect(find.text('Save Configuration'), findsOneWidget);
    });

    testWidgets('loads current config values', (WidgetTester tester) async {
      appState.updateConfig(const AppConfig(
        apiUrl: 'https://test.example.com',
        accountId: 'testuser',
      ));

      await pumpConfigurationPage(tester);

      expect(find.text('https://test.example.com'), findsOneWidget);
      expect(find.text('testuser'), findsOneWidget);
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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
    });
  });
}
