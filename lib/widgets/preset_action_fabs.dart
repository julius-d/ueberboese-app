import 'package:material_ui/material_ui.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/widgets/preset_edit_fab.dart';

/// A reusable widget that combines both play and edit FABs for preset detail pages.
/// Displays an edit FAB on top and a play FAB on the bottom.
class PresetActionFabs extends StatefulWidget {
  final Preset preset;
  final String speakerIp;
  final ValueNotifier<bool>? isExpandedNotifier;
  final SpeakerApiService? speakerApiService;

  const PresetActionFabs({
    super.key,
    required this.preset,
    required this.speakerIp,
    this.isExpandedNotifier,
    this.speakerApiService,
  });

  @override
  State<PresetActionFabs> createState() => _PresetActionFabsState();
}

class _PresetActionFabsState extends State<PresetActionFabs> {
  late final SpeakerApiService _speakerApiService;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _speakerApiService = widget.speakerApiService ?? SpeakerApiService();
  }

  Future<void> _onPlayPreset() async {
    setState(() => _isPlaying = true);

    try {
      await _speakerApiService.selectPreset(widget.speakerIp, widget.preset);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playing ${widget.preset.itemName}')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play preset: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Edit FAB
        PresetEditFab(
          preset: widget.preset,
          speakerIp: widget.speakerIp,
          isExpandedNotifier: widget.isExpandedNotifier,
        ),
        const SizedBox(height: 16),
        // Play FAB
        FloatingActionButton(
          heroTag: 'play_preset_fab',
          onPressed: _isPlaying ? null : _onPlayPreset,
          tooltip: 'Play preset',
          child: _isPlaying
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.play_arrow),
        ),
      ],
    );
  }
}
