# Seerah Timeline — Patreon API

Node.js 20+ / Express / PostgreSQL. Cette API est le seul composant autorisé à parler à Patreon avec les secrets OAuth.

La base peut être le PostgreSQL du projet Supabase. Le schéma existe dans `sql/schema.sql` et dans `../supabase/migrations/`. Après avoir lié le projet Supabase, appliquer la migration depuis la racine Flutter avec `npx.cmd supabase@latest db push`. Le backend doit ensuite recevoir une URL de connexion PostgreSQL Supabase dans `DATABASE_URL` (conserver cette valeur uniquement dans les variables secrètes de l’hébergeur).

## Développement local

```bash
cp .env.example .env
# Renseigner les variables ; utiliser une base PostgreSQL locale.
psql "$DATABASE_URL" -f sql/schema.sql
npm install
npm run dev
```

`GET /health` vérifie la disponibilité du processus. Ne publiez jamais `.env`, les journaux contenant des identifiants ou les sauvegardes de la base.

## Variables de production requises

- `DATABASE_URL`
- `APP_BASE_URL` (origine publique réservée)
- `PATREON_CLIENT_ID`, `PATREON_CLIENT_SECRET` (client OAuth Patreon API v2)
- `PATREON_REDIRECT_URI` (doit correspondre exactement à l'URL déclarée chez Patreon)
- `PATREON_CAMPAIGN_ID` (ID de la campagne TheLastMessage)
- `PATREON_ALLOWED_TIERS` (configuration exacte des tiers Explorer et Companion, voir `.env.example`)
- `APP_JWT_SECRET` (secret aléatoire long)
- `TOKEN_ENCRYPTION_KEY` (32 octets aléatoires encodés sur 64 caractères hexadécimaux)
- `PATREON_WEBHOOK_SECRET` (secret retourné par Patreon lors de la création du webhook)

Le mapping autorise uniquement le tier nommé `Explorer` à 500 cents et `Companion` à 1000 cents. `Traveller` n'est pas configuré et ne donne donc aucun droit. Les deux niveaux éligibles donnent accès aux entitlements `events`, `biographies`, `map`, `family_tree` et `library`.

## OAuth Patreon

Créer un client Patreon API v2 et autoriser les scopes `identity`, `identity.memberships` et `campaigns`. Configurer comme redirect URI l'URL de `PATREON_REDIRECT_URI`. Le serveur échange le code OAuth, chiffre les tokens, vérifie les adhésions via `currently_entitled_tiers`, puis redirige vers `seerahtimeline://patreon/callback` avec un code de transfert à usage unique.

Cette version ne met pas encore en œuvre Supabase Auth : l’association Patreon est encore liée à une installation de l’application, pas à un compte utilisateur multi-appareils. Le projet source ne contient pas les dossiers Android/iOS. Ajouter les déclarations natives indiquées dans `docs/patreon/PLATFORM_DEEP_LINKS.md`, puis compiler Flutter avec `--dart-define=PATREON_API_BASE_URL=https://<votre-api>`.

## Routes API

- `POST /v1/patreon/oauth/start`
- `GET /v1/patreon/oauth/callback`
- `POST /v1/patreon/oauth/exchange`
- `GET /v1/premium/status`
- `POST /v1/patreon/disconnect`
- `GET /v1/patreon/tiers`
- `POST /v1/patreon/webhook`

Le webhook doit utiliser les événements v2 `members:create`, `members:update`, `members:delete` et `members:pledge:delete` si disponibles dans le portail. Le callback et le statut restent les sources de vérité : le webhook déclenche une nouvelle vérification Patreon, il ne donne jamais de droits à lui seul.

## Checklist production

- HTTPS uniquement ; URL OAuth exacte enregistrée chez Patreon.
- PostgreSQL sauvegardé, clés de chiffrement sauvegardées et accès DB restreint.
- Limitation de débit partagée au reverse proxy/WAF (le limiteur inclus est seulement une protection basique par processus).
- Journaux expurgés : ne jamais journaliser les codes OAuth, tokens, secrets webhook ou en-têtes Authorization.
- Tester avec quatre comptes : Explorer, Companion, Traveller et sans adhésion ; vérifier aussi une adhésion annulée et une déconnexion.
- Tester le retour deep-link après connexion, application ouverte et fermée.
