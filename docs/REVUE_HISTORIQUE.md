# Revue historique et suivi des vérifications — V0.8.0

Ce document distingue le statut de publication dans l’application et le statut de vérification historique. Les événements sont publiés dans l’interface afin de ne plus afficher un badge de brouillon, mais cela ne signifie pas que chaque détail est validé.

## Inventaire

- Événements : **79** (71 fiches initiales conservées + 8 dossiers ajoutés en V0.8.0).
- Statut de publication : **79 publiés**.
- Statut de vérification : **0 relu**, **79 à corroborer** au moment de la préparation de cette version.
- Précision chronologique : **60 approximatives**, **12 discutées**, **7 indiquées exactes**.
- Références ou repères de sources dans les données : présents sur les 79 fiches, mais la présence d’un repère ne vaut pas vérification du passage.

## Références ciblées déjà ajoutées

| Événement | Référence | Portée exacte |
|---|---|---|
| `birth_prophet` | Sahih Muslim 1162e | Le lundi est rapporté comme jour de naissance ; ce hadith ne fixe ni le mois ni le quantième. |
| `shepherd` | Sahih al-Bukhari 2262 | Le Prophète ﷺ a gardé les moutons des habitants de Makkah ; le hadith ne date pas précisément cette période. |
| `first_revelation` | Sahih al-Bukhari 3 ; Coran 96:1–5 | Récit du début de la révélation à Hira et premiers versets associés. |
| `death_prophet` | Sahih al-Bukhari 5217 | Le décès dans la demeure de ʿAisha ; le hadith ne tranche pas le jour exact du mois. |

Les références soutiennent uniquement les éléments qu’elles rapportent explicitement. Les récits de Sîra transmis par Ibn Hishâm à partir d’Ibn Ishâq doivent être distingués des recueils de hadiths et des synthèses postérieures.

## Dossiers ajoutés en V0.8.0

- `banu_qaynuqa`
- `banu_nadir`
- `banu_mustaliq`
- `banu_qurayza`
- `dhat_riqa`
- `wadi_al_qura`
- `siege_taif`
- `delegation_thaqif`

Ces fiches exposent les divergences de datation et signalent les limites des récits. Elles restent `needs_corroboration` jusqu’à une comparaison avec les éditions et études retenues.

## Règles de validation

1. Identifier l’édition, le volume et le système de pagination avant de citer une page.
2. Distinguer le texte de l’auteur, les transmissions, les notes de l’éditeur et les commentaires modernes.
3. Distinguer la fiabilité d’un récit de la certitude de sa datation.
4. Ne pas transformer une date discutée en date certaine.
5. Une référence bibliographique générale ne remplace pas la vérification du passage exact.
6. Ne passer `verificationStatus` à `reviewed` qu’après contrôle documenté ; le statut de publication reste indépendant.

Le script `tools/apply_review.py` met à jour `verificationStatus` depuis la colonne « Editorial review » du fichier `docs/fiches_verification.csv`. Il ne retire pas les événements de la navigation et ne les transforme pas en brouillons.


## Repères géographiques ajoutés en V0.9.2

- **Al-Abwâʾ** : localité située sur la route historique entre Makkah et Madinah ; association au décès d'Âmina rapportée par des sources biographiques. Notice de synthèse : Islam Museum, « al-Abwa » (bibliographie comprenant Ibn Hisham 1/168 et l'Encyclopaedia of Islam) ; notice géographique et coordonnées modernes : Wikidata / OpenStreetMap. Le point reste indicatif.
- **Al-Qiblatayn** : mosquée actuelle de Madinah traditionnellement associée au récit du changement de qibla. Coordonnées de la notice patrimoniale IRCICA : 24°29′02.78″ N, 39°34′44″ E. L'entrée précise que le bâtiment visible aujourd'hui n'est pas présenté comme le bâtiment originel.
- **Arafat** : repère placé dans la plaine, non au sommet du Jabal al-Rahmah. Saudipedia rappelle que le wuqûf concerne la zone d'Arafat et non exclusivement la montagne.

Sources web de travail :
- https://www.islam.museum/en/place/al-abwa/
- https://www.wikidata.org/wiki/Q1051781
- https://www.islamicarchitecturalheritage.com/listings/masjid-al-qiblatayn
- https://saudipedia.com/en/jabal-al-rahmah

## Repères géographiques supplémentaires — préparation 1.0

- **Dâr al-Arqam** : emplacement traditionnel associé aux réunions des premiers musulmans ; le point cartographique est indicatif et ne prétend pas identifier des vestiges archéologiques certains.
- **Al-Safâ et al-Marwa** : zone rituelle actuelle dans l'enceinte de la Mosquée sacrée ; le repère désigne la zone moderne, non une reconstitution du site au VIIe siècle.
- **Mosquée du Prophète** : point placé sur l'emplacement actuel à Madinah ; le bâtiment visible a connu de nombreux agrandissements et n'est pas une représentation de la première mosquée.
- **Zone du Fossé** : secteur traditionnellement associé au fossé défensif au nord de Madinah ; le tracé historique exact n'est pas restitué.
- **Tabuk** : ville actuelle utilisée comme repère régional de l'expédition ; le point ne localise pas un campement précis.
- **Muzdalifah** : zone rituelle actuelle entre ʿArafât et Minâ ; le point ne prétend pas identifier un emplacement de campement du VIIe siècle.

Ces points sont ajoutés pour la lisibilité pédagogique. Les descriptions distinguent explicitement un lieu actuel, une région historique et une localisation traditionnelle approximative.

## Audit complet de couverture — V0.9.4+15

Voir `AUDIT_COMPLET_79_ET_68.md`, `AUDIT_79_EVENEMENTS.csv` et `AUDIT_68_BIOGRAPHIES_ET_LIENS.csv`. La couverture a été passée sur les 79 événements et les 68 biographies. 48 événements ont une preuve ciblée enregistrée ; 31 restent à collationner dans une édition identifiée. Aucun événement n’a été promu artificiellement à `reviewed`.
