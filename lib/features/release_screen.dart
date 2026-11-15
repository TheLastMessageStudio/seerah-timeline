import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import 'nav.dart';

class ReleaseScreen extends StatefulWidget {
  final AppState state;
  final String? eventId;
  const ReleaseScreen({super.key, required this.state, this.eventId});
  @override
  State<ReleaseScreen> createState() => _ReleaseScreenState();
}

class _ReleaseScreenState extends State<ReleaseScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  Timer? _timer;
  @override
  void initState() { super.initState(); _future = _load(); _timer = Timer.periodic(const Duration(minutes: 1), (_) { if (mounted) setState(() {}); }); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  Future<List<Map<String, dynamic>>> _load() async => (jsonDecode(await rootBundle.loadString('assets/data/release_schedule.json')) as List).cast<Map<String, dynamic>>();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(Strings.lang == 'en' ? 'Next release' : (Strings.lang == 'ar' ? 'الإصدار القادم' : 'Prochaine sortie'))),
    body: FutureBuilder<List<Map<String, dynamic>>>(future: _future, builder: (context, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final now = DateTime.now();
      final rows = snap.data!;
      final upcoming = rows.where((r) { final d = DateTime.parse(r['releaseDate'] as String); return !DateTime(d.year, d.month, d.day, 10).isBefore(now); }).toList();
      final eventId = widget.eventId;
      final targetedRows = eventId == null ? <Map<String, dynamic>>[] : rows.where((r) => (r['eventIds'] as List).contains(eventId)).toList();
      final next = targetedRows.isNotEmpty ? targetedRows.first : (upcoming.isEmpty ? null : upcoming.first);
      if (next == null) return const Center(child: Text('Aucune sortie planifiée.'));
      final rawDate = DateTime.parse(next['releaseDate'] as String);
      final date = DateTime(rawDate.year, rawDate.month, rawDate.day, 10);
      final delta = date.difference(now);
      final days = delta.inDays;
      final hours = delta.inHours % 24;
      final minutes = delta.inMinutes % 60;
      final ids = (next['eventIds'] as List).cast<String>();
      final events = ids.map(widget.state.repo.event).whereType<Event>().toList();
      final cs = Theme.of(context).colorScheme;
      return ListView(padding: const EdgeInsets.all(18), children: [
        Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
          Icon(Icons.auto_awesome, size: 34, color: cs.primary),
          const SizedBox(height: 8),
          Text(Strings.lang == 'en' ? 'Time remaining' : (Strings.lang == 'ar' ? 'الوقت المتبقي' : 'Temps restant'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _unit(context, '$days', Strings.lang == 'en' ? 'days' : (Strings.lang == 'ar' ? 'أيام' : 'jours')),
            _unit(context, '$hours', Strings.lang == 'en' ? 'hours' : (Strings.lang == 'ar' ? 'ساعات' : 'heures')),
            _unit(context, '$minutes', Strings.lang == 'en' ? 'min' : (Strings.lang == 'ar' ? 'دقائق' : 'min')),
          ]),
          const SizedBox(height: 10),
          Text('${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}', style: Theme.of(context).textTheme.titleLarge),
          Text(Strings.lang == 'en' ? 'Planned editorial release · not an automatic store publication' : (Strings.lang == 'ar' ? 'موعد تحريري مخطط وليس نشراً تلقائياً في المتجر' : 'Sortie éditoriale prévue · pas une publication automatique sur le store'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ]))),
        const SizedBox(height: 14),
        Text(Strings.lang == 'en' ? 'Next batch' : (Strings.lang == 'ar' ? 'الدفعة القادمة' : 'Prochain lot'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final e in events) Card(child: ListTile(
          leading: Icon(widget.state.canOpenEvent(e) ? Icons.menu_book_outlined : Icons.lock_outline),
          title: Text(e.title), subtitle: Text(e.dateLabel),
          trailing: const Icon(Icons.chevron_right), onTap: () => openEvent(context, widget.state, e),
        )),
      ]);
    }),
  );
  Widget _unit(BuildContext context, String value, String label) => Column(children: [Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), Text(label, style: Theme.of(context).textTheme.labelSmall)]);
}
