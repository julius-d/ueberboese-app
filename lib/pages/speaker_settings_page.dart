import 'package:flutter/material.dart';
import 'package:ueberboese_app/models/bass.dart';
import 'package:ueberboese_app/models/clock_display.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';

enum SpeakerLanguage {
  danish(1, 'Danish'),
  german(2, 'German'),
  english(3, 'English'),
  spanish(4, 'Spanish'),
  french(5, 'French'),
  italian(6, 'Italian'),
  dutch(7, 'Dutch'),
  swedish(8, 'Swedish'),
  japanese(9, 'Japanese'),
  simplifiedChinese(10, 'Simplified Chinese'),
  traditionalChinese(11, 'Traditional Chinese'),
  korean(12, 'Korean'),
  thai(13, 'Thai'),
  czech(15, 'Czech'),
  finnish(16, 'Finnish'),
  greek(17, 'Greek'),
  norwegian(18, 'Norwegian'),
  polish(19, 'Polish'),
  portuguese(20, 'Portuguese'),
  romanian(21, 'Romanian'),
  russian(22, 'Russian'),
  slovenian(23, 'Slovenian'),
  turkish(24, 'Turkish'),
  hungarian(25, 'Hungarian');

  const SpeakerLanguage(this.code, this.displayName);

  final int code;
  final String displayName;

  static SpeakerLanguage? fromCode(int code) {
    for (final lang in SpeakerLanguage.values) {
      if (lang.code == code) return lang;
    }
    return null;
  }
}

class SpeakerSettingsPage extends StatefulWidget {
  final Speaker speaker;
  final SpeakerApiService? apiService;

  const SpeakerSettingsPage({
    super.key,
    required this.speaker,
    this.apiService,
  });

  @override
  State<SpeakerSettingsPage> createState() => _SpeakerSettingsPageState();
}

class _SpeakerSettingsPageState extends State<SpeakerSettingsPage> {
  late final SpeakerApiService _apiService;

  SpeakerLanguage? _currentLanguage;
  bool _loadingLanguage = true;
  String? _languageError;

  BassCapabilities? _bassCapabilities;
  Bass? _currentBass;
  bool _loadingBass = true;
  String? _bassError;
  double? _pendingBass;

