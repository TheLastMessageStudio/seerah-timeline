import '../l10n/strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'nav.dart';

class SettingsScreen extends StatelessWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('settings'))),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => ListView(padding: const EdgeInsets.all(16), children: [
          Text(tr('language'), style: tt.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              for (final l in Strings.supported)
                ButtonSegment(value: l, label: Text(Strings.names[l]!)),
            ],
            selected: {state.lang},
            onSelectionChanged: (v) => state.setLang(v.first),
          ),
          const SizedBox(height: 16),
          Text(tr('premium'), style: tt.titleMedium),
          Card(
            child: ListTile(
              leading: Icon(state.isPremium ? Icons.verified : Icons.workspace_premium_outlined),
              title: Text(state.isPremium ? tr('premium_active') : tr('free_version')),
              subtitle: Text(state.isPremium
                  ? 'Niveau Patreon : ${state.patreon.tierName ?? 'actif'}'
                  : tr('unlock_rest')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openPaywall(context, state),
            ),
          ),
          if (state.patreon.connected) ...[
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(state.patreon.tierName ?? 'Compte Patreon connecté'),
              subtitle: const Text('Abonnement vérifié par Seerah Timeline'),
              trailing: TextButton(onPressed: state.patreon.disconnect, child: const Text('Déconnecter')),
            ),
            TextButton.icon(onPressed: state.patreon.refreshStatus, icon: const Icon(Icons.refresh), label: const Text('Actualiser mon accès Patreon')),
          ] else if (!state.isPremium)
            TextButton.icon(
              onPressed: state.patreon.refreshStatus,
              icon: const Icon(Icons.refresh),
              label: const Text('Vérifier Patreon'),
            ),
          if (kDebugMode) ...[
            Card(child: SwitchListTile(
              secondary: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Mode administrateur (test)'),
              subtitle: const Text('Désactive temporairement les verrous de sortie et Premium sur cette version de test uniquement.'),
              value: state.debugAdminPreview,
              onChanged: state.setDebugAdminPreview,
            )),
            SwitchListTile(
              title: Text(tr('debug_premium')),
              subtitle: Text(tr('debug_only')),
              value: state.debugPremium,
              onChanged: state.setDebugPremium,
            ),
          ],
          const SizedBox(height: 16),
          Text(tr('appearance'), style: tt.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(value: ThemeMode.system, label: Text(tr('theme_auto'))),
              ButtonSegment(value: ThemeMode.light, label: Text(tr('theme_light'))),
              ButtonSegment(value: ThemeMode.dark, label: Text(tr('theme_dark'))),
            ],
            selected: {state.themeMode},
            onSelectionChanged: (v) => state.setThemeMode(v.first),
          ),
          const SizedBox(height: 16),
          Text(tr('text_size'), style: tt.bodyMedium),
          Slider(
            value: state.textScale,
            min: 0.85,
            max: 1.5,
            divisions: 13,
            label: '${(state.textScale * 100).round()} %',
            onChanged: state.setTextScale,
          ),
          const SizedBox(height: 8),
          Text(tr('data'), style: tt.titleMedium),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline),
            title: Text(tr('reset_progress')),
            subtitle: Text(tr('reset_sub')),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text(tr('reset_q')),
                  content: Text(tr('reset_body')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('cancel'))),
                    FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('reset'))),
                  ],
                ),
              );
              if (ok == true) state.resetProgress();
            },
          ),
          const SizedBox(height: 16),
          Text(tr('principles'), style: tt.titleMedium),
          const SizedBox(height: 8),
          Text(tr('principles_text')),
          const SizedBox(height: 16),
          Center(child: Text('${tr('app_name')} · ${tr('version', {'v': '0.9.5'})}', style: tt.bodySmall)),
        ]),
      ),
    );
  }
}
