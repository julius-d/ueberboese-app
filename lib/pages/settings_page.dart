import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/pages/ueberboese_api_setup_page.dart';
import 'package:url_launcher/url_launcher.dart';

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
              SizedBox(height: 16),
              _AboutCard(),
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

class _AboutCard extends StatefulWidget {
  const _AboutCard();

  @override
  State<_AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<_AboutCard> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _packageInfo = info);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final version = _packageInfo?.version;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // App name
            Text(
              'Überböse App',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            // Version + license badges
            Wrap(
              spacing: 8,
              children: [
                if (version != null)
                  Chip(
                    label: Text('v$version'),
                    labelStyle: theme.textTheme.labelSmall,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                Chip(
                  label: const Text('MIT License'),
                  labelStyle: theme.textTheme.labelSmall,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // Link chips
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _LinkChip(
                  label: 'F-Droid',
                  icon: Icon(Icons.android, size: 16),
                  url:
                      'https://f-droid.org/packages/io.github.juliusd.ueberboese.app',
                ),
                _LinkChip(
                  label: 'App on GitHub',
                  icon: FaIcon(FontAwesomeIcons.github, size: 14),
                  url: 'https://github.com/julius-d/ueberboese-app',
                ),
                _LinkChip(
                  label: 'API on GitHub',
                  icon: FaIcon(FontAwesomeIcons.github, size: 14),
                  url: 'https://github.com/julius-d/ueberboese-api',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.label,
    required this.icon,
    required this.url,
  });

  final String label;
  final Widget icon;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: icon,
      label: Text(label),
      onPressed: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ),
    );
  }
}
