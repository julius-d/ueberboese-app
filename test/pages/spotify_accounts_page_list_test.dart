import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/pages/spotify_accounts_page.dart';
import 'package:ueberboese_app/services/spotify_api_service.dart';
import 'dart:convert';

@GenerateMocks([http.Client])
import 'spotify_accounts_page_list_test.mocks.dart';

void main() {
  group('SpotifyAccountsPage Account List', () {
    late MyAppState appState;
    late MockClient mockClient;

    setUp(() {
      appState = MyAppState();
      appState.config = const AppConfig(
        apiUrl: 'https://api.example.com',
        accountId: 'test-account',
      );
      mockClient = MockClient();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider.value(
          value: appState,
          child: Scaffold(
            body: SpotifyAccountsPage(
              apiService: SpotifyApiService(httpClient: mockClient),
            ),
          ),
        ),
      );
    }

    testWidgets('should show loading indicator while fetching accounts',
        (WidgetTester tester) async {
      // Mock the API call to delay
      when(mockClient.get(
        Uri.parse('https://api.example.com/mgmt/spotify/accounts'),
      )).thenAnswer(
        (_) => Future.delayed(
          const Duration(milliseconds: 100),
          () => http.Response('{"accounts": []}', 200),
        ),
      );

      await tester.pumpWidget(createTestWidget());

      // Initial loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Loading should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should show empty state when no accounts',
        (WidgetTester tester) async {
      when(mockClient.get(
        Uri.parse('https://api.example.com/mgmt/spotify/accounts'),
      )).thenAnswer(
        (_) async => http.Response('{"accounts": []}', 200),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No Spotify accounts connected yet.'), findsOneWidget);
      expect(find.text('Spotify Accounts'), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('should display list of accounts when accounts exist',
        (WidgetTester tester) async {
      final responseBody = jsonEncode({
        'accounts': [
          {
            'displayName': 'John Doe',
            'createdAt': '2025-12-23T10:30:00Z',
          },
          {
            'displayName': 'Jane Smith',
            'createdAt': '2025-12-22T14:15:00Z',
          },
        ],
      });

      when(mockClient.get(
        Uri.parse('https://api.example.com/mgmt/spotify/accounts'),
      )).thenAnswer(
        (_) async => http.Response(responseBody, 200),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('should display formatted dates for accounts',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final twoDaysAgo = now.subtract(const Duration(days: 2));

      final responseBody = jsonEncode({
        'accounts': [
          {
            'displayName': 'John Doe',
            'createdAt': twoDaysAgo.toIso8601String(),
          },
        ],
      });

      when(mockClient.get(
        Uri.parse('https://api.example.com/mgmt/spotify/accounts'),
      )).thenAnswer(
        (_) async => http.Response(responseBody, 200),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Connected'), findsOneWidget);
      expect(find.textContaining('days ago'), findsOneWidget);
    });

    testWidgets('should show error snackbar when API fails',
        (WidgetTester tester) async {
      when(mockClient.get(
        Uri.parse('https://api.example.com/mgmt/spotify/accounts'),
      )).thenAnswer(
        (_) async => http.Response('Internal Server Error', 500),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Failed to load Spotify accounts'), findsOneWidget);
    });

    testWidgets('should show empty state when API returns empty list',
        (WidgetTester tester) async {
      when(mockClient.get(
        Uri.parse('https://api.example.com/mgmt/spotify/accounts'),
      )).thenAnswer(
        (_) async => http.Response('{"accounts": []}', 200),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No Spotify accounts connected yet.'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('should have music note icon for each account',
        (WidgetTester tester) async {
      final responseBody = jsonEncode({
        'accounts': [
          {
            'displayName': 'John Doe',
            'createdAt': '2025-12-23T10:30:00Z',
          },
          {
            'displayName': 'Jane Smith',
            'createdAt': '2025-12-22T14:15:00Z',
          },
        ],
      });

      when(mockClient.get(
        Uri.parse('https://api.example.com/mgmt/spotify/accounts'),
      )).thenAnswer(
        (_) async => http.Response(responseBody, 200),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should have 2 music note icons (one per account)
      expect(find.byIcon(Icons.music_note), findsNWidgets(2));
    });

    testWidgets('should display ListView when accounts are present',
        (WidgetTester tester) async {
      final responseBody = jsonEncode({
        'accounts': [
          {
            'displayName': 'John Doe',
            'createdAt': '2025-12-23T10:30:00Z',
          },
        ],
      });

      when(mockClient.get(
        Uri.parse('https://api.example.com/mgmt/spotify/accounts'),
      )).thenAnswer(
        (_) async => http.Response(responseBody, 200),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
