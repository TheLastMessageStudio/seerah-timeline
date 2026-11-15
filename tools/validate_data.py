#!/usr/bin/env python3
"""Vérifie l'intégrité des données : python3 tools/validate_data.py"""
import json, sys, os
D = os.path.join(os.path.dirname(__file__), "..", "assets", "data")
L = lambda f: json.load(open(os.path.join(D, f), encoding="utf-8"))
T = lambda lang, f: json.load(open(os.path.join(D, "i18n", lang, f), encoding="utf-8"))
errors = []
periods, events, persons, places, sources, books = (L(f + ".json") for f in ["periods", "events", "persons", "places", "sources", "books"])
book_passages = L("book_passages.json")
event_evidence = L("event_evidence.json")
release_schedule = L("release_schedule.json")
ids = lambda l: [x["id"] for x in l]
for name, lst in [("periods", periods), ("events", events), ("persons", persons), ("places", places), ("sources", sources), ("books", books)]:
    if len(ids(lst)) != len(set(ids(lst))): errors.append(f"{name}: identifiants dupliqués")
    for lang in sorted(os.listdir(os.path.join(D, "i18n"))):
        tr = T(lang, name + ".json")
        for i in ids(lst):
            if i not in tr: errors.append(f"[{lang}] {name}: traduction manquante pour {i}")
P, PL, PE, S, B = set(ids(persons)), set(ids(places)), set(ids(periods)), set(ids(sources)), set(ids(books))
if len(ids(book_passages)) != len(set(ids(book_passages))): errors.append("book_passages: identifiants dupliqués")
for book in books:
    if book.get("availability") == "scan_only" and (not book.get("sourceUrl") or not book.get("rightsNote")):
        errors.append(f"{book['id']}: source du scan ou note de droits manquante")
E = set(ids(events))
for evidence in event_evidence:
    if evidence.get("eventId") not in E: errors.append(f"event_evidence: événement inconnu -> {evidence.get('eventId')}")
    if not (evidence.get("textAr") or evidence.get("textFr") or evidence.get("textEn")) or not evidence.get("url"): errors.append(f"event_evidence: texte ou source manquant -> {evidence.get('eventId')}")
scheduled_ids = []
for week in release_schedule:
    count = len(week.get("eventIds", []))
    if not 1 <= count <= 5: errors.append(f"release_schedule semaine {week.get('week')}: entre 1 et 5 événements attendus")
    for event_id in week.get("eventIds", []):
        if event_id not in E: errors.append(f"release_schedule: événement inconnu -> {event_id}")
        scheduled_ids.append(event_id)
if len(scheduled_ids) != len(set(scheduled_ids)):
    errors.append("release_schedule: un événement est programmé plusieurs fois")
for place in places:
    if place.get("imageUrl") and not all(place.get(k) for k in ("imageCredit", "imageLicense", "imageLicenseUrl", "imageSourceUrl")):
        errors.append(f"{place['id']}: attribution/licence d’image incomplète")
    if place.get("imageAsset"):
        asset_path = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", place["imageAsset"]))
        if not os.path.isfile(asset_path):
            errors.append(f"{place['id']}: imageAsset introuvable -> {place['imageAsset']}")
        for key in ("imageAssetCaptionFr", "imageAssetCaptionEn", "imageAssetCaptionAr"):
            if not place.get(key): errors.append(f"{place['id']}: légende d’illustration manquante -> {key}")
for passage in book_passages:
    if passage.get("bookId") not in B: errors.append(f"{passage.get('id')}: ouvrage inconnu")
    if passage.get("pageStart") is not None and passage.get("pageStart") < 1: errors.append(f"{passage.get('id')}: pageStart invalide")
    if passage.get("pageEnd") is not None and passage.get("pageStart") is not None and passage["pageEnd"] < passage["pageStart"]: errors.append(f"{passage.get('id')}: intervalle de pages invalide")
    for event_id in passage.get("eventIds", []):
        if event_id not in E: errors.append(f"{passage.get('id')}: événement inconnu -> {event_id}")
orders = [e["sortOrder"] for e in events]
if orders != sorted(orders) or len(orders) != len(set(orders)): errors.append("events: sortOrder doit être unique et croissant")
for e in events:
    if e["periodId"] not in PE: errors.append(f"{e['id']}: période inconnue")
    if e["datePrecision"] not in ("exact", "approximate", "disputed"): errors.append(f"{e['id']}: datePrecision invalide")
    if e.get("status") not in ("draft", "reviewed", "published"): errors.append(f"{e['id']}: status invalide")
    if e.get("verificationStatus") not in ("reviewed", "needs_corroboration"): errors.append(f"{e['id']}: verificationStatus invalide")
    for k, ref in (("personIds", P), ("placeIds", PL), ("sourceIds", S)):
        for x in e.get(k, []):
            if x not in ref: errors.append(f"{e['id']}: {k} inconnu -> {x}")
used_p = {x for e in events for x in e["personIds"]}
used_pl = {x for e in events for x in e["placeIds"]}
for p in P - used_p: print(f"avertissement: personnage sans événement: {p}")
for p in PL - used_pl: print(f"avertissement: lieu sans événement: {p}")
for p in periods:
    if not any(e["periodId"] == p["id"] for e in events): print(f"avertissement: période vide: {p['id']}")
print(f"{len(events)} événements, {len(persons)} personnages, {len(places)} lieux, {len(sources)} sources, {len(books)} livres")
if errors:
    print("\n".join("ERREUR: " + e for e in errors)); sys.exit(1)
print("OK : données cohérentes")
