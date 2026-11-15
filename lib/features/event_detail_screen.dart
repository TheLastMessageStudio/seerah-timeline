import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/widgets.dart';
import '../core/place_image.dart';
import '../data/models.dart';
import '../data/repository.dart';
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
  bool details = true;

  bool _isChronologySection(Section section) {
    final value = section.heading.toLowerCase();
    if (value.contains('التاريخي') || value.contains('التاريخية')) return false;
    return value.contains('date') || value.contains('datation') ||
        value.contains('chronolog') || value.contains('dating') ||
        value.contains('timeframe') || value.contains('ملاحظات حول التاريخ') ||
        value.contains('التأريخ') || value.contains('التسلسل الزمني');
  }

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
              if (places.where((p) => p.hasImage).isNotEmpty) ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: 218,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: places.where((p) => p.hasImage).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final illustrated = places.where((p) => p.hasImage).toList()[index];
                      return SizedBox(
                        width: MediaQuery.of(context).size.width * .78,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: PlaceImage(place: illustrated, height: 166, width: double.infinity),
                          ),
                          const SizedBox(height: 5),
                          Text(illustrated.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.labelLarge),
                          Text(placeImageCaption(illustrated), maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.bodySmall),
                          Text(placeImageCreditLine(illustrated), maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.labelSmall),
                        ]),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 4, children: [
                Chip(
                  avatar: const Icon(Icons.event, size: 16),
                  label: Text(e.dateLabel),
                  visualDensity: VisualDensity.compact,
                ),
                PrecisionChip(e.datePrecision),
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
              if (!details) ...[
                Card(
                  margin: EdgeInsets.zero,
                  color: cs.surfaceContainerLow,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: cs.outlineVariant.withOpacity(.6))),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Icon(Icons.short_text_rounded, color: cs.secondary), const SizedBox(width: 8),
                        Text(Strings.lang == 'ar' ? 'خلاصة الحدث' : (Strings.lang == 'en' ? 'At a glance' : 'En bref'), style: tt.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w800))]),
                      const SizedBox(height: 10),
                      Text(e.summary, textAlign: Strings.lang == 'ar' ? TextAlign.right : TextAlign.start, style: body?.copyWith(fontSize: 16, height: 1.8)),
                    ]),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
                  child: Row(children: [
                    Icon(Icons.auto_stories_rounded, color: cs.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(Strings.lang == 'ar' ? 'القراءة المتعمقة' : (Strings.lang == 'en' ? 'In-depth reading' : 'Lecture approfondie'),
                      style: tt.titleLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w800)),
                  ]),
                ),
                for (var sectionIndex = 0; sectionIndex < e.content.where((section) => !_isChronologySection(section)).length; sectionIndex++)
                  Builder(builder: (context) {
                    final section = e.content.where((section) => !_isChronologySection(section)).toList()[sectionIndex];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: cs.surfaceContainerLow,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: cs.outlineVariant.withOpacity(.6))),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 15, 16, 17),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(width: 28, height: 28, alignment: Alignment.center,
                              decoration: BoxDecoration(color: cs.primary.withOpacity(.10), borderRadius: BorderRadius.circular(9)),
                              child: Text('${sectionIndex + 1}', style: tt.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w800))),
                            const SizedBox(width: 10),
                            Expanded(child: Text(section.heading, style: tt.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w800, height: 1.2))),
                          ]),
                          const SizedBox(height: 11),
                          Text(section.body, textAlign: Strings.lang == 'ar' ? TextAlign.right : TextAlign.start,
                            style: body?.copyWith(height: 1.78, fontSize: 16)),
                        ]),
                      ),
                    );
                  }),
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    initiallyExpanded: false,
                    leading: Icon(precisionIcon(e.datePrecision)),
                    title: Text(Strings.lang == 'en' ? 'Date and chronology' : (Strings.lang == 'ar' ? 'التاريخ والتسلسل الزمني' : 'Date et chronologie')),
                    subtitle: Text('${e.dateLabel} · ${precisionLabel(e.datePrecision)}'),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Text(precisionExplain(e.datePrecision), style: tt.bodyMedium?.copyWith(height: 1.45)),
                      for (final section in e.content.where(_isChronologySection)) ...[
                        const SizedBox(height: 12),
                        Align(alignment: Alignment.centerLeft, child: Text(section.heading, style: tt.titleSmall?.copyWith(color: cs.primary))),
                        const SizedBox(height: 4),
                        Text(section.body, style: tt.bodyMedium?.copyWith(height: 1.45)),
                      ],
                    ],
                  ),
                ),
                if (e.references.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: Icon(Icons.menu_book_outlined, color: cs.primary),
                      title: Text(Strings.lang == 'en' ? 'Bibliography and references' : (Strings.lang == 'ar' ? 'المراجع والمصادر' : 'Sources et références')),
                      subtitle: Text(Strings.lang == 'en' ? '${e.references.length} reference(s)' : (Strings.lang == 'ar' ? '${e.references.length} مراجع' : '${e.references.length} référence(s)')),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        for (var index = 0; index < e.references.length; index++) Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${index + 1}. ', style: tt.labelLarge?.copyWith(color: cs.primary)),
                            Expanded(child: SelectableText(e.references[index], style: tt.bodySmall?.copyWith(height: 1.45))),
                          ]),
                        ),
                      ],
                    ),
                  ),
                if (e.reliabilityNote != null)
                  Card(
                    child: ExpansionTile(
                      leading: const Icon(Icons.fact_check_outlined),
                      title: Text(tr('reliability')),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [Text(e.reliabilityNote!, style: tt.bodySmall)],
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
                if (repo.evidenceForEvent(e.id).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(Strings.lang == 'ar' ? 'الأحاديث ونصوص المصادر' : (Strings.lang == 'en' ? 'Hadith and source texts' : 'Hadiths et textes des sources'),
                      style: tt.titleMedium?.copyWith(color: cs.primary)),
                  const SizedBox(height: 6),
                  for (final evidence in repo.evidenceForEvent(e.id))
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: Icon(evidence['kind'] == 'quran' ? Icons.menu_book : Icons.format_quote,
                            color: cs.primary),
                        title: Text(
                          '${Strings.lang == 'ar' ? (evidence['collectionAr'] ?? evidence['collection'] ?? '') : (evidence['collection'] ?? '')} · ${Strings.lang == 'fr' ? (evidence['reference'] ?? '') : (evidence['reference'] ?? '').toString().split('·').first.trim()}',
                          style: tt.titleSmall),
                        subtitle: Text(Strings.lang == 'en' ? (evidence['noteEn'] ?? '') : (Strings.lang == 'ar' ? (evidence['noteAr'] ?? '') : (evidence['noteFr'] ?? '')), maxLines: 3, overflow: TextOverflow.ellipsis),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          if ((evidence['collectionAr'] ?? '').toString().isNotEmpty)
                            Align(alignment: Alignment.centerRight, child: Text(evidence['collectionAr'],
                                textDirection: TextDirection.rtl, style: tt.titleSmall?.copyWith(color: cs.primary))),
                          const SizedBox(height: 8),
                          if ((evidence['textAr'] ?? '').toString().trim().isNotEmpty)
                            Directionality(textDirection: TextDirection.rtl, child: SelectableText(
                              evidence['textAr'], textAlign: TextAlign.justify,
                              style: tt.bodyLarge?.copyWith(fontFamily: 'serif', height: 2.0, fontSize: 19))),
                          if ((Strings.lang == 'en' ? evidence['textEn'] : (Strings.lang == 'ar' ? evidence['textArSummary'] : evidence['textFr']))?.toString().isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            if ((evidence['textAr'] ?? '').toString().trim().isEmpty)
                              Text(Strings.lang == 'ar' ? 'خلاصة الرواية' : (Strings.lang == 'en' ? 'Narration summary' : 'Résumé de la narration'), style: tt.labelMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                            Text(Strings.lang == 'en' ? evidence['textEn'] : (Strings.lang == 'ar' ? evidence['textArSummary'] : evidence['textFr']),
                                textAlign: Strings.lang == 'ar' ? TextAlign.right : TextAlign.start, style: body),
                          ],
                          if ((Strings.lang == 'en' ? evidence['noteEn'] : (Strings.lang == 'ar' ? evidence['noteAr'] : evidence['noteFr']))?.toString().isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(Strings.lang == 'en' ? evidence['noteEn'] : (Strings.lang == 'ar' ? evidence['noteAr'] : evidence['noteFr']),
                                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                          if ((evidence['url'] ?? '').toString().startsWith('https://')) ...[
                            const SizedBox(height: 10),
                            Align(alignment: Alignment.centerLeft, child: TextButton.icon(
                              onPressed: () async {
                                final uri = Uri.tryParse(evidence['url'].toString());
                                if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                              },
                              icon: const Icon(Icons.open_in_new, size: 17),
                              label: Text(Strings.lang == 'ar' ? 'فتح الحديث في المصدر' : (Strings.lang == 'en' ? 'Open hadith at source' : 'Ouvrir le hadith dans le recueil')),
                            )),
                          ],
                        ],
                      ),
                    ),
                ],
              ],
              const SizedBox(height: 24),
              _QuizBonus(event: e, repo: repo),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}


