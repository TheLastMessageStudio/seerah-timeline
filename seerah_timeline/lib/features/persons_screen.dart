import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'nav.dart';

class PersonsScreen extends StatefulWidget {
  final AppState state;
  const PersonsScreen({super.key, required this.state});
  @override
  State<PersonsScreen> createState() => _PersonsScreenState();
}

class _PersonsScreenState extends State<PersonsScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final q = query.toLowerCase();
    final list = s.repo.persons.where((p) => q.isEmpty || p.name.toLowerCase().contains(q) || p.role.toLowerCase().contains(q)).toList();
    return Column(children: [
      ScreenTitle(tr('persons_title')),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SearchBar(
          hintText: tr('search_person_hint'),
          leading: const Icon(Icons.search),
          onChanged: (v) => setState(() => query = v),
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final p = list[i];
            final locked = !s.canOpenPerson(p);
            return Card(
              child: ListTile(
                // Initiale seulement : jamais de portrait.
                leading: CircleAvatar(child: Text(p.name.substring(0, 1))),
                title: Text(p.name),
                subtitle: Text(p.role),
                trailing: Icon(locked ? Icons.lock_outline : Icons.chevron_right),
                onTap: () => openPerson(context, s, p),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class PersonDetailScreen extends StatelessWidget {
  final AppState state;
  final Person person;
  const PersonDetailScreen({super.key, required this.state, required this.person});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final events = state.repo.eventsOfPerson(person.id);
    return Scaffold(
      appBar: AppBar(title: Text(person.name)),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (person.nameAr.isNotEmpty && Strings.lang != 'ar')
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(person.nameAr, style: tt.headlineSmall?.copyWith(color: cs.primary)),
          ),
        Text(person.name, style: tt.headlineSmall),
        const SizedBox(height: 8),
        Chip(label: Text(person.role)),
        const SizedBox(height: 12),
        Text(tr('biography'), style: tt.titleMedium?.copyWith(color: cs.primary)),
        const SizedBox(height: 4),
        Text(person.bio, style: tt.bodyLarge?.copyWith(height: 1.6, fontFamily: 'serif')),
        const SizedBox(height: 20),
        Text(tr('related_events'), style: tt.titleMedium?.copyWith(color: cs.primary)),
        const SizedBox(height: 4),
        if (events.isEmpty) Text(tr('no_related')),
        for (final e in events)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(precisionIcon(e.datePrecision)),
            title: Text(e.title),
            subtitle: Text(e.dateLabel),
            trailing: Icon(state.canOpenEvent(e) ? Icons.chevron_right : Icons.lock_outline),
            onTap: () => openEvent(context, state, e),
          ),
      ]),
    );
  }
}
