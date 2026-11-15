import 'package:flutter/material.dart';
import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import 'nav.dart';

class _FamilyNode {
  final String id;
  final List<String> spouses;
  final List<String> mothers;
  final List<_FamilyNode> children;
  const _FamilyNode(this.id, {this.spouses = const [], this.mothers = const [], this.children = const []});
}

// The lineage is intentionally stopped at Adnan: earlier chains are disputed.
const _tree = _FamilyNode('adnan', children: [
  _FamilyNode('maadd', children: [
    _FamilyNode('nizar', children: [
      _FamilyNode('mudar', children: [
        _FamilyNode('ilyas', children: [
          _FamilyNode('mudrika', children: [
            _FamilyNode('khuzayma', children: [
              _FamilyNode('kinana', children: [
                _FamilyNode('al_nadr', children: [
                  _FamilyNode('malik_ancestor', children: [
                    _FamilyNode('fihr', children: [
                      _FamilyNode('ghalib', children: [
                        _FamilyNode('luayy', children: [
                          _FamilyNode('kab', children: [
                            _FamilyNode('murrah', children: [
                              _FamilyNode('kilab', children: [
                                _FamilyNode('qusayy', children: [
                                  _FamilyNode('abd_manaf', children: [
                                    _FamilyNode('hashim', children: [
                                      _FamilyNode('abd_al_muttalib', children: [
                                        _FamilyNode('abdullah', spouses: ['aminah'], children: [
                                          _FamilyNode('muhammad', spouses: [
                                            'khadijah','sawda','aisha','hafsa','umm_salama',
                                            'zaynab_bint_jahsh','juwayriya','safiyya_bint_huyayy',
                                            'umm_habiba','maymuna','zaynab_bint_khuzayma'
                                          ], children: [
                                            _FamilyNode('qasim', mothers: ['khadijah']),
                                            _FamilyNode('zaynab_bint_muhammad', mothers: ['khadijah'], spouses: ['abu_al_as'], children: [_FamilyNode('umama', mothers: ['zaynab_bint_muhammad'])]),
                                            _FamilyNode('ruqayyah', mothers: ['khadijah'], spouses: ['uthman']),
                                            _FamilyNode('umm_kulthum', mothers: ['khadijah'], spouses: ['uthman']),
                                            _FamilyNode('abdullah_ibn_muhammad', mothers: ['khadijah']),
                                            _FamilyNode('fatimah_bint_muhammad', mothers: ['khadijah'], spouses: ['ali'], children: [_FamilyNode('hasan', mothers: ['fatimah_bint_muhammad']), _FamilyNode('husayn', mothers: ['fatimah_bint_muhammad'])]),
                                            _FamilyNode('ibrahim', mothers: ['mariya_al_qibtiyya']),
                                          ]),
                                        ]),
                                        _FamilyNode('abu_talib', spouses: ['fatimah_bint_asad'], children: [
                                          _FamilyNode('ali', mothers: ['fatimah_bint_asad']), _FamilyNode('jafar', mothers: ['fatimah_bint_asad'])
                                        ]),
                                        _FamilyNode('hamzah'),
                                        _FamilyNode('al_abbas'),
                                        _FamilyNode('abu_lahab'),
                                        _FamilyNode('al_harith'),
                                        _FamilyNode('safiyyah_bint_abd_al_muttalib'),
                                        _FamilyNode('umayma_bint_abd_al_muttalib', children: [
                                          _FamilyNode('zaynab_bint_jahsh'),
                                        ]),
                                      ]),
                                    ]),
                                  ]),
                                ]),
                              ]),
                            ]),
                          ]),
                        ]),
                      ]),
                    ]),
                  ]),
                ]),
              ]),
            ]),
          ]),
        ]),
      ]),
    ]),
  ]),
]);

class FamilyRelation {
  final String personId;
  final String kind;
  const FamilyRelation(this.personId, this.kind);
}

