import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'nav.dart';

class AppSearchDelegate extends SearchDelegate<void> {
  final AppState state;
  AppSearchDelegate(this.state) : super(searchFieldLabel: tr('search_hint'));

  @override
  List<Widget>? buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _list(context);

  @override
  Widget buildSuggestions(BuildContext context) => _list(context);

  Widget _list(BuildContext context) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return Center(child: Text(tr('search_prompt')));
    final repo = state.repo;

    final events = repo.events.where((e) {
      var hit = e.title.toLowerCase().contains(q) || e.summary.toLowerCase().contains(q);
      if (!hit && state.canOpenEvent(e)) {
        hit = e.content.any((c) => c.body.toLowerCase().contains(q));
      }
      return hit;
    }).toList();
    final persons = repo.persons.where((p) => p.name.toLowerCase().contains(q) || p.role.toLowerCase().contains(q)).toList();
    final places = repo.places.where((p) => p.name.toLowerCase().contains(q)).toList();

    if (events.isEmpty && persons.isEmpty && places.isEmpty) {
      return Center(child: Text(tr('no_results')));
    }
    return ListView(children: [
      if (events.isNotEmpty) _Header(tr('h_events')),
      for (final e in events)
        ListTile(
          leading: const Icon(Icons.event),
          title: Text(e.title),
          subtitle: Text(e.dateLabel),
          trailing: state.canOpenEvent(e) ? null : const Icon(Icons.lock_outline),
          onTap: () => openEvent(context, state, e),
        ),
      if (persons.isNotEmpty) _Header(tr('persons')),
      for (final p in persons)
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(p.name),
          subtitle: Text(p.role),
          trailing: state.canOpenPerson(p) ? null : const Icon(Icons.lock_outline),
          onTap: () => openPerson(context, state, p),
        ),
      if (places.isNotEmpty) _Header(tr('places')),
      for (final p in places)
        ListTile(
          leading: const Icon(Icons.place_outlined),
          title: Text(p.name),
          trailing: state.canOpenPlace(p) ? null : const Icon(Icons.lock_outline),
          onTap: () => openPlace(context, state, p),
        ),
    ]);
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}
