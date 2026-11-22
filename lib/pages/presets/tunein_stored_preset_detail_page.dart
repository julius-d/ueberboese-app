import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/widgets/preset_action_fabs.dart';

class TuneInStoredPresetDetailPage extends StatefulWidget {
  final String presetId;
  final String speakerIp;
  final SpeakerApiService? apiService;

  const TuneInStoredPresetDetailPage({
    super.key,
    required this.presetId,
    required this.speakerIp,
    this.apiService,
  });

  @override
  State<TuneInStoredPresetDetailPage> createState() =>
      _TuneInStoredPresetDetailPageState();
}

class _TuneInStoredPresetDetailPageState
    extends State<TuneInStoredPresetDetailPage> {
  late final SpeakerApiService _speakerApiService;
  bool _isDeleting = false;
  final _fabExpandedNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _speakerApiService = widget.apiService ?? SpeakerApiService();
  }

  Future<Preset?> _getPreset() async {
    final appState = context.read<MyAppState>();
    // First check cache
    final cachedPreset = appState.getPresetById(
      widget.speakerIp,
      widget.presetId,
    );
    if (cachedPreset != null) {
      return cachedPreset;
    }
    // If not in cache, fetch from API
    final presets = await appState.getPresets(widget.speakerIp);
    return presets.where((p) => p.id == widget.presetId).firstOrNull;
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final preset = await _getPreset();
    if (preset == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Preset'),
        content: Text(
          'Are you sure you want to delete preset ${preset.id} "${preset.itemName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deletePreset();
    }
  }

  Future<void> _deletePreset() async {
    final appState = context.read<MyAppState>();

    setState(() {
      _isDeleting = true;
    });

    try {
      await _speakerApiService.removePreset(widget.speakerIp, widget.presetId);

      if (!mounted) return;

      // Invalidate cache to trigger refresh
      appState.invalidatePresetsCache(widget.speakerIp);

      // Navigate back to presets list
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preset ${widget.presetId} deleted successfully'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      _showErrorDialog('Failed to delete preset: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: SelectableText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String? _extractStationId(String location) {
    // Extract station ID from location format: /v1/playback/station/s288368
    const prefix = '/v1/playback/station/';

    if (location.startsWith(prefix)) {
      return location.substring(prefix.length);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    context.watch<MyAppState>(); // Listen for preset changes

    return FutureBuilder<Preset?>(
      future: _getPreset(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text('TuneIn Preset ${widget.presetId}')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final preset = snapshot.data;
        if (preset == null) {
          return Scaffold(
            appBar: AppBar(title: Text('TuneIn Preset ${widget.presetId}')),
            body: const Center(child: Text('Preset not found')),
          );
        }

        final stationId = _extractStationId(preset.location);

        return Scaffold(
          appBar: AppBar(
            title: Text('TuneIn Preset ${preset.id}'),
            actions: [
              if (_isDeleting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmationDialog();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: 8),
                          Text('Delete preset'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (preset.containerArt != null &&
                        preset.containerArt!.isNotEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              preset.containerArt!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.radio,
                                    size: 100,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        16.0,
                        16.0,
                        88.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: SelectableText(
                              preset.itemName,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildDetailRow(
                            context,
                            'Preset Number',
                            preset.id,
                            Icons.numbers,
                          ),
                          const Divider(),
                          _buildDetailRow(
                            context,
                            'Source',
                            preset.source,
                            Icons.source,
                          ),
                          if (stationId != null) ...[
                            const Divider(),
                            _buildDetailRow(
                              context,
                              'Station ID',
                              stationId,
                              Icons.radio,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _fabExpandedNotifier,
                builder: (context, isExpanded, child) {
                  if (!isExpanded) return const SizedBox.shrink();
                  return Positioned.fill(
                    child: GestureDetector(
                      onTap: () => _fabExpandedNotifier.value = false,
                      child: Container(
                        color: theme.colorScheme.scrim.withValues(alpha: 0.4),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: PresetActionFabs(
            preset: preset,
            speakerIp: widget.speakerIp,
            isExpandedNotifier: _fabExpandedNotifier,
            speakerApiService: _speakerApiService,
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
