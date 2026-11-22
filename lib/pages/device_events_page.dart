import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/models/device_event.dart';
import 'package:ueberboese_app/models/recent.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/services/management_api_service.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/main.dart';
import 'package:xml/xml.dart';

class DeviceEventsPage extends StatefulWidget {
  final Speaker speaker;
  final ManagementApiService? apiService;

  const DeviceEventsPage({super.key, required this.speaker, this.apiService});

  @override
  State<DeviceEventsPage> createState() => _DeviceEventsPageState();
}

class _EventHandler {
  final IconData icon;
  final String Function(Map<String, dynamic> data) getSummary;

  const _EventHandler({required this.icon, required this.getSummary});
}

class _DeviceEventsPageState extends State<DeviceEventsPage> {
  late final ManagementApiService _managementApiService;
  late final SpeakerApiService _speakerApiService;
  Future<List<DeviceEvent>>? _eventsFuture;
  bool _isPlaying = false;
  String? _playingEventId;

  @override
  void initState() {
    super.initState();
    _managementApiService = widget.apiService ?? ManagementApiService();
    _speakerApiService = SpeakerApiService();
    _loadEvents();
  }

  void _loadEvents() {
    final appState = context.read<MyAppState>();
    final config = appState.config;

    setState(() {
      _eventsFuture = _managementApiService.fetchDeviceEvents(
        config.apiUrl,
        widget.speaker.deviceId,
        config.mgmtUsername,
        config.mgmtPassword,
      );
    });
  }

