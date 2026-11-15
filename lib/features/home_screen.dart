import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'nav.dart';
import 'search_delegate.dart';

class HomeScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback? onMenu;
  final VoidCallback? onCalendar;
  const HomeScreen({super.key, required this.state, this.onMenu, this.onCalendar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final repo = state.repo;
    final last = state.lastEvent;
    final total = repo.events.length;
    final done = state.readCount;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [cs.primary, Color.lerp(cs.primary, const Color(0xFF071F19), .38)!],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [BoxShadow(color: cs.primary.withOpacity(.18), blurRadius: 22, offset: const Offset(0, 10))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.auto_stories_rounded, color: Color(0xFFE8D3A2), size: 27),
              const Spacer(),
              IconButton(tooltip: tr('nav_home'), icon: const Icon(Icons.menu, color: Colors.white), onPressed: onMenu),
              IconButton(tooltip: tr('search'), icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => showSearch(context: context, delegate: AppSearchDelegate(state))),
              IconButton(tooltip: tr('settings'), icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => openSettings(context)),
            ]),
            const SizedBox(height: 18),
            Text(tr('app_name'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white, fontWeight: FontWeight.w800, height: 1.12, letterSpacing: -.35)),
            const SizedBox(height: 9),
            Text(tr('app_tagline'), style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(.88), height: 1.5)),
            const SizedBox(height: 16),
            Container(height: 1, color: const Color(0x66E8D3A2)),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.explore_outlined, color: Color(0xFFE8D3A2), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(
                Strings.lang == 'en' ? 'Explore the life, places and people' : (Strings.lang == 'ar' ? 'اكتشف السيرة وأماكنها وشخصياتها' : 'Explorez les récits, les lieux et les personnages'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFFFFF7E8))),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 22),
        if (last != null) ...[
          Card(
            color: cs.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: Text(tr('resume_reading')),
              subtitle: Text(last.title),
              onTap: () => openEvent(context, state, last),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('overall_progress'), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: total == 0 ? 0 : done / total),
              const SizedBox(height: 6),
              Text(tr('events_read', {'done': done, 'total': total})),
            ]),
          ),
        ),
        if (!state.isPremium)
          Card(
            color: cs.tertiaryContainer,
            child: ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: Text(tr('unlock_all')),
              subtitle: Text(tr('unlock_sub')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openPaywall(context, state),
            ),
          ),
        const SizedBox(height: 8),
        Card(child: ListTile(
          leading: Icon(Icons.hourglass_bottom_rounded, color: cs.primary),
          title: Text(Strings.lang == 'en' ? 'Next release countdown' : (Strings.lang == 'ar' ? 'العد التنازلي للإصدار القادم' : 'Compte à rebours de la prochaine sortie')),
          subtitle: Text(Strings.lang == 'en' ? 'See the next five locked sheets and their release date.' : (Strings.lang == 'ar' ? 'اعرض البطاقات الخمس القادمة وتاريخ إصدارها.' : 'Voir les cinq prochaines fiches verrouillées et leur date de sortie.')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/release'),
        )),
        const SizedBox(height: 8),
        _RecentReleases(state: state, onCalendar: onCalendar),
        const SizedBox(height: 8),
        for (final p in repo.periods) _PeriodCard(state: state, period: p),
      ],
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final AppState state;
  final Period period;
  const _PeriodCard({required this.state, required this.period});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final count = state.repo.eventsOfPeriod(period.id).length;
    final prog = state.progress(period.id);
    final locked = !state.periodUnlocked(period);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openPeriod(context, state, period),
        child: Stack(children: [
          Positioned(
            right: -10,
            top: -10,
            child: SizedBox(
              width: 90,
              height: 90,
              child: CustomPaint(painter: StarPainter(cs.primary.withOpacity(0.18))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(period.title, style: Theme.of(context).textTheme.titleLarge)),
                if (locked) const Padding(
                  padding: EdgeInsets.only(left: 8, right: 36),
                  child: Icon(Icons.lock_outline, size: 18),
                ),
              ]),
              const SizedBox(height: 6),
              Text(period.intro),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: prog),
              const SizedBox(height: 6),
              Text(tr('period_stats', {'n': count, 'p': (prog * 100).round()}),
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ]),
      ),
    );
  }
}


class _RecentReleases extends StatelessWidget {
  final AppState state;
  final VoidCallback? onCalendar;
  const _RecentReleases({required this.state, this.onCalendar});
  @override
  Widget build(BuildContext context) {
      final events = state.latestReleasedEvents;
      final cs = Theme.of(context).colorScheme;
      return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.new_releases_outlined, color: cs.primary), const SizedBox(width: 8), Expanded(child: Text(tr('latest_releases'), style: Theme.of(context).textTheme.titleMedium)), Text('${events.length} / lot', style: Theme.of(context).textTheme.labelSmall)]),
        const SizedBox(height: 8),
        for (final e in events) ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(state.canOpenEvent(e) ? Icons.article_outlined : Icons.lock_outline, size: 19), title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text(e.dateLabel), onTap: () => openEvent(context, state, e)),
        Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: onCalendar, icon: const Icon(Icons.calendar_month), label: Text(tr('open_calendar')))),
      ])));
  }
}
