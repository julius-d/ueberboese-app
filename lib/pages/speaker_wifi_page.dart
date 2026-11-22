import 'package:flutter/material.dart';
import 'package:ueberboese_app/models/network_stats.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/wireless_network.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/speaker_setup_service.dart';
import 'package:ueberboese_app/widgets/wifi_password_dialog.dart';

/// Security types accepted by the speaker's addWirelessProfile service.
const Map<String, String> kWifiSecurityTypes = {
  'wpa_or_wpa2': 'WPA/WPA2 (recommended)',
  'wpa2aes': 'WPA2/AES',
  'wpa2tkip': 'WPA2/TKIP',
  'wpaaes': 'WPA/AES',
  'wpatkip': 'WPA/TKIP',
  'wep': 'WEP',
  'none': 'None',
};

class SpeakerWifiPage extends StatefulWidget {
  final Speaker speaker;
  final SpeakerApiService? apiService;
  final SpeakerSetupService? setupService;

  const SpeakerWifiPage({
    super.key,
    required this.speaker,
    this.apiService,
    this.setupService,
  });

  @override
  State<SpeakerWifiPage> createState() => _SpeakerWifiPageState();
}

class _SpeakerWifiPageState extends State<SpeakerWifiPage> {
  late final SpeakerApiService _apiService;
  late final SpeakerSetupService _setupService;

  NetworkStats? _stats;
  bool _loadingStats = true;
  String? _statsError;

  List<WirelessNetwork>? _networks;
  bool _scanning = false;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? SpeakerApiService();
    _setupService = widget.setupService ?? SpeakerSetupService();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loadingStats = true;
      _statsError = null;
    });
    try {
      final stats = await _apiService.getNetworkStats(widget.speaker.ipAddress);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statsError = e.toString();
        _loadingStats = false;
      });
    }
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _scanError = null;
    });
    try {
      final networks = await _setupService.performWirelessSiteSurvey(
        speakerIp: widget.speaker.ipAddress,
      );
      if (!mounted) return;
      setState(() {
        _networks = networks;
        _scanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanError = e.toString();
        _scanning = false;
      });
    }
  }

  Future<void> _onNetworkTap(WirelessNetwork network) async {
    var password = '';
    if (network.secure) {
      final entered = await showWifiPasswordDialog(context, network.ssid);
      if (entered == null) return;
      password = entered;
    }
    if (!mounted) return;
    await _connect(network.ssid, password, network.securityType);
  }

  Future<void> _onManualNetwork() async {
    final result = await showDialog<_ManualNetwork>(
      context: context,
      builder: (context) => const _ManualNetworkDialog(),
    );
    if (result == null || !mounted) return;
    await _connect(result.ssid, result.password, result.securityType);
  }

  Future<void> _connect(
      String ssid, String password, String securityType) async {
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
                Text('Saving Wi-Fi profile…'),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      await _setupService.addWirelessProfile(
        ssid,
        password,
        securityType,
        speakerIp: widget.speaker.ipAddress,
      );
      if (!mounted) return;
      Navigator.pop(context);
      await _showInfoDialog(
        'Wi-Fi profile saved',
        'The profile for "$ssid" was saved on the speaker. The speaker '
            'connects to the first known network it can reach, so it may '
            'stay on its current network. If it switches networks, its IP '
            'address may change and you may need to discover it again or '
            'edit its IP address.',
      );
      if (mounted) _loadStats();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      await _showInfoDialog('Failed to configure Wi-Fi', e.toString());
    }
  }

  Future<void> _showInfoDialog(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadingStats ? null : _loadStats,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCurrentNetworkCard(context),
          const SizedBox(height: 24),
          _buildAvailableNetworks(context),
        ],
      ),
    );
  }

  Widget _buildCurrentNetworkCard(BuildContext context) {
    final theme = Theme.of(context);
    final Widget content;
    if (_loadingStats) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_statsError != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Failed to load network information: $_statsError',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadStats, child: const Text('Retry')),
        ],
      );
    } else {
      final stats = _stats!;
      final rows = <MapEntry<String, String?>>[
        if (stats.isWireless) MapEntry('Signal', stats.rssi),
        if (stats.isWireless) MapEntry('Band', stats.band),
        MapEntry('IP address', stats.ipAddress),
        MapEntry('MAC address', stats.macAddress),
      ].where((e) => e.value != null).toList();
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(stats.isWireless ? Icons.wifi : Icons.settings_ethernet),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stats.isWireless
                      ? (stats.ssid ?? 'Unknown network')
                      : 'Connected via Ethernet',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(row.key, style: theme.textTheme.bodySmall),
                  ),
                  Expanded(child: Text(row.value!)),
                ],
              ),
            ),
        ],
      );
    }
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current network', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableNetworks(BuildContext context) {
    final theme = Theme.of(context);
    final networks = _networks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Available networks', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _scanning ? null : _scan,
              icon: const Icon(Icons.search),
              label: const Text('Scan for networks'),
            ),
            OutlinedButton.icon(
              onPressed: _onManualNetwork,
              icon: const Icon(Icons.edit),
              label: const Text('Manual network…'),
            ),
          ],
        ),
        if (_scanning)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_scanError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Scan failed: $_scanError',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        if (networks != null && !_scanning)
          if (networks.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('No networks found.'),
            )
          else
            for (final network in networks)
              ListTile(
                leading: Icon(_signalIcon(network.signalStrength)),
                title: Text(network.ssid),
                subtitle: network.ssid == _stats?.ssid
                    ? const Text('Connected')
                    : null,
                trailing: network.secure ? const Icon(Icons.lock) : null,
                onTap: () => _onNetworkTap(network),
              ),
      ],
    );
  }

  IconData _signalIcon(int dbm) {
    if (dbm >= -60) return Icons.signal_wifi_4_bar;
    if (dbm >= -70) return Icons.network_wifi_3_bar;
    if (dbm >= -80) return Icons.network_wifi_2_bar;
    return Icons.network_wifi_1_bar;
  }
}

class _ManualNetwork {
  final String ssid;
  final String password;
  final String securityType;

  const _ManualNetwork(this.ssid, this.password, this.securityType);
}

class _ManualNetworkDialog extends StatefulWidget {
  const _ManualNetworkDialog();

  @override
  State<_ManualNetworkDialog> createState() => _ManualNetworkDialogState();
}

class _ManualNetworkDialogState extends State<_ManualNetworkDialog> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  String _securityType = 'wpa_or_wpa2';
  bool _obscure = true;

  bool get _isOpen => _securityType == 'none';

  bool get _valid =>
      _ssidController.text.trim().isNotEmpty &&
      (_isOpen || _passwordController.text.isNotEmpty);

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manual network'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ssidController,
              decoration: const InputDecoration(labelText: 'SSID'),
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _securityType,
              decoration: const InputDecoration(labelText: 'Security'),
              items: [
                for (final entry in kWifiSecurityTypes.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) =>
                  setState(() => _securityType = value ?? _securityType),
            ),
            if (!_isOpen) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _valid
              ? () => Navigator.pop(
                    context,
                    _ManualNetwork(
                      _ssidController.text.trim(),
                      _isOpen ? '' : _passwordController.text,
                      _securityType,
                    ),
                  )
              : null,
          child: const Text('Connect'),
        ),
      ],
    );
  }
}
