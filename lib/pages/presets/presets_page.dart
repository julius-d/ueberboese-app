import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/pages/presets/preset_detail_page.dart';
import 'package:ueberboese_app/pages/presets/spotify_preset_detail_page.dart';
import 'package:ueberboese_app/pages/presets/tunein_stored_preset_detail_page.dart';
import 'package:ueberboese_app/pages/presets/empty_preset_detail_page.dart';

class PresetsPage extends StatelessWidget {
  final String speakerIp;

  const PresetsPage({super.key, required this.speakerIp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Presets')),
      body: FutureBuilder<List<Preset>>(
        future: appState.getPresets(speakerIp),
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
                    onPressed: () {
                      // Invalidate cache to force refresh
                      appState.invalidatePresetsCache(speakerIp);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final presets = snapshot.data ?? [];

          // Always show all 6 preset slots (1-6)
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 6,
            itemBuilder: (context, index) {
              final presetId = (index + 1).toString();
              final preset = presets.cast<Preset?>().firstWhere(
                (p) => p?.id == presetId,
                orElse: () => null,
              );

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: SizedBox(
                    width: 76,
                    height: 56,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (preset != null)
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
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        child: Icon(
                                          Icons.music_note,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.music_note,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                        else
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.add,
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
                              color: preset != null
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                presetId,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: preset != null
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
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
                    preset?.itemName ?? 'Empty Preset',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: preset == null
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    preset?.source ?? 'No content assigned',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.primary,
                  ),
                  onTap: () {
                    if (preset == null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => EmptyPresetDetailPage(
                            presetId: presetId,
                            speakerIp: speakerIp,
                          ),
                        ),
                      );
                    } else if (preset.source == 'SPOTIFY') {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => SpotifyPresetDetailPage(
                            presetId: presetId,
                            speakerIp: speakerIp,
                          ),
                        ),
                      );
                    } else if (preset.source == 'TUNEIN') {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => TuneInStoredPresetDetailPage(
                            presetId: presetId,
                            speakerIp: speakerIp,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => PresetDetailPage(
                            presetId: presetId,
                            speakerIp: speakerIp,
                          ),
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
