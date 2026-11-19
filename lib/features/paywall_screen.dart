import 'package:flutter/material.dart';
import '../state/app_state.dart';

Future<void> _check(BuildContext context, AppState state) async {
  final message = await state.patreon.checkSubscription();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Widget _busyIcon(bool busy, IconData icon) => busy
    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
    : Icon(icon);

class PaywallScreen extends StatelessWidget {
  final AppState state;
  const PaywallScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Seerah Timeline Premium')),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final patreon = state.patreon;
          if (state.isPremium) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text('Compte Patreon connecté', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                if (patreon.tierName != null) Text('Niveau actuel : ${patreon.tierName}'),
                const SizedBox(height: 8),
                const Text('Ce niveau ne comprend pas nécessairement tous les contenus. Pour changer de niveau, rends-toi sur ta page Patreon depuis ton navigateur.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton.icon(onPressed: patreon.busy ? null : () => _check(context, state), icon: _busyIcon(patreon.busy, Icons.refresh), label: const Text('Actualiser mes droits')),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Retour')),
              ]),
            ));
          }
          if (patreon.awaitingAuthorization) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(width: 44, height: 44, child: CircularProgressIndicator(strokeWidth: 3)),
                const SizedBox(height: 20),
                Text('En attente de Patreon…', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                  'Valide l’accès sur la page Patreon (un seul clic sur « Autoriser » suffit), puis reviens ici : ta connexion sera détectée automatiquement.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: patreon.busy ? null : () => _check(context, state),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('J’ai autorisé, vérifier'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: patreon.busy ? null : patreon.connect,
                  child: const Text('Rouvrir la page Patreon'),
                ),
                TextButton(onPressed: patreon.cancelPending, child: const Text('Annuler')),
                if (patreon.error != null) ...[
                  const SizedBox(height: 8),
                  Text(patreon.error!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
                ],
              ]),
            ));
          }
          if (patreon.connected && !patreon.premium) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.link, size: 56),
                const SizedBox(height: 12),
                Text('Compte Patreon connecté', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Aucun niveau payant éligible n’a été détecté pour cette campagne. Vérifie ton abonnement ou consulte les niveaux disponibles.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: patreon.busy ? null : () => _check(context, state),
                  icon: _busyIcon(patreon.busy, Icons.refresh),
                  label: const Text('Vérifier mon abonnement'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: patreon.busy ? null : patreon.disconnect,
                  child: const Text('Utiliser un autre compte Patreon'),
                ),
                if (patreon.error != null) ...[
                  const SizedBox(height: 8),
                  Text(patreon.error!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
                ],
              ]),
            ));
          }
          return ListView(padding: const EdgeInsets.all(24), children: [
            Icon(Icons.workspace_premium, size: 60, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Soutenir Seerah Timeline', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            const Text('Connecte ton compte Patreon pour débloquer les contenus correspondant à ton niveau de soutien.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Text('Les niveaux de soutien', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.favorite_border),
              title: Text('Traveller — 2 \$ / mois'),
              subtitle: Text('Merci pour ton soutien. L’accès à l’application reste gratuit.'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.workspace_premium),
              title: Text('Explorer — 5 \$ / mois'),
              subtitle: Text('Accès Premium complet : événements, biographies, carte, arbre familial et bibliothèque.'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.verified),
              title: Text('Companion — 10 \$ / mois'),
              subtitle: Text('Les mêmes avantages Premium complets que le niveau Explorer.'),
            ),
            const SizedBox(height: 12),
            Text('Connecte le compte Patreon qui soutient Seerah Timeline. Le paiement et la gestion de l’abonnement se font sur Patreon, pas dans l’application.', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: patreon.busy ? null : patreon.connect,
              icon: patreon.busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.favorite),
              label: const Text('Connecter mon compte Patreon'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: patreon.busy ? null : () => _check(context, state),
              icon: const Icon(Icons.refresh),
              label: const Text('Vérifier mon abonnement'),
            ),
            if (patreon.error != null) ...[
              const SizedBox(height: 12),
              Text(patreon.error!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            Text('Les niveaux et leurs avantages sont définis par le créateur sur Patreon. La connexion ne déclenche aucun paiement dans l’application.', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ]);
        },
      ),
    );
  }
}
