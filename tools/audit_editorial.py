#!/usr/bin/env python3
"""Audit rapide des références et traductions éditoriales."""
import csv
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "assets" / "data"
events = json.loads((DATA / "events.json").read_text(encoding="utf-8"))
precision = Counter(e.get("datePrecision", "missing") for e in events)
status = Counter(e.get("status", "draft") for e in events)
verification = Counter(e.get("verificationStatus", "not_recorded") for e in events)
missing_refs = [e["id"] for e in events if not e.get("references")]
print(f"Événements : {len(events)}")
print(f"Statuts de publication : {dict(status)}")
print(f"Statuts de vérification : {dict(verification)}")
print(f"Précision chronologique : {dict(precision)}")
print(f"Sans référence consultable : {len(missing_refs)}")
if missing_refs:
    print("À compléter : " + ", ".join(missing_refs))

with (ROOT / "docs" / "fiches_verification.csv").open(encoding="utf-8-sig", newline="") as f:
    rows = list(csv.reader(f, delimiter=";"))
invalid = [(i + 1, len(row)) for i, row in enumerate(rows) if len(row) != 8]
if invalid:
    raise SystemExit(f"CSV invalide (8 colonnes attendues) : {invalid}")
print(f"CSV de vérification : {len(rows) - 1} fiches, 8 colonnes chacune")
