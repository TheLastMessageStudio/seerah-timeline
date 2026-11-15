# Audit intégral des 79 événements et des 68 biographies — V0.9.4+15

## Résultat général

- **79 événements** relus individuellement au niveau des données, de leurs dates, des personnages, des lieux et des références enregistrées.
- **48 événements** possèdent au moins une preuve ciblée dans `event_evidence.json` (42 entrées hadith et 9 entrées coraniques, soit 51 éléments au total).
- **31 événements** n’ont pas de preuve ciblée enregistrée : ils possèdent des références bibliographiques, souvent générales, mais le passage exact n’est pas encore collationné dans une édition identifiée.
- **0 événement** n’est promu au statut `reviewed` par simple enrichissement rédactionnel : les 79 restent `needs_corroboration` tant que la collation n’est pas terminée.
- Les preuves ciblées ne valident que ce qu’elles rapportent explicitement ; elles ne valident pas automatiquement l’ensemble du récit ni sa date.

Le détail événement par événement se trouve dans `AUDIT_79_EVENEMENTS.csv`. Les biographies et leurs liens sont listés dans `AUDIT_68_BIOGRAPHIES_ET_LIENS.csv`.

## Références primaires ciblées actuellement enregistrées

- **Naissance du Prophète Muhammad ﷺ** (`birth_prophet`) — Sahih Muslim 1162e · Livre du jeûne, 13, hadith 256.
- **Décès d'Abdullah, père du Prophète ﷺ** (`abdullah_death`) — .
- **Allaitement chez les Banu Sa'd** (`halimah_nursing`) — .
- **L'épisode de la purification du cœur** (`chest_opening`) — Sahih Muslim 162c · Livre de la foi, 1, hadith 318.
- **Décès d'Aminah, mère du Prophète ﷺ** (`aminah_death`) — .
- **Tutelle d'Abd al-Muttalib puis d'Abu Talib** (`guardianship`) — .
- **Le Prophète ﷺ gardien de troupeaux** (`shepherd`) — Sahih al-Bukhari 2262 · Livre de la location, 37, hadith 3.
- **Voyage en Syrie avec Abu Talib** (`syria_trip`) — .
- **Le pacte des Fudul (Hilf al-Fudul)** (`hilf_fudul`) — .
- **Mariage avec Khadijah** (`marriage_khadijah`) — Sahih al-Bukhari 3816 · Mérites des Ansar, chapitre du mariage avec Khadija.
- **Reconstruction de la Ka'ba et arbitrage de la Pierre noire** (`kaaba_rebuild`) — .
- **Retraites dans la grotte de Hira** (`hira_retreat`) — Sahih al-Bukhari 3 · Livre du commencement de la révélation, hadith 3.
- **La première révélation** (`first_revelation`) — Sahih al-Bukhari 3 · Livre du commencement de la révélation, hadith 3 ; Coran · Sourate 96, Al-ʿAlaq 96:1–5.
- **Rencontre avec Waraqa ibn Nawfal** (`waraqah_meeting`) — Sahih al-Bukhari 3 · Livre du commencement de la révélation, hadith 3.
- **Les premiers croyants** (`first_believers`) — .
- **Les premières prières** (`first_prayers`) — .
- **La pause de la révélation et la sourate Al-Muddaththir** (`fatrah`) — Sahih al-Bukhari 4 · Livre du commencement de la révélation.
- **L'appel discret** (`secret_preaching`) — .
- **La maison d'al-Arqam** (`dar_arqam`) — .
- **L'ordre d'avertir les proches** (`warn_kin`) — Coran 26:214.
- **L'appel depuis la colline de Safa** (`safa_call`) — Sahih al-Bukhari 4770 · Tafsîr, commentaire de Coran 26:214.
- **Les accusations de Quraysh** (`quraysh_accusations`) — Coran 38:4.
- **La protection d'Abu Talib** (`abu_talib_protection`) — .
- **Persécution des croyants vulnérables** (`weak_persecuted`) — .
- **Les pressions de Quraysh sur Abu Talib** (`quraysh_pressure`) — .
- **La proposition de compromis de Quraysh** (`compromise_offer`) — Coran 109:1–6.
- **L'agression de 'Uqbah et la défense d'Abu Bakr** (`uqbah_abu_bakr`) — Sahih al-Bukhari 3678 · Mérites des Compagnons.
- **Conversion de Hamzah** (`hamzah_islam`) — .
- **Conversion de Umar ibn al-Khattab** (`umar_islam`) — .
- **Première migration vers l'Abyssinie** (`first_habasha`) — .
- **Seconde migration vers l'Abyssinie** (`second_habasha`) — .
- **L'audience devant le Négus** (`najashi_audience`) — .
- **Le boycott des Banu Hashim et Banu al-Muttalib** (`boycott`) — .
- **L'année de la tristesse** (`year_sorrow`) — .
- **L'appel présenté aux tribus** (`tribes_presentation`) — .
- **Le voyage à Taïf** (`taif_trip`) — Sahih al-Bukhari 3231 · Début de la création.
- **Retour à Makkah sous la protection de Mut'im** (`mutim_protection`) — .
- **Al-Isra wal-Mi'raj** (`isra_miraj`) — Sahih al-Bukhari 3207 · Livre du commencement de la création, récit du voyage nocturne.
- **L'obligation des cinq prières** (`five_prayers`) — Sahih al-Bukhari 349 · Livre de la prière, prescription de la prière lors de l’Isrâʾ.
- **La réaction de Quraysh** (`isra_reaction`) — .
- **Rencontre avec les Khazraj à Al-Aqabah** (`khazraj_meeting`) — .
- **Premier serment d'Al-Aqabah** (`first_aqabah`) — Sahih al-Bukhari 3893 · Mérites des Ansar, serment d’al-ʿAqaba.
- **Mission de Mus'ab ibn Umayr** (`musab_madinah`) — .
- **Second serment d'Al-Aqabah** (`second_aqabah`) — Sahih al-Bukhari 3892 · Mérites des Ansar, serment d’al-ʿAqaba.
- **Migration des compagnons vers Yathrib** (`companions_migrate`) — Sahih al-Bukhari 3905 · Livre des mérites des Ansar, émigration vers Médine.
- **Le complot de Dar an-Nadwa** (`dar_nadwa_plot`) — Coran 8:30.
- **La grotte de Thawr** (`thawr_cave`) — Sahih al-Bukhari 3905 · Livre des mérites des Ansar, chapitre de l’émigration.
- **La poursuite de Suraqa ibn Malik** (`suraqah`) — Sahih al-Bukhari 3908 · Mérites des Ansar.
- **Arrivée à Quba** (`quba_arrival`) — Sahih al-Bukhari 3932 · Livre des mérites des Ansar, arrivée du Prophète ﷺ à Médine.
- **Arrivée à Madinah** (`arrive_madinah`) — Sahih al-Bukhari 3932 · Livre des mérites des Ansar, arrivée du Prophète ﷺ à Médine.
- **Construction de la mosquée du Prophète ﷺ** (`masjid_nabawi`) — Sahih al-Bukhari 3932 · Livre des mérites des Ansar, construction de la mosquée.
- **La fraternisation entre Muhajirun et Ansar** (`muakhat`) — Sahih al-Bukhari 3780 · Mérites des Ansar, fraternisation entre Muhajirun et Ansar.
- **Le pacte de Madinah (Sahifa)** (`madinah_charter`) — .
- **L'institution de l'adhan** (`adhan`) — Sahih al-Bukhari 604 · Livre de l’appel à la prière, chapitre du début de l’adhân.
- **Le changement de qibla** (`qibla_change`) — Coran 2:144.
- **L'obligation du jeûne de Ramadan** (`ramadan_fasting`) — Coran 2:183–185 ; Sahih al-Bukhari 2001 · Livre du jeûne.
- **La bataille de Badr** (`badr`) — Sahih Muslim 1763 · Livre du jihad et des expéditions, chapitre du soutien des anges à Badr.
- **L’épisode des Banû Qaynuqâ** (`banu_qaynuqa`) — .
- **La bataille d'Uhud** (`uhud`) — Sahih al-Bukhari 4075 · Livre des expéditions, chapitre des blessures du Prophète ﷺ à Uhud.
- **L’épisode des Banû Nadîr** (`banu_nadir`) — Coran 59:2.
- **La bataille du Fossé (Al-Khandaq)** (`khandaq`) — Sahih al-Bukhari 4101 · Livre des expéditions, chapitre de la bataille du Fossé.
- **L’épisode des Banû Qurayza** (`banu_qurayza`) — Coran 33:26.
- **L’expédition contre les Banû al-Mustaliq** (`banu_mustaliq`) — Sahih al-Bukhari 4141 · Livre des expéditions, récit de l’Ifk.
- **L’expédition de Dhât ar-Riqâʿ** (`dhat_riqa`) — Sahih Muslim 1816 · Livre du jihâd et des expéditions.
- **Le serment de Ridwan** (`ridwan`) — Sahih al-Bukhari 4169 · Livre des expéditions, chapitre d’al-Hudaybiyya.
- **Le traité de Hudaybiyyah** (`hudaybiyyah`) — Sahih al-Bukhari 2731–2732 · Livre des conditions, chapitre des accords de paix.
- **Les lettres aux souverains** (`letters_rulers`) — Sahih al-Bukhari 7 · Livre du commencement de la révélation, lettre à Héraclius.
- **L'expédition de Khaybar** (`khaybar`) — Sahih al-Bukhari 4210 · Livre des expéditions, chapitre de Khaybar.
- **L’expédition de Wâdî al-Qurâ** (`wadi_al_qura`) — .
- **La bataille de Mu'tah** (`mutah`) — Sahih al-Bukhari 4261 · Livre des expéditions, chapitre de l’expédition de Muʾta.
- **La conquête de Makkah** (`fath_makkah`) — Sahih al-Bukhari 4287 · Livre des expéditions, chapitre de la conquête de Makkah.
- **La bataille de Hunayn** (`hunayn`) — Sahih Muslim 1775a · Livre du jihad et des expéditions, chapitre de Hunayn.
- **Le siège de Tâ’if** (`siege_taif`) — Sahih al-Bukhari 4324 · Expéditions militaires, siège de Tâ’if.
- **L'expédition de Tabuk** (`tabuk`) — Sahih al-Bukhari 4418 · Livre des expéditions, récit de Kaʿb ibn Mâlik.
- **La prière funéraire pour le Négus** (`najashi_funeral`) — Sahih al-Bukhari 1245 · Livre des funérailles, prière sur le Négus.
- **L'année des délégations** (`delegations`) — .
- **La délégation de Thaqîf** (`delegation_thaqif`) — .
- **Le pèlerinage d'adieu** (`farewell_hajj`) — Sahih Muslim 1218a–b · Livre du pèlerinage, chapitre du pèlerinage du Prophète ﷺ.
- **Décès du Prophète ﷺ** (`death_prophet`) — Sahih al-Bukhari 5217 · Livre du mariage, 67, hadith 150 ; Sahih al-Bukhari 4452–4454 · Livre des expéditions, chapitre de la maladie et du décès du Prophète ﷺ.

