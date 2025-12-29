import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/speaker_info.dart';
import 'package:ueberboese_app/models/volume.dart';
import 'package:ueberboese_app/models/now_playing.dart';
import 'package:ueberboese_app/models/zone.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/pages/edit_speaker_page.dart';

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

  // Speaker info state
  SpeakerInfo? _speakerInfo;
  bool _hasMargeUrlMismatch = false;

  // Zone member volume state
  final Map<String, Volume?> _zoneMemberVolumes = {};
  final Map<String, bool> _loadingVolumes = {};
  final Map<String, String?> _volumeErrors = {};

  @override
  void initState() {
    super.initState();
    _loadVolume();
    _loadNowPlaying();
    _loadZone();
    _loadSpeakerInfo();
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

      // Load volumes for zone members if zone exists
      if (zone != null && zone.isNotEmpty) {
        _loadZoneMemberVolumes();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _zoneErrorMessage = 'Failed to load zone: ${e.toString()}';
        _isLoadingZone = false;
      });
    }
  }

  Future<void> _loadSpeakerInfo() async {
    try {
      final speakerInfo = await _apiService.fetchSpeakerInfo(widget.speaker.ipAddress);
      if (!mounted) return;

      // Get configured API URL from app settings
      final appState = context.read<MyAppState>();
      final configuredApiUrl = appState.config.apiUrl;

      // Normalize URLs for comparison (remove trailing slashes, convert to lowercase)
      final normalizedMargeUrl = speakerInfo.margeUrl?.trim().toLowerCase().replaceAll(RegExp(r'/+$'), '');
      final normalizedConfigUrl = configuredApiUrl.trim().toLowerCase().replaceAll(RegExp(r'/+$'), '');

      // Check for mismatch: both must be non-empty and different
      final hasMismatch = normalizedMargeUrl != null &&
                          normalizedMargeUrl.isNotEmpty &&
                          normalizedConfigUrl.isNotEmpty &&
                          normalizedMargeUrl != normalizedConfigUrl;

      setState(() {
        _speakerInfo = speakerInfo;
        _hasMargeUrlMismatch = hasMismatch;
      });
    } catch (e) {
      // Silently ignore errors - if we can't fetch speaker info,
      // we simply won't show a warning banner
      if (!mounted) return;
    }
  }

  Future<void> _loadZoneMemberVolumes() async {
    if (_currentZone == null || _currentZone!.isEmpty) return;

    // Load volumes for all zone members
    for (final deviceId in _currentZone!.allMemberDeviceIds) {
      final speaker = _getSpeakerByDeviceId(deviceId);
      if (speaker == null) {
        // Speaker not found in local list, skip
        continue;
      }

      setState(() {
        _loadingVolumes[deviceId] = true;
        _volumeErrors[deviceId] = null;
      });

      try {
        final volume = await _apiService.getVolume(speaker.ipAddress);
        if (!mounted) return;
        setState(() {
          _zoneMemberVolumes[deviceId] = volume;
          _loadingVolumes[deviceId] = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _volumeErrors[deviceId] = 'Failed to load volume: ${e.toString()}';
          _loadingVolumes[deviceId] = false;
        });
      }
    }
  }

  Future<void> _adjustVolume(int delta) async {
    if (_currentVolume == null) return;

    final newVolume = (_currentVolume!.actualVolume + delta).clamp(0, 100);

    setState(() {
      _isLoadingVolume = true;
      _volumeErrorMessage = null;
      // Also update zone member volume loading state if speaker is in a zone
      if (_currentZone != null && _currentZone!.isInZone(widget.speaker.deviceId)) {
        _loadingVolumes[widget.speaker.deviceId] = true;
        _volumeErrors[widget.speaker.deviceId] = null;
      }
    });

    try {
      final volume = await _apiService.setVolume(widget.speaker.ipAddress, newVolume);
      if (!mounted) return;
      setState(() {
        _currentVolume = volume;
        _isLoadingVolume = false;
        // Also update zone member volume if speaker is in a zone
        if (_currentZone != null && _currentZone!.isInZone(widget.speaker.deviceId)) {
          _zoneMemberVolumes[widget.speaker.deviceId] = volume;
          _loadingVolumes[widget.speaker.deviceId] = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _volumeErrorMessage = 'Failed to adjust volume: ${e.toString()}';
        _isLoadingVolume = false;
        // Also update zone member volume error state if speaker is in a zone
        if (_currentZone != null && _currentZone!.isInZone(widget.speaker.deviceId)) {
          _volumeErrors[widget.speaker.deviceId] = 'Failed to adjust volume: ${e.toString()}';
          _loadingVolumes[widget.speaker.deviceId] = false;
        }
      });
    }
  }

  Future<void> _adjustMemberVolume(String deviceId, int delta) async {
    final currentVolume = _zoneMemberVolumes[deviceId];
    if (currentVolume == null) return;

    final speaker = _getSpeakerByDeviceId(deviceId);
    if (speaker == null) return;

    final newVolume = (currentVolume.actualVolume + delta).clamp(0, 100);
    final isCurrentSpeaker = deviceId == widget.speaker.deviceId;

    setState(() {
      _loadingVolumes[deviceId] = true;
      _volumeErrors[deviceId] = null;
      // Also update main volume loading state if this is the current speaker
      if (isCurrentSpeaker) {
        _isLoadingVolume = true;
        _volumeErrorMessage = null;
      }
    });

    try {
      final volume = await _apiService.setVolume(speaker.ipAddress, newVolume);
      if (!mounted) return;
      setState(() {
        _zoneMemberVolumes[deviceId] = volume;
        _loadingVolumes[deviceId] = false;
        // Also update main volume if this is the current speaker
        if (isCurrentSpeaker) {
          _currentVolume = volume;
          _isLoadingVolume = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _volumeErrors[deviceId] = 'Failed to adjust volume: ${e.toString()}';
        _loadingVolumes[deviceId] = false;
        // Also update main volume error state if this is the current speaker
        if (isCurrentSpeaker) {
          _volumeErrorMessage = 'Failed to adjust volume: ${e.toString()}';
          _isLoadingVolume = false;
        }
      });
    }
  }

  Future<void> _createZone(List<Speaker> selectedSpeakers) async {
    setState(() {
      _isLoadingZone = true;
      _zoneErrorMessage = null;
    });

    try {
      // Create members list including this speaker as master
      final members = <ZoneMember>[
        ZoneMember(
          deviceId: widget.speaker.deviceId,
          ipAddress: widget.speaker.ipAddress,
        ),
        ...selectedSpeakers
            .where((s) => s.id != widget.speaker.id)
            .map((s) => ZoneMember(
                  deviceId: s.deviceId,
                  ipAddress: s.ipAddress,
                )),
      ];

      await _apiService.createZone(
        widget.speaker.ipAddress,
        widget.speaker.deviceId,
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
    if (_currentZone == null) return;

    setState(() {
      _isLoadingZone = true;
      _zoneErrorMessage = null;
    });

    try {
      final newMembers = selectedSpeakers
          .where((s) =>
              !_currentZone!.members.any((m) => m.deviceId == s.deviceId))
          .map((s) => ZoneMember(
                deviceId: s.deviceId,
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

  Future<void> _togglePlayPause() async {
    setState(() {
      _isLoadingNowPlaying = true;
      _nowPlayingErrorMessage = null;
    });

    try {

      await _apiService.userPlayControl(
        widget.speaker.ipAddress,
        'PLAY_PAUSE_CONTROL',
      );

      // Wait a bit for the state to update on the speaker
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Reload the now playing info to get the updated play status
      await _loadNowPlaying();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playback toggled')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nowPlayingErrorMessage = 'Failed to toggle playback: ${e.toString()}';
        _isLoadingNowPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle playback: ${e.toString()}')),
      );
    }
  }

  Speaker? _getSpeakerByDeviceId(String deviceId) {
    final appState = context.read<MyAppState>();
    try {
      return appState.speakers.firstWhere((s) => s.deviceId == deviceId);
    } catch (e) {
      return null;
    }
  }

  void _showZoneDialog(BuildContext context) {
    final appState = context.read<MyAppState>();
    final availableSpeakers = appState.speakers
        .where((s) => s.id != widget.speaker.id)
        .toList();

    if (availableSpeakers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other speakers available')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => _ZoneDialog(
        availableSpeakers: availableSpeakers,
        currentZone: _currentZone,
        onCreateZone: _createZone,
        onAddToZone: _addToZone,
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Speaker'),
        content: Text(
          'Are you sure you want to delete "${widget.speaker.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteSpeaker(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteSpeaker(BuildContext context) {
    final appState = context.read<MyAppState>();
    appState.removeSpeaker(widget.speaker);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.speaker.name} deleted')),
    );
  }

  Future<void> _sendToStandby() async {
    try {
      await _apiService.standby(widget.speaker.ipAddress);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speaker sent to standby')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send to standby: ${e.toString()}')),
      );
    }
  }

  String? _decodeSpotifyUri(String? location) {
    if (location == null) return null;

    try {
      const prefix = '/playback/container/';
      if (!location.startsWith(prefix)) {
        return null;
      }

      final base64Part = location.substring(prefix.length);
      final decodedBytes = base64Decode(base64Part);
      final decodedUri = utf8.decode(decodedBytes);
      return decodedUri;
    } catch (e) {
      return null;
    }
  }

  String? _convertSpotifyUriToWebUrl(String spotifyUri) {
    // Convert spotify:type:id to https://open.spotify.com/type/id
    final uriPattern = RegExp(r'^spotify:([a-z]+):(.+)$');
    final match = uriPattern.firstMatch(spotifyUri);

    if (match == null) {
      return null;
    }

    final type = match.group(1); // playlist, album, track, etc.
    final id = match.group(2);

    return 'https://open.spotify.com/$type/$id';
  }

  Future<void> _openInSpotify() async {
    if (_nowPlaying?.source != 'SPOTIFY' || _nowPlaying?.location == null) {
      return;
    }

    try {
      final spotifyUri = _decodeSpotifyUri(_nowPlaying!.location);
      if (spotifyUri == null) {
        _showErrorDialog('Failed to decode Spotify URI');
        return;
      }

      final webUrl = _convertSpotifyUriToWebUrl(spotifyUri);
      if (webUrl == null) {
        _showErrorDialog('Invalid Spotify URI format');
        return;
      }

      final uri = Uri.parse(webUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showErrorDialog('Failed to open Spotify web player');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error opening Spotify: ${e.toString()}');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
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
    final appState = context.read<MyAppState>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.speaker.emoji),
            const SizedBox(width: 8),
            Text(widget.speaker.name),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => EditSpeakerPage(speaker: widget.speaker),
                  ),
                );
              } else if (value == 'standby') {
                _sendToStandby();
              } else if (value == 'delete') {
                _showDeleteConfirmationDialog(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit speaker'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'standby',
                child: Row(
                  children: [
                    Icon(Icons.bedtime),
                    SizedBox(width: 8),
                    Text('Send to standby'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    const Text('Delete speaker'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Warning banner (only shown when there's a mismatch)
          if (_hasMargeUrlMismatch && _speakerInfo?.margeUrl != null)
            Container(
              width: double.infinity,
              color: theme.colorScheme.errorContainer,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Management URL Mismatch',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Speaker: ${_speakerInfo!.margeUrl}\nSettings: ${appState.config.apiUrl}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Existing content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.speaker.emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.speaker.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        '${widget.speaker.type} • ${widget.speaker.ipAddress}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
                                _currentZone!.isMaster(widget.speaker.deviceId)
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
                            'Zone Members (${_currentZone!.allMemberDeviceIds.length})',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._currentZone!.allMemberDeviceIds.map((deviceId) {
                            final isCurrentSpeaker = deviceId == widget.speaker.deviceId;
                            final isMaster = _currentZone!.isMaster(deviceId);
                            final speaker = _getSpeakerByDeviceId(deviceId);

                            // Find the member object for this device (null if it's the master)
                            final member = _currentZone!.members
                                .where((m) => m.deviceId == deviceId)
                                .firstOrNull;

                            // Get volume state for this member
                            final memberVolume = _zoneMemberVolumes[deviceId];
                            final isLoadingMemberVolume = _loadingVolumes[deviceId] ?? false;
                            final volumeError = _volumeErrors[deviceId];

                            // Determine role text
                            final roleText = isMaster ? 'Master' : 'Zone Member';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      // Speaker emoji and info
                                      if (speaker != null) ...[
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
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                roleText,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ] else
                                        Expanded(
                                          child: Text(
                                            member?.ipAddress ?? deviceId,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ),
                                      // Volume controls - always present to maintain alignment
                                      if (speaker != null) ...[
                                        const SizedBox(width: 16),
                                        SizedBox(
                                          height: 40,
                                          width: 40,
                                          child: FilledButton(
                                            onPressed: (isLoadingMemberVolume || memberVolume == null)
                                                ? null
                                                : () => _adjustMemberVolume(deviceId, -5),
                                            style: FilledButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(40, 40),
                                            ),
                                            child: const Icon(Icons.volume_down, size: 18),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        if (isLoadingMemberVolume)
                                          const SizedBox(
                                            width: 50,
                                            height: 16,
                                            child: Center(
                                              child: SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            ),
                                          )
                                        else if (memberVolume != null) ...[
                                          SizedBox(
                                            width: 50,
                                            child: Text(
                                              '${memberVolume.actualVolume}%',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ] else
                                          const SizedBox(width: 50),
                                        const SizedBox(width: 4),
                                        SizedBox(
                                          height: 40,
                                          width: 40,
                                          child: FilledButton(
                                            onPressed: (isLoadingMemberVolume || memberVolume == null)
                                                ? null
                                                : () => _adjustMemberVolume(deviceId, 5),
                                            style: FilledButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(40, 40),
                                            ),
                                            child: const Icon(Icons.volume_up, size: 18),
                                          ),
                                        ),
                                        // Remove button - fixed width to maintain alignment
                                        const SizedBox(width: 4),
                                        SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: (!isCurrentSpeaker &&
                                                  !isMaster &&
                                                  _currentZone!.isMaster(widget.speaker.deviceId) &&
                                                  member != null)
                                              ? FilledButton(
                                                  onPressed: _isLoadingZone
                                                      ? null
                                                      : () => _removeFromZone(member),
                                                  style: FilledButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: const Size(40, 40),
                                                    backgroundColor: theme.colorScheme.errorContainer,
                                                    foregroundColor: theme.colorScheme.onErrorContainer,
                                                  ),
                                                  child: const Icon(Icons.remove_circle_outline, size: 18),
                                                )
                                              : null,
                                        ),
                                      ],
                                    ],
                                  ),
                                  // Show error message if volume load failed
                                  if (volumeError != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 36, top: 4),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              volumeError,
                                              style: TextStyle(
                                                color: theme.colorScheme.error,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              if (speaker == null) return;
                                              setState(() {
                                                _loadingVolumes[deviceId] = true;
                                                _volumeErrors[deviceId] = null;
                                              });
                                              try {
                                                final volume = await _apiService.getVolume(speaker.ipAddress);
                                                if (!mounted) return;
                                                setState(() {
                                                  _zoneMemberVolumes[deviceId] = volume;
                                                  _loadingVolumes[deviceId] = false;
                                                });
                                              } catch (e) {
                                                if (!mounted) return;
                                                setState(() {
                                                  _volumeErrors[deviceId] = 'Failed to load volume: ${e.toString()}';
                                                  _loadingVolumes[deviceId] = false;
                                                });
                                              }
                                            },
                                            child: const Text('Retry', style: TextStyle(fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          if (_currentZone!.isMaster(widget.speaker.deviceId))
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
                          // Action buttons (Play/Pause and Open in Spotify)
                          if ((_nowPlaying!.playStatus == 'PLAY_STATE' ||
                                  _nowPlaying!.playStatus == 'PAUSE_STATE') ||
                              (_nowPlaying!.source == 'SPOTIFY' &&
                                  _nowPlaying!.location != null &&
                                  _decodeSpotifyUri(_nowPlaying!.location) != null)) ...[
                            const SizedBox(height: 16),
                            Center(
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: [
                                  // Play/Pause button
                                  if (_nowPlaying!.playStatus != null &&
                                      (_nowPlaying!.playStatus == 'PLAY_STATE' ||
                                          _nowPlaying!.playStatus == 'PAUSE_STATE'))
                                    FilledButton.icon(
                                      onPressed: _isLoadingNowPlaying ? null : _togglePlayPause,
                                      icon: Icon(
                                        _nowPlaying!.playStatus == 'PLAY_STATE'
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                      ),
                                      label: Text(
                                        _nowPlaying!.playStatus == 'PLAY_STATE'
                                            ? 'Pause'
                                            : 'Play',
                                      ),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  // Open in Spotify button
                                  if (_nowPlaying!.source == 'SPOTIFY' &&
                                      _nowPlaying!.location != null &&
                                      _decodeSpotifyUri(_nowPlaying!.location) != null)
                                    OutlinedButton.icon(
                                      onPressed: _openInSpotify,
                                      icon: const Icon(Icons.open_in_new),
                                      label: const Text('Open in Spotify'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
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
          ),
        ],
      ),
    );
  }
}

class _ZoneDialog extends StatefulWidget {
  final List<Speaker> availableSpeakers;
  final Zone? currentZone;
  final void Function(List<Speaker>) onCreateZone;
  final void Function(List<Speaker>) onAddToZone;

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
