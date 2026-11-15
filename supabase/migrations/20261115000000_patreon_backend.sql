-- Seerah Timeline Patreon backend tables.
-- These tables are private: only the trusted backend should access them.
CREATE TABLE IF NOT EXISTS oauth_states (
  state_hash TEXT PRIMARY KEY,
  installation_id UUID NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
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

ALTER TABLE public.oauth_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patreon_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.webhook_events ENABLE ROW LEVEL SECURITY;