/// Relations familiales calculées à partir de l'arbre, puis complétées par les
/// liens documentés qui ne sont pas représentés dans la lignée principale.
/// Les relations sociales (ex. ancienne adoption) restent distinctes du sang.
List<FamilyRelation> familyRelationsFor(String personId) {
  final parents = <String, Set<String>>{};
  final children = <String, Set<String>>{};
  final spouses = <String, Set<String>>{};
  final all = <String>{};

  Set<String> bucket(Map<String, Set<String>> map, String id) =>
      map.putIfAbsent(id, () => <String>{});

  void addParent(String child, String parent) {
    if (child == parent) return;
    bucket(parents, child).add(parent);
    bucket(children, parent).add(child);
    all..add(child)..add(parent);
  }

  void addSpouse(String a, String b) {
    if (a == b) return;
    bucket(spouses, a).add(b);
    bucket(spouses, b).add(a);
    all..add(a)..add(b);
  }

  void collect(_FamilyNode node, {_FamilyNode? parent}) {
    all.add(node.id);
    if (parent != null) addParent(node.id, parent.id);
    for (final motherId in node.mothers) {
      addParent(node.id, motherId);
    }
    for (final spouseId in node.spouses) {
      addSpouse(node.id, spouseId);
    }
    for (final child in node.children) {
      collect(child, parent: node);
    }
  }

  collect(_tree);

  // Le nœud de Muhammad est enfant d'Abdullah ; Aminah est son autre parent.
  addParent('muhammad', 'aminah');
  // Liens de filiation connus, absents de la branche dessinée dans l'arbre.
  addParent('aisha', 'abu_bakr');
  addParent('hafsa', 'umar');
  addParent('umm_habiba', 'abu_sufyan');
  // Liens collatéraux explicitement documentés, absents de la seule lignée
  // verticale (cousins, parenté maternelle et liens sociaux non biologiques).
  const explicitKinship = <String, Map<String, List<String>>>{
    'muhammad': {
      'cousin': ['ali', 'jafar'],
      'former_adoptive': ['zayd'],
      'foster_parent': ['halimah'],
    },
    'ali': {'cousin': ['muhammad']},
    'jafar': {'cousin': ['muhammad']},
    'khadijah': {'cousin': ['waraqah']},
    'waraqah': {'cousin': ['khadijah']},
    'zaynab_bint_khuzayma': {'sibling': ['maymuna']},
    'maymuna': {'sibling': ['zaynab_bint_khuzayma']},
    'zayd': {'former_adoptive': ['muhammad']},
    'halimah': {'foster_child': ['muhammad']},
  };

  final result = <FamilyRelation>[];
  final seen = <String>{};
  void add(String id, String kind) {
    if (id == personId) return;
    final key = '$kind:$id';
    if (seen.add(key)) result.add(FamilyRelation(id, kind));
  }

  final personParents = parents[personId] ?? const <String>{};
  for (final id in personParents) add(id, 'parent');
  for (final id in children[personId] ?? const <String>{}) add(id, 'child');
  for (final id in spouses[personId] ?? const <String>{}) add(id, 'spouse');

  // Parenté par alliance : parents du conjoint et conjoints des enfants.
  for (final spouseId in spouses[personId] ?? const <String>{}) {
    for (final parentId in parents[spouseId] ?? const <String>{}) {
      add(parentId, 'in_law');
    }
  }
  for (final childId in children[personId] ?? const <String>{}) {
    for (final childSpouse in spouses[childId] ?? const <String>{}) {
      add(childSpouse, 'in_law');
    }
    for (final otherParent in parents[childId] ?? const <String>{}) {
      if (otherParent != personId) add(otherParent, 'co_parent');
    }
  }

  // Frères et sœurs : au moins un parent partagé, sans confondre les conjoints.
  for (final candidate in all) {
    if (candidate == personId) continue;
    final shared = (parents[candidate] ?? const <String>{})
        .intersection(personParents);
    if (shared.isNotEmpty) add(candidate, 'sibling');
  }

  // Grands-parents et petits-enfants, lorsque les deux générations sont dans
  // le corpus de l'application.
  for (final parentId in personParents) {
    for (final grandparent in parents[parentId] ?? const <String>{}) {
      add(grandparent, 'grandparent');
    }
  }
  for (final childId in children[personId] ?? const <String>{}) {
    for (final grandchild in children[childId] ?? const <String>{}) {
      add(grandchild, 'grandchild');
    }
  }

  // Oncles/tantes et cousins issus des frères/sœurs d'un parent.
  final parentSiblings = <String>{};
  for (final parentId in personParents) {
    for (final candidate in all) {
      if (candidate == parentId || candidate == personId) continue;
      if ((parents[candidate] ?? const <String>{})
          .intersection(parents[parentId] ?? const <String>{}).isNotEmpty) {
        parentSiblings.add(candidate);
      }
    }
  }
  for (final id in parentSiblings) add(id, 'uncle_aunt');
  for (final auntOrUncle in parentSiblings) {
    for (final cousin in children[auntOrUncle] ?? const <String>{}) {
      add(cousin, 'cousin');
    }
  }

  // Neveux et nièces : enfants des frères et sœurs.
  for (final sibling in result.where((r) => r.kind == 'sibling').toList()) {
    for (final id in children[sibling.personId] ?? const <String>{}) {
      add(id, 'niece_nephew');
    }
  }

  for (final entry in explicitKinship[personId]?.entries ?? const <MapEntry<String, List<String>>>[]) {
    for (final id in entry.value) {
      add(id, entry.key);
    }
  }

  return result;
}


