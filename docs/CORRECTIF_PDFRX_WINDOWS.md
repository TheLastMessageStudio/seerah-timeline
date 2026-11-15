# Correctif pdfrx 1.3.2 sous Windows

Le correctif précédent pouvait laisser une parenthèse fermante manquante si la ligne était modifiée manuellement. Cette version remplace les deux lignes complètes dans le cache Pub, en conservant la syntaxe Dart.

À la racine du projet, dans le terminal PowerShell déjà ouvert :

```powershell
flutter pub get
.\tools\patch_pdfrx.ps1
flutter run
```

Si l'exécution des scripts est bloquée dans cette session, utiliser :

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\tools\patch_pdfrx.ps1
flutter run
```

La ligne Dart corrigée doit être exactement :

```dart
final readEnd = min(p + size, (blockId + 1) * cache!.blockSize);
```

Et l'autre accès :

```dart
await cache!.read(buffer, bufferPosition, p, sizeToRead);
```

Ce correctif ne modifie ni la version Flutter/Dart ni `pubspec.yaml`. Il modifie le fichier de cache local de `pdfrx 1.3.2`. Si le cache est recréé par Pub, relancer le script.
