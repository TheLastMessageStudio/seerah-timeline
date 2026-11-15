# Seerah Timeline (V0.4)

## Lancer
1. `flutter create . --platforms=android`  (génère `android/` sans écraser `lib/` ni `pubspec.yaml`)
2. `flutter pub get`
3. `dart run flutter_launcher_icons`   (icône de l'app)
4. `flutter test`  puis  `flutter run`

## Architecture
- Riverpod (`lib/state/providers.dart`) pour l'état, GoRouter (`lib/app/router.dart`) pour la navigation.
- Données 100 % locales : `assets/data/*.json` (structure) + `assets/data/i18n/fr/*.json` (textes traduisibles).
- Favoris, progression et préférences : SharedPreferences.
- Achat unique : `lib/services/purchase_service.dart` (in_app_purchase, produit `seerah_timeline_premium`).

## Contenu (71 événements, brouillon)
- Tout événement est marqué « Brouillon · à vérifier » tant que son `status` n'est pas `reviewed`.
- Fiches de vérification : `docs/fiches_verification.csv` (+ mode d'emploi `docs/FICHE_VERIFICATION.md`).
- `python3 tools/validate_data.py` : contrôle des relations et des traductions.
- `python3 tools/apply_review.py` : applique les validations « OK » du CSV.
- Langues : français, anglais, arabe (`assets/data/i18n/fr|en|ar`). L'interface est dans `lib/l10n/strings.dart`.
- Changer de langue : Accueil → Réglages → Langue (mise en page de droite à gauche automatique en arabe).
- Ajouter une langue : créer `assets/data/i18n/<code>/`, traduire les valeurs, ajouter le code dans `Strings.supported`
  et une colonne dans `lib/l10n/strings.dart`, puis déclarer le dossier dans `pubspec.yaml`.
- Les traductions anglaises et arabes sont à faire relire avec le contenu (même statut « brouillon »).

## Publication
`docs/CHECKLIST_PUBLICATION.md` (tests et étapes) et `store/play_store_fr.md` (fiche Play, icône 512, bannière).
