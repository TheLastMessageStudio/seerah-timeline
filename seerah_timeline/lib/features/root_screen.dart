import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'persons_screen.dart';
import 'places_screen.dart';
import 'timeline_screen.dart';

class RootScreen extends StatefulWidget {
  final AppState state;
  const RootScreen({super.key, required this.state});
  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final pages = <Widget>[
      HomeScreen(state: s),
      TimelineScreen(state: s, title: tr('nav_timeline')),
      PersonsScreen(state: s),
      PlacesScreen(state: s),
      FavoritesScreen(state: s),
    ];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: tr('nav_home')),
          NavigationDestination(icon: const Icon(Icons.timeline), label: tr('nav_timeline')),
          NavigationDestination(icon: const Icon(Icons.people_outline), selectedIcon: const Icon(Icons.people), label: tr('nav_people')),
          NavigationDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map), label: tr('nav_places')),
          NavigationDestination(icon: const Icon(Icons.bookmark_border), selectedIcon: const Icon(Icons.bookmark), label: tr('nav_favorites')),
        ],
      ),
    );
  }
}
