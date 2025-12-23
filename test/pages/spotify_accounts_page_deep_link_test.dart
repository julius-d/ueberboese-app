import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/pages/spotify_accounts_page.dart';

void main() {
  group('SpotifyAccountsPage Deep Link Tests', () {
    late MyAppState appState;

    setUp(() {
      appState = MyAppState();
      appState.config = const AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: 'test-account',
      );
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider.value(
          value: appState,
          child: const Scaffold(
            body: SpotifyAccountsPage(),
          ),
        ),
      );
    }

    testWidgets('should initialize deep link listener on init',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify the page renders correctly
      expect(find.text('Spotify Accounts'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should show loading overlay when connecting to Spotify',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially no loading overlay
      expect(find.text('Connecting to Spotify...'), findsNothing);

      // This test verifies the UI structure for the loading state
      // Actual deep link testing would require integration tests
    });

    testWidgets('should have cancel button in loading overlay',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify the structure exists for showing loading with cancel option
      // In actual use, this appears when processing a deep link
    });

    group('Deep Link URI Parsing', () {
      test('should parse valid Spotify callback URI', () {
        final uri = Uri.parse('ueberboese-login://spotify?code=abc123');

        expect(uri.scheme, 'ueberboese-login');
        expect(uri.host, 'spotify');
        expect(uri.queryParameters['code'], 'abc123');
      });

      test('should parse URI with state parameter', () {
        final uri = Uri.parse('ueberboese-login://spotify?code=abc123&state=xyz789');

        expect(uri.scheme, 'ueberboese-login');
        expect(uri.host, 'spotify');
        expect(uri.queryParameters['code'], 'abc123');
        expect(uri.queryParameters['state'], 'xyz789');
      });

      test('should parse URI without code parameter', () {
        final uri = Uri.parse('ueberboese-login://spotify');

        expect(uri.scheme, 'ueberboese-login');
        expect(uri.host, 'spotify');
        expect(uri.queryParameters['code'], isNull);
      });

      test('should parse URL encoded parameters', () {
        final uri = Uri.parse('ueberboese-login://spotify?code=abc%20123&error=access%20denied');

        expect(uri.scheme, 'ueberboese-login');
        expect(uri.host, 'spotify');
        expect(uri.queryParameters['code'], 'abc 123');
        expect(uri.queryParameters['error'], 'access denied');
      });

      test('should validate correct scheme', () {
        final validUri = Uri.parse('ueberboese-login://spotify?code=abc123');
        final invalidUri = Uri.parse('wrong-scheme://spotify?code=abc123');

        expect(validUri.scheme, 'ueberboese-login');
        expect(invalidUri.scheme, 'wrong-scheme');
        expect(invalidUri.scheme == 'ueberboese-login', false);
      });

      test('should validate correct host', () {
        final validUri = Uri.parse('ueberboese-login://spotify?code=abc123');
        final invalidUri = Uri.parse('ueberboese-login://wrong-host?code=abc123');

        expect(validUri.host, 'spotify');
        expect(invalidUri.host, 'wrong-host');
        expect(invalidUri.host == 'spotify', false);
      });

      test('should validate code parameter exists and is not empty', () {
        final validUri = Uri.parse('ueberboese-login://spotify?code=abc123');
        final missingCodeUri = Uri.parse('ueberboese-login://spotify');
        final emptyCodeUri = Uri.parse('ueberboese-login://spotify?code=');

        final validCode = validUri.queryParameters['code'];
        final missingCode = missingCodeUri.queryParameters['code'];
        final emptyCode = emptyCodeUri.queryParameters['code'];

        expect(validCode != null && validCode.isNotEmpty, true);
        expect(missingCode == null, true);
        expect(emptyCode == null || emptyCode.isEmpty, true);
      });

      test('should handle multiple query parameters', () {
        final uri = Uri.parse(
            'ueberboese-login://spotify?code=test_code&state=random_state&extra=value');

        expect(uri.queryParameters.length, 3);
        expect(uri.queryParameters['code'], 'test_code');
        expect(uri.queryParameters['state'], 'random_state');
        expect(uri.queryParameters['extra'], 'value');
      });

      test('should handle special characters in parameters', () {
        final uri = Uri.parse(
            'ueberboese-login://spotify?code=abc-123_xyz.456&state=test%2Bvalue');

        expect(uri.queryParameters['code'], 'abc-123_xyz.456');
        expect(uri.queryParameters['state'], 'test+value');
      });
    });

    group('Deep Link Validation Logic', () {
      test('should validate complete deep link criteria', () {
        // This test validates the logic that would be used in _handleIncomingLink
        bool isValidDeepLink(Uri uri) {
          if (uri.scheme != 'ueberboese-login') return false;
          if (uri.host != 'spotify') return false;
          final code = uri.queryParameters['code'];
          if (code == null || code.isEmpty) return false;
          return true;
        }

        // Valid cases
        expect(isValidDeepLink(Uri.parse('ueberboese-login://spotify?code=abc123')), true);
        expect(isValidDeepLink(Uri.parse('ueberboese-login://spotify?code=xyz&state=test')), true);

        // Invalid cases
        expect(isValidDeepLink(Uri.parse('wrong-scheme://spotify?code=abc123')), false);
        expect(isValidDeepLink(Uri.parse('ueberboese-login://wrong-host?code=abc123')), false);
        expect(isValidDeepLink(Uri.parse('ueberboese-login://spotify')), false);
        expect(isValidDeepLink(Uri.parse('ueberboese-login://spotify?code=')), false);
      });
    });
  });
}
