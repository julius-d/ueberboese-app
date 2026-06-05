import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/speaker_info.dart';
import 'package:ueberboese_app/pages/configuration_page.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/speaker_setup_service.dart';
import 'package:ueberboese_app/widgets/async_filled_button.dart';
import 'package:ueberboese_app/widgets/envswitch_log_view.dart';

/// Config keys that will be reconfigured by the "Connect to Überböse-API"
/// button. Rows with these keys are highlighted when their value doesn't match
/// the expected URL.
const _reconfiguredKeys = {
  'bmxRegistryUrl',
  'statsServerUrl',
  'margeServerUrl',
  'swUpdateUrl',
};

class SpeakerDoctorPage extends StatefulWidget {
  final Speaker speaker;
  final SpeakerSetupService? setupService;
  final SpeakerApiService? apiService;

  const SpeakerDoctorPage({
    super.key,
    required this.speaker,
    this.setupService,
    this.apiService,
  });

  @override
  State<SpeakerDoctorPage> createState() => _SpeakerDoctorPageState();
}

class _SpeakerDoctorPageState extends State<SpeakerDoctorPage> {
  late final SpeakerSetupService _service;
  late final SpeakerApiService _apiService;

  bool _loading = true;
  String? _error;
  Map<String, String>? _config;
  List<String>? _envswitchLog;

  bool _isRebooting = false;

  bool _infoLoading = true;
  String? _infoError;
  SpeakerInfo? _info;

  final _accountIdController = TextEditingController();
  final _authTokenController = TextEditingController();
  String? _margeAccountError;
  bool _isLinkingAccount = false;

