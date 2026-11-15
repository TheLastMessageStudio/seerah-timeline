import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/arabic_search.dart';
import '../l10n/strings.dart';

class CorpusReaderScreen extends StatefulWidget {
  final String id;
  final String title;
  final bool quran;
  const CorpusReaderScreen({super.key, required this.id, required this.title, this.quran = false});
  @override
  State<CorpusReaderScreen> createState() => _CorpusReaderScreenState();
}

class _CorpusReaderScreenState extends State<CorpusReaderScreen> {
  String query = '';
  late final Future<Map<String, dynamic>> data = _load();

  Future<Map<String, dynamic>> _load() async {
    final path = widget.quran ? 'assets/data/quran_ar.json' : 'assets/data/hadith/${widget.id}.json';
    return jsonDecode(await rootBundle.loadString(path)) as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: data,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError || !snap.hasData) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
              mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.download_for_offline_outlined, size: 42, color: cs.primary),
                const SizedBox(height: 12),
                Text(tr('corpus_not_imported'), style: tt.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(tr('corpus_import_instruction'), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                SelectableText('python tools/import_corpora.py', textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(fontFamily: 'monospace', color: cs.primary)),
              ],
            )));
          }
          final root = snap.data!;
          final List<dynamic> raw = widget.quran ? (root['verses'] as List? ?? []) : (root['hadiths'] as List? ?? []);
          final q = normalizeSearchText(query.trim());
          final items = raw.where((v) {
            final m = Map<String, dynamic>.from(v as Map);
            if (q.isEmpty) return true;
            return normalizeSearchText('${m['textAr']} ${m['matnAr']} ${m['chapterAr']} ${m['reference']} ${m['surah']} ${m['ayah']}').contains(q);
          }).toList();
          return Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 10), child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: tr('book_search_text'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
            )),
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 5), child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${items.length} / ${raw.length}', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            )),
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${root['source'] ?? ''} · ${root['license'] ?? ''}',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            )),
            if ((root['note'] ?? '').toString().isNotEmpty)
              Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: Text(root['note'],
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
            Expanded(child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final m = Map<String, dynamic>.from(items[index] as Map);
                if (widget.quran) {
                  final surah = m['surah'];
                  final isFirst = index == 0 || items[index - 1]['surah'] != surah;
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (isFirst) Container(padding: const EdgeInsets.all(12), color: cs.surfaceContainerHighest,
                      child: Text('${m['surahNameAr'] ?? ''} · ${tr('quran_surah')} $surah', textAlign: TextAlign.center, style: tt.titleMedium)),
                    ListTile(
                      leading: CircleAvatar(radius: 16, child: Text('${m['ayah']}')),
                      title: Directionality(textDirection: TextDirection.rtl, child: SelectableText(
                        m['textAr'] ?? '', textAlign: TextAlign.justify,
                        style: tt.bodyLarge?.copyWith(fontFamily: 'serif', fontSize: 21, height: 2.0))),
                      subtitle: Text('$surah:${m['ayah']}', textAlign: TextAlign.end),
                    ),
                    const Divider(height: 1),
                  ]);
                }
                return Card(margin: const EdgeInsets.fromLTRB(12, 4, 12, 4), child: ExpansionTile(
                  title: Text('${tr('hadith_number')} ${m['number'] ?? index + 1}'),
                  subtitle: Text('${m['chapterAr'] ?? ''} ${m['reference'] ?? ''}'.trim(), maxLines: 2, overflow: TextOverflow.ellipsis),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Directionality(textDirection: TextDirection.rtl, child: SelectableText(
                      m['textAr'] ?? '', textAlign: TextAlign.justify,
                      style: tt.bodyLarge?.copyWith(fontFamily: 'serif', fontSize: 19, height: 2.0))),
                    if ((m['gradeAr'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 8), Align(alignment: Alignment.centerRight, child: Text('${tr('hadith_grade')}: ${m['gradeAr']}')),
                    ],
                    if ((m['reference'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 6), Text(m['reference'], style: tt.bodySmall),
                    ],
                  ],
                ));
              },
            )),
          ]);
        },
      ),
    );
  }
}
