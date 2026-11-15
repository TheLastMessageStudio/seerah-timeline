class Period {
  final String id, title, intro;
  final bool free;
  Period({required this.id, required this.title, required this.intro, required this.free});
  factory Period.fromJson(Map<String, dynamic> j) => Period(
      id: j['id'], title: j['title'], intro: j['intro'], free: j['free'] ?? false);
}

class Section {
  final String heading, body;
  Section(this.heading, this.body);
}

class Source {
  final String id, title, description;
  Source({required this.id, required this.title, required this.description});
  factory Source.fromJson(Map<String, dynamic> j) =>
      Source(id: j['id'], title: j['title'], description: j['description']);
}

class Person {
  final String id, name, nameAr, role, bio;
  final bool free;
  Person({required this.id, required this.name, required this.nameAr, required this.role, required this.bio, required this.free});
  factory Person.fromJson(Map<String, dynamic> j) => Person(
      id: j['id'], name: j['name'], nameAr: j['nameAr'] ?? '', role: j['role'], bio: j['bio'], free: j['free'] ?? false);
}

class Place {
  final String id, name, nameAr, description;
  final double lat, lon;
  final bool free;
  Place({required this.id, required this.name, required this.nameAr, required this.description, required this.lat, required this.lon, required this.free});
  factory Place.fromJson(Map<String, dynamic> j) => Place(
      id: j['id'],
      name: j['name'],
      nameAr: j['nameAr'] ?? '',
      description: j['description'],
      lat: (j['lat'] as num).toDouble(),
      lon: (j['lon'] as num).toDouble(),
      free: j['free'] ?? false);
}

class Event {
  final String id, periodId, title, titleAr, dateLabel, datePrecision, summary, status;
  final String? reliabilityNote;
  final int sortOrder;
  final List<Section> content;
  final List<String> personIds, placeIds, sourceIds, references;

  Event({
    required this.id,
    required this.periodId,
    required this.title,
    required this.titleAr,
    required this.dateLabel,
    required this.datePrecision,
    required this.summary,
    required this.status,
    required this.reliabilityNote,
    required this.sortOrder,
    required this.content,
    required this.personIds,
    required this.placeIds,
    required this.sourceIds,
    required this.references,
  });

  factory Event.fromJson(Map<String, dynamic> j) => Event(
        id: j['id'],
        periodId: j['periodId'],
        title: j['title'],
        titleAr: j['titleAr'] ?? '',
        dateLabel: j['dateLabel'],
        datePrecision: j['datePrecision'],
        summary: j['summary'],
        status: j['status'] ?? 'draft',
        reliabilityNote: j['reliabilityNote'],
        sortOrder: j['sortOrder'],
        content: (j['content'] as List).map((c) => Section(c['heading'], c['body'])).toList(),
        personIds: List<String>.from(j['personIds'] ?? []),
        placeIds: List<String>.from(j['placeIds'] ?? []),
        sourceIds: List<String>.from(j['sourceIds'] ?? []),
        references: List<String>.from(j['references'] ?? []),
      );
}
