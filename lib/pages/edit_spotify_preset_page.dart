import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/models/spotify_account.dart';
import 'package:ueberboese_app/models/spotify_entity.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/spotify_api_service.dart';

class EditSpotifyPresetPage extends StatefulWidget {
  final Preset preset;
  final SpotifyApiService? apiService;
  final SpeakerApiService? speakerApiService;

  const EditSpotifyPresetPage({
    super.key,
    required this.preset,
    this.apiService,
    this.speakerApiService,
  });

  @override
  State<EditSpotifyPresetPage> createState() => _EditSpotifyPresetPageState();
}


class _EditSpotifyPresetPageState extends State<EditSpotifyPresetPage> {
  late TextEditingController _spotifyUriController;
  late final SpotifyApiService _apiService;
  late final SpeakerApiService _speakerApiService;
  String? _decodingError;
  SpotifyEntity? _entity;
  bool _isLoadingEntity = false;
  String? _entityFetchError;
  Timer? _debounceTimer;
  List<SpotifyAccount> _accounts = [];
  SpotifyAccount? _selectedAccount;
  bool _isLoadingAccounts = false;
  String? _accountsFetchError;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _spotifyUriController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only initialize once
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    // Initialize services here where context is available
    if (widget.apiService != null) {
      _apiService = widget.apiService!;
    } else {
      final config = context.read<MyAppState>().config;
      _apiService = SpotifyApiService(
        username: config.mgmtUsername,
        password: config.mgmtPassword,
      );
    }
    _speakerApiService = widget.speakerApiService ?? SpeakerApiService();

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

        // Preselect account if sourceAccount matches
        if (widget.preset.sourceAccount != null) {
          try {
            _selectedAccount = accounts.firstWhere(
              (account) => account.spotifyUserId == widget.preset.sourceAccount,
            );
          } catch (e) {
            // Account not found in list - leave as null for user to select
            _selectedAccount = null;
          }
        }
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
    showDialog<void>(
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

  Future<void> _onSavePressed() async {
    final appState = context.read<MyAppState>();

    // Validate required fields
    final spotifyUri = _spotifyUriController.text.trim();
    if (spotifyUri.isEmpty) {
      _showErrorDialog('Spotify URI cannot be empty');
      return;
    }

    if (_selectedAccount == null) {
      _showErrorDialog('Please select a Spotify account');
      return;
    }

    if (_entity == null) {
      _showErrorDialog('Please wait for entity information to load');
      return;
    }

    if (appState.speakers.isEmpty) {
      _showErrorDialog('No speakers available');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final speaker = appState.speakers.first;
      await _speakerApiService.storePreset(
        speaker.ipAddress,
        widget.preset.id,
        spotifyUri,
        _selectedAccount!.spotifyUserId,
        _entity!.name,
        _entity!.imageUrl,
      );

      if (!mounted) return;

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preset saved successfully'),
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back to presets list
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showErrorDialog('Failed to save preset: ${e.toString()}');
    }
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
              const Padding(
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
              )
            else if (_entity != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_entity!.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _entity!.imageUrl!,
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
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.music_note,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 16),
                  SelectableText(
                    _entity!.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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
                initialValue: _selectedAccount,
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
              onPressed: _decodingError == null &&
                      _selectedAccount != null &&
                      _entity != null &&
                      !_isSaving
                  ? _onSavePressed
                  : null,
              child: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const Text('Save'),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
