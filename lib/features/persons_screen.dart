import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import '../core/widgets.dart';
import '../core/arabic_search.dart';
import 'family_tree_screen.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'nav.dart';
import 'package:go_router/go_router.dart';

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
    final q = normalizeSearchText(query);
    final list = s.repo.persons.where((p) => q.isEmpty || normalizeSearchText('${p.name} ${p.nameAr} ${p.role}').contains(q)).toList();
    return Column(children: [
      ScreenTitle(tr('persons_title')),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () => context.push('/family-tree'),
          icon: const Icon(Icons.account_tree_outlined),
          label: Text(tr('family_tree')),
        )),
      ),
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

class _FamilyLinks extends StatelessWidget {
  final AppState state;
  final Person person;
  const _FamilyLinks({required this.state, required this.person});

  String _label(String kind) {
    if (Strings.lang == 'ar') {
      return switch (kind) {
        'parent' => 'والد/والدة أو سلف', 'child' => 'ابن/ابنة',
        'spouse' => 'زوج/زوجة', 'sibling' => 'أخ/أخت',
        'grandparent' => 'جد/جدة', 'grandchild' => 'حفيد/حفيدة',
        'uncle_aunt' => 'عم/عمة أو خال/خالة', 'cousin' => 'ابن/ابنة عم أو خال',
        'niece_nephew' => 'ابن/ابنة أخ أو أخت',
        'former_adoptive' => 'صلة تبنٍّ سابقة / رعاية',
        'foster_parent' => 'مرضعة / أم من الرضاعة', 'foster_child' => 'رضيع / ابن من الرضاعة',
        'in_law' => 'قرابة بالمصاهرة', 'co_parent' => 'والد/والدة شريك في الأبناء',
        _ => 'صلة أسرية'
      };
    }
    if (Strings.lang == 'en') {
      return switch (kind) {
        'parent' => 'Parent', 'child' => 'Child', 'spouse' => 'Spouse',
        'sibling' => 'Sibling', 'grandparent' => 'Grandparent',
        'grandchild' => 'Grandchild', 'uncle_aunt' => 'Uncle / aunt',
        'cousin' => 'Cousin', 'niece_nephew' => 'Niece / nephew',
        'former_adoptive' => 'Former adoptive / guardianship tie',
        'foster_parent' => 'Wet nurse / milk mother', 'foster_child' => 'Foster child / milk child',
        'in_law' => 'In-law relationship', 'co_parent' => 'Co-parent',
        _ => 'Family connection'
      };
    }
    return switch (kind) {
      'parent' => 'Parent', 'child' => 'Enfant', 'spouse' => 'Conjoint(e)',
      'sibling' => 'Frère / sœur', 'grandparent' => 'Grand-parent',
      'grandchild' => 'Petit-enfant', 'uncle_aunt' => 'Oncle / tante',
      'cousin' => 'Cousin(e)', 'niece_nephew' => 'Neveu / nièce',
      'former_adoptive' => 'Ancien lien d’adoption / de protection',
      'foster_parent' => 'Nourrice / mère de lait', 'foster_child' => 'Enfant allaité / de lait',
      'in_law' => 'Parenté par alliance', 'co_parent' => 'Autre parent de leur enfant',
      _ => 'Lien familial'
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final relations = familyRelationsFor(person.id);
    final linked = relations.map((r) => (relation: r, person: state.repo.person(r.personId)))
        .where((x) => x.person != null).toList();
    if (linked.isEmpty) {
      final note = Strings.lang == 'ar'
          ? 'لا توجد في شجرة التطبيق الحالية قرابة مباشرة موثقة لهذه الشخصية مع الأسرة المعروضة. ولا يعني ذلك أنها لم تكن لها أسرة؛ بل إن الروابط تحتاج إلى مصدر محدد قبل إضافتها.'
          : (Strings.lang == 'en'
              ? 'No direct kinship link to the family shown in this app tree is currently documented for this person. This does not mean the person had no family; a specific source is needed before adding a link.'
              : 'Aucun lien de parenté direct avec la famille représentée dans cet arbre n’est actuellement documenté pour cette personne. Cela ne signifie pas qu’elle n’avait pas de famille : un lien ne sera ajouté qu’avec une source précise.');
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outlineVariant.withOpacity(.65))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline, color: cs.secondary), const SizedBox(width: 9), Expanded(child: Text(note, style: tt.bodySmall?.copyWith(height: 1.45))) ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.secondary.withOpacity(.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.account_tree_rounded, color: cs.primary), const SizedBox(width: 8), Text(Strings.lang == 'ar' ? 'الروابط الأسرية' : (Strings.lang == 'en' ? 'Family connections' : 'Liens familiaux'), style: tt.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 8),
        Wrap(spacing: 7, runSpacing: 6, children: [
          for (final item in linked) ActionChip(
            avatar: Icon(item.relation.kind == 'spouse' ? Icons.favorite_border : (item.relation.kind == 'cousin' ? Icons.groups_outlined : Icons.family_restroom), size: 15, color: cs.primary),
            label: Text('${_label(item.relation.kind)} : ${item.person!.name}', style: tt.labelMedium),
            onPressed: () => openPerson(context, state, item.person!),
          ),
        ]),
        const SizedBox(height: 5),
        Text(Strings.lang == 'ar' ? 'اضغط على الاسم لفتح الترجمة المرتبطة به.' : (Strings.lang == 'en' ? 'Tap a name to open the linked biography.' : 'Touchez un nom pour ouvrir sa biographie.'), style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
      ]),
    );
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
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(Icons.menu_book_rounded, color: cs.primary), const SizedBox(width: 8), Text(tr('biography'), style: tt.titleMedium?.copyWith(color: cs.primary))]),
              const SizedBox(height: 8),
              Text(person.bio, style: tt.bodyLarge?.copyWith(height: 1.68, fontFamily: 'serif')),
            ]),
          ),
        ),
        for (final section in person.bioSections) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withOpacity(.65)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(section.heading, style: tt.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              Text(section.body, style: tt.bodyMedium?.copyWith(height: 1.58)),
            ]),
          ),
        ],
        const SizedBox(height: 18),
        _FamilyLinks(state: state, person: person),
        const SizedBox(height: 18),
        Row(children: [Icon(Icons.timeline_rounded, color: cs.primary), const SizedBox(width: 8), Text(tr('related_events'), style: tt.titleMedium?.copyWith(color: cs.primary))]),
        const SizedBox(height: 6),
        if (events.isEmpty) Text(tr('no_related')),
        for (final e in events)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(precisionIcon(e.datePrecision), color: cs.primary),
              title: Text(e.title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.dateLabel, style: tt.labelSmall?.copyWith(color: cs.secondary)),
                const SizedBox(height: 4),
                Text(e.summary, maxLines: 4, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(height: 1.4)),
              ])),
              trailing: Icon(state.canOpenEvent(e) ? Icons.chevron_right : Icons.lock_outline),
              onTap: () => openEvent(context, state, e),
            ),
          ),
      ]),
    );
  }
}