## Les 31 dossiers à collationner

Pour ces dossiers, l’application ne possède pas encore d’extrait de source primaire précisément attaché à l’événement. La présence de « Ibn Hishâm, al-Sîra » dans la bibliographie constitue une piste de travail, pas une preuve suffisante. Il faut retrouver le chapitre et la page dans une édition identifiée, relever les variantes de transmission, puis comparer la chronologie séparément.

## Vérification des 68 biographies

- Toutes les fiches ont une entrée FR / EN / AR et conservent trois sections communes.
- Les liens de parenté sont maintenant calculés à partir des parents, enfants, conjoints, frères et sœurs, grands-parents, oncles/tantes et cousins connus.
- Les liens sociaux ou nourriciers (Zayd et Halîma) sont explicitement séparés de la filiation biologique.
- Les personnages pour lesquels aucune parenté directe n’est documentée affichent une note de prudence au lieu de rester silencieusement isolés.
- **Trois fiches de parenté ajoutées : Zaynab bint Khuzayma, Umayma bint ʿAbd al-Muttalib et Abû Sufyân ibn Harb**. L’inventaire initial omettait cette épouse parmi les onze épouses généralement listées dans les sources sunnites. Son lien maternel avec Maymûna est indiqué comme une parenté rapportée, et non comme une filiation paternelle.

