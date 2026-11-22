import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/possible_speaker.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/speaker_discovery_service.dart';
import 'package:ueberboese_app/widgets/emoji_selector.dart';

class DiscoverSpeakersPage extends StatefulWidget {
  final SpeakerDiscoveryService? discoveryService;
  final SpeakerApiService? apiService;

  const DiscoverSpeakersPage({
    super.key,
    this.discoveryService,
    this.apiService,
  });

  @override
  State<DiscoverSpeakersPage> createState() => _DiscoverSpeakersPageState();
}

class _DiscoverSpeakersPageState extends State<DiscoverSpeakersPage> {
  late final SpeakerDiscoveryService _discoveryService;
  late final SpeakerApiService _apiService;

  bool _isSearching = true;
  final List<PossibleSpeaker> _discovered = [];
  final Set<String> _selected = {};
  final Map<String, String> _emojiAssignments = {};
  Set<String> _existingIps = {};

  StreamSubscription<PossibleSpeaker>? _subscription;

  @override
  void initState() {
    super.initState();
    _discoveryService = widget.discoveryService ?? SpeakerDiscoveryService();
    _apiService = widget.apiService ?? SpeakerApiService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _existingIps = context
          .read<MyAppState>()
          .speakers
          .map((s) => s.ipAddress)
          .toSet();
      _startDiscovery();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  String _nextEmoji() {
    final appState = context.read<MyAppState>();
    final used = {
      ...appState.speakers.map((s) => s.emoji),
      ..._emojiAssignments.values,
    };
    for (final emoji in EmojiSelector.availableEmojis) {
      if (!used.contains(emoji)) return emoji;
    }
    return EmojiSelector.availableEmojis.first;
  }

  void _startDiscovery() {
    _subscription?.cancel();
    setState(() {
      _isSearching = true;
      _discovered.clear();
      _selected.clear();
      _emojiAssignments.clear();
    });

    _subscription = _discoveryService.discover().listen(
      (possible) async {
        final emoji = _nextEmoji();
        _emojiAssignments[possible.ip] = emoji;
        setState(() => _discovered.add(possible));

        try {
          final info = await _apiService.fetchSpeakerInfo(possible.ip);
          if (!mounted) return;
          setState(() => possible.info = info);
        } catch (_) {}
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _isSearching = false);
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _isSearching = false);
      },
    );
  }

  Future<void> _addSelected() async {
    final appState = context.read<MyAppState>();
    int addedCount = 0;
    int failedCount = 0;

    for (final ip in _selected) {
      final emoji =
          _emojiAssignments[ip] ?? EmojiSelector.availableEmojis.first;
      try {
        final speaker = await _apiService.createSpeakerFromIp(ip, emoji);
        if (!mounted) return;
        appState.addSpeaker(speaker);
        addedCount++;
      } catch (_) {
        failedCount++;
      }
    }

    if (!mounted) return;

    final parts = <String>[];
    if (addedCount > 0)
      parts.add(
        'Added $addedCount ${addedCount == 1 ? 'speaker' : 'speakers'}',
      );
    if (failedCount > 0) parts.add('$failedCount failed');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(parts.join(', ')),
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.pop(context);
  }

  void _showEmojiPicker(String ip, String currentEmoji) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => EmojiSelector(
        selectedEmoji: currentEmoji,
        onEmojiSelected: (emoji) {
          setState(() => _emojiAssignments[ip] = emoji);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body;
    if (_discovered.isEmpty && !_isSearching) {
      body = const Center(child: Text('No speakers found'));
    } else {
      body = ListView.builder(
        itemCount: _discovered.length,
        itemBuilder: (context, index) {
          final possible = _discovered[index];
          final isExisting = _existingIps.contains(possible.ip);
          final existingSpeaker = isExisting
              ? context.read<MyAppState>().speakers.cast<Speaker?>().firstWhere(
                  (s) => s?.ipAddress == possible.ip,
                  orElse: () => null,
                )
              : null;
          final emoji =
              existingSpeaker?.emoji ??
              _emojiAssignments[possible.ip] ??
              EmojiSelector.availableEmojis.first;
          final isSelected = _selected.contains(possible.ip);
          final displayName = possible.info?.name ?? possible.ip;

          return CheckboxListTile(
            value: isExisting ? false : isSelected,
            onChanged: isExisting
                ? null
                : (checked) {
                    setState(() {
                      if (checked == true) {
                        _selected.add(possible.ip);
                      } else {
                        _selected.remove(possible.ip);
                      }
                    });
                  },
            secondary: GestureDetector(
              onTap: isExisting
                  ? null
                  : () => _showEmojiPicker(possible.ip, emoji),
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
            title: Text(
              displayName,
              style: isExisting
                  ? TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    )
                  : null,
            ),
            subtitle: Row(
              children: [
                Text(possible.ip),
                if (isExisting) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Already added',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Speakers'),
        bottom: _isSearching
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Rescan',
              onPressed: _startDiscovery,
            ),
        ],
      ),
      body: body,
      floatingActionButton: _selected.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _addSelected,
              icon: const Icon(Icons.add),
              label: Text(
                'Add ${_selected.length} ${_selected.length == 1 ? 'Speaker' : 'Speakers'}',
              ),
            )
          : null,
    );
  }
}
