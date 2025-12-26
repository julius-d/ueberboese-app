import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/preset.dart';

class PresetDetailPage extends StatelessWidget {
  final Preset preset;

  const PresetDetailPage({super.key, required this.preset});

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Preset ${preset.id}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (preset.containerArt != null && preset.containerArt!.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      preset.containerArt!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 200,
                          color: theme.colorScheme.surfaceVariant,
                          child: Icon(
                            Icons.music_note,
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.itemName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
                  const Divider(),
                  _buildDetailRow(
                    context,
                    'Type',
                    preset.type,
                    Icons.category,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    'Location',
                    preset.location,
                    Icons.location_on,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    'Presetable',
                    preset.isPresetable ? 'Yes' : 'No',
                    Icons.bookmark,
                  ),
                  if (preset.createdOn != null) ...[
                    const Divider(),
                    _buildDetailRow(
                      context,
                      'Created On',
                      _formatTimestamp(preset.createdOn),
                      Icons.access_time,
                    ),
                  ],
                  if (preset.updatedOn != null) ...[
                    const Divider(),
                    _buildDetailRow(
                      context,
                      'Updated On',
                      _formatTimestamp(preset.updatedOn),
                      Icons.update,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
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
                Text(
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
