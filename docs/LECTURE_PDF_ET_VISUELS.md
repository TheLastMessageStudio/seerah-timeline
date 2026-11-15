# Lecteur PDF et atlas illustré — v0.9.1

## Lecteur PDF

Le lecteur intégré utilise `pdfrx` et ouvre les PDF distants sans les embarquer dans l'APK. Les quatre ouvrages dont le PDF a été vérifié :

- Ibn Hishām, *Tahdhīb Sīrat Ibn Hishām*, vol. 1, 1955, PDF basse résolution (35,92 Mo) : https://sites.dlib.nyu.edu/viewer/books/aub_aco002965/1
- Ibn Saʿd, *al-Ṭabaqāt al-kubrā*, édition Leiden/Brill 1322–1347 H, vol. 1, 442 pages, PDF 10,27 Mo, page Wikisource indiquant le domaine public : https://ar.wikisource.org/wiki/ملف:الطبقات_الكبرى1.pdf
- Al-Ṭabarī, *Tārīkh al-umam wa-al-mulūk*, vol. 1–2, 1908, PDF basse résolution (70,74 Mo) : https://sites.dlib.nyu.edu/viewer/books/aub_aco001205/display?lang=en
- Al-Balādhurī, *Ansāb al-ashrāf*, vol. 1, édition indiquée 1964?, PDF basse résolution (36,39 Mo) : https://sites.dlib.nyu.edu/viewer/books/columbia_aco003923/1

Les notices NYU indiquent que les documents de la collection sont dans le domaine public selon leur appréciation. Les PDF restent hébergés par NYU et sont chargés à la demande. Les autres ouvrages gardent un lien externe tant qu'une édition numérique lisible et réutilisable n'a pas été vérifiée. Ne pas traiter un scan OCR comme texte établi sans collation.

## Visuels

Les photos intégrées aux fiches et à la carte montrent des lieux actuels, pas leur état au VIIe siècle. Chaque image porte une légende, un auteur, une licence et un lien vers la source Commons. Les coordonnées des sites secondaires sont indicatives ; le zoom permet de voir leur emplacement relatif, sans prétendre fournir une localisation archéologique certifiée.

## Accès de test

Le commutateur « Mode administrateur (test) » n'existe que dans les builds debug. Il contourne les verrous Premium et les dates de sortie pour faciliter les essais. Il ne crée aucun droit d'achat et ne doit pas être exposé dans une version de production.

### Crédits photo supplémentaires

- Mina — Mahmoud Farrag, CC BY 3.0 : https://commons.wikimedia.org/wiki/File:Mina,_Mecca_Saudi_Arabia_-_panoramio.jpg
- Secteur de Thawr — King Eliot, CC BY-SA 4.0 : https://commons.wikimedia.org/wiki/File:Thawr_Area_in_Makkah.jpg
- Khaybar — Hardscarf, CC BY-SA 4.0 : https://commons.wikimedia.org/wiki/File:Khaybar_-_deserted_houses.jpg
- Aksoum — Jnyssen, CC BY-SA 4.0 : https://commons.wikimedia.org/wiki/File:Aksum_main_stelae.jpg
- Région de Muʿtah — Bashar Tabbah, CC BY-SA 4.0 : https://commons.wikimedia.org/wiki/File:Battle_of_Mu%27tah.jpg

Les images sont des vues contemporaines de ces régions ou vestiges. Elles ne prouvent pas l'emplacement exact d'un épisode ancien ni l'aspect des lieux au VIIe siècle.
- Al-Hudaybiyyah — GusJuned, CC BY-SA 3.0 : https://commons.wikimedia.org/wiki/File:Hudaibiyah_Mosque_-_panoramio.jpg

## Autres éditions consultables en ligne (sans intégration PDF)

- Al-Wāqidī, *al-Maghāzī*, éd. Marsden Jones, Dār al-Aʿlamī, 3e éd. 1989, 3 volumes : lecture numérique sur KetabOnline ; page Waqfeya distincte pour le scan de l’édition al-Saʿāda (1948). Le scan 1855 de Commons reste une autre édition, de faible définition.
- Ibn Saʿd, *al-Ṭabaqāt al-kubrā* : lecteur multi-volumes Internet Archive (OCR arabe à vérifier) et page Waqfeya pour l’édition al-Khānjī.
- Al-Bayhaqī, *Dalāʾil al-nubuwwa* : texte arabe consultable sur Ihya us Sunnah, dérivé d’OpenITI, CC BY-NC-SA 4.0 ; introduction éditoriale et numéros de notes absents. La clause non commerciale doit être respectée.
- Ṣafī al-Raḥmān al-Mubārakfūrī, *al-Raḥīq al-makhtūm* : page Waqfeya indiquant une édition Dar-us-Salam (1996), 503 pages, PDF téléchargeable depuis leur site. L’application ouvre la page source et ne redistribue pas ce PDF moderne.

Ces liens rendent les notices consultables, mais ne signifient pas que chaque édition peut être copiée ou redistribuée dans l’application.

Le lecteur `pdfrx` prend en charge Android, le chargement par URI et le chargement progressif des pages ; la sélection de texte est activée lorsque le PDF contient une couche de texte. Pour un build de production, après `flutter pub get`, exécuter `dart run pdfrx:remove_wasm_modules` avant `flutter build` afin de retirer les binaires WASM non nécessaires à Android.


## Préparation des photos hors ligne — V0.9.2

Le modèle `Place` accepte désormais `imageAsset`. `PlaceImage` donne la priorité à l'asset embarqué et ne retombe sur l'URL Wikimedia que si l'asset n'est pas disponible. Pour télécharger les images dont les URL, crédits et licences sont déjà renseignés dans `assets/data/places.json`, lancer depuis la racine :

```bash
python tools/download_place_images.py
flutter pub get
```

Le script n'accepte que les hôtes `upload.wikimedia.org` et `thumb.wikimedia.org`, limite la taille d'un fichier à 12 Mo et crée `assets/images/media_manifest.json` avec l'auteur, la licence et la page source. Les nouvelles localités al-Abwâʾ, al-Qiblatayn et Arafat n'ont pas encore de photo référencée ; elles ne reçoivent donc pas d'image inventée.