class _QuizBonus extends StatefulWidget {
  final Event event;
  final Repository repo;
  const _QuizBonus({required this.event, required this.repo});
  @override
  State<_QuizBonus> createState() => _QuizBonusState();
}

class _QuizBonusState extends State<_QuizBonus> {
  final Map<int, int> _answers = {};

  List<Map<String, dynamic>> _buildQuestions() {
    final sections = widget.event.content;
    if (sections.length < 2) return const [];
    final questions = <Map<String, dynamic>>[];
    final prompts = Strings.lang == 'en'
        ? ['Which aspect of the event is explained in this excerpt?', 'Which part of the account does this passage describe?', 'What theme is developed in the paragraph below?', 'Which element of the entry is illustrated by this text?']
        : (Strings.lang == 'ar'
            ? ['أي جانب من الحدث يشرحه هذا المقطع؟', 'إلى أي جزء من الرواية يشير هذا النص؟', 'ما الموضوع الذي تتناوله الفقرة؟', 'أي عنصر من هذه الصفحة يوضحه النص؟']
            : ['Quel aspect de l’événement est expliqué dans cet extrait ?', 'À quelle partie du récit ce passage correspond-il ?', 'Quel thème est développé dans le paragraphe ci-dessous ?', 'Quel élément de la fiche est illustré par ce texte ?']);
    for (var q = 0; q < 2 && q < sections.length; q++) {
      final correctSection = sections[(widget.event.sortOrder ~/ 10 + q) % sections.length];
      final excerpt = correctSection.body.trim().split(RegExp(r'(?<=[.!?])\s+')).first;
      final choices = <String>[correctSection.heading];
      for (final section in sections) {
        if (section.heading != correctSection.heading && choices.length < 3) choices.add(section.heading);
      }
      // Shuffle distractors deterministically per event without repeating a fixed pair.
      final globalHeadings = widget.repo.events
          .where((e) => e.id != widget.event.id)
          .expand((e) => e.content.map((s) => s.heading))
          .where((h) => !choices.contains(h));
      for (final h in globalHeadings) { if (choices.length >= 4) break; choices.add(h); }
      final shift = (widget.event.sortOrder + q * 3) % choices.length;
      final rotated = [...choices.skip(shift), ...choices.take(shift)];
      questions.add({
        'prompt': prompts[(widget.event.sortOrder + q) % prompts.length],
        'excerpt': excerpt.length > 190 ? '${excerpt.substring(0, 187)}…' : excerpt,
        'options': rotated,
        'correct': rotated.indexOf(correctSection.heading),
      });
    }
    return questions;
  }

