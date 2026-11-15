# Seerah Timeline (V0.9.4 — audit historique et généalogique)

## Lancer
1. `flutter create . --platforms=android`  (génère `android/` sans écraser `lib/` ni `pubspec.yaml`)
2. `flutter pub get`
3. `dart run flutter_launcher_icons`   (icône de l'app)
4. `flutter test`  puis  `flutter run`

## Architecture
- Riverpod (`lib/state/providers.dart`) pour l'état, GoRouter (`lib/app/router.dart`) pour la navigation.
- Données éditoriales JSON locales (`assets/data/`) ; certains PDF et visuels restent hébergés à distance tant que leurs fichiers n'ont pas été intégrés au paquet.
- Favoris, progression et préférences : SharedPreferences.
- Accès Premium : vérification Patreon côté serveur. Les droits ne sont pas mis en cache hors ligne : en cas d’indisponibilité du serveur, l’application repasse en accès gratuit jusqu’à vérification.
- Patreon : Traveller (2 $) reste sans droit Premium ; Explorer (5 $) et Companion (10 $) donnent les mêmes droits Premium.
- La migration PostgreSQL compatible Supabase se trouve dans `supabase/migrations/`. Supabase Auth n’est pas encore intégré : l’association Patreon est actuellement liée à une installation de l’application.

## Contenu (79 événements publiés, 68 personnages, 24 lieux)
- Les événements sont visibles comme publiés. Le champ `verificationStatus` distingue les fiches relues (`reviewed`) de celles qui demandent encore une corroboration (`needs_corroboration`).
- Fiches de vérification : `docs/fiches_verification.csv` (+ mode d'emploi `docs/FICHE_VERIFICATION.md`).
- `python3 tools/validate_data.py` : contrôle des relations et des traductions.
- `python3 tools/apply_review.py` : applique les validations « OK » du CSV.
- Langues : français, anglais, arabe (`assets/data/i18n/fr|en|ar`). L'interface est dans `lib/l10n/strings.dart`.
- Changer de langue : Accueil → Réglages → Langue (mise en page de droite à gauche automatique en arabe).
- Ajouter une langue : créer `assets/data/i18n/<code>/`, traduire les valeurs, ajouter le code dans `Strings.supported`
  et une colonne dans `lib/l10n/strings.dart`, puis déclarer le dossier dans `pubspec.yaml`.
- Les traductions anglaises et arabes doivent encore faire l’objet d’une relecture éditoriale complète.

## Publication
`docs/CHECKLIST_PUBLICATION.md` (tests et étapes) et `store/play_store_fr.md` (fiche Play, icône 512, bannière).

## Bibliothèque des ouvrages (première étape)
- Un onglet Bibliothèque est disponible en français, anglais et arabe.
- Le catalogue comprend désormais Ibn Hishâm, des collections de hadiths, le Coran arabe et plusieurs ouvrages classiques de Sîra en notices courtes.
- La recherche tolère plusieurs variantes de l’arabe (hamza/alif, ya/alif maqsura, ta marbuta, diacritiques).
- Les fiches d’ouvrage sont volontairement épurées : titre, auteur, courte présentation et accès au lecteur lorsqu’un corpus est réellement disponible.
- Le schéma `assets/data/book_passages.json` permet d’ajouter des passages vérifiés, leur texte arabe, les pages et les événements associés.
- Aucun texte intégral d’Ibn Hishâm ni des autres ouvrages de Sîra n’est encore embarqué ; les éditions et les droits des transcriptions doivent être vérifiés avant import.
- Voir `docs/ETAT_AVANCEMENT.md` pour le suivi des exigences, des ajouts et des tâches restantes.


## Bibliothèque et lecteur (0.5.0)

- Catalogue d’ouvrages et fiche de provenance.
- Lecteur prêt pour l’import de passages vérifiés : recherche arabe normalisée, filtre par chapitre, affichage des volumes/pages disponibles et reprise locale de la position.
- La fiche Ibn Hishâm référence provisoirement le fac-similé de l’édition Wüstenfeld (1858–1860) signalé comme domaine public par Wikisource. L’index Wikisource nécessite correction et l’OCR Internet Archive est fortement dégradé ; aucun texte OCR ni pagination n’est embarqué dans cette version.
- La carte historique reste schématique et hors ligne ; son fond et ses repères ont été retravaillés sans API cartographique.
- Quatre événements existants ont reçu des références précises (Muslim 1162e, Bukhari 2262, 3, 5217) et des notes éditoriales traduites ; les autres événements restent à vérifier.
- Thème clair/sombre harmonisé autour du vert profond, du parchemin et d’accents dorés discrets.

Voir `docs/SOURCES_AND_RIGHTS.md`, `docs/REVUE_HISTORIQUE.md` et `docs/ETAT_AVANCEMENT.md` pour les limites et la suite.


## Version 0.6.0 — bibliothèque et carte

La bibliothèque référence désormais Ibn Hishām, Ṣaḥīḥ al-Bukhārī et Ṣaḥīḥ Muslim. Les collections de hadiths sont consultables intégralement via leurs sources en ligne ; elles ne sont pas embarquées dans le paquet. Le texte arabe intégral d’Ibn Hishām n’est pas encore intégré : le fac-similé ancien est référencé, mais les OCR publics consultés nécessitent une correction page par page.

La carte affiche les villes/régions seulement. Sélectionner une ville zoome dans la carte existante et fait apparaître les événements associés, avec une texture de parchemin. Les lieux proches sont regroupés sous leur ville/région de référence.


## Corpus arabes hors ligne (V0.7.0 — conservé en V0.8.0)

Le catalogue propose les ouvrages de Sîra, 17 collections de hadiths et le Coran arabe. Pour importer les textes complets sur votre machine (Python 3 + Internet) :

```powershell
python tools/import_corpora.py
flutter pub get
flutter run
```

Ou exécutez `tools/import_corpora.ps1` sous PowerShell. Le script récupère les textes arabes et les métadonnées, exclut les traductions dont les droits sont distincts et vérifie la présence de Bukhari et Muslim ainsi que les 6 236 versets du Coran. Les textes arabes importés doivent encore être comparés aux éditions imprimées pour les variantes et références. Voir `docs/CORPUS_IMPORT.md` et `docs/SOURCES_AND_RIGHTS.md`.


## Version 0.8.0 — interface éditoriale et arbre familial

- Fiches de livres simplifiées : titre, auteur, présentation courte et accès au lecteur. Les liens techniques, notices de droits et longues métadonnées restent dans les données de maintenance, pas dans l’interface.
- Les références brutes et liens de consultation ne sont plus affichés en bloc dans les fiches d’événements ; les données de provenance restent conservées dans les fichiers.
- Ajout d’un arbre familial interactif : lignée paternelle jusqu’à Adnân, branche des Banû Hâshim, épouses, enfants et petits-enfants. Chaque nom ouvre sa fiche.
- Ajout de dossiers sur Banû Qaynuqâ, Banû Nadîr, Banû al-Mustaliq, Banû Qurayza, Dhât ar-Riqâʿ, Wâdî al-Qurâ, le siège de Tâ’if et la délégation de Thaqîf.
- Les entrées sont publiées dans la navigation sans badge « brouillon ». Le champ `verificationStatus` conserve séparément les besoins de corroboration historique : « publié » ne signifie pas que chaque détail de la tradition est unanimement établi.
- Les pages de Makkah, Médine, Taïf et Abyssinie ont reçu des synthèses thématiques.

> **Correctif PDF Android (pdfrx 1.3.2)** : si le compilateur Dart signale que `blockSize` ou `read` ne peuvent pas être appelés sur `PdfFileCache?`, exécuter `flutter pub get`, puis `powershell -ExecutionPolicy Bypass -File .\tools\patch_pdfrx.ps1`, puis `flutter run`. Voir `docs/CORRECTIF_PDFRX_WINDOWS.md`.


## Version 0.9.2 — lecture enrichie, dates repliables et carte

- Résumés trilingues enrichis à partir des contenus déjà présents ; les détails de datation sont regroupés dans un panneau ouvrable/fermable.
- Références bibliographiques disponibles dans un panneau séparé sur chaque événement.
- Galerie horizontale des photos des différents lieux liés à un événement.
- Accueil aéré avec un en-tête éditorial et une hiérarchie visuelle plus lisible.
- Carte : les lieux secondaires apparaissent dans une liste de repères à proximité après sélection d'une ville, au lieu de se superposer sur la carte. Trois lieux ont été ajoutés : al-Abwâʾ, al-Qiblatayn et Arafat.
- Les boutons qui ouvraient les pages de lecture des ouvrages à l'extérieur de l'application ont été retirés. Les PDF disponibles s'ouvrent dans le lecteur intégré ; ils nécessitent encore une connexion tant qu'ils ne sont pas embarqués.
- Pour préparer les photos Wikimedia en local : `python tools/download_place_images.py`. Le script conserve les auteurs, licences et pages sources dans `assets/images/media_manifest.json`.

Voir `docs/REFONTE_EDITORIALE_V0_9_2.md` pour le plan des lots éditoriaux et `docs/ETAT_AVANCEMENT.md` pour les limites restantes.


## Version 0.9.3 — préparation éditoriale et carte détaillée

- Les 79 événements ont désormais un résumé trilingue plus développé et quatre sections de lecture harmonisées : contexte, récit, portée et sources. Les notes de datation restent dans un panneau séparé.
- Les 65 biographies de la V0.9.3 sont organisées autour du parcours dans la Sîra, des liens familiaux/généalogiques et des précautions de lecture. Les liens de parenté sont cliquables et ouvrent les biographies correspondantes.
- La carte affiche uniquement les villes principales au premier niveau ; après sélection, celles-ci disparaissent et les sites secondaires apparaissent sur la carte avec des étiquettes espacées. Six repères ont été ajoutés : Dâr al-Arqam, al-Safâ/al-Marwa, la Mosquée du Prophète, la zone du Fossé, Tabuk et Muzdalifah.
- Le fond cartographique local comporte davantage de repères régionaux, de courbes de relief stylisées et d’liaisons régionales schématiques. Il reste une carte illustrative hors ligne, et non une reproduction des routes de Google Maps.
- Le menu latéral, les cartes de lecture, l’arbre et les éléments de navigation ont reçu une finition plus éditoriale, vert profond et or.
- Les 79 événements restent `needs_corroboration` : l’enrichissement rédactionnel n’équivaut pas à une validation historique indépendante. Les traductions EN/AR nécessitent encore une relecture humaine.
- La version Dart/Flutter n’a pas pu être compilée dans l’environnement de préparation ; lancer `flutter analyze` et `flutter test` sur un poste Flutter avant publication.

Voir `docs/PREPARATION_1_0_V0_9_3.md` pour le détail des changements, des sources et des limites.


## Version 0.9.4 — audit de couverture, parentés et illustrations hors ligne

- Audit de couverture des 79 événements et de leurs références : 48 ont une preuve ciblée enregistrée, 31 restent à collationner dans une édition identifiée. Aucun statut historique n’est artificiellement validé.
- Relations familiales enrichies : cousins, frères et sœurs, oncles/tantes, grands-parents, liens nourriciers et ancien lien d’adoption distingué de la filiation biologique.
- Ajout de Zaynab bint Khuzayma, Umayma bint Abd al-Muttalib et Abu Sufyan ; le catalogue passe à 68 personnages et relie les branches familiales de Zaynab bint Jahsh et Umm Habiba.
- Six illustrations originales optimisées en WebP sont intégrées localement et s’affichent hors ligne pour Makkah, Hira, Thawr, Madinah, Badr et Khaybar. Elles sont clairement étiquetées comme illustrations générées, non documentaires.
- Dossiers d’audit : `docs/AUDIT_COMPLET_79_ET_68.md`, `docs/AUDIT_79_EVENEMENTS.csv`, `docs/AUDIT_68_BIOGRAPHIES_ET_LIENS.csv`.

## Audit complémentaire — reprise sur V0.9.4 (15 novembre 2026)

- Base de travail : archive `seerah_timeline_v0_9_4_audit_genealogie_images.zip` (version Flutter `0.9.4+15`).
- Premier lot traité : `abdullah_death`, `halimah_nursing`, `aminah_death`, `guardianship`, `syria_trip`.
- Ajout de cinq notices sourcées dans `assets/data/event_evidence.json` et de références ciblées dans `docs/AUDIT_79_EVENEMENTS.csv`.
- Les cinq statuts restent `needs_corroboration` : les divergences de chronologie, l’isnād ou l’historicité doivent encore être examinés. Aucun cas n’a été déclaré définitivement vérifié.
- Les 48 entrées qui avaient déjà une preuve ciblée sont conservées sans modification.


## V0.9.5 — Préparation Patreon

Cette version prépare la connexion OAuth Patreon API v2 et la gestion de droits Premium par niveaux. Voir `docs/patreon/ARCHITECTURE.md` et `backend/`. L'intégration n'est pas activable tant que le backend n'est pas déployé, que les identifiants Patreon et IDs des tiers ne sont pas configurés et que le deep link Android n'est pas ajouté au projet de plateforme.
