import 'package:flutter/material.dart';

class SpeakerWarningBanner extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onOpenDoctor;

  const SpeakerWarningBanner({
    super.key,
    required this.title,
    required this.body,
    required this.onOpenDoctor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
          ActionChip(
            avatar: Icon(
              Icons.medical_services,
              color: theme.colorScheme.onErrorContainer,
              size: 16,
            ),
            label: Text(
              'Doctor',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
            backgroundColor: theme.colorScheme.errorContainer,
            side: BorderSide(color: theme.colorScheme.onErrorContainer),
            onPressed: onOpenDoctor,
          ),
        ],
      ),
    );
  }
}
