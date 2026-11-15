# Refonte éditoriale et visuelle — V0.9.2

## Direction éditoriale

L'application doit raconter la Sîrah de façon vivante, claire et instructive, sans transformer les traditions rapportées en certitudes historiques. Chaque fiche doit progressivement comporter :
1. un résumé de lecture de 45 à 70 mots ;
2. un récit développé avec contexte social, géographique et politique ;
3. les conséquences de l'événement et ses liens avec la suite de la Sîrah ;
4. les récits secondaires clairement attribués ;
5. les textes primaires et références localisées ;
6. un panneau séparé pour les dates et les divergences chronologiques.

## Règles de vérification

- Distinguer Coran, hadith, Sîra ancienne, chronique historique et synthèse moderne.
- Indiquer l'édition, le volume et la page seulement après collation.
- Ne pas utiliser une synthèse moderne comme preuve primaire.
- Ne pas confondre fiabilité d'une narration et précision de sa date.
- Ne pas inventer d'isnad, de citation, de numéro de page ou de localisation.
- Les détails secondaires doivent être explicitement attribués à leur source.

## Travail déjà effectué en V0.9.2

- Résumés FR/EN/AR enrichis à partir du contenu déjà présent dans les fiches.
- Sections de datation regroupées dans un panneau repliable.
- Références bibliographiques visibles dans un panneau séparé.
- Galerie multi-lieux pour les événements liés à plusieurs lieux.
- Page d'accueil plus aérée.
- Trois lieux supplémentaires reliés aux événements pertinents.
- Architecture de chargement des images locales préparée, avec script de téléchargement et manifeste de licence.
- Suppression des boutons qui ouvraient les pages de lecture des livres à l'extérieur de l'application.

## Lots éditoriaux suivants

### Lot A — premières années
Naissance, décès de ʿAbd Allâh, allaitement, purification du cœur, décès d'Âmina, tutelle, berger, voyage au Shâm, Hilf al-Fudûl, mariage avec Khadîja.

### Lot B — début de la révélation et appel mecquois
Retraites à Hira, première révélation, Waraqa, premiers croyants, prière, pause de la révélation, appel discret, Dâr al-Arqam, avertissement des proches, appel public, persécutions et migrations.

### Lot C — Hégire et construction de la communauté
Aqabah, départ vers Yathrib, Thawr, Qubâʾ, arrivée à Madinah, mosquée, fraternisation, pacte, adhân, changement de qibla et Ramadan.

### Lot D — période médinoise
Badr, Uhud, Banû Qaynuqâ, Banû Nadîr, Khandaq, Banû Qurayza, Hudaybiyyah, Khaybar, lettres, Muʾtah, conquête, Hunayn, Tâʾif, Tabûk, délégations et pèlerinage d'adieu.

Chaque lot doit être documenté dans `docs/LOT_EDITORIAL_*.md` et laisser le statut `needs_corroboration` tant que la vérification historique n'est pas terminée.
