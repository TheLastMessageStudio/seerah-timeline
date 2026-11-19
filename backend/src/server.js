import 'dotenv/config';
import express from 'express';
import helmet from 'helmet';
import pg from 'pg';
import jwt from 'jsonwebtoken';
import crypto from 'node:crypto';

const { Pool } = pg;
const app = express();
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : undefined });
const PORT = Number(process.env.PORT || 8080);
const API = 'https://www.patreon.com/api/oauth2/v2';
const allowedTiers = JSON.parse(process.env.PATREON_ALLOWED_TIERS || '{}');
// Le créateur ne peut pas être membre de sa propre campagne : il reçoit donc tous les droits
// configurés. PATREON_ADMIN_USER_IDS (IDs Patreon séparés par des virgules) permet d'ajouter des testeurs.
const adminUserIds = new Set((process.env.PATREON_ADMIN_USER_IDS || '').split(',').map(x => x.trim()).filter(Boolean));
const allEntitlements = [...new Set(Object.values(allowedTiers).flatMap(t => t.entitlements || []))];
app.use(helmet());
app.use('/v1', (req, res, next) => {
  // Basic per-process throttling; put a shared proxy/WAF rate limit in front in production.
  const now = Date.now();
  app.locals.rateBuckets ||= new Map();
  const key = req.ip; const bucket = app.locals.rateBuckets.get(key) || { start: now, count: 0 };
  if (now - bucket.start > 60_000) { bucket.start = now; bucket.count = 0; }
  bucket.count += 1; app.locals.rateBuckets.set(key, bucket);
  if (bucket.count > 60) return res.status(429).json({ error: 'rate_limited' });
  next();
});
app.use('/v1/patreon/webhook', express.raw({ type: '*/*', limit: '1mb' }));
app.use(express.json({ limit: '32kb' }));

