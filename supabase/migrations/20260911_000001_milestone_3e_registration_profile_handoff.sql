BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.registration_invitations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  prospect_id uuid NOT NULL,
  invitation_channel text NOT NULL CHECK (invitation_channel IN ('email', 'text', 'social_media', 'phone')),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'awaiting_approval', 'approved', 'sent', 'accepted', 'expired', 'revoked', 'rejected')),
  human_approval_required boolean NOT NULL DEFAULT true,
  human_approval_granted boolean NOT NULL DEFAULT false,
  approved_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  approved_at timestamptz,
  approval_reason text,
  consent_allowed boolean NOT NULL DEFAULT false,
  consent_evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
  opt_out_active boolean NOT NULL DEFAULT false,
  suppression_evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
  frequency_ok boolean NOT NULL DEFAULT false,
  frequency_reason text,
  source_context jsonb NOT NULL DEFAULT '{}'::jsonb,
  campaign_id uuid,
  source_type text,
  source_handle text,
  source_message_id uuid,
  external_provider text,
  invitation_token text NOT NULL,
  token_hash text NOT NULL,
  expires_at timestamptz,
  sent_at timestamptz,
  accepted_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  rejected_at timestamptz,
  rejection_reason text,
  single_use boolean NOT NULL DEFAULT true,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (tenant_id, invitation_token),
  UNIQUE (tenant_id, prospect_id, campaign_id, source_message_id)
);

CREATE TABLE IF NOT EXISTS public.registration_handoffs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  prospect_id uuid NOT NULL,
  invitation_id uuid REFERENCES public.registration_invitations(id) ON DELETE SET NULL,
  provider_name text NOT NULL CHECK (provider_name IN ('brilliant_directories')),
  external_member_id text,
  external_profile_id text,
  profile_state text NOT NULL DEFAULT 'pending' CHECK (profile_state IN ('pending', 'created', 'claimed', 'completed')),
  registration_url text,
  provider_status text NOT NULL DEFAULT 'pending' CHECK (provider_status IN ('pending', 'configured', 'ready', 'created', 'claimed', 'completed', 'failed', 'restricted', 'disconnected')),
  last_sync_status text NOT NULL DEFAULT 'pending' CHECK (last_sync_status IN ('pending', 'synced', 'failed', 'duplicate', 'review_required')),
  idempotency_key text,
  provider_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, prospect_id, provider_name, external_member_id)
);

CREATE TABLE IF NOT EXISTS public.member_profile_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  prospect_id uuid NOT NULL,
  member_profile_id uuid,
  provider_name text NOT NULL CHECK (provider_name IN ('brilliant_directories')),
  external_member_id text,
  external_profile_id text,
  claimed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  claim_state text NOT NULL DEFAULT 'pending' CHECK (claim_state IN ('pending', 'created', 'claimed', 'completed')),
  link_status text NOT NULL DEFAULT 'active' CHECK (link_status IN ('active', 'replaced', 'rejected', 'review_required')),
  match_confidence numeric(4,3) NOT NULL DEFAULT 0,
  normalized_email text,
  normalized_phone text,
  source_handle text,
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, prospect_id, provider_name, external_member_id),
  UNIQUE (tenant_id, provider_name, external_profile_id)
);

CREATE TABLE IF NOT EXISTS public.registration_journey_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  prospect_id uuid,
  invitation_id uuid REFERENCES public.registration_invitations(id) ON DELETE SET NULL,
  profile_link_id uuid REFERENCES public.member_profile_links(id) ON DELETE SET NULL,
  related_thread_id uuid,
  related_message_id uuid,
  event_source text NOT NULL CHECK (event_source IN ('discovery', 'outreach', 'response', 'invitation_approval', 'invitation_sent', 'registration_started', 'profile_created', 'profile_claimed', 'profile_completed', 'verification_pending', 'verified', 'audit', 'system')),
  actor text,
  stage text NOT NULL CHECK (stage IN ('invitation_sent', 'registration_started', 'profile_created', 'profile_claimed', 'profile_completed', 'verification_pending', 'verified')),
  previous_stage text,
  new_stage text,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (previous_stage IS NULL OR previous_stage IN ('invitation_sent', 'registration_started', 'profile_created', 'profile_claimed', 'profile_completed', 'verification_pending', 'verified')),
  CHECK (new_stage IS NULL OR new_stage IN ('invitation_sent', 'registration_started', 'profile_created', 'profile_claimed', 'profile_completed', 'verification_pending', 'verified'))
);

