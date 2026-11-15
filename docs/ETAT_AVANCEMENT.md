# Seerah Timeline — état d’avancement (V0.9.3)

Ce document distingue l’état de l’interface, l’intégration technique et la vérification historique. Une fiche visible comme publiée n’est pas automatiquement une fiche dont chaque détail est confirmé par les sources.

## Inventaire actuel

| Élément | Quantité / état | Note |
|---|---:|---|
| Événements | 79 | 71 événements de base conservés + 8 dossiers ajoutés en V0.8.0. Tous sont visibles comme publiés. |
| Vérification éditoriale | 0 relu / 79 à corroborer | `verificationStatus` conserve l’état réel de la revue ; aucun statut de validation n’a été inventé. |
| Personnages | 65 | Arbre familial interactif ; lignée paternelle affichée jusqu’à Adnân, puis branche familiale proche. |
| Lieux | 24 | Six sites secondaires ajoutés ; positions indicatives signalées dans les descriptions. |
| Ouvrages | 25 | Ibn Hishâm, collections de hadiths, Coran et six autres titres classiques / modernes de Sîra en catalogue. |
| Langues | FR / EN / AR | Données traduites ; relecture humaine encore nécessaire. |

## Changements V0.8.0

- Bibliothèque simplifiée : les fiches de livres ne montrent plus les URLs, notes de droits, longues notices d’édition ni références techniques. Le catalogue affiche le titre et l’auteur.
- Ajout de six titres de Sîra et d’histoire : al-Wâqidî, Ibn Saʿd, al-Tabarî, al-Balâdhurî, al-Bayhaqî et ar-Rahîq al-Makhtûm. Ils sont catalogués mais leur texte intégral n’est pas embarqué.
- La fiche d’Ibn Hishâm est épurée. Son texte intégral n’est pas encore intégré : le scan ancien et l’OCR consultés nécessitent une transcription et une vérification page par page.
- Les fiches d’événements n’affichent plus le badge « brouillon », les longues listes de références ni les URLs brutes. Les textes de sources déjà intégrés restent accessibles dans des panneaux repliables.
- Arbre familial interactif avec noms cliquables, ancêtres de la lignée paternelle jusqu’à Adnân, famille proche, épouses, enfants et petits-enfants. Les filiations antérieures à Adnân ne sont pas présentées comme certaines.
- Huit nouveaux dossiers : Banû Qaynuqâ, Banû Nadîr, Banû al-Mustaliq, Banû Qurayza, Dhât ar-Riqâʿ, Wâdî al-Qurâ, siège de Tâ’if et délégation de Thaqîf.
- Synthèses thématiques enrichies pour Makkah, Médine, Taïf et l’Abyssinie.


## Changements V0.8.1

- L’arbre généalogique est désormais réservé à Premium ; un écran de présentation et un accès direct à l’offre Premium remplacent l’arbre pour les comptes non Premium.
- À l’ouverture, la vue se centre automatiquement sur le nœud de Muhammad ﷺ ; une action dans la barre supérieure permet de recentrer à tout moment.
- Ajout d’un quiz bonus de deux questions à la fin de chaque fiche : période historique et précision chronologique. Les réponses sont expliquées immédiatement ; le quiz fonctionne hors ligne et dans les trois langues.
- La fiche bibliothèque identifie clairement les ouvrages dont le texte intégral n’est pas encore intégré. Le script actuel n’importe toujours que les corpus arabes de hadiths et le Coran.
- Premier lot éditorial approfondi : naissance, décès de ʿAbd Allâh, allaitement chez Halîma, ouverture de la poitrine et décès d’Âmina. Les formulations distinguent les hadiths identifiés des récits de Sîra et des synthèses modernes ; les points non collationnés restent signalés.

## Limites connues

