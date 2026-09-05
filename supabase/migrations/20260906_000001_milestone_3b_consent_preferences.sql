BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.consent_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_type text NOT NULL CHECK (subject_type IN ('prospect', 'business', 'member', 'contact')),
  subject_id uuid NOT NULL,
  tenant_id uuid,
  channel text NOT NULL CHECK (channel IN ('email', 'phone', 'text', 'social_media')),
  purpose text NOT NULL CHECK (purpose IN ('general_communication', 'verification_share', 'service_updates', 'marketing', 'security_notice')),
  status text NOT NULL CHECK (status IN ('granted', 'denied', 'withdrawn', 'expired')),
  capture_source text NOT NULL DEFAULT 'manual',
  captured_at timestamptz NOT NULL DEFAULT now(),
  effective_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  withdrawn_at timestamptz,
  privacy_notice_version text NOT NULL DEFAULT 'v1',
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (subject_type, subject_id, channel, purpose)
);

CREATE INDEX IF NOT EXISTS idx_consent_preferences_subject
  ON public.consent_preferences (subject_type, subject_id, channel, purpose, status, effective_at);

CREATE INDEX IF NOT EXISTS idx_consent_preferences_expires_at
  ON public.consent_preferences (expires_at);

CREATE UNIQUE INDEX IF NOT EXISTS ux_consent_preferences_active
  ON public.consent_preferences (subject_type, subject_id, channel, purpose)
  WHERE status = 'granted'
    AND withdrawn_at IS NULL;

CREATE TABLE IF NOT EXISTS public.verification_sharing_consents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_type text NOT NULL CHECK (subject_type IN ('prospect', 'business', 'member', 'contact')),
  subject_id uuid NOT NULL,
  verification_case_id uuid REFERENCES public.verification_cases(id) ON DELETE SET NULL,
  selected_organization text NOT NULL,
  purpose text NOT NULL DEFAULT 'verification_share' CHECK (purpose IN ('verification_share', 'membership_verification')),
  status text NOT NULL CHECK (status IN ('granted', 'denied', 'withdrawn', 'expired')),
  capture_source text NOT NULL DEFAULT 'manual',
  captured_at timestamptz NOT NULL DEFAULT now(),
  effective_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  withdrawn_at timestamptz,
  privacy_notice_version text NOT NULL DEFAULT 'v1',
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (subject_type, subject_id, selected_organization)
);

CREATE INDEX IF NOT EXISTS idx_verification_sharing_subject
  ON public.verification_sharing_consents (subject_type, subject_id, selected_organization, status, effective_at);

CREATE TABLE IF NOT EXISTS public.consent_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_type text NOT NULL,
  subject_id uuid NOT NULL,
  channel text,
  purpose text,
  selected_organization text,
  previous_state text,
  new_state text,
  reason text,
  source text NOT NULL DEFAULT 'manual',
  actor_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  event_type text NOT NULL,
  correlation_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_consent_history_subject
  ON public.consent_history (subject_type, subject_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.retention_policies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category text NOT NULL CHECK (category IN ('active_consent', 'withdrawn_expired_consent', 'opt_out_suppression', 'verification_sharing', 'consent_history', 'deletion_requests')),
  retention_days integer NOT NULL DEFAULT 365,
  effective_from timestamptz NOT NULL DEFAULT now(),
  enabled boolean NOT NULL DEFAULT true,
  disposition text NOT NULL CHECK (disposition IN ('retain', 'delete', 'anonymize')),
  policy_version text NOT NULL DEFAULT 'v1',
  notes text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (category, policy_version)
);

