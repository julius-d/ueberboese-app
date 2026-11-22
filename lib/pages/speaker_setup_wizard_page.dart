import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/wireless_network.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/speaker_setup_service.dart';
import 'package:ueberboese_app/widgets/envswitch_log_view.dart';
import 'package:ueberboese_app/widgets/wifi_password_dialog.dart';

class SpeakerSetupWizardPage extends StatefulWidget {
  final SpeakerSetupService? setupService;
  final SpeakerApiService? apiService;

  const SpeakerSetupWizardPage({super.key, this.setupService, this.apiService});

  @override
  State<SpeakerSetupWizardPage> createState() => _SpeakerSetupWizardPageState();
}

class _SpeakerSetupWizardPageState extends State<SpeakerSetupWizardPage> {
  late final SpeakerSetupService _setupService;
  late final SpeakerApiService _apiService;

  int _currentStep = 0;

  // Step 1: AP connection check state
  bool _checkingConnection = false;
  String? _connectionError;

  // Step 2: Wi-Fi selection state
  List<WirelessNetwork>? _networks;
  bool _loadingNetworks = false;
  String? _networkError;

  // Step 3: envswitch log
  List<String> _envswitchLog = [];
  bool _envswitchDone = false;

  // Step 4: Marge account state
  final _accountIdController = TextEditingController();
  final _authTokenController = TextEditingController(text: 'auth1234');
  bool _pairingInProgress = false;
  String? _pairingError;

  // Step 5: Rename device state
  final _deviceNameController = TextEditingController();
  bool _loadingDeviceName = false;
  bool _savingDeviceName = false;
  String? _deviceNameError;

  @override
  void initState() {
    super.initState();
    _setupService = widget.setupService ?? SpeakerSetupService();
    _apiService = widget.apiService ?? SpeakerApiService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill account ID from config (only once, when controller is empty).
    if (_accountIdController.text.isEmpty) {
      final config = context.read<MyAppState>().config;
      _accountIdController.text = config.accountId;
    }
  }

