import 'package:flutter/material.dart';

/// Asks for the Wi-Fi password of [ssid]. Returns null if cancelled.
Future<String?> showWifiPasswordDialog(BuildContext context, String ssid) {
  return showDialog<String>(
    context: context,
    builder: (context) => _WifiPasswordDialog(ssid: ssid),
  );
}

class _WifiPasswordDialog extends StatefulWidget {
  final String ssid;

  const _WifiPasswordDialog({required this.ssid});

  @override
  State<_WifiPasswordDialog> createState() => _WifiPasswordDialogState();
}

class _WifiPasswordDialogState extends State<_WifiPasswordDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Password for "${widget.ssid}"'),
      content: TextField(
        controller: _controller,
        obscureText: _obscure,
        decoration: InputDecoration(
          labelText: 'Password',
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        autofocus: true,
        onSubmitted: (_) => Navigator.pop(context, _controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Connect'),
        ),
      ],
    );
  }
}
