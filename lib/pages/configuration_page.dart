import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_config.dart';
import '../main.dart';

class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({super.key});

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiUrlController = TextEditingController();
  final _accountIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load current config values
    final config = context.read<MyAppState>().config;
    _apiUrlController.text = config.apiUrl;
    _accountIdController.text = config.accountId;
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _accountIdController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String url) {
    if (url.isEmpty) {
      return true; // Optional field
    }
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  void _saveConfig() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final appState = context.read<MyAppState>();
    final newConfig = AppConfig(
      apiUrl: _apiUrlController.text.trim(),
      accountId: _accountIdController.text.trim(),
    );

    appState.updateConfig(newConfig);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuration saved successfully'),
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate back
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiUrlController,
              decoration: const InputDecoration(
                labelText: 'Überböse API URL',
                hintText: 'e.g., https://api.example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cloud),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (!_isValidUrl(value.trim())) {
                    return 'Please enter a valid HTTP or HTTPS URL';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _accountIdController,
              decoration: const InputDecoration(
                labelText: 'Account ID',
                hintText: 'e.g., abc123',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an account ID';
                }
                final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]*$');
                if (!alphanumericRegex.hasMatch(value.trim())) {
                  return 'Account ID must contain only letters and numbers';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveConfig,
        icon: const Icon(Icons.save),
        label: const Text('Save Configuration'),
      ),
    );
  }
}
