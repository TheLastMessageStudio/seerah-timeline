# Configuration des niveaux Patreon — TheLastMessage

L'application n'accorde le premium qu'aux deux niveaux exacts ci-dessous :

| Niveau Patreon | Prix mensuel | Accès Seerah Timeline |
|---|---:|---|
| Traveller | 2 $ | Aucun accès premium |
| Explorer | 5 $ | Premium complet |
| Companion | 10 $ | Premium complet |

Explorer et Companion débloquent les mêmes fonctions dans Seerah Timeline : événements, biographies, carte, arbre familial et bibliothèque. Companion est simplement identifié comme le niveau supérieur.

Le backend vérifie les adhésions via Patreon API v2 et `currently_entitled_tiers`. Pour éviter toute confusion avec des IDs d'images ou d'autres liens Patreon, la règle combine le nom exact du tier et son montant en centimes. Le tier Traveller n'est volontairement pas présent dans la configuration autorisée.

## Configuration serveur

Copier `backend/.env.example` vers `.env`, puis renseigner les vraies valeurs :

- `PATREON_CLIENT_ID` et `PATREON_CLIENT_SECRET` : client OAuth v2 créé dans le portail développeur Patreon ;
- `PATREON_REDIRECT_URI` : URL publique exacte du callback backend, déclarée dans le client Patreon ;
- `PATREON_CAMPAIGN_ID` : ID de la campagne TheLastMessage ;
- `DATABASE_URL` : PostgreSQL ;
- `APP_JWT_SECRET` : secret aléatoire long ;
- `TOKEN_ENCRYPTION_KEY` : 32 octets aléatoires encodés en hexadécimal (64 caractères) ;
- `PATREON_WEBHOOK_SECRET` : secret communiqué lors de la création du webhook.

Ne jamais mettre les secrets Patreon dans Flutter, dans le dépôt Git ou dans une conversation. Ils doivent être saisis directement dans les variables d'environnement de l'hébergeur.

## API Patreon v2 — scopes

Le client OAuth doit autoriser `identity`, `identity.memberships` et `campaigns`. Les adhésions et niveaux sont lus via `/api/oauth2/v2/identity` avec les inclusions imbriquées `memberships.campaign` et `memberships.currently_entitled_tiers`.

## Validation

Après déploiement : vérifier `/health`, lancer les migrations SQL de `backend/sql/schema.sql`, connecter un compte Explorer, puis Companion, puis Traveller. Explorer et Companion doivent recevoir les cinq entitlements ; Traveller doit rester connecté sans entitlement et sans premium. Tester également un compte sans adhésion, une adhésion annulée et une déconnexion.
