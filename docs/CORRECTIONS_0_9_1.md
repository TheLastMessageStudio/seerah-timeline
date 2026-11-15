# Correctifs v0.9.1 — compilation, fiches, hadiths et quiz

## Compilation Android

- `ReleaseScreen` lit maintenant l'identifiant ciblé via `widget.eventId` (la propriété appartient au widget, pas à son State).
- `pdfrx` est épinglé exactement à `1.3.2`. La contrainte `^1.3.2` laissait Pub installer `1.3.5`, qui échouait avec les erreurs de null-safety observées sur certains environnements Dart/Flutter.
- La version Flutter/Dart minimale du projet n'a pas été modifiée dans ce correctif.

Après remplacement du projet sous Windows :

```powershell
flutter clean
flutter pub get
flutter run
```

Si Pub garde une ancienne résolution, supprimer `pubspec.lock` (s'il existe), puis relancer `flutter pub get`.

## Fiches et références de hadith

- Le mode détaillé est désormais affiché par défaut afin que les paragraphes développés soient visibles dès l'ouverture d'une fiche.
- Les fiches déjà documentées par un hadith conservent leurs références antérieures.
- Des références directes supplémentaires ont été ajoutées pour l'émigration et la grotte de Thawr, Badr, Uhud, al-Khandaq, al-Hudaybiyya, Khaybar, Mu'ta, Hunayn, Tabuk, le pèlerinage d'adieu, le décès du Prophète ﷺ, l'Isrâʾ, l'arrivée à Médine, la mosquée prophétique, Bayʿat ar-Ridwân, la conquête de Makkah et la prière funéraire du Négus.
- Quand le texte arabe intégral n'est pas fourni dans les données locales, l'application indique explicitement qu'il s'agit d'un résumé de la narration, et propose un bouton ouvrant la référence dans le recueil en ligne. Le résumé n'est pas présenté comme une citation verbatim.
- Aucun hadith n'est inventé pour les épisodes qui ne disposent pas d'une attestation directe identifiée dans les recueils consultés. Les récits biographiques restent attribués aux sources de Sîra correspondantes.

## Quiz

Les deux questions sont maintenant construites à partir des sections de la fiche ouverte : le lecteur doit associer un extrait réel au thème traité. Les formulations et les choix varient selon la fiche et les sections, au lieu de répéter les questions génériques sur la période et la précision chronologique.

## Limites de vérification

Les validateurs Python et la cohérence JSON sont exécutés sur le projet. Aucun `flutter analyze`, `flutter test` ni build Android ne peut être déclaré réussi depuis cet environnement, car le SDK Flutter n'y est pas installé. Le test final doit être fait sur le poste Windows avec les commandes ci-dessus.
