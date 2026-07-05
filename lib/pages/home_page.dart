import 'package:flutter/material.dart';
import 'package:ueberboese_app/pages/speaker_list_page.dart';
import 'package:ueberboese_app/pages/spotify_accounts_page.dart';
import 'package:ueberboese_app/pages/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const SpeakerListPage();
      case 1:
        page = const SpotifyAccountsPage();
      case 2:
        page = const SettingsPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    final mainArea = Material(
      elevation: 0,
      color: colorScheme.surface,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: page,
      ),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 450) {
            // Use a more mobile-friendly layout with BottomNavigationBar
            // on narrow screens.
            return Column(
              children: [
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    child: mainArea,
                  ),
                ),
                BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: colorScheme.primary,
                  unselectedItemColor: colorScheme.onSurfaceVariant,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.speaker),
                      label: 'Speakers',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.music_note),
                      label: 'Spotify',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                  currentIndex: selectedIndex,
                  onTap: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                )
              ],
            );
          } else {
            return Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: constraints.maxWidth >= 600,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.speaker),
                        label: Text('Speakers'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.music_note),
                        label: Text('Spotify'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings),
                        label: Text('Settings'),
                      ),
                    ],
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: SafeArea(
                    child: mainArea,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