CREATE TABLE IF NOT EXISTS public.registration_match_candidates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  prospect_id uuid,
  provider_name text NOT NULL CHECK (provider_name IN ('brilliant_directories')),
  external_member_id text,
  normalized_email text,
  normalized_phone text,
  source_handle text,
  candidate_type text NOT NULL CHECK (candidate_type IN ('prospect_match', 'profile_ambiguous', 'provider_unmatched', 'duplicate_review')),
  confidence_score numeric(4,3) NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'review_required')),
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, provider_name, external_member_id)
);

CREATE TABLE IF NOT EXISTS public.brilliant_directories_sync_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  prospect_id uuid,
  invitation_id uuid REFERENCES public.registration_invitations(id) ON DELETE SET NULL,
  profile_link_id uuid REFERENCES public.member_profile_links(id) ON DELETE SET NULL,
  provider_name text NOT NULL DEFAULT 'brilliant_directories' CHECK (provider_name IN ('brilliant_directories')),
  external_member_id text,
  external_profile_id text,
  event_type text NOT NULL,
  event_status text NOT NULL DEFAULT 'received' CHECK (event_status IN ('received', 'processed', 'duplicate', 'failed', 'review_required')),
  provider_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  payload_hash text NOT NULL,
  processed_at timestamptz,
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, provider_name, external_member_id, payload_hash)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_registration_invitations_token ON public.registration_invitations (tenant_id, invitation_token);
CREATE UNIQUE INDEX IF NOT EXISTS ux_registration_invitations_single_use ON public.registration_invitations (tenant_id, prospect_id, invitation_channel, status) WHERE status IN ('approved', 'sent');
CREATE UNIQUE INDEX IF NOT EXISTS ux_registration_handoffs_active_provider_member ON public.registration_handoffs (tenant_id, provider_name, external_member_id) WHERE provider_status IN ('pending', 'configured', 'ready', 'created', 'claimed', 'completed');
CREATE UNIQUE INDEX IF NOT EXISTS ux_member_profile_links_external_profile ON public.member_profile_links (tenant_id, provider_name, external_profile_id) WHERE external_profile_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_registration_journey_stage ON public.registration_journey_events (tenant_id, prospect_id, occurred_at);
CREATE UNIQUE INDEX IF NOT EXISTS ux_registration_match_candidates_identity ON public.registration_match_candidates (tenant_id, provider_name, normalized_email, normalized_phone, source_handle) WHERE normalized_email IS NOT NULL OR normalized_phone IS NOT NULL OR source_handle IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_brilliant_directories_sync_events_idempotency ON public.brilliant_directories_sync_events (tenant_id, provider_name, event_type, payload_hash);

