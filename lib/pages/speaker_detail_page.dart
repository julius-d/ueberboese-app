import 'package:flutter/material.dart';
import '../models/speaker.dart';
import '../models/volume.dart';
import '../models/now_playing.dart';
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
  NowPlaying? _nowPlaying;
  bool _isLoadingVolume = true;
  bool _isLoadingNowPlaying = true;
  String? _volumeErrorMessage;
  String? _nowPlayingErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadVolume();
    _loadNowPlaying();
  }

  Future<void> _loadVolume() async {
    setState(() {
      _isLoadingVolume = true;
      _volumeErrorMessage = null;
    });

    try {
      final volume = await _apiService.getVolume(widget.speaker.ipAddress);
      if (!mounted) return;
      setState(() {
        _currentVolume = volume;
        _isLoadingVolume = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _volumeErrorMessage = 'Failed to load volume: ${e.toString()}';
        _isLoadingVolume = false;
      });
    }
  }

  Future<void> _loadNowPlaying() async {
    setState(() {
      _isLoadingNowPlaying = true;
      _nowPlayingErrorMessage = null;
    });

    try {
      final nowPlaying = await _apiService.getNowPlaying(widget.speaker.ipAddress);
      if (!mounted) return;
      setState(() {
        _nowPlaying = nowPlaying;
        _isLoadingNowPlaying = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nowPlayingErrorMessage = 'Failed to load now playing: ${e.toString()}';
        _isLoadingNowPlaying = false;
      });
    }
  }

  Future<void> _adjustVolume(int delta) async {
    if (_currentVolume == null) return;

    final newVolume = (_currentVolume!.actualVolume + delta).clamp(0, 100);

    setState(() {
      _isLoadingVolume = true;
      _volumeErrorMessage = null;
    });

    try {
      final volume = await _apiService.setVolume(widget.speaker.ipAddress, newVolume);
      if (!mounted) return;
      setState(() {
        _currentVolume = volume;
        _isLoadingVolume = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _volumeErrorMessage = 'Failed to adjust volume: ${e.toString()}';
        _isLoadingVolume = false;
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
      body: SingleChildScrollView(
        child: Padding(
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
                    if (_isLoadingVolume && _currentVolume == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_volumeErrorMessage != null)
                      Column(
                        children: [
                          Text(
                            _volumeErrorMessage!,
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
                                onPressed: _isLoadingVolume ? null : () => _adjustVolume(-5),
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
                                onPressed: _isLoadingVolume ? null : () => _adjustVolume(5),
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
            const SizedBox(height: 16),
            // Now Playing Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.music_note,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Now Playing',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingNowPlaying && _nowPlaying == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_nowPlayingErrorMessage != null)
                      Column(
                        children: [
                          Text(
                            _nowPlayingErrorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loadNowPlaying,
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    else if (_nowPlaying != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_nowPlaying!.track != null) ...[
                            Text(
                              _nowPlaying!.track!,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (_nowPlaying!.artist != null) ...[
                            Text(
                              _nowPlaying!.artist!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Album art and settings
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_nowPlaying!.art != null &&
                                  _nowPlaying!.artImageStatus == 'IMAGE_PRESENT')
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _nowPlaying!.art!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.music_note,
                                          size: 48,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_nowPlaying!.shuffleSetting != null) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.shuffle,
                                            size: 18,
                                            color: _nowPlaying!.shuffleSetting == 'SHUFFLE_ON'
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _nowPlaying!.shuffleSetting == 'SHUFFLE_ON'
                                                ? 'Shuffle On'
                                                : 'Shuffle Off',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (_nowPlaying!.repeatSetting != null) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            _nowPlaying!.repeatSetting == 'REPEAT_ALL'
                                                ? Icons.repeat
                                                : _nowPlaying!.repeatSetting == 'REPEAT_ONE'
                                                    ? Icons.repeat_one
                                                    : Icons.repeat,
                                            size: 18,
                                            color: _nowPlaying!.repeatSetting != 'REPEAT_OFF'
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _nowPlaying!.repeatSetting == 'REPEAT_ALL'
                                                ? 'Repeat All'
                                                : _nowPlaying!.repeatSetting == 'REPEAT_ONE'
                                                    ? 'Repeat One'
                                                    : 'Repeat Off',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
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
          ],
        ),
        ),
      ),
    );
  }
}