- Le contenu des 71 fiches historiques initiales n’a pas encore fait l’objet d’une réécriture détaillée et d’une corroboration indépendante, événement par événement. Le retrait du badge brouillon concerne uniquement la présentation ; `verificationStatus` reste `needs_corroboration` tant que la fiche n’a pas été relue.
- Les huit nouveaux dossiers sont trilingues et détaillés, mais leurs dates, variantes narratives et détails doivent encore être confrontés aux éditions de référence.
- Le texte intégral d’Ibn Hishâm et celui des autres ouvrages de Sîra ne sont pas inclus. Aucun texte moderne protégé n’est redistribué sans licence.
- Flutter et Dart ne sont pas installés dans l’environnement de préparation ; `flutter analyze`, `flutter test` et les tests sur Android doivent être exécutés sur un poste équipé.

## Contrôles exécutés

- `python tools/validate_data.py` : relations, traductions, identifiants et ordre chronologique des données JSON.
- `python tools/audit_editorial.py` : inventaire des événements et structure du CSV de vérification.
- `python -m py_compile` sur les scripts Python d’import et de validation.

## Prochaines étapes éditoriales

1. Réécrire en profondeur les 71 fiches initiales, en commençant par les événements majeurs de la période mecquoise et médinoise.
2. Vérifier chaque récit avec au moins une référence localisée dans une édition déterminée ; distinguer Coran, hadith, Sîra et synthèse moderne.
3. Documenter les divergences de dates et de versions sans imposer une certitude artificielle.
4. Transcrire et collationner les passages d’Ibn Hishâm depuis une édition vérifiée, puis étudier les droits de chaque transcription.
5. Tester l’arbre, la navigation, le RTL, la recherche, les achats et la lecture hors ligne sur appareil Android.

## Changements V0.9.1

- Accueil remanié avec menu latéral principal, raccourcis de navigation et bloc « Dernières sorties ».
- Nouvel onglet Calendrier avec grille mensuelle et tableau de 4 semaines préremplies, 5 fiches planifiées par semaine (20 au total).
- Lot éditorial 02 : cinq fiches approfondies en FR/EN/AR ; Sahih al-Bukhari 2262 ajouté comme texte source pour la fiche du berger.
- Sept livres de Sîrah disposent de dossiers de lecture synthétiques trilingues. Ils ne remplacent pas les textes intégraux ; les liens vers les sources externes sont accessibles depuis la fiche livre.
- Photos contemporaines de Jabal al-Nour/Hira et du site de Badr ajoutées aux fiches lieux/événements via Wikimedia Commons, avec crédits et licences affichés. Les photos nécessitent une connexion.
- Le mode de test Premium dans les réglages est mémorisé sur les builds debug ; il déverrouille les contenus pour essais sans achat réel.


## Changements V0.9.1

