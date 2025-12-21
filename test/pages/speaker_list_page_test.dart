import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/pages/speaker_list_page.dart';
import 'package:ueberboese_app/pages/speaker_detail_page.dart';

void main() {
  group('SpeakerListPage', () {
    testWidgets('displays list of speakers', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      expect(find.text('Living Room Speaker'), findsOneWidget);
      expect(find.text('192.168.1.101'), findsOneWidget);
      expect(find.text('🔊'), findsOneWidget);
    });

    testWidgets('shows all speakers from state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      expect(find.text('Living Room Speaker'), findsOneWidget);
      expect(find.text('Bedroom Speaker'), findsOneWidget);
      expect(find.text('Kitchen Speaker'), findsOneWidget);
      expect(find.text('Office Speaker'), findsOneWidget);
      expect(find.text('Garage Speaker'), findsOneWidget);
    });

    testWidgets('navigates to detail page on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      await tester.tap(find.text('Living Room Speaker'));
      await tester.pumpAndSettle();

      expect(find.byType(SpeakerDetailPage), findsOneWidget);
      expect(find.text('Speaker Details'), findsOneWidget);
    });

    testWidgets('displays speaker emoji with correct size',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MyAppState(),
          child: const MaterialApp(
            home: Scaffold(body: SpeakerListPage()),
          ),
        ),
      );

      final emojiText = tester.widget<Text>(
        find.text('🔊').first,
      );

      expect(emojiText.style?.fontSize, 32);
    });
  });
}
