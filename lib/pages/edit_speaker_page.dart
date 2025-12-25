import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/speaker.dart';
import '../main.dart';
import '../widgets/emoji_selector.dart';

class EditSpeakerPage extends StatefulWidget {
  final Speaker speaker;

  const EditSpeakerPage({
    super.key,
    required this.speaker,
  });

  @override
  State<EditSpeakerPage> createState() => _EditSpeakerPageState();
}

class _EditSpeakerPageState extends State<EditSpeakerPage> {
  late String _selectedEmoji;
  bool _showEmojiSelector = false;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.speaker.emoji;
  }

  void _saveSpeaker() {
    final appState = context.read<MyAppState>();

    final updatedSpeaker = Speaker(
      id: widget.speaker.id,
      name: widget.speaker.name,
      emoji: _selectedEmoji,
      ipAddress: widget.speaker.ipAddress,
      type: widget.speaker.type,
      deviceId: widget.speaker.deviceId,
    );

    appState.updateSpeaker(updatedSpeaker);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Speaker'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          // Emoji Selector
          Card(
            child: InkWell(
              onTap: () {
                setState(() {
                  _showEmojiSelector = !_showEmojiSelector;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      _selectedEmoji,
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to change emoji',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Emoji Grid
          if (_showEmojiSelector)
            Card(
              child: EmojiSelector(
                selectedEmoji: _selectedEmoji,
                onEmojiSelected: (emoji) {
                  setState(() {
                    _selectedEmoji = emoji;
                    _showEmojiSelector = false;
                  });
                },
              ),
            ),
          if (_showEmojiSelector) const SizedBox(height: 24),
          // Read-only Speaker Name
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Speaker Name',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.speaker.name,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Read-only Speaker Type
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Speaker Type',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.speaker.type,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Read-only IP Address
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IP Address',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.speaker.ipAddress,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Read-only Device ID
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device ID',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.speaker.deviceId,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSpeaker,
        tooltip: 'Save changes',
        icon: const Icon(Icons.save),
        label: const Text('Save Changes'),
      ),
    );
  }
}
