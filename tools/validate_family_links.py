#!/usr/bin/env python3
"""Contrôle que tous les identifiants du graphe familial existent."""
import json, re
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
people = {x['id'] for x in json.loads((ROOT/'assets/data/persons.json').read_text(encoding='utf-8'))}
source = (ROOT/'lib/features/family_tree_screen.dart').read_text(encoding='utf-8')
tree = source.split('const _tree =', 1)[1].split('/// Relations familiales', 1)[0]
ids = set(re.findall(r"_FamilyNode\('([^']+)'", tree))
for arr in re.findall(r'(?:spouses|mothers):\s*\[([^\]]*)\]', tree):
    ids.update(re.findall(r"'([^']+)'", arr))
explicit = source.split('const explicitKinship', 1)[1].split('final result', 1)[0]
relation_kinds = {'cousin','sibling','former_adoptive','foster_parent','foster_child'}
ids.update(x for x in re.findall(r"'([^']+)'", explicit) if x not in relation_kinds)
for a,b in re.findall(r"addParent\('([^']+)'\s*,\s*'([^']+)'\)", source): ids.update([a,b])
unknown = sorted(ids - people)
if unknown:
    raise SystemExit('Identifiants familiaux absents de persons.json: '+', '.join(unknown))
for fragment in ["'muhammad': {\n      'cousin': ['ali', 'jafar']", "'zaynab_bint_khuzayma': {'sibling': ['maymuna']}" ]:
    if fragment not in explicit:
        raise SystemExit('Lien familial clé manquant: '+fragment)
print(f'OK : {len(people)} personnes ; {len(ids)} identifiants de l’arbre et du graphe présents.')
