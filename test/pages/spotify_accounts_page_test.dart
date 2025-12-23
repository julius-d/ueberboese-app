import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/pages/spotify_accounts_page.dart';

void main() {
  group('SpotifyAccountsPage', () {
    late MyAppState appState;

    setUp(() {
      appState = MyAppState();
    });

    Widget createTestWidget({AppConfig? config}) {
      if (config != null) {
        appState.config = config;
      }
      return MaterialApp(
        home: ChangeNotifierProvider.value(
          value: appState,
          child: const Scaffold(
            body: SpotifyAccountsPage(),
          ),
        ),
      );
    }

    testWidgets('should render with Plus button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Spotify Accounts'), findsOneWidget);
      expect(find.text('No Spotify accounts connected yet.'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should render music note icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('should show error dialog when API URL not configured',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        config: const AppConfig(apiUrl: '', accountId: 'test'),
      ));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Configuration Required'), findsOneWidget);
      expect(find.text('Überböse API URL is not configured.\n\n'
          'Please configure it in Settings first.'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('should dismiss error dialog when OK is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        config: const AppConfig(apiUrl: '', accountId: 'test'),
      ));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Configuration Required'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Configuration Required'), findsNothing);
    });

    testWidgets('should not show error when API URL is configured',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        config: const AppConfig(
          apiUrl: 'https://api.example.com',
          accountId: 'test',
        ),
      ));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('Configuration Required'), findsNothing);
    });

    testWidgets('should show error dialog on API failure',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        config: const AppConfig(
          apiUrl: 'https://api.example.com',
          accountId: 'test',
        ),
      ));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsOneWidget);
      expect(find.textContaining('Failed to initialize Spotify authentication'), findsOneWidget);
    });
  });
}
