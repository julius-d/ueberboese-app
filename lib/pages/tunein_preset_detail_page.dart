import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/models/tunein_station.dart';
import 'package:ueberboese_app/models/tunein_station_detail.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/tunein_api_service.dart';

class TuneInPresetDetailPage extends StatefulWidget {
  final Preset preset;
  final TuneInStation station;
  final TuneInApiService? tuneInApiService;
  final SpeakerApiService? speakerApiService;

  const TuneInPresetDetailPage({
    super.key,
    required this.preset,
    required this.station,
    this.tuneInApiService,
    this.speakerApiService,
  });

  @override
  State<TuneInPresetDetailPage> createState() => _TuneInPresetDetailPageState();
}

class _TuneInPresetDetailPageState extends State<TuneInPresetDetailPage> {
  late final TuneInApiService _tuneInApiService;
  late final SpeakerApiService _speakerApiService;
  TuneInStationDetail? _stationDetail;
  bool _isLoadingDetail = true;
  String? _detailFetchError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tuneInApiService = widget.tuneInApiService ?? TuneInApiService();
    _speakerApiService = widget.speakerApiService ?? SpeakerApiService();
    _fetchStationDetails();
  }

  Future<void> _fetchStationDetails() async {
    setState(() {
      _isLoadingDetail = true;
      _detailFetchError = null;
    });

    try {
      final detail = await _tuneInApiService.getStationDetails(widget.station.guideId);

      if (!mounted) return;

      setState(() {
        _stationDetail = detail;
        _isLoadingDetail = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _stationDetail = null;
        _detailFetchError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingDetail = false;
      });
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

    if (appState.speakers.isEmpty) {
      _showErrorDialog('No speakers available');
      return;
    }

    if (_stationDetail == null) {
      _showErrorDialog('Station details not loaded');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final speaker = appState.speakers.first;
      await _speakerApiService.storeTuneInPreset(
        speaker.ipAddress,
        widget.preset.id,
        widget.station.guideId,
        _stationDetail!.name,
        _stationDetail!.logo,
      );

      if (!mounted) return;

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preset saved successfully'),
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back to presets list (pop twice: detail page and search page)
      Navigator.pop(context);
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
        title: const Text('Station Details'),
      ),
      body: _isLoadingDetail
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _detailFetchError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load station details',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _detailFetchError!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchStationDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_stationDetail!.logo != null && _stationDetail!.logo!.isNotEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _stationDetail!.logo!,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.radio,
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
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 88.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: SelectableText(
                                _stationDetail!.name,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (_stationDetail!.slogan != null) ...[
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  _stationDetail!.slogan!,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            if (_stationDetail!.description != null &&
                                _stationDetail!.description!.isNotEmpty) ...[
                              _buildDetailRow(
                                context,
                                'Description',
                                _stationDetail!.description!,
                                Icons.description,
                              ),
                            ],
                            if ((_stationDetail!.location != null && _stationDetail!.location!.isNotEmpty) ||
                                (_stationDetail!.genreName != null && _stationDetail!.genreName!.isNotEmpty)) ...[
                              const Divider(height: 32),
                              if (_stationDetail!.location != null && _stationDetail!.location!.isNotEmpty)
                                _buildDetailRow(
                                  context,
                                  'Location',
                                  _stationDetail!.location!,
                                  Icons.location_on,
                                ),
                              if (_stationDetail!.genreName != null && _stationDetail!.genreName!.isNotEmpty)
                                _buildDetailRow(
                                  context,
                                  'Genre',
                                  _stationDetail!.genreName!,
                                  Icons.music_note,
                                ),
                            ],
                            if ((_stationDetail!.contentClassification != null && _stationDetail!.contentClassification!.isNotEmpty) ||
                                _stationDetail!.isFamilyContent != null ||
                                _stationDetail!.isMatureContent != null) ...[
                              const Divider(height: 32),
                              if (_stationDetail!.contentClassification != null && _stationDetail!.contentClassification!.isNotEmpty)
                                _buildDetailRow(
                                  context,
                                  'Content Type',
                                  _stationDetail!.contentClassification!,
                                  Icons.category,
                                ),
                              if (_stationDetail!.isFamilyContent != null)
                                _buildDetailRow(
                                  context,
                                  'Family Content',
                                  _stationDetail!.isFamilyContent! ? 'Yes' : 'No',
                                  Icons.family_restroom,
                                ),
                              if (_stationDetail!.isMatureContent != null)
                                _buildDetailRow(
                                  context,
                                  'Mature Content',
                                  _stationDetail!.isMatureContent! ? 'Yes' : 'No',
                                  Icons.warning,
                                ),
                            ],
                            if (_stationDetail!.url != null && _stationDetail!.url!.isNotEmpty) ...[
                              const Divider(height: 32),
                              _buildDetailRow(
                                context,
                                'Website',
                                _stationDetail!.url!,
                                Icons.link,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: _stationDetail != null && !_isSaving
          ? FloatingActionButton.extended(
              onPressed: _onSavePressed,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            )
          : _isSaving
              ? const FloatingActionButton(
                  onPressed: null,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
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
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
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
}
