import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../core/widgets.dart';
import '../core/place_image.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'nav.dart';

const _minLat = 10.5, _maxLat = 31.0, _minLon = 32.0, _maxLon = 58.0;
const _africaCoast = [
  [30.5, 32.0], [10.5, 32.0], [10.5, 41.0], [12.5, 42.5],
  [15.0, 40.8], [18.0, 38.0], [21.0, 36.5], [23.5, 35.7],
  [25.5, 35.5], [27.4, 35.0], [28.7, 34.8], [30.0, 34.6],
];
const _arabianPeninsula = [
  [30.0, 34.8], [28.7, 35.2], [27.4, 36.0], [25.5, 36.8],
  [23.5, 37.0], [21.0, 38.0], [18.0, 40.0], [15.0, 42.5],
  [12.5, 43.4], [12.0, 45.0], [13.2, 48.0], [16.0, 52.0],
  [18.5, 55.0], [22.0, 57.0], [25.5, 56.5], [27.0, 53.0],
  [29.0, 50.0], [29.5, 47.0], [29.0, 44.0], [30.0, 40.0],
];

// La carte affiche des villes/regions seulement. Les sites proches sont regroupés
// sous la ville de référence pour éviter une constellation de marqueurs de lieux.
const _cityGroups = <String, List<String>>{
  'makkah': ['makkah', 'jabal_al_nur', 'thawr', 'mina', 'hudaybiyyah', 'arafat', 'dar_al_arqam', 'safa_marwa', 'muzdalifah'],
  'madinah': ['madinah', 'quba', 'uhud', 'qiblatayn', 'masjid_nabawi', 'khandaq'],
  'taif': ['taif'], 'badr': ['badr'], 'khaybar': ['khaybar'],
  'abyssinia': ['abyssinia'], 'al_abwa': ['al_abwa'], 'hunayn': ['hunayn'], 'wadi_al_qura': ['wadi_al_qura'], 'mutah': ['mutah'], 'tabuk': ['tabuk'],
};

