import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/widgets/emoji_selector.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/management_api_service.dart';
import 'package:ueberboese_app/pages/speaker_detail_page.dart';
import 'package:ueberboese_app/pages/add_speaker_page.dart';
import 'package:ueberboese_app/pages/configuration_page.dart';

class SpeakerListPage extends StatefulWidget {
  const SpeakerListPage({super.key});

  @override
  State<SpeakerListPage> createState() => _SpeakerListPageState();
}

class _SpeakerListPageState extends State<SpeakerListPage> with SingleTickerProviderStateMixin {
  bool _isFabExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  final _speakerApiService = SpeakerApiService();
  final _managementApiService = ManagementApiService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
      if (_isFabExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _closeFab() {
    if (_isFabExpanded) {
      setState(() {
        _isFabExpanded = false;
        _animationController.reverse();
      });
    }
  }

  String _getNextAvailableEmoji(List<Speaker> speakers) {
    final usedEmojis = speakers.map((s) => s.emoji).toSet();

    for (final emoji in EmojiSelector.availableEmojis) {
      if (!usedEmojis.contains(emoji)) {
        return emoji;
      }
    }

    return EmojiSelector.availableEmojis.first;
  }

  Future<void> _addAllSpeakersFromAccount() async {
    _closeFab();

    final appState = context.read<MyAppState>();
    final config = appState.config;

    // Validate configuration
    if (config.apiUrl.isEmpty) {
      _showConfigurationErrorDialog(
        'API URL not configured',
        'Please configure the Überböse API URL in the settings to use this feature.',
      );
      return;
    }

    if (config.accountId.isEmpty) {
      _showConfigurationErrorDialog(
        'Account ID not configured',
        'Please configure your Account ID in the settings to use this feature.',
      );
      return;
    }

    if (config.mgmtUsername.isEmpty) {
      _showConfigurationErrorDialog(
        'Management username not configured',
        'Please configure the management username in the settings to use this feature.',
      );
      return;
    }

    if (config.mgmtPassword.isEmpty) {
      _showConfigurationErrorDialog(
        'Management password not configured',
        'Please configure the management password in the settings to use this feature.',
      );
      return;
    }

    // Check if running on web
    if (kIsWeb) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Web Platform Not Supported'),
          content: const Text(
            'Adding speakers from account is not supported in the web browser due to CORS restrictions.\n\n'
            'Please use the native app instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show loading dialog
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fetching speakers from account...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Fetch IP addresses from management API
      final ipAddresses = await _managementApiService.fetchAccountSpeakers(
        config.apiUrl,
        config.accountId,
        config.mgmtUsername,
        config.mgmtPassword,
      );

      if (!mounted) return;

      if (ipAddresses.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No speakers found in account'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Process each IP address
      int addedCount = 0;
      int existingCount = 0;
      int failedCount = 0;

      for (final ipAddress in ipAddresses) {
        // Check if speaker already exists
        final existingSpeaker = appState.speakers.cast<Speaker?>().firstWhere(
          (speaker) => speaker?.ipAddress == ipAddress,
          orElse: () => null,
        );

        if (existingSpeaker != null) {
          existingCount++;
          continue;
        }

        // Try to fetch speaker info and add
        try {
          final speakerInfo = await _speakerApiService.fetchSpeakerInfo(ipAddress);
          final emoji = _getNextAvailableEmoji(appState.speakers);

          final newSpeaker = Speaker(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: speakerInfo.name,
            emoji: emoji,
            ipAddress: ipAddress,
            type: speakerInfo.type,
            deviceId: speakerInfo.accountId ?? '',
          );

          appState.addSpeaker(newSpeaker);
          addedCount++;

          // Small delay to avoid overwhelming the speakers
          await Future<void>.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          failedCount++;
        }
      }

      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      // Show summary
      if (addedCount > 0 || existingCount > 0) {
        final parts = <String>[];
        if (addedCount > 0) {
          parts.add('Added $addedCount ${addedCount == 1 ? 'speaker' : 'speakers'}');
        }
        if (existingCount > 0) {
          parts.add('$existingCount already existed');
        }
        if (failedCount > 0) {
          parts.add('$failedCount failed');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parts.join(', ')),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Failed to Add Speakers'),
            content: Text(
              'Failed to add any speakers from the account. $failedCount ${failedCount == 1 ? 'speaker' : 'speakers'} could not be reached.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: SelectableText(
            'Failed to fetch speakers from account.\n\n${e.toString()}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showConfigurationErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const ConfigurationPage(),
                ),
              );
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final theme = Theme.of(context);

    Widget content;
    if (appState.speakers.isEmpty) {
      content = const Center(
        child: Text('No speakers available'),
      );
    } else {
      content = ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appState.speakers.length,
        itemBuilder: (context, index) {
          final speaker = appState.speakers[index];
          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: ListTile(
              leading: Text(
                speaker.emoji,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              title: Text(
                speaker.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                speaker.type,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => SpeakerDetailPage(speaker: speaker),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          content,
          if (_isFabExpanded)
            GestureDetector(
              onTap: _closeFab,
              child: Container(
                color: theme.colorScheme.scrim.withValues(alpha: 0.4),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Mini FAB 2: Add all from account
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      color: theme.colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          'Add all from account',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.small(
                      heroTag: 'add_all_fab',
                      onPressed: _addAllSpeakersFromAccount,
                      tooltip: 'Add all from account',
                      child: const Icon(Icons.cloud_download),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Mini FAB 1: Add by IP
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      color: theme.colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          'Add by IP',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.small(
                      heroTag: 'add_by_ip_fab',
                      onPressed: () {
                        _closeFab();
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const AddSpeakerPage(),
                          ),
                        );
                      },
                      tooltip: 'Add by IP',
                      child: const Icon(Icons.router),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Main FAB
          RotationTransition(
            turns: _rotationAnimation,
            child: FloatingActionButton(
              onPressed: _toggleFab,
              tooltip: 'Add speaker',
              child: Icon(_isFabExpanded ? Icons.close : Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
