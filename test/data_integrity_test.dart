import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:seerah_timeline/data/models.dart';
import 'package:seerah_timeline/core/arabic_search.dart';

List<dynamic> _list(String f) =>
    jsonDecode(File('assets/data/$f').readAsStringSync()) as List<dynamic>;
Map<String, dynamic> _tr(String f, [String lang = 'fr']) =>
    jsonDecode(File('assets/data/i18n/$lang/$f').readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> _merged(String f) {
  final tr = _tr(f);
  return _list(f).map((x) {
    final m = Map<String, dynamic>.from(x as Map);
    m.addAll(Map<String, dynamic>.from(tr[m['id']] as Map));
    return m;
  }).toList();
}

void main() {
  test('normalisation de recherche arabe sans modifier les textes source', () {
    expect(normalizeSearchText('إِبْنُ هِشَامٍ'), normalizeSearchText('ابن هشام'));
    expect(normalizeSearchText('السيرة النبوية'), normalizeSearchText('السِّيرَةُ النَّبَوِيَّة'));
  });

  final periods = _merged('periods.json');
  final events = _merged('events.json');
  final persons = _merged('persons.json');
  final places = _merged('places.json');
  final sources = _merged('sources.json');
  final books = _merged('books.json');
  final evidence = _list('event_evidence.json');
  final passages = _list('book_passages.json');
  Set<String> ids(List<Map<String, dynamic>> l) => l.map((e) => e['id'] as String).toSet();

  test('les illustrations locales sont embarquées et légendées en trois langues', () {
    final illustrated = places.where((p) => p['imageAsset'] != null).toList();
    expect(illustrated.length, 6);
    for (final p in illustrated) {
      expect(File(p['imageAsset'] as String).existsSync(), isTrue, reason: p['id']);
      expect((p['imageAssetCaptionFr'] as String).isNotEmpty, isTrue, reason: p['id']);
      expect((p['imageAssetCaptionEn'] as String).isNotEmpty, isTrue, reason: p['id']);
      expect((p['imageAssetCaptionAr'] as String).isNotEmpty, isTrue, reason: p['id']);
    }
  });

  test('tous les modèles se chargent', () {
    expect(periods.map(Period.fromJson).length, periods.length);
    expect(events.map(Event.fromJson).length, events.length);
    expect(persons.map(Person.fromJson).length, persons.length);
    expect(places.map(Place.fromJson).length, places.length);
    expect(sources.map(Source.fromJson).length, sources.length);
    expect(books.map(Book.fromJson).length, books.length);
    expect(passages.map((p) => BookPassage.fromJson(Map<String, dynamic>.from(p as Map))).length, passages.length);
  });

  test('catalogue Ibn Hisham, livres de Sira et collections de hadiths', () {
    final ibn = books.firstWhere((b) => b['id'] == 'ibn_hisham');
    expect(ibn['availability'], 'scan_only');
    expect((ibn['sourceUrl'] as String).startsWith('https://'), isTrue);
    expect((ibn['rightsNote'] as String).isNotEmpty, isTrue);
    final bukhari = books.firstWhere((b) => b['id'] == 'bukhari');
    final muslim = books.firstWhere((b) => b['id'] == 'muslim');
    expect(bukhari['availability'], 'hadith_import_required');
    expect(muslim['availability'], 'hadith_import_required');
    expect(bukhari['sourceUrl'], 'https://github.com/Jaguar16/open-hadith-data');
    expect(muslim['sourceUrl'], 'https://github.com/Jaguar16/open-hadith-data');
    expect(books.where((b) => b['availability'] == 'hadith_import_required').length, 17);
    expect(books.any((b) => b['id'] == 'quran_ar'), isTrue);
    expect(books.any((b) => b['id'] == 'waqidi_maghazi'), isTrue);
    expect(books.any((b) => b['id'] == 'ibn_sad_tabaqat'), isTrue);
    expect(persons.length, 68);
    expect(persons.any((p) => p['id'] == 'zaynab_bint_khuzayma'), isTrue);
    expect(persons.any((p) => p['id'] == 'umayma_bint_abd_al_muttalib'), isTrue);
    expect(persons.any((p) => p['id'] == 'abu_sufyan'), isTrue);
  });

  test('références hadith et Coran ajoutées avec leur portée exacte', () {
    final birth = events.firstWhere((e) => e['id'] == 'birth_prophet');
    final shepherd = events.firstWhere((e) => e['id'] == 'shepherd');
    final revelation = events.firstWhere((e) => e['id'] == 'first_revelation');
    final death = events.firstWhere((e) => e['id'] == 'death_prophet');
    final safa = events.firstWhere((e) => e['id'] == 'safa_call');
    final adhan = events.firstWhere((e) => e['id'] == 'adhan');
    final qibla = events.firstWhere((e) => e['id'] == 'qibla_change');
    expect(birth['references'], contains('Sahih Muslim 1162e — atteste le lundi, sans fixer le mois, le quantième ou l’année.'));
    expect(shepherd['references'], contains('Sahih al-Bukhari 2262 — récit du Prophète ﷺ gardant les moutons à Makkah.'));
    expect(revelation['references'], contains('Sahih al-Bukhari 3 — début de la révélation dans la grotte de Hira.'));
    expect(revelation['references'], contains("Coran 96:1–5 — premiers versets de la sourate Al-'Alaq."));
    expect(death['references'], contains('Sahih al-Bukhari 5217 — décès dans la demeure de ʿAisha.'));
    expect(death['datePrecision'], 'disputed');
    expect(safa['references'], contains('Sahih al-Bukhari 4770 — appel sur al-Safâ après la révélation de 26:214 ; portée limitée au récit du hadith.'));
    expect(adhan['references'], contains('Sahih al-Bukhari 604 — établissement de l’appel à la prière à Médine et ordre donné à Bilâl ; sans date précise.'));
    expect(qibla['references'], contains('Coran 2:144 — ordre de se tourner vers la Mosquée sacrée ; la chronologie détaillée demande un recoupement distinct.'));
    expect(evidence.cast<Map>().any((x) => x['eventId'] == 'fatrah' && x['reference'].toString().startsWith('4 ·')), isTrue);
    expect(evidence.cast<Map>().any((x) => x['eventId'] == 'five_prayers' && x['reference'].toString().startsWith('349 ·')), isTrue);
    expect(evidence.cast<Map>().any((x) => x['eventId'] == 'suraqah' && x['reference'].toString().startsWith('3908 ·')), isTrue);
    expect(evidence.cast<Map>().any((x) => x['eventId'] == 'muakhat' && x['reference'].toString().startsWith('3780 ·')), isTrue);
    expect(evidence.cast<Map>().any((x) => x['eventId'] == 'uqbah_abu_bakr' && x['reference'].toString().startsWith('3678 ·')), isTrue);
    expect(evidence.cast<Map>().any((x) => x['eventId'] == 'dhat_riqa' && x['reference'].toString().startsWith('1816 ·')), isTrue);
    expect(evidence.cast<Map>().any((x) => x['eventId'] == 'second_aqabah' && x['reference'].toString().startsWith('3892 ·')), isTrue);
    expect(evidence.cast<Map>().any((x) => x['eventId'] == 'siege_taif' && x['reference'].toString().startsWith('4324 ·')), isTrue);
    expect(evidence.cast<Map>().any((x) => x['eventId'] == 'banu_mustaliq' && x['reference'].toString().startsWith('4141 ·')), isTrue);
  });


  test('les preuves sont lisibles en FR/EN/AR et leurs liens sont valides', () {
    expect(evidence.length, 51);
    expect(evidence.where((x) => (x as Map)['kind'] == 'hadith').length, 42);
    expect(evidence.where((x) => (x as Map)['kind'] == 'quran').length, 9);
    for (final item in evidence) {
      final m = Map<String, dynamic>.from(item as Map);
      expect((m['textArSummary'] as String).trim().isNotEmpty, isTrue, reason: m['eventId']);
      expect((m['textFr'] as String).trim().isNotEmpty, isTrue, reason: m['eventId']);
      expect((m['textEn'] as String).trim().isNotEmpty, isTrue, reason: m['eventId']);
      expect((m['noteAr'] as String).trim().isNotEmpty, isTrue, reason: m['eventId']);
      expect((m['url'] as String).startsWith('https://'), isTrue, reason: m['eventId']);
      if ((m['textAr'] as String? ?? '').isNotEmpty) {
        expect((m['textAr'] as String).length > 30, isTrue, reason: m['eventId']);
      }
    }
  });

  test('identifiants uniques', () {
    for (final l in [periods, events, persons, places, sources, books]) {
      expect(ids(l).length, l.length);
    }
    expect(ids(passages.map((p) => Map<String, dynamic>.from(p as Map)).toList()).length, passages.length);
  });

  test('événements dans l\'ordre chronologique (sortOrder strictement croissant)', () {
    final orders = events.map((e) => e['sortOrder'] as int).toList();
    for (var i = 1; i < orders.length; i++) {
      expect(orders[i] > orders[i - 1], isTrue, reason: 'ordre cassé à ${events[i]['id']}');
    }
  });

  test('relations valides', () {
    final p = ids(persons), pl = ids(places), pe = ids(periods), so = ids(sources), bo = ids(books);
    for (final e in events) {
      expect(pe.contains(e['periodId']), isTrue, reason: e['id']);
      for (final x in e['personIds']) { expect(p.contains(x), isTrue, reason: '${e['id']} -> $x'); }
      for (final x in e['placeIds']) { expect(pl.contains(x), isTrue, reason: '${e['id']} -> $x'); }
      for (final x in e['sourceIds']) { expect(so.contains(x), isTrue, reason: '${e['id']} -> $x'); }
    }
    for (final raw in passages) {
      final passage = Map<String, dynamic>.from(raw as Map);
      expect(bo.contains(passage['bookId']), isTrue, reason: passage['id']);
      for (final eventId in (passage['eventIds'] ?? const [])) {
        expect(events.any((e) => e['id'] == eventId), isTrue, reason: '${passage['id']} -> $eventId');
      }
    }
  });

  test('précision de date et statut valides', () {
    for (final e in events) {
      expect(['exact', 'approximate', 'disputed'], contains(e['datePrecision']), reason: e['id']);
      expect(['draft', 'reviewed', 'published'], contains(e['status']), reason: e['id']);
      expect(['reviewed', 'needs_corroboration'], contains(e['verificationStatus']), reason: e['id']);
    }
  });

  test('chaque événement a un résumé et des sources', () {
    for (final e in events) {
      expect((e['summary'] as String).isNotEmpty, isTrue, reason: e['id']);
      expect((e['sourceIds'] as List).isNotEmpty, isTrue, reason: e['id']);
    }
  });

  test('fr, en et ar : traduction complète de tous les contenus', () {
    for (final lang in ['fr', 'en', 'ar']) {
      for (final f in ['periods.json', 'events.json', 'persons.json', 'places.json', 'sources.json', 'books.json']) {
        final tr = _tr(f, lang);
        for (final item in _list(f)) {
          final id = (item as Map)['id'];
          expect(tr.containsKey(id), isTrue, reason: '[$lang] $f -> $id');
        }
      }
      final booksTr = _tr('books.json', lang);
      expect((booksTr['ibn_hisham'] as Map)['rightsNote'], isA<String>());
      final peopleTr = _tr('persons.json', lang);
      for (final person in peopleTr.entries) {
        expect((person.value as Map)['bioSections'].length, 3, reason: '[$lang] ${person.key} sections biographiques');
      }
      final ev = _tr('events.json', lang);
      for (final e in ev.entries) {
        final m = e.value as Map;
        expect((m['title'] as String).isNotEmpty, isTrue, reason: '[$lang] ${e.key} titre');
        expect((m['summary'] as String).isNotEmpty, isTrue, reason: '[$lang] ${e.key} résumé');
        expect((m['content'] as List).length >= 3, isTrue, reason: '[$lang] ${e.key} contenu enrichi');
        expect((m['reliabilityNote'] as String).isNotEmpty, isTrue, reason: '[$lang] ${e.key} note de sources');
      }
    }
  });
  test('préparation éditoriale 1.0 : toutes les fiches et biographies ont une structure homogène', () {
    for (final lang in ['fr', 'en', 'ar']) {
      final eventTranslations = _tr('events.json', lang);
      for (final entry in eventTranslations.entries) {
        final item = Map<String, dynamic>.from(entry.value as Map);
        final summary = item['summary'] as String;
        expect(summary.trim().split(RegExp(r'\s+')).length >= 45, isTrue, reason: '[$lang] ${entry.key} résumé trop court');
        final content = (item['content'] as List).map((x) => Map<String, dynamic>.from(x as Map)).toList();
        final headings = content.where((x) => !(x['heading'] as String).toLowerCase().contains('date') && !(x['heading'] as String).toLowerCase().contains('chronolog')).take(4).toList();
        expect(headings.length, 4, reason: '[$lang] ${entry.key} sections');
        for (final section in headings) {
          expect((section['body'] as String).trim().isNotEmpty, isTrue, reason: '[$lang] ${entry.key} section vide');
        }
      }
      final personTranslations = _tr('persons.json', lang);
      for (final entry in personTranslations.entries) {
        final item = Map<String, dynamic>.from(entry.value as Map);
        expect((item['bioSections'] as List).length, 3, reason: '[$lang] ${entry.key} biographie structurée');
      }
    }
  });

}
