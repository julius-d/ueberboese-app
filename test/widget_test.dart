import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/pages/home_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App starts with home page', (WidgetTester tester) async {
    final appState = MyAppState();
    await appState.initializeSpeakers();

    await tester.pumpWidget(MyApp(appState: appState));

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Speakers'), findsOneWidget);
  });

  testWidgets('Can navigate to Spotify page', (WidgetTester tester) async {
    final appState = MyAppState();
    await appState.initializeSpeakers();

    await tester.pumpWidget(MyApp(appState: appState));

    // Tap on Spotify navigation item
    await tester.tap(find.text('Spotify'));
    await tester.pumpAndSettle();

    expect(find.text('Spotify Accounts'), findsOneWidget);
    expect(find.text('No Spotify accounts connected yet.'), findsOneWidget);
  });
}
