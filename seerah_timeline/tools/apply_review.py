#!/usr/bin/env python3
"""Passe en 'reviewed' les événements dont la colonne « Editorial review » vaut OK
dans docs/fiches_verification.csv (ceux-ci n'affichent plus « Brouillon »).
Usage : python3 tools/apply_review.py"""
import csv, json, os
root = os.path.join(os.path.dirname(__file__), "..")
csv_path = os.path.join(root, "docs", "fiches_verification.csv")
ev_path = os.path.join(root, "assets", "data", "events.json")
events = json.load(open(ev_path, encoding="utf-8"))
ok = set()
with open(csv_path, encoding="utf-8-sig", newline="") as f:
    for row in csv.DictReader(f, delimiter=";"):
        if (row.get("Editorial review") or "").strip().lower() == "ok":
            ok.add(row["Event ID"])
n = 0
for e in events:
    new = "reviewed" if e["id"] in ok else "draft"
    if e["status"] != new: e["status"] = new; n += 1
json.dump(events, open(ev_path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(f"{len(ok)} événement(s) validé(s), {n} statut(s) modifié(s)")
