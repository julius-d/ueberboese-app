import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/spotify_api_service.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/pages/edit_spotify_preset_page.dart';

class SpotifyPresetDetailPage extends StatefulWidget {
  final Preset preset;
  final SpotifyApiService? spotifyApiService;

  const SpotifyPresetDetailPage({
    super.key,
    required this.preset,
    this.spotifyApiService,
  });

  @override
  State<SpotifyPresetDetailPage> createState() => _SpotifyPresetDetailPageState();
}

class _SpotifyPresetDetailPageState extends State<SpotifyPresetDetailPage> {
  final _speakerApiService = SpeakerApiService();
  late final SpotifyApiService _spotifyApiService;
  bool _isDeleting = false;
  String? _decodedUri;
  String? _decodingError;
  String? _accountDisplayName;
  bool _isLoadingAccount = false;
  String? _accountFetchError;

  @override
  void initState() {
    super.initState();

    final config = context.read<MyAppState>().config;
    _spotifyApiService = widget.spotifyApiService ??
        SpotifyApiService(
          username: config.mgmtUsername,
          password: config.mgmtPassword,
        );

    _decodeSpotifyUri();
    _fetchSpotifyAccount();
  }

  void _decodeSpotifyUri() {
    try {
      final location = widget.preset.location;
      const prefix = '/playback/container/';

      if (!location.startsWith(prefix)) {
        setState(() {
          _decodingError = 'Invalid location format';
        });
        return;
      }

      final base64Part = location.substring(prefix.length);
      final decodedBytes = base64Decode(base64Part);
      final decodedUri = utf8.decode(decodedBytes);

      setState(() {
        _decodedUri = decodedUri;
        _decodingError = null;
      });
    } catch (e) {
      setState(() {
        _decodedUri = null;
        _decodingError = 'Failed to decode Spotify URI: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchSpotifyAccount() async {
    if (widget.preset.sourceAccount == null) {
      return;
    }

    final appState = context.read<MyAppState>();
    final apiUrl = appState.config.apiUrl;

    if (apiUrl.isEmpty) return;

    setState(() {
      _isLoadingAccount = true;
    });

    try {
      final accounts = await _spotifyApiService.listSpotifyAccounts(apiUrl);
      final account = accounts.firstWhere(
        (a) => a.spotifyUserId == widget.preset.sourceAccount,
        orElse: () => throw Exception('Account not found'),
      );

      if (!mounted) return;
      setState(() {
        _accountDisplayName = account.displayName;
        _isLoadingAccount = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _accountDisplayName = null;
        _accountFetchError = e.toString();
        _isLoadingAccount = false;
      });
    }
  }

  String? _convertSpotifyUriToWebUrl(String spotifyUri) {
    // Convert spotify:type:id to https://open.spotify.com/type/id
    final uriPattern = RegExp(r'^spotify:([a-z]+):(.+)$');
    final match = uriPattern.firstMatch(spotifyUri);

    if (match == null) {
      return null;
    }

    final type = match.group(1); // playlist, album, track, etc.
    final id = match.group(2);

    return 'https://open.spotify.com/$type/$id';
  }

  Future<void> _openInSpotify() async {
    if (_decodedUri == null || _decodedUri!.isEmpty) {
      _showErrorDialog('Spotify URI could not be decoded');
      return;
    }

    try {
      final webUrl = _convertSpotifyUriToWebUrl(_decodedUri!);

      if (webUrl == null) {
        _showErrorDialog('Invalid Spotify URI format. Expected format: spotify:type:id');
        return;
      }

      final uri = Uri.parse(webUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showErrorDialog('Failed to open Spotify web player.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error opening Spotify: ${e.toString()}');
      }
    }
  }

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
        builder: (context) => EditSpotifyPresetPage(preset: widget.preset),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Spotify Preset ${widget.preset.id}'),
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
                    borderRadius: BorderRadius.circular(8),
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
                  if (widget.preset.sourceAccount != null) ...[
                    const Divider(),
                    if (_isLoadingAccount)
                      _buildLoadingRow(context, 'Spotify Account', Icons.account_circle)
                    else if (_accountDisplayName != null)
                      _buildDetailRow(
                        context,
                        'Spotify Account',
                        _accountDisplayName!,
                        Icons.account_circle,
                      )
                    else if (_accountFetchError != null)
                      _buildDetailRow(
                        context,
                        'Spotify Account',
                        widget.preset.sourceAccount!,
                        Icons.account_circle,
                      ),
                  ],
                  if (_decodedUri != null) ...[
                    const Divider(),
                    _buildDetailRow(
                      context,
                      'Spotify URI',
                      _decodedUri!,
                      Icons.link,
                    ),
                  ],
                  if (_decodingError != null) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Card(
                        color: theme.colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _decodingError!,
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _decodingError == null ? _openInSpotify : null,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open in Spotify'),
                    ),
                  ),
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

  Widget _buildLoadingRow(BuildContext context, String label, IconData icon) {
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
                const Text('Loading...'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
