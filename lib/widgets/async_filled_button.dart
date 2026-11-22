import 'package:flutter/material.dart';

/// A [FilledButton.icon] that swaps its icon for a [CircularProgressIndicator]
/// and disables itself while [isLoading] is true.
class AsyncFilledButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget icon;
  final Widget label;
  final ButtonStyle? style;

  const AsyncFilledButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.icon,
    required this.label,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor =
        style?.foregroundColor?.resolve(<WidgetState>{}) ??
        Theme.of(context).colorScheme.onPrimary;

    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
              ),
            )
          : icon,
      label: label,
      style: style,
    );
  }
}
