"""Ajoute le deep link Patreon (seerahtimeline://patreon/callback) au projet Android.

À lancer depuis la racine du projet, après `flutter create . --platforms=android` :
    python tools/add_patreon_deep_link.py

Le script est idempotent : il ne modifie rien si le filtre est déjà présent.
"""
from pathlib import Path
import sys

MANIFEST = Path("android/app/src/main/AndroidManifest.xml")
FILTER = """
            <!-- Retour de Patreon vers l'application -->
            <intent-filter android:autoVerify="false">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="seerahtimeline" android:host="patreon" />
            </intent-filter>
"""
QUERIES = """
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
    </queries>
"""


def main() -> int:
    if not MANIFEST.exists():
        print(f"Introuvable : {MANIFEST}. Lance d'abord : flutter create . --platforms=android")
        return 1
    text = MANIFEST.read_text(encoding="utf-8")
    changed = False

    if 'android:scheme="seerahtimeline"' not in text:
        start = text.find('android:name=".MainActivity"')
        end = text.find("</activity>", start)
        if start == -1 or end == -1:
            print("Activité MainActivity introuvable dans le manifeste.")
            return 1
        text = text[:end] + FILTER.lstrip("\n") + "        " + text[end:]
        changed = True
        print("✓ Deep link seerahtimeline://patreon ajouté.")
    else:
        print("• Deep link déjà présent.")

    # Android 11+ : url_launcher doit pouvoir « voir » le navigateur pour ouvrir Patreon.
    if 'android:scheme="https"' not in text:
        text = text.replace("</manifest>", QUERIES.lstrip("\n") + "</manifest>")
        changed = True
        print("✓ Déclaration <queries> https ajoutée (url_launcher, Android 11+).")

    # Le deep link doit être lu par app_links uniquement, pas par le routeur Flutter
    # (sinon : « GoException: no routes for location: seerahtimeline://patreon/callback »).
    if "flutter_deeplinking_enabled" not in text:
        start = text.find('android:name=".MainActivity"')
        end = text.find("</activity>", start)
        meta = '<meta-data android:name="flutter_deeplinking_enabled" android:value="false" />\n'
        text = text[:end] + "    " + meta + "        " + text[end:]
        changed = True
        print("✓ Routage Flutter des deep links désactivé (app_links s'en charge).")

    if changed:
        MANIFEST.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
