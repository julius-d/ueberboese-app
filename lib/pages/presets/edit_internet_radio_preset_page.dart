import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/tunein_api_service.dart';
import 'package:ueberboese_app/models/tunein_station.dart';

class EditInternetRadioPresetPage extends StatefulWidget {
  final Preset preset;
  final String speakerIp;
  final SpeakerApiService? speakerApiService;
  final TuneInApiService? tuneInApiService;

  const EditInternetRadioPresetPage({
    super.key,
    required this.preset,
    required this.speakerIp,
    this.speakerApiService,
    this.tuneInApiService,
  });

  @override
  State<EditInternetRadioPresetPage> createState() =>
      _EditInternetRadioPresetPageState();
}

class _EditInternetRadioPresetPageState
    extends State<EditInternetRadioPresetPage> {
  late final SpeakerApiService _speakerApiService;
  late final TuneInApiService _tuneInApiService;
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _containerArtController;
  bool _isSaving = false;
  bool _isSearchingImage = false;
  String? _urlError;

  @override
  void initState() {
    super.initState();
    _speakerApiService = widget.speakerApiService ?? SpeakerApiService();
    _tuneInApiService = widget.tuneInApiService ?? TuneInApiService();
    _nameController = TextEditingController();
    _urlController = TextEditingController();
    _containerArtController = TextEditingController();

    // Add listener to URL field for validation
    _urlController.addListener(_validateUrl);

    // Add listener to name field to update search button state
    _nameController.addListener(() {
      setState(() {});
    });

    // Add listener to containerArt field to trigger rebuild for preview
    _containerArtController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _containerArtController.dispose();
    super.dispose();
  }

  void _validateUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _urlError = null;
      });
      return;
    }

    if (_isValidUrl(url)) {
      setState(() {
        _urlError = null;
      });
    } else {
      setState(() {
        _urlError =
            'Please enter a valid URL starting with http:// or https://';
      });
    }
  }

  bool _isValidUrl(String url) {
    if (url.trim().isEmpty) return false;
    try {
      final uri = Uri.parse(url.trim());
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
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

  Future<void> _searchStationImage() async {
    final stationName = _nameController.text.trim();

    if (stationName.isEmpty) {
      _showErrorDialog('Please enter a station name first');
      return;
    }

    setState(() {
      _isSearchingImage = true;
    });

    try {
      final results = await _tuneInApiService.searchStations(stationName);

      if (results.isEmpty) {
        if (!mounted) return;
        _showErrorDialog('No stations found for "$stationName"');
        return;
      }

      // Try to find exact match (case-insensitive)
      TuneInStation? selectedStation;
      try {
        selectedStation = results.firstWhere(
          (s) => s.text.toLowerCase() == stationName.toLowerCase(),
        );
      } catch (e) {
        // No exact match found, use first result
        selectedStation = results.first;
      }

      // Extract image URL
      final imageUrl = selectedStation.image;
      if (imageUrl == null || imageUrl.isEmpty) {
        if (!mounted) return;
        _showErrorDialog('No image found for the station');
        return;
      }

      // Update containerArt field
      _containerArtController.text = imageUrl;
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Failed to search stations: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingImage = false;
        });
      }
    }
  }

  Future<void> _onSavePressed() async {
    final appState = context.read<MyAppState>();

    // Validate required fields
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();

    if (name.isEmpty) {
      _showErrorDialog('Station name cannot be empty');
      return;
    }

    if (url.isEmpty) {
      _showErrorDialog('Stream URL cannot be empty');
      return;
    }

    if (!_isValidUrl(url)) {
      _showErrorDialog(
        'Please enter a valid URL starting with http:// or https://',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final containerArt = _containerArtController.text.trim();

      await _speakerApiService.storeInternetRadioPreset(
        widget.speakerIp,
        widget.preset.id,
        url,
        name,
        containerArt.isEmpty ? null : containerArt,
        appState.config.apiUrl,
      );

      if (!mounted) return;

      // Invalidate preset cache to trigger UI refresh
      appState.invalidatePresetsCache(widget.speakerIp);

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
      appBar: AppBar(title: const Text('Edit Internet Radio Preset')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Station Name *',
                  border: OutlineInputBorder(),
                  helperText: 'Required',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Stream URL *',
                  border: const OutlineInputBorder(),
                  helperText:
                      'Required (e.g., https://stream.example.com/radio)',
                  errorText: _urlError,
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _containerArtController,
                      decoration: const InputDecoration(
                        labelText: 'Cover Art URL',
                        border: OutlineInputBorder(),
                        helperText:
                            'Optional (e.g., https://example.com/cover.png)',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: IconButton(
                      onPressed:
                          _nameController.text.trim().isEmpty ||
                              _isSearchingImage
                          ? null
                          : _searchStationImage,
                      icon: _isSearchingImage
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      tooltip: 'Search for station image',
                    ),
                  ),
                ],
              ),
              if (_containerArtController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _containerArtController.text.trim(),
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            width: 120,
                            height: 120,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Card(
                elevation: 1,
                color: theme.colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.onSecondaryContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Note',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Make sure the stream URL is a direct link to an audio stream. '
                        'Most internet radio stations provide stream URLs on their websites.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: !_isSaving ? _onSavePressed : null,
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