CREATE TABLE IF NOT EXISTS public.deletion_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_type text NOT NULL,
  subject_id uuid NOT NULL,
  request_type text NOT NULL CHECK (request_type IN ('delete', 'anonymize')),
  status text NOT NULL CHECK (status IN ('requested', 'under_review', 'approved', 'rejected', 'completed', 'cancelled')),
  reason text NOT NULL,
  disposition text NOT NULL CHECK (disposition IN ('retain', 'delete', 'anonymize')),
  requested_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  processed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  hold_until timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE IF EXISTS public.opt_outs
  ADD COLUMN IF NOT EXISTS channel text CHECK (channel IN ('email', 'phone', 'text', 'social_media')),
  ADD COLUMN IF NOT EXISTS purpose text CHECK (purpose IN ('general_communication', 'verification_share', 'service_updates', 'marketing', 'security_notice')),
  ADD COLUMN IF NOT EXISTS is_global boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS suppression_reason text,
  ADD COLUMN IF NOT EXISTS suppression_source text DEFAULT 'manual',
  ADD COLUMN IF NOT EXISTS effective_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS reversed_at timestamptz,
  ADD COLUMN IF NOT EXISTS reversed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE IF EXISTS public.opt_outs ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.set_consent_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.prevent_consent_history_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  RAISE EXCEPTION 'Consent history is append-only and cannot be updated or deleted.';
END;
$$;

DROP TRIGGER IF EXISTS consent_preferences_set_updated_at ON public.consent_preferences;
CREATE TRIGGER consent_preferences_set_updated_at
BEFORE UPDATE ON public.consent_preferences
FOR EACH ROW EXECUTE FUNCTION public.set_consent_updated_at();

DROP TRIGGER IF EXISTS verification_sharing_consents_set_updated_at ON public.verification_sharing_consents;
CREATE TRIGGER verification_sharing_consents_set_updated_at
BEFORE UPDATE ON public.verification_sharing_consents
FOR EACH ROW EXECUTE FUNCTION public.set_consent_updated_at();

DROP TRIGGER IF EXISTS retention_policies_set_updated_at ON public.retention_policies;
CREATE TRIGGER retention_policies_set_updated_at
BEFORE UPDATE ON public.retention_policies
FOR EACH ROW EXECUTE FUNCTION public.set_consent_updated_at();

DROP TRIGGER IF EXISTS deletion_requests_set_updated_at ON public.deletion_requests;
CREATE TRIGGER deletion_requests_set_updated_at
BEFORE UPDATE ON public.deletion_requests
FOR EACH ROW EXECUTE FUNCTION public.set_consent_updated_at();

DROP TRIGGER IF EXISTS consent_history_block_update ON public.consent_history;
CREATE TRIGGER consent_history_block_update
BEFORE UPDATE ON public.consent_history
FOR EACH ROW EXECUTE FUNCTION public.prevent_consent_history_mutation();

DROP TRIGGER IF EXISTS consent_history_block_delete ON public.consent_history;
CREATE TRIGGER consent_history_block_delete
BEFORE DELETE ON public.consent_history
FOR EACH ROW EXECUTE FUNCTION public.prevent_consent_history_mutation();

