import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'nav.dart';

class TimelineScreen extends StatefulWidget {
  final AppState state;
  final String? periodId;
  final String title;
  final bool embedded;
  const TimelineScreen({
    super.key,
    required this.state,
    this.periodId,
    this.title = '',
    this.embedded = false,
  });
  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  String query = '';
  String? filter;
  bool onlyFavs = false;

  @override
  void initState() {
    super.initState();
    filter = widget.periodId;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final q = query.toLowerCase();
        final items = s.repo.events.where((e) {
          if (filter != null && e.periodId != filter) return false;
          if (onlyFavs && !s.favorites.contains(e.id)) return false;
          return q.isEmpty || e.title.toLowerCase().contains(q) || e.summary.toLowerCase().contains(q);
        }).toList();

        return Column(children: [
          if (!widget.embedded) ScreenTitle(widget.title),
          Padding(
            padding: EdgeInsets.fromLTRB(16, widget.embedded ? 16 : 0, 16, 12),
            child: SearchBar(
              hintText: tr('search_event_hint'),
              leading: const Icon(Icons.search),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          if (!widget.embedded)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip(tr('filter_all'), filter == null && !onlyFavs, () => setState(() { filter = null; onlyFavs = false; })),
                  _chip(tr('nav_favorites'), onlyFavs, () => setState(() => onlyFavs = !onlyFavs)),
                  for (final p in s.repo.periods)
                    _chip(p.title, filter == p.id, () => setState(() => filter = filter == p.id ? null : p.id)),
                ],
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text(tr('no_events')))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _TimelineTile(state: s, event: items[i], isLast: i == items.length - 1),
                  ),
          ),
        ]);
      },
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
      );
}

class _TimelineTile extends StatelessWidget {
  final AppState state;
  final Event event;
  final bool isLast;
  const _TimelineTile({required this.state, required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRead = state.read.contains(event.id);
    final locked = !state.canOpenEvent(event);
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 28,
          child: Column(children: [
            const SizedBox(height: 18),
            Icon(isRead ? Icons.circle : Icons.circle_outlined, size: 16, color: cs.primary),
            if (!isLast) Expanded(child: Container(width: 2, color: cs.primary.withOpacity(0.3))),
          ]),
        ),
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => openEvent(context, state, event),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(precisionIcon(event.datePrecision), size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(event.dateLabel, style: Theme.of(context).textTheme.labelMedium)),
                    if (locked) const Icon(Icons.lock_outline, size: 16),
                    if (state.favorites.contains(event.id)) Icon(Icons.favorite, size: 16, color: cs.error),
                  ]),
                  const SizedBox(height: 6),
                  Text(event.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(locked ? tr('premium_content') : event.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: locked ? TextStyle(color: cs.outline, fontStyle: FontStyle.italic) : null),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class PeriodScreen extends StatelessWidget {
  final AppState state;
  final Period period;
  const PeriodScreen({super.key, required this.state, required this.period});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(period.title)),
        body: TimelineScreen(state: state, periodId: period.id, embedded: true),
      );
}
