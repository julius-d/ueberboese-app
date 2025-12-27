import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/preset.dart';

class EditSpotifyPresetPage extends StatefulWidget {
  final Preset preset;

  const EditSpotifyPresetPage({super.key, required this.preset});

  @override
  State<EditSpotifyPresetPage> createState() => _EditSpotifyPresetPageState();
}

class _EditSpotifyPresetPageState extends State<EditSpotifyPresetPage> {
  late TextEditingController _spotifyUriController;
  String? _decodingError;

  @override
  void initState() {
    super.initState();
    _spotifyUriController = TextEditingController();

    try {
      final location = widget.preset.location;
      const prefix = '/playback/container/';

      if (!location.startsWith(prefix)) {
        _decodingError = 'Invalid location format';
        return;
      }

      final base64Part = location.substring(prefix.length);
      final decodedBytes = base64Decode(base64Part);
      final decodedUri = utf8.decode(decodedBytes);

      _spotifyUriController.text = decodedUri;
    } catch (e) {
      _decodingError = 'Failed to decode Spotify URI: ${e.toString()}';
    }
  }

  @override
  void dispose() {
    _spotifyUriController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not Implemented'),
        content: const Text('Saving is not yet implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Spotify Preset'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_decodingError != null) ...[
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _decodingError!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _spotifyUriController,
              enabled: _decodingError == null,
              decoration: const InputDecoration(
                labelText: 'Spotify URI',
                border: OutlineInputBorder(),
                helperText: 'e.g., spotify:playlist:23SMdyOHA6KkzHoPOJ5KQ9',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _decodingError == null ? _onSavePressed : null,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
