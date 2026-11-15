#!/usr/bin/env python3
"""Met à jour la vérification sans masquer les fiches publiées."""
import csv, json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
events_path = root / 'assets/data/events.json'
csv_path = root / 'docs/fiches_verification.csv'
with csv_path.open(encoding='utf-8-sig', newline='') as f:
    rows = list(csv.DictReader(f, delimiter=';'))
verified = {r.get('Event ID') for r in rows if (r.get('Editorial review') or '').strip().upper() == 'OK'}
events = json.loads(events_path.read_text(encoding='utf-8'))
for event in events:
    event['status'] = 'published'
    event['verificationStatus'] = 'reviewed' if event['id'] in verified else 'needs_corroboration'
events_path.write_text(json.dumps(events, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'{len(verified)} fiches vérifiées ; {len(events)-len(verified)} à corroborer. Toutes restent publiées dans la navigation.')
