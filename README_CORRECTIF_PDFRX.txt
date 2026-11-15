CORRECTIF BUILD ANDROID / PDFRX

1. Décompressez ce ZIP dans un nouveau dossier.
2. Copiez vos éventuels fichiers Android locaux si nécessaire (le dossier android/ n'est pas inclus dans cette archive).
3. Ouvrez le dossier du projet dans VS Code.
4. Dans le terminal PowerShell à la racine :
   flutter pub get
   .\tools\patch_pdfrx.ps1
   flutter run

Si PowerShell bloque les scripts :
   Set-ExecutionPolicy -Scope Process Bypass
   .\tools\patch_pdfrx.ps1
   flutter run

Le correctif réécrit les deux lignes pdfrx complètes avec les parenthèses et le point-virgule nécessaires.
