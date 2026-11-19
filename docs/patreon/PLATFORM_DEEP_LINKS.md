# Deep links Patreon — configuration native

Le callback OAuth revient vers : `seerahtimeline://patreon/callback?code=...`.

L'archive source ne contient pas les dossiers natifs `android/` et `ios/`. Il faut donc ajouter les déclarations ci-dessous aux projets natifs générés par Flutter (sans remplacer les autres déclarations existantes).

## Android — `android/app/src/main/AndroidManifest.xml`

Dans le `<activity android:name=".MainActivity" ...>` ajoutez cet intent-filter, en conservant celui de lancement Flutter :

```xml
<intent-filter android:label="Seerah Timeline Patreon callback">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="seerahtimeline" android:host="patreon" android:path="/callback" />
</intent-filter>
```

## iOS — `ios/Runner/Info.plist`

Dans le dictionnaire principal, ajoutez `CFBundleURLTypes` (fusionnez avec une entrée existante si nécessaire) :

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>seerahtimeline</string></array>
  </dict>
</array>
```

> Raccourci Android : après `flutter create . --platforms=android`, lance `python tools/add_patreon_deep_link.py`.

## Build Flutter

Fournir l'URL publique du backend au build :

```bash
flutter build apk --release --dart-define=PATREON_API_BASE_URL=https://api.example.com
```

Remplacer l'URL par celle du backend déployé. Ne jamais y placer de secret Patreon.
