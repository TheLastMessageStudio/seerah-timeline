import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'nav.dart';
import 'search_delegate.dart';

class HomeScreen extends StatelessWidget {
  final AppState state;
  const HomeScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final repo = state.repo;
    final last = state.lastEvent;
    final total = repo.events.length;
    final done = state.readCount;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(
            child: Text(tr('app_name'),
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(context: context, delegate: AppSearchDelegate(state)),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => openSettings(context),
          ),
        ]),
        Text(tr('app_tagline')),
        const SizedBox(height: 16),
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
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openPeriod(context, period),
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
