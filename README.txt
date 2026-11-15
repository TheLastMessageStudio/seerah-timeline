THE LAST MESSAGE — VERSION 6 DEVELOPMENT BUILD
===============================================

TARGETS
- Windows desktop
- Android

WHAT'S NEW IN V5
----------------
1. The original Badr scenario (id: badr) remains separately playable with its original map, deck and story script. It uses the shared V5 engine and hero-passive improvements.
2. A separate expanded Badr Version II (id: badr_v2) has been added:
   - longer 35-round scenario with a pre-battle phase: enemy forces reposition but do not attack until the main clash;
   - caravan and march context, consultation, well strategy, rain, dawn,
     champions, reserve waves representing the army already present, battle and aftermath;
   - additional objectives and story events; reserve waves are a gameplay abstraction, not a claim of historical arrivals;
   - dialogue distinguishes transmitted accounts from narrative reconstruction.
3. Future campaigns are visible but locked: Uhud, the Battle of the Trench,
   Khaybar, the Conquest of Mecca and Yarmouk.
4. Rare, epic and legendary heroes now have signature passive abilities.
   These are gameplay abstractions and are not claims about historical powers:
   - melee specialists gain extra adjacent damage;
   - commanders can protect adjacent allies;
   - marksmen gain extra range;
   - cavalry specialists gain extra flank damage.
5. AI target selection and positioning have been improved:
   - prioritizes vulnerable support and ranged units;
   - values named heroes and high-impact units;
   - moves toward strategic objectives;
   - protects fragile ranged units and wounded troops;
   - makes better use of terrain and nearby allies.
6. Refined visual theme and hero detail cards.
7. Android save files now use the application support directory via path_provider.
   Windows keeps the existing %APPDATA%\TheLastMessage\save.json location.
8. Tests added for hero passives and the independent Badr V2 scenario.

INSTALL / UPDATE
----------------
1. Make a backup copy of your current project folder.
2. Extract this archive. For an EXISTING project, copy/merge the lib/, test/ and
   assets/ folders into your project root. Do NOT overwrite your existing
   pubspec.yaml: merge the dependency below into its dependencies section.
   The included pubspec.yaml is a minimal fallback for a new/empty Flutter
   project. Its root folder must be the folder where you run Flutter commands.
3. Ensure this dependency is present under dependencies:
       path_provider: ^2.1.5
   If your package name differs from flutter_application_1, update the package
   imports at the top of test/game_test.dart to match your pubspec name.
4. Run from the same folder that contains pubspec.yaml:
       flutter pub get
       flutter test
       flutter run -d windows
   For Android, connect a device or start an emulator, then run:
       flutter run

PLATFORM RUNNERS
----------------
This archive contains the Flutter source, tests and assets. It does not replace
native Windows or Android runner folders. If your project does not yet have
those platform folders, run this from the project root:
       flutter create --platforms=windows,android .

IMPORTANT TESTING NOTE
----------------------
The source archive originally supplied did not include the native runner folders
or a pubspec.yaml. A standalone pubspec.yaml is now included, but the build and
runtime still need to be verified on your own Flutter installation and devices.
The 35-round Badr V2 is a playable scenario draft; historical details, pacing,
map layout and balance should be reviewed through actual playtesting before a
release. No historical dialogue should be read as a verbatim transcript. See
HISTORICAL_NOTES.md for the research trail, source links and gameplay abstractions.

SAVE MIGRATION
--------------
- Windows: existing save path is preserved.
- Android: saves are now stored persistently in the app's support directory.
  Existing V4 temporary saves are migrated on first load when the old file is present.


VERSION 6 — TACTICAL REWORK
---------------------------
Badr V2 now requires the player to hold the strategic well for two
uncontested player turns, reach the night phase, defeat all three champions,
clear both reserve waves, and defeat Abu Jahl. Killing Abu Jahl alone is no
longer an instant victory. Badr V1 remains separate and unchanged. The AI has
additional Badr V2 incentives to contest the well and protect its commander.
See CHANGELOG_V6.txt for details and build limitations.


VERSION 7 — MENU & LOCAL RUSH DUEL
---------------------------------
1. Main menu redesigned with a dark tactical look, gold accents, animated
   entrance, responsive menu cards and animated page transitions.
2. New Local 1v1 lobby for two devices on the same Wi-Fi network or mobile
   hotspot. One device hosts the room; the other enters the host IP.
3. The host runs an authoritative TCP room on port 45454. One guest is allowed.
4. New lightweight Rush duel: the existing 19x14 Rush map, four unit roles per
   side, a 60-second deployment phase, 60-second turns, movement, attacks,
   elimination victory, and a central-fort objective (hold it at the end of
   two of your turns).
5. This is LAN-only multiplayer: both devices must be on the same local
   network. It does not use public matchmaking or an internet relay.

LOCAL 1v1 QUICK START
--------------------
1. On device 1, activate a Wi-Fi hotspot or connect both devices to the same
   Wi-Fi network. Open DUEL LOCAL · 1v1 and choose HOST.
2. Give the displayed IP address to device 2. Device 2 chooses JOIN and enters
   the IP only (not the port). The game uses TCP port 45454 automatically.
3. Both players enter the duel. Each has 60 seconds to place Guard, Archer,
   Cavalry and Scout on their side of the Rush map, then press READY.
4. During a turn, select one of your units and tap an empty tile to move, or
   tap an enemy to attack if it is in range. Each unit gets one action per turn.
   End your turn before the 60-second timer expires.
5. Win by eliminating all four enemy units or holding the central fort at the
   end of two of your turns.

NETWORK NOTES
-------------
- The host device must allow incoming local connections on TCP port 45454.
- For Android release builds, ensure android/app/src/main/AndroidManifest.xml has
  <uses-permission android:name="android.permission.INTERNET" /> before the
  <application> element. (Flutter debug builds commonly include this via the
  debug manifest, but release builds should declare it explicitly.)
- Windows may display a Firewall prompt: allow the game on Private networks.
- If connection fails, check that both devices are on the same hotspot/Wi-Fi,
  verify the host IP, and temporarily check firewall rules.
- No router port forwarding is required; do not expose this port to the public
  internet.
- This build has not been compiled or tested on physical devices in the
  current environment. Verify with flutter analyze, flutter test and a real
  two-device connection test before release.
