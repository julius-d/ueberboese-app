import 'package:flutter/material.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/pages/presets/edit_spotify_preset_page.dart';
import 'package:ueberboese_app/pages/presets/edit_tunein_preset_page.dart';
import 'package:ueberboese_app/pages/presets/edit_internet_radio_preset_page.dart';

/// A reusable floating action button widget that provides options to edit
/// a preset as Spotify, TuneIn, or Internet Radio.
class PresetEditFab extends StatefulWidget {
  final Preset preset;
  final String speakerIp;
  final ValueNotifier<bool>? isExpandedNotifier;

  const PresetEditFab({
    super.key,
    required this.preset,
    required this.speakerIp,
    this.isExpandedNotifier,
  });

  @override
  State<PresetEditFab> createState() => _PresetEditFabState();
}

class _PresetEditFabState extends State<PresetEditFab>
    with SingleTickerProviderStateMixin {
  bool _isFabExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

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

    // Listen to external changes to the expanded state (e.g., from backdrop tap)
    widget.isExpandedNotifier?.addListener(_onExpandedChanged);
  }

  void _onExpandedChanged() {
    final shouldBeExpanded = widget.isExpandedNotifier?.value ?? false;
    if (shouldBeExpanded != _isFabExpanded) {
      setState(() {
        _isFabExpanded = shouldBeExpanded;
        if (_isFabExpanded) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.isExpandedNotifier?.removeListener(_onExpandedChanged);
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
      widget.isExpandedNotifier?.value = _isFabExpanded;
    });
  }

  void _closeFab() {
    if (_isFabExpanded) {
      setState(() {
        _isFabExpanded = false;
        _animationController.reverse();
        widget.isExpandedNotifier?.value = false;
      });
    }
  }

  void _onEditInternetRadio() {
    _closeFab();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => EditInternetRadioPresetPage(
          preset: widget.preset,
          speakerIp: widget.speakerIp,
        ),
      ),
    );
  }

  void _onEditTuneIn() {
    _closeFab();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => EditTuneInPresetPage(
          preset: widget.preset,
          speakerIp: widget.speakerIp,
        ),
      ),
    );
  }

  void _onEditSpotify() {
    _closeFab();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => EditSpotifyPresetPage(
          preset: widget.preset,
          speakerIp: widget.speakerIp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Sub-FAB 3: Internet Radio
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
                    elevation: 3,
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        'Internet Radio',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton.small(
                    heroTag: 'edit_internet_radio_fab',
                    onPressed: _onEditInternetRadio,
                    tooltip: 'Edit as Internet Radio',
                    child: const Icon(Icons.radio),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Sub-FAB 2: TuneIn
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
                    elevation: 3,
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text('TuneIn', style: theme.textTheme.bodyMedium),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton.small(
                    heroTag: 'edit_tunein_fab',
                    onPressed: _onEditTuneIn,
                    tooltip: 'Edit as TuneIn',
                    child: const Icon(Icons.podcasts),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Sub-FAB 1: Spotify
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
                    elevation: 3,
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text('Spotify', style: theme.textTheme.bodyMedium),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton.small(
                    heroTag: 'edit_spotify_fab',
                    onPressed: _onEditSpotify,
                    tooltip: 'Edit as Spotify',
                    child: const Icon(Icons.audiotrack),
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
            tooltip: 'Edit preset',
            child: Icon(_isFabExpanded ? Icons.close : Icons.edit),
          ),
        ),
      ],
    );
  }
}