String _collateralChipLabel(String id) {
  final cousin = id == 'ali' || id == 'jafar' || id == 'zaynab_bint_jahsh';
  final aunt = id == 'safiyyah_bint_abd_al_muttalib' || id == 'umayma_bint_abd_al_muttalib';
  if (Strings.lang == 'ar') return cousin ? 'قريب' : (aunt ? 'عمة' : 'عم');
  if (Strings.lang == 'en') return cousin ? 'cousin' : (aunt ? 'aunt' : 'uncle');
  return cousin ? 'cousin(e)' : (aunt ? 'tante' : 'oncle');
}

class FamilyTreeScreen extends StatefulWidget {
  final AppState state;
  const FamilyTreeScreen({super.key, required this.state});

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  final TransformationController _transform = TransformationController();
  final GlobalKey _viewerKey = GlobalKey();
  final GlobalKey _prophetKey = GlobalKey();
  bool _initialCenterScheduled = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _centerOnProphet() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final viewerObject = _viewerKey.currentContext?.findRenderObject();
      final prophetObject = _prophetKey.currentContext?.findRenderObject();
      if (viewerObject is! RenderBox || prophetObject is! RenderBox ||
          !viewerObject.hasSize || !prophetObject.hasSize) return;

      final point = prophetObject.localToGlobal(
        prophetObject.size.center(Offset.zero),
        ancestor: viewerObject,
      );
      const scale = 0.62;
      final dx = viewerObject.size.width / 2 - point.dx * scale;
      final dy = viewerObject.size.height / 2 - point.dy * scale;
      _transform.value = Matrix4.identity()
        ..translate(dx, dy)
        ..scale(scale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        if (!widget.state.hasEntitlement('family_tree')) {
          return Scaffold(
            appBar: AppBar(title: Text(tr('family_tree'))),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.account_tree_rounded, size: 64, color: cs.primary),
                  const SizedBox(height: 18),
                  Text(tr('family_tree_locked_title'), style: tt.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text(tr('family_tree_locked_body'), style: tt.bodyLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: () => openPaywall(context, widget.state),
                    icon: const Icon(Icons.lock_open_rounded),
                    label: Text(tr('family_tree_unlock')),
                  ),
                ]),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(tr('family_tree')),
            actions: [
              IconButton(
                tooltip: tr('family_tree_recenter'),
                onPressed: _centerOnProphet,
                icon: const Icon(Icons.center_focus_strong),
              ),
            ],
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [cs.primary.withOpacity(.10), cs.secondary.withOpacity(.08)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.secondary.withOpacity(.35)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.account_tree_rounded, color: cs.primary, size: 23),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tr('family_tree_intro'), style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.45))),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.secondary.withOpacity(.28)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    Strings.lang == 'ar' ? 'روابط القرابة الجانبية' : (Strings.lang == 'en' ? 'Collateral family links' : 'Liens de parenté collatéraux'),
                    style: tt.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final id in const ['ali', 'jafar', 'hamzah', 'al_abbas', 'safiyyah_bint_abd_al_muttalib', 'umayma_bint_abd_al_muttalib', 'zaynab_bint_jahsh'])
                        if (widget.state.repo.person(id) != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 7),
                            child: ActionChip(
                              visualDensity: VisualDensity.compact,
                              avatar: Icon(Icons.groups_outlined, size: 15, color: cs.primary),
                              label: Text(
                                '${widget.state.repo.person(id)!.name} · ${_collateralChipLabel(id)}',
                                style: tt.labelSmall,
                              ),
                              onPressed: () => openPerson(context, widget.state, widget.state.repo.person(id)!),
                            ),
                          ),
                    ]),
                  ),
                ]),
              ),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                if (!_initialCenterScheduled) {
                  _initialCenterScheduled = true;
                  _centerOnProphet();
                }
                return InteractiveViewer(
                  key: _viewerKey,
                  transformationController: _transform,
                  constrained: false,
                  minScale: .35,
                  maxScale: 2.5,
                  boundaryMargin: const EdgeInsets.all(120),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 18, 28, 40),
                    child: _Branch(state: widget.state, node: _tree, prophetKey: _prophetKey),
                  ),
                );
              }),
            ),
          ]),
        );
      },
    );
  }
}

