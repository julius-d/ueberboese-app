import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/pages/edit_tunein_preset_page.dart';

class TuneInStoredPresetDetailPage extends StatefulWidget {
  final Preset preset;

  const TuneInStoredPresetDetailPage({
    super.key,
    required this.preset,
  });

  @override
  State<TuneInStoredPresetDetailPage> createState() => _TuneInStoredPresetDetailPageState();
}

class _TuneInStoredPresetDetailPageState extends State<TuneInStoredPresetDetailPage> {
  final _speakerApiService = SpeakerApiService();
  bool _isDeleting = false;

  Future<void> _showDeleteConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Preset'),
        content: Text(
          'Are you sure you want to delete preset ${widget.preset.id} "${widget.preset.itemName}"?',
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

    if (appState.speakers.isEmpty) {
      if (!mounted) return;
      _showErrorDialog('No speakers available to delete preset');
      return;
    }

    final firstSpeaker = appState.speakers.first;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _speakerApiService.removePreset(
        firstSpeaker.ipAddress,
        widget.preset.id,
      );

      if (!mounted) return;

      // Navigate back to presets list
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preset ${widget.preset.id} deleted successfully'),
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

  void _onEditPressed() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => EditTuneInPresetPage(preset: widget.preset),
      ),
    );
  }

  String? _extractStationId() {
    // Extract station ID from location format: /v1/playback/station/s288368
    final location = widget.preset.location;
    const prefix = '/v1/playback/station/';

    if (location.startsWith(prefix)) {
      return location.substring(prefix.length);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stationId = _extractStationId();

    return Scaffold(
      appBar: AppBar(
        title: Text('TuneIn Preset ${widget.preset.id}'),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.preset.containerArt != null && widget.preset.containerArt!.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.preset.containerArt!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 200,
                          color: theme.colorScheme.surfaceContainerHighest,
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
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 88.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SelectableText(
                      widget.preset.itemName,
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
                    widget.preset.id,
                    Icons.numbers,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    'Source',
                    widget.preset.source,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _onEditPressed,
        child: const Icon(Icons.edit),
      ),
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
          Icon(
            icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
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
                SelectableText(
                  value,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
