import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/speaker.dart';
import '../models/app_config.dart';
import '../main.dart';
import '../widgets/emoji_selector.dart';
import '../services/speaker_api_service.dart';

class AddSpeakerPage extends StatefulWidget {
  const AddSpeakerPage({super.key});

  @override
  State<AddSpeakerPage> createState() => _AddSpeakerPageState();
}



class _AddSpeakerPageState extends State<AddSpeakerPage> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _apiService = SpeakerApiService();
  String _selectedEmoji = '🔊';
  bool _showEmojiSelector = false;
  bool _isLoading = false;

  @override
  void dispose() {
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

  Future<void> _saveSpeaker() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if running on web and show warning
    if (kIsWeb) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Web Platform Not Supported'),
          content: const Text(
            'Adding speakers is not supported in the web browser due to CORS restrictions.\n\n'
            'Please use the native app instead.'
            'Native apps can access your local network without restrictions.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ipAddress = _ipController.text.trim();
      final speakerInfo = await _apiService.fetchSpeakerInfo(ipAddress);

      if (!mounted) return;

      final appState = context.read<MyAppState>();

      // Auto-fill config if API URL and Account ID are not set
      if (appState.config.apiUrl.isEmpty &&
          appState.config.accountId.isEmpty &&
          speakerInfo.margeUrl != null &&
          speakerInfo.accountId != null) {

        // Check if margeURL is not a Bose domain
        final margeUrl = speakerInfo.margeUrl!;
        final isBoseDomain = margeUrl.contains('bose.com');

        if (!isBoseDomain) {
          // Update config with values from speaker info
          final newConfig = AppConfig(
            apiUrl: margeUrl,
            accountId: speakerInfo.accountId!,
          );
          appState.updateConfig(newConfig);
        }
      }

      final newSpeaker = Speaker(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: speakerInfo.name,
        emoji: _selectedEmoji,
        ipAddress: ipAddress,
        type: speakerInfo.type,
        deviceId: speakerInfo.accountId ?? '',
      );

      appState.addSpeaker(newSpeaker);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(
            'Failed to fetch speaker information.\n\n${e.toString()}',
          ),
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
        title: const Text('Add Speaker'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 16),
                // Emoji Selector
                Card(
                  child: InkWell(
                    onTap: _isLoading
                        ? null
                        : () {
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
                  enabled: !_isLoading,
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
                const SizedBox(height: 16),
                // Info text
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Speaker name and type will be fetched automatically',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Fetching speaker information...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveSpeaker,
        icon: const Icon(Icons.save),
        label: const Text('Save Speaker'),
      ),
    );
  }
}
