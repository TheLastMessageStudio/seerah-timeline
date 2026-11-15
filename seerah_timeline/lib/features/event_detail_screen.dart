import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'nav.dart';

class EventDetailScreen extends StatefulWidget {
  final AppState state;
  final Event event;
  const EventDetailScreen({super.key, required this.state, required this.event});
  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool details = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => widget.state.visit(widget.event.id));
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final repo = state.repo;
    final e = widget.event;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final body = tt.bodyLarge?.copyWith(height: 1.6, fontFamily: 'serif');

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final fav = state.favorites.contains(e.id);
        final isRead = state.read.contains(e.id);
        final prev = repo.neighbor(e, -1);
        final next = repo.neighbor(e, 1);
        final persons = e.personIds.map(repo.person).whereType<Person>().toList();
        final places = e.placeIds.map(repo.place).whereType<Place>().toList();
        final sources = e.sourceIds.map(repo.source).whereType<Source>().toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(repo.period(e.periodId)?.title ?? '', style: tt.titleSmall),
            actions: [
              IconButton(
                icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? cs.error : null),
                onPressed: () => state.toggleFavorite(e.id),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: prev == null ? null : () => openEvent(context, state, prev, replace: true),
                    icon: const Icon(Icons.chevron_left),
                    label: Text(tr('prev')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: next == null ? null : () => openEvent(context, state, next, replace: true),
                    icon: const Icon(Icons.chevron_right),
                    label: Text(tr('next')),
                  ),
                ),
              ]),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (e.titleAr.isNotEmpty && Strings.lang != 'ar')
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(e.titleAr, style: tt.headlineSmall?.copyWith(color: cs.primary)),
                ),
              Text(e.title, style: tt.headlineSmall),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 4, children: [
                Chip(
                  avatar: const Icon(Icons.event, size: 16),
                  label: Text(e.dateLabel),
                  visualDensity: VisualDensity.compact,
                ),
                PrecisionChip(e.datePrecision),
                if (e.status == 'draft')
                  Chip(label: Text(tr('draft_badge')), visualDensity: VisualDensity.compact),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text(tr('summary'))),
                      ButtonSegment(value: true, label: Text(tr('details'))),
                    ],
                    selected: {details},
                    onSelectionChanged: (v) => setState(() => details = v.first),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => state.toggleRead(e.id),
                  icon: Icon(isRead ? Icons.check_circle : Icons.check_circle_outline),
                  label: Text(isRead ? tr('read') : tr('mark_read')),
                ),
              ),
              const SizedBox(height: 8),
              if (!details)
                Text(e.summary, style: body)
              else ...[
                for (final s in e.content) ...[
                  Text(s.heading, style: tt.titleMedium?.copyWith(color: cs.primary)),
                  const SizedBox(height: 4),
                  Text(s.body, style: body),
                  const SizedBox(height: 16),
                ],
                Card(
                  child: ListTile(
                    leading: Icon(precisionIcon(e.datePrecision)),
                    title: Text(tr('chrono_certainty', {'label': precisionLabel(e.datePrecision).toLowerCase()})),
                    subtitle: Text(precisionExplain(e.datePrecision)),
                  ),
                ),
                if (e.reliabilityNote != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.fact_check_outlined),
                      title: Text(tr('reliability')),
                      subtitle: Text(e.reliabilityNote!),
                    ),
                  ),
                const SizedBox(height: 12),
                if (persons.isNotEmpty) ...[
                  Text(tr('persons'), style: tt.titleMedium?.copyWith(color: cs.primary)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, children: [
                    for (final p in persons)
                      ActionChip(
                        avatar: state.canOpenPerson(p) ? null : const Icon(Icons.lock_outline, size: 14),
                        label: Text(p.name),
                        onPressed: () => openPerson(context, state, p),
                      ),
                  ]),
                  const SizedBox(height: 16),
                ],
                if (places.isNotEmpty) ...[
                  Text(tr('places'), style: tt.titleMedium?.copyWith(color: cs.primary)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, children: [
                    for (final p in places)
                      ActionChip(
                        avatar: Icon(state.canOpenPlace(p) ? Icons.place_outlined : Icons.lock_outline, size: 14),
                        label: Text(p.name),
                        onPressed: () => openPlace(context, state, p),
                      ),
                  ]),
                  const SizedBox(height: 16),
                ],
                Text(tr('sources'), style: tt.titleMedium?.copyWith(color: cs.primary)),
                const SizedBox(height: 6),
                for (final s in sources)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(s.title),
                    subtitle: Text(s.description),
                  ),
                for (final r in e.references) Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('• ${localRef(r)}'),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
