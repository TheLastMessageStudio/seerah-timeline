import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'places_screen.dart';

void openPaywall(BuildContext c, AppState s) => c.push('/paywall');
void openSettings(BuildContext c) => c.push('/settings');
void openFamilyTree(BuildContext c) => c.push('/family-tree');
void openBook(BuildContext c, String bookId) => c.push('/book/$bookId');
void openPeriod(BuildContext c, AppState s, Period p) {
  if (!s.periodUnlocked(p)) {
    openPaywall(c, s);
    return;
  }
  c.push('/period/${p.id}');
}

void openEvent(BuildContext c, AppState s, Event e, {bool replace = false}) {
  if (!s.canOpenEvent(e)) {
    if (s.isWaitingForRelease(e.id)) {
      c.push('/release?event=${e.id}');
    } else {
      openPaywall(c, s);
    }
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
    final related = s.repo.eventsOfPerson(p.id);
    if (related.isNotEmpty && related.every((event) => s.isWaitingForRelease(event.id))) {
      c.push('/release?event=${related.first.id}');
    } else {
      openPaywall(c, s);
    }
    return;
  }
  c.push('/person/${p.id}');
}

void openPlace(BuildContext c, AppState s, Place p) {
  if (!s.canOpenPlace(p)) {
    final related = s.repo.eventsOfPlace(p.id);
    if (related.isNotEmpty && related.every((event) => s.isWaitingForRelease(event.id))) {
      c.push('/release?event=${related.first.id}');
    } else {
      openPaywall(c, s);
    }
    return;
  }
  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    builder: (_) => PlaceSheet(state: s, place: p, parent: c),
  );
}
