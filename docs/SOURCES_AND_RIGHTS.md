# Ibn Hishâm — édition de référence et provenance

## Édition de référence retenue

- Auteur : ʿAbd al-Malik ibn Hishâm, transmettant et remaniant la Sîra d’Ibn Isḥâq.
- Éditeur scientifique : Ferdinand Wüstenfeld.
- Publication : Göttingen, Dieterichsche Universitäts-Buchhandlung, 1858–1860.
- Structure bibliographique : deux tomes en trois volumes. Le tome I contient le texte arabe en deux parties : 1858 (540 pages), puis 1859 (pagination imprimée 541–1026). Le tome II (1860) contient introduction, notes et index.
- Notice BnF : https://catalogue.bnf.fr/ark:/12148/cb32268200q
- Notice Qatar National Library : https://ediscovery.qnl.qa/islandora/object/QNL:00018327 — statut de droits indiqué : « No Known Copyright ».
- Scan Wikisource actuellement référencé dans l’application : https://ar.wikisource.org/wiki/ملف:السيرة_النبوية_لابن_هشام.pdf (fichier PDF signalé domaine public, 1 388 pages). L’index Wikisource signale cependant « يحتاج إلى تصحيح » (nécessite correction) et un index non vérifié/non intégré.

## Recherche d’une version TXT

Internet Archive met à disposition le texte OCR de la première partie de l’édition Wüstenfeld (1858), identifiant `bub_gb_GH8pAAAAYAAJ` : https://archive.org/stream/bub_gb_GH8pAAAAYAAJ/bub_gb_GH8pAAAAYAAJ_djvu.txt. La fiche indique un OCR Tesseract configuré avec `-l deu` malgré un script détecté comme arabe. L’examen du texte montre une corruption importante et un mélange de caractères arabes et latins. Cette transcription n’est donc pas assez fiable pour être embarquée ni pour générer des pages/chapitres automatiquement.

## Texte consultable en ligne, non embarqué

Shamela référence une autre édition : édition critique de Muṣṭafā al-Saqqā, Ibrāhīm al-Abyārī et ʿAbd al-Ḥafīẓ Shalabī, deuxième édition, 1375 H / 1955, deux volumes, pagination conforme à l’imprimé : https://shamela.ws/index.php/book/23833. Elle est utile comme outil de recherche, mais ce n’est pas l’édition Wüstenfeld. Ses pages ne doivent pas être transférées à l’édition Wüstenfeld. Le texte et l’appareil éditorial de cette édition de 1955 ne sont pas embarqués ; leurs droits doivent être clarifiés avant toute redistribution dans l’application payante.

## Règles d’intégration

- Aucun OCR dégradé n’est inclus dans `assets/data/book_passages.json`.
- Aucun numéro de page n’est attribué à un événement sans contrôle du fac-similé et identification du volume/partie.
- Les titres ou repères d’une édition ne sont pas transférés vers une autre édition sans collation.
- Les corrections OCR doivent être conservées dans un journal de correction et ne jamais moderniser silencieusement le texte.
- Une éventuelle transcription sera accompagnée de sa provenance, de la date de contrôle et de son statut de droits.


## Collections de hadiths référencées dans la bibliothèque

Deux entrées supplémentaires sont désormais présentes dans le catalogue de l’application :

- **Ṣaḥīḥ al-Bukhārī** — Muhammad ibn Ismāʿīl al-Bukhārī (194–256 H), collection complète consultable sur https://sunnah.com/bukhari. Le catalogue de l’application référence la collection externe ; il n’en embarque pas le corpus complet ni une traduction.
- **Ṣaḥīḥ Muslim** — Muslim ibn al-Ḥajjāj al-Naysābūrī (204–261 H), collection complète consultable sur https://sunnah.com/muslim. La numérotation varie selon les éditions et les sites : toute référence doit préciser son système de numérotation.

Les notices de ces deux ouvrages distinguent le texte classique des interfaces, bases de données et traductions numériques, qui peuvent avoir des conditions propres. Aucun corpus complet de hadiths n’est redistribué dans le ZIP. Les références ponctuelles déjà utilisées dans les événements restent explicites (par exemple Muslim 1162e, Bukhārī 2262, 3 et 5217) et leur portée est limitée à ce que rapporte effectivement chaque tradition.

## État du texte arabe d’Ibn Hishām