  void _retryLoad() {
    _loadEvents();
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(time);
    }
  }

  static final Map<String, _EventHandler> _eventHandlers = {
    'art-changed': _EventHandler(
      icon: Icons.image,
      getSummary: (data) {
        final artStatus = data['art-status'] as String?;
        if (artStatus == 'IMAGE_PRESENT') return 'Album art updated';
        if (artStatus == 'SHOW_DEFAULT_IMAGE') return 'Using default image';
        return 'No additional data';
      },
    ),
    'balance-changed': _EventHandler(
      icon: Icons.tune,
      getSummary: (data) => 'Balance: ${data['balance'] ?? ''}',
    ),
    'favorite-changed': _EventHandler(
      icon: Icons.favorite,
      getSummary: (data) {
        final isFavorite =
            data['favorite-value'] == 'true' || data['favorite-value'] == true;
        return isFavorite ? 'Marked as favorite' : 'Removed from favorites';
      },
    ),
    'item-started': _EventHandler(
      icon: Icons.play_arrow,
      getSummary: (data) {
        final nowPlaying = data['nowPlaying'] as Map<String, dynamic>?;
        final source = nowPlaying?['source'] as String?;
        final track =
            (nowPlaying?['track'] as Map<String, dynamic>?)?['text'] as String?;
        if (track == null || track.isEmpty) {
          if (source == 'BLUETOOTH') {
            final connInfo =
                nowPlaying?['connectionStatusInfo'] as Map<String, dynamic>?;
            final deviceName = connInfo?['deviceName'] as String?;
            final status = connInfo?['status'] as String?;
            if (deviceName != null && deviceName.isNotEmpty) {
              if (status != null && status.isNotEmpty) {
                final formattedStatus =
                    status[0].toUpperCase() + status.substring(1).toLowerCase();
                return 'Bluetooth: $deviceName ($formattedStatus)';
              }
              return 'Bluetooth: $deviceName';
            }
          }
          return 'Playback stopped';
        }
        final artist =
            (nowPlaying?['artist'] as Map<String, dynamic>?)?['text']
                as String?;
        if (artist != null && artist.isNotEmpty) return '$track — $artist';
        return track;
      },
    ),
    'language-changed': _EventHandler(
      icon: Icons.language,
      getSummary: (data) {
        final lang = data['language'] as String?;
        if (lang == null || lang.isEmpty) return 'No additional data';
        const prefix = 'DISPLAY_LANGUAGE_';
        final name = lang.startsWith(prefix)
            ? lang.substring(prefix.length)
            : lang;
        final capitalized =
            name[0].toUpperCase() + name.substring(1).toLowerCase();
        return 'Language: $capitalized';
      },
    ),
    'masterdevice-changed': _EventHandler(
      icon: Icons.settings,
      getSummary: (data) => 'Master: ${data['masterDeviceId'] ?? ''}',
    ),
    'play-item': _EventHandler(
      icon: Icons.play_arrow,
      getSummary: (data) {
        final origin = data['origin'] as String?;
        if (origin != null && origin.isNotEmpty) return 'Played from $origin';
        return 'Played from device';
      },
    ),
    'play-state-changed': _EventHandler(
      icon: Icons.play_arrow,
      getSummary: (data) =>
          _staticFormatPlayState(data['play-state'] as String?),
    ),
    'playpause-pressed': _EventHandler(
      icon: Icons.play_arrow,
      getSummary: (data) {
        final origin = data['origin'] as String?;
        if (origin != null && origin.isNotEmpty) {
          return 'Play/Pause via $origin';
        }
        return 'Play/Pause pressed';
      },
    ),
    'power-pressed': _EventHandler(
      icon: Icons.power_settings_new,
      getSummary: (data) {
        final origin = data['origin'] as String?;
        if (origin != null && origin.isNotEmpty) return 'Power via $origin';
        return 'Power pressed';
      },
    ),
    'preset-pressed': _EventHandler(
      icon: Icons.star,
      getSummary: (data) {
        final buttonId = data['buttonId'] as String?;
        if (buttonId != null) {
          final match = RegExp(r'(\d+)$').firstMatch(buttonId);
          if (match != null) return 'Preset ${match.group(1)}';
        }
        return 'Preset pressed';
      },
    ),
    'shuffle-state-changed': _EventHandler(
      icon: Icons.shuffle,
      getSummary: (data) {
        final state = data['shuffle-state'] as String?;
        return state == 'SHUFFLE_ON' ? 'Shuffle on' : 'Shuffle off';
      },
    ),
    'skip-forward-pressed': _EventHandler(
      icon: Icons.skip_next,
      getSummary: (_) => 'Skip forward',
    ),
    'skip-backward-pressed': _EventHandler(
      icon: Icons.skip_previous,
      getSummary: (_) => 'Skip backward',
    ),
    'bass-changed': _EventHandler(
      icon: Icons.equalizer,
      getSummary: (data) {
        if (data.containsKey('bass')) return 'Bass: ${data['bass']}';
        return 'No additional data';
      },
    ),
    'clock-changed': _EventHandler(
      icon: Icons.access_time,
      getSummary: (data) {
        final parts = <String>[];
        final timezone = data['timezone'] as String?;
        if (timezone != null && timezone.isNotEmpty) parts.add(timezone);
        final timeformat = data['timeformat'];
        if (timeformat != null) parts.add('${timeformat}h');
        final brightness = data['brightness'];
        if (brightness != null) parts.add('Brightness: $brightness');
        final enabled = data['enabled'];
        if (enabled != null) {
          parts.add(
            'Display: ${enabled == 'true' || enabled == true ? 'on' : 'off'}',
          );
        }
        final useroffset = data['useroffset'];
        if (useroffset != null) parts.add('Offset: $useroffset');
        final usertime = data['usertime'];
        if (usertime != null) parts.add('User time: $usertime');
        return parts.isNotEmpty ? parts.join(' • ') : 'No additional data';
      },
    ),
    'mute-pressed': _EventHandler(
      icon: Icons.volume_off,
      getSummary: (_) => 'Mute pressed',
    ),
    'pause-pressed': _EventHandler(
      icon: Icons.pause,
      getSummary: (data) {
        final origin = data['origin'] as String?;
        if (origin != null && origin.isNotEmpty) return 'Pause via $origin';
        return 'Pause pressed';
      },
    ),
    'preset-assigned': _EventHandler(
      icon: Icons.star,
      getSummary: (data) {
        final preset = data['preset'] as String?;
        final origin = data['origin'] as String?;
        if (preset != null && preset.isNotEmpty) {
          if (origin != null && origin.isNotEmpty) {
            return '$preset assigned via $origin';
          }
          return '$preset assigned';
        }
        return 'Preset assigned';
      },
    ),
    'stop-pressed': _EventHandler(
      icon: Icons.stop,
      getSummary: (data) {
        final origin = data['origin'] as String?;
        if (origin != null && origin.isNotEmpty) return 'Stop via $origin';
        return 'Stop pressed';
      },
    ),
    'like-pressed': _EventHandler(
      icon: Icons.thumb_up,
      getSummary: (data) {
        final origin = data['origin'] as String?;
        if (origin != null && origin.isNotEmpty) return 'Like via $origin';
        return 'Like pressed';
      },
    ),
    'dislike-pressed': _EventHandler(
      icon: Icons.thumb_down,
      getSummary: (data) {
        final origin = data['origin'] as String?;
        if (origin != null && origin.isNotEmpty) return 'Dislike via $origin';
        return 'Dislike pressed';
      },
    ),
    'aux-pressed': _EventHandler(
      icon: Icons.settings_input_component,
      getSummary: (data) {
        final origin = data['origin'] as String?;
        if (origin != null && origin.isNotEmpty) return 'AUX via $origin';
        return 'AUX pressed';
      },
    ),
    'presets-changed': _EventHandler(
      icon: Icons.star,
      getSummary: (data) {
        final presets = data['presets'] as List<dynamic>?;
        if (presets == null || presets.isEmpty) return 'Presets updated';
        final parts = presets
            .map((p) {
              final preset = p as Map<String, dynamic>;
              final id = preset['id'] as String? ?? '';
              final name = preset['name'] as String? ?? '';
              return '$id: $name';
            })
            .where((s) => s != ': ')
            .toList();
        return parts.isNotEmpty ? parts.join(' \u2013 ') : 'Presets updated';
      },
    ),
    'source-state-changed': _EventHandler(
      icon: Icons.input,
      getSummary: (data) =>
          'Source: ${_staticFormatSourceState(data['source-state'] as String?)}',
    ),
    'system-state-changed': _EventHandler(
      icon: Icons.settings,
      getSummary: (data) {
        final state = data['system-state'] as String?;
        if (state != null && state.isNotEmpty) return 'System: $state';
        return 'No additional data';
      },
    ),
    'volume-change': _EventHandler(
      icon: Icons.volume_up,
      getSummary: (data) {
        if (data.containsKey('volume-change')) {
          final volumeChange = data['volume-change'];
          if (volumeChange is List && volumeChange.isNotEmpty) {
            if (volumeChange.length >= 2) {
              return 'Volume: ${volumeChange.first} → ${volumeChange.last}';
            }
            return 'Volume: ${volumeChange.first}';
          }
        }
        if (data.containsKey('volume')) return 'Volume: ${data['volume']}';
        return 'No additional data';
      },
    ),
    'volume-changed': _EventHandler(
      icon: Icons.volume_up,
      getSummary: (data) {
        if (data.containsKey('volume')) return 'Volume: ${data['volume']}';
        return 'No additional data';
      },
    ),
    'zone-state-changed': _EventHandler(
      icon: Icons.speaker_group,
      getSummary: (data) {
        final masterId = data['masterDeviceId'] as String?;
        if (masterId == null || masterId.isEmpty) return 'Zone disbanded';
        final roles = data['roles'];
        if (roles is List && roles.length > 1) {
          return 'Master: $masterId (${roles.length} devices)';
        }
        return 'Master: $masterId';
      },
    ),
  };

  IconData _getEventIcon(String eventType) {
    final handler = _eventHandlers[eventType];
    if (handler != null) return handler.icon;
    return Icons.event;
  }

  String _getEventSummary(DeviceEvent event) {
    final handler = _eventHandlers[event.type];
    if (handler != null) return handler.getSummary(event.data);
    return _fallbackSummary(event);
  }

  String _fallbackSummary(DeviceEvent event) {
    if (event.data.isEmpty) return 'No additional data';
    final parts = <String>[];
    for (final entry in event.data.entries) {
      final key = entry.key;
      final value = entry.value.toString();
      final displayValue = value.length > 30
          ? '${value.substring(0, 30)}...'
          : value;
      parts.add('$key: $displayValue');
    }
    return parts.join(' • ');
  }

  bool _isPlayableEvent(DeviceEvent event) {
    // Check if event has contentItem field
    if (!event.data.containsKey('contentItem')) return false;

    final contentItem = event.data['contentItem'] as String?;
    if (contentItem == null || contentItem.isEmpty) return false;

    // For item-started events, also check if nowPlaying has valid track data
    if (event.type == 'item-started') {
      final nowPlaying = event.data['nowPlaying'] as Map<String, dynamic>?;
      if (nowPlaying == null) return false;

      final track =
          (nowPlaying['track'] as Map<String, dynamic>?)?['text'] as String?;
      if (track == null || track.isEmpty) return false;
    }

    return true;
  }

  Recent? _parseContentItem(DeviceEvent event) {
    try {
      final contentItemBase64 = event.data['contentItem'] as String?;
      if (contentItemBase64 == null) return null;

      final xmlString = utf8.decode(base64Decode(contentItemBase64));
      final document = XmlDocument.parse(xmlString);
      final contentItemElement = document.rootElement;

      final source = contentItemElement.getAttribute('source') ?? '';
      final type = contentItemElement.getAttribute('type') ?? '';
      final location = contentItemElement.getAttribute('location') ?? '';
      final sourceAccount = contentItemElement.getAttribute('sourceAccount');
      final isPresetable =
          contentItemElement.getAttribute('isPresetable') == 'true';

      final itemName =
          contentItemElement.findElements('itemName').firstOrNull?.innerText ??
          '';
      final containerArt = contentItemElement
          .findElements('containerArt')
          .firstOrNull
          ?.innerText;

      return Recent(
        deviceId: widget.speaker.deviceId,
        utcTime: event.time.millisecondsSinceEpoch ~/ 1000,
        id: '${event.monoTime}',
        itemName: itemName,
        source: source,
        location: location,
        type: type,
        isPresetable: isPresetable,
        sourceAccount: sourceAccount,
        containerArt: containerArt,
      );
    } catch (e) {
      return null;
    }
  }

  Map<String, String>? _getNowPlayingInfo(DeviceEvent event) {
    try {
      final nowPlaying = event.data['nowPlaying'] as Map<String, dynamic>?;
      if (nowPlaying == null) return null;

      final track =
          (nowPlaying['track'] as Map<String, dynamic>?)?['text'] as String?;
      final artist =
          (nowPlaying['artist'] as Map<String, dynamic>?)?['text'] as String?;
      final album =
          (nowPlaying['album'] as Map<String, dynamic>?)?['text'] as String?;
      final artUrl =
          (nowPlaying['art'] as Map<String, dynamic>?)?['text'] as String?;

      final result = <String, String>{};
      if (track != null) result['track'] = track;
      if (artist != null) result['artist'] = artist;
      if (album != null && album.isNotEmpty) result['album'] = album;
      if (artUrl != null) result['artUrl'] = artUrl;

      return result;
    } catch (e) {
      return null;
    }
  }

  static String _staticFormatPlayState(String? playState) {
    if (playState == null) return '';
    switch (playState) {
      case 'PLAY_STATE':
        return 'Playing';
      case 'PAUSE_STATE':
        return 'Paused';
      case 'BUFFERING_STATE':
        return 'Buffering';
      case 'STOP_STATE':
        return 'Stopped';
      default:
        return playState.replaceAll('_', ' ').toLowerCase();
    }
  }

  static String _staticFormatSourceState(String? source) {
    if (source == null || source.isEmpty) return '';
    // Format known sources
    final sourceMap = {
      'SPOTIFY': 'Spotify',
      'TUNEIN': 'TuneIn',
      'BLUETOOTH': 'Bluetooth',
      'AUX': 'AUX',
      'AIRPLAY': 'AirPlay',
    };
    return sourceMap[source] ?? source;
  }

  String? _getEventContextInfo(DeviceEvent event) {
    final data = event.data;
    final parts = <String>[];

    // Get source from various places
    String? source;
    if (data.containsKey('nowPlaying')) {
      source =
          (data['nowPlaying'] as Map<String, dynamic>?)?['source'] as String?;
    }

    // Try to parse source from contentItem if not in nowPlaying
    if (source == null || source.isEmpty) {
      final recentItem = _parseContentItem(event);
      source = recentItem?.source;
    }

    if (source != null && source.isNotEmpty && source != 'INVALID_SOURCE') {
      parts.add(source);
    }

    // Get origin (how it was started)
    final origin = data['origin'] as String?;
    if (origin != null && origin.isNotEmpty) {
      parts.add('via $origin');
    }

    // Get preset information
    final preset = data['preset'];
    if (preset != null && preset != 'none' && preset.toString().isNotEmpty) {
      parts.add('Preset $preset');
    }

    // Get play state for item-started events
    if (event.type == 'item-started') {
      final playState = data['play-state'] as String?;
      if (playState == 'PAUSE_STATE') {
        parts.add('Paused');
      }

      // Add shuffle/repeat info
      final shuffleState = data['shuffle-state'] as String?;
      if (shuffleState == 'SHUFFLE_ON') {
        parts.add('Shuffle');
      }

      final repeatState = data['repeat-state'] as String?;
      if (repeatState == 'REPEAT_ONE') {
        parts.add('Repeat one');
      } else if (repeatState == 'REPEAT_ALL') {
        parts.add('Repeat all');
      }
    }

    return parts.isEmpty ? null : parts.join(' • ');
  }

  Future<void> _playContent(DeviceEvent event) async {
    final recent = _parseContentItem(event);
    if (recent == null) return;

    setState(() {
      _isPlaying = true;
      _playingEventId = '${event.monoTime}';
    });

    try {
      await _speakerApiService.selectContentItem(
        widget.speaker.ipAddress,
        recent,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Playing "${recent.itemName}"')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playingEventId = null;
        });
      }
    }
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Device Events',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DeviceEvent>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load events',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SelectableText(
                            snapshot.error.toString(),
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _retryLoad,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final events = snapshot.data ?? [];

                if (events.isEmpty) {
                  return const Center(child: Text('No events found'));
                }

                // Sort events by time, newest first
                final sortedEvents = List<DeviceEvent>.from(events)
                  ..sort((a, b) => b.time.compareTo(a.time));

                return ListView.separated(
                  itemCount: sortedEvents.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final event = sortedEvents[index];
                    final isPlayable = _isPlayableEvent(event);

                    // Display playable events like recent entries
                    if (isPlayable) {
                      final nowPlayingInfo = _getNowPlayingInfo(event);
                      final recentItem = _parseContentItem(event);

                      // Get title - prefer track from nowPlaying, fallback to itemName from contentItem
                      final track =
                          nowPlayingInfo?['track'] ??
                          recentItem?.itemName ??
                          'Unknown Track';
                      final artist = nowPlayingInfo?['artist'] ?? '';
                      final album = nowPlayingInfo?['album'];
                      final artUrl =
                          nowPlayingInfo?['artUrl'] ?? recentItem?.containerArt;
                      final contextInfo = _getEventContextInfo(event);
                      final eventId = '${event.monoTime}';
                      final isPlayingThis = _playingEventId == eventId;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        leading: artUrl != null && artUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  artUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.music_note,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.music_note,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                        title: SelectableText(
                          track,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (artist.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              SelectableText(
                                artist,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                            if (album != null && album.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              SelectableText(
                                album,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            if (contextInfo != null) ...[
                              const SizedBox(height: 2),
                              SelectableText(
                                contextInfo,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 2),
                            SelectableText(
                              _formatTimestamp(event.time),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton.filledTonal(
                          onPressed: _isPlaying
                              ? null
                              : () => _playContent(event),
                          icon: isPlayingThis
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                        ),
                      );
                    }

                    // Regular event display
                    final eventIcon = _getEventIcon(event.type);
                    final artUri = event.data['art-uri'] as String?;
                    final showArt = artUri != null && artUri.isNotEmpty;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      leading: showArt
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                artUri,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      eventIcon,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                eventIcon,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                      title: SelectableText(
                        event.type,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          SelectableText(
                            _getEventSummary(event),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            _formatTimestamp(event.time),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
