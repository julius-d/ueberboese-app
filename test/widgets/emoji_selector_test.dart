import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/widgets/emoji_selector.dart';

void main() {
  group('EmojiSelector', () {
    testWidgets('displays all 12 emojis', (WidgetTester tester) async {
      String selectedEmoji = '🔊';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmojiSelector(
              selectedEmoji: selectedEmoji,
              onEmojiSelected: (emoji) {
                selectedEmoji = emoji;
              },
            ),
          ),
        ),
      );

      // Check that all 12 emojis are displayed
      expect(find.text('🔊'), findsOneWidget);
      expect(find.text('🎵'), findsOneWidget);
      expect(find.text('🎶'), findsOneWidget);
      expect(find.text('🎧'), findsOneWidget);
      expect(find.text('📻'), findsOneWidget);
      expect(find.text('🎤'), findsOneWidget);
      expect(find.text('🎸'), findsOneWidget);
      expect(find.text('🎹'), findsOneWidget);
      expect(find.text('🏠'), findsOneWidget);
      expect(find.text('🛋️'), findsOneWidget);
      expect(find.text('🛏️'), findsOneWidget);
      expect(find.text('🍳'), findsOneWidget);
    });

    testWidgets('calls onEmojiSelected when emoji is tapped',
        (WidgetTester tester) async {
      String selectedEmoji = '🔊';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return EmojiSelector(
                  selectedEmoji: selectedEmoji,
                  onEmojiSelected: (emoji) {
                    setState(() {
                      selectedEmoji = emoji;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Tap on a different emoji
      await tester.tap(find.text('🎵'));
      await tester.pumpAndSettle();

      expect(selectedEmoji, '🎵');
    });

    testWidgets('displays title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmojiSelector(
              selectedEmoji: '🔊',
              onEmojiSelected: (emoji) {},
            ),
          ),
        ),
      );

      expect(find.text('Choose an emoji'), findsOneWidget);
    });
  });
}