  ClockConfig? _clockConfig;
  bool _clockSupported = false;
  bool _loadingClock = true;
  String? _clockError;
  int? _pendingBrightness;
  bool _applyingClock = false;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? SpeakerApiService();
    _loadLanguage();
    _loadBass();
    _loadClock();
  }

  Future<void> _loadLanguage() async {
    setState(() {
      _loadingLanguage = true;
      _languageError = null;
    });
    try {
      final code = await _apiService.getLanguage(widget.speaker.ipAddress);
      setState(() {
        _currentLanguage = SpeakerLanguage.fromCode(code);
        _loadingLanguage = false;
      });
    } catch (e) {
      setState(() {
        _languageError = e.toString();
        _loadingLanguage = false;
      });
    }
  }

  Future<void> _loadBass() async {
    setState(() {
      _loadingBass = true;
      _bassError = null;
    });
    try {
      final capabilities = await _apiService.getBassCapabilities(
        widget.speaker.ipAddress,
      );
      final bass = capabilities.bassAvailable
          ? await _apiService.getBass(widget.speaker.ipAddress)
          : null;
      setState(() {
        _bassCapabilities = capabilities;
        _currentBass = bass;
        _loadingBass = false;
      });
    } catch (e) {
      setState(() {
        _bassError = e.toString();
        _loadingBass = false;
      });
    }
  }

  Future<void> _loadClock() async {
    setState(() {
      _loadingClock = true;
      _clockError = null;
    });
    try {
      final supported = await _apiService.isClockDisplaySupported(
        widget.speaker.ipAddress,
      );
      final config = supported
          ? await _apiService.getClockDisplay(widget.speaker.ipAddress)
          : null;
      setState(() {
        _clockSupported = supported;
        _clockConfig = config;
        _loadingClock = false;
      });
    } catch (e) {
      setState(() {
        _clockError = e.toString();
        _loadingClock = false;
      });
    }
  }

  Future<void> _showLanguageDialog() async {
    final SpeakerLanguage? selected = _currentLanguage;

    final result = await showDialog<SpeakerLanguage>(
      context: context,
      builder: (context) => _LanguagePickerDialog(initial: selected),
    );

    if (result == null || result == _currentLanguage) return;

    try {
      await _apiService.setLanguage(widget.speaker.ipAddress, result.code);
      setState(() {
        _currentLanguage = result;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to set language: $e')));
    }
  }

  Future<void> _onBassChangeEnd(double value) async {
    await _applyBass(value.round());
  }

  Future<void> _adjustBass(int delta) async {
    final caps = _bassCapabilities;
    final bass = _currentBass;
    if (caps == null || bass == null) return;
    final current = (_pendingBass ?? bass.actualBass.toDouble()).round();
    final next = (current + delta).clamp(caps.bassMin, caps.bassMax);
    await _applyBass(next);
  }

  Future<void> _resetBass() async {
    final caps = _bassCapabilities;
    if (caps == null) return;
    await _applyBass(caps.bassDefault);
  }

  Future<void> _applyBass(int value) async {
    try {
      await _apiService.setBass(widget.speaker.ipAddress, value);
      final bass = await _apiService.getBass(widget.speaker.ipAddress);
      if (!mounted) return;
      setState(() {
        _currentBass = bass;
        _pendingBass = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _pendingBass = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to set bass: $e')));
    }
  }

  Future<void> _applyClockConfig(ClockConfig updated) async {
    setState(() => _applyingClock = true);
    try {
      await _apiService.setClockDisplay(widget.speaker.ipAddress, updated);
      final config = await _apiService.getClockDisplay(
        widget.speaker.ipAddress,
      );
      if (!mounted) return;
      setState(() {
        _clockConfig = config;
        _pendingBrightness = null;
        _applyingClock = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pendingBrightness = null;
        _applyingClock = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set clock display: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Settings – ${widget.speaker.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLanguageCard(theme),
          const SizedBox(height: 16),
          _buildBassCard(theme),
          const SizedBox(height: 16),
          _buildClockCard(theme),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(ThemeData theme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Language',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildLanguageValue(theme)),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Change language',
                  onPressed: _loadingLanguage ? null : _showLanguageDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageValue(ThemeData theme) {
    if (_loadingLanguage) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (_languageError != null) {
      return Text(
        'Error loading language',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }
    final lang = _currentLanguage;
    return Text(
      lang != null ? lang.displayName : 'Unknown',
      style: theme.textTheme.bodyLarge,
    );
  }

  Widget _buildBassCard(ThemeData theme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.equalizer, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Bass',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBassContent(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBassContent(ThemeData theme) {
    if (_loadingBass) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_bassError != null) {
      return Column(
        children: [
          Text(
            'Error loading bass',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadBass, child: const Text('Retry')),
        ],
      );
    }

    final caps = _bassCapabilities;
    if (caps == null) return const SizedBox.shrink();

    if (!caps.bassAvailable) {
      return Text(
        'Bass control not supported on this device',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final bass = _currentBass;
    if (bass == null) return const SizedBox.shrink();

    final sliderValue = (_pendingBass ?? bass.actualBass.toDouble()).clamp(
      caps.bassMin.toDouble(),
      caps.bassMax.toDouble(),
    );
    final busy = _pendingBass != null;

    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              caps.bassMin.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: Slider(
                value: sliderValue,
                min: caps.bassMin.toDouble(),
                max: caps.bassMax.toDouble(),
                label: sliderValue.round().toString(),
                onChanged: (value) => setState(() => _pendingBass = value),
                onChangeEnd: _onBassChangeEnd,
              ),
            ),
            Text(
              caps.bassMax.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: busy ? null : () => _adjustBass(-1),
              icon: const Icon(Icons.remove),
              label: const Text('Down'),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 60,
              child: Center(
                child: Text(
                  sliderValue.round().toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: busy ? null : () => _adjustBass(1),
              icon: const Icon(Icons.add),
              label: const Text('Up'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: busy ? null : _resetBass,
          icon: const Icon(Icons.restart_alt),
          label: Text('Reset to default (${caps.bassDefault})'),
        ),
      ],
    );
  }

  Widget _buildClockCard(ThemeData theme) {
    final config = _clockConfig;
    final busy = _applyingClock || _pendingBrightness != null;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Clock Display',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!_loadingClock && _clockSupported && config != null)
                  Switch(
                    value: config.userEnable,
                    onChanged: busy
                        ? null
                        : (value) => _applyClockConfig(
                            config.copyWith(userEnable: value),
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildClockContent(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildClockContent(ThemeData theme) {
    if (_loadingClock) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_clockError != null) {
      return Column(
        children: [
          SelectableText(
            'Error loading clock display: $_clockError',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadClock, child: const Text('Retry')),
        ],
      );
    }

    if (!_clockSupported) {
      return Text(
        'Clock display not supported on this device',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final config = _clockConfig;
    if (config == null) return const SizedBox.shrink();

    final busy = _applyingClock || _pendingBrightness != null;
    final brightness = (_pendingBrightness ?? config.brightnessLevel).clamp(
      0,
      100,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Time format', style: theme.textTheme.bodyMedium),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: busy || !config.is24Hour
                  ? null
                  : () => _applyClockConfig(
                      config.copyWith(timeFormat: ClockConfig.format12h),
                    ),
              style: OutlinedButton.styleFrom(
                backgroundColor: !config.is24Hour
                    ? theme.colorScheme.primaryContainer
                    : null,
              ),
              child: const Text('12h'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: busy || config.is24Hour
                  ? null
                  : () => _applyClockConfig(
                      config.copyWith(timeFormat: ClockConfig.format24h),
                    ),
              style: OutlinedButton.styleFrom(
                backgroundColor: config.is24Hour
                    ? theme.colorScheme.primaryContainer
                    : null,
              ),
              child: const Text('24h'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Time zone', style: theme.textTheme.bodyMedium),
            const SizedBox(width: 16),
            Text(
              config.timezoneInfo.isNotEmpty ? config.timezoneInfo : '—',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Brightness', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: busy || brightness <= 0
                  ? null
                  : () {
                      final next = (brightness - 1).clamp(0, 100);
                      setState(() => _pendingBrightness = next);
                      _applyClockConfig(config.copyWith(brightnessLevel: next));
                    },
              icon: const Icon(Icons.remove),
              label: const Text('Down'),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 60,
              child: Center(
                child: Text(
                  '$brightness%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: busy || brightness >= 100
                  ? null
                  : () {
                      final next = (brightness + 1).clamp(0, 100);
                      setState(() => _pendingBrightness = next);
                      _applyClockConfig(config.copyWith(brightnessLevel: next));
                    },
              icon: const Icon(Icons.add),
              label: const Text('Up'),
            ),
          ],
        ),
      ],
    );
  }
}

class _LanguagePickerDialog extends StatefulWidget {
  final SpeakerLanguage? initial;

  const _LanguagePickerDialog({this.initial});

  @override
  State<_LanguagePickerDialog> createState() => _LanguagePickerDialogState();
}

class _LanguagePickerDialogState extends State<_LanguagePickerDialog> {
  late SpeakerLanguage? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Language'),
      content: SizedBox(
        width: double.maxFinite,
        child: DropdownButtonFormField<SpeakerLanguage>(
          initialValue: _selected,
          decoration: const InputDecoration(labelText: 'Language'),
          items: SpeakerLanguage.values
              .map(
                (lang) => DropdownMenuItem(
                  value: lang,
                  child: Text(lang.displayName),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selected = value),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
