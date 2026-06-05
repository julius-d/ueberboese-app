import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/speaker_info.dart';
import 'package:ueberboese_app/models/volume.dart';
import 'package:ueberboese_app/models/now_playing.dart';
import 'package:ueberboese_app/models/zone.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/speaker_websocket_service.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/pages/edit_speaker_page.dart';
import 'package:ueberboese_app/pages/remote_control_page.dart';
import 'package:ueberboese_app/pages/album_art_viewer_page.dart';
import 'package:ueberboese_app/pages/recents_page.dart';
import 'package:ueberboese_app/pages/device_events_page.dart';
import 'package:ueberboese_app/utils/url_utils.dart';
import 'package:ueberboese_app/pages/presets/presets_page.dart';
import 'package:ueberboese_app/pages/speaker_settings_page.dart';
import 'package:ueberboese_app/pages/speaker_doctor_page.dart';
import 'package:ueberboese_app/widgets/speaker_warning_banner.dart';

class SpeakerDetailPage extends StatefulWidget {
  final Speaker speaker;
  final SpeakerApiService? apiService;

  const SpeakerDetailPage({
    super.key,
    required this.speaker,
    this.apiService,
  });

  @override
  State<SpeakerDetailPage> createState() => _SpeakerDetailPageState();
}

class _SpeakerDetailPageState extends State<SpeakerDetailPage> {
  late final SpeakerApiService _apiService;
  SpeakerWebsocketService? _websocketService;
  StreamSubscription<Volume>? _volumeSubscription;
  StreamSubscription<NowPlaying>? _nowPlayingSubscription;
  StreamSubscription<void>? _zoneSubscription;

  // Use ValueNotifier for volume to avoid rebuilding entire widget tree
  final ValueNotifier<Volume?> _currentVolumeNotifier = ValueNotifier(null);
  Volume? get _currentVolume => _currentVolumeNotifier.value;
  set _currentVolume(Volume? value) => _currentVolumeNotifier.value = value;

  Zone? _currentZone;
  bool _isLoadingVolume = true;
  bool _isLoadingZone = true;
  String? _volumeErrorMessage;
  String? _zoneErrorMessage;

  // Speaker info state
  SpeakerInfo? _speakerInfo;
  bool _hasMargeUrlMismatch = false;

  // Zone member volume state
  final Map<String, Volume?> _zoneMemberVolumes = {};
  final Map<String, bool> _loadingVolumes = {};
  final Map<String, String?> _volumeErrors = {};

  // Volume slider state for debouncing
  Timer? _volumeDebounceTimer;
  double? _pendingVolume;

  // Scroll controller to preserve scroll position
  final ScrollController _scrollController = ScrollController();

  // Page storage key to maintain scroll position across rebuilds
  final PageStorageKey<String> _scrollKey = const PageStorageKey<String>('speaker_detail_scroll');

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? SpeakerApiService();
    _loadVolume();
    _loadZone();
    _loadSpeakerInfo();
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    _websocketService = SpeakerWebsocketService(widget.speaker.ipAddress);

    // Subscribe to volume updates
    _volumeSubscription = _websocketService!.volumeStream.listen(
          (volume) {
        if (!mounted) return;
        // Update volume via ValueNotifier - doesn't trigger full rebuild
        _currentVolume = volume;

        // Also update zone member volume if speaker is in a zone
        if (_currentZone != null &&
            _currentZone!.isInZone(widget.speaker.deviceId)) {
          setState(() {
            _zoneMemberVolumes[widget.speaker.deviceId] = volume;
          });
        }
      },
      onError: (error) {
        // Errors are logged in the service
      },
    );

    // Subscribe to now playing updates
    _nowPlayingSubscription = _websocketService!.nowPlayingStream.listen(
          (nowPlaying) {
        if (!mounted) return;
        // Update shared state instead of local state
        final appState = context.read<MyAppState>();
        appState.updateNowPlayingForSpeaker(
          widget.speaker.ipAddress,
          nowPlaying,
          true,
        );
      },
      onError: (error) {
        // Errors are logged in the service
      },
    );