ALTER TABLE public.registration_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registration_handoffs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.member_profile_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registration_journey_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registration_match_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brilliant_directories_sync_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read registration invitations" ON public.registration_invitations;
CREATE POLICY "Authenticated users can read registration invitations" ON public.registration_invitations FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can insert registration invitations" ON public.registration_invitations FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can update registration invitations" ON public.registration_invitations FOR UPDATE USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can delete registration invitations" ON public.registration_invitations FOR DELETE USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can read registration handoffs" ON public.registration_handoffs;
CREATE POLICY "Authenticated users can read registration handoffs" ON public.registration_handoffs FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can insert registration handoffs" ON public.registration_handoffs FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can update registration handoffs" ON public.registration_handoffs FOR UPDATE USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can delete registration handoffs" ON public.registration_handoffs FOR DELETE USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can read member profile links" ON public.member_profile_links;
CREATE POLICY "Authenticated users can read member profile links" ON public.member_profile_links FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can insert member profile links" ON public.member_profile_links FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can update member profile links" ON public.member_profile_links FOR UPDATE USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can delete member profile links" ON public.member_profile_links FOR DELETE USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can read registration journey events" ON public.registration_journey_events;
CREATE POLICY "Authenticated users can read registration journey events" ON public.registration_journey_events FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can insert registration journey events" ON public.registration_journey_events FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can update registration journey events" ON public.registration_journey_events FOR UPDATE USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can delete registration journey events" ON public.registration_journey_events FOR DELETE USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can read registration match candidates" ON public.registration_match_candidates;
CREATE POLICY "Authenticated users can read registration match candidates" ON public.registration_match_candidates FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can insert registration match candidates" ON public.registration_match_candidates FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can update registration match candidates" ON public.registration_match_candidates FOR UPDATE USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can delete registration match candidates" ON public.registration_match_candidates FOR DELETE USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can read Brilliant Directories sync events" ON public.brilliant_directories_sync_events;
CREATE POLICY "Authenticated users can read Brilliant Directories sync events" ON public.brilliant_directories_sync_events FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can insert Brilliant Directories sync events" ON public.brilliant_directories_sync_events FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can update Brilliant Directories sync events" ON public.brilliant_directories_sync_events FOR UPDATE USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can delete Brilliant Directories sync events" ON public.brilliant_directories_sync_events FOR DELETE USING (auth.uid() IS NOT NULL);

CREATE OR REPLACE FUNCTION public.evaluate_registration_invitation_eligibility(
  p_tenant_id uuid,
  p_prospect_id uuid,
  p_channel text,
  p_consent_allowed boolean,
  p_opt_out_active boolean,
  p_frequency_ok boolean,
  p_human_approval_granted boolean,
  p_is_expired boolean DEFAULT false,
  p_is_revoked boolean DEFAULT false,
  p_frequency_reason text DEFAULT NULL
) RETURNS TABLE (
  allowed boolean,
  reason text,
  code text
) LANGUAGE plpgsql AS $$
BEGIN
  IF p_consent_allowed IS NOT TRUE THEN
    RETURN QUERY SELECT false, 'Consent is missing or denied.', 'consent_missing';
    RETURN;
  END IF;

  IF p_opt_out_active IS TRUE THEN
    RETURN QUERY SELECT false, 'Opt-out is active and blocks invitation delivery.', 'opt_out_active';
    RETURN;
  END IF;

  IF p_frequency_ok IS NOT TRUE THEN
    RETURN QUERY SELECT false, COALESCE(p_frequency_reason, 'Frequency limit reached.'), 'frequency_limit_reached';
    RETURN;
  END IF;

  IF p_is_expired IS TRUE THEN
    RETURN QUERY SELECT false, 'Invitation has expired.', 'invitation_expired';
    RETURN;
  END IF;

  IF p_is_revoked IS TRUE THEN
    RETURN QUERY SELECT false, 'Invitation has been revoked.', 'invitation_revoked';
    RETURN;
  END IF;

  IF p_human_approval_granted IS NOT TRUE THEN
    RETURN QUERY SELECT false, 'Human approval is required before this invitation can be sent.', 'human_approval_required';
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Eligible for invitation approval and delivery.', 'eligible';
END;
$$;

CREATE OR REPLACE FUNCTION public.create_registration_invitation(
  p_tenant_id uuid,
  p_prospect_id uuid,
  p_channel text,
  p_status text,
  p_human_approval_required boolean,
  p_human_approval_granted boolean,
  p_consent_allowed boolean,
  p_opt_out_active boolean,
  p_frequency_ok boolean,
  p_source_context jsonb,
  p_campaign_id uuid DEFAULT NULL,
  p_source_type text DEFAULT NULL,
  p_source_handle text DEFAULT NULL,
  p_source_message_id uuid DEFAULT NULL,
  p_invitation_token text DEFAULT NULL,
  p_expires_at timestamptz DEFAULT NULL,
  p_single_use boolean DEFAULT true,
  p_metadata jsonb DEFAULT '{}'::jsonb
) RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
  v_invitation_id uuid;
  v_token text;
