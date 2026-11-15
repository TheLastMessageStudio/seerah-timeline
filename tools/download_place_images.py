#!/usr/bin/env python3
"""Télécharge les photos de lieux sous licence ouverte et prépare leur intégration offline.

À lancer depuis la racine du projet :
    python tools/download_place_images.py

Le script ne télécharge que les URL Wikimedia déjà référencées dans places.json.
Il conserve les crédits, licences et URL sources dans media_manifest.json.
"""
from __future__ import annotations

import json
import mimetypes
import sys
import time
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "assets" / "data" / "places.json"
IMAGE_DIR = ROOT / "assets" / "images"
MANIFEST = IMAGE_DIR / "media_manifest.json"
ALLOWED_HOSTS = {"upload.wikimedia.org", "thumb.wikimedia.org"}
MAX_BYTES = 12 * 1024 * 1024


def main() -> int:
    places = json.loads(DATA.read_text(encoding="utf-8"))
    IMAGE_DIR.mkdir(parents=True, exist_ok=True)
    manifest = []
    downloaded = 0
    failures = []

    for place in places:
        url = place.get("imageUrl")
        if not url:
            continue
        parsed = urlparse(url)
        if parsed.scheme != "https" or parsed.hostname not in ALLOWED_HOSTS:
            failures.append((place["id"], "URL non autorisée"))
            continue

        ext = Path(parsed.path).suffix.lower()
        if ext not in {".jpg", ".jpeg", ".png", ".webp"}:
            ext = ".jpg"
        destination = IMAGE_DIR / f"{place['id']}{ext}"
        try:
            if not destination.exists():
                request = Request(url, headers={"User-Agent": "SeerahTimeline/0.9.3 (offline media pack)"})
                with urlopen(request, timeout=25) as response:
                    content_type = response.headers.get_content_type()
                    payload = response.read(MAX_BYTES + 1)
                if not content_type.startswith("image/") or len(payload) > MAX_BYTES:
                    raise ValueError(f"contenu refusé ({content_type}, {len(payload)} octets)")
                destination.write_bytes(payload)
            place["imageAsset"] = f"assets/images/{destination.name}"
            manifest.append({
                "placeId": place["id"],
                "asset": place["imageAsset"],
                "source": url,
                "author": place.get("imageCredit"),
                "license": place.get("imageLicense"),
                "licenseUrl": place.get("imageLicenseUrl"),
                "sourcePage": place.get("imageSourceUrl"),
                "captionFr": place.get("imageCaptionFr"),
            })
            downloaded += 1
            print(f"OK  {place['id']} -> {destination.name}")
        except Exception as exc:  # keep processing other assets
            failures.append((place["id"], str(exc)))
            print(f"ERR {place['id']}: {exc}", file=sys.stderr)
        time.sleep(0.15)

    DATA.write_text(json.dumps(places, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"\nPhotos intégrées : {downloaded}")
    print(f"Échecs : {len(failures)}")
    if failures:
        for place_id, reason in failures:
            print(f"- {place_id}: {reason}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
