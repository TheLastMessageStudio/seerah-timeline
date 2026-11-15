import 'package:flutter_test/flutter_test.dart';
import 'package:seerah_timeline/features/family_tree_screen.dart';

Set<String> _ids(String personId, String kind) => familyRelationsFor(personId)
    .where((relation) => relation.kind == kind)
    .map((relation) => relation.personId)
    .toSet();

void main() {
  test('Ali et Jaafar sont visibles comme cousins du Prophète', () {
    expect(_ids('muhammad', 'cousin'), containsAll(['ali', 'jafar', 'zaynab_bint_jahsh']));
    expect(_ids('muhammad', 'uncle_aunt'), contains('umayma_bint_abd_al_muttalib'));
    expect(_ids('umayma_bint_abd_al_muttalib', 'child'), contains('zaynab_bint_jahsh'));
    expect(_ids('umayma_bint_abd_al_muttalib', 'sibling'), contains('abdullah'));
    expect(_ids('ali', 'cousin'), contains('muhammad'));
    expect(_ids('jafar', 'cousin'), contains('muhammad'));
  });

  test('les oncles et la tante paternels sont calculés depuis Abd al-Muttalib', () {
    expect(_ids('muhammad', 'uncle_aunt'), containsAll([
      'abu_talib', 'hamzah', 'al_abbas', 'abu_lahab', 'al_harith',
      'safiyyah_bint_abd_al_muttalib',
    ]));
  });

  test('les liens de filiation et de mariage sont réciproques', () {
    expect(_ids('ali', 'sibling'), contains('jafar'));
    expect(_ids('ali', 'spouse'), contains('fatimah_bint_muhammad'));
    expect(_ids('fatimah_bint_muhammad', 'spouse'), contains('ali'));
    expect(_ids('ali', 'child'), containsAll(['hasan', 'husayn']));
    expect(_ids('aisha', 'parent'), contains('abu_bakr'));
    expect(_ids('hafsa', 'parent'), contains('umar'));
    expect(_ids('umm_habiba', 'parent'), contains('abu_sufyan'));
    expect(_ids('muhammad', 'in_law'), contains('abu_sufyan'));
    expect(_ids('abu_sufyan', 'in_law'), contains('muhammad'));
    expect(_ids('muhammad', 'co_parent'), contains('mariya_al_qibtiyya'));
    expect(_ids('mariya_al_qibtiyya', 'co_parent'), contains('muhammad'));
  });

  test('les liens de parenté collatérale et de protection restent qualifiés', () {
    expect(_ids('khadijah', 'cousin'), contains('waraqah'));
    expect(_ids('zaynab_bint_khuzayma', 'sibling'), contains('maymuna'));
    expect(_ids('muhammad', 'former_adoptive'), contains('zayd'));
    expect(_ids('muhammad', 'foster_parent'), contains('halimah'));
    expect(_ids('halimah', 'foster_child'), contains('muhammad'));
  });
}