class PlacesScreen extends StatefulWidget {
  final AppState state;
  const PlacesScreen({super.key, required this.state});
  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> with SingleTickerProviderStateMixin {
  final TransformationController ctrl = TransformationController();
  String? selectedCityId;
  Size _mapSize = const Size(1, 1);
  late final AnimationController _zoomAnimation = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 420));
  Animation<Matrix4>? _zoomTween;

  @override
  void dispose() {
    _zoomAnimation.dispose();
    ctrl.dispose();
    super.dispose();
  }

  Place? _cityPlace(String id) {
    for (final p in widget.state.repo.places) { if (p.id == id) return p; }
    return null;
  }

  List<Event> _eventsForCity(String id) {
    final ids = _cityGroups[id] ?? [id];
    return widget.state.repo.events.where((e) => e.placeIds.any(ids.contains)).toList()
      ..sort((a,b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Offset _position(Size size, double lat, double lon) => Offset(
    (lon - _minLon) / (_maxLon - _minLon) * size.width,
    (_maxLat - lat) / (_maxLat - _minLat) * size.height,
  );

  // Déplace les étiquettes proches les unes des autres tout en gardant un
  // trait discret vers la coordonnée réelle de la ville.
  Map<String, Offset> _cityLabelLayout(Size size, List<String> ids) {
    const w = 100.0, h = 34.0, pad = 5.0;
    final result = <String, Offset>{};
    for (var i = 0; i < ids.length; i++) {
      final p = _cityPlace(ids[i]);
      if (p == null) continue;
      final anchor = _position(size, p.lat, p.lon);
      final side = i.isEven ? 1.0 : -1.0;
      result[ids[i]] = Offset(
        (anchor.dx + (i.isEven ? 12 : -w - 12)).clamp(2.0, size.width - w - 2).toDouble(),
        (anchor.dy + side * (i % 3 == 0 ? 12 : 22) - h / 2).clamp(2.0, size.height - h - 2).toDouble(),
      );
    }
    for (var pass = 0; pass < 36; pass++) {
      for (var i = 0; i < ids.length; i++) {
        final aId = ids[i];
        if (!result.containsKey(aId)) continue;
        var a = result[aId]!;
        for (var j = i + 1; j < ids.length; j++) {
          final bId = ids[j];
          if (!result.containsKey(bId)) continue;
          var b = result[bId]!;
          final ox = (w + pad) - (a.dx - b.dx).abs();
          final oy = (h + pad) - (a.dy - b.dy).abs();
          if (ox > 0 && oy > 0) {
            if (oy <= ox) {
              final shift = oy / 2 + 2;
              final sign = b.dy >= a.dy ? 1.0 : -1.0;
              a = Offset(a.dx, (a.dy - sign * shift).clamp(2.0, size.height - h - 2).toDouble());
              b = Offset(b.dx, (b.dy + sign * shift).clamp(2.0, size.height - h - 2).toDouble());
            } else {
              final shift = ox / 2 + 2;
              final sign = b.dx >= a.dx ? 1.0 : -1.0;
              a = Offset((a.dx - sign * shift).clamp(2.0, size.width - w - 2).toDouble(), a.dy);
              b = Offset((b.dx + sign * shift).clamp(2.0, size.width - w - 2).toDouble(), b.dy);
            }
            result[aId] = a;
            result[bId] = b;
          }
        }
      }
    }
    return result;
  }

  void _selectCity(String id, Place place, Size size) {
    if (!widget.state.canOpenPlace(place)) {
      openPlace(context, widget.state, place);
      return;
    }
    setState(() => selectedCityId = id);
    final p = _position(size, place.lat, place.lon);
    const scale = 3.0;
    final target = Matrix4.identity()
      ..translate(size.width / 2 - p.dx * scale, size.height / 2 - p.dy * scale)
      ..scale(scale);
    _zoomAnimation.stop();
    _zoomTween = Matrix4Tween(begin: ctrl.value, end: target).animate(
      CurvedAnimation(parent: _zoomAnimation, curve: Curves.easeInOutCubic));
    _zoomAnimation
      ..removeListener(_applyZoom)
      ..addListener(_applyZoom)
      ..forward(from: 0);
  }

  void _applyZoom() { final a = _zoomTween; if (a != null) ctrl.value = a.value; }

  void _resetMap() {
    setState(() => selectedCityId = null);
    _zoomAnimation.stop();
    _zoomTween = Matrix4Tween(begin: ctrl.value, end: Matrix4.identity()).animate(
      CurvedAnimation(parent: _zoomAnimation, curve: Curves.easeInOutCubic));
    _zoomAnimation
      ..removeListener(_applyZoom)
      ..addListener(_applyZoom)
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final selected = selectedCityId == null ? null : _cityPlace(selectedCityId!);
    final events = selectedCityId == null ? <Event>[] : _eventsForCity(selectedCityId!);
    final cityIds = _cityGroups.keys.toList();

    return Column(children: [
      ScreenTitle(tr('map_title')),
      Expanded(flex: selectedCityId == null ? 7 : 6, child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        decoration: BoxDecoration(border: Border.all(color: cs.outlineVariant), borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(builder: (context, box) {
          final size = Size(box.maxWidth, box.maxHeight);
          _mapSize = size;
          final visibleCityIds = selectedCityId == null ? cityIds : <String>[];
          final childIds = selectedCityId == null
              ? <String>[]
              : (_cityGroups[selectedCityId!] ?? const <String>[]).where((id) => id != selectedCityId).toList();
          // Après sélection, les grandes villes disparaissent et seuls les sites
          // secondaires sont affichés à leur position géographique, avec des
          // étiquettes déplacées pour éviter les superpositions.
          final mapLabelIds = selectedCityId == null ? visibleCityIds : childIds;
          final labelPositions = _cityLabelLayout(size, mapLabelIds);
          final labelLinks = <Offset>[];
          for (final id in mapLabelIds) {
            final p = _cityPlace(id);
            final label = labelPositions[id];
            if (p != null && label != null) {
              final anchor = _position(size, p.lat, p.lon);
              labelLinks..add(anchor)..add(Offset(label.dx + 50, label.dy + 17));
            }
          }
          return Stack(children: [
            InteractiveViewer(
              transformationController: ctrl, minScale: 1, maxScale: 10,
              boundaryMargin: const EdgeInsets.all(80),
              child: SizedBox(width: size.width, height: size.height,
                child: Stack(children: [
                  Positioned.fill(child: CustomPaint(painter: _MapPainter(
                    land: dark ? const Color(0xFF393326) : const Color(0xFFE9D9B6),
                    sea: dark ? const Color(0xFF252F2D) : const Color(0xFFD7C49D),
                    coast: dark ? const Color(0xFF85775A) : const Color(0xFF9C8357),
                    text: dark ? const Color(0xFFE8D8B3) : const Color(0xFF5C4A2E),
                    labelLinks: labelLinks,
                    selectedDetail: selectedCityId != null,
                  ))),
                  for (final id in visibleCityIds)
                    if (_cityPlace(id) case final Place p)
                      Positioned(
                        left: labelPositions[id]?.dx ?? 0,
                        top: labelPositions[id]?.dy ?? 0,
                        width: 100, height: 34,
                        child: GestureDetector(
                          onTap: () => _selectCity(id, p, size),
                          child: Center(child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: selectedCityId == id ? cs.primary : (dark ? const Color(0xFF342F25) : const Color(0xFFF5E9CD)),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: selectedCityId == id ? cs.primary : const Color(0xFF9C8357), width: 1.2),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 5, offset: const Offset(0,2))],
                            ),
                            child: Text(p.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.5, height: 1.05, fontWeight: FontWeight.w700,
                                color: selectedCityId == id ? cs.onPrimary : (dark ? const Color(0xFFF0E3C5) : const Color(0xFF49391F))),
                            ),
                          )),
                        ),
                      ),
                  for (final id in childIds)
                    if (_cityPlace(id) case final Place child)
                      Positioned(
                        left: labelPositions[id]?.dx ?? 0,
                        top: labelPositions[id]?.dy ?? 0,
                        width: 100, height: 36,
                        child: GestureDetector(
                          onTap: () => openPlace(context, s, child),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                            decoration: BoxDecoration(
                              color: dark ? const Color(0xFF14251E) : const Color(0xFFFFF9EC),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: cs.secondary.withOpacity(.9), width: 1.2),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.20), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.location_on_rounded, size: 15, color: cs.primary),
                              const SizedBox(width: 3),
                              Expanded(child: Text(child.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10, height: 1.05, fontWeight: FontWeight.w700, color: dark ? const Color(0xFFF5E9D0) : const Color(0xFF49391F)))),
                            ]),
                          ),
                        ),
                      ),
                ]),
              ),
            ),
            Positioned(right: 10, top: 10, child: Column(children: [
              FloatingActionButton.small(heroTag: 'map-reset', onPressed: _resetMap,
                child: const Icon(Icons.center_focus_strong)),
              const SizedBox(height: 6),
              FloatingActionButton.small(heroTag: 'map-zoom-in', onPressed: () {
                final m = Matrix4.copy(ctrl.value)..scale(1.35); ctrl.value = m;
              }, child: const Icon(Icons.add)),
            ])),
            if (selected != null)
              Positioned(left: 10, top: 10, child: Chip(
                avatar: const Icon(Icons.location_city, size: 17),
                label: Text(selected.name),
                deleteIcon: const Icon(Icons.close, size: 17), onDeleted: _resetMap,
              )),
          ]);
        }),
      )),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        child: Row(children: [
          Container(width: 18, height: 3, decoration: BoxDecoration(color: cs.secondary, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 7),
          Expanded(child: Text(Strings.lang == 'ar' ? 'روابط جغرافية تقريبية وليست مسارات ملاحة' : (Strings.lang == 'en' ? 'Indicative regional links, not navigation routes' : 'Liaisons régionales indicatives, pas des itinéraires de navigation'), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant))),
        ]),
      ),
      if (selected == null)
        Expanded(flex: 3, child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            Text(Strings.lang == 'ar' ? 'اختر مدينة لعرض أحداث السيرة' : (Strings.lang == 'en' ? 'Select a city to explore its Sirah events' : 'Choisissez une ville pour voir les événements de la Sîrah'), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Wrap(spacing: 7, runSpacing: 4, children: [for (final id in cityIds)
              ActionChip(label: Text(_cityPlace(id)?.name ?? id), avatar: const Icon(Icons.location_on_outlined, size: 16),
                onPressed: () { final p = _cityPlace(id); if (p != null) _selectCity(id, p, _mapSize); }),
            ]),
          ],
        ))
      else
        Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (selected.hasImage)
            Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 8), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: PlaceImage(place: selected, height: 104, width: double.infinity))),
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 4), child: Row(children: [
            Expanded(child: Text(selected.name, style: Theme.of(context).textTheme.titleMedium)),
            Text('${events.length} ${Strings.lang == 'ar' ? 'أحداث' : (Strings.lang == 'en' ? 'events' : 'événements')}', style: Theme.of(context).textTheme.labelMedium),
          ])),
          Expanded(child: events.isEmpty ? Center(child: Text(tr('no_related'))) : ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) { final e = events[i]; return ListTile(
              dense: true, leading: Icon(precisionIcon(e.datePrecision), color: cs.primary),
              title: Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('${e.dateLabel} · ${Strings.lang == 'ar' ? 'موقع تقريبي' : (Strings.lang == 'en' ? 'Approximate location' : 'Lieu approximatif')}'),
              trailing: Icon(s.canOpenEvent(e) ? Icons.chevron_right : Icons.lock_outline),
              onTap: () => openEvent(context, s, e),
            ); },
          )),
        ])),
    ]);
  }
}

