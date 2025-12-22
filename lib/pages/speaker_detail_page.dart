import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/speaker.dart';
import '../models/volume.dart';
import '../models/now_playing.dart';
import '../models/zone.dart';
import '../services/speaker_api_service.dart';
import '../main.dart';

class SpeakerDetailPage extends StatefulWidget {
  final Speaker speaker;


  const SpeakerDetailPage({
    super.key,
    required this.speaker,
  });

  @override
  State<SpeakerDetailPage> createState() => _SpeakerDetailPageState();
}

class _SpeakerDetailPageState extends State<SpeakerDetailPage> {
  final SpeakerApiService _apiService = SpeakerApiService();
  Volume? _currentVolume;
  NowPlaying? _nowPlaying;
  Zone? _currentZone;
  bool _isLoadingVolume = true;
  bool _isLoadingNowPlaying = true;
  bool _isLoadingZone = true;
  String? _volumeErrorMessage;
  String? _nowPlayingErrorMessage;
  String? _zoneErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadVolume();
    _loadNowPlaying();
    _loadZone();
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

  Future<void> _loadZone() async {
    setState(() {
      _isLoadingZone = true;
      _zoneErrorMessage = null;
    });

    try {
      final zone = await _apiService.getZone(widget.speaker.ipAddress);
      if (!mounted) return;
      setState(() {
        _currentZone = zone;
        _isLoadingZone = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _zoneErrorMessage = 'Failed to load zone: ${e.toString()}';
        _isLoadingZone = false;
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

  Future<void> _createZone(List<Speaker> selectedSpeakers) async {
    if (widget.speaker.deviceId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speaker device ID not available')),
      );
      return;
    }

    setState(() {
      _isLoadingZone = true;
      _zoneErrorMessage = null;
    });

    try {
      // Create members list including this speaker as master
      final members = <ZoneMember>[
        ZoneMember(
          deviceId: widget.speaker.deviceId!,
          ipAddress: widget.speaker.ipAddress,
        ),
        ...selectedSpeakers
            .where((s) => s.deviceId != null && s.id != widget.speaker.id)
            .map((s) => ZoneMember(
                  deviceId: s.deviceId!,
                  ipAddress: s.ipAddress,
                )),
      ];

      await _apiService.createZone(
        widget.speaker.ipAddress,
        widget.speaker.deviceId!,
        members,
      );

      // Reload zone info
      await _loadZone();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zone created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _zoneErrorMessage = 'Failed to create zone: ${e.toString()}';
        _isLoadingZone = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create zone: ${e.toString()}')),
      );
    }
  }

  Future<void> _addToZone(List<Speaker> selectedSpeakers) async {
    if (_currentZone == null || widget.speaker.deviceId == null) return;

    setState(() {
      _isLoadingZone = true;
      _zoneErrorMessage = null;
    });

    try {
      final newMembers = selectedSpeakers
          .where((s) =>
              s.deviceId != null &&
              !_currentZone!.members.any((m) => m.deviceId == s.deviceId))
          .map((s) => ZoneMember(
                deviceId: s.deviceId!,
                ipAddress: s.ipAddress,
              ))
          .toList();

      if (newMembers.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No new speakers to add')),
        );
        setState(() => _isLoadingZone = false);
        return;
      }

      await _apiService.addZoneMembers(
        widget.speaker.ipAddress,
        _currentZone!.masterId,
        newMembers,
      );

      await _loadZone();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speakers added to zone')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _zoneErrorMessage = 'Failed to add speakers: ${e.toString()}';
        _isLoadingZone = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add speakers: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeFromZone(ZoneMember member) async {
    if (_currentZone == null) return;

    setState(() {
      _isLoadingZone = true;
      _zoneErrorMessage = null;
    });

    try {
      await _apiService.removeZoneMembers(
        widget.speaker.ipAddress,
        _currentZone!.masterId,
        [member],
      );

      await _loadZone();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speaker removed from zone')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _zoneErrorMessage = 'Failed to remove speaker: ${e.toString()}';
        _isLoadingZone = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove speaker: ${e.toString()}')),
      );
    }
  }

  void _showZoneDialog(BuildContext context) {
    final appState = context.read<MyAppState>();
    final availableSpeakers = appState.speakers
        .where((s) => s.id != widget.speaker.id && s.deviceId != null)
        .toList();

    if (availableSpeakers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other speakers available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ZoneDialog(
        availableSpeakers: availableSpeakers,
        currentZone: _currentZone,
        onCreateZone: _createZone,
        onAddToZone: _addToZone,
      ),
    );
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
            // Multi-Room Zone Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.speaker_group,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Multi-Room Zone',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingZone && _currentZone == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_zoneErrorMessage != null)
                      Column(
                        children: [
                          Text(
                            _zoneErrorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loadZone,
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    else if (_currentZone == null || _currentZone!.isEmpty)
                      Column(
                        children: [
                          Text(
                            'This speaker is not in a zone',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _isLoadingZone ? null : () => _showZoneDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Zone'),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.album,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _currentZone!.isMaster(widget.speaker.deviceId ?? '')
                                    ? 'Master Speaker'
                                    : 'Zone Member',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Zone Members (${_currentZone!.members.length})',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._currentZone!.members.map((member) {
                            final isCurrentSpeaker = member.deviceId == widget.speaker.deviceId;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Icon(
                                    isCurrentSpeaker ? Icons.star : Icons.speaker,
                                    size: 16,
                                    color: isCurrentSpeaker
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      member.ipAddress,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  if (!isCurrentSpeaker &&
                                      _currentZone!.isMaster(widget.speaker.deviceId ?? ''))
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      iconSize: 20,
                                      onPressed: _isLoadingZone
                                          ? null
                                          : () => _removeFromZone(member),
                                      color: theme.colorScheme.error,
                                    ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          if (_currentZone!.isMaster(widget.speaker.deviceId ?? ''))
                            FilledButton.icon(
                              onPressed: _isLoadingZone ? null : () => _showZoneDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Speakers'),
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

class _ZoneDialog extends StatefulWidget {
  final List<Speaker> availableSpeakers;
  final Zone? currentZone;
  final Function(List<Speaker>) onCreateZone;
  final Function(List<Speaker>) onAddToZone;

  const _ZoneDialog({
    required this.availableSpeakers,
    required this.currentZone,
    required this.onCreateZone,
    required this.onAddToZone,
  });

  @override
  State<_ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends State<_ZoneDialog> {
  final Set<String> _selectedSpeakerIds = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasZone = widget.currentZone != null && widget.currentZone!.isNotEmpty;

    return AlertDialog(
      title: Text(hasZone ? 'Add Speakers to Zone' : 'Create Multi-Room Zone'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasZone
                  ? 'Select speakers to add to the zone:'
                  : 'Select speakers to group with this speaker:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.availableSpeakers.length,
                itemBuilder: (context, index) {
                  final speaker = widget.availableSpeakers[index];
                  final isInZone = hasZone &&
                      widget.currentZone!.members
                          .any((m) => m.deviceId == speaker.deviceId);
                  final isSelected = _selectedSpeakerIds.contains(speaker.id);

                  return CheckboxListTile(
                    enabled: !isInZone,
                    value: isInZone ? true : isSelected,
                    onChanged: isInZone
                        ? null
                        : (value) {
                            setState(() {
                              if (value == true) {
                                _selectedSpeakerIds.add(speaker.id);
                              } else {
                                _selectedSpeakerIds.remove(speaker.id);
                              }
                            });
                          },
                    title: Row(
                      children: [
                        Text(
                          speaker.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                speaker.name,
                                style: theme.textTheme.bodyLarge,
                              ),
                              Text(
                                speaker.ipAddress,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isInZone)
                          Chip(
                            label: const Text('In Zone'),
                            backgroundColor: theme.colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedSpeakerIds.isEmpty
              ? null
              : () {
                  final selectedSpeakers = widget.availableSpeakers
                      .where((s) => _selectedSpeakerIds.contains(s.id))
                      .toList();

                  Navigator.of(context).pop();

                  if (hasZone) {
                    widget.onAddToZone(selectedSpeakers);
                  } else {
                    widget.onCreateZone(selectedSpeakers);
                  }
                },
          child: Text(hasZone ? 'Add' : 'Create Zone'),
        ),
      ],
    );
  }
}
