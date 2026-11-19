CREATE TABLE IF NOT EXISTS oauth_states (
  state_hash TEXT PRIMARY KEY,
  installation_id UUID NOT NULL,
  poll_hash TEXT,
  expires_at TIMESTAMPTZ NOT NULL,
  consumed_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS oauth_states_poll_idx ON oauth_states(poll_hash) WHERE poll_hash IS NOT NULL;
CREATE TABLE IF NOT EXISTS app_sessions (
  code_hash TEXT PRIMARY KEY,
  installation_id UUID NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  consumed_at TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS patreon_links (
  installation_id UUID PRIMARY KEY,
  patreon_user_id TEXT NOT NULL,
  patreon_member_id TEXT,
  access_token_enc TEXT NOT NULL,
  refresh_token_enc TEXT,
  token_expires_at TIMESTAMPTZ,
  is_connected BOOLEAN NOT NULL DEFAULT TRUE,
  is_premium BOOLEAN NOT NULL DEFAULT FALSE,
  entitlements JSONB NOT NULL DEFAULT '[]'::jsonb,
  tier_id TEXT,
  tier_code TEXT,
  tier_name TEXT,
  patron_status TEXT,
  last_charge_status TEXT,
  valid_until TIMESTAMPTZ,
  last_verified_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS patreon_links_member_idx ON patreon_links(patreon_member_id);
CREATE TABLE IF NOT EXISTS webhook_events (
  event_key TEXT PRIMARY KEY,
  event_type TEXT NOT NULL,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
