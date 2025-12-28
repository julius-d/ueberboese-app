import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/pages/preset_detail_page.dart';
import 'package:ueberboese_app/pages/spotify_preset_detail_page.dart';
import 'package:ueberboese_app/pages/tunein_stored_preset_detail_page.dart';

class PresetsPage extends StatefulWidget {
  const PresetsPage({super.key});

  @override
  State<PresetsPage> createState() => _PresetsPageState();
}

class _PresetsPageState extends State<PresetsPage> {
  final _speakerApiService = SpeakerApiService();
  Future<List<Preset>>? _presetsFuture;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  void _loadPresets() {
    final appState = context.read<MyAppState>();
    if (appState.speakers.isNotEmpty) {
      final firstSpeaker = appState.speakers.first;
      setState(() {
        _presetsFuture = _speakerApiService.getPresets(firstSpeaker.ipAddress);
      });
    }
  }

  void _retryLoad() {
    _loadPresets();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final theme = Theme.of(context);

    // Check if there are no speakers
    if (appState.speakers.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No speakers available'),
        ),
      );
    }

    // If we have speakers, show the presets
    return Scaffold(
      body: FutureBuilder<List<Preset>>(
        future: _presetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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
                    'Failed to load presets',
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

          final presets = snapshot.data ?? [];

          if (presets.isEmpty) {
            return const Center(
              child: Text('No presets available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: SizedBox(
                    width: 76,
                    height: 56,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        preset.containerArt != null &&
                                preset.containerArt!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  preset.containerArt!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 56,
                                      height: 56,
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.music_note,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.music_note,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                        Positioned(
                          right: 0,
                          top: 8,
                          child: Container(
                            width: 20,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                preset.id,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    preset.itemName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    preset.source,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.primary,
                  ),
                  onTap: () {
                    if (preset.source == 'SPOTIFY') {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => SpotifyPresetDetailPage(preset: preset),
                        ),
                      );
                    } else if (preset.source == 'TUNEIN') {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => TuneInStoredPresetDetailPage(preset: preset),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => PresetDetailPage(preset: preset),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
