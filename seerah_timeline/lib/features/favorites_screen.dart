import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'nav.dart';

class FavoritesScreen extends StatefulWidget {
  final AppState state;
  const FavoritesScreen({super.key, required this.state});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int mode = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final List<Event> list = mode == 0
        ? s.repo.events.where((e) => s.favorites.contains(e.id)).toList()
        : s.history.map(s.repo.event).whereType<Event>().toList();
    return Column(children: [
      ScreenTitle(tr('personal_reading')),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 0, label: Text(tr('tab_favorites')), icon: Icon(Icons.favorite_border)),
            ButtonSegment(value: 1, label: Text(tr('tab_history')), icon: Icon(Icons.history)),
          ],
          selected: {mode},
          onSelectionChanged: (v) => setState(() => mode = v.first),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: list.isEmpty
            ? Center(child: Text(mode == 0 ? tr('no_favorites') : tr('no_history')))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final e = list[i];
                  return Card(
                    child: ListTile(
                      leading: Icon(s.read.contains(e.id) ? Icons.check_circle : Icons.circle_outlined),
                      title: Text(e.title),
                      subtitle: Text(e.dateLabel),
                      trailing: Icon(s.canOpenEvent(e) ? Icons.chevron_right : Icons.lock_outline),
                      onTap: () => openEvent(context, s, e),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}
