import 'dart:convert';
import 'package:flutter/services.dart';
import 'models.dart';

class Repository {
  final List<Period> periods;
  final List<Event> events;
  final List<Person> persons;
  final List<Place> places;
  final List<Source> sources;

  Repository(this.periods, this.events, this.persons, this.places, this.sources);

  static Future<List<dynamic>> _list(String f) async =>
      jsonDecode(await rootBundle.loadString('assets/data/$f')) as List<dynamic>;

  /// Traductions : assets/data/i18n/<lang>/<fichier>, avec repli sur le français.
  static Future<Map<String, dynamic>> _tr(String lang, String f) async {
    for (final l in [lang, 'fr']) {
      try {
        return jsonDecode(await rootBundle.loadString('assets/data/i18n/$l/$f'))
            as Map<String, dynamic>;
      } catch (_) {}
    }
    return {};
  }

  static Future<List<Map<String, dynamic>>> _merged(String f, String lang) async {
    final base = await _list(f);
    final tr = await _tr(lang, f);
    return base.map((x) {
      final m = Map<String, dynamic>.from(x as Map);
      final t = tr[m['id']];
      if (t is Map) m.addAll(Map<String, dynamic>.from(t));
      return m;
    }).toList();
  }

  static Future<Repository> load({String lang = 'fr'}) async {
    final p = await _merged('periods.json', lang);
    final e = await _merged('events.json', lang);
    final pe = await _merged('persons.json', lang);
    final pl = await _merged('places.json', lang);
    final s = await _merged('sources.json', lang);
    return Repository(
      p.map(Period.fromJson).toList(),
      e.map(Event.fromJson).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      pe.map(Person.fromJson).toList(),
      pl.map(Place.fromJson).toList(),
      s.map(Source.fromJson).toList(),
    );
  }

  Period? period(String id) {
    for (final x in periods) {
      if (x.id == id) return x;
    }
    return null;
  }

  Event? event(String id) {
    for (final x in events) {
      if (x.id == id) return x;
    }
    return null;
  }

  Person? person(String id) {
    for (final x in persons) {
      if (x.id == id) return x;
    }
    return null;
  }

  Place? place(String id) {
    for (final x in places) {
      if (x.id == id) return x;
    }
    return null;
  }

  Source? source(String id) {
    for (final x in sources) {
      if (x.id == id) return x;
    }
    return null;
  }

  List<Event> eventsOfPeriod(String id) => events.where((e) => e.periodId == id).toList();
  List<Event> eventsOfPerson(String id) => events.where((e) => e.personIds.contains(id)).toList();
  List<Event> eventsOfPlace(String id) => events.where((e) => e.placeIds.contains(id)).toList();

  Event? neighbor(Event e, int delta) {
    final i = events.indexWhere((x) => x.id == e.id) + delta;
    return (i >= 0 && i < events.length) ? events[i] : null;
  }
}