### Liens corrigés ou ajoutés

- **Muhammad ﷺ ↔ ʿAlî ibn Abî Tâlib** : cousins paternels, par Abû Tâlib, frère de ʿAbd Allâh.
- **Muhammad ﷺ ↔ Jaʿfar ibn Abî Tâlib** : cousins paternels, même branche d’Abû Tâlib.
- **Muhammad ﷺ ↔ Zaynab bint Jahsh** : le lien de cousinage est déduit à partir de sa mère Umayma bint ʿAbd al-Muttalib, dont la fiche et la branche sont présentes.
- **Muhammad ﷺ ↔ ses oncles et sa tante paternels** : Abû Tâlib, Hamza, al-ʿAbbâs, Abû Lahab, al-Hârith et Safiyya bint ʿAbd al-Muttalib.
- **Khadîja ↔ Waraqa ibn Nawfal** : cousins selon le récit de la première révélation.
- **Muhammad ﷺ ↔ Halîma** : lien de nourrice / mère de lait, non biologique.
- **Muhammad ﷺ ↔ Zayd** : ancien lien d’adoption et de protection, distinct de la filiation biologique. **Muhammad ﷺ ↔ Mariya al-Qibtiyya** : co-parentalité autour d’Ibrâhîm, sans présenter Mariya comme épouse.
- **ʿÂʾisha ↔ Abû Bakr** et **Hafsa ↔ ʿUmar** : liens père-fille ajoutés au graphe. **Umm Habîba ↔ Abû Sufyân** : lien père-fille ; la parenté par alliance avec Muhammad ﷺ est également affichée.
- **Zaynab bint Khuzayma ↔ Maymûna** : lien de sœur par la mère rapporté dans une notice biographique.

