#!/usr/bin/env python3
"""Vérifie l'intégrité des données : python3 tools/validate_data.py"""
import json, sys, os
D = os.path.join(os.path.dirname(__file__), "..", "assets", "data")
L = lambda f: json.load(open(os.path.join(D, f), encoding="utf-8"))
T = lambda lang, f: json.load(open(os.path.join(D, "i18n", lang, f), encoding="utf-8"))
errors = []
periods, events, persons, places, sources = (L(f + ".json") for f in ["periods", "events", "persons", "places", "sources"])
ids = lambda l: [x["id"] for x in l]
for name, lst in [("periods", periods), ("events", events), ("persons", persons), ("places", places), ("sources", sources)]:
    if len(ids(lst)) != len(set(ids(lst))): errors.append(f"{name}: identifiants dupliqués")
    for lang in sorted(os.listdir(os.path.join(D, "i18n"))):
        tr = T(lang, name + ".json")
        for i in ids(lst):
            if i not in tr: errors.append(f"[{lang}] {name}: traduction manquante pour {i}")
P, PL, PE, S = set(ids(persons)), set(ids(places)), set(ids(periods)), set(ids(sources))
orders = [e["sortOrder"] for e in events]
if orders != sorted(orders) or len(orders) != len(set(orders)): errors.append("events: sortOrder doit être unique et croissant")
for e in events:
    if e["periodId"] not in PE: errors.append(f"{e['id']}: période inconnue")
    if e["datePrecision"] not in ("exact", "approximate", "disputed"): errors.append(f"{e['id']}: datePrecision invalide")
    if e.get("status") not in ("draft", "reviewed"): errors.append(f"{e['id']}: status invalide")
    for k, ref in (("personIds", P), ("placeIds", PL), ("sourceIds", S)):
        for x in e.get(k, []):
            if x not in ref: errors.append(f"{e['id']}: {k} inconnu -> {x}")
used_p = {x for e in events for x in e["personIds"]}
used_pl = {x for e in events for x in e["placeIds"]}
for p in P - used_p: print(f"avertissement: personnage sans événement: {p}")
for p in PL - used_pl: print(f"avertissement: lieu sans événement: {p}")
for p in periods:
    if not any(e["periodId"] == p["id"] for e in events): print(f"avertissement: période vide: {p['id']}")
print(f"{len(events)} événements, {len(persons)} personnages, {len(places)} lieux, {len(sources)} sources")
if errors:
    print("\n".join("ERREUR: " + e for e in errors)); sys.exit(1)
print("OK : données cohérentes")