class _Branch extends StatelessWidget {
  final AppState state;
  final _FamilyNode node;
  final GlobalKey? prophetKey;
  const _Branch({required this.state, required this.node, this.prophetKey});

  @override
  Widget build(BuildContext context) {
    final person = state.repo.person(node.id);
    if (person == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Material(
        key: node.id == 'muhammad' ? prophetKey : null,
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: node.id == 'muhammad' ? 5 : 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => openPerson(context, state, person),
          child: Container(width: 194, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cs.surface, cs.surfaceContainerLow]),
              border: Border.all(color: node.id == 'muhammad' ? cs.secondary : cs.outlineVariant, width: node.id == 'muhammad' ? 1.8 : 1.0),
            ),
            child: Column(children: [
              if (node.id == 'muhammad') Icon(Icons.auto_awesome, color: cs.secondary, size: 17),
              Text(person.name, textAlign: TextAlign.center, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              if (person.nameAr.isNotEmpty && Strings.lang != 'ar')
                Directionality(textDirection: TextDirection.rtl, child: Text(person.nameAr,
                  textAlign: TextAlign.center, style: tt.bodySmall?.copyWith(color: cs.primary))),
              const SizedBox(height: 3),
              Text(person.role, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, height: 1.15)),
              const SizedBox(height: 4),
              Text(Strings.lang == 'ar' ? 'عرض السيرة' : (Strings.lang == 'en' ? 'Open biography' : 'Ouvrir la biographie'),
                style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
      if (node.spouses.isNotEmpty) ...[
        const SizedBox(height: 7),
        Wrap(spacing: 5, runSpacing: 5, alignment: WrapAlignment.center,
          children: node.spouses.map((id) {
            final spouse = state.repo.person(id);
            if (spouse == null) return const SizedBox.shrink();
            return ActionChip(
              visualDensity: VisualDensity.compact,
              avatar: Icon(Icons.favorite_border, size: 14, color: cs.secondary),
              label: Text(spouse.name, style: tt.labelSmall),
              onPressed: () => openPerson(context, state, spouse),
            );
          }).toList()),
      ],
      if (node.mothers.isNotEmpty) ...[
        const SizedBox(height: 6),
        Wrap(spacing: 5, children: node.mothers.map((id) {
          final mother = state.repo.person(id);
          if (mother == null) return const SizedBox.shrink();
          return ActionChip(
            visualDensity: VisualDensity.compact,
            avatar: Icon(Icons.family_restroom, size: 14, color: cs.secondary),
            label: Text(mother.name, style: tt.labelSmall),
            onPressed: () => openPerson(context, state, mother),
          );
        }).toList()),
      ],
      if (node.children.isNotEmpty) ...[
        Container(width: 1.5, height: 22, color: cs.outlineVariant),
        Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: node.children.map((child) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _Branch(state: state, node: child, prophetKey: prophetKey),
          )).toList()),
      ],
    ]);
  }
}