Le texte arabe intégral **n’est pas encore importé dans l’application**. Le fac-similé Wikisource de 1 388 pages est public-domain selon sa notice, mais ses pages OCR indiquent encore qu’elles nécessitent une correction. Une autre numérisation Wikisource, de 356 pages, est également signalée comme domaine public, mais ne constitue pas une transcription textuelle complète vérifiée. Les extraits OCR ne sont donc pas assimilés à un texte authentique et ne sont pas injectés dans le lecteur. Le lecteur conserve son schéma de passages contrôlés et attend une transcription arabe collationnée.

## Corpus arabes ajoutables hors ligne (V0.7.0)

- Hadith : `Jaguar16/open-hadith-data` (https://github.com/Jaguar16/open-hadith-data). Le dépôt annonce les données structurées sous CC0 1.0 et précise que les traductions anglaises proviennent de Sunnah.com et ont des conditions de redistribution distinctes. Le script `tools/import_corpora.py` n’importe donc que les champs arabes et les métadonnées. Le dépôt indique que l’extraction est automatique et recommande de vérifier les données dans des éditions authentifiées.
- Coran : `quran-json.risanb.com`, profil `text/uthmani`, attribution Tanzil. Le projet publie le texte arabe Tanzil sous CC BY 3.0 et demande une reproduction verbatim. Le script conserve l’attribution et ne télécharge pas de traductions.
- Les deux corpus complets ne sont pas inclus dans le ZIP source de cette version : le script les récupère depuis les sources lorsque l’utilisateur le lance sur sa machine. Cette limitation est volontaire, car l’environnement de construction ici ne permet pas de télécharger les archives binaires externes.
- Une base de données structurée n’est pas une édition critique : variantes, numérotation, isnads et classements doivent être confrontés à des éditions imprimées et validés avant publication savante.

## Dossiers de lecture Sîrah (v0.9.1)

Des dossiers de lecture éditoriaux ont été ajoutés à sept notices de la bibliothèque : Ibn Hisham, al-Waqidi, Ibn Saʿd, al-Tabari, al-Bayhaqi et Ar-Raheeq al-Makhtum. Ils proposent une méthode de lecture et des synthèses contextualisées en français, anglais et arabe. **Ils ne sont pas les textes intégraux des ouvrages** et ne comportent ni citations inventées ni pagination non vérifiée. Les ouvrages contemporains ne sont pas reproduits.

Le scan de l’édition de 1855 du *Kitab al-Maghazi* d’al-Waqidi est référencé sur Wikimedia Commons : https://commons.wikimedia.org/wiki/File:المغازي_(1855)_-محمد_بن_عمر_الواقدي.pdf. La notice signale le domaine public en Inde ; la portée territoriale de cette indication doit être vérifiée avant redistribution commerciale dans d’autres pays. Le PDF n’est pas embarqué dans cette version.

## Photographies de lieux (v0.9.1)

Les fiches de lieux et événements peuvent afficher des photographies contemporaines en ligne, avec crédit et licence visibles. Elles ne sont pas embarquées dans le paquet et nécessitent une connexion internet.

- **Jabal al-Nour / zone de Hira :** Sadath i, Wikimedia Commons, CC BY-SA 4.0. Fichier : https://commons.wikimedia.org/wiki/File:Jabal_al-Nour_And_cave_Hira.jpg. Licence : https://creativecommons.org/licenses/by-sa/4.0/.
- **Site de Badr :** Richard Mortel, Wikimedia Commons, CC BY 2.0. Fichier : https://commons.wikimedia.org/wiki/File:General_view_of_the_battlefield_and_burial_ground_of_Badr,_Saudi_Arabia,_site_of_the_historic_battle_between_the_Prophet_Muhammad_and_the_Quraysh_in_624_(7).jpg. Licence : https://creativecommons.org/licenses/by/2.0/.

Les légendes précisent qu’il s’agit de vues actuelles, pas de photographies de l’époque du Prophète ﷺ ni de preuve autonome de l’emplacement exact des événements anciens.


## Lecteur PDF et autres liens de lecture (v0.9.1)

Voir `LECTURE_PDF_ET_VISUELS.md` pour les quatre PDF du lecteur intégré, les sources externes de Waqidi, Ibn Saʿd, al-Bayhaqi et ar-Raheeq, ainsi que les crédits/licences des photos supplémentaires. Les PDF modernes dont les droits de redistribution ne sont pas clairement établis sont ouverts sur leur site source, pas copiés dans le paquet.
