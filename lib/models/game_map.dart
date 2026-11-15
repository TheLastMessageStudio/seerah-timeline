import 'dart:math';
import 'dart:typed_data';

import '../strings.dart';
import 'battlefield.dart';
import 'side.dart';
import 'terrain.dart';

/// A city covering several cells. It is captured by ending a turn with a unit
/// on its [citadel] (the central cell). Reinforcements appear at the [gates].
class City {
  City({
    required this.id,
    required this.cells,
    required this.citadel,
    required this.gates,
    this.capitalOf,
  });

  final String id;
  final List<Pos> cells;
  final Pos citadel;
  final List<Pos> gates;
  final Side? capitalOf; // starting capital of this side

  String get name => tr('city_$id');
}

class GameMap {
  GameMap({
    required this.cols,
    required this.rows,
    required this.terrain,
    required this.cities,
    required this.playerCapital,
    required this.enemyCapital,
    required this.messageCity,
    this.zoneRadius = 6,
    Set<Pos>? roadCells,
    this.playerZone,
    this.enemyZone,
    this.backgroundBytes,
    this.bgCamps = const {},
  }) : roads = roadCells ?? <Pos>{} {
    for (final c in cities) {
      for (final p in c.cells) {
        _cityAt[p] = c;
      }
    }
  }

  final int cols;
  final int rows;
  final List<List<Terrain>> terrain; // [row][col], mutable (tests edit it)
  final List<City> cities;
  final City playerCapital;
  final City enemyCapital;
  final City messageCity;
  final int zoneRadius;
  final Set<Pos> roads; // dotted tracks: cost 1 per cell
  final Set<Pos>? playerZone; // custom deployment areas (story maps)
  final Set<Pos>? enemyZone;
  final Uint8List? backgroundBytes; // picture drawn under the grid
  final Set<String> bgCamps; // city ids already drawn in the background picture
  final Map<Pos, City> _cityAt = {};

  City? cityAt(Pos p) => _cityAt[p];
  bool inBounds(Pos p) => p.c >= 0 && p.c < cols && p.r >= 0 && p.r < rows;
  Terrain terrainAt(Pos p) => terrain[p.r][p.c];
  Pos capitalOf(Side s) => (s == Side.player ? playerCapital : enemyCapital).citadel;

  /// Starting territory: land around each capital.
  Side? zoneOf(Pos p) {
    final pz = playerZone, ez = enemyZone;
    if (pz != null && ez != null) {
      if (pz.contains(p)) return Side.player;
      if (ez.contains(p)) return Side.ai;
      return null;
    }
    if (p.dist(playerCapital.citadel) <= zoneRadius) return Side.player;
    if (p.dist(enemyCapital.citadel) <= zoneRadius) return Side.ai;
    return null;
  }

  /// Small flat map for tests: plains everywhere, 3 cities. Edit [terrain].
  factory GameMap.flat({int cols = 20, int rows = 24}) {
    final terrain = [
      for (var r = 0; r < rows; r++) List<Terrain>.filled(cols, Terrain.plains)
    ];
    City mk(String id, Pos c, Side? s) {
      final cells = [c, Pos(c.c + 1, c.r), Pos(c.c - 1, c.r), Pos(c.c, c.r + 1), Pos(c.c, c.r - 1)];
      for (final p in cells) {
        terrain[p.r][p.c] = Terrain.city;
      }
      return City(id: id, cells: cells, citadel: c, gates: [Pos(c.c + 1, c.r), Pos(c.c - 1, c.r)], capitalOf: s);
    }

    final pc = mk('sanaa', Pos(cols ~/ 2, rows - 4), Side.player);
    final ec = mk('damascus', Pos(cols ~/ 2, 3), Side.ai);
    final mc = mk('aqaba', Pos(3, rows ~/ 2), null);
    return GameMap(
      cols: cols,
      rows: rows,
      terrain: terrain,
      cities: [pc, ec, mc],
      playerCapital: pc,
      enemyCapital: ec,
      messageCity: mc,
      zoneRadius: 5,
    );
  }

