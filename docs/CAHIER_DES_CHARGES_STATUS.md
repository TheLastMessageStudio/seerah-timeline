# État du cahier des charges — Seerah Timeline

État de référence : version 0.9.4+15. Ce tableau sépare les fonctionnalités présentes, celles qui restent partielles et les conditions de publication.

| Exigence du cahier des charges | État | Constat |
|---|---|---|
| Application Android en Flutter | Partiel | Le code Flutter est présent. L'archive source contrôlée ne contient pas de dossier `android/` ; la génération et la configuration Android doivent être vérifiées dans le projet local avant publication. |
| Parcours chronologique de la naissance au décès | Présent | 12 périodes et 79 événements affichés dans l'ordre. |
| Accueil, cartes de périodes et progression | Présent | Accueil remanié, progression globale, progression par période, dernières fiches enrichies et accès menu principal. |
| Chronologie, filtres, recherche | Présent | Recherche locale et navigation chronologique. |
| Fiches avec résumé et détails | Partiel | Les deux niveaux existent. Deux lots de 5 fiches sont approfondis en 0.9.0 ; les autres restent à reprendre par lots. |
| Dates exactes, approximatives et discutées | Présent techniquement | Les trois niveaux sont pris en charge. La justesse de chaque date doit encore être vérifiée événement par événement. |
| Références consultables et distinction des récits | Partiel | Références et notes sont conservées ; 51 extraits de preuve ciblée (42 hadiths, 9 références coraniques) sont attachés à 47 événements. 79/79 fiches portent encore `needs_corroboration`. |
| Personnages et biographies liées aux événements | Présent, à enrichir | 68 personnages, profils et liens vers les événements ; plusieurs liens généalogiques ne correspondent pas nécessairement à des événements de la chronologie. |
| Carte historique avec lieux interactifs | Présent | Carte schématique locale et fiches de lieux ; 24 lieux. 13 lieux disposent d’un visuel : 6 illustrations originales locales hors ligne et 7 photographies Wikimedia en ligne avec attribution/licence ; 75 événements sur 79 sont associés à un lieu illustré. |
| Favoris, historique et progression | Présent | Stockage local via SharedPreferences. |
| Fonctionnement hors ligne | Présent pour les données embarquées | Les contenus JSON sont locaux. Les imports Hadith/Coran doivent être présents dans les assets de l'installation concernée. |
| Français, anglais et arabe | Présent techniquement | Fichiers de traduction disponibles ; relecture linguistique humaine encore nécessaire. |
| Achat unique Premium et restauration | Partiel | `in_app_purchase`, achat non consommable et restauration sont codés. Le produit `seerah_timeline_premium` doit être configuré et testé dans Google Play Console ; aucun contrôle serveur de reçu n'est implémenté. |
| Design sobre, sans portraits historiques | Présent dans les écrans inspectés | Thème Material 3, palette vert/parchemin et absence de portraits de personnages dans les écrans contrôlés. |
| Tests avant publication | Partiel | Validation JSON et audit éditorial Python réussis. Les tests Flutter, tests Android, mode hors ligne réel et achat/restauration sur Play doivent encore être exécutés sur un poste configuré. |
| Arbre généalogique interactif Premium | Ajout hors MVP initial | Vue centrée sur Muhammad ﷺ, zoom/recentrage et noms cliquables ; l'accès est réservé à Premium. La généalogie complète reste une représentation pédagogique limitée par les divergences des sources. |
| Quiz bonus après les fiches | Ajout hors MVP initial | Deux questions de mémorisation par fiche, générées à partir de la période et de la précision de date ; ce n'est pas encore un quiz historique approfondi propre à chaque événement. |
| Calendrier éditorial et sorties hebdomadaires | Présent en prévisionnel | Calendrier/tableau intégré avec 15 semaines préremplies et 74 fiches non encore publiées ; dernier lot de 4 fiches. Dates planifiées, non publication automatique garantie. |
| Livres de Sîra | Partiel | Sept ouvrages ont des dossiers de lecture synthétiques en FR/EN/AR. Quatre éditions disposent d’un PDF lisible dans le lecteur intégré (Ibn Hishâm vol. 1, Ibn Saʿd vol. 1, al-Tabarî vol. 1–2, al-Balâdhurî vol. 1). Les autres notices ouvrent des sources externes ; le scan ancien d’al-Waqidi n’est pas l’unique option de lecture. Les transcriptions complètes restent à collationner et à vérifier côté droits. |