- Lecteur PDF intégré via `pdfrx` : Ibn Hishâm vol. 1, Ibn Saʿd vol. 1 (scan public domain Wikisource), al-Ṭabarī vol. 1–2 et al-Balādhurī vol. 1. Les PDF sont lus en ligne et ne sont pas embarqués dans l'APK.
- Liens externes de lecture ajoutés pour al-Wāqidī (transcription numérique de l'édition Marsden Jones), Ibn Saʿd (Internet Archive/Waqfeya), al-Bayhaqī (texte OpenITI sous CC BY-NC-SA 4.0) et ar-Raḥīq al-makhtūm (Waqfeya).
- Carte enrichie : après sélection de Makkah, Médine ou une autre ville, les points secondaires sont visibles et cliquables ; le panneau de ville et les lieux affichent des photos contemporaines créditées. 75/79 événements ont maintenant un lieu illustré.
- Calendrier porté à 15 semaines (74 fiches planifiées après les cinq fiches du lot 01 déjà disponibles), tableau avec hauteur de ligne corrigée et compte à rebours accessible depuis l'accueil et le calendrier.
- Verrouillage par date appliqué aux événements et aux lieux/personnes liés aux sorties futures. Le mode « administrateur (test) » dans les réglages debug contourne tous les verrous Premium et les dates de sortie.
- Le validateur accepte le dernier lot de quatre fiches et vérifie l'absence de doublons dans le calendrier.


## Changements V0.9.3 — refonte éditoriale et lecture

- Les résumés FR/EN/AR ont été enrichis à partir des paragraphes déjà présents dans chaque fiche, sans introduire de faits externes non sourcés. Moyenne indicative après enrichissement : environ 38 mots en français, 37 en anglais et 25 en arabe ; les fiches arabes très brèves restent à reprendre manuellement.
- Dans le détail, les paragraphes dont le titre concerne la datation ou la chronologie sont désormais regroupés dans un panneau repliable « Date et chronologie ». La précision et les limites de datation restent accessibles sans interrompre le récit.
- Ajout d’un panneau repliable de références bibliographiques sur chaque événement.
- La galerie d’un événement affiche toutes les photos de lieux associées, plutôt qu’une seule photo.
- La page d’accueil reçoit une zone d’introduction plus aérée et une hiérarchie visuelle renforcée.
- Le lecteur de lieux prend en charge des images locales (`imageAsset`) avant tout recours à une URL. Le script `tools/download_place_images.py` prépare les photos Wikimedia déjà créditées pour un paquet hors ligne ; il n’a pas pu être exécuté ici faute d’accès réseau depuis l’environnement de préparation.
- La bibliothèque ne propose plus de bouton ouvrant les pages de lecture externes. Les PDF qui existent restent accessibles dans le lecteur intégré, mais ils sont encore hébergés à distance et nécessitent une connexion. Les livres sans texte/PDF intégré sont explicitement indiqués comme non intégrés.
- Ajout de trois repères géographiques : al-Abwâʾ, la mosquée al-Qiblatayn et la plaine d’Arafat. Ils sont reliés respectivement au décès d’Âmina, au changement de qibla et au pèlerinage d’adieu. Les points représentent des localités ou repères actuels, pas une localisation archéologique certifiée.

### Limites à traiter dans le lot suivant

- Le téléchargement des images n’a pas pu être effectué dans cet environnement : les fichiers photo ne sont donc pas encore embarqués dans cette archive. Sur un poste connecté, lancer `python tools/download_place_images.py`, puis `flutter pub get`.
- Les PDF de la bibliothèque ne sont pas encore stockés localement dans l’APK ; il faut vérifier les droits édition par édition avant de les redistribuer hors ligne.
- Les résumés arabes et les détails de toutes les fiches doivent encore faire l’objet d’une réécriture éditoriale manuelle et d’une corroboration source par source.
- La compilation Flutter et les tests Android n’ont pas pu être exécutés ici, car Flutter/Dart ne sont pas installés.


## Changements V0.9.3 — préparation éditoriale 1.0

- Les 79 événements ont été repris sans exception dans les trois langues. Chaque fiche possède un résumé d’au moins 45 mots et une structure identique de quatre parties : contexte et cadre, récit et déroulement, portée et enseignements, sources et niveau de preuve. Les notes de datation restent séparées dans le panneau repliable.
- Les résumés ont été développés à partir du texte déjà présent dans chaque fiche ; les sections courtes ont été complétées avec le contexte de leur période, les résumés, les notes de sources et les références déjà recensées. Aucun statut de vérification n’a été promu.
- Les 68 biographies disposent de trois parties structurées : parcours dans la Sîra, liens familiaux/généalogiques et précautions de lecture. Les événements associés sont présentés avec un résumé et ouvrent directement la fiche correspondante.
- L’arbre familial précise les liens maternels explicitement retenus pour les enfants du Prophète ﷺ, de Fâtima et de Zaynab. Les nœuds, conjoints et enfants restent cliquables. Les biographies exposent les mêmes liens sous forme de puces ouvrant les notices associées.
- La carte n’affiche plus les villes principales lorsqu’une ville est sélectionnée : les sites secondaires reprennent leur place sur le fond, avec étiquettes espacées et lignes de repère. Six lieux sont ajoutés : Dâr al-Arqam, al-Safâ/al-Marwa, Mosquée du Prophète, zone du Fossé, Tabuk et Muzdalifah.
- Le fond cartographique reste entièrement local : contours de relief stylisés, itinéraires régionaux schématiques, noms des mers et régions. Les itinéraires ne sont pas des routes de navigation et les sites historiques à localisation incertaine sont indiqués comme approximatifs.
- Menu latéral, typographie, panneaux de lecture et cartes de biographies harmonisés autour du vert profond, du parchemin et de l’or.
- Version de projet : `0.9.3+14`.

### Limites de préparation 1.0

- La reprise éditoriale porte sur les 79 fiches, mais les développements utilisent les données, références et notes déjà présentes dans le projet. Elle ne constitue pas une collation primaire complète de chaque récit.
- Les 79 fiches restent `needs_corroboration`. Les citations de hadith déjà importées gardent leur portée précise ; une référence générale à Ibn Hishâm ou à une chronique ne confirme pas automatiquement chaque détail.
- La Sîra d’Ibn Ishâq est connue notamment par la recension abrégée et remaniée d’Ibn Hishâm ; le texte doit être lu comme une tradition transmise, non comme un journal contemporain. Voir la notice de présentation du texte par Islam Museum et la revue critique du genre de la Sîra.
- Les textes arabes et les traductions EN/AR nécessitent une relecture humaine par une personne compétente, en particulier les formulations générées à partir des résumés et les termes généalogiques.
- La carte est plus détaillée, mais elle n’utilise pas les tuiles commerciales ou le réseau routier de Google Maps. Elle fonctionne hors ligne et signale les liaisons régionales comme schématiques.
- Flutter et Dart n’étant pas installés dans l’environnement de préparation, la compilation, `flutter analyze`, les tests Flutter et les essais sur Android restent à exécuter sur un poste équipé.


## Changements V0.9.4 — audit des 79 événements et 68 biographies

- Passage de couverture sur les 79 événements, avec matrice `AUDIT_79_EVENEMENTS.csv`. 48 événements disposent d’une preuve ciblée attachée ; 31 restent à collationner sur des passages précis. Tous conservent `needs_corroboration`.
- Vérification des 68 biographies existantes, correction des relations collatérales, ajout de Zaynab bint Khuzayma, Umayma bint Abd al-Muttalib et Abu Sufyan (68 personnages).
- Liens de cousins, oncles/tantes, frères/sœurs, grands-parents, nourrice et ancienne adoption affichés dans les biographies.
- Six illustrations originales WebP locales ajoutées et reliées aux fiches de lieux et aux galeries des événements.
- Version de projet : `0.9.4+15`.
- Limites : les 32 dossiers sans preuve ciblée ne sont pas validés historiquement ; les photos Wikimedia non embarquées restent en ligne ; Flutter/Dart non disponibles pour compilation et tests dans l’environnement de préparation.

## V0.9.5 — Préparation de l'accès Patreon (2026-11-15)

- Migration de la source Premium Flutter vers `PatreonService`.
- Préparation OAuth Patreon API v2, retour deep link Android, session d'application sécurisée et vérification côté serveur.
- Préparation d'un backend Node.js + PostgreSQL avec stockage chiffré des jetons Patreon.
- Webhooks v2 `members:create`, `members:update`, `members:delete`.
- Mapping multi-niveaux vers les droits `events`, `biographies`, `map`, `family_tree`, `library`.
- Cache local sécurisé de 24 h maximum pour l'accès hors ligne.
- Configuration réelle non activée : identifiants Patreon, IDs de tiers, URL backend, base PostgreSQL et intent filter Android restent à renseigner.
- Tests Flutter non exécutés dans l'environnement de préparation (SDK Flutter/Dart absent).