class _MapPainter extends CustomPainter {
  final Color land, sea, coast, text;
  final List<Offset> labelLinks;
  final bool selectedDetail;
  _MapPainter({required this.land, required this.sea, required this.coast, required this.text, this.labelLinks = const [], this.selectedDetail = false});
  Offset _p(Size s, double lat, double lon) => Offset(
    (lon - _minLon) / (_maxLon - _minLon) * s.width,
    (_maxLat - lat) / (_maxLat - _minLat) * s.height);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = sea);
    // Grain et fibres du parchemin, motifs déterministes pour rester identiques hors ligne.
    final grain = Paint()..color = const Color(0xFF8D7148).withOpacity(.055);
    for (var y = 8.0; y < size.height; y += 17) {
      for (var x = ((y ~/ 17) % 2) * 9.0 + 5; x < size.width; x += 23) {
        canvas.drawCircle(Offset(x, y + ((x ~/ 23) % 3)), .65 + ((x + y).toInt() % 3) * .25, grain);
      }
    }
    final fibre = Paint()..color = const Color(0xFF9C7A4C).withOpacity(.07)..strokeWidth = .55;
    for (var i = 0; i < 24; i++) {
      final y = (i * 47.0) % size.height;
      final x = (i * 83.0) % size.width;
      canvas.drawLine(Offset(x, y), Offset((x + 28 + (i % 5) * 9).clamp(0, size.width).toDouble(), y + ((i % 3) - 1) * 1.4), fibre);
    }
    final wash = Paint()..shader = RadialGradient(colors: [const Color(0x00A27B45), const Color(0x1C8C6838)], radius: .8).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);
    final grid = Paint()..color = text.withOpacity(.09)..strokeWidth = .65;
    for (var lat = 12.0; lat <= 30.0; lat += 3.0) {
      final y = _p(size, lat, _minLon).dy; canvas.drawLine(Offset(0,y), Offset(size.width,y), grid);
    }
    for (var lon = 33.0; lon <= 57.0; lon += 4.0) {
      final x = _p(size, _minLat, lon).dx; canvas.drawLine(Offset(x,0), Offset(x,size.height), grid);
    }
    void drawLand(List<List<double>> coords, double width) {
      final path = Path();
      for (var i=0;i<coords.length;i++) { final o=_p(size,coords[i][0],coords[i][1]); if(i==0){path.moveTo(o.dx,o.dy);}else{path.lineTo(o.dx,o.dy);} }
      path.close(); canvas.drawPath(path, Paint()..color=land);
      canvas.drawPath(path, Paint()..color=coast..style=PaintingStyle.stroke..strokeWidth=width);
    }
    drawLand(_africaCoast, 1.0); drawLand(_arabianPeninsula, 1.35);

    // Relief stylisé du Hijaz : courbes de niveau discrètes, dessinées localement.
    final contour = Paint()..color = coast.withOpacity(.22)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    for (var band = 0; band < 5; band++) {
      final path = Path();
      final baseLat = 18.5 + band * 2.25;
      final a = _p(size, baseLat, 36.2 + band * .18);
      final b = _p(size, baseLat + 1.0, 38.0 + band * .22);
      final c = _p(size, baseLat + .55, 40.1 + band * .15);
      final d = _p(size, baseLat - .25, 42.0 + band * .12);
      path.moveTo(a.dx, a.dy);
      path.cubicTo(b.dx, b.dy - 22, c.dx, c.dy + 18, d.dx, d.dy);
      canvas.drawPath(path, contour);
    }

    // Liaisons régionales schématiques (elles ne représentent pas une navigation routière).
    final routePaint = Paint()..color = const Color(0xFFB28A43).withOpacity(.58)..style = PaintingStyle.stroke..strokeWidth = 1.8;
    void route(List<List<double>> coords) {
      final path = Path();
      for (var i = 0; i < coords.length; i++) {
        final point = _p(size, coords[i][0], coords[i][1]);
        if (i == 0) { path.moveTo(point.dx, point.dy); } else { path.lineTo(point.dx, point.dy); }
      }
      canvas.drawPath(path, routePaint);
      for (final metric in path.computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 12) {
          final tangent = metric.getTangentForOffset(d);
          if (tangent != null) canvas.drawCircle(tangent.position, 1.25, Paint()..color = const Color(0xFF8A6B35).withOpacity(.75));
        }
      }
    }
    route([[21.4225,39.8262],[22.2,39.5],[23.744,38.79],[24.4672,39.6111]]);
    route([[24.4672,39.6111],[25.7,39.3],[26.6,37.9],[28.3838,36.5662]]);
    route([[21.4225,39.8262],[21.27,40.4158]]);

    // Noms des mers et grandes régions pour mieux lire l’espace géographique.
    final arabic = Strings.lang == 'ar';
    final english = Strings.lang == 'en';
    void label(String value, Offset point, {double fontSize = 10, bool italic = false}) {
      final painter = TextPainter(
        text: TextSpan(text: value, style: TextStyle(color: text.withOpacity(.55), fontSize: fontSize, fontStyle: italic ? FontStyle.italic : FontStyle.normal, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
        textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      )..layout(maxWidth: size.width * .42);
      painter.paint(canvas, point - Offset(painter.width / 2, painter.height / 2));
    }
    label(arabic ? 'البحر الأحمر' : (english ? 'RED SEA' : 'MER ROUGE'), _p(size, 20.0, 35.1), fontSize: 11, italic: true);
    label(arabic ? 'الحجاز' : (english ? 'HEJAZ' : 'HEDJAZ'), _p(size, 24.0, 38.2), fontSize: 12);
    label(arabic ? 'شبه الجزيرة العربية' : (english ? 'ARABIAN PENINSULA' : 'PÉNINSULE ARABIQUE'), _p(size, 17.0, 49.2), fontSize: 11);
    label(arabic ? 'خليج العقبة' : (english ? 'GULF OF AQABA' : 'GOLFE D’AQABA'), _p(size, 28.7, 35.1), fontSize: 8, italic: true);

    // Cadre ornemental discret façon enluminure.
    final border = Paint()..color = coast.withOpacity(.45)..style=PaintingStyle.stroke..strokeWidth=1.2;
    canvas.drawRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(5), const Radius.circular(8)), border);
    final leader = Paint()..color = coast.withOpacity(.72)..strokeWidth = 1.0;
    for (var i = 0; i + 1 < labelLinks.length; i += 2) {
      canvas.drawLine(labelLinks[i], labelLinks[i + 1], leader);
      canvas.drawCircle(labelLinks[i], selectedDetail ? 3.0 : 2.4, Paint()..color = coast);
    }
  }
  @override
  bool shouldRepaint(covariant _MapPainter old) => land!=old.land || sea!=old.sea || coast!=old.coast || text!=old.text || labelLinks!=old.labelLinks || selectedDetail!=old.selectedDetail;
}

