import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import '../state/app_state.dart';

class PaywallScreen extends StatelessWidget {
  final AppState state;
  const PaywallScreen({super.key, required this.state});

  static List<String> get _features => [tr('f1'), tr('f2'), tr('f3'), tr('f4'), tr('f5'), tr('f6'), tr('f7')];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('premium_title'))),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final ps = state.purchases;
          if (state.isPremium) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified, size: 64, color: cs.primary),
                  const SizedBox(height: 12),
                  Text(tr('premium_active'), style: tt.headlineSmall),
                  const SizedBox(height: 8),
                  Text(tr('thanks_premium')),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () => Navigator.pop(context), child: Text(tr('continue'))),
                ]),
              ),
            );
          }
          final price = ps.product?.price ?? '4,99 €';
          return ListView(padding: const EdgeInsets.all(24), children: [
            Icon(Icons.workspace_premium, size: 56, color: cs.primary),
            const SizedBox(height: 12),
            Text(tr('one_time'), style: tt.headlineSmall, textAlign: TextAlign.center),
            Text(price, style: tt.displaySmall?.copyWith(color: cs.primary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            for (final f in _features)
              ListTile(dense: true, leading: Icon(Icons.check, color: cs.primary), title: Text(f)),
            const SizedBox(height: 16),
            if (ps.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(ps.error!, style: TextStyle(color: cs.error), textAlign: TextAlign.center),
              ),
            FilledButton(
              onPressed: ps.busy ? null : ps.buy,
              child: ps.busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(tr('unlock_for', {'price': price})),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: ps.busy ? null : ps.restore,
              child: Text(tr('restore')),
            ),
            const SizedBox(height: 12),
            if (!ps.storeAvailable)
              Text(tr('store_unavailable'),
                  style: tt.bodySmall, textAlign: TextAlign.center),
          ]);
        },
      ),
    );
  }
}