    // Subscribe to zone updates
    _zoneSubscription = _websocketService!.zoneStream.listen(
          (_) {
        if (!mounted) return;
        // Refresh zone data when zone update is received
        _loadZone();
      },
      onError: (error) {
        // Errors are logged in the service
      },
    );

    // Connect to the WebSocket
    _websocketService!.connect();
  }

  @override
  void dispose() {
    _volumeSubscription?.cancel();
    _nowPlayingSubscription?.cancel();
    _zoneSubscription?.cancel();
    _volumeDebounceTimer?.cancel();
    _scrollController.dispose();
    _currentVolumeNotifier.dispose();
    _websocketService?.dispose();
    super.dispose();
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
      final speakerInfo = await _apiService.fetchSpeakerInfo(
          widget.speaker.ipAddress);
      if (!mounted) return;

      // Get configured API URL from app settings
      final appState = context.read<MyAppState>();
      final configuredApiUrl = appState.config.apiUrl;

      // Normalize URLs for comparison (remove trailing slashes, convert to lowercase)
      final normalizedMargeUrl = speakerInfo.margeUrl
          ?.trim()
          .toLowerCase()
          .replaceAll(RegExp(r'/+$'), '');
      final normalizedConfigUrl = configuredApiUrl
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'/+$'), '');

      // Warn only when the hosts (scheme+domain+port) differ; ignore path differences
      final hasMismatch = normalizedMargeUrl != null &&
          normalizedMargeUrl.isNotEmpty &&
          normalizedConfigUrl.isNotEmpty &&
          !urlHostsMatch(normalizedMargeUrl, normalizedConfigUrl);

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

  Future<void> _selectPreset(Preset preset) async {
    try {
      await _apiService.selectPreset(
        widget.speaker.ipAddress,
        preset,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playing ${preset.itemName}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play preset: ${e.toString()}')),
      );
    }
  }

  Future<void> _adjustVolume(int delta) async {
    if (_currentVolume == null) return;

    final newVolume = (_currentVolume!.actualVolume + delta).clamp(0, 100);

    // Update optimistically without setting loading state
    // The WebSocket will provide the authoritative update
    try {
      await _apiService.setVolume(widget.speaker.ipAddress, newVolume);
      // WebSocket will update _currentVolume automatically via subscription
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to adjust volume: ${e.toString()}')),
      );
    }
  }

  Future<void> _setVolumeDirectly(int targetVolume) async {
    if (_currentVolume == null) return;

    final newVolume = targetVolume.clamp(0, 100);

    // Update optimistically without setting loading state
    // The WebSocket will provide the authoritative update
    try {
      await _apiService.setVolume(widget.speaker.ipAddress, newVolume);
      // WebSocket will update _currentVolume automatically via subscription
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set volume: ${e.toString()}')),
      );
    }
  }

  void _onSliderChanged(double value) {
    // Update local state immediately for smooth UI
    setState(() {
      _pendingVolume = value;
    });
  }

  void _onSliderChangeEnd(double value) {
    // Cancel any pending debounce timer
    _volumeDebounceTimer?.cancel();

    // Set volume immediately when user stops dragging
    _setVolumeDirectly(value.round());

    // Clear pending volume
    setState(() {
      _pendingVolume = null;
    });
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
            .map((s) =>
            ZoneMember(
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
          .map((s) =>
          ZoneMember(
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
    try {
      await _apiService.userPlayControl(
        widget.speaker.ipAddress,
        'PLAY_PAUSE_CONTROL',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playback toggled')),
      );

      // The WebSocket will update the state automatically
    } catch (e) {
      if (!mounted) return;
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
      builder: (context) =>
          _ZoneDialog(
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
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Speaker'),
            content: Text(
              'Are you sure you want to delete "${widget.speaker
                  .name}"? This action cannot be undone.',
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
    final appState = context.read<MyAppState>();
    final nowPlaying = appState.getCachedNowPlaying(widget.speaker.ipAddress);

    if (nowPlaying?.source != 'SPOTIFY' || nowPlaying?.location == null) {
      return;
    }

    try {
      final spotifyUri = _decodeSpotifyUri(nowPlaying!.location);
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
      builder: (context) =>
          AlertDialog(
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

  void _openAlbumArtFullScreen() {
    final appState = context.read<MyAppState>();
    final nowPlaying = appState.getCachedNowPlaying(widget.speaker.ipAddress);

    if (nowPlaying?.art == null) return;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            AlbumArtViewerPage(
              imageUrl: nowPlaying!.art!,
              heroTag: 'album-art-${widget.speaker.id}',
              track: nowPlaying.track,
              artist: nowPlaying.artist,
              album: nowPlaying.album,
            ),
      ),
    );
  }

  bool _shouldShowNowPlayingCard(NowPlaying? nowPlaying) {
    // Don't show card if nowPlaying is null or still loading without data
    if (nowPlaying == null) return false;

    // Show card if TV source is active
    if (nowPlaying.source == 'PRODUCT' && nowPlaying.sourceAccount == 'TV') {
      return true;
    }

    // Check if we have actual content to display
    final hasContentInfo = nowPlaying.track != null ||
        nowPlaying.artist != null ||
        nowPlaying.album != null;

    final hasArtwork = nowPlaying.art != null &&
        nowPlaying.artImageStatus == 'IMAGE_PRESENT';

    // Only show the now playing card if we have content info OR artwork
    // Don't show placeholder when we have playback state but no actual content
    return hasContentInfo || hasArtwork;
  }

  bool _isTvSource(NowPlaying? nowPlaying) {
    return nowPlaying?.source == 'PRODUCT' && nowPlaying?.sourceAccount == 'TV';
  }

  Widget _buildSpeakerHeader(BuildContext context, ThemeData theme) {
    return Hero(
      tag: 'speaker-info-${widget.speaker.id}',
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.speaker.emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroNowPlaying(BuildContext context, ThemeData theme, NowPlaying nowPlaying) {
    // Handle TV source
    if (_isTvSource(nowPlaying)) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.tv,
              size: 120,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Playing TV sound',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Regular content (music/spotify)
    return Center(
      child: Column(
        children: [
          // Large album art
          if (nowPlaying.art != null &&
              nowPlaying.artImageStatus == 'IMAGE_PRESENT')
            GestureDetector(
              onTap: _openAlbumArtFullScreen,
              child: Hero(
                tag: 'album-art-${widget.speaker.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    nowPlaying.art!,
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.music_note,
                          size: 120,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
          else
            // Placeholder when no album art
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.music_note,
                size: 120,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 24),
          // Track and artist info (left-aligned)
          if (nowPlaying.track != null || nowPlaying.artist != null)
            SizedBox(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (nowPlaying.track != null) ...[
                    Text(
                      nowPlaying.track!,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (nowPlaying.artist != null) ...[
                    Text(
                      nowPlaying.artist!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 24),
          // Action buttons (Play/Pause and Open in Spotify in one line)
          if ((nowPlaying.playStatus != null &&
                  (nowPlaying.playStatus == 'PLAY_STATE' ||
                      nowPlaying.playStatus == 'PAUSE_STATE' ||
                      nowPlaying.playStatus == 'STOP_STATE')) ||
              (nowPlaying.source == 'SPOTIFY' &&
                  nowPlaying.location != null &&
                  _decodeSpotifyUri(nowPlaying.location) != null))
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                // Play/Pause button
                if (nowPlaying.playStatus != null &&
                    (nowPlaying.playStatus == 'PLAY_STATE' ||
                        nowPlaying.playStatus == 'PAUSE_STATE' ||
                        nowPlaying.playStatus == 'STOP_STATE'))
                  FilledButton.icon(
                    onPressed: _togglePlayPause,
                    icon: Icon(
                      nowPlaying.playStatus == 'PLAY_STATE'
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    label: Text(
                      nowPlaying.playStatus == 'PLAY_STATE'
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
                if (nowPlaying.source == 'SPOTIFY' &&
                    nowPlaying.location != null &&
                    _decodeSpotifyUri(nowPlaying.location) != null)
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
          // Shuffle and Repeat in single row
          if (nowPlaying.shuffleSetting != null ||
              nowPlaying.repeatSetting != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (nowPlaying.shuffleSetting != null) ...[
                  Icon(
                    Icons.shuffle,
                    size: 20,
                    color: nowPlaying.shuffleSetting == 'SHUFFLE_ON'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    nowPlaying.shuffleSetting == 'SHUFFLE_ON'
                        ? 'Shuffle On'
                        : 'Shuffle Off',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                if (nowPlaying.shuffleSetting != null &&
                    nowPlaying.repeatSetting != null)
                  const SizedBox(width: 24),
                if (nowPlaying.repeatSetting != null) ...[
                  Icon(
                    nowPlaying.repeatSetting == 'REPEAT_ALL'
                        ? Icons.repeat
                        : nowPlaying.repeatSetting == 'REPEAT_ONE'
                            ? Icons.repeat_one
                            : Icons.repeat,
                    size: 20,
                    color: nowPlaying.repeatSetting != 'REPEAT_OFF'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    nowPlaying.repeatSetting == 'REPEAT_ALL'
                        ? 'Repeat All'
                        : nowPlaying.repeatSetting == 'REPEAT_ONE'
                            ? 'Repeat One'
                            : 'Repeat Off',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetButton(
    BuildContext context,
    ThemeData theme,
    String presetId,
    Preset? preset,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: InkWell(
            onTap: preset != null ? () => _selectPreset(preset) : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: preset != null
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: preset != null
                      ? theme.colorScheme.outline.withValues(alpha: 0.2)
                      : theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: preset != null && preset.containerArt != null
                    ? Stack(
                        children: [
                          Image.network(
                            preset.containerArt!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPresetPlaceholder(
                                theme,
                                presetId,
                                preset,
                              );
                            },
                          ),
                          // Preset number in bottom right
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                presetId,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _buildPresetPlaceholder(theme, presetId, preset),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetPlaceholder(
    ThemeData theme,
    String presetId,
    Preset? preset,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          preset?.itemName ?? 'Preset $presetId',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: preset != null
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildAppBarActions(BuildContext context, ThemeData theme) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'edit') {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) =>
                  EditSpeakerPage(speaker: widget.speaker),
            ),
          );
        } else if (value == 'remote') {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) =>
                  RemoteControlPage(speaker: widget.speaker),
            ),
          );
        } else if (value == 'recent') {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => RecentsPage(speaker: widget.speaker),
            ),
          );
        } else if (value == 'presets') {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => PresetsPage(speakerIp: widget.speaker.ipAddress),
            ),
          );
        } else if (value == 'events') {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => DeviceEventsPage(speaker: widget.speaker),
            ),
          );
        } else if (value == 'settings') {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) =>
                  SpeakerSettingsPage(speaker: widget.speaker),
            ),
          );
        } else if (value == 'doctor') {
          _navigateToDoctor(context);
        } else if (value == 'standby') {
          _sendToStandby();
        } else if (value == 'delete') {
          _showDeleteConfirmationDialog(context);
        }
      },
      itemBuilder: (BuildContext context) =>
      [
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
          value: 'remote',
          child: Row(
            children: [
              Icon(Icons.settings_remote),
              SizedBox(width: 8),
              Text('Remote Control'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'recent',
          child: Row(
            children: [
              Icon(Icons.history),
              SizedBox(width: 8),
              Text('Recent'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'presets',
          child: Row(
            children: [
              Icon(Icons.star),
              SizedBox(width: 8),
              Text('Manage Presets'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'events',
          child: Row(
            children: [
              Icon(Icons.event),
              SizedBox(width: 8),
              Text('Device Events'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'doctor',
          child: Row(
            children: [
              Icon(Icons.home_repair_service),
              SizedBox(width: 8),
              Text('Doctor'),
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
    );
  }

  void _navigateToDoctor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => SpeakerDoctorPage(speaker: widget.speaker),
      ),
    );
  }


  Widget _buildVolumeCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 1,
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
            // Use ValueListenableBuilder to only rebuild volume section
            ValueListenableBuilder<Volume?>(
              valueListenable: _currentVolumeNotifier,
              builder: (context, currentVolume, child) {
                if (_isLoadingVolume && currentVolume == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (_volumeErrorMessage != null) {
                  return Column(
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
                  );
                }

                if (currentVolume != null) {
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      // Volume slider
                      Slider(
                        value: (_pendingVolume ?? currentVolume.actualVolume.toDouble()),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: '${(_pendingVolume ?? currentVolume.actualVolume.toDouble()).round()}%',
                        onChanged: _isLoadingVolume ? null : _onSliderChanged,
                        onChangeEnd: _onSliderChangeEnd,
                      ),
                      const SizedBox(height: 8),
                      // Volume control buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Vol down button
                          FilledButton.icon(
                            onPressed: _isLoadingVolume
                                ? null
                                : () => _adjustVolume(-5),
                            icon: const Icon(Icons.volume_down),
                            label: const Text('Down'),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 80,
                            child: Center(
                              child: Text(
                                '${currentVolume.actualVolume} %',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          FilledButton.icon(
                            onPressed: _isLoadingVolume
                                ? null
                                : () => _adjustVolume(5),
                            icon: const Icon(Icons.volume_up),
                            label: const Text('Up'),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Presets',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => PresetsPage(speakerIp: widget.speaker.ipAddress),
                      ),
                    );
                  },
                  tooltip: 'Manage Presets',
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Preset>>(
              future: context.read<MyAppState>().getPresets(widget.speaker.ipAddress),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Column(
                    children: [
                      Text(
                        'Failed to load presets: ${snapshot.error}',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          context.read<MyAppState>().invalidatePresetsCache(widget.speaker.ipAddress);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  );
                }

                final presets = snapshot.data ?? [];
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate appropriate max width
                    // On screens wider than 600px, constrain the preset grid to 500px
                    // On smaller screens, use full width
                    final maxGridWidth = constraints.maxWidth > 600 ? 500.0 : constraints.maxWidth;

                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxGridWidth),
                        child: Column(
                          children: [
                            // First row: Presets 1-3
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (var i = 1; i <= 3; i++)
                                  _buildPresetButton(
                                    context,
                                    theme,
                                    i.toString(),
                                    presets.where((p) => p.id == i.toString()).firstOrNull,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Second row: Presets 4-6
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (var i = 4; i <= 6; i++)
                                  _buildPresetButton(
                                    context,
                                    theme,
                                    i.toString(),
                                    presets.where((p) => p.id == i.toString()).firstOrNull,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
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
            Text(widget.speaker.name),
          ],
        ),
        actions: [
          _buildAppBarActions(context, theme),
        ],
      ),
      body: Column(
        children: [
          // Priority 1: URL mismatch banner
          if (_hasMargeUrlMismatch && _speakerInfo?.margeUrl != null)
            Selector<MyAppState, AppConfig>(
              selector: (_, appState) => appState.config,
              builder: (context, config, child) => SpeakerWarningBanner(
                title: 'Management URL Mismatch',
                body:
                    'Speaker: ${_speakerInfo!.margeUrl}\nSettings: ${config.apiUrl}',
                onOpenDoctor: () => _navigateToDoctor(context),
              ),
            ),
          // Priority 2: no Marge account linked (only when no mismatch and margeUrl is set)
          if (!_hasMargeUrlMismatch &&
              _speakerInfo?.margeUrl != null &&
              (_speakerInfo?.accountId == null ||
                  _speakerInfo!.accountId!.isEmpty))
            SpeakerWarningBanner(
              title: 'No Marge Account Id set',
              body:
                  'This speaker is not linked to a Marge account. Open the Doctor page to link one.',
              onOpenDoctor: () => _navigateToDoctor(context),
            ),
          // Use Selector to only rebuild when this speaker's nowPlaying changes
          Expanded(
            child: Selector<MyAppState, NowPlaying?>(
              selector: (_, appState) => appState.getCachedNowPlaying(widget.speaker.ipAddress),
              builder: (context, nowPlaying, child) {
                return SingleChildScrollView(
                  key: _scrollKey,
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Conditional rendering: Hero Now Playing or Speaker Header
                        if (_shouldShowNowPlayingCard(nowPlaying) && nowPlaying != null)
                          _buildHeroNowPlaying(context, theme, nowPlaying)
                        else
                          _buildSpeakerHeader(context, theme),
                        const SizedBox(height: 32),
                        // Volume Control Section
                        _buildVolumeCard(context, theme),
                        const SizedBox(height: 16),
                        // Multi-Room Zone Section
                        _buildZoneCard(context, theme),
                        const SizedBox(height: 16),
                        // Presets Section
                        _buildPresetsCard(context, theme),
                        // Safe area padding for modern Android gesture navigation
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(BuildContext context, ThemeData theme) {
    return Card(
                      elevation: 1,
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
                            else
                              if (_zoneErrorMessage != null)
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
                              else
                                if (_currentZone == null ||
                                    _currentZone!.isEmpty)
                                  Column(
                                    children: [
                                      Text(
                                        'This speaker is not in a zone',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme.colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      FilledButton.icon(
                                        onPressed: _isLoadingZone ? null : () =>
                                            _showZoneDialog(context),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Create Zone'),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
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
                                            _currentZone!.isMaster(
                                                widget.speaker.deviceId)
                                                ? 'Master Speaker'
                                                : 'Zone Member',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Zone Members (${_currentZone!
                                            .allMemberDeviceIds.length})',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ..._currentZone!.allMemberDeviceIds.map((
                                          deviceId) {
                                        final isCurrentSpeaker = deviceId ==
                                            widget.speaker.deviceId;
                                        final isMaster = _currentZone!.isMaster(
                                            deviceId);
                                        final speaker = _getSpeakerByDeviceId(
                                            deviceId);

                                        // Find the member object for this device (null if it's the master)
                                        final member = _currentZone!
                                            .members
                                            .where((m) =>
                                        m.deviceId == deviceId)
                                            .firstOrNull;

                                        // Get volume state for this member
                                        final memberVolume = _zoneMemberVolumes[deviceId];
                                        final isLoadingMemberVolume = _loadingVolumes[deviceId] ??
                                            false;
                                        final volumeError = _volumeErrors[deviceId];

                                        // Determine role text
                                        final roleText = isMaster
                                            ? 'Master'
                                            : 'Zone Member';

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  // Speaker emoji and info
                                                  if (speaker != null) ...[
                                                    Text(
                                                      speaker.emoji,
                                                      style: const TextStyle(
                                                          fontSize: 24),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment
                                                            .start,
                                                        children: [
                                                          Text(
                                                            speaker.name,
                                                            style: theme
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                              fontWeight: FontWeight
                                                                  .w500,
                                                            ),
                                                          ),
                                                          Text(
                                                            roleText,
                                                            style: theme
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ] else
                                                    Expanded(
                                                      child: Text(
                                                        member?.ipAddress ??
                                                            deviceId,
                                                        style: theme.textTheme
                                                            .bodyMedium,
                                                      ),
                                                    ),
                                                  // Volume controls - always present to maintain alignment
                                                  if (speaker != null) ...[
                                                    const SizedBox(width: 16),
                                                    SizedBox(
                                                      height: 40,
                                                      width: 40,
                                                      child: FilledButton(
                                                        onPressed: (isLoadingMemberVolume ||
                                                            memberVolume ==
                                                                null)
                                                            ? null
                                                            : () =>
                                                            _adjustMemberVolume(
                                                                deviceId, -5),
                                                        style: FilledButton
                                                            .styleFrom(
                                                          padding: EdgeInsets
                                                              .zero,
                                                          minimumSize: const Size(
                                                              40, 40),
                                                        ),
                                                        child: const Icon(
                                                            Icons.volume_down,
                                                            size: 18),
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
                                                            child: CircularProgressIndicator(
                                                                strokeWidth: 2),
                                                          ),
                                                        ),
                                                      )
                                                    else
                                                      if (memberVolume !=
                                                          null) ...[
                                                        SizedBox(
                                                          width: 50,
                                                          child: Text(
                                                            '${memberVolume
                                                                .actualVolume}%',
                                                            style: theme
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                              fontWeight: FontWeight
                                                                  .bold,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ),
                                                      ] else
                                                        const SizedBox(
                                                            width: 50),
                                                    const SizedBox(width: 4),
                                                    SizedBox(
                                                      height: 40,
                                                      width: 40,
                                                      child: FilledButton(
                                                        onPressed: (isLoadingMemberVolume ||
                                                            memberVolume ==
                                                                null)
                                                            ? null
                                                            : () =>
                                                            _adjustMemberVolume(
                                                                deviceId, 5),
                                                        style: FilledButton
                                                            .styleFrom(
                                                          padding: EdgeInsets
                                                              .zero,
                                                          minimumSize: const Size(
                                                              40, 40),
                                                        ),
                                                        child: const Icon(
                                                            Icons.volume_up,
                                                            size: 18),
                                                      ),
                                                    ),
                                                    // Remove button - fixed width to maintain alignment
                                                    const SizedBox(width: 4),
                                                    SizedBox(
                                                      width: 40,
                                                      height: 40,
                                                      child: (!isCurrentSpeaker &&
                                                          !isMaster &&
                                                          _currentZone!
                                                              .isMaster(
                                                              widget.speaker
                                                                  .deviceId) &&
                                                          member != null)
                                                          ? FilledButton(
                                                        onPressed: _isLoadingZone
                                                            ? null
                                                            : () =>
                                                            _removeFromZone(
                                                                member),
                                                        style: FilledButton
                                                            .styleFrom(
                                                          padding: EdgeInsets
                                                              .zero,
                                                          minimumSize: const Size(
                                                              40, 40),
                                                          backgroundColor: theme
                                                              .colorScheme
                                                              .errorContainer,
                                                          foregroundColor: theme
                                                              .colorScheme
                                                              .onErrorContainer,
                                                        ),
                                                        child: const Icon(Icons
                                                            .remove_circle_outline,
                                                            size: 18),
                                                      )
                                                          : null,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              // Show error message if volume load failed
                                              if (volumeError != null)
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .only(left: 36, top: 4),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          volumeError,
                                                          style: TextStyle(
                                                            color: theme
                                                                .colorScheme
                                                                .error,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          if (speaker == null) {
                                                            return;
                                                          }
                                                          setState(() {
                                                            _loadingVolumes[deviceId] =
                                                            true;
                                                            _volumeErrors[deviceId] =
                                                            null;
                                                          });
                                                          try {
                                                            final volume = await _apiService
                                                                .getVolume(
                                                                speaker
                                                                    .ipAddress);
                                                            if (!mounted) {
                                                              return;
                                                            }
                                                            setState(() {
                                                              _zoneMemberVolumes[deviceId] =
                                                                  volume;
                                                              _loadingVolumes[deviceId] =
                                                              false;
                                                            });
                                                          } catch (e) {
                                                            if (!mounted) {
                                                              return;
                                                            }
                                                            setState(() {
                                                              _volumeErrors[deviceId] =
                                                              'Failed to load volume: ${e
                                                                  .toString()}';
                                                              _loadingVolumes[deviceId] =
                                                              false;
                                                            });
                                                          }
                                                        },
                                                        child: const Text(
                                                            'Retry',
                                                            style: TextStyle(
                                                                fontSize: 12)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 16),
                                      if (_currentZone!.isMaster(
                                          widget.speaker.deviceId))
                                        FilledButton.icon(
                                          onPressed: _isLoadingZone
                                              ? null
                                              : () => _showZoneDialog(context),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add Speakers'),
                                        ),
                                    ],
                                  ),
                          ],
                        ),
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
    final hasZone = widget.currentZone != null &&
        widget.currentZone!.isNotEmpty;

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
                          child: Text(
                            speaker.name,
                            style: theme.textTheme.bodyLarge,
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