BEGIN
  v_token := COALESCE(p_invitation_token, encode(gen_random_bytes(24), 'hex'));

  INSERT INTO public.registration_invitations (
    tenant_id, prospect_id, invitation_channel, status, human_approval_required,
    human_approval_granted, consent_allowed, opt_out_active, frequency_ok, source_context,
    campaign_id, source_type, source_handle, source_message_id, invitation_token,
    token_hash, expires_at, single_use, metadata
  ) VALUES (
    p_tenant_id, p_prospect_id, p_channel, p_status, p_human_approval_required,
    p_human_approval_granted, p_consent_allowed, p_opt_out_active, p_frequency_ok, p_source_context,
    p_campaign_id, p_source_type, p_source_handle, p_source_message_id, v_token,
    encode(digest(v_token, 'sha256'), 'hex'), p_expires_at, p_single_use, p_metadata
  ) RETURNING id INTO v_invitation_id;

  RETURN v_invitation_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.approve_registration_invitation(
  p_invitation_id uuid,
  p_approved_by uuid,
  p_approval_reason text,
  p_consented boolean DEFAULT true,
  p_human_approval_granted boolean DEFAULT true
) RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN
  UPDATE public.registration_invitations
  SET status = 'approved',
      approved_by = p_approved_by,
      approved_at = now(),
      approval_reason = p_approval_reason,
      consent_allowed = p_consented,
      human_approval_granted = p_human_approval_granted,
      updated_at = now()
  WHERE id = p_invitation_id;

  RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_registration_invitation_sent(
  p_invitation_id uuid,
  p_sent_by uuid DEFAULT NULL,
  p_channel text DEFAULT 'email'
) RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN
  UPDATE public.registration_invitations
  SET status = 'sent',
      sent_at = now(),
      invitation_channel = COALESCE(p_channel, invitation_channel),
      updated_at = now()
  WHERE id = p_invitation_id
    AND status IN ('approved', 'awaiting_approval')
    AND consent_allowed IS TRUE
    AND opt_out_active IS FALSE
    AND frequency_ok IS TRUE
    AND human_approval_granted IS TRUE;

  RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION public.start_registration_handoff(
  p_tenant_id uuid,
  p_prospect_id uuid,
  p_invitation_id uuid,
  p_provider_name text,
  p_external_member_id text,
  p_external_profile_id text DEFAULT NULL,
  p_registration_url text DEFAULT NULL,
  p_idempotency_key text DEFAULT NULL,
  p_provider_metadata jsonb DEFAULT '{}'::jsonb
) RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
  v_handoff_id uuid;
BEGIN
  INSERT INTO public.registration_handoffs (
    tenant_id, prospect_id, invitation_id, provider_name, external_member_id,
    external_profile_id, registration_url, idempotency_key, provider_metadata,
    profile_state, provider_status, last_sync_status
  ) VALUES (
    p_tenant_id, p_prospect_id, p_invitation_id, p_provider_name, p_external_member_id,
    p_external_profile_id, p_registration_url, p_idempotency_key, p_provider_metadata,
    'pending', 'pending', 'pending'
  ) ON CONFLICT (tenant_id, prospect_id, provider_name, external_member_id) DO NOTHING
  RETURNING id INTO v_handoff_id;

  RETURN v_handoff_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.link_prospect_to_member_profile(
  p_tenant_id uuid,
  p_prospect_id uuid,
  p_provider_name text,
  p_external_member_id text,
  p_external_profile_id text,
  p_claim_state text DEFAULT 'claimed',
  p_match_confidence numeric(4,3) DEFAULT 0,
  p_normalized_email text DEFAULT NULL,
  p_normalized_phone text DEFAULT NULL,
  p_source_handle text DEFAULT NULL
) RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
  v_link_id uuid;