  /// Procedural Middle East (north up): Mediterranean, Red Sea, Persian Gulf,
  /// Arabian Sea, Nile, Tigris/Euphrates, mountains, deserts, real cities.
  /// The same [seed] always gives the same map; capitals vary with the seed.
  factory GameMap.generate(int seed) {
    final rng = Random(seed);
    const cols = 30;
    const rows = 45;
    const lon0 = 30.0, lonSpan = 22.0, lat0 = 37.0, latSpan = 24.5;
    double lonOf(int c) => lon0 + (c + 0.5) / cols * lonSpan;
    double latOf(int r) => lat0 - (r + 0.5) / rows * latSpan;
    int colOf(double lon) => ((lon - lon0) / lonSpan * cols).floor();
    int rowOf(double lat) => ((lat0 - lat) / latSpan * rows).floor();
    bool ok(Pos p) => p.c >= 0 && p.c < cols && p.r >= 0 && p.r < rows;

    // --- smooth noise layers
    List<List<double>> layer() => [
          for (var r = 0; r < rows ~/ 4 + 2; r++)
            [for (var c = 0; c < cols ~/ 4 + 2; c++) rng.nextDouble()]
        ];
    final n1 = layer(), n2 = layer(), n3 = layer();
    double sample(List<List<double>> g, int c, int r) {
      final x = c / 4, y = r / 4;
      final x0 = x.floor(), y0 = y.floor();
      final fx = x - x0, fy = y - y0;
      double l(double a, double b, double t) => a + (b - a) * t;
      return l(l(g[y0][x0], g[y0][x0 + 1], fx), l(g[y0 + 1][x0], g[y0 + 1][x0 + 1], fx), fy);
    }

    // --- seas
    final sea = [for (var r = 0; r < rows; r++) List<bool>.filled(cols, false)];
    final red = [for (var r = 0; r < rows; r++) List<bool>.filled(cols, false)];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final x = lonOf(c), y = latOf(r);
        for (final poly in _seas) {
          if (_inPoly(poly, x, y)) sea[r][c] = true;
        }
        for (final poly in _redSea) {
          if (_inPoly(poly, x, y)) {
            sea[r][c] = true;
            red[r][c] = true;
          }
        }
      }
    }

    // --- rivers (with fords)
    final riverCells = <Pos>{};
    final fordCells = <Pos>{};
    void river(List<LL> pts) {
      final path = <Pos>[];
      for (var i = 0; i < pts.length - 1; i++) {
        final (x0, y0) = pts[i];
        final (x1, y1) = pts[i + 1];
        for (var s = 0; s <= 40; s++) {
          final p = Pos(colOf(x0 + (x1 - x0) * s / 40), rowOf(y0 + (y1 - y0) * s / 40));
          if (ok(p) && !sea[p.r][p.c] && (path.isEmpty || path.last != p)) path.add(p);
        }
      }
      final off = rng.nextInt(7);
      for (var k = 0; k < path.length; k++) {
        riverCells.add(path[k]);
        if ((k + off) % 4 == 0) fordCells.add(path[k]);
      }
    }

    river(_nile);
    river(_euphrates);
    river(_tigris);
    bool nearRiver(int c, int r) {
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          if (riverCells.contains(Pos(c + dx, r + dy))) return true;
        }
      }
      return false;
    }

    // --- land terrain
    final terrain = [
      for (var r = 0; r < rows; r++) List<Terrain>.filled(cols, Terrain.plains)
    ];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final p = Pos(c, r);
        if (sea[r][c]) {
          terrain[r][c] = Terrain.sea;
          continue;
        }
        if (riverCells.contains(p)) {
          terrain[r][c] = fordCells.contains(p) ? Terrain.ford : Terrain.river;
          continue;
        }
        final lon = lonOf(c), lat = latOf(r);
        final a = sample(n1, c, r), b = sample(n2, c, r), d = sample(n3, c, r);
        bool box(double l0, double l1, double a0, double a1) =>
            lon >= l0 && lon <= l1 && lat >= a0 && lat <= a1;
        var t = Terrain.plains;
        final yemen = box(43, 46.5, 13, 17.5);
        final desert = box(36, 51, 14.5, 31.5) && !yemen;
        if (desert && a > 0.5) t = Terrain.dunes;
        if (box(44, 52, 17.5, 23) && a > 0.3) t = Terrain.dunes; // Empty Quarter
        if (box(37.5, 42, 27, 30) && a > 0.4) t = Terrain.dunes; // Nefud
        if (!desert && d > 0.74) t = Terrain.hills;
        void ridge(bool inside, double mountain, double hills) {
          if (!inside) return;
          if (b > mountain) {
            t = Terrain.mountain;
          } else if (b > hills) {
            t = Terrain.hills;
          }
        }

        final hejaz = lat >= 14 && lat <= 29.5 &&
            ((c > 0 && red[r][c - 1]) || (c > 1 && red[r][c - 2]) || (c > 2 && red[r][c - 3]));
        ridge(hejaz, 0.6, 0.3);
        ridge(yemen, 0.4, 0.1);
        ridge(box(33.2, 34.8, 27.8, 29.6), 0.3, 0.1); // Sinai
        ridge(box(35.6, 37.0, 33, 36.4), 0.45, 0.2); // Lebanon
        ridge(lat > 36.0, 0.6, 0.3); // Taurus
        ridge(box(46.5, 52, 30.5, 37), 0.4, 0.2); // Zagros
        ridge(box(36.5, 40.5, 12.5, 16), 0.5, 0.25); // Eritrea highlands
        if (box(31.5, 33.5, 22, 27) && b > 0.5) t = Terrain.hills;
        final fertile = nearRiver(c, r) || box(34.8, 37, 31, 36.4) || yemen;
        if (fertile && d > 0.55 && t == Terrain.plains) t = Terrain.grove;
        terrain[r][c] = t;
      }
    }

    // --- scattered oases in the desert
    for (var k = 0, tries = 0; k < 16 && tries < 400; tries++) {
      final c = rng.nextInt(cols), r = rng.nextInt(rows);
      final lon = lonOf(c), lat = latOf(r);
      if (lon > 36 && lon < 51 && lat > 15 && lat < 31 &&
          (terrain[r][c] == Terrain.dunes || terrain[r][c] == Terrain.plains)) {
        terrain[r][c] = Terrain.oasis;
        k++;
      }
    }

    // --- cities
    bool land(Pos p) => ok(p) && !terrain[p.r][p.c].impassable;
    final cities = <City>[];
    final taken = <Pos>{};
    final playerIds = ['sanaa', 'najran', 'hodeidah'];
    final enemyIds = ['damascus', 'baghdad', 'mosul'];
    final pId = playerIds[rng.nextInt(playerIds.length)];
    final eId = enemyIds[rng.nextInt(enemyIds.length)];
    for (final def in _cityDefs) {
      final (id, lon, lat, shapeName) = def;
      final isCap = id == pId || id == eId;
      Pos? center;
      final c0 = colOf(lon), r0 = rowOf(lat);
      for (var rad = 0; rad <= 4 && center == null; rad++) {
        for (var dy = -rad; dy <= rad && center == null; dy++) {
          for (var dx = -rad; dx <= rad && center == null; dx++) {
            final p = Pos(c0 + dx, r0 + dy);
            if (land(p) && !taken.contains(p)) center = p;
          }
        }
      }
      if (center == null) continue;
      final ctr = center;
      final offs = (isCap && shapeName != 'big') ? _shapes['block']! : _shapes[shapeName]!;
      final cells = <Pos>[];
      for (final (dx, dy) in offs) {
        final p = Pos(ctr.c + dx, ctr.r + dy);
        if (land(p) && !taken.contains(p) && terrain[p.r][p.c] != Terrain.ford) cells.add(p);
      }
      if (!cells.contains(ctr)) cells.add(ctr);
      for (final p in cells) {
        taken.add(p);
        terrain[p.r][p.c] = Terrain.city;
      }
      // gates: up to 4 edge cells spread around the city
      final edge = cells.where((p) => p.neighbors.any((n) => land(n) && !cells.contains(n))).toList()
        ..sort((u, v) => atan2((u.r - ctr.r).toDouble(), (u.c - ctr.c).toDouble())
            .compareTo(atan2((v.r - ctr.r).toDouble(), (v.c - ctr.c).toDouble())));
      final gates = <Pos>[];
      final want = min(4, edge.length);
      for (var i = 0; i < want; i++) {
        gates.add(edge[(i * edge.length / want).floor()]);
      }
      cities.add(City(
        id: id,
        cells: cells,
        citadel: ctr,
        gates: gates.isEmpty ? [ctr] : gates,
        capitalOf: id == pId ? Side.player : (id == eId ? Side.ai : null),
      ));
    }
    final pc = cities.firstWhere((c) => c.id == pId);
    final ec = cities.firstWhere((c) => c.id == eId);
    final mc = cities.firstWhere((c) => c.id == 'aqaba', orElse: () => cities.first);

    // --- zones: flatten mountains around capitals; widen if too cramped
    int deployable(City cap, int rad) {
      var n = 0;
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          final p = Pos(c, r);
          if (p.dist(cap.citadel) <= rad && !terrain[r][c].impassable) n++;
        }
      }
      return n;
    }

    var zoneRadius = 6;
    if (min(deployable(pc, 6), deployable(ec, 6)) < 26) zoneRadius = 8;
    for (final cap in [pc, ec]) {
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          if (Pos(c, r).dist(cap.citadel) <= zoneRadius && terrain[r][c] == Terrain.mountain) {
            terrain[r][c] = Terrain.hills;
          }
        }
      }
    }

    // --- guarantee the capitals and the destination are connected on foot
    bool connected() {
      final seen = <Pos>{pc.citadel};
      final q = [pc.citadel];
      while (q.isNotEmpty) {
        final cur = q.removeLast();
        for (final n in cur.neighbors) {
          if (land(n) && seen.add(n)) q.add(n);
        }
      }
      return seen.contains(ec.citadel) && seen.contains(mc.citadel);
    }

    if (!connected()) {
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          if (terrain[r][c] == Terrain.river) terrain[r][c] = Terrain.ford;
        }
      }
    }

    // --- roads: cheapest track between capitals and to the message city.
    // Mountains on a road become hills, so cavalry can use it too.
    final roads = <Pos>{};
    void carve(Pos from, Pos to) {
      final cost = <Pos, int>{from: 0};
      final prev = <Pos, Pos>{};
      final open = <Pos>[from];
      while (open.isNotEmpty) {
        open.sort((a, b) => cost[a]!.compareTo(cost[b]!));
        final cur = open.removeAt(0);
        if (cur == to) break;
        for (final n in cur.neighbors) {
          if (!land(n)) continue;
          final nc = cost[cur]! + terrain[n.r][n.c].moveCost;
          final k = cost[n];
          if (k == null || nc < k) {
            cost[n] = nc;
            prev[n] = cur;
            open.add(n);
          }
        }
      }
      if (!prev.containsKey(to)) return;
      var cur = to;
      while (cur != from) {
        roads.add(cur);
        if (terrain[cur.r][cur.c] == Terrain.mountain) terrain[cur.r][cur.c] = Terrain.hills;
        cur = prev[cur]!;
      }
      roads.add(from);
    }

    carve(pc.citadel, ec.citadel);
    carve(pc.citadel, mc.citadel);
    carve(ec.citadel, mc.citadel);

    return GameMap(
      cols: cols,
      rows: rows,
      terrain: terrain,
      cities: cities,
      playerCapital: pc,
      enemyCapital: ec,
      messageCity: mc,
      zoneRadius: zoneRadius,
      roadCells: roads,
    );
  }

  /// Rush: the small hand-made map for fast 1v1 games, portrait like a phone
  /// duel: you at the bottom, the enemy at the top, the river across the middle.
  /// [extraRows] stretches the battlefield (extra land on each side of the river).
  factory GameMap.rush({int extraRows = 0}) {
    const left = [
      '..gg.hMMM', '.g..hhMM.', '...g.hV..', '..h...g..', '.h.dd....',
      '...dd.o..', '..P.g....', '.....g...', '...dd.o..', '.h.dd....',
      '..h...g..', '...g.hV..', '.g..hhMM.', '..gg.hMMM',
    ];
    const center = 'wwfwfwFwfwfwww';
    const cols = 14, baseRows = 19;
    // Built west-to-east first, then turned 90 degrees: the western side
    // (player) ends up at the bottom, the eastern side (enemy) at the top.
    final wide = [
      for (var r = 0; r < cols; r++)
        left[r] + center[r] + left[r].split('').reversed.map((ch) => ch == 'P' ? 'E' : ch).join(),
    ];
    final turned = [
      for (var r = 0; r < baseRows; r++)
        [for (var c = 0; c < cols; c++) wide[c][baseRows - 1 - r]].join(),
    ];
    const fillers = ['.g..d...d..g..', '..h..g..g..h..', '.d...hh.....d.', '...g..dd..g...'];
    final lines = <String>[];
    for (var r = 0; r < baseRows; r++) {
      if (extraRows > 0 && (r == 8 || r == 11)) {
        for (var k = 0; k < extraRows; k++) {
          lines.add(fillers[(k + (r == 8 ? 0 : 2)) % fillers.length]);
        }
      }
      lines.add(turned[r]);
    }
    final rows = lines.length;
    final terrain = [
      for (var r = 0; r < rows; r++)
        [
          for (var c = 0; c < cols; c++)
            switch (lines[r][c]) {
              'd' => Terrain.dunes,
              'g' => Terrain.grove,
              'h' => Terrain.hills,
              'M' => Terrain.mountain,
              'w' => Terrain.river,
              'f' => Terrain.ford,
              'o' => Terrain.oasis,
              'F' => Terrain.fort,
              'P' || 'E' || 'V' => Terrain.city,
              _ => Terrain.plains,
            }
        ]
    ];
    final cities = <City>[];
    final villages = ['jerusalem', 'aqaba', 'tabuk', 'hail'];
    var v = 0;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final ch = lines[r][c];
        if (ch != 'P' && ch != 'E' && ch != 'V') continue;
        final cells = [Pos(c, r), Pos(c + 1, r), Pos(c - 1, r), Pos(c, r + 1), Pos(c, r - 1)];
        for (final p in cells) {
          terrain[p.r][p.c] = Terrain.city;
        }
        cities.add(City(
          id: ch == 'P' ? 'sanaa' : (ch == 'E' ? 'damascus' : villages[v++ % villages.length]),
          cells: cells,
          citadel: Pos(c, r),
          gates: [Pos(c, r - 1), Pos(c, r + 1)],
          capitalOf: ch == 'P' ? Side.player : (ch == 'E' ? Side.ai : null),
        ));
      }
    }
    final pc = cities.firstWhere((c) => c.capitalOf == Side.player);
    final ec = cities.firstWhere((c) => c.capitalOf == Side.ai);
    return GameMap(
      cols: cols,
      rows: rows,
      terrain: terrain,
      cities: cities,
      playerCapital: pc,
      enemyCapital: ec,
      messageCity: cities.firstWhere((c) => c.capitalOf == null),
      zoneRadius: 4,
    );
  }
}

