import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/event_detail_screen.dart';
import '../features/paywall_screen.dart';
import '../features/persons_screen.dart';
import '../features/root_screen.dart';
import '../features/settings_screen.dart';
import '../features/timeline_screen.dart';
import '../state/app_state.dart';

GoRouter buildRouter(AppState s) {
  Widget missing() => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(tr('not_found'))),
      );

  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (c, st) => ListenableBuilder(
          listenable: s,
          builder: (_, __) => s.ready
              ? RootScreen(state: s)
              : const Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
      ),
      GoRoute(
        path: '/event/:id',
        builder: (c, st) {
          final e = s.repo.event(st.pathParameters['id']!);
          return e == null ? missing() : EventDetailScreen(state: s, event: e);
        },
      ),
      GoRoute(
        path: '/person/:id',
        builder: (c, st) {
          final p = s.repo.person(st.pathParameters['id']!);
          return p == null ? missing() : PersonDetailScreen(state: s, person: p);
        },
      ),
      GoRoute(
        path: '/period/:id',
        builder: (c, st) {
          final p = s.repo.period(st.pathParameters['id']!);
          return p == null ? missing() : PeriodScreen(state: s, period: p);
        },
      ),
      GoRoute(path: '/settings', builder: (c, st) => SettingsScreen(state: s)),
      GoRoute(path: '/paywall', builder: (c, st) => PaywallScreen(state: s)),
    ],
  );
}
