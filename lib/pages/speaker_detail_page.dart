import 'package:flutter/material.dart';
import '../models/speaker.dart';
import '../models/volume.dart';
import '../services/speaker_api_service.dart';

class SpeakerDetailPage extends StatefulWidget {
  final Speaker speaker;

  const SpeakerDetailPage({
    Key? key,
    required this.speaker,
  }) : super(key: key);

  @override
  State<SpeakerDetailPage> createState() => _SpeakerDetailPageState();
}

class _SpeakerDetailPageState extends State<SpeakerDetailPage> {
  final SpeakerApiService _apiService = SpeakerApiService();
  Volume? _currentVolume;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVolume();
  }

  Future<void> _loadVolume() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final volume = await _apiService.getVolume(widget.speaker.ipAddress);
      if (!mounted) return;
      setState(() {
        _currentVolume = volume;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load volume: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _adjustVolume(int delta) async {
    if (_currentVolume == null) return;

    final newVolume = (_currentVolume!.actualVolume + delta).clamp(0, 100);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final volume = await _apiService.setVolume(widget.speaker.ipAddress, newVolume);
      if (!mounted) return;
      setState(() {
        _currentVolume = volume;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to adjust volume: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speaker Details'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    widget.speaker.emoji,
                    style: const TextStyle(fontSize: 120),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.speaker.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.speaker.type} • ${widget.speaker.ipAddress}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Volume Control Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.volume_up,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Volume',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading && _currentVolume == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_errorMessage != null)
                      Column(
                        children: [
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loadVolume,
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    else if (_currentVolume != null)
                      Column(
                        children: [
                          // Volume percentage display
                          Text(
                            '${_currentVolume!.actualVolume}%',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Volume bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _currentVolume!.actualVolume / 100,
                              minHeight: 12,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Volume control buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FilledButton.icon(
                                onPressed: _isLoading ? null : () => _adjustVolume(-5),
                                icon: const Icon(Icons.volume_down),
                                label: const Text('Down'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              FilledButton.icon(
                                onPressed: _isLoading ? null : () => _adjustVolume(5),
                                icon: const Icon(Icons.volume_up),
                                label: const Text('Up'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            // Space for other features can be added here
          ],
        ),
      ),
    );
  }
}
