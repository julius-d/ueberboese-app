import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/speaker.dart';
import '../main.dart';
import '../widgets/emoji_selector.dart';

class AddSpeakerPage extends StatefulWidget {
  const AddSpeakerPage({Key? key}) : super(key: key);

  @override
  State<AddSpeakerPage> createState() => _AddSpeakerPageState();
}

class _AddSpeakerPageState extends State<AddSpeakerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  String _selectedEmoji = '🔊';
  bool _showEmojiSelector = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  bool _isValidIpAddress(String ip) {
    final ipRegex = RegExp(
      r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
    );

    if (!ipRegex.hasMatch(ip)) {
      return false;
    }

    final parts = ip.split('.');
    for (var part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        return false;
      }
    }

    return true;
  }

  void _saveSpeaker() {
    if (_formKey.currentState!.validate()) {
      final appState = context.read<MyAppState>();
      final newSpeaker = Speaker(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        emoji: _selectedEmoji,
        ipAddress: _ipController.text.trim(),
      );

      appState.addSpeaker(newSpeaker);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Speaker'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
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
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Speaker Name',
                hintText: 'e.g., Living Room Speaker',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a speaker name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // IP Address Field
            TextFormField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: 'e.g., 192.168.1.100',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.router),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an IP address';
                }
                if (!_isValidIpAddress(value.trim())) {
                  return 'Please enter a valid IP address';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSpeaker,
        icon: const Icon(Icons.save),
        label: const Text('Save Speaker'),
      ),
    );
  }
}
