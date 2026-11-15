import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'places_screen.dart';

void openPaywall(BuildContext c, AppState s) => c.push('/paywall');
void openSettings(BuildContext c) => c.push('/settings');
void openPeriod(BuildContext c, Period p) => c.push('/period/${p.id}');

void openEvent(BuildContext c, AppState s, Event e, {bool replace = false}) {
  if (!s.canOpenEvent(e)) {
    openPaywall(c, s);
    return;
  }
  if (replace) {
    c.pushReplacement('/event/${e.id}');
  } else {
    c.push('/event/${e.id}');
  }
}

void openPerson(BuildContext c, AppState s, Person p) {
  if (!s.canOpenPerson(p)) {
    openPaywall(c, s);
    return;
  }
  c.push('/person/${p.id}');
}

void openPlace(BuildContext c, AppState s, Place p) {
  if (!s.canOpenPlace(p)) {
    openPaywall(c, s);
    return;
  }
  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    builder: (_) => PlaceSheet(state: s, place: p, parent: c),
  );
}
