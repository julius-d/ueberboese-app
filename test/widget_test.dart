import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/pages/home_page.dart';

void main() {
  testWidgets('App starts with home page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Speakers'), findsOneWidget);
    expect(find.text('Living Room Speaker'), findsOneWidget);
  });

  testWidgets('Can navigate to Spotify page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Tap on Spotify navigation item
    await tester.tap(find.text('Spotify'));
    await tester.pumpAndSettle();

    expect(find.text('Spotify Accounts'), findsOneWidget);
    expect(find.text('No Spotify accounts connected yet.'), findsOneWidget);
  });
}
