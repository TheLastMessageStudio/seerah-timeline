# Seerah Timeline — préparation 1.0 (V0.9.3)

## Objectif de cette version

Harmoniser la lecture des 79 événements, enrichir les biographies des 65 personnages, relier les biographies à l'arbre familial, restaurer les lieux secondaires sur la carte et donner une finition plus éditoriale à la navigation.

## Événements : 79 sur 79

Chaque événement dispose dans FR / EN / AR :

1. d'un résumé développé (au moins 45 mots) ;
2. d'un contexte et cadre ;
3. d'un récit et déroulement ;
4. d'une portée et de repères de compréhension ;
5. d'une partie sources et niveau de preuve.

Les notes de chronologie sont conservées dans la section repliable « Date et chronologie ». Les références et les textes de hadith déjà présents restent accessibles séparément.

**Limite éditoriale :** les sections ont été harmonisées et enrichies à partir des contenus, références et notes déjà présents dans le dépôt. Il ne s'agit pas encore d'une vérification savante complète, ligne par ligne, des 79 récits. Aucun événement n'a été marqué `reviewed` par simple effet de rédaction.

## Biographies : 65 sur 65

Les notices disposent de trois parties cohérentes :

- parcours dans la Sîra, relié aux événements existants ;
- liens familiaux et généalogiques, avec accès direct aux biographies des personnes apparentées ;
- précautions de lecture sur les sources et les chaînes généalogiques.

L'arbre conserve la limite généalogique retenue jusqu'à Adnân. Les liens maternels sont affichés uniquement là où ils sont explicitement renseignés dans le modèle familial de l'application.

## Carte : 24 lieux

- Au premier niveau, seules les villes et régions principales sont affichées.
- Après sélection d'une ville, le marqueur principal disparaît et les sites secondaires apparaissent à leurs coordonnées, avec des étiquettes déplacées et reliées à leur ancrage pour éviter les superpositions.
- Six sites ajoutés : Dâr al-Arqam, al-Safâ/al-Marwa, Mosquée du Prophète, zone du Fossé, Tabuk et Muzdalifah.
- Le fond hors ligne comporte des repères régionaux, des courbes de relief stylisées et des liaisons régionales schématiques.

Les emplacements incertains sont explicitement décrits comme approximatifs. Cette carte est une carte pédagogique hors ligne, pas un service de navigation ni une copie de Google Maps.

## Sources et méthode

La méthode conserve la distinction entre texte coranique, hadith, récit de Sîra, chronique et synthèse moderne. Elle évite d'utiliser un hadith ciblé pour confirmer des détails qu'il ne rapporte pas.

Références consultées pour la méthode :

- Islam Museum, « The Sira of Ibn Ishaq in Ibn Hisham's recension » : https://www.islam.museum/en/work/sira-ibn-ishaq-ibn-hisham/ — présentation de la transmission et du remaniement de la Sîra attribuée à Ibn Ishâq par Ibn Hishâm.
- « A Critical and Historical Overview of the Sīrah Genre from the Classical to the Modern Period », *Religions* (2022) : https://www.mdpi.com/2077-1444/13/3/196 — aperçu des débats de critique des sources et de la transmission des récits.
- Sahih Muslim 160a, début de la révélation : https://sunnah.com/muslim:160 — référence ciblée pour le récit de la retraite à Hirâʾ et du commencement de la révélation.

## Contrôles et limites techniques

- `python tools/validate_data.py` : relations et traductions JSON.
- `python tools/audit_editorial.py` : inventaire des références et contrôle du CSV de vérification.
- Contrôle additionnel : 79 résumés trilingues, 4 sections principales par événement, 65 biographies avec 3 sections, 24 lieux et identifiants de lieux référencés.
- Flutter/Dart indisponibles dans l'environnement de préparation : la compilation et les tests Flutter ne sont pas certifiés. Avant publication, exécuter `flutter pub get`, `dart format lib test`, `flutter analyze` et `flutter test` sur Windows/Android.

## Statut de publication

Cette archive est une étape de préparation 1.0, pas une version déclarée prête à publier. Les 79 événements restent `needs_corroboration` et les traductions nécessitent une relecture humaine.