function required(name) { const value = process.env[name]; if (!value) throw new Error(`Missing env ${name}`); return value; }
function hash(value) { return crypto.createHash('sha256').update(value).digest('hex'); }
function encrypt(value) {
  const key = Buffer.from(required('TOKEN_ENCRYPTION_KEY'), 'hex');
  if (key.length !== 32) throw new Error('TOKEN_ENCRYPTION_KEY must be 32 bytes hex');
  const iv = crypto.randomBytes(12); const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const body = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
  return [iv, cipher.getAuthTag(), body].map(x => x.toString('base64url')).join('.');
}
function decrypt(value) {
  const [iv, tag, body] = value.split('.').map(x => Buffer.from(x, 'base64url'));
  const decipher = crypto.createDecipheriv('aes-256-gcm', Buffer.from(required('TOKEN_ENCRYPTION_KEY'), 'hex'), iv);
  decipher.setAuthTag(tag); return Buffer.concat([decipher.update(body), decipher.final()]).toString('utf8');
}
function issueSession(installationId) { return jwt.sign({ sub: installationId, aud: 'seerah-app' }, required('APP_JWT_SECRET'), { expiresIn: '90d', issuer: 'seerah-patreon-api' }); }
function auth(req, res, next) {
  try { const token = (req.headers.authorization || '').replace(/^Bearer\s+/i, ''); const p = jwt.verify(token, required('APP_JWT_SECRET'), { audience: 'seerah-app', issuer: 'seerah-patreon-api' }); req.installationId = p.sub; next(); }
  catch { res.status(401).json({ error: 'invalid_session' }); }
}
async function tokenRequest(form) {
  const response = await fetch('https://www.patreon.com/api/oauth2/token', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'User-Agent': 'Seerah Timeline Patreon Integration' }, body: new URLSearchParams(form) });
  const data = await response.json(); if (!response.ok) throw new Error(`Patreon token exchange failed: ${response.status}`); return data;
}
async function apiGet(path, accessToken) {
  const response = await fetch(`${API}${path}`, { headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/json', 'User-Agent': 'Seerah Timeline Patreon Integration' } });
  const data = await response.json(); if (!response.ok) throw new Error(`Patreon API error ${response.status}`); return data;
}
async function freshTokens(link) {
  if (!link.token_expires_at || new Date(link.token_expires_at).getTime() > Date.now() + 60_000) return { access: decrypt(link.access_token_enc), refresh: link.refresh_token_enc ? decrypt(link.refresh_token_enc) : null, expiresAt: link.token_expires_at };
  if (!link.refresh_token_enc) throw new Error('Patreon refresh token missing');
  const refreshed = await tokenRequest({ grant_type: 'refresh_token', refresh_token: decrypt(link.refresh_token_enc), client_id: required('PATREON_CLIENT_ID'), client_secret: required('PATREON_CLIENT_SECRET') });
  const expiresAt = new Date(Date.now() + Number(refreshed.expires_in || 0) * 1000);
  await pool.query('UPDATE patreon_links SET access_token_enc=$1, refresh_token_enc=$2, token_expires_at=$3, updated_at=NOW() WHERE installation_id=$4', [encrypt(refreshed.access_token), refreshed.refresh_token ? encrypt(refreshed.refresh_token) : link.refresh_token_enc, expiresAt, link.installation_id]);
  return { access: refreshed.access_token, refresh: refreshed.refresh_token, expiresAt };
}
async function loadMembership(accessToken) {
  // Patreon API v2 requires nested includes and explicit fields for related resources.
  const query = new URLSearchParams({
    include: 'memberships.campaign,memberships.currently_entitled_tiers,campaign',
    'fields[user]': 'full_name',
    'fields[member]': 'patron_status,last_charge_status,last_charge_date,currently_entitled_amount_cents',
    'fields[tier]': 'title,amount_cents',
  });
  const identity = await apiGet(`/identity?${query.toString()}`, accessToken);
  const user = identity.data;
  const included = identity.included || [];
  const members = included.filter(x => x.type === 'member');
  const selected = members.find(m => String(m.relationships?.campaign?.data?.id) === String(required('PATREON_CAMPAIGN_ID'))) || null;
  const entitled = selected?.relationships?.currently_entitled_tiers?.data || [];
  const tiersById = new Map(included.filter(x => x.type === 'tier').map(x => [String(x.id), x]));
  const eligible = entitled.map(ref => {
    const tierData = tiersById.get(String(ref.id));
    const title = tierData?.attributes?.title || '';
    const amount = Number(tierData?.attributes?.amount_cents);
    const rule = allowedTiers[title];
    // Match both the exact configured tier name and its configured amount. Never infer access from price alone.
    return rule && amount === Number(rule.amount_cents) ? { id: String(ref.id), title, rule } : null;
  }).filter(Boolean).sort((a, b) => Number(b.rule.rank || 0) - Number(a.rule.rank || 0));
  const chosen = eligible[0] || null;
  const campaignId = required('PATREON_CAMPAIGN_ID');
  const ownedCampaignId = user?.relationships?.campaign?.data?.id ? String(user.relationships.campaign.data.id) : null;
  const isCreator = ownedCampaignId === String(campaignId);
  const isAdmin = isCreator || adminUserIds.has(String(user?.id));
  if (ownedCampaignId && !isCreator) {
    // Aide au diagnostic : si c'est ton propre compte, cette valeur est ton PATREON_CAMPAIGN_ID.
    console.warn(`Patreon user ${user?.id} owns campaign ${ownedCampaignId}, configured PATREON_CAMPAIGN_ID is ${campaignId}`);
  }
  if (isAdmin) {
    return {
      userId: user?.id, memberId: selected?.id || null,
      tierId: null, tierCode: isCreator ? 'creator' : 'admin',
      tierName: isCreator ? 'Créateur (accès complet)' : 'Testeur (accès complet)',
      entitlements: allEntitlements, premium: true,
      patronStatus: selected?.attributes?.patron_status || null,
      lastChargeStatus: selected?.attributes?.last_charge_status || null, validUntil: null,
    };
  }
  const memberStatus = selected?.attributes?.patron_status || null;
  const chargeStatus = selected?.attributes?.last_charge_status || null;
  const active = memberStatus === 'active_patron' && Boolean(chosen);
  const entitlements = active ? (chosen.rule.entitlements || []) : [];
  return {
    userId: user?.id, memberId: selected?.id || null,
    tierId: chosen?.id || null, tierCode: chosen?.rule.code || null,
    tierName: chosen?.rule.label || chosen?.title || null,
    entitlements: [...new Set(entitlements)], premium: active,
    patronStatus: memberStatus, lastChargeStatus: chargeStatus, validUntil: null,
  };
}
async function syncLink(installationId) {
  const result = await pool.query('SELECT * FROM patreon_links WHERE installation_id=$1 AND is_connected=TRUE', [installationId]);
  if (!result.rowCount) return null;
  const link = result.rows[0]; const tokens = await freshTokens(link); const membership = await loadMembership(tokens.access);
  await pool.query(`UPDATE patreon_links SET patreon_member_id=$1,is_premium=$2,tier_id=$3,tier_code=$4,tier_name=$5,entitlements=$6,patron_status=$7,last_charge_status=$8,valid_until=$9,last_verified_at=NOW(),updated_at=NOW() WHERE installation_id=$10`, [membership.memberId, membership.premium, membership.tierId, membership.tierCode, membership.tierName, JSON.stringify(membership.entitlements), membership.patronStatus, membership.lastChargeStatus, membership.validUntil, installationId]);
  return membership;
}

app.get('/health', (_req, res) => res.json({ ok: true, service: 'seerah-patreon-api' }));
app.get('/v1/patreon/tiers', (_req, res) => res.json({ tiers: Object.entries(allowedTiers).map(([name, t]) => ({ name, amount_cents: t.amount_cents, code: t.code, label: t.label, premium: true })) }));
app.post('/v1/patreon/oauth/start', async (req, res) => {
  try {
    const { installation_id: installationId, poll_secret: pollSecret } = req.body || {};
    if (!/^[0-9a-f-]{36}$/i.test(installationId || '')) return res.status(400).json({ error: 'invalid_installation_id' });
    if (pollSecret !== undefined && (typeof pollSecret !== 'string' || pollSecret.length < 32 || pollSecret.length > 128)) {
      return res.status(400).json({ error: 'invalid_poll_secret' });
    }
    // Nettoyage opportuniste des anciennes tentatives.
    await pool.query("DELETE FROM oauth_states WHERE expires_at < NOW() - INTERVAL '1 day'");
    const state = crypto.randomBytes(32).toString('base64url');
    await pool.query('INSERT INTO oauth_states(state_hash,installation_id,poll_hash,expires_at) VALUES($1,$2,$3,NOW()+INTERVAL \'20 minutes\')', [hash(state), installationId, pollSecret ? hash(pollSecret) : null]);
    const url = new URL('https://www.patreon.com/oauth2/authorize');
    url.search = new URLSearchParams({ response_type: 'code', client_id: required('PATREON_CLIENT_ID'), redirect_uri: required('PATREON_REDIRECT_URI'), scope: 'identity identity.memberships campaigns', state }).toString();
    res.json({ authorization_url: url.toString() });
  } catch (e) { console.error('OAuth start failed', e); res.status(500).json({ error: 'oauth_start_failed' }); }
});
// Page affichée dans le navigateur à la fin de l'autorisation.
// On n'utilise plus une redirection 302 directe vers seerahtimeline:// : les navigateurs
// (Chrome Android notamment) la bloquent souvent sans rien afficher, l'utilisateur reste
// sur la page Patreon, reclique sur « Autoriser » et tombe sur « Session expirée ».
function resultPage(res, status, { title, message, appUrl = null }) {
  const button = appUrl
    ? `<a class="btn" href="${appUrl}">Retourner dans Seerah Timeline</a>`
    : '';
  const refresh = appUrl ? `<meta http-equiv="refresh" content="0;url=${appUrl}">` : '';
  res.status(status).set('Cache-Control', 'no-store').type('html').send(`<!doctype html>
<html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">${refresh}
<title>${title}</title>
<style>
body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;background:#F4EBD8;font-family:system-ui,-apple-system,sans-serif;color:#1d2a24}
.card{max-width:420px;margin:24px;padding:32px 28px;background:#FBF7ED;border:1px solid #d9c9a3;border-radius:20px;text-align:center;box-shadow:0 10px 30px rgba(18,75,54,.12)}
h1{font-family:Georgia,serif;color:#124B36;font-size:22px;margin:0 0 12px}
p{line-height:1.55;margin:0 0 22px}
.btn{display:inline-block;background:#124B36;color:#fff;text-decoration:none;font-weight:700;padding:14px 22px;border-radius:14px}
small{display:block;margin-top:18px;color:#6b6252}
</style></head><body><div class="card"><h1>${title}</h1><p>${message}</p>${button}
<small>Tu peux aussi simplement revenir dans l’application : la connexion y sera détectée automatiquement.</small></div></body></html>`);
}

app.get('/v1/patreon/oauth/callback', async (req, res) => {
  let stateHash = null;
  try {
    const { code, state, error: oauthError } = req.query;
    if (oauthError) return resultPage(res, 400, { title: 'Autorisation refusée', message: 'Tu as refusé l’accès sur Patreon. Reviens dans l’application pour réessayer.' });
    if (!code || !state) return resultPage(res, 400, { title: 'Lien invalide', message: 'Cette page de connexion est incomplète. Relance la connexion depuis l’application.' });
    stateHash = hash(String(state));
    // On marque l'état comme utilisé au lieu de le supprimer : un deuxième clic sur
    // « Autoriser » doit afficher un message clair, pas « Session expirée ».
    const stateResult = await pool.query('UPDATE oauth_states SET consumed_at=NOW() WHERE state_hash=$1 AND expires_at>NOW() AND consumed_at IS NULL RETURNING installation_id', [stateHash]);
    if (!stateResult.rowCount) {
      const existing = await pool.query('SELECT completed_at, failed_at FROM oauth_states WHERE state_hash=$1', [stateHash]);
      const row = existing.rows[0];
      if (row?.completed_at) return resultPage(res, 200, { title: 'Compte Patreon connecté', message: 'La connexion a déjà été validée. Retourne dans Seerah Timeline.', appUrl: 'seerahtimeline://patreon/callback?status=done' });
      if (row && !row.failed_at) return resultPage(res, 200, { title: 'Connexion en cours…', message: 'Ta première autorisation est en cours de traitement. Retourne dans l’application, ton accès va s’afficher.' , appUrl: 'seerahtimeline://patreon/callback?status=pending' });
      return resultPage(res, 400, { title: 'Session expirée', message: 'Cette tentative de connexion n’est plus valable. Retourne dans Seerah Timeline et relance la connexion.' });
    }
    const installationId = stateResult.rows[0].installation_id;
    const tokens = await tokenRequest({ grant_type: 'authorization_code', code: String(code), client_id: required('PATREON_CLIENT_ID'), client_secret: required('PATREON_CLIENT_SECRET'), redirect_uri: required('PATREON_REDIRECT_URI') });
    const membership = await loadMembership(tokens.access_token);
    if (!membership.userId) throw new Error('Patreon returned no user profile');
    const expiresAt = new Date(Date.now() + Number(tokens.expires_in || 0) * 1000);
    await pool.query(`INSERT INTO patreon_links(installation_id,patreon_user_id,patreon_member_id,access_token_enc,refresh_token_enc,token_expires_at,is_connected,is_premium,tier_id,tier_code,tier_name,entitlements,patron_status,last_charge_status,last_verified_at)
      VALUES($1,$2,$3,$4,$5,$6,TRUE,$7,$8,$9,$10,$11,$12,$13,NOW())
      ON CONFLICT(installation_id) DO UPDATE SET patreon_user_id=EXCLUDED.patreon_user_id,patreon_member_id=EXCLUDED.patreon_member_id,access_token_enc=EXCLUDED.access_token_enc,refresh_token_enc=EXCLUDED.refresh_token_enc,token_expires_at=EXCLUDED.token_expires_at,is_connected=TRUE,is_premium=EXCLUDED.is_premium,tier_id=EXCLUDED.tier_id,tier_code=EXCLUDED.tier_code,tier_name=EXCLUDED.tier_name,entitlements=EXCLUDED.entitlements,patron_status=EXCLUDED.patron_status,last_charge_status=EXCLUDED.last_charge_status,last_verified_at=NOW(),updated_at=NOW()`, [installationId, membership.userId, membership.memberId, encrypt(tokens.access_token), tokens.refresh_token ? encrypt(tokens.refresh_token) : null, expiresAt, membership.premium, membership.tierId, membership.tierCode, membership.tierName, JSON.stringify(membership.entitlements), membership.patronStatus, membership.lastChargeStatus]);
    const oneTime = crypto.randomBytes(32).toString('base64url');
    await pool.query('INSERT INTO app_sessions(code_hash,installation_id,expires_at) VALUES($1,$2,NOW()+INTERVAL \'10 minutes\')', [hash(oneTime), installationId]);
    await pool.query('UPDATE oauth_states SET completed_at=NOW() WHERE state_hash=$1', [stateHash]);
    return resultPage(res, 200, {
      title: 'Compte Patreon connecté ✓',
      message: membership.premium ? 'Ton soutien a bien été vérifié. Retourne dans Seerah Timeline pour profiter de ton accès.' : 'Ton compte est relié. Aucun niveau Premium n’a été détecté pour l’instant ; tu pourras vérifier ton abonnement dans l’application.',
      appUrl: `seerahtimeline://patreon/callback?code=${encodeURIComponent(oneTime)}`,
    });
  } catch (e) {
    console.error('OAuth callback failed', e);
    if (stateHash) await pool.query('UPDATE oauth_states SET failed_at=NOW() WHERE state_hash=$1', [stateHash]).catch(() => {});
    return resultPage(res, 500, { title: 'La connexion a échoué', message: 'Patreon n’a pas pu confirmer ton compte. Retourne dans l’application et réessaie.' });
  }
});

// Solution de secours sans deep link : l'app interroge le serveur avec un secret
// qu'elle seule connaît (envoyé haché au démarrage du flux).
app.post('/v1/patreon/oauth/poll', async (req, res) => {
  try {
    const { installation_id: installationId, poll_secret: pollSecret } = req.body || {};
    if (typeof installationId !== 'string' || !/^[0-9a-f-]{36}$/i.test(installationId) ||
        typeof pollSecret !== 'string' || pollSecret.length < 32 || pollSecret.length > 128) {
      return res.status(400).json({ error: 'invalid_poll_request' });
    }
    const result = await pool.query('SELECT state_hash, completed_at, failed_at, delivered_at, expires_at FROM oauth_states WHERE poll_hash=$1 AND installation_id=$2', [hash(pollSecret), installationId]);
    const row = result.rows[0];
    if (!row) return res.status(404).json({ status: 'unknown' });
    if (row.failed_at) return res.json({ status: 'failed' });
    if (!row.completed_at) {
      // 30 min de marge : la connexion à Patreon (mot de passe, 2FA…) peut être longue.
      return res.json({ status: new Date(row.expires_at).getTime() + 10 * 60_000 < Date.now() ? 'expired' : 'pending' });
    }
    const delivered = await pool.query('UPDATE oauth_states SET delivered_at=NOW() WHERE state_hash=$1 AND delivered_at IS NULL RETURNING state_hash', [row.state_hash]);
    if (!delivered.rowCount) return res.json({ status: 'already_delivered' });
    return res.json({ status: 'done', session_token: issueSession(installationId) });
  } catch (e) {
    console.error('OAuth poll failed', e);
    return res.status(500).json({ error: 'oauth_poll_failed' });
  }
});
app.post('/v1/patreon/oauth/exchange', async (req, res) => {
  try {
    const { code, installation_id: installationId } = req.body || {};
    if (typeof code !== 'string' || code.length < 20 ||
        typeof installationId !== 'string' ||
        !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(installationId)) {
      return res.status(400).json({ error: 'invalid_exchange_request' });
    }
    const result = await pool.query(
      'DELETE FROM app_sessions WHERE code_hash=$1 AND installation_id=$2 AND expires_at>NOW() AND consumed_at IS NULL RETURNING installation_id',
      [hash(code), installationId],
    );
    if (!result.rowCount) return res.status(400).json({ error: 'invalid_or_expired_code' });
    return res.json({ session_token: issueSession(installationId) });
  } catch (e) {
    console.error('OAuth exchange failed', e);
    return res.status(500).json({ error: 'oauth_exchange_failed' });
  }
});
app.get('/v1/premium/status', auth, async (req, res) => {
  try {
    const membership = await syncLink(req.installationId);
    const row = await pool.query('SELECT is_connected,is_premium,tier_code,tier_name,entitlements,valid_until,last_verified_at FROM patreon_links WHERE installation_id=$1', [req.installationId]);
    if (!row.rowCount) return res.json({ patreon_connected: false, premium: false, entitlements: [] });
    const r = row.rows[0];
    res.json({ patreon_connected: r.is_connected, premium: membership?.premium ?? r.is_premium, tier_code: membership?.tierCode ?? r.tier_code, tier_name: membership?.tierName ?? r.tier_name, entitlements: membership?.entitlements ?? r.entitlements ?? [], valid_until: r.valid_until, verified_at: r.last_verified_at });
  } catch (e) { console.error('Status check failed', e); res.status(503).json({ error: 'patreon_verification_unavailable' }); }
});
app.post('/v1/patreon/disconnect', auth, async (req, res) => {
  await pool.query('UPDATE patreon_links SET is_connected=FALSE,is_premium=FALSE,access_token_enc=\'\',refresh_token_enc=NULL,updated_at=NOW() WHERE installation_id=$1', [req.installationId]);
  res.json({ disconnected: true });
});
app.post('/v1/patreon/webhook', async (req, res) => {
  try {
    const raw = req.body;
    const signature = req.header('X-Patreon-Signature') || '';
    const expected = crypto.createHmac('md5', required('PATREON_WEBHOOK_SECRET')).update(raw).digest('hex');
    const a = Buffer.from(signature, 'hex'); const b = Buffer.from(expected, 'hex');
    if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return res.status(401).send('bad signature');
    const eventType = req.header('X-Patreon-Event') || 'unknown';
    const payload = JSON.parse(raw.toString('utf8'));
    const memberId = payload?.data?.id;
    const userId = payload?.data?.relationships?.user?.data?.id;
    const eventKey = hash(`${eventType}:${memberId}:${JSON.stringify(payload).slice(0, 500)}`);
    await pool.query('INSERT INTO webhook_events(event_key,event_type) VALUES($1,$2) ON CONFLICT DO NOTHING', [eventKey, eventType]);
    if (userId) {
      const link = await pool.query('SELECT installation_id FROM patreon_links WHERE patreon_user_id=$1', [String(userId)]);
      for (const row of link.rows) await syncLink(row.installation_id);
    }
    res.status(200).send('ok');
  } catch (e) { console.error('Webhook processing failed', e); res.status(500).send('retry'); }
});

app.listen(PORT, () => console.log(`Seerah Patreon API listening on ${PORT}`));
