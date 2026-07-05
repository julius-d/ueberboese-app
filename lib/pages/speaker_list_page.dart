import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/now_playing.dart';
import 'package:ueberboese_app/pages/speaker_detail_page.dart';
import 'package:ueberboese_app/pages/add_speaker_page.dart';
import 'package:ueberboese_app/pages/speaker_setup_wizard_page.dart';
import 'package:ueberboese_app/pages/discover_speakers_page.dart';

class SpeakerListPage extends StatefulWidget {
  const SpeakerListPage({super.key});

  @override
  State<SpeakerListPage> createState() => _SpeakerListPageState();
}

class _SpeakerListPageState extends State<SpeakerListPage> with SingleTickerProviderStateMixin {
  bool _isFabExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
      if (_isFabExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _closeFab() {
    if (_isFabExpanded) {
      setState(() {
        _isFabExpanded = false;
        _animationController.reverse();
      });
    }
  }

  void _startPolling() {
    // Initial poll - use addPostFrameCallback to avoid notifying during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = context.read<MyAppState>();
      appState.pollAllSpeakersNowPlaying();
    });

    // Set up periodic polling
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!mounted) return;
      final appState = context.read<MyAppState>();
      appState.pollAllSpeakersNowPlaying();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  String? _getFullArtworkUrl(Speaker speaker, NowPlaying? nowPlaying) {
    if (nowPlaying?.art == null || nowPlaying!.art!.isEmpty) return null;
    final art = nowPlaying.art!;
    if (art.startsWith('http')) return art;
    return 'http://${speaker.ipAddress}:8090$art';
  }

  Widget _buildSpeakerListTile(
    BuildContext context,
    Speaker speaker,
    ThemeData cardTheme,
    bool isConnected,
    bool isPlaying,
    bool hasArtwork,
  ) {
    final listTile = ListTile(
      leading: Text(
        speaker.emoji,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      title: Text(
        speaker.name,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: hasArtwork
            ? cardTheme.colorScheme.surface
            : !isConnected
              ? cardTheme.colorScheme.onErrorContainer
              : null,
        ),
      ),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              speaker.type,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: hasArtwork
                    ? cardTheme.colorScheme.surface
                    : !isConnected
                      ? cardTheme.colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          if (!isConnected) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.wifi_off,
              size: 16,
              color: cardTheme.colorScheme.onErrorContainer,
            ),
          ],
        ],
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: hasArtwork
            ? cardTheme.colorScheme.surface
            : Theme.of(context).colorScheme.primary,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => SpeakerDetailPage(speaker: speaker),
          ),
        );
      },
    );

    // Only wrap in Hero when there's no artwork
    // (to avoid conflict with album art hero)
    if (hasArtwork) {
      return listTile;
    }

    return Hero(
      tag: 'speaker-info-${speaker.id}',
      child: Material(
        color: Colors.transparent,
        child: listTile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final theme = Theme.of(context);

    Widget content;
    if (appState.speakers.isEmpty) {
      content = const Center(
        child: Text('No speakers available'),
      );
    } else {
      content = ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appState.speakers.length,
        itemBuilder: (context, index) {
          final speaker = appState.speakers[index];
          final nowPlaying = appState.getCachedNowPlaying(speaker.ipAddress);
          final isConnected = appState.getSpeakerConnectionStatus(speaker.ipAddress);
          final isPlaying = nowPlaying?.playStatus == 'PLAY_STATE';
          final artworkUrl = _getFullArtworkUrl(speaker, nowPlaying);
          // Show artwork if present, regardless of play status (consistent with detail page)
          final hasArtwork = appState.config.showAlbumArtInList &&
                            artworkUrl != null &&
                            artworkUrl.isNotEmpty &&
                            nowPlaying?.artImageStatus == 'IMAGE_PRESENT';
          final cardTheme = Theme.of(context);

          return Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            color: !isConnected ? cardTheme.colorScheme.errorContainer : null,
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Background image with overlay (if has artwork)
                if (hasArtwork)
                  Positioned.fill(
                    child: Hero(
                      tag: 'album-art-${speaker.id}',
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            artworkUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(),
                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                              // Only show the image with overlay if it loaded successfully
                              if (frame == null) {
                                return const SizedBox();
                              }
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  child,
                                  Container(
                                    color: cardTheme.colorScheme.scrim.withValues(alpha: 0.4),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                // Actual content
                // Wrap in Hero when there's no artwork to animate speaker info
                _buildSpeakerListTile(
                  context,
                  speaker,
                  cardTheme,
                  isConnected,
                  isPlaying,
                  hasArtwork,
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          content,
          if (_isFabExpanded)
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: _closeFab,
                  child: Container(
                    color: theme.colorScheme.scrim.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Mini FAB 3: Discover speakers
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(8),
                      color: theme.colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          'Discover',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.small(
                      heroTag: 'discover_fab',
                      onPressed: () {
                        _closeFab();
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const DiscoverSpeakersPage(),
                          ),
                        );
                      },
                      tooltip: 'Discover speakers',
                      child: const Icon(Icons.wifi_find),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Mini FAB 1b: Set up new speaker
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(8),
                      color: theme.colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          'Set up new speaker',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.small(
                      heroTag: 'setup_new_speaker_fab',
                      onPressed: () {
                        _closeFab();
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                const SpeakerSetupWizardPage(),
                          ),
                        );
                      },
                      tooltip: 'Set up new speaker',
                      child: const Icon(Icons.wifi_protected_setup),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Mini FAB 1: Add by IP
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(8),
                      color: theme.colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          'Add by IP',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.small(
                      heroTag: 'add_by_ip_fab',
                      onPressed: () {
                        _closeFab();
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const AddSpeakerPage(),
                          ),
                        );
                      },
                      tooltip: 'Add by IP',
                      child: const Icon(Icons.router),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Main FAB
          RotationTransition(
            turns: _rotationAnimation,
            child: FloatingActionButton(
              onPressed: _toggleFab,
              tooltip: 'Add speaker',
              child: Icon(_isFabExpanded ? Icons.close : Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