// ----------------------------------------------------------- geography data

typedef LL = (double, double); // (longitude, latitude)

bool _inPoly(List<LL> poly, double x, double y) {
  var inside = false;
  for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final (xi, yi) = poly[i];
    final (xj, yj) = poly[j];
    if ((yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
      inside = !inside;
    }
  }
  return inside;
}

const List<List<LL>> _seas = [
  // Mediterranean
  [(28.0, 36.4), (35.9, 36.4), (35.8, 35.5), (35.5, 34.0), (35.0, 32.8), (34.3, 31.5), (34.2, 31.3), (32.3, 31.2), (31.0, 31.5), (28.0, 31.0)],
  // Gulf of Suez, Gulf of Aqaba
  [(32.0, 30.4), (33.0, 30.4), (33.9, 28.4), (32.9, 28.4)],
  [(34.7, 29.6), (35.5, 29.6), (35.7, 27.6), (34.9, 27.6)],
  // Persian Gulf
  [(47.9, 29.9), (48.8, 30.3), (50.0, 29.6), (51.0, 28.6), (52.5, 27.4), (52.5, 24.0), (51.7, 24.3), (51.4, 25.6), (50.4, 26.2), (50.0, 27.0), (49.5, 27.8), (48.5, 28.6), (48.0, 29.5)],
  // Gulf of Aden / Arabian Sea
  [(43.0, 11.0), (53.0, 11.0), (53.0, 16.2), (51.0, 15.0), (49.0, 14.2), (47.0, 13.5), (45.0, 12.8), (43.7, 12.2)],
];

