# Tests indispensables avant publication

- [ ] `python3 tools/validate_data.py` sans erreur ; `flutter test` au vert
- [ ] Tous les événements s'affichent dans le bon ordre
- [ ] Dates approximatives / discutées clairement identifiées
- [ ] Références consultables sur chaque fiche ; tous les événements dont `verificationStatus` est `reviewed`
- [ ] Filtres et recherche fonctionnent
- [ ] Favoris conservés après fermeture ; progression conservée
- [ ] App utilisable sans Internet (mode avion)
- [ ] Achat Premium OK (compte testeur) ; restauration OK ; annulation / erreur gérées
- [ ] Textes arabes correctement affichés (appareils anciens inclus)
- [ ] Thème clair et sombre ; texte agrandi à 150 %
- [ ] Appareil Android modeste (2 Go de RAM) : fluidité de la carte et des listes
- [ ] Aucune représentation de personnes dans l'app, l'icône, les captures et la fiche Play Store

# Publication
1. `flutter create . --platforms=android` (si pas déjà fait)
2. `dart run flutter_launcher_icons`
3. Générer une clé de signature, configurer `android/key.properties`, puis `flutter build appbundle --release`
4. Play Console : créer l'app, produit intégré `seerah_timeline_premium` (non consommable, 4,99 €),
   remplir `store/play_store_fr.md`, déclarer la sécurité des données, tester en test interne puis production.
