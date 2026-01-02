import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/widgets/emoji_selector.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';

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
  final SpeakerApiService _apiService = SpeakerApiService();
  late String _selectedEmoji;
  late TextEditingController _nameController;
  bool _showEmojiSelector = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.speaker.emoji;
    _nameController = TextEditingController(text: widget.speaker.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSpeaker() async {
    final newName = _nameController.text.trim();

    // Validate name
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speaker name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Call API if name changed
      if (newName != widget.speaker.name) {
        await _apiService.setSpeakerName(widget.speaker.ipAddress, newName);
      }

      // Update local speaker
      final updatedSpeaker = Speaker(
        id: widget.speaker.id,
        name: newName,
        emoji: _selectedEmoji,
        ipAddress: widget.speaker.ipAddress,
        type: widget.speaker.type,
        deviceId: widget.speaker.deviceId,
      );

      if (!mounted) return;
      final appState = context.read<MyAppState>();
      appState.updateSpeaker(updatedSpeaker);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to update speaker name: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
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
          // Editable Speaker Name
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Speaker Name',
                  border: const OutlineInputBorder(),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                style: theme.textTheme.bodyLarge,
                enabled: !_isSaving,
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
        onPressed: _isSaving ? null : _saveSpeaker,
        tooltip: 'Save changes',
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
      ),
    );
  }
}