const List<List<LL>> _redSea = [
  [(33.0, 28.4), (34.2, 26.0), (35.5, 23.8), (36.7, 21.0), (37.9, 18.5), (39.2, 16.2), (41.0, 14.4), (42.6, 13.0), (43.7, 12.0), (43.3, 13.4), (42.6, 14.9), (41.5, 16.8), (40.3, 19.0), (39.3, 21.2), (37.9, 24.0), (36.5, 26.4), (35.6, 28.0), (34.8, 28.3)],
];

const List<LL> _nile = [(31.2, 31.5), (31.3, 30.2), (31.6, 28.5), (32.4, 26.2), (32.8, 24.8), (32.9, 23.5), (32.3, 22.0), (31.6, 20.5), (32.0, 18.8), (32.6, 16.5), (32.6, 12.5)];
const List<LL> _euphrates = [(38.0, 36.4), (38.9, 35.6), (40.2, 34.6), (41.6, 33.9), (43.2, 33.2), (44.3, 32.2), (46.0, 31.1), (47.8, 30.4)];
const List<LL> _tigris = [(41.2, 37.0), (42.4, 36.2), (43.4, 34.8), (44.4, 33.4), (45.4, 32.2), (46.7, 31.3), (47.8, 30.5)];

// id, longitude, latitude, footprint shape. Mecca and Medina are left out on purpose.
const List<(String, double, double, String)> _cityDefs = [
  ('fustat', 31.3, 30.0, 'big'),
  ('aswan', 32.9, 24.1, 'plus'),
  ('portsudan', 37.2, 19.6, 'port'),
  ('aqaba', 35.0, 29.5, 'port'),
  ('jerusalem', 35.2, 31.8, 'block'),
  ('damascus', 36.3, 33.5, 'big'),
  ('antioch', 36.2, 36.0, 'crescent'),
  ('palmyra', 38.3, 34.6, 'plus'),
  ('baghdad', 44.4, 33.3, 'big'),
  ('mosul', 43.1, 36.3, 'block'),
  ('basra', 47.8, 30.5, 'port'),
  ('hofuf', 49.6, 25.4, 'plus'),
  ('tabuk', 36.6, 28.4, 'plus'),
  ('hail', 41.7, 27.5, 'block'),
  ('riyadh', 46.7, 24.6, 'big'),
  ('jeddah', 39.2, 21.5, 'port'),
  ('yanbu', 38.1, 24.1, 'crescent'),
  ('najran', 44.1, 17.5, 'block'),
  ('sanaa', 44.2, 15.4, 'big'),
  ('hodeidah', 42.9, 14.8, 'port'),
  ('aden', 45.0, 12.9, 'crescent'),
  ('mukalla', 49.1, 14.5, 'plus'),
];

final Map<String, List<(int, int)>> _shapes = {
  'plus': [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)],
  'block': [for (var y = -1; y <= 1; y++) for (var x = -1; x <= 1; x++) (x, y)],
  'port': [(-1, 0), (0, 0), (1, 0), (-1, 1), (0, 1), (1, 1)],
  'crescent': [(0, 0), (-2, -1), (-2, 0), (-1, 1), (0, 1), (1, 1), (2, 0), (2, -1)],
  'big': [
    for (var y = -2; y <= 2; y++)
      for (var x = -2; x <= 2; x++)
        if (x.abs() + y.abs() <= 2) (x, y)
  ],
};
