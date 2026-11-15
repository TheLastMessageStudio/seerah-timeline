import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import 'nav.dart';

class CalendarScreen extends StatefulWidget {
  final AppState state;
  const CalendarScreen({super.key, required this.state});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final Future<List<Map<String, dynamic>>> _schedule = _load();
  Future<List<Map<String, dynamic>>> _load() async {
    final raw = await rootBundle.loadString('assets/data/release_schedule.json');
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  String _date(String value) {
    final d = DateTime.parse(value);
    final months = Strings.lang == 'en'
        ? ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
        : (Strings.lang == 'ar'
            ? ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر']
            : ['janv.','févr.','mars','avr.','mai','juin','juil.','août','sept.','oct.','nov.','déc.']);
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _month(DateTime month, Set<String> releaseDays, ColorScheme cs) {
    final first = DateTime(month.year, month.month, 1);
    final offset = (first.weekday + 6) % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = ((offset + days + 6) ~/ 7) * 7;
    final weekdays = Strings.lang == 'en'
        ? ['M','T','W','T','F','S','S']
        : (Strings.lang == 'ar' ? ['ن','ث','ر','خ','ج','س','ح'] : ['L','M','M','J','V','S','D']);
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${month.month.toString().padLeft(2,'0')}/${month.year}', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 7, childAspectRatio: 1.35, children: [
        for (final day in weekdays) Center(child: Text(day, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.primary))),
        for (var i = 0; i < cells; i++)
          if (i < offset || i >= offset + days) const SizedBox.shrink()
          else Builder(builder: (context) {
            final d = i - offset + 1;
            final key = '${month.year}-${month.month.toString().padLeft(2,'0')}-${d.toString().padLeft(2,'0')}';
            final release = releaseDays.contains(key);
            return Center(child: Container(width: 30, height: 30, alignment: Alignment.center,
              decoration: BoxDecoration(color: release ? cs.primary : Colors.transparent, shape: BoxShape.circle),
              child: Text('$d', style: TextStyle(fontSize: 12, fontWeight: release ? FontWeight.bold : FontWeight.normal, color: release ? cs.onPrimary : null))));
          }),
      ]),
      const SizedBox(height: 4),
      Row(children: [Container(width: 9,height: 9,decoration:BoxDecoration(color:cs.primary,shape:BoxShape.circle)), const SizedBox(width: 6), Text(Strings.lang == 'en' ? 'Release day' : (Strings.lang == 'ar' ? 'موعد الإصدار' : 'Jour de sortie'), style: Theme.of(context).textTheme.labelSmall)])
    ])));
  }

  String _status(Map<String, dynamic> row) {
    final parsed = DateTime.parse(row['releaseDate'] as String);
    final release = DateTime(parsed.year, parsed.month, parsed.day, 10);
    final released = !DateTime.now().isBefore(release);
    return released
        ? (Strings.lang == 'en' ? 'Released' : (Strings.lang == 'ar' ? 'صدر' : 'Sorti'))
        : (Strings.lang == 'en' ? 'Planned' : (Strings.lang == 'ar' ? 'مخطط' : 'Planifié'));
  }

  List<DateTime> _months(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return [DateTime.now()];
    final dates = rows.map((r) => DateTime.parse(r['releaseDate'] as String)).toList()..sort();
    final result = <DateTime>[];
    var cursor = DateTime(dates.first.year, dates.first.month);
    final end = DateTime(dates.last.year, dates.last.month);
    while (!cursor.isAfter(end)) { result.add(cursor); cursor = DateTime(cursor.year, cursor.month + 1); }
    return result;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _schedule,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final rows = snapshot.data!;
      final releaseDays = rows.map((r) => r['releaseDate'] as String).toSet();
      final eventsById = <String, Event>{for (final e in widget.state.repo.events) e.id: e};
      final cs = Theme.of(context).colorScheme;
      return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
        Text(Strings.lang == 'en' ? 'Release calendar' : (Strings.lang == 'ar' ? 'تقويم الإصدارات' : 'Calendrier des sorties'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(Strings.lang == 'en' ? 'A 15-week editorial plan · five event sheets each week.' : (Strings.lang == 'ar' ? 'خطة تحريرية لخمسة عشر أسبوعاً · خمس بطاقات أحداث كل أسبوع.' : 'Quinze semaines de préparation éditoriale · cinq fiches par semaine (quatre pour le dernier lot).'), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Card(child: ListTile(
          leading: const Icon(Icons.hourglass_bottom_rounded),
          title: Text(Strings.lang == 'en' ? 'Countdown to the next release' : (Strings.lang == 'ar' ? 'العد التنازلي للإصدار القادم' : 'Compte à rebours avant la prochaine sortie')),
          subtitle: Text(Strings.lang == 'en' ? 'Open the release screen and see the next batch.' : (Strings.lang == 'ar' ? 'افتح شاشة الإصدار والدفعة القادمة.' : 'Voir le temps restant et le contenu du prochain lot.')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/release'),
        )),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final month in _months(rows))
            SizedBox(width: (MediaQuery.of(context).size.width - 48) / 2, child: _month(month, releaseDays, cs)),
        ]),
        const SizedBox(height: 16),
        Text(Strings.lang == 'en' ? 'Publication table' : (Strings.lang == 'ar' ? 'جدول النشر' : 'Tableau des publications'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(clipBehavior: Clip.antiAlias, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
          dataRowMinHeight: 58, dataRowMaxHeight: 130,
          columnSpacing: 18,
          columns: [
            DataColumn(label: Text(Strings.lang == 'en' ? 'Batch / date' : (Strings.lang == 'ar' ? 'الدفعة / التاريخ' : 'Lot / date'))),
            DataColumn(label: Text(Strings.lang == 'en' ? 'Planned releases' : (Strings.lang == 'ar' ? 'الإصدارات المقررة' : 'Sorties prévues'))),
            DataColumn(label: Text(Strings.lang == 'en' ? 'Status' : (Strings.lang == 'ar' ? 'الحالة' : 'État'))),
          ],
          rows: [for (final row in rows) DataRow(cells: [
            DataCell(SizedBox(width: 94, child: Text('${row['week']} · ${_date(row['releaseDate'])}'))),
            DataCell(SizedBox(width: 245, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [for (final id in (row['eventIds'] as List).cast<String>()) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('${eventsById[id] != null && !widget.state.canOpenEvent(eventsById[id]!) ? '🔒 ' : '• '}${eventsById[id]?.title ?? id}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall))]))),
            DataCell(Chip(label: Text(_status(row)), visualDensity: VisualDensity.compact)),
          ])],
        ))),
        const SizedBox(height: 8),
        Text(Strings.lang == 'en' ? 'The dates are a planned editorial cadence, not a promise that a store update is already published. Content is reviewed before being marked as verified.' : (Strings.lang == 'ar' ? 'هذه التواريخ خطة تحريرية وليست تأكيداً لنشر تحديث في المتجر. تتم مراجعة المحتوى قبل اعتباره موثقاً.' : 'Ces dates sont un calendrier éditorial prévisionnel, pas la confirmation d’une publication sur les stores. Chaque fiche reste à relire avant toute validation historique.'), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ]);
    },
  );
}