class PlaceSheet extends StatelessWidget {
  final AppState state; final Place place; final BuildContext parent;
  const PlaceSheet({super.key, required this.state, required this.place, required this.parent});
  @override
  Widget build(BuildContext context) {
    final tt=Theme.of(context).textTheme; final cs=Theme.of(context).colorScheme;
    final events=state.repo.eventsOfPlace(place.id);
    return SafeArea(child: ListView(shrinkWrap:true,padding:const EdgeInsets.all(20),children:[
      if(place.nameAr.isNotEmpty && Strings.lang!='ar') Directionality(textDirection:TextDirection.rtl,child:Text(place.nameAr,style:tt.titleLarge?.copyWith(color:cs.primary))),
      Text(place.name,style:tt.headlineSmall), const SizedBox(height:8),
      if (place.hasImage) ...[
        ClipRRect(borderRadius: BorderRadius.circular(16), child: PlaceImage(place: place, height: 190, width: double.infinity)),
        const SizedBox(height: 6),
        if (placeImageCaption(place).isNotEmpty) Text(placeImageCaption(place), style: tt.bodySmall),
        if (place.hasImage) Text(placeImageCreditLine(place), style: tt.labelSmall),
        if (place.imageAsset == null && place.imageSourceUrl != null) SelectableText(place.imageSourceUrl!, style: tt.labelSmall?.copyWith(color: cs.primary)),
        const SizedBox(height: 10),
      ],
      Text(place.description,style:tt.bodyLarge?.copyWith(height:1.5)),
      const SizedBox(height:16), Text(tr('related_events'),style:tt.titleMedium?.copyWith(color:cs.primary)),
      if(events.isEmpty) Text(tr('no_related')),
      for(final e in events) ListTile(contentPadding:EdgeInsets.zero,leading:Icon(precisionIcon(e.datePrecision)),title:Text(e.title),subtitle:Text(e.dateLabel),trailing:Icon(state.canOpenEvent(e)?Icons.chevron_right:Icons.lock_outline),onTap:(){Navigator.pop(context);openEvent(parent,state,e);}),
    ]));
  }
}
