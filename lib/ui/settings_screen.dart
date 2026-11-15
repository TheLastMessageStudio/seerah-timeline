import 'package:flutter/material.dart';
import '../services/sfx.dart';
import '../strings.dart';
import 'theme.dart';

class SettingsScreen extends StatefulWidget { const SettingsScreen({super.key}); @override State<SettingsScreen> createState() => _SettingsScreenState(); }
class _SettingsScreenState extends State<SettingsScreen> {
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(currentLanguage == 'fr' ? 'Paramètres' : 'Settings')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Card(color: Pal.parchment, child: SwitchListTile(
        value: Sfx.enabled, activeColor: Pal.green,
        title: Text(currentLanguage == 'fr' ? 'Effets sonores' : 'Sound effects', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(currentLanguage == 'fr' ? 'Menus, déplacements, attaques et impacts.' : 'Menus, movement, attacks and impacts.'),
        onChanged: (v) { setState(() => Sfx.enabled = v); if (v) Sfx.tap(); },
      )),
      Card(color: Pal.parchment, child: ListTile(
        leading: const Icon(Icons.music_off, color: Pal.bronze),
        title: Text(currentLanguage == 'fr' ? 'Musique désactivée' : 'Music disabled', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(currentLanguage == 'fr' ? 'Aucune musique de fond n’est utilisée dans le jeu.' : 'No background music is used in the game.'),
      )),
      Card(color: Pal.parchment, child: ListTile(
        leading: const Icon(Icons.language, color: Pal.bronze),
        title: Text(currentLanguage == 'fr' ? 'Langue' : 'Language', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(currentLanguage == 'fr' ? 'Français' : 'English'),
        trailing: const Icon(Icons.swap_horiz),
        onTap: () => setState(toggleLanguage),
      )),
    ]),
  );
}
