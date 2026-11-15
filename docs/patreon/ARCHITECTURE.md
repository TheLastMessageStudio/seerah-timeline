# Architecture Patreon

1. Flutter crée ou réutilise un identifiant d'installation aléatoire et demande au backend une URL OAuth.
2. Le backend stocke un `state` haché à usage unique, puis redirige le navigateur vers Patreon.
3. Patreon revient au callback HTTPS du backend. Le backend valide le `state`, échange le code OAuth et interroge l'API Patreon v2.
4. Le backend vérifie la campagne attendue et les niveaux réellement présents dans `currently_entitled_tiers`. Les seuls niveaux autorisés sont `Explorer` (500 cents) et `Companion` (1000 cents), avec nom exact ; Traveller est exclu.
5. Les tokens Patreon sont chiffrés avec AES-256-GCM dans PostgreSQL. Le backend crée un code de transfert éphémère, puis redirige vers `seerahtimeline://patreon/callback`.
6. Flutter échange ce code contre un JWT applicatif et stocke uniquement ce JWT dans le stockage sécurisé. Les secrets Patreon ne sont jamais embarqués dans l'application.
7. Chaque vérification de statut renouvelle si nécessaire le token Patreon puis relit l'adhésion côté serveur. Le cache local de droits est limité à 24 heures pour un usage hors ligne.
8. Les webhooks Patreon sont authentifiés par HMAC et déclenchent une nouvelle lecture de l'adhésion ; le payload webhook seul ne constitue pas une preuve d'accès.

Le déploiement réel nécessite les secrets OAuth, l'ID de campagne, PostgreSQL, HTTPS et la configuration deep-link native décrite dans `PLATFORM_DEEP_LINKS.md`.

## Base Supabase — périmètre actuel

Le schéma PostgreSQL Patreon est également disponible comme migration dans `supabase/migrations/`. Il peut être appliqué au projet Supabase lié avec `npx.cmd supabase@latest db push`. Les quatre tables backend activent RLS et ne définissent aucune politique d’accès client : elles sont réservées au serveur de confiance.

**Important :** cette version utilise encore un identifiant d’installation aléatoire et un JWT applicatif pour rattacher Patreon à une installation. Supabase Auth (comptes utilisateur, connexion par e-mail, liaison multi-appareils) n’est pas encore intégré. Ne pas présenter cette version comme une authentification Supabase complète.