  @override
  void initState() {
    super.initState();
    _service = widget.setupService ??
        SpeakerSetupService(envswitchDelay: Duration.zero);
    _apiService = widget.apiService ?? SpeakerApiService();
    _loadConfig();
    _loadInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_accountIdController.text.isEmpty) {
      _accountIdController.text =
          context.read<MyAppState>().config.accountId;
    }
    if (_authTokenController.text.isEmpty) {
      _authTokenController.text = 'auth123';
    }
  }

  @override
  void dispose() {
    _accountIdController.dispose();
    _authTokenController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw =
          await _service.getSystemConfiguration(widget.speaker.ipAddress);
      if (!mounted) return;
      setState(() {
        _config = SpeakerSetupService.parseSystemConfiguration(raw);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadInfo() async {
    setState(() {
      _infoLoading = true;
      _infoError = null;
    });
    try {
      final info = await _apiService.fetchSpeakerInfo(widget.speaker.ipAddress);
      if (!mounted) return;
      setState(() {
        _info = info;
        _infoLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _infoError = e.toString();
        _infoLoading = false;
      });
    }
  }

  Future<void> _onConnectToUeberboese() async {
    final apiUrl = context.read<MyAppState>().config.apiUrl;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Configuring speaker…'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final log = await _service.configureEnvswitch(
        apiUrl,
        speakerIp: widget.speaker.ipAddress,
      );
      if (!mounted) return;
      Navigator.pop(context);
      setState(() => _envswitchLog = log);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Configuration failed'),
          content: Text(e.toString()),
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

  Future<void> _onReboot() async {
    setState(() => _isRebooting = true);

    try {
      await _service.rebootSpeaker(widget.speaker.ipAddress);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speaker is rebooting…')),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reboot failed'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isRebooting = false);
    }
  }

  Future<void> _onMargeAccountConfirm() async {
    final accountId = _accountIdController.text.trim();
    final authToken = _authTokenController.text.trim();
    if (accountId.isEmpty || authToken.isEmpty) {
      setState(
          () => _margeAccountError = 'Account ID and auth token are required.');
      return;
    }
    if (accountId.length < 3) {
      setState(() =>
          _margeAccountError = 'Account ID must be at least 3 characters.');
      return;
    }
    setState(() {
      _margeAccountError = null;
      _isLinkingAccount = true;
    });
    try {
      await _service.setMargeAccount(
          widget.speaker.ipAddress, accountId, authToken);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marge account linked successfully.')),
      );
      _loadInfo();
    } catch (e) {
      if (!mounted) return;
      setState(() => _margeAccountError = e.toString());
    } finally {
      if (mounted) setState(() => _isLinkingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apiUrl = context.watch<MyAppState>().config.apiUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor — ${widget.speaker.name}'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConfigCard(theme, apiUrl),
            const SizedBox(height: 16),
            _buildConnectCard(context, theme, apiUrl),
            const SizedBox(height: 16),
            _buildInfoCard(theme),
            const SizedBox(height: 16),
            _buildMargeAccountCard(theme),
            const SizedBox(height: 16),
            _buildRebootCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Device Info', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildInfoContent(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContent(ThemeData theme) {
    if (_infoLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_infoError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Failed to load device info:',
              style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 4),
          Text(_infoError!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loadInfo,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }
    if (_info == null) {
      return const Text('No device info returned.');
    }

    final rows = [
      ('Device ID', _info!.deviceId),
      ('Type', _info!.type),
      ('Marge Account ID', _info!.accountId ?? '—'),
    ];

    final accountIdEmpty =
        _info!.accountId == null || _info!.accountId!.isEmpty;

    return Table(
      border: TableBorder.all(
        color: theme.colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: rows.map((row) {
        final isAccountIdRow = row.$1 == 'Marge Account ID';
        final warn = isAccountIdRow && accountIdEmpty;
        final decoration = warn
            ? BoxDecoration(color: theme.colorScheme.errorContainer)
            : null;
        return TableRow(
          decoration: decoration,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: SelectableText(
                row.$1,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: warn ? theme.colorScheme.onErrorContainer : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: warn
                  ? Row(
                      children: [
                        Icon(
                          Icons.warning,
                          size: 14,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 4),
                        SelectableText(
                          row.$2,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    )
                  : SelectableText(row.$2, style: theme.textTheme.bodySmall),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildConfigCard(ThemeData theme, String apiUrl) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('System Configuration', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildConfigContent(theme, apiUrl),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigContent(ThemeData theme, String apiUrl) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Failed to load configuration:',
              style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 4),
          Text(_error!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loadConfig,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }
    if (_config == null || _config!.isEmpty) {
      return const Text('No configuration data returned.');
    }

    final updatesUrl = apiUrl.isNotEmpty ? '$apiUrl/updates/soundtouch' : null;
    final expectedValues = apiUrl.isNotEmpty
        ? {
            'bmxRegistryUrl': '$apiUrl/bmx/registry/v1/services',
            'statsServerUrl': apiUrl,
            'margeServerUrl': apiUrl,
            'swUpdateUrl': updatesUrl!,
          }
        : <String, String>{};

    return Table(
      border: TableBorder.all(
        color: theme.colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: _config!.entries.map((entry) {
        final isReconfigured = _reconfiguredKeys.contains(entry.key);
        final expected = expectedValues[entry.key];
        final isWrong = isReconfigured &&
            expected != null &&
            entry.value != expected;
        final rowColor = isWrong ? theme.colorScheme.errorContainer : null;

        return TableRow(
          decoration: rowColor != null ? BoxDecoration(color: rowColor) : null,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: SelectableText(
                entry.key,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isWrong ? theme.colorScheme.onErrorContainer : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: SelectableText(
                entry.value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isWrong ? theme.colorScheme.onErrorContainer : null,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildConnectCard(
      BuildContext context, ThemeData theme, String apiUrl) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Connect to Überböse-API', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (apiUrl.isEmpty) ...[
                          Text(
                            'No API URL configured.',
                            style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor:
                                  theme.colorScheme.onErrorContainer,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (context) =>
                                      const ConfigurationPage()),
                            ),
                            child: const Text('Open Settings to configure it'),
                          ),
                        ] else ...[
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontSize: 13),
                              children: [
                                const TextSpan(text: 'Target API: '),
                                TextSpan(
                                  text: apiUrl,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Wrong URL? Change it in Settings first.',
                            style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Overwrites all server URLs on the speaker and triggers a reboot.',
                            style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: apiUrl.isNotEmpty ? _onConnectToUeberboese : null,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('Connect speaker to Überböse-API'),
            ),
            if (_envswitchLog != null) ...[
              const SizedBox(height: 16),
              EnvswitchLogView(log: _envswitchLog!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMargeAccountCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Link Marge Account', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _accountIdController,
              decoration: const InputDecoration(
                labelText: 'Marge Account ID',
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                LengthLimitingTextInputFormatter(42),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _authTokenController,
              decoration: const InputDecoration(
                labelText: 'Auth Token',
                border: OutlineInputBorder(),
              ),
            ),
            if (_margeAccountError != null) ...[
              const SizedBox(height: 8),
              Text(
                _margeAccountError!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            AsyncFilledButton(
              onPressed: _onMargeAccountConfirm,
              isLoading: _isLinkingAccount,
              icon: const Icon(Icons.link),
              label: const Text('Link Account'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRebootCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Reboot', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            AsyncFilledButton(
              onPressed: _onReboot,
              isLoading: _isRebooting,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reboot speaker'),
            ),
          ],
        ),
      ),
    );
  }
}
