import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/spotify_api_service.dart';
import '../models/spotify_account.dart';

class SpotifyAccountsPage extends StatefulWidget {
  final SpotifyApiService? apiService;

  const SpotifyAccountsPage({super.key, this.apiService});

  @override
  State<SpotifyAccountsPage> createState() => _SpotifyAccountsPageState();
}

class _SpotifyAccountsPageState extends State<SpotifyAccountsPage> {
  late final SpotifyApiService _apiService;
  bool _isLoading = false;
  bool _isLoadingAccounts = false;
  List<SpotifyAccount> _accounts = [];
  late AppLinks _appLinks;
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? SpotifyApiService();
    _initDeepLinkListener();
    _loadAccounts();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinkListener() async {
    _appLinks = AppLinks();

    try {
      // Listen to all incoming links
      _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
        _handleIncomingLink(uri);
      }, onError: (err) {
        print('Error listening to deep links: $err');
      });

      // Note: We intentionally don't check getInitialLink() here to avoid
      // processing stale auth codes when navigating back to this page.
      // The uriLinkStream listener above handles all deep link redirects.
    } catch (e) {
      print('Error initializing deep link listener: $e');
    }
  }

  void _handleIncomingLink(Uri uri) {
    if (uri.scheme == 'ueberboese-login' && uri.host == 'spotify') {
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        _confirmSpotifyAuth(code);
      }
    }
  }

  Future<void> _loadAccounts() async {
    final appState = context.read<MyAppState>();
    final apiUrl = appState.config.apiUrl;

    if (apiUrl.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingAccounts = true;
    });

    try {
      final accounts = await _apiService.listSpotifyAccounts(apiUrl);

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        _isLoadingAccounts = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingAccounts = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load Spotify accounts: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _onAddSpotifyAccount() async {
    final appState = context.read<MyAppState>();
    final apiUrl = appState.config.apiUrl;

    if (apiUrl.isEmpty) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Configuration Required'),
          content: const Text(
            'Überböse API URL is not configured.\n\n'
            'Please configure it in Settings first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final redirectUrl = await _apiService.initSpotifyAuth(apiUrl);

      if (!mounted) return;

      final uri = Uri.parse(redirectUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Failed to launch browser');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(
            'Failed to initialize Spotify authentication.\n\n${e.toString()}',
          ),
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

  Future<void> _confirmSpotifyAuth(String code) async {
    final appState = context.read<MyAppState>();
    final apiUrl = appState.config.apiUrl;

    if (apiUrl.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.confirmSpotifyAuth(apiUrl, code);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spotify account connected successfully!'),
          duration: Duration(seconds: 3),
        ),
      );

      // Refresh the accounts list
      await _loadAccounts();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(
            'Failed to confirm Spotify authentication.\n\n${e.toString()}',
          ),
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

  void _cancelLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  String _formatAccountDate(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    String relativeTime;
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      relativeTime = '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      relativeTime = '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      relativeTime = '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      relativeTime = '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      relativeTime = '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      relativeTime = 'just now';
    }

    final dateFormat = DateFormat('MMM d, y');
    final formattedDate = dateFormat.format(createdAt);

    return 'Connected $relativeTime ($formattedDate)';
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoadingAccounts) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_accounts.isEmpty) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Spotify Accounts',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'No Spotify accounts connected yet.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    } else {
      content = ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _accounts.length,
        itemBuilder: (context, index) {
          final account = _accounts[index];
          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: ListTile(
              leading: Icon(
                Icons.music_note,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                account.displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                _formatAccountDate(account.createdAt),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          content,
          if (_isLoading)
            Container(
              color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.6),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const Text('Connecting to Spotify...'),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _cancelLoading,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _onAddSpotifyAccount,
        child: const Icon(Icons.add),
      ),
    );
  }
}