CREATE OR REPLACE FUNCTION public.write_consent_history(
  p_subject_type text,
  p_subject_id uuid,
  p_event_type text,
  p_previous_state text,
  p_new_state text,
  p_channel text DEFAULT NULL,
  p_purpose text DEFAULT NULL,
  p_selected_organization text DEFAULT NULL,
  p_reason text DEFAULT NULL,
  p_source text DEFAULT 'manual',
  p_actor_user_id uuid DEFAULT NULL,
  p_correlation_id text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  INSERT INTO public.consent_history (
    subject_type,
    subject_id,
    event_type,
    previous_state,
    new_state,
    channel,
    purpose,
    selected_organization,
    reason,
    source,
    actor_user_id,
    correlation_id
  ) VALUES (
    p_subject_type,
    p_subject_id,
    p_event_type,
    p_previous_state,
    p_new_state,
    p_channel,
    p_purpose,
    p_selected_organization,
    p_reason,
    p_source,
    p_actor_user_id,
    p_correlation_id
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_effective_consent_preferences(p_subject_type text, p_subject_id uuid)
RETURNS TABLE (
  id uuid,
  subject_type text,
  subject_id uuid,
  tenant_id uuid,
  channel text,
  purpose text,
  status text,
  capture_source text,
  captured_at timestamptz,
  effective_at timestamptz,
  expires_at timestamptz,
  withdrawn_at timestamptz,
  privacy_notice_version text,
  created_by uuid,
  updated_by uuid,
  created_at timestamptz,
  updated_at timestamptz
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT cp.id, cp.subject_type, cp.subject_id, cp.tenant_id, cp.channel, cp.purpose, cp.status,
         cp.capture_source, cp.captured_at, cp.effective_at, cp.expires_at, cp.withdrawn_at,
         cp.privacy_notice_version, cp.created_by, cp.updated_by, cp.created_at, cp.updated_at
  FROM public.consent_preferences cp
  WHERE cp.subject_type = p_subject_type
    AND cp.subject_id = p_subject_id
    AND cp.status IN ('granted', 'denied', 'withdrawn', 'expired')
  ORDER BY cp.channel, cp.purpose, cp.updated_at DESC;
$$;

CREATE OR REPLACE FUNCTION public.evaluate_outreach_eligibility(
  p_subject_type text,
  p_subject_id uuid,
  p_channel text,
  p_purpose text,
  p_tenant_id uuid DEFAULT NULL
)
RETURNS TABLE (allowed boolean, reason text, channel text, purpose text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row record;
BEGIN
  IF p_channel NOT IN ('email','phone','text','social_media') THEN
    RETURN QUERY SELECT false, 'Unsupported communication channel.', p_channel, p_purpose;
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.opt_outs o
    WHERE o.is_active = true
      AND o.is_global = true
      AND o.entity_type = p_subject_type
      AND o.entity_id = p_subject_id
  ) THEN
    RETURN QUERY SELECT false, 'Global opt-out is active and prohibits outreach.', p_channel, p_purpose;
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.opt_outs o
    WHERE o.is_active = true
      AND o.entity_type = p_subject_type
      AND o.entity_id = p_subject_id
      AND o.channel = p_channel
  ) THEN
    RETURN QUERY SELECT false, 'Channel-specific opt-out is active.', p_channel, p_purpose;
    RETURN;
  END IF;

  SELECT cp.* INTO v_row
  FROM public.consent_preferences cp
  WHERE cp.subject_type = p_subject_type
    AND cp.subject_id = p_subject_id
    AND cp.channel = p_channel
    AND cp.purpose = p_purpose
    AND cp.status = 'granted'
    AND (cp.effective_at IS NULL OR cp.effective_at <= now())
    AND (cp.withdrawn_at IS NULL OR cp.withdrawn_at > now())
    AND (cp.expires_at IS NULL OR cp.expires_at > now())
  ORDER BY cp.updated_at DESC
  LIMIT 1;

  IF v_row IS NULL THEN
    RETURN QUERY SELECT false, 'No valid active consent exists for the requested channel and purpose.', p_channel, p_purpose;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Valid active consent exists and no suppression is active.', p_channel, p_purpose;
END;
$$;

CREATE OR REPLACE FUNCTION public.evaluate_verification_sharing_eligibility(
  p_subject_type text,
  p_subject_id uuid,
  p_selected_organization text,
  p_verification_case_id uuid DEFAULT NULL
)
RETURNS TABLE (allowed boolean, reason text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row record;
BEGIN
  IF NULLIF(trim(p_selected_organization), '') IS NULL THEN
    RETURN QUERY SELECT false, 'No selected organization is available for verification sharing.';
    RETURN;
  END IF;

  SELECT vsc.* INTO v_row
  FROM public.verification_sharing_consents vsc
  WHERE vsc.subject_type = p_subject_type
    AND vsc.subject_id = p_subject_id
    AND vsc.selected_organization = p_selected_organization
    AND vsc.status = 'granted'
    AND (vsc.effective_at IS NULL OR vsc.effective_at <= now())
    AND (vsc.withdrawn_at IS NULL OR vsc.withdrawn_at > now())
    AND (vsc.expires_at IS NULL OR vsc.expires_at > now())
  ORDER BY vsc.updated_at DESC
  LIMIT 1;

  IF v_row IS NULL THEN
    RETURN QUERY SELECT false, 'No active verification-sharing consent exists for the selected organization.';
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Verification-sharing consent is active for the selected organization.';
END;
$$;

CREATE OR REPLACE FUNCTION public.upsert_communication_consent(
  p_subject_type text,
  p_subject_id uuid,
  p_channel text,
  p_purpose text,
  p_status text DEFAULT 'granted',
  p_capture_source text DEFAULT 'manual',
  p_privacy_notice_version text DEFAULT 'v1',
  p_expires_at timestamptz DEFAULT NULL,
  p_created_by uuid DEFAULT NULL,
  p_updated_by uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF auth.uid() IS NULL AND p_created_by IS NULL THEN
    RAISE EXCEPTION 'Authentication is required to manage consent.';
  END IF;

  INSERT INTO public.consent_preferences (
    subject_type,
    subject_id,
    channel,
    purpose,
    status,
    capture_source,
    privacy_notice_version,
    expires_at,
    created_by,
    updated_by,
    effective_at,
    captured_at
  ) VALUES (
    p_subject_type,
    p_subject_id,
    p_channel,
    p_purpose,
    p_status,
    p_capture_source,
    p_privacy_notice_version,
    p_expires_at,
    COALESCE(p_created_by, auth.uid()),
    COALESCE(p_updated_by, auth.uid()),
    now(),
    now()
  )
  ON CONFLICT (subject_type, subject_id, channel, purpose)
  DO UPDATE SET
    status = EXCLUDED.status,
    capture_source = EXCLUDED.capture_source,
    privacy_notice_version = EXCLUDED.privacy_notice_version,
    expires_at = EXCLUDED.expires_at,
    effective_at = now(),
    updated_by = COALESCE(EXCLUDED.updated_by, auth.uid()),
    updated_at = now(),
    withdrawn_at = CASE WHEN EXCLUDED.status = 'withdrawn' THEN now() ELSE NULL END
  RETURNING id INTO v_id;

  PERFORM public.write_consent_history(
    p_subject_type,
    p_subject_id,
    'consent_updated',
    'previous',
    p_status,
    p_channel,
    p_purpose,
    NULL,
    'Consent record updated',
    p_capture_source,
    COALESCE(p_updated_by, auth.uid()),
    gen_random_uuid()::text
  );

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.withdraw_communication_consent(
  p_subject_type text,
  p_subject_id uuid,
  p_channel text,
  p_purpose text,
  p_reason text DEFAULT NULL,
  p_actor_user_id uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  UPDATE public.consent_preferences
  SET status = 'withdrawn',
      withdrawn_at = now(),
      updated_at = now(),
      updated_by = COALESCE(p_actor_user_id, auth.uid())
  WHERE subject_type = p_subject_type
    AND subject_id = p_subject_id
    AND channel = p_channel
    AND purpose = p_purpose;

  PERFORM public.write_consent_history(
    p_subject_type,
    p_subject_id,
    'consent_withdrawn',
    'granted',
    'withdrawn',
    p_channel,
    p_purpose,
    NULL,
    COALESCE(p_reason, 'Consent withdrawn by authorized actor.'),
    'manual',
    COALESCE(p_actor_user_id, auth.uid()),
    gen_random_uuid()::text
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.grant_verification_sharing_consent(
  p_subject_type text,
  p_subject_id uuid,
  p_selected_organization text,
  p_verification_case_id uuid DEFAULT NULL,
  p_purpose text DEFAULT 'verification_share',
  p_actor_user_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_id uuid;
BEGIN
  INSERT INTO public.verification_sharing_consents (
    subject_type,
    subject_id,
    selected_organization,
    verification_case_id,
    purpose,
    status,
    capture_source,
    privacy_notice_version,
    effective_at,
    captured_at,
    created_by,
    updated_by
  ) VALUES (
    p_subject_type,
    p_subject_id,
    p_selected_organization,
    p_verification_case_id,
    p_purpose,
    'granted',
    'manual',
    'v1',
    now(),
    now(),
    COALESCE(p_actor_user_id, auth.uid()),
    COALESCE(p_actor_user_id, auth.uid())
  )
  ON CONFLICT (subject_type, subject_id, selected_organization)
  DO UPDATE SET
    status = 'granted',
    verification_case_id = EXCLUDED.verification_case_id,
    purpose = EXCLUDED.purpose,
    effective_at = now(),
    withdrawn_at = NULL,
    updated_by = COALESCE(EXCLUDED.updated_by, auth.uid()),
    updated_at = now()
  RETURNING id INTO v_id;

  PERFORM public.write_consent_history(
    p_subject_type,
    p_subject_id,
    'organization_sharing_consent_granted',
    'none',
    'granted',
    NULL,
    p_purpose,
    p_selected_organization,
    'Organization-specific sharing consent granted.',
    'manual',
    COALESCE(p_actor_user_id, auth.uid()),
    gen_random_uuid()::text
  );

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.withdraw_verification_sharing_consent(
  p_subject_type text,
  p_subject_id uuid,
  p_selected_organization text,
  p_actor_user_id uuid DEFAULT NULL,
  p_reason text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  UPDATE public.verification_sharing_consents
  SET status = 'withdrawn',
      withdrawn_at = now(),
      updated_at = now(),
      updated_by = COALESCE(p_actor_user_id, auth.uid())
  WHERE subject_type = p_subject_type
    AND subject_id = p_subject_id
    AND selected_organization = p_selected_organization;

  PERFORM public.write_consent_history(
    p_subject_type,
    p_subject_id,
    'organization_sharing_consent_withdrawn',
    'granted',
    'withdrawn',
    NULL,
    'verification_share',
    p_selected_organization,
    COALESCE(p_reason, 'Verification-sharing consent withdrawn.'),
    'manual',
    COALESCE(p_actor_user_id, auth.uid()),
    gen_random_uuid()::text
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.record_opt_out(
  p_entity_type text,
  p_entity_id uuid,
  p_source text,
  p_reason text DEFAULT NULL,
  p_channel text DEFAULT NULL,
  p_actor_user_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_id uuid;
BEGIN
  INSERT INTO public.opt_outs (
    entity_type,
    entity_id,
    source,
    opt_out_reason,
    channel,
    purpose,
    is_global,
    suppression_reason,
    suppression_source,
    effective_at,
    is_active,
    created_by,
    updated_at
  ) VALUES (
    p_entity_type,
    p_entity_id,
    p_source,
    p_reason,
    p_channel,
    NULL,
    p_channel IS NULL,
    p_reason,
    COALESCE(p_source, 'manual'),
    now(),
    true,
    COALESCE(p_actor_user_id, auth.uid()),
    now()
  )
  RETURNING id INTO v_id;

  PERFORM public.write_consent_history(
    p_entity_type,
    p_entity_id,
    'opt_out_recorded',
    'active',
    'suppressed',
    p_channel,
    NULL,
    NULL,
    COALESCE(p_reason, 'Opt-out recorded.'),
    p_source,
    COALESCE(p_actor_user_id, auth.uid()),
    gen_random_uuid()::text
  );

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.reverse_opt_out(
  p_entity_type text,
  p_entity_id uuid,
  p_reason text,
  p_actor_user_id uuid DEFAULT NULL,
  p_authorized boolean DEFAULT false
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF p_authorized IS NOT TRUE THEN
    RAISE EXCEPTION 'Reversal requires authorized approval and a reason.';
  END IF;

  UPDATE public.opt_outs
  SET is_active = false,
      reversed_at = now(),
      reversed_by = COALESCE(p_actor_user_id, auth.uid()),
      updated_at = now()
  WHERE entity_type = p_entity_type
    AND entity_id = p_entity_id;

  PERFORM public.write_consent_history(
    p_entity_type,
    p_entity_id,
    'suppression_reversed',
    'suppressed',
    'active',
    NULL,
    NULL,
    NULL,
    p_reason,
    'manual',
    COALESCE(p_actor_user_id, auth.uid()),
    gen_random_uuid()::text
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.request_data_deletion(
  p_subject_type text,
  p_subject_id uuid,
  p_request_type text,
  p_reason text,
  p_requested_by uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_id uuid;
BEGIN
  INSERT INTO public.deletion_requests (
    subject_type,
    subject_id,
    request_type,
    status,
    reason,
    disposition,
    requested_by,
    created_at,
    updated_at
  ) VALUES (
    p_subject_type,
    p_subject_id,
    p_request_type,
    'requested',
    p_reason,
    CASE WHEN p_request_type = 'anonymize' THEN 'anonymize' ELSE 'delete' END,
    COALESCE(p_requested_by, auth.uid()),
    now(),
    now()
  ) RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.process_deletion_request(
  p_request_id uuid,
  p_status text,
  p_actor_user_id uuid DEFAULT NULL,
  p_reason text DEFAULT NULL,
  p_action text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  UPDATE public.deletion_requests
  SET status = p_status,
      reviewed_by = COALESCE(p_actor_user_id, auth.uid()),
      processed_by = COALESCE(p_actor_user_id, auth.uid()),
      reason = COALESCE(p_reason, reason),
      updated_at = now()
  WHERE id = p_request_id;

  PERFORM public.write_consent_history(
    'deletion_request',
    p_request_id,
    'retention_deletion_action',
    'request',
    p_status,
    NULL,
    NULL,
    NULL,
    COALESCE(p_action, p_status),
    'system',
    COALESCE(p_actor_user_id, auth.uid()),
    gen_random_uuid()::text
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_consent_history(p_subject_type text, p_subject_id uuid)
RETURNS TABLE (
  id uuid,
  subject_type text,
  subject_id uuid,
  channel text,
  purpose text,
  selected_organization text,
  previous_state text,
  new_state text,
  reason text,
  source text,
  actor_user_id uuid,
  event_type text,
  created_at timestamptz
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT ch.id, ch.subject_type, ch.subject_id, ch.channel, ch.purpose, ch.selected_organization,
         ch.previous_state, ch.new_state, ch.reason, ch.source, ch.actor_user_id, ch.event_type, ch.created_at
  FROM public.consent_history ch
  WHERE ch.subject_type = p_subject_type
    AND ch.subject_id = p_subject_id
  ORDER BY ch.created_at DESC;
$$;

CREATE OR REPLACE FUNCTION public.load_suppression_status(p_subject_type text, p_subject_id uuid)
RETURNS TABLE (
  kind text,
  channel text,
  is_active boolean,
  reason text,
  effective_at timestamptz,
  expires_at timestamptz
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT
    CASE WHEN is_global THEN 'global' ELSE 'channel' END,
    channel,
    is_active,
    COALESCE(suppression_reason, opt_out_reason),
    effective_at,
    expires_at
  FROM public.opt_outs
  WHERE entity_type = p_subject_type
    AND entity_id = p_subject_id;
$$;

ALTER TABLE public.consent_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_sharing_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consent_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.retention_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deletion_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can manage their consent" ON public.consent_preferences;
CREATE POLICY "Authenticated users can manage their consent" ON public.consent_preferences
  FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can manage verification sharing consent" ON public.verification_sharing_consents;
CREATE POLICY "Authenticated users can manage verification sharing consent" ON public.verification_sharing_consents
  FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authorized users can read consent history" ON public.consent_history;
CREATE POLICY "Authorized users can read consent history" ON public.consent_history
  FOR SELECT
  USING (auth.uid() IS NOT NULL AND (public.current_user_is_platform_admin() OR public.user_has_permission('view_platform') OR public.user_has_permission('view_operational_modules')));

DROP POLICY IF EXISTS "Platform admins manage retention policies" ON public.retention_policies;
CREATE POLICY "Platform admins manage retention policies" ON public.retention_policies
  FOR ALL
  USING (public.current_user_is_platform_admin())
  WITH CHECK (public.current_user_is_platform_admin());

DROP POLICY IF EXISTS "Platform admins manage deletion requests" ON public.deletion_requests;
CREATE POLICY "Platform admins manage deletion requests" ON public.deletion_requests
  FOR ALL
  USING (public.current_user_is_platform_admin() OR public.user_has_permission('manage_privacy'))
  WITH CHECK (public.current_user_is_platform_admin() OR public.user_has_permission('manage_privacy'));

DROP POLICY IF EXISTS "Authenticated users can read active opt-out suppression evidence" ON public.opt_outs;
CREATE POLICY "Authenticated users can read active opt-out suppression evidence" ON public.opt_outs
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can manage opt_outs" ON public.opt_outs;
CREATE POLICY "Authenticated users can manage opt_outs" ON public.opt_outs
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can update opt_outs" ON public.opt_outs;
CREATE POLICY "Authenticated users can update opt_outs" ON public.opt_outs
  FOR UPDATE
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.consent_preferences TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.verification_sharing_consents TO authenticated;
GRANT SELECT, INSERT ON TABLE public.consent_history TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.retention_policies TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.deletion_requests TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.opt_outs TO authenticated;

COMMIT;
