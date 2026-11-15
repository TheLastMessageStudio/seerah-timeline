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
  final List<Section> bioSections;
  Person({required this.id, required this.name, required this.nameAr, required this.role, required this.bio, required this.free, this.bioSections = const []});
  factory Person.fromJson(Map<String, dynamic> j) => Person(
      id: j['id'], name: j['name'], nameAr: j['nameAr'] ?? '', role: j['role'], bio: j['bio'], free: j['free'] ?? false,
      bioSections: (j['bioSections'] as List? ?? const []).map((s) => Section(s['heading'] ?? '', s['body'] ?? '')).toList());
}

class Place {
  final String id, name, nameAr, description;
  final double lat, lon;
  final bool free;
  final String? imageUrl, imageAsset, imageCredit, imageLicense, imageLicenseUrl, imageSourceUrl, imageCaptionFr;
  final String? imageAssetCaptionFr, imageAssetCaptionEn, imageAssetCaptionAr;
  bool get hasImage => (imageAsset != null && imageAsset!.isNotEmpty) || (imageUrl != null && imageUrl!.isNotEmpty);
  Place({required this.id, required this.name, required this.nameAr, required this.description, required this.lat, required this.lon, required this.free, this.imageUrl, this.imageAsset, this.imageCredit, this.imageLicense, this.imageLicenseUrl, this.imageSourceUrl, this.imageCaptionFr, this.imageAssetCaptionFr, this.imageAssetCaptionEn, this.imageAssetCaptionAr});
  factory Place.fromJson(Map<String, dynamic> j) => Place(
      id: j['id'],
      name: j['name'],
      nameAr: j['nameAr'] ?? '',
      description: j['description'],
      lat: (j['lat'] as num).toDouble(),
      lon: (j['lon'] as num).toDouble(),
      free: j['free'] ?? false,
      imageUrl: j['imageUrl'], imageAsset: j['imageAsset'], imageCredit: j['imageCredit'], imageLicense: j['imageLicense'],
      imageLicenseUrl: j['imageLicenseUrl'], imageSourceUrl: j['imageSourceUrl'], imageCaptionFr: j['imageCaptionFr'],
      imageAssetCaptionFr: j['imageAssetCaptionFr'], imageAssetCaptionEn: j['imageAssetCaptionEn'], imageAssetCaptionAr: j['imageAssetCaptionAr']);
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


/// Ouvrage de la bibliothèque intégrée. Le texte complet peut être ajouté
/// ultérieurement sans modifier le modèle des événements existants.
class Book {
  final String id, title, titleAr, author, description, edition, language, availability;
  final String? sourceUrl, rightsNote, pdfUrl, secondarySourceUrl;

  Book({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.author,
    required this.description,
    required this.edition,
    required this.language,
    required this.availability,
    this.sourceUrl,
    this.rightsNote,
    this.pdfUrl,
    this.secondarySourceUrl,
  });

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        id: j['id'],
        title: j['title'] ?? '',
        titleAr: j['titleAr'] ?? '',
        author: j['author'] ?? '',
        description: j['description'] ?? '',
        edition: j['edition'] ?? '',
        language: j['language'] ?? 'ar',
        availability: j['availability'] ?? 'metadata_only',
        sourceUrl: j['sourceUrl'],
        rightsNote: j['rightsNote'],
        pdfUrl: j['pdfUrl'],
        secondarySourceUrl: j['secondarySourceUrl'],
      );
}


/// Passage d'un ouvrage numérisé. Les pages sont celles de l'édition indiquée
/// dans Book.edition ; elles restent nulles tant que cette édition n'est pas
/// vérifiée. Le contenu est fourni par assets/data/book_passages.json.
class BookPassage {
  final String id, bookId, title, titleAr, text, chapterId;
  final String? titleEn, textEn, textAr, chapterTitle, chapterTitleAr, chapterTitleEn;
  String titleFor(String lang) => lang == 'ar' ? titleAr : (lang == 'en' ? (titleEn ?? title) : title);
  String textFor(String lang) => lang == 'ar' ? (textAr ?? text) : (lang == 'en' ? (textEn ?? text) : text);
  final int? volume, pageStart, pageEnd;
  final List<String> eventIds;

  BookPassage({
    required this.id,
    required this.bookId,
    required this.title,
    required this.titleAr,
    required this.text,
    required this.chapterId,
    this.titleEn,
    this.textEn,
    this.textAr,
    this.chapterTitleEn,
    this.chapterTitle,
    this.chapterTitleAr,
    this.volume,
    required this.pageStart,
    required this.pageEnd,
    required this.eventIds,
  });

  factory BookPassage.fromJson(Map<String, dynamic> j) => BookPassage(
        id: j['id'],
        bookId: j['bookId'],
        title: j['title'] ?? '',
        titleAr: j['titleAr'] ?? '',
        text: j['text'] ?? '',
        chapterId: j['chapterId'] ?? '',
        titleEn: j['titleEn'], textEn: j['textEn'], textAr: j['textAr'],
        chapterTitleEn: j['chapterTitleEn'],
        chapterTitle: j['chapterTitle'],
        chapterTitleAr: j['chapterTitleAr'],
        volume: j['volume'],
        pageStart: j['pageStart'],
        pageEnd: j['pageEnd'],
        eventIds: List<String>.from(j['eventIds'] ?? const []),
      );
}
