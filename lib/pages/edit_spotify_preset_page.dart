import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/preset.dart';
import '../models/spotify_account.dart';
import '../models/spotify_entity.dart';
import '../services/spotify_api_service.dart';

class EditSpotifyPresetPage extends StatefulWidget {
  final Preset preset;
  final SpotifyApiService? apiService;

  const EditSpotifyPresetPage({
    super.key,
    required this.preset,
    this.apiService,
  });

  @override
  State<EditSpotifyPresetPage> createState() => _EditSpotifyPresetPageState();
}


class _EditSpotifyPresetPageState extends State<EditSpotifyPresetPage> {
  late TextEditingController _spotifyUriController;
  late final SpotifyApiService _apiService;
  String? _decodingError;
  SpotifyEntity? _entity;
  bool _isLoadingEntity = false;
  String? _entityFetchError;
  Timer? _debounceTimer;
  List<SpotifyAccount> _accounts = [];
  SpotifyAccount? _selectedAccount;
  bool _isLoadingAccounts = false;
  String? _accountsFetchError;

  @override
  void initState() {
    super.initState();
    _spotifyUriController = TextEditingController();

    final config = context.read<MyAppState>().config;
    _apiService = widget.apiService ??
        SpotifyApiService(
          username: config.mgmtUsername,
          password: config.mgmtPassword,
        );

    try {
      final location = widget.preset.location;
      const prefix = '/playback/container/';

      if (!location.startsWith(prefix)) {
        _decodingError = 'Invalid location format';
        return;
      }

      final base64Part = location.substring(prefix.length);
      final decodedBytes = base64Decode(base64Part);
      final decodedUri = utf8.decode(decodedBytes);

      _spotifyUriController.text = decodedUri;

      // Fetch entity info on page load if no decoding error
      if (_decodingError == null) {
        _fetchEntityInfo();
      }
    } catch (e) {
      _decodingError = 'Failed to decode Spotify URI: ${e.toString()}';
    }

    // Add listener for URI changes with debouncing
    _spotifyUriController.addListener(_onUriChanged);

    // Fetch Spotify accounts
    _fetchSpotifyAccounts();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _spotifyUriController.dispose();
    super.dispose();
  }

  void _onUriChanged() {
    // Cancel existing timer
    _debounceTimer?.cancel();

    // Set a new timer to fetch entity info after 500ms of no changes
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchEntityInfo();
    });
  }

  Future<void> _fetchEntityInfo() async {
    final spotifyUri = _spotifyUriController.text.trim();

    if (spotifyUri.isEmpty) {
      setState(() {
        _entity = null;
        _entityFetchError = null;
        _isLoadingEntity = false;
      });
      return;
    }

    final appState = context.read<MyAppState>();
    final apiUrl = appState.config.apiUrl;

    if (apiUrl.isEmpty) {
      setState(() {
        _entity = null;
        _entityFetchError = 'API URL not configured';
        _isLoadingEntity = false;
      });
      return;
    }

    setState(() {
      _isLoadingEntity = true;
      _entityFetchError = null;
    });

    try {
      final entity = await _apiService.getSpotifyEntity(apiUrl, spotifyUri);

      if (!mounted) return;

      setState(() {
        _entity = entity;
        _entityFetchError = null;
        _isLoadingEntity = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _entity = null;
        _entityFetchError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingEntity = false;
      });
    }
  }

  Future<void> _fetchSpotifyAccounts() async {
    final appState = context.read<MyAppState>();
    final apiUrl = appState.config.apiUrl;

    if (apiUrl.isEmpty) {
      setState(() {
        _accounts = [];
        _accountsFetchError = 'API URL not configured';
        _isLoadingAccounts = false;
      });
      return;
    }

    setState(() {
      _isLoadingAccounts = true;
      _accountsFetchError = null;
    });

    try {
      final accounts = await _apiService.listSpotifyAccounts(apiUrl);

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        _accountsFetchError = null;
        _isLoadingAccounts = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _accounts = [];
        _accountsFetchError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingAccounts = false;
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
    final spotifyUri = _spotifyUriController.text.trim();

    if (spotifyUri.isEmpty) {
      _showErrorDialog('Spotify URI is empty');
      return;
    }

    try {
      final webUrl = _convertSpotifyUriToWebUrl(spotifyUri);

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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onSavePressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not Implemented'),
        content: const Text('Saving is not yet implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Spotify Preset'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            if (_decodingError != null) ...[
              Card(
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
              const SizedBox(height: 16),
            ],
            // Entity display section
            if (_isLoadingEntity)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Loading entity information...'),
                    ],
                  ),
                ),
              )
            else if (_entity != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      if (_entity!.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            _entity!.imageUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 64,
                                height: 64,
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.music_note,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.music_note,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _entity!.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Spotify Entity',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_entityFetchError != null)
              Card(
                color: theme.colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _entityFetchError!,
                          style: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_entity != null || _isLoadingEntity || _entityFetchError != null)
              const SizedBox(height: 16),
            // Spotify Account Dropdown
            if (_isLoadingAccounts)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Loading Spotify accounts...'),
                    ],
                  ),
                ),
              )
            else if (_accountsFetchError != null)
              Card(
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
                          _accountsFetchError!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              DropdownButtonFormField<SpotifyAccount>(
                value: _selectedAccount,
                decoration: const InputDecoration(
                  labelText: 'Spotify Account',
                  border: OutlineInputBorder(),
                  helperText: 'Select the Spotify account to use',
                ),
                items: _accounts.isEmpty
                    ? null
                    : _accounts.map((account) {
                        return DropdownMenuItem<SpotifyAccount>(
                          value: account,
                          child: Text(account.displayName),
                        );
                      }).toList(),
                onChanged: _decodingError == null
                    ? (SpotifyAccount? newAccount) {
                        setState(() {
                          _selectedAccount = newAccount;
                        });
                      }
                    : null,
                hint: Text(
                  _accounts.isEmpty
                      ? 'No Spotify accounts connected'
                      : 'Select an account',
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _spotifyUriController,
              enabled: _decodingError == null,
              decoration: const InputDecoration(
                labelText: 'Spotify URI',
                border: OutlineInputBorder(),
                helperText: 'e.g., spotify:playlist:23SMdyOHA6KkzHoPOJ5KQ9',
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _decodingError == null ? _openInSpotify : null,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in Spotify'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _decodingError == null && _selectedAccount != null
                  ? _onSavePressed
                  : null,
              child: const Text('Save'),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
