import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'nav.dart';

// Carte schématique (pas d'API, pas de GPS). Positions approximatives.
const _minLat = 11.5, _maxLat = 27.5, _minLon = 34.0, _maxLon = 45.0;

const _eastCoast = [
  [27.5, 35.6], [24.1, 38.05], [23.0, 38.8], [21.5, 39.17], [19.1, 41.1],
  [16.9, 42.55], [14.8, 42.95], [12.7, 43.4], [11.5, 43.5],
];
const _westCoast = [
  [27.5, 33.7], [24.0, 35.5], [22.0, 36.8], [19.6, 37.2], [18.4, 38.2],
  [15.6, 39.45], [14.0, 40.9], [13.0, 42.7], [11.6, 43.1],
];

class PlacesScreen extends StatefulWidget {
  final AppState state;
  const PlacesScreen({super.key, required this.state});
  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final ctrl = TransformationController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      ScreenTitle(tr('map_title')),
      Expanded(
        flex: 5,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth, h = box.maxHeight;
            Offset pos(double lat, double lon) => Offset(
                  (lon - _minLon) / (_maxLon - _minLon) * w,
                  (_maxLat - lat) / (_maxLat - _minLat) * h,
                );
            return InteractiveViewer(
              transformationController: ctrl,
              minScale: 1,
              maxScale: 14,
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MapPainter(
                        land: dark ? const Color(0xFF2A2A22) : const Color(0xFFEADFC3),
                        sea: dark ? const Color(0xFF1E3A4A) : const Color(0xFFA9CCDB),
                        coast: cs.outline,
                        text: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: ListenableBuilder(
                      listenable: ctrl,
                      builder: (context, _) {
                        final scale = ctrl.value.getMaxScaleOnAxis();
                        return Stack(children: [
                          for (final p in s.repo.places)
                            Positioned(
                              left: pos(p.lat, p.lon).dx - 14,
                              top: pos(p.lat, p.lon).dy - 14,
                              width: 28,
                              height: 28,
                              child: Transform.scale(
                                scale: 1 / scale,
                                child: GestureDetector(
                                  onTap: () => openPlace(context, s, p),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: s.canOpenPlace(p) ? cs.primary : cs.outline,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Icon(
                                      s.canOpenPlace(p) ? Icons.place : Icons.lock,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ]);
                      },
                    ),
                  ),
                ]),
              ),
            );
          }),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        child: Text(tr('map_note'),
            style: Theme.of(context).textTheme.bodySmall),
      ),
      Expanded(
        flex: 4,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final p in s.repo.places)
              ListTile(
                dense: true,
                leading: const Icon(Icons.place_outlined),
                title: Text(p.name),
                subtitle: Text(tr('n_events', {'n': s.repo.eventsOfPlace(p.id).length})),
                trailing: Icon(s.canOpenPlace(p) ? Icons.chevron_right : Icons.lock_outline),
                onTap: () => openPlace(context, s, p),
              ),
          ],
        ),
      ),
    ]);
  }
}

class _MapPainter extends CustomPainter {
  final Color land, sea, coast, text;
  _MapPainter({required this.land, required this.sea, required this.coast, required this.text});

  Offset _p(Size s, double lat, double lon) => Offset(
        (lon - _minLon) / (_maxLon - _minLon) * s.width,
        (_maxLat - lat) / (_maxLat - _minLat) * s.height,
      );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = land);
    final path = Path();
    var first = true;
    for (final c in _eastCoast) {
      final o = _p(size, c[0], c[1]);
      first ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      first = false;
    }
    for (final c in _westCoast.reversed) {
      final o = _p(size, c[0], c[1]);
      path.lineTo(o.dx, o.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = sea);
    canvas.drawPath(
      path,
      Paint()
        ..color = coast
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    _label(canvas, size, tr('sea_red'), 19.0, 38.9);
    _label(canvas, size, tr('arabia'), 22.5, 42.5);
    _label(canvas, size, tr('africa'), 17.5, 35.4);
  }

  void _label(Canvas canvas, Size size, String t, double lat, double lon) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(color: text, fontSize: 10, fontStyle: FontStyle.italic)),
      textDirection: TextDirection.ltr,
    )..layout();
    final o = _p(size, lat, lon);
    tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => true;
}

class PlaceSheet extends StatelessWidget {
  final AppState state;
  final Place place;
  final BuildContext parent;
  const PlaceSheet({super.key, required this.state, required this.place, required this.parent});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final events = state.repo.eventsOfPlace(place.id);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          if (place.nameAr.isNotEmpty && Strings.lang != 'ar')
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(place.nameAr, style: tt.titleLarge?.copyWith(color: cs.primary)),
            ),
          Text(place.name, style: tt.headlineSmall),
          const SizedBox(height: 8),
          Text(place.description, style: tt.bodyLarge?.copyWith(height: 1.5)),
          const SizedBox(height: 16),
          Text(tr('related_events'), style: tt.titleMedium?.copyWith(color: cs.primary)),
          if (events.isEmpty) Text(tr('no_related')),
          for (final e in events)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(precisionIcon(e.datePrecision)),
              title: Text(e.title),
              subtitle: Text(e.dateLabel),
              trailing: Icon(state.canOpenEvent(e) ? Icons.chevron_right : Icons.lock_outline),
              onTap: () {
                Navigator.pop(context);
                openEvent(parent, state, e);
              },
            ),
        ],
      ),
    );
  }
}
