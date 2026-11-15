# Import des corpus arabes hors ligne

Depuis la racine du projet Flutter, avec Python 3 et une connexion Internet :

```powershell
python tools/import_corpora.py
flutter pub get
flutter run
```

Options :

```powershell
python tools/import_corpora.py --hadith-only
python tools/import_corpora.py --quran-only
```

## Hadith

Le script interroge la dernière release de `Jaguar16/open-hadith-data`, télécharge l'archive JSON, puis normalise les textes arabes dans `assets/data/hadith/*.json`. Il n'importe pas les traductions anglaises : le README du dépôt précise qu'elles proviennent de Sunnah.com et relèvent de conditions distinctes. Le dépôt dédie ses données structurées au domaine public CC0 1.0. Le script vérifie la présence de Bukhari et Muslim avant de considérer l’import réussi. Le dépôt signale que les chapitres 8 à 30 de Musnad Ahmad sont absents de la source Sunnah.com : cette collection ne doit donc pas être présentée comme exhaustive.

Collections prévues : Bukhari, Muslim, Abu Dawud, Tirmidhi, Nasa'i, Ibn Majah, Muwatta Malik, Musnad Ahmad, Darimi, Adab al-Mufrad, Riyad as-Salihin, Bulugh al-Maram, Shamail, Mishkat, Nawawi 40, Hadith Qudsi 40 et Shah Waliullah 40. Une collection absente de l'archive n'est pas créée artificiellement.

## Coran

Le script télécharge les 114 fichiers de sourates du profil Uthmani/Hafs depuis `quran-json.risanb.com`, puis construit `assets/data/quran_ar.json`. Le texte arabe est attribué à Tanzil et reproduit verbatim sous CC BY 3.0. Les traductions ne sont pas incluses dans ce corpus, car chaque traduction a ses propres droits.

## Vérification religieuse et éditoriale

Les bases JSON sont des corpus de travail, pas des éditions critiques imprimées. Les numéros, variantes, isnads et classements doivent être comparés à une édition de référence. La présence d'une narration dans une collection ne signifie pas automatiquement que son classement est sahih. Les fiches de la chronologie conservent les références précises et les notes de portée.


## Réimporter dans la version 0.9.1

Depuis la racine du projet sous Windows PowerShell :

```powershell
.\tools\import_corpora.ps1
flutter pub get
flutter run
```

Le script récupère les corpus hadiths depuis `Jaguar16/open-hadith-data` et le texte arabe du Coran depuis le dépôt configuré dans `tools/import_corpora.py`, puis les place dans `assets/data/`. Il faut relancer `flutter pub get` puis reconstruire l'application pour embarquer les nouveaux fichiers. Ce script ne télécharge pas les ouvrages de Sîrah : ceux-ci sont ouverts via le lecteur PDF pour les éditions avec PDF vérifié, ou via leurs pages de lecture externes.
