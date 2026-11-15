# Corrections Patreon — Seerah Timeline 0.9.6

## Changements effectués
- Affichage clair des trois niveaux sur l’écran Premium : Traveller (2 $), Explorer (5 $), Companion (10 $).
- Traveller reste sans droit Premium ; Explorer et Companion gardent les cinq droits configurés par le backend.
- Suppression du cache Premium hors ligne de 24 heures. Si le serveur ne peut pas confirmer l’abonnement, les droits Premium sont suspendus : cela évite de conserver un accès après une résiliation ou une révocation.
- Validation des paramètres et gestion d’erreur sur l’échange du code OAuth à usage unique.
- Ajout d’une migration Supabase PostgreSQL reprenant le schéma Patreon. RLS est activé sur les quatre tables privées et aucune politique client n’est créée.
- Version Flutter mise à `0.9.6+17`.

## Ce qui reste à configurer avant une vraie mise en production
1. Appliquer la migration Supabase avec `npx.cmd supabase@latest db push` depuis la racine du projet.
2. Déployer le serveur Node `backend/` sur un hébergeur HTTPS et renseigner ses variables secrètes. Ne jamais mettre ces secrets dans Flutter.
3. Renseigner les vrais identifiants Patreon (Client ID, Client Secret, Campaign ID, webhook secret) dans les variables d’environnement du serveur. Vérifier les noms et prix exacts des tiers dans Patreon.
4. Compiler Flutter en passant l’URL publique du backend avec `--dart-define=PATREON_API_BASE_URL=https://VOTRE-API`.
5. Ajouter le deep link natif décrit dans `docs/patreon/PLATFORM_DEEP_LINKS.md`. L’archive reçue ne contenait pas les dossiers `android/` et `ios/`, donc ils n’ont pas pu être modifiés ici.

## Limite d’architecture à connaître
La version actuelle lie Patreon à un identifiant d’installation et à un JWT applicatif. La migration Supabase apporte le schéma PostgreSQL, mais **Supabase Auth n’est pas encore implémenté**. La connexion Patreon ne suit donc pas encore un compte Supabase partagé entre plusieurs appareils.

## Vérifications réalisées
- Syntaxe JavaScript du serveur vérifiée avec `node --check`.
- La compilation Flutter et le flux OAuth réel ne peuvent pas être validés sans les dossiers natifs, l’URL du backend déployé et les identifiants de test Patreon.