  @override
  void dispose() {
    _accountIdController.dispose();
    _authTokenController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
      if (step == 1) {
        _checkingConnection = false;
        _connectionError = null;
      }
      if (step == 2) {
        _loadNetworks();
      }
      if (step == 5) {
        _loadDeviceName();
      }
    });
  }

  Future<void> _checkConnectionAndContinue() async {
    setState(() {
      _checkingConnection = true;
      _connectionError = null;
    });
    try {
      await _apiService.fetchSpeakerInfo(kSetupSpeakerIp);
      if (!mounted) return;
      _goToStep(2);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkingConnection = false;
        _connectionError =
            'Could not reach the speaker. Make sure you are connected '
            'to the Bose Wi-Fi network and try again.';
      });
    }
  }

  Future<void> _loadNetworks() async {
    setState(() {
      _loadingNetworks = true;
      _networkError = null;
      _networks = null;
    });
    try {
      final networks = await _setupService.performWirelessSiteSurvey();
      if (!mounted) return;
      setState(() {
        _networks = networks;
        _loadingNetworks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _networkError = e.toString();
        _loadingNetworks = false;
      });
    }
  }

  Future<void> _onNetworkSelected(WirelessNetwork network) async {
    String password = '';
    if (network.secure) {
      final entered = await showWifiPasswordDialog(context, network.ssid);
      if (entered == null) return; // cancelled
      password = entered;
    }

    if (!mounted) return;

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
                Text('Configuring Wi-Fi…'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await _setupService.addWirelessProfile(
        network.ssid,
        password,
        network.securityType,
      );
      if (!mounted) return;
      Navigator.pop(context); // close loading
      _goToStep(3);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      _showErrorDialog('Failed to configure Wi-Fi', e.toString());
    }
  }

  Future<void> _onEnvswitchConfirm() async {
    final apiUrl = context.read<MyAppState>().config.apiUrl;
    if (apiUrl.isEmpty) {
      _showErrorDialog(
        'API URL not configured',
        'Please configure the Überböse API URL in Settings first.',
      );
      return;
    }

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
                Text('Configuring server URL…'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final log = await _setupService.configureEnvswitch(apiUrl);
      if (!mounted) return;
      Navigator.pop(context);
      setState(() {
        _envswitchLog = log;
        _envswitchDone = true;
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorDialog('Failed to configure server URL', e.toString());
    }
  }

  Future<void> _onMargeAccountConfirm() async {
    final accountId = _accountIdController.text.trim();
    final authToken = _authTokenController.text.trim();

    if (accountId.isEmpty) {
      setState(() => _pairingError = 'Please enter your account ID.');
      return;
    }
    if (authToken.isEmpty) {
      setState(() => _pairingError = 'Please enter the auth token.');
      return;
    }

    setState(() {
      _pairingInProgress = true;
      _pairingError = null;
    });

    try {
      await _setupService.setMargeAccount(
        kSetupSpeakerIp,
        accountId,
        authToken,
      );
      if (!mounted) return;
      setState(() => _pairingInProgress = false);
      _goToStep(5);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pairingInProgress = false;
        _pairingError = e.toString();
      });
    }
  }

  Future<void> _leaveSetupMode() async {
    try {
      await _setupService.leaveSetupMode();
    } catch (_) {
      // Non-fatal: the AP may already be gone if the speaker switched networks.
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SelectableText(message),
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
      appBar: AppBar(title: const Text('Set Up New Speaker')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildStep(_currentStep),
      ),
    );
  }

  Widget _buildStep(int step) {
    return KeyedSubtree(
      key: ValueKey(step),
      child: switch (step) {
        0 => _buildFactoryResetStep(),
        1 => _buildConnectToApStep(),
        2 => _buildWifiSelectionStep(),
        3 => _buildEnvswitchStep(),
        4 => _buildMargeAccountStep(),
        5 => _buildRenameStep(),
        6 => _buildFinishStep(),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildStepScaffold({
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFactoryResetStep() {
    return _buildStepScaffold(
      title: 'Step 1: Factory Reset Your Speaker',
      description:
          'Before starting, factory-reset your speaker. On most Bose SoundTouch '
          'devices, press and hold the Power button and Volume Down button '
          'simultaneously for about 10 seconds until the speaker resets.',
      children: [
        const SizedBox(height: 8),
        FilledButton(onPressed: () => _goToStep(1), child: const Text('Next')),
      ],
    );
  }

  Widget _buildConnectToApStep() {
    return _buildStepScaffold(
      title: 'Step 2: Connect to Speaker Wi-Fi',
      description:
          'Your speaker has created a temporary Wi-Fi access point. '
          'Go to your phone\'s Wi-Fi settings and connect to the network '
          'named "Bose…" (it may include part of the device serial number).\n\n'
          'Once connected, tap Continue.',
      children: [
        if (_connectionError != null) ...[
          Text(
            _connectionError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
        ],
        if (_checkingConnection)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton(
            onPressed: _checkConnectionAndContinue,
            child: Text(_connectionError != null ? 'Retry' : 'Continue'),
          ),
      ],
    );
  }

  Widget _buildWifiSelectionStep() {
    Widget body;

    if (_loadingNetworks) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Scanning for Wi-Fi networks…'),
            ],
          ),
        ),
      );
    } else if (_networkError != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Failed to scan networks:\n$_networkError',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _loadNetworks, child: const Text('Retry')),
        ],
      );
    } else if (_networks == null || _networks!.isEmpty) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('No networks found.'),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _loadNetworks, child: const Text('Retry')),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._networks!.map(
            (n) => Card(
              child: ListTile(
                leading: Icon(_signalIcon(n.signalStrength)),
                title: Text(n.ssid),
                subtitle: Text(_securityLabel(n)),
                trailing: n.secure ? const Icon(Icons.lock, size: 16) : null,
                onTap: () => _onNetworkSelected(n),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _loadNetworks,
            child: const Text('Refresh'),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Step 3: Select Wi-Fi Network',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Select the Wi-Fi network your speaker should connect to.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          body,
        ],
      ),
    );
  }

  String _securityLabel(WirelessNetwork network) {
    if (!network.secure) return 'Insecure';
    return switch (network.securityType) {
      'none' => 'Insecure',
      'wep' => 'WEP',
      'wpatkip' => 'WPA/TKIP',
      'wpaaes' => 'WPA/AES',
      'wpa2tkip' => 'WPA2/TKIP',
      'wpa2aes' => 'WPA2/AES',
      'wpa_or_wpa2' => 'WPA/WPA2',
      _ => network.securityType,
    };
  }

  IconData _signalIcon(int strength) {
    if (strength >= -55) return Icons.signal_wifi_4_bar;
    if (strength >= -70) return Icons.network_wifi_3_bar;
    if (strength >= -80) return Icons.network_wifi_2_bar;
    return Icons.network_wifi_1_bar;
  }

  Widget _buildEnvswitchStep() {
    final apiUrl = context.read<MyAppState>().config.apiUrl;
    return _buildStepScaffold(
      title: 'Step 4: Connect to your Überböse Server',
      description:
          'This step configures your speaker to communicate with your '
          'Überböse server${apiUrl.isNotEmpty ? ' at:\n$apiUrl\n\n' : '.'}'
          'The speaker is configured using the envswitch command.\n\n'
          'You can skip this step if you don\'t want to use your Überböse server now.',
      children: [
        if (_envswitchLog.isNotEmpty) ...[
          EnvswitchLogView(log: _envswitchLog),
          const SizedBox(height: 16),
        ],
        if (!_envswitchDone) ...[
          FilledButton(
            onPressed: apiUrl.isNotEmpty ? _onEnvswitchConfirm : null,
            child: const Text('Configure Server URL'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _goToStep(4),
            child: const Text('Skip'),
          ),
        ] else ...[
          FilledButton(
            onPressed: () => _goToStep(4),
            child: const Text('Next'),
          ),
        ],
      ],
    );
  }

  Widget _buildMargeAccountStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Step 5: Link Marge Account',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Your phone is still connected to the speaker\'s access point. '
            'Enter your Marge account credentials to pair the speaker.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _accountIdController,
            decoration: const InputDecoration(
              labelText: 'Marge Account ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _authTokenController,
            decoration: const InputDecoration(
              labelText: 'Auth Token',
              border: OutlineInputBorder(),
            ),
          ),
          if (_pairingError != null) ...[
            const SizedBox(height: 12),
            Text(
              _pairingError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          if (_pairingInProgress)
            const Center(child: CircularProgressIndicator())
          else ...[
            FilledButton(
              onPressed: _onMargeAccountConfirm,
              child: const Text('Confirm'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _goToStep(5),
              child: const Text('Skip'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadDeviceName() async {
    setState(() {
      _loadingDeviceName = true;
      _deviceNameError = null;
    });
    try {
      final info = await _apiService.fetchSpeakerInfo(kSetupSpeakerIp);
      if (!mounted) return;
      setState(() {
        _deviceNameController.text = info.name;
        _loadingDeviceName = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deviceNameError = e.toString();
        _loadingDeviceName = false;
      });
    }
  }

  Future<void> _saveDeviceName() async {
    final name = _deviceNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _deviceNameError = 'Please enter a name.');
      return;
    }
    setState(() {
      _savingDeviceName = true;
      _deviceNameError = null;
    });
    try {
      await _apiService.setSpeakerName(kSetupSpeakerIp, name);
      if (!mounted) return;
      setState(() => _savingDeviceName = false);
      _goToStep(6);
      _leaveSetupMode();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingDeviceName = false;
        _deviceNameError = e.toString();
      });
    }
  }

  Widget _buildRenameStep() {
    return _buildStepScaffold(
      title: 'Step 6: Name Your Speaker',
      description: 'Give your speaker a name so you can identify it easily.',
      children: [
        if (_loadingDeviceName)
          const Center(child: CircularProgressIndicator())
        else ...[
          TextField(
            controller: _deviceNameController,
            decoration: InputDecoration(
              labelText: 'Speaker Name',
              border: const OutlineInputBorder(),
              errorText: _deviceNameError,
            ),
            autofocus: true,
            onSubmitted: (_) => _saveDeviceName(),
          ),
          const SizedBox(height: 24),
          if (_savingDeviceName)
            const Center(child: CircularProgressIndicator())
          else ...[
            FilledButton(onPressed: _saveDeviceName, child: const Text('Save')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                _goToStep(6);
                _leaveSetupMode();
              },
              child: const Text('Skip'),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildFinishStep() {
    return _buildStepScaffold(
      title: 'Setup Complete',
      description:
          'Your speaker has been configured. Please reconnect your phone '
          'to your regular Wi-Fi network.\n\n'
          'Restart the speaker by plugging out the power adapter. '
          'After the restart the speaker should appear on your local network.\n\n'
          'You can add it to the app using "Add by IP" or "Discover".',
      children: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
