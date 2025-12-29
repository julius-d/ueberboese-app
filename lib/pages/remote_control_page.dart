import 'package:flutter/material.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';

class RemoteControlPage extends StatefulWidget {
  final Speaker speaker;

  const RemoteControlPage({
    super.key,
    required this.speaker,
  });

  @override
  State<RemoteControlPage> createState() => _RemoteControlPageState();
}

class _RemoteControlPageState extends State<RemoteControlPage> {
  final SpeakerApiService _apiService = SpeakerApiService();
  bool _isProcessing = false;

  Future<void> _sendSimpleKey(String keyValue) async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _apiService.sendKey(widget.speaker.ipAddress, keyValue, 'press');
      await _apiService.sendKey(widget.speaker.ipAddress, keyValue, 'release');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send key: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _sendKeyPress(String keyValue) async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _apiService.sendKey(widget.speaker.ipAddress, keyValue, 'press');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send key press: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _sendKeyRelease(String keyValue) async {
    try {
      await _apiService.sendKey(widget.speaker.ipAddress, keyValue, 'release');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send key release: ${e.toString()}')),
      );
    }
  }

  // Simple button - sends press then release on tap
  Widget _buildSimpleButton({
    required String label,
    required IconData icon,
    required String keyValue,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: FilledButton.icon(
        onPressed: _isProcessing ? null : () => _sendSimpleKey(keyValue),
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: isFullWidth ? 24 : 12,
            vertical: 16,
          ),
          textStyle: TextStyle(
            fontSize: isFullWidth ? 16 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Hold button - sends press on tap down, release on tap up (for volume controls)
  Widget _buildHoldButton({
    required String label,
    required IconData icon,
    required String keyValue,
  }) {
    return GestureDetector(
      onTapDown: (_) => _sendKeyPress(keyValue),
      onTapUp: (_) => _sendKeyRelease(keyValue),
      onTapCancel: () => _sendKeyRelease(keyValue),
      child: Material(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Empty onTap to show ripple effect, but actual handling is in GestureDetector
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.speaker.emoji),
            const SizedBox(width: 8),
            const Text('Remote Control'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Speaker name display
              Center(
                child: Text(
                  widget.speaker.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Power button
              _buildSimpleButton(
                label: 'Power',
                icon: Icons.power_settings_new,
                keyValue: 'POWER',
                isFullWidth: true,
              ),
              const SizedBox(height: 24),

              // AUX Input button
              _buildSimpleButton(
                label: 'AUX Input',
                icon: Icons.input,
                keyValue: 'AUX_INPUT',
                isFullWidth: true,
              ),
              const SizedBox(height: 24),

              // Presets 1-3
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildSimpleButton(
                      label: '1',
                      icon: Icons.filter_1,
                      keyValue: 'PRESET_1',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSimpleButton(
                      label: '2',
                      icon: Icons.filter_2,
                      keyValue: 'PRESET_2',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSimpleButton(
                      label: '3',
                      icon: Icons.filter_3,
                      keyValue: 'PRESET_3',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Presets 4-6
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildSimpleButton(
                      label: '4',
                      icon: Icons.filter_4,
                      keyValue: 'PRESET_4',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSimpleButton(
                      label: '5',
                      icon: Icons.filter_5,
                      keyValue: 'PRESET_5',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSimpleButton(
                      label: '6',
                      icon: Icons.filter_6,
                      keyValue: 'PRESET_6',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Mute button
              _buildSimpleButton(
                label: 'Mute',
                icon: Icons.volume_off,
                keyValue: 'MUTE',
                isFullWidth: true,
              ),
              const SizedBox(height: 24),

              // Volume controls (hold buttons)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildHoldButton(
                      label: 'Volume Down',
                      icon: Icons.volume_down,
                      keyValue: 'VOLUME_DOWN',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHoldButton(
                      label: 'Volume Up',
                      icon: Icons.volume_up,
                      keyValue: 'VOLUME_UP',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Play/Pause button
              _buildSimpleButton(
                label: 'Play/Pause',
                icon: Icons.play_arrow,
                keyValue: 'PLAY_PAUSE',
                isFullWidth: true,
              ),
              const SizedBox(height: 24),

              // Track controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildSimpleButton(
                      label: 'Previous',
                      icon: Icons.skip_previous,
                      keyValue: 'PREV_TRACK',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSimpleButton(
                      label: 'Next',
                      icon: Icons.skip_next,
                      keyValue: 'NEXT_TRACK',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
