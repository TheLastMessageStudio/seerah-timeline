import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../core/widgets.dart';
import 'favorites_screen.dart';
import 'book_library_screen.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'persons_screen.dart';
import 'places_screen.dart';
import 'timeline_screen.dart';
import 'nav.dart';

class RootScreen extends StatefulWidget {
  final AppState state;
  const RootScreen({super.key, required this.state});
  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final _scaffold = GlobalKey<ScaffoldState>();
  int tab = 0; // 0 accueil, 1 chronologie, 2 calendrier, 3 bibliothèque, 4 personnes, 5 lieux, 6 favoris

  void _select(int index) {
    setState(() => tab = index);
    _scaffold.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final pages = <Widget>[
      HomeScreen(state: s, onMenu: () => _scaffold.currentState?.openDrawer(), onCalendar: () => setState(() => tab = 2)),
      TimelineScreen(state: s, title: tr('nav_timeline')),
      CalendarScreen(state: s),
      BookLibraryScreen(state: s),
      PersonsScreen(state: s),
      PlacesScreen(state: s),
      FavoritesScreen(state: s),
    ];
    final navIndex = tab <= 2 ? tab : (tab == 3 ? 3 : 0);
    return Scaffold(
      key: _scaffold,
      drawer: Drawer(child: SafeArea(child: Column(children: [
        Container(
          width: double.infinity, height: 176,
          padding: const EdgeInsets.fromLTRB(21, 20, 20, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Theme.of(context).colorScheme.primary, const Color(0xFF092D22)]),
          ),
          child: Stack(children: [
            Positioned(right: -18, top: -24, child: SizedBox(width: 150, height: 150, child: CustomPaint(painter: StarPainter(const Color(0x55E7CE98))))),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
              Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x77D9BC79))),
                  child: const Icon(Icons.auto_stories_rounded, size: 25, color: Color(0xFFE8D3A2))),
                const Spacer(),
                const Text('السيرة النبوية', textDirection: TextDirection.rtl, style: TextStyle(color: Color(0xFFE8D3A2), fontSize: 18, fontFamily: 'serif')),
              ]),
              const SizedBox(height: 13),
              Text(tr('app_name'), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(tr('app_tagline'), maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(.82), height: 1.35)),
            ]),
          ]),
        ),
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(10, 12, 10, 12), children: [
          _sectionLabel(Strings.lang == 'ar' ? 'اكتشف' : (Strings.lang == 'en' ? 'DISCOVER' : 'DÉCOUVRIR'), context),
          _item(Icons.home_outlined, tr('nav_home'), () => _select(0), selected: tab == 0),
          _item(Icons.timeline_rounded, tr('nav_timeline'), () => _select(1), selected: tab == 1),
          _item(Icons.calendar_month_outlined, tr('nav_calendar'), () => _select(2), selected: tab == 2),
          _item(Icons.menu_book_rounded, tr('nav_books'), () => _select(3), selected: tab == 3),
          const SizedBox(height: 12),
          _sectionLabel(Strings.lang == 'ar' ? 'استكشف المزيد' : (Strings.lang == 'en' ? 'EXPLORE MORE' : 'APPROFONDIR'), context),
          _item(Icons.people_alt_outlined, tr('nav_people'), () => _select(4), selected: tab == 4),
          _item(Icons.map_outlined, tr('nav_places'), () => _select(5), selected: tab == 5),
          _item(Icons.bookmark_outline_rounded, tr('nav_favorites'), () => _select(6), selected: tab == 6),
          _item(Icons.account_tree_outlined, tr('family_tree'), () { _scaffold.currentState?.closeDrawer(); openFamilyTree(context); }),
          const SizedBox(height: 12),
          _sectionLabel(Strings.lang == 'ar' ? 'الإعدادات' : (Strings.lang == 'en' ? 'PREFERENCES' : 'PRÉFÉRENCES'), context),
          _item(Icons.settings_outlined, tr('settings'), () { _scaffold.currentState?.closeDrawer(); openSettings(context); }),
        ])),
        if (!s.isPremium) Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, const Color(0xFF0A3023)]), borderRadius: BorderRadius.circular(16)),
            child: ListTile(leading: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFE8D3A2)), title: Text(tr('unlock_all'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), trailing: const Icon(Icons.chevron_right, color: Color(0xFFE8D3A2)), onTap: () { _scaffold.currentState?.closeDrawer(); openPaywall(context, s); }),
          ),
        ),
      ]))),
      body: SafeArea(child: IndexedStack(index: tab, children: pages)),
      bottomNavigationBar: NavigationBar(selectedIndex: navIndex, onDestinationSelected: (i) => setState(() => tab = i), destinations: [
        NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: tr('nav_home')),
        NavigationDestination(icon: const Icon(Icons.timeline), label: tr('nav_timeline')),
        NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month), label: tr('nav_calendar')),
        NavigationDestination(icon: const Icon(Icons.menu_book_outlined), selectedIcon: const Icon(Icons.menu_book), label: tr('nav_books')),
      ]),
    );
  }

  Widget _sectionLabel(String title, BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 7, 14, 5),
    child: Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.secondary)),
  );

  Widget _item(IconData icon, String title, VoidCallback onTap, {bool selected = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: ListTile(leading: Icon(icon), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), selected: selected, onTap: onTap),
  );
}
