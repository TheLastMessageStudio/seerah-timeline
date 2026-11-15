import 'package:flutter/material.dart';
import '../data/models.dart';
import '../core/arabic_search.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';

class BookReaderScreen extends StatefulWidget {
  final AppState state;
  final Book book;
  final String? eventId;
  const BookReaderScreen({super.key, required this.state, required this.book, this.eventId});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final Map<String, GlobalKey> _passageKeys = {};
  String query = '';
  String? selectedChapter;
  bool _restoreScheduled = false;

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _chapterLabel(BookPassage p) =>
      (Strings.lang == 'ar' && (p.chapterTitleAr ?? '').isNotEmpty)
          ? p.chapterTitleAr!
          : (Strings.lang == 'en' && (p.chapterTitleEn ?? '').isNotEmpty)
              ? p.chapterTitleEn!
              : ((p.chapterTitle ?? '').isNotEmpty ? p.chapterTitle! : p.chapterId);

  void _resume(String passageId) {
    final key = _passageKeys[passageId];
    if (key?.currentContext == null) return;
    Scrollable.ensureVisible(key!.currentContext!, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut, alignment: 0.08);
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.state.repo.passagesForBook(widget.book.id);
    final event = widget.eventId == null ? null : widget.state.repo.event(widget.eventId!);
    final q = normalizeSearchText(query.trim());
    final chapters = <String, String>{};
    for (final p in all) {
      chapters.putIfAbsent(p.chapterId, () => _chapterLabel(p));
    }
    final passages = all.where((p) {
      final matchesChapter = selectedChapter == null || selectedChapter == p.chapterId;
      if (!matchesChapter) return false;
      if (q.isEmpty) return true;
      return normalizeSearchText('${p.title} ${p.titleAr} ${p.titleEn ?? ''} ${p.text} ${p.textEn ?? ''} ${p.textAr ?? ''} ${p.chapterId} ${p.chapterTitle ?? ''} ${p.chapterTitleAr ?? ''}').contains(q);
    }).toList();
    final related = event == null
        ? <BookPassage>[]
        : widget.state.repo.passagesForEvent(event.id).where((p) => p.bookId == widget.book.id).toList();
    final saved = widget.state.bookPosition(widget.book.id);
    final cs = Theme.of(context).colorScheme;

    if (!_restoreScheduled && saved != null && all.any((p) => p.id == saved)) {
      _restoreScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _resume(saved));
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr('book_reader_title'))),
      body: Column(children: [
        if (event != null)
          Container(
            width: double.infinity,
            color: cs.secondaryContainer.withOpacity(0.55),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('book_from_event'), style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 3),
              Text(event.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(related.isEmpty ? tr('book_event_mapping_pending') : tr('book_event_passages_found')),
            ]),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => query = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: tr('book_search_text'),
              suffixIcon: query.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () { _search.clear(); setState(() => query = ''); }),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        if (chapters.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              Expanded(child: DropdownButtonFormField<String?>(
                value: selectedChapter,
                isExpanded: true,
                decoration: InputDecoration(labelText: tr('book_chapter_filter'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(tr('filter_all'))),
                  for (final entry in chapters.entries) DropdownMenuItem<String?>(value: entry.key, child: Text(entry.value, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => selectedChapter = v),
              )),
              const SizedBox(width: 8),
              if (saved != null && all.any((p) => p.id == saved))
                IconButton.filledTonal(
                  tooltip: tr('book_resume'),
                  onPressed: () {
                    if (query.isNotEmpty) { _search.clear(); query = ''; }
                    setState(() => selectedChapter = null);
                    WidgetsBinding.instance.addPostFrameCallback((_) => _resume(saved));
                  },
                  icon: const Icon(Icons.bookmark),
                ),
            ]),
          ),
        if (all.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Row(children: [
              Expanded(child: Text(tr('book_results_count', {'n': passages.length}), style: Theme.of(context).textTheme.labelMedium)),
              if (selectedChapter != null) TextButton(onPressed: () => setState(() => selectedChapter = null), child: Text(tr('filter_all'))),
            ]),
          ),
        Expanded(
          child: passages.isEmpty
              ? _EmptyBookState(hasQuery: q.isNotEmpty, hasText: all.isNotEmpty)
              : ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: passages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = passages[index];
                    final page = p.pageStart == null
                        ? tr('book_page_unverified')
                        : p.pageEnd == null || p.pageEnd == p.pageStart
                            ? '${tr('book_page')} ${p.pageStart}'
                            : '${tr('book_pages')} ${p.pageStart}–${p.pageEnd}';
                    final key = _passageKeys.putIfAbsent(p.id, () => GlobalKey());
                    return Card(
                      key: key,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => widget.state.saveBookPosition(widget.book.id, p.id),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (_chapterLabel(p).isNotEmpty)
                              Text(_chapterLabel(p), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.primary)),
                            const SizedBox(height: 5),
                            Text(p.titleFor(Strings.lang), style: Theme.of(context).textTheme.titleMedium),
                            if (Strings.lang != 'ar' && p.titleAr.isNotEmpty)
                              Directionality(textDirection: TextDirection.rtl, child: Align(alignment: Alignment.centerRight, child: Text(p.titleAr, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.primary)))),
                            const SizedBox(height: 5),
                            Wrap(spacing: 8, children: [
                              if (p.volume != null) Chip(label: Text('${tr('book_volume')} ${p.volume}'), visualDensity: VisualDensity.compact),
                              Chip(label: Text(page), visualDensity: VisualDensity.compact),
                            ]),
                            const SizedBox(height: 8),
                            SelectableText(p.textFor(Strings.lang), textDirection: Strings.lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 2.0, fontSize: 18)),
                            Align(alignment: Alignment.centerLeft, child: TextButton.icon(
                              onPressed: () => widget.state.saveBookPosition(widget.book.id, p.id),
                              icon: const Icon(Icons.bookmark_border, size: 18),
                              label: Text(tr('book_save_position')),
                            )),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class _EmptyBookState extends StatelessWidget {
  final bool hasQuery;
  final bool hasText;
  const _EmptyBookState({required this.hasQuery, required this.hasText});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(hasQuery ? Icons.search_off : Icons.menu_book_outlined, size: 48, color: cs.primary),
        const SizedBox(height: 14),
        Text(hasQuery ? tr('book_no_passage_match') : tr('book_text_pending'),
          textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(hasText ? tr('book_chapter_empty') : tr('book_reader_pending_note'), textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      ],
    )));
  }
}
