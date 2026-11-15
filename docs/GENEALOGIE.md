# Arbre familial — méthode et limites

L’arbre de l’application présente la lignée paternelle du Prophète ﷺ jusqu’à Adnân, puis la branche familiale des Banû Hâshim et les principaux liens immédiats : parents, oncles et tante paternels, épouses, enfants et petits-enfants.

## Limite généalogique

La chaîne affichée est : Muhammad ibn ʿAbd Allâh ibn ʿAbd al-Muttalib ibn Hâshim ibn ʿAbd Manâf ibn Qusayy ibn Kilâb ibn Murra ibn Kaʿb ibn Luʾayy ibn Ghâlib ibn Fihr ibn Mâlik ibn an-Nadr ibn Kinâna ibn Khuzayma ibn Mudrika ibn Ilyâs ibn Mudar ibn Nizâr ibn Maʿadd ibn ʿAdnân.

Les généalogistes distinguent généralement cette partie, retenue jusqu’à Adnân, des chaînes proposées au-delà d’Adnân vers Ismâʿîl et Ibrâhîm, qui comportent des divergences. L’application s’arrête donc à Adnân et ne présente pas de chaîne jusqu’à Adam comme certaine.

## Sources de travail

- Ibn Hishâm, *al-Sîra al-Nabawiyya*, ouverture de l’ouvrage et généalogie du Prophète ﷺ.
- Ibn Saʿd, *al-Tabaqât al-Kubrâ*, notices de la famille du Prophète ﷺ.
- Ibn Hazm, *Jamharat Ansâb al-ʿArab*, pour les chaînes généalogiques de Quraysh.
- Pour la distinction entre la chaîne jusqu’à Adnân et les chaînes antérieures : synthèses classiques de Sîra et de généalogie ; les variantes doivent être conservées plutôt que fusionnées artificiellement.

## Limites de cette version

- L’arbre est une vue familiale pédagogique, pas une base exhaustive de tous les clans, cousins et descendants.
- Les liens de mariage, de maternité et de filiation sont séparés autant que possible dans les données d’affichage.
- Certains liens de parenté et détails biographiques demandent encore une vérification systématique dans les éditions de référence.
- Les noms sont cliquables et ouvrent les fiches de personnages ; les restrictions Premium existantes continuent de s’appliquer.


## Parentés collatérales et liens non biologiques — V0.9.4

Le calcul des liens de biographies ne se limite plus à la seule relation parent-enfant. Il déduit aussi les frères et sœurs, grands-parents, petits-enfants, oncles/tantes, cousins et neveux/nièces à partir du graphe enregistré. Les liens absents de la branche verticale sont ajoutés explicitement avec leur qualification :

- ʿAlî et Jaʿfar ibn Abî Tâlib sont affichés comme cousins paternels de Muhammad ﷺ par Abû Tâlib.
- Zaynab bint Jahsh est affichée comme cousine de Muhammad ﷺ par Umayma bint ʿAbd al-Muttalib, désormais présente comme fiche et comme branche dans l’arbre.
- Les oncles paternels (Abû Tâlib, Hamza, al-ʿAbbâs, Abû Lahab, al-Hârith) et la tante Safiyya bint ʿAbd al-Muttalib sont calculés depuis les enfants de ʿAbd al-Muttalib.
- Waraqa ibn Nawfal est relié à Khadija comme cousin dans le récit de la première révélation.
- Halîma est reliée comme nourrice / mère de lait ; ce lien n’est pas une filiation biologique.
- Zayd est relié comme ancien fils adoptif / protégé, avec une étiquette qui le distingue de la filiation biologique.
- Abû Bakr–ʿÂʾisha et ʿUmar–Hafsa sont ajoutés comme liens père-fille.
- Zaynab bint Khuzayma est ajoutée à la liste des épouses ; une notice rapporte qu’elle était sœur de Maymûna par leur mère.

La liste des relations et leurs réserves figure dans `AUDIT_68_BIOGRAPHIES_ET_LIENS.csv`. Lorsqu’aucune parenté directe n’est documentée dans le corpus de l’application, la biographie affiche une note de prudence au lieu d’inventer un lien.


## Branches complétées — V0.9.4+15

- **Umayma bint ʿAbd al-Muttalib** est ajoutée comme fille d'ʿAbd al-Muttalib et mère de Zaynab bint Jahsh. Le graphe déduit ainsi le cousinage de Zaynab avec Muhammad ﷺ au lieu de s'appuyer uniquement sur un lien manuel. Son statut religieux reste signalé comme discuté.
- **Abû Sufyân ibn Harb** est ajouté comme père d'Umm Habîba ; le graphe affiche aussi le lien par alliance avec Muhammad ﷺ. Sa biographie est reliée aux événements de Badr, Uhud, al-Khandaq, la correspondance avec Héraclius, la conquête de Makkah, Hunayn et le siège de Tâʾif.