## Images originales intégrées

- Six illustrations originales générées pour le projet sont désormais embarquées localement : Makkah/Kaʿba, paysage de Hira, relief de Thawr, oasis du Hijaz, plaine désertique du Hijaz et habitat fortifié de Khaybar.
- Elles sont signalées dans l’application comme **illustrations générées par IA, pédagogiques et non documentaires**. Elles ne sont pas présentées comme des photographies ni comme des reconstitutions archéologiques.
- Les photographies Wikimedia déjà référencées restent disponibles en ligne pour les autres lieux ; elles nécessitent toujours une connexion tant qu’elles ne sont pas téléchargées et embarquées.

## Limites qui restent ouvertes avant la 1.0

1. Collationner les 31 dossiers restants dans les éditions primaires retenues ; les références génériques ne suffisent pas.
2. Vérifier chaque variante chronologique et chaque détail secondaire, notamment les récits de Sîra sans hadith ciblé.
3. Relire humainement les traductions EN / AR et les notices enrichies ; la présence des trois langues ne garantit pas une qualité littéraire équivalente.
4. Poursuivre la collation des notices généalogiques et vérifier les variantes sur les liens maternels et les mariages.
5. Exécuter `flutter pub get`, `dart format`, `flutter analyze` et `flutter test` sur une machine disposant de Flutter/Dart. Ces commandes ne sont pas disponibles dans l’environnement de préparation.

## Sources de méthode et de parenté consultées

- Moojan Momen / Oxford Bibliographies, « ʿAlī Ibn Abī Ṭālib » : https://academic.oup.com/reference/62361/reference-article-abstract/554579518 — confirme explicitement le cousinage avec le Prophète ﷺ et le mariage avec Fâtima.
- Islam Museum, « Ali ibn Abi Talib » : https://www.islam.museum/en/person/ali-ibn-abi-talib/ — notice et connexions familiales.
- Islam Museum, « Zaynab bint Jahsh » : https://www.islam.museum/en/person/zaynab-bint-jahsh/ — mère Umayma, tante du Prophète, et parenté avec Muhammad.
- Islam Museum, « Waraqa ibn Nawfal » : https://www.islam.museum/en/person/waraqa-ibn-nawfal/ — lien de cousinage avec Khadija ; à recouper avec Sahih al-Bukhari 3.
- Islam Museum, « Umayma bint Abd al-Muttalib » : https://www.islam.museum/en/person/umayma-bint-abd-al-muttalib/ — notice sur sa filiation, sa fille Zaynab bint Jahsh et le caractère discuté de son islam.
- Islam Museum, « Abu Sufyan ibn Harb » : https://www.islam.museum/en/person/abu-sufyan-ibn-harb/ — notice sur son rôle dans les campagnes et sa fille Umm Habiba.
- Islam Museum, « Umm Habiba » : https://www.islam.museum/en/person/umm-habiba-bint-abi-sufyan/ — confirme la filiation avec Abu Sufyan.
- Islam Museum, « Zaynab bint Khuzayma » : https://www.islam.museum/en/person/zaynab-bint-khuzayma/ — surnom Umm al-Masâkîn, lien maternel avec Maymûna, variantes sur la durée du mariage.
- *Encyclopaedia of Islam*, notice « Zaynab bt. Khuzayma » (C. E. Bosworth) : https://isamveri.org/pdfdkm/23/DKM230233.pdf — références classiques citées, dont Ibn Saʿd, al-Balâdhurî et al-Tabarî.
- « A Critical and Historical Overview of the Sīrah Genre from the Classical to the Modern Period », *Religions* (2022) : https://www.mdpi.com/2077-1444/13/3/196 — rappelle les débats sur la transmission et la critique des récits de Sîra.
- Islam Museum, « The Sira of Ibn Ishaq in Ibn Hisham’s recension » : https://www.islam.museum/en/work/sira-ibn-ishaq-ibn-hisham/ — précise la transmission et la recension du texte.

**Conclusion éditoriale :** l’audit de couverture des 79 événements et des 68 biographies est réalisé ; la vérification historique complète des 79 récits n’est pas encore terminée. Le statut `needs_corroboration` est conservé pour rester transparent.