## Bilan chiffré

- 79 événements ; 12 périodes ; 68 personnages ; 24 lieux ; 25 entrées de bibliothèque.
- 10 fiches approfondies dans les lots éditoriaux 01 et 02 ; 69 fiches restent à reprendre en profondeur. Le calendrier programme les 74 fiches non encore publiées sur 15 semaines : le lot 02 est prêt pour le 16 novembre 2026, puis cinq fiches par semaine (quatre dans le dernier lot).
- 0 fiche sur 79 n'a encore le statut interne `reviewed` ; toutes restent `needs_corroboration`.
- 51 extraits de preuve sont intégrés dans `event_evidence.json` (42 hadiths et 9 passages coraniques), couvrant 48 événements.

## Priorités pour atteindre une version 1.0 publiable

1. Rechercher, réécrire et corroborer les 69 fiches restantes par lots, sans convertir artificiellement les statuts de vérification.
2. Collationner les références primaires et leurs éditions/pages, notamment Ibn Hisham.
3. Compléter les textes de livres uniquement à partir de transcriptions dont la licence est claire, ou proposer des fac-similés consultables sans redistribuer le texte protégé.
4. Configurer le projet Android et Google Play Billing, puis tester achat, restauration et erreurs sur les canaux internes de Play.
5. Exécuter `flutter analyze`, `flutter test`, tests sur appareils Android modestes, RTL arabe et mode hors ligne.
6. Finaliser la fiche Play Store, captures, politique de confidentialité et contrôle final des contenus.

## Hors périmètre du MVP initial

Comptes utilisateurs, synchronisation cloud, commentaires, IA, audio, multijoueur et encyclopédie exhaustive des Compagnons restent exclus conformément au cahier des charges. Les quiz ajoutés ici sont volontairement légers et ne changent pas ce périmètre.



## Mise à jour v0.9.1
- Lecteur PDF intégré `pdfrx` avec chargement à la demande pour trois scans documentés d’Arabic Collections Online (Ibn Hishâm vol. 1, al-Tabarî vol. 1–2, al-Balâdhurî vol. 1).
- Verrouillage des 74 fiches non encore publiées selon un calendrier complet de 15 semaines ; mode administrateur de test disponible uniquement en build debug. Les cinq fiches du lot 02 restent verrouillées jusqu’au 16 novembre 2026.
- Carte : marqueurs de lieux secondaires après sélection d’une ville, photo contemporaine dans le panneau de ville et fiches de lieux cliquables. 13 lieux sur 24 disposent d’un visuel (6 illustrations locales et 7 photos en ligne) ; 75 événements sur 79 sont associés à un lieu illustré.
- Calendrier : tableau à hauteur variable (correctif de l’overflow) et mois générés jusqu’à la dernière sortie planifiée. Écran de compte à rebours par lot et verrouillage des événements, personnes et lieux liés aux sorties futures.
- Quatre PDF distants s’ouvrent dans le lecteur intégré : Ibn Hishâm vol. 1, Ibn Saʿd vol. 1, al-Tabarî vol. 1–2 et al-Balâdhurî vol. 1. Les autres ouvrages disposent de liens externes vérifiés lorsqu’une version lisible a été trouvée ; les éditions modernes sans autorisation claire ne sont pas embarquées.
- Les images et PDF sont chargés en ligne ; le cache hors ligne des médias reste à faire.
- SDK Dart minimal fixé à 3.7 pour la dépendance `pdfrx 1.3.2`.
