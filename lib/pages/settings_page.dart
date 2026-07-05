import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/pages/ueberboese_api_setup_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              _ApiSetupCard(),
              SizedBox(height: 16),
              _AppearanceCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApiSetupCard extends StatelessWidget {
  const _ApiSetupCard();

  @override
  Widget build(BuildContext context) {
    final config = context.watch<MyAppState>().config;
    final theme = Theme.of(context);

    return Card(
      child: SelectionArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Überböse API Setup',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const UeberboesApiSetupPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'API URL',
                value: config.apiUrl.isEmpty ? '(not set)' : config.apiUrl,
              ),
              _InfoRow(label: 'Account ID', value: config.accountId),
              const Divider(height: 24),
              Text(
                'Management API',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              _InfoRow(label: 'Username', value: config.mgmtUsername),
              _InfoRow(
                label: 'Password',
                value: '•' * config.mgmtPassword.length,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                'Appearance',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show album art in speaker list'),
              value: appState.config.showAlbumArtInList,
              onChanged: (value) {
                appState.updateConfig(
                  appState.config.copyWith(showAlbumArtInList: value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
