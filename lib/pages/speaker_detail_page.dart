import 'package:flutter/material.dart';
import '../models/speaker.dart';

class SpeakerDetailPage extends StatelessWidget {
  final Speaker speaker;

  const SpeakerDetailPage({
    Key? key,
    required this.speaker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speaker Details'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    speaker.emoji,
                    style: const TextStyle(fontSize: 120),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    speaker.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${speaker.type} • ${speaker.ipAddress}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Space for other features can be added here
          ],
        ),
      ),
    );
  }
}
