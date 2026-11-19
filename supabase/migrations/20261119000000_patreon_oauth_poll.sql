-- Patreon OAuth : états idempotents + récupération de la session par « polling ».
-- Corrige le cas « premier clic sur Autoriser sans effet, deuxième clic = session expirée ».
ALTER TABLE public.oauth_states ADD COLUMN IF NOT EXISTS poll_hash TEXT;
ALTER TABLE public.oauth_states ADD COLUMN IF NOT EXISTS consumed_at TIMESTAMPTZ;
ALTER TABLE public.oauth_states ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;
ALTER TABLE public.oauth_states ADD COLUMN IF NOT EXISTS failed_at TIMESTAMPTZ;
ALTER TABLE public.oauth_states ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;
CREATE UNIQUE INDEX IF NOT EXISTS oauth_states_poll_idx ON public.oauth_states(poll_hash) WHERE poll_hash IS NOT NULL;
