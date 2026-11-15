import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:seerah_timeline/data/models.dart';

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
  final periods = _merged('periods.json');
  final events = _merged('events.json');
  final persons = _merged('persons.json');
  final places = _merged('places.json');
  final sources = _merged('sources.json');
  Set<String> ids(List<Map<String, dynamic>> l) => l.map((e) => e['id'] as String).toSet();

  test('tous les modèles se chargent', () {
    expect(periods.map(Period.fromJson).length, periods.length);
    expect(events.map(Event.fromJson).length, events.length);
    expect(persons.map(Person.fromJson).length, persons.length);
    expect(places.map(Place.fromJson).length, places.length);
    expect(sources.map(Source.fromJson).length, sources.length);
  });

  test('identifiants uniques', () {
    for (final l in [periods, events, persons, places, sources]) {
      expect(ids(l).length, l.length);
    }
  });

  test('événements dans l\'ordre chronologique (sortOrder strictement croissant)', () {
    final orders = events.map((e) => e['sortOrder'] as int).toList();
    for (var i = 1; i < orders.length; i++) {
      expect(orders[i] > orders[i - 1], isTrue, reason: 'ordre cassé à ${events[i]['id']}');
    }
  });

  test('relations valides', () {
    final p = ids(persons), pl = ids(places), pe = ids(periods), so = ids(sources);
    for (final e in events) {
      expect(pe.contains(e['periodId']), isTrue, reason: e['id']);
      for (final x in e['personIds']) { expect(p.contains(x), isTrue, reason: '${e['id']} -> $x'); }
      for (final x in e['placeIds']) { expect(pl.contains(x), isTrue, reason: '${e['id']} -> $x'); }
      for (final x in e['sourceIds']) { expect(so.contains(x), isTrue, reason: '${e['id']} -> $x'); }
    }
  });

  test('précision de date et statut valides', () {
    for (final e in events) {
      expect(['exact', 'approximate', 'disputed'], contains(e['datePrecision']), reason: e['id']);
      expect(['draft', 'reviewed'], contains(e['status']), reason: e['id']);
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
      for (final f in ['periods.json', 'events.json', 'persons.json', 'places.json', 'sources.json']) {
        final tr = _tr(f, lang);
        for (final item in _list(f)) {
          final id = (item as Map)['id'];
          expect(tr.containsKey(id), isTrue, reason: '[$lang] $f -> $id');
        }
      }
      final ev = _tr('events.json', lang);
      for (final e in ev.entries) {
        final m = e.value as Map;
        expect((m['title'] as String).isNotEmpty, isTrue, reason: '[$lang] ${e.key} titre');
        expect((m['summary'] as String).isNotEmpty, isTrue, reason: '[$lang] ${e.key} résumé');
        expect((m['content'] as List).length, 2, reason: '[$lang] ${e.key} contenu');
      }
    }
  });
}
