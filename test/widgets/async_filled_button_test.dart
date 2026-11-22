import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/widgets/async_filled_button.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AsyncFilledButton', () {
    testWidgets('shows icon and label when not loading', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AsyncFilledButton(
            onPressed: () {},
            isLoading: false,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Do thing'),
          ),
        ),
      );

      expect(find.text('Do thing'), findsOneWidget);
      expect(find.byIcon(Icons.restart_alt), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows spinner and hides icon when loading', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AsyncFilledButton(
            onPressed: () {},
            isLoading: true,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Do thing'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.restart_alt), findsNothing);
    });

    testWidgets('button is disabled when loading', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AsyncFilledButton(
            onPressed: () {},
            isLoading: true,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Do thing'),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(
        find.byWidgetPredicate((w) => w is FilledButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('button is enabled when not loading', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AsyncFilledButton(
            onPressed: () {},
            isLoading: false,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Do thing'),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(
        find.byWidgetPredicate((w) => w is FilledButton),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('calls onPressed callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _wrap(
          AsyncFilledButton(
            onPressed: () => tapped = true,
            isLoading: false,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Do thing'),
          ),
        ),
      );

      await tester.tap(find.text('Do thing'));
      expect(tapped, isTrue);
    });

    testWidgets('does not call onPressed when loading and tapped', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        _wrap(
          AsyncFilledButton(
            onPressed: () => tapped = true,
            isLoading: true,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Do thing'),
          ),
        ),
      );

      await tester.tap(find.text('Do thing'), warnIfMissed: false);
      expect(tapped, isFalse);
    });
  });
}