BEGIN
  INSERT INTO public.member_profile_links (
    tenant_id, prospect_id, provider_name, external_member_id, external_profile_id,
    claim_state, match_confidence, normalized_email, normalized_phone, source_handle
  ) VALUES (
    p_tenant_id, p_prospect_id, p_provider_name, p_external_member_id, p_external_profile_id,
    p_claim_state, p_match_confidence, p_normalized_email, p_normalized_phone, p_source_handle
  ) ON CONFLICT (tenant_id, prospect_id, provider_name, external_member_id) DO NOTHING
  RETURNING id INTO v_link_id;

  RETURN v_link_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.find_registration_duplicate_candidates(
  p_tenant_id uuid,
  p_prospect_id uuid DEFAULT NULL,
  p_normalized_email text DEFAULT NULL,
  p_normalized_phone text DEFAULT NULL,
  p_external_member_id text DEFAULT NULL,
  p_claimed_profile_id text DEFAULT NULL,
  p_source_handle text DEFAULT NULL
) RETURNS TABLE (
  candidate_id uuid,
  candidate_type text,
  provider_name text,
  prospect_id uuid,
  external_member_id text,
  normalized_email text,
  normalized_phone text,
  source_handle text,
  status text,
  confidence_score numeric,
  evidence jsonb
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    m.id,
    'prospect_match'::text,
    m.provider_name,
    m.prospect_id,
    m.external_member_id,
    m.normalized_email,
    m.normalized_phone,
    m.source_handle,
    m.link_status,
    m.match_confidence,
    m.metadata
  FROM public.member_profile_links m
  WHERE m.tenant_id = p_tenant_id
    AND (
      (p_prospect_id IS NOT NULL AND m.prospect_id = p_prospect_id)
      OR (p_normalized_email IS NOT NULL AND m.normalized_email = p_normalized_email)
      OR (p_normalized_phone IS NOT NULL AND m.normalized_phone = p_normalized_phone)
      OR (p_external_member_id IS NOT NULL AND m.external_member_id = p_external_member_id)
      OR (p_claimed_profile_id IS NOT NULL AND m.external_profile_id = p_claimed_profile_id)
      OR (p_source_handle IS NOT NULL AND m.source_handle = p_source_handle)
    )
  UNION ALL
  SELECT
    r.id,
    'duplicate_review'::text,
    'brilliant_directories'::text,
    r.prospect_id,
    r.external_member_id,
    NULL::text,
    NULL::text,
    NULL::text,
    r.status,
    0.0::numeric,
    r.evidence
  FROM public.registration_match_candidates r
  WHERE r.tenant_id = p_tenant_id
    AND r.status IN ('pending', 'review_required');
END;
$$;

CREATE OR REPLACE FUNCTION public.record_registration_journey_event(
  p_tenant_id uuid,
  p_prospect_id uuid,
  p_event_source text,
  p_stage text,
  p_invitation_id uuid DEFAULT NULL,
  p_profile_link_id uuid DEFAULT NULL,
  p_related_thread_id uuid DEFAULT NULL,
  p_related_message_id uuid DEFAULT NULL,
  p_actor text DEFAULT NULL,
  p_previous_stage text DEFAULT NULL,
  p_new_stage text DEFAULT NULL,
  p_metadata jsonb DEFAULT '{}'::jsonb
) RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
  v_event_id uuid;
BEGIN
  INSERT INTO public.registration_journey_events (
    tenant_id, prospect_id, invitation_id, profile_link_id, related_thread_id,
    related_message_id, event_source, actor, stage, previous_stage, new_stage, metadata
  ) VALUES (
    p_tenant_id, p_prospect_id, p_invitation_id, p_profile_link_id, p_related_thread_id,
    p_related_message_id, p_event_source, p_actor, p_stage, p_previous_stage, p_new_stage, p_metadata
  ) RETURNING id INTO v_event_id;

  RETURN v_event_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.advance_registration_stage(
  p_tenant_id uuid,
  p_prospect_id uuid,
  p_stage text,
  p_previous_stage text DEFAULT NULL,
  p_new_stage text DEFAULT NULL,
  p_invitation_id uuid DEFAULT NULL,
  p_profile_link_id uuid DEFAULT NULL,
  p_event_source text DEFAULT 'system'
) RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO public.registration_journey_events (
    tenant_id, prospect_id, invitation_id, profile_link_id, event_source, stage, previous_stage, new_stage
  ) VALUES (
    p_tenant_id, p_prospect_id, p_invitation_id, p_profile_link_id, p_event_source, p_stage, p_previous_stage, COALESCE(p_new_stage, p_stage)
  );

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION public.ingest_brilliant_directories_sync_event(
  p_tenant_id uuid,
  p_prospect_id uuid,
  p_event_type text,
  p_invitation_id uuid DEFAULT NULL,
  p_profile_link_id uuid DEFAULT NULL,
  p_external_member_id text DEFAULT NULL,
  p_external_profile_id text DEFAULT NULL,
  p_provider_payload jsonb DEFAULT '{}'::jsonb,
  p_payload_hash text DEFAULT NULL
) RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
  v_event_id uuid;
BEGIN
  INSERT INTO public.brilliant_directories_sync_events (
    tenant_id, prospect_id, invitation_id, profile_link_id, external_member_id,
    external_profile_id, event_type, provider_payload, payload_hash
  ) VALUES (
    p_tenant_id, p_prospect_id, p_invitation_id, p_profile_link_id, p_external_member_id,
    p_external_profile_id, p_event_type, p_provider_payload, COALESCE(p_payload_hash, encode(digest(CAST(p_provider_payload AS text), 'sha256'), 'hex'))
  ) ON CONFLICT (tenant_id, provider_name, event_type, payload_hash) DO NOTHING
  RETURNING id INTO v_event_id;

  RETURN v_event_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_registration_journey(
  p_tenant_id uuid,
  p_prospect_id uuid,
  p_limit integer DEFAULT 100
) RETURNS TABLE (
  id uuid,
  event_source text,
  actor text,
  stage text,
  previous_stage text,
  new_stage text,
  occurred_at timestamptz,
  metadata jsonb
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT e.id, e.event_source, e.actor, e.stage, e.previous_stage, e.new_stage, e.occurred_at, e.metadata
  FROM public.registration_journey_events e
  WHERE e.tenant_id = p_tenant_id AND e.prospect_id = p_prospect_id
  ORDER BY e.occurred_at DESC
  LIMIT p_limit;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_registration_review_queue(
  p_tenant_id uuid,
  p_status text DEFAULT 'pending'
) RETURNS TABLE (
  id uuid,
  candidate_type text,
  provider_name text,
  prospect_id uuid,
  external_member_id text,
  normalized_email text,
  normalized_phone text,
  source_handle text,
  status text,
  confidence_score numeric,
  evidence jsonb
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.candidate_type,
    c.provider_name,
    c.prospect_id,
    c.external_member_id,
    c.normalized_email,
    c.normalized_phone,
    c.source_handle,
    c.status,
    c.confidence_score,
    c.evidence
  FROM public.registration_match_candidates c
  WHERE c.tenant_id = p_tenant_id AND c.status = p_status
  ORDER BY c.created_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.require_registration_invitation_approval()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.human_approval_granted IS NOT TRUE THEN
    RAISE EXCEPTION 'Human approval is required before this invitation can be sent.';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.prevent_registration_journey_append_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'Registration journey history is append-only and cannot be mutated.';
END;
$$;

DROP TRIGGER IF EXISTS registration_invitations_approval_gate ON public.registration_invitations;
CREATE TRIGGER registration_invitations_approval_gate
  BEFORE UPDATE OR INSERT ON public.registration_invitations
  FOR EACH ROW
  EXECUTE FUNCTION public.require_registration_invitation_approval();

DROP TRIGGER IF EXISTS registration_journey_events_append_only ON public.registration_journey_events;
CREATE TRIGGER registration_journey_events_append_only
  BEFORE UPDATE OR DELETE ON public.registration_journey_events
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_registration_journey_append_mutation();

COMMIT;
