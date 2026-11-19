# Correctif — « Autoriser » sans effet, puis « Session expirée »

## Cause
1. Après « Autoriser », Patreon renvoyait vers le serveur, qui répondait par une
   redirection 302 directe vers `seerahtimeline://patreon/callback`.
   Si le deep link n'est pas déclaré dans `AndroidManifest.xml` (cas d'un projet
   régénéré avec `flutter create`), ou si le navigateur bloque cette redirection
   (fréquent sur Chrome Android quand le serveur met quelques secondes à répondre),
   **rien ne se passe** : l'utilisateur reste sur la page Patreon.
2. Pourtant, côté serveur, la connexion avait réussi et l'état OAuth avait été
   **supprimé**. Le deuxième clic sur « Autoriser » envoyait le même état → « Session expirée ».
3. Bonus : `app_links` ≥ 6 livre le lien initial deux fois (getInitialLink + flux),
   ce qui provoquait un deuxième échange du code à usage unique, refusé en 400.

## Corrections
- Serveur : la fin de l'autorisation affiche une **vraie page** « Compte Patreon connecté »
  avec un bouton « Retourner dans Seerah Timeline » (un clic de l'utilisateur n'est jamais bloqué).
- Serveur : l'état OAuth est marqué « utilisé » au lieu d'être supprimé ; un double clic
  affiche « Connexion déjà validée » au lieu de « Session expirée ».
- Serveur : nouvel endpoint `POST /v1/patreon/oauth/poll`. L'app envoie un secret haché au
  démarrage ; au retour dans l'app, elle récupère la session **même sans deep link**.
- App : polling automatique au retour au premier plan, écran « En attente de Patreon… »
  avec « J'ai autorisé, vérifier », reprise si Android a tué l'app, déduplication du deep link,
  délais d'attente réseau (20 s).
- Durée de validité de la tentative portée à 20 min (connexion Patreon + 2FA).

## À faire de ton côté
1. Appliquer la migration : `npx supabase@latest db push`
   (fichier `supabase/migrations/20261119000000_patreon_oauth_poll.sql`).
2. Redéployer le backend (`backend/src/server.js`).
3. Après `flutter create . --platforms=android` : `python tools/add_patreon_deep_link.py`.
4. Recompiler l'app avec `--dart-define=PATREON_API_BASE_URL=https://TON-API`.
