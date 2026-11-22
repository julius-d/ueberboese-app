import 'package:material_ui/material_ui.dart';

class EmojiSelector extends StatelessWidget {
  final String selectedEmoji;
  final void Function(String) onEmojiSelected;

  const EmojiSelector({
    super.key,
    required this.selectedEmoji,
    required this.onEmojiSelected,
  });

  static const List<String> availableEmojis = [
    '🔊', // Speaker
    '🎵', // Musical Note
    '🎶', // Musical Notes
    '🎧', // Headphones
    '📻', // Radio
    '🎤', // Microphone
    '🎸', // Guitar
    '🎹', // Piano
    '🏠', // House
    '🛋️', // Couch
    '🛏️', // Bed
    '🍳', // Cooking
    '📺', // TV
    '🍿', // Popcorn
    '🛁', // Bathtub
    '🚿', // Shower
    '🍽️', // Dining
    '🧸', // Kids room
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Choose an emoji',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: availableEmojis.length,
            itemBuilder: (context, index) {
              final emoji = availableEmojis[index];
              final isSelected = emoji == selectedEmoji;

              return InkWell(
                onTap: () => onEmojiSelected(emoji),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 32)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
