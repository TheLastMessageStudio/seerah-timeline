import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/event_detail_screen.dart';
import '../features/book_detail_screen.dart';
import '../features/book_reader_screen.dart';
import '../features/pdf_book_screen.dart';
import '../features/release_screen.dart';
import '../features/corpus_reader_screen.dart';
import '../features/paywall_screen.dart';
import '../features/persons_screen.dart';
import '../features/family_tree_screen.dart';
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
          if (e == null) return missing();
          if (!s.canOpenEvent(e)) {
            return s.isWaitingForRelease(e.id)
                ? ReleaseScreen(state: s, eventId: e.id)
                : PaywallScreen(state: s);
          }
          return EventDetailScreen(state: s, event: e);
        },
      ),
      GoRoute(path: '/family-tree', builder: (c, st) => FamilyTreeScreen(state: s)),
      GoRoute(
        path: '/person/:id',
        builder: (c, st) {
          final p = s.repo.person(st.pathParameters['id']!);
          if (p == null) return missing();
          if (!s.canOpenPerson(p)) {
            final related = s.repo.eventsOfPerson(p.id);
            if (related.isNotEmpty && related.every((event) => s.isWaitingForRelease(event.id))) {
              return ReleaseScreen(state: s, eventId: related.first.id);
            }
            return PaywallScreen(state: s);
          }
          return PersonDetailScreen(state: s, person: p);
        },
      ),
      GoRoute(
        path: '/period/:id',
        builder: (c, st) {
          final p = s.repo.period(st.pathParameters['id']!);
          return p == null ? missing() : (s.periodUnlocked(p) ? PeriodScreen(state: s, period: p) : PaywallScreen(state: s));
        },
      ),
      GoRoute(
        path: '/book/:id',
        builder: (c, st) {
          final book = s.repo.book(st.pathParameters['id']!);
          return book == null ? missing() : (s.hasEntitlement('library') ? BookDetailScreen(book: book) : PaywallScreen(state: s));
        },
      ),
      GoRoute(
        path: '/book/:id/read',
        builder: (c, st) {
          final book = s.repo.book(st.pathParameters['id']!);
          return book == null
              ? missing()
              : !s.hasEntitlement('library')
                  ? PaywallScreen(state: s)
                  : BookReaderScreen(
                  state: s,
                  book: book,
                  eventId: st.uri.queryParameters['event'],
                );
        },
      ),
      GoRoute(
        path: '/pdf/:id',
        builder: (c, st) {
          final book = s.repo.book(st.pathParameters['id']!);
          return book == null ? missing() : (s.hasEntitlement('library') ? PdfBookScreen(book: book) : PaywallScreen(state: s));
        },
      ),
      GoRoute(path: '/release', builder: (c, st) => ReleaseScreen(state: s, eventId: st.uri.queryParameters['event'])),
      GoRoute(
        path: '/hadith/:id',
        builder: (c, st) {
          final book = s.repo.book(st.pathParameters['id']!);
          return book == null ? missing() : (s.hasEntitlement('library') ? CorpusReaderScreen(id: book.id, title: book.title) : PaywallScreen(state: s));
        },
      ),
      GoRoute(
        path: '/quran',
        builder: (c, st) => s.hasEntitlement('library') ? CorpusReaderScreen(id: 'quran_ar', title: s.repo.book('quran_ar')?.title ?? 'القرآن الكريم', quran: true) : PaywallScreen(state: s),
      ),
      GoRoute(path: '/settings', builder: (c, st) => SettingsScreen(state: s)),
      GoRoute(path: '/paywall', builder: (c, st) => PaywallScreen(state: s)),
    ],
  );
}
