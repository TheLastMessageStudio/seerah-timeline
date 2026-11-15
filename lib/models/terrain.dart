import '../strings.dart';

enum Terrain { plains, dunes, grove, hills, mountain, river, ford, oasis, city, fort, sea, mud, cliff }

extension TerrainInfo on Terrain {
  bool get impassable => this == Terrain.river || this == Terrain.sea || this == Terrain.cliff;

  /// Movement points needed to enter.
  int get moveCost => switch (this) {
        Terrain.plains || Terrain.oasis || Terrain.city || Terrain.fort => 1,
        Terrain.dunes || Terrain.grove || Terrain.hills || Terrain.ford || Terrain.mud => 2,
        Terrain.mountain => 3,
        Terrain.river || Terrain.sea || Terrain.cliff => 99,
      };

  /// Defense bonus (negative = exposed).
  int get defense => switch (this) {
        Terrain.grove || Terrain.hills || Terrain.mountain || Terrain.city => 1,
        Terrain.fort => 2,
        Terrain.ford => -1,
        _ => 0,
      };

  /// Extra attack range for ranged units standing here.
  int get rangeBonus => switch (this) {
        Terrain.hills || Terrain.city || Terrain.fort => 1,
        Terrain.mountain => 2,
        _ => 0,
      };

  String get label => tr('terrain_$name');
  String get shortLabel => tr('terrainshort_$name');
  String get description => tr('terraindesc_$name');
}
