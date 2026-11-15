import 'package:flutter/material.dart';

import '../models/cards.dart';
import '../models/units.dart';
import '../strings.dart';

IconData typeIcon(UnitType t) => switch (t.troopRole) {
      'spearmen' => Icons.change_history,
      'swordsman' => Icons.gavel,
      'archer' => Icons.gps_fixed,
      'skirmisher' => Icons.north_east,
      'guard' => Icons.shield,
      'scout' => Icons.visibility,
      'rider' => Icons.bolt,
      'camel' => Icons.terrain,
      'standard' => Icons.flag,
      'healer' => Icons.local_hospital,
      _ => Icons.mail,
    };

IconData cardIcon(CardDef c) => switch (c.effect) {
      CardEffect.heal => Icons.local_drink,
      CardEffect.shield => Icons.shield_outlined,
      CardEffect.fortify => Icons.domain,
      CardEffect.rally => Icons.campaign,
      CardEffect.march => Icons.directions_run,
      CardEffect.recon => Icons.remove_red_eye,
      CardEffect.energy => Icons.battery_charging_full,
      CardEffect.drums => Icons.volume_up,
      CardEffect.sabotage => Icons.build,
      CardEffect.sandstorm => Icons.cloud,
      CardEffect.ambush => Icons.visibility_off,
      CardEffect.reinforce => Icons.group_add,
      CardEffect.damage => Icons.whatshot,
      CardEffect.rush => Icons.fast_forward,
    };

/// Human readable attack pattern, e.g. "Straight lines, range 1-2".
String patternText(UnitType t) {
  if (t.shape.name == 'none') return tr('shape_none');
  return tr('shape_${t.shape.name}', {'min': t.minR, 'max': t.maxR});
}
