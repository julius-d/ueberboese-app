import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/widgets/speaker_warning_banner.dart';

void main() {
  group('SpeakerWarningBanner', () {
    testWidgets('renders title and body text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeakerWarningBanner(
              title: 'Test Title',
              body: 'Test body text',
              onOpenDoctor: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test body text'), findsOneWidget);
    });

    testWidgets('renders warning icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeakerWarningBanner(
              title: 'Title',
              body: 'Body',
              onOpenDoctor: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('renders Doctor button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeakerWarningBanner(
              title: 'Title',
              body: 'Body',
              onOpenDoctor: () {},
            ),
          ),
        ),
      );

      expect(find.text('Doctor'), findsOneWidget);
    });

    testWidgets('calls onOpenDoctor when button is tapped',
        (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeakerWarningBanner(
              title: 'Title',
              body: 'Body',
              onOpenDoctor: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Doctor'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('uses errorContainer background color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeakerWarningBanner(
              title: 'Title',
              body: 'Body',
              onOpenDoctor: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byIcon(Icons.warning),
          matching: find.byType(Container),
        ).first,
      );
      final theme = Theme.of(tester.element(find.byType(SpeakerWarningBanner)));
      expect(container.color, theme.colorScheme.errorContainer);
    });
  });
}
