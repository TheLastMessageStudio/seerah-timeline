# Fiche de vérification interne (un événement = une ligne de `fiches_verification.csv`)

Ouvre `fiches_verification.csv` dans Excel / LibreOffice (séparateur `;`, UTF-8).

| Colonne | À remplir |
|---|---|
| Event ID | Identifiant stable (ne jamais le changer) |
| Event title | Titre affiché |
| Historical period | Période |
| Primary references | Sources principales (Coran, Bukhari, Muslim, Ibn Hisham, Zad al-Ma'ad…) |
| Additional references | Références précises : sourate:verset, livre/chapitre/numéro de hadith, page |
| Authenticity / reliability notes | Fiabilité du RÉCIT (hadith, chaîne, avis des spécialistes) |
| Chronological certainty | Certitude de la DATE (établie / approximative / discutée) |
| Editorial review | `À faire` → `En cours` → `OK` |

Règle : la fiabilité d'un hadith et la certitude d'une date sont deux questions distinctes.

## Workflow
1. Vérifier l'événement sur les sources, compléter les références et corriger les textes dans
   `assets/data/events.json` et `assets/data/i18n/fr/events.json`.
2. Mettre `OK` dans « Editorial review ».
3. `python3 tools/apply_review.py` → les événements `OK` passent en `verificationStatus=reviewed`. Le statut de publication reste `published` ; les fiches restent visibles dans l’application.
4. `python3 tools/validate_data.py` → contrôle des relations (personnages, lieux, sources, traductions).

## Ajouter une langue
Copier `assets/data/i18n/fr/` vers `assets/data/i18n/en/` et traduire les valeurs (pas les identifiants).
Les dates, coordonnées, relations et niveaux de précision restent dans `assets/data/*.json`.
