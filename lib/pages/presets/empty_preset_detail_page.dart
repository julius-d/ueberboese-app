import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/widgets/preset_edit_fab.dart';

class EmptyPresetDetailPage extends StatefulWidget {
  final String presetId;
  final String speakerIp;

  const EmptyPresetDetailPage({
    super.key,
    required this.presetId,
    required this.speakerIp,
  });

  @override
  State<EmptyPresetDetailPage> createState() => _EmptyPresetDetailPageState();
}

class _EmptyPresetDetailPageState extends State<EmptyPresetDetailPage> {
  final _fabExpandedNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _fabExpandedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Listen for changes to detect when this slot gets filled
    context.watch<MyAppState>();

    // Check if this slot is now filled
    final appState = context.read<MyAppState>();
    final actualPreset = appState.getPresetById(
      widget.speakerIp,
      widget.presetId,
    );

    // If the preset now exists, navigate back so the list can show the updated state
    if (actualPreset != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }

    // Create a temporary preset object for the edit FAB
    // This preset represents an empty slot that can be edited
    final tempPreset = Preset(
      id: widget.presetId,
      itemName: 'Empty Preset',
      source: 'NONE',
      location: '',
      type: 'none',
      isPresetable: true,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Preset ${widget.presetId}')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 100,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'This preset is empty',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Tap the edit button below to assign content to this preset slot',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _fabExpandedNotifier,
            builder: (context, isExpanded, child) {
              if (!isExpanded) return const SizedBox.shrink();
              return Positioned.fill(
                child: GestureDetector(
                  onTap: () => _fabExpandedNotifier.value = false,
                  child: Container(
                    color: theme.colorScheme.scrim.withValues(alpha: 0.4),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: PresetEditFab(
        preset: tempPreset,
        speakerIp: widget.speakerIp,
        isExpandedNotifier: _fabExpandedNotifier,
      ),
    );
  }
}