  @override
  Widget build(BuildContext context) {
    final questions = _buildQuestions();
    if (questions.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.quiz_outlined, color: cs.primary), const SizedBox(width: 8),
          Expanded(child: Text(tr('quiz_bonus'), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700))) ]),
        const SizedBox(height: 6),
        Text(Strings.lang == 'en' ? 'Reading-comprehension questions based on this entry.' : (Strings.lang == 'ar' ? 'أسئلة فهم مبنية على فقرات هذه الصفحة.' : 'Questions de compréhension construites à partir des paragraphes de cette fiche.'), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        for (var q = 0; q < questions.length; q++) ...[
          const SizedBox(height: 16),
          Text(Strings.lang == 'en' ? 'Question ${q + 1}' : (Strings.lang == 'ar' ? 'السؤال ${q + 1}' : 'Question ${q + 1}'), style: tt.labelLarge?.copyWith(color: cs.primary)),
          const SizedBox(height: 5),
          Text(questions[q]['prompt'] as String, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)), child: Text('« ${questions[q]['excerpt']} »', style: tt.bodyMedium)),
          const SizedBox(height: 8),
          for (var i = 0; i < (questions[q]['options'] as List<String>).length; i++)
            Padding(padding: const EdgeInsets.only(bottom: 6), child: Material(
              color: _answers[q] == null ? cs.surfaceContainerLow : (i == questions[q]['correct'] ? cs.primaryContainer.withOpacity(.7) : (_answers[q] == i ? cs.errorContainer.withOpacity(.7) : cs.surfaceContainerLow)),
              borderRadius: BorderRadius.circular(10), child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _answers[q] != null ? null : () => setState(() => _answers[q] = i),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(children: [
                  Expanded(child: Text((questions[q]['options'] as List<String>)[i])),
                  if (_answers[q] != null && i == questions[q]['correct']) Icon(Icons.check_circle, color: cs.primary, size: 18)
                  else if (_answers[q] == i) Icon(Icons.cancel, color: cs.error, size: 18),
                ])),
              ),
            )),
          if (_answers[q] != null) Text(_answers[q] == questions[q]['correct'] ? tr('quiz_correct') : (Strings.lang == 'en' ? 'Review the passage: the correct answer is highlighted.' : (Strings.lang == 'ar' ? 'راجع النص؛ الإجابة الصحيحة مميزة.' : 'Relis le passage : la réponse correcte est mise en évidence.')), style: tt.bodySmall?.copyWith(color: _answers[q] == questions[q]['correct'] ? cs.primary : cs.error)),
        ],
        if (_answers.length == questions.length) Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => setState(_answers.clear), icon: const Icon(Icons.refresh, size: 17), label: Text(tr('quiz_retry')))),
      ],
    )));
  }
}
