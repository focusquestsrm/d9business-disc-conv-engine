BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.engagement_connections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  organization_id uuid,
  platform text NOT NULL CHECK (platform IN ('instagram', 'facebook', 'linkedin', 'email')),
  connection_name text NOT NULL,
  external_account_id text,
  external_account_name text,
  external_handle text,
  connection_status text NOT NULL DEFAULT 'draft' CHECK (connection_status IN ('draft', 'pending', 'connected', 'restricted', 'disconnected', 'error')),
  authorization_status text NOT NULL DEFAULT 'pending' CHECK (authorization_status IN ('pending', 'approved', 'rejected', 'restricted', 'expired')),
  capabilities jsonb NOT NULL DEFAULT '{}'::jsonb,
  restrictions jsonb NOT NULL DEFAULT '{}'::jsonb,
  connected_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  connected_at timestamptz,
  last_validated_at timestamptz,
  last_sync_at timestamptz,
  disconnected_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.engagement_threads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  connection_id uuid REFERENCES public.engagement_connections(id) ON DELETE CASCADE,
  platform text NOT NULL CHECK (platform IN ('instagram', 'facebook', 'linkedin', 'email')),
  external_thread_id text,
  source_handle text,
  source_display_name text,
  source_profile_url text,
  prospect_id uuid,
  matching_status text NOT NULL DEFAULT 'unmatched' CHECK (matching_status IN ('matched', 'unmatched', 'needs_review', 'rejected')),
  matching_method text,
  matching_confidence numeric(4,3) DEFAULT 0,
  last_message_at timestamptz,
  unread_count integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'archived', 'closed', 'pending')),
  assigned_to uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.engagement_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  connection_id uuid REFERENCES public.engagement_connections(id) ON DELETE CASCADE,
  thread_id uuid REFERENCES public.engagement_threads(id) ON DELETE CASCADE,
  prospect_id uuid,
  direction text NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  platform text NOT NULL CHECK (platform IN ('instagram', 'facebook', 'linkedin', 'email')),
  external_message_id text,
  external_thread_id text,
  original_source text,
  original_handle text,
  original_url text,
  sender_external_id text,
  sender_display_name text,
  recipient_external_id text,
  message_type text NOT NULL DEFAULT 'text',
  message_text text,
  provider_created_at timestamptz,
  received_at timestamptz NOT NULL DEFAULT now(),
  delivery_status text NOT NULL DEFAULT 'received' CHECK (delivery_status IN ('received', 'sent', 'delivered', 'failed', 'read')),
  raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.engagement_match_candidates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  thread_id uuid REFERENCES public.engagement_threads(id) ON DELETE CASCADE,
  message_id uuid REFERENCES public.engagement_messages(id) ON DELETE CASCADE,
  prospect_id uuid,
  matching_method text NOT NULL,
  confidence_score numeric(4,3) NOT NULL DEFAULT 0,
  evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'rejected')),
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  rejection_reason text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.engagement_ingestion_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  connection_id uuid REFERENCES public.engagement_connections(id) ON DELETE CASCADE,
  platform text NOT NULL CHECK (platform IN ('instagram', 'facebook', 'linkedin', 'email')),
  external_event_id text,
  event_type text NOT NULL,
  payload_hash text NOT NULL,
  processing_status text NOT NULL DEFAULT 'received' CHECK (processing_status IN ('received', 'processed', 'duplicate', 'failed')),
  received_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  error_message text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS public.engagement_work_queue_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  thread_id uuid REFERENCES public.engagement_threads(id) ON DELETE CASCADE,
  message_id uuid REFERENCES public.engagement_messages(id) ON DELETE CASCADE,
  prospect_id uuid,
  assigned_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  queue_reason text NOT NULL CHECK (queue_reason IN ('inbound_response', 'identity_match_review', 'consent_review', 'connection_error', 'manual_follow_up')),
  priority text NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  status text NOT NULL DEFAULT 'unassigned' CHECK (status IN ('unassigned', 'assigned', 'in_progress', 'waiting', 'completed', 'canceled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  source_platform text,
  details jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_engagement_connections_account
  ON public.engagement_connections (tenant_id, platform, external_account_id)
  WHERE external_account_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_engagement_threads_provider
  ON public.engagement_threads (tenant_id, connection_id, external_thread_id)
  WHERE external_thread_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_engagement_messages_provider
  ON public.engagement_messages (tenant_id, connection_id, external_message_id)
  WHERE external_message_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_engagement_ingestion_event_idempotency
  ON public.engagement_ingestion_events (tenant_id, connection_id, platform, external_event_id)
  WHERE external_event_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_engagement_queue_active_reason
  ON public.engagement_work_queue_items (thread_id, message_id, queue_reason)
  WHERE status IN ('unassigned', 'assigned', 'in_progress', 'waiting');

ALTER TABLE public.engagement_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.engagement_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.engagement_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.engagement_match_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.engagement_ingestion_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.engagement_work_queue_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read engagement connections" ON public.engagement_connections;
CREATE POLICY "Authenticated users can read engagement connections"
  ON public.engagement_connections
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can insert engagement connections"
  ON public.engagement_connections
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update engagement connections"
  ON public.engagement_connections
  FOR UPDATE
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete engagement connections"
  ON public.engagement_connections
  FOR DELETE
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can read engagement threads" ON public.engagement_threads;
CREATE POLICY "Authenticated users can read engagement threads"
  ON public.engagement_threads
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can insert engagement threads"
  ON public.engagement_threads
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update engagement threads"
  ON public.engagement_threads
  FOR UPDATE
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete engagement threads"
  ON public.engagement_threads
  FOR DELETE
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can read engagement messages" ON public.engagement_messages;
CREATE POLICY "Authenticated users can read engagement messages"
  ON public.engagement_messages
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can insert engagement messages"
  ON public.engagement_messages
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update engagement messages"
  ON public.engagement_messages
  FOR UPDATE
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete engagement messages"
  ON public.engagement_messages
  FOR DELETE
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can read engagement match candidates" ON public.engagement_match_candidates;
CREATE POLICY "Authenticated users can read engagement match candidates"
  ON public.engagement_match_candidates
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can insert engagement match candidates"
  ON public.engagement_match_candidates
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update engagement match candidates"
  ON public.engagement_match_candidates
  FOR UPDATE
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete engagement match candidates"
  ON public.engagement_match_candidates
  FOR DELETE
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can read ingestion events" ON public.engagement_ingestion_events;
CREATE POLICY "Authenticated users can read ingestion events"
  ON public.engagement_ingestion_events
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can insert ingestion events"
  ON public.engagement_ingestion_events
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update ingestion events"
  ON public.engagement_ingestion_events
  FOR UPDATE
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete ingestion events"
  ON public.engagement_ingestion_events
  FOR DELETE
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can read engagement queue items" ON public.engagement_work_queue_items;
CREATE POLICY "Authenticated users can read engagement queue items"
  ON public.engagement_work_queue_items
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can insert engagement queue items"
  ON public.engagement_work_queue_items
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update engagement queue items"
  ON public.engagement_work_queue_items
  FOR UPDATE
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete engagement queue items"
  ON public.engagement_work_queue_items
  FOR DELETE
  USING (auth.uid() IS NOT NULL);

CREATE OR REPLACE FUNCTION public.set_engagement_updated_at()
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

DROP TRIGGER IF EXISTS engagement_connections_set_updated_at ON public.engagement_connections;
CREATE TRIGGER engagement_connections_set_updated_at
BEFORE UPDATE ON public.engagement_connections
FOR EACH ROW EXECUTE FUNCTION public.set_engagement_updated_at();

DROP TRIGGER IF EXISTS engagement_threads_set_updated_at ON public.engagement_threads;
CREATE TRIGGER engagement_threads_set_updated_at
BEFORE UPDATE ON public.engagement_threads
FOR EACH ROW EXECUTE FUNCTION public.set_engagement_updated_at();

DROP TRIGGER IF EXISTS engagement_work_queue_items_set_updated_at ON public.engagement_work_queue_items;
CREATE TRIGGER engagement_work_queue_items_set_updated_at
BEFORE UPDATE ON public.engagement_work_queue_items
FOR EACH ROW EXECUTE FUNCTION public.set_engagement_updated_at();

CREATE OR REPLACE FUNCTION public.create_engagement_connection(
  p_tenant_id uuid,
  p_organization_id uuid,
  p_platform text,
  p_connection_name text,
  p_external_account_id text DEFAULT NULL,
  p_external_account_name text DEFAULT NULL,
  p_external_handle text DEFAULT NULL,
  p_connection_status text DEFAULT 'draft',
  p_authorization_status text DEFAULT 'pending',
  p_capabilities jsonb DEFAULT '{}'::jsonb,
  p_restrictions jsonb DEFAULT '{}'::jsonb,
  p_connected_by uuid DEFAULT NULL,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS public.engagement_connections
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_connections;
BEGIN
  INSERT INTO public.engagement_connections (
    tenant_id, organization_id, platform, connection_name, external_account_id,
    external_account_name, external_handle, connection_status, authorization_status,
    capabilities, restrictions, connected_by, metadata, created_at, updated_at
  ) VALUES (
    p_tenant_id, p_organization_id, p_platform, p_connection_name, p_external_account_id,
    p_external_account_name, p_external_handle, p_connection_status, p_authorization_status,
    p_capabilities, p_restrictions, p_connected_by, p_metadata, NOW(), NOW()
  ) RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_engagement_connection_status(
  p_id uuid,
  p_connection_status text,
  p_authorization_status text DEFAULT NULL,
  p_reason text DEFAULT NULL
)
RETURNS public.engagement_connections
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_connections;
BEGIN
  UPDATE public.engagement_connections
  SET connection_status = p_connection_status,
      authorization_status = COALESCE(p_authorization_status, authorization_status),
      metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object('last_status_update_reason', p_reason),
      updated_at = NOW()
  WHERE id = p_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.validate_engagement_connection(p_id uuid, p_notes text DEFAULT NULL)
RETURNS public.engagement_connections
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_connections;
BEGIN
  UPDATE public.engagement_connections
  SET last_validated_at = NOW(),
      metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object('validation_notes', p_notes),
      updated_at = NOW()
  WHERE id = p_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.disconnect_engagement_connection(p_id uuid, p_reason text DEFAULT NULL)
RETURNS public.engagement_connections
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_connections;
BEGIN
  UPDATE public.engagement_connections
  SET connection_status = 'disconnected',
      disconnected_at = NOW(),
      metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object('disconnect_reason', p_reason),
      updated_at = NOW()
  WHERE id = p_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.ingest_engagement_event(
  p_tenant_id uuid,
  p_connection_id uuid,
  p_platform text,
  p_external_event_id text,
  p_event_type text,
  p_payload jsonb DEFAULT '{}'::jsonb,
  p_received_at timestamptz DEFAULT NOW()
)
RETURNS public.engagement_ingestion_events
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_ingestion_events;
BEGIN
  INSERT INTO public.engagement_ingestion_events (
    tenant_id, connection_id, platform, external_event_id, event_type,
    payload_hash, processing_status, received_at, metadata
  ) VALUES (
    p_tenant_id, p_connection_id, p_platform, p_external_event_id, p_event_type,
    md5(COALESCE(p_payload::text, '{}')), 'received', p_received_at, jsonb_build_object('source_payload', COALESCE(p_payload, '{}'::jsonb))
  )
  ON CONFLICT (tenant_id, connection_id, platform, external_event_id)
  WHERE external_event_id IS NOT NULL
  DO NOTHING
  RETURNING * INTO v_row;

  IF v_row.id IS NULL THEN
    SELECT * INTO v_row
    FROM public.engagement_ingestion_events
    WHERE tenant_id = p_tenant_id
      AND connection_id = p_connection_id
      AND platform = p_platform
      AND external_event_id = p_external_event_id
    ORDER BY received_at DESC
    LIMIT 1;
  END IF;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.ingest_engagement_message(
  p_tenant_id uuid,
  p_connection_id uuid,
  p_thread_id uuid,
  p_direction text,
  p_platform text,
  p_external_message_id text,
  p_prospect_id uuid DEFAULT NULL,
  p_external_thread_id text DEFAULT NULL,
  p_original_source text DEFAULT NULL,
  p_original_handle text DEFAULT NULL,
  p_original_url text DEFAULT NULL,
  p_sender_external_id text DEFAULT NULL,
  p_sender_display_name text DEFAULT NULL,
  p_recipient_external_id text DEFAULT NULL,
  p_message_type text DEFAULT 'text',
  p_message_text text DEFAULT NULL,
  p_provider_created_at timestamptz DEFAULT NOW(),
  p_received_at timestamptz DEFAULT NOW(),
  p_delivery_status text DEFAULT 'received',
  p_raw_payload jsonb DEFAULT '{}'::jsonb,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS public.engagement_messages
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_messages;
BEGIN
  INSERT INTO public.engagement_messages (
    tenant_id, connection_id, thread_id, prospect_id, direction, platform,
    external_message_id, external_thread_id, original_source, original_handle,
    original_url, sender_external_id, sender_display_name, recipient_external_id,
    message_type, message_text, provider_created_at, received_at, delivery_status,
    raw_payload, metadata, created_at
  ) VALUES (
    p_tenant_id, p_connection_id, p_thread_id, p_prospect_id, p_direction, p_platform,
    p_external_message_id, p_external_thread_id, p_original_source, p_original_handle,
    p_original_url, p_sender_external_id, p_sender_display_name, p_recipient_external_id,
    p_message_type, p_message_text, p_provider_created_at, p_received_at, p_delivery_status,
    p_raw_payload, p_metadata, NOW()
  ) ON CONFLICT (tenant_id, connection_id, external_message_id)
  WHERE external_message_id IS NOT NULL
  DO NOTHING
  RETURNING * INTO v_row;

  IF v_row.id IS NULL THEN
    SELECT * INTO v_row
    FROM public.engagement_messages
    WHERE tenant_id = p_tenant_id
      AND connection_id = p_connection_id
      AND external_message_id = p_external_message_id
    ORDER BY created_at DESC
    LIMIT 1;
  END IF;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.match_engagement_thread_to_prospect(
  p_thread_id uuid,
  p_prospect_id uuid,
  p_matching_method text DEFAULT 'manual',
  p_matching_confidence numeric DEFAULT 0.95
)
RETURNS public.engagement_threads
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_threads;
BEGIN
  UPDATE public.engagement_threads
  SET prospect_id = p_prospect_id,
      matching_status = 'matched',
      matching_method = p_matching_method,
      matching_confidence = p_matching_confidence,
      metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object('last_match_confidence', p_matching_confidence),
      updated_at = NOW()
  WHERE id = p_thread_id
  RETURNING * INTO v_row;

  INSERT INTO public.engagement_match_candidates (
    tenant_id, thread_id, prospect_id, matching_method, confidence_score, evidence, status, created_at
  )
  SELECT tenant_id, id, p_prospect_id, p_matching_method, p_matching_confidence, jsonb_build_object('source', 'auto_match'), 'confirmed', NOW()
  FROM public.engagement_threads
  WHERE id = p_thread_id
  ON CONFLICT DO NOTHING;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.review_engagement_match_candidate(
  p_candidate_id uuid,
  p_status text,
  p_reviewed_by uuid DEFAULT NULL,
  p_rejection_reason text DEFAULT NULL
)
RETURNS public.engagement_match_candidates
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_match_candidates;
BEGIN
  UPDATE public.engagement_match_candidates
  SET status = p_status,
      reviewed_by = p_reviewed_by,
      reviewed_at = NOW(),
      rejection_reason = p_rejection_reason,
      evidence = COALESCE(evidence, '{}'::jsonb) || jsonb_build_object('review_decision', p_status)
  WHERE id = p_candidate_id
  RETURNING * INTO v_row;

  IF v_row.thread_id IS NOT NULL AND p_status = 'confirmed' THEN
    UPDATE public.engagement_threads
    SET prospect_id = v_row.prospect_id,
        matching_status = 'matched',
        matching_confidence = v_row.confidence_score,
        updated_at = NOW()
    WHERE id = v_row.thread_id;
  ELSIF v_row.thread_id IS NOT NULL AND p_status = 'rejected' THEN
    UPDATE public.engagement_threads
    SET matching_status = 'rejected',
        updated_at = NOW()
    WHERE id = v_row.thread_id;
  END IF;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_unified_social_inbox(p_tenant_id uuid DEFAULT NULL)
RETURNS TABLE (
  id uuid,
  connection_name text,
  platform text,
  source_handle text,
  prospect_name text,
  preview text,
  last_message_at timestamptz,
  unread_state boolean,
  assignee uuid,
  queue_status text,
  match_state text,
  connection_status text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT t.id,
         c.connection_name,
         t.platform,
         t.source_handle,
         COALESCE(p.business_name, p.display_name) AS prospect_name,
         m.message_text AS preview,
         t.last_message_at,
         (t.unread_count > 0) AS unread_state,
         t.assigned_to AS assignee,
         COALESCE(wq.status, 'unassigned') AS queue_status,
         t.matching_status AS match_state,
         c.connection_status
  FROM public.engagement_threads t
  LEFT JOIN public.engagement_connections c ON c.id = t.connection_id
  LEFT JOIN public.engagement_messages m ON m.thread_id = t.id
  LEFT JOIN public.engagement_work_queue_items wq ON wq.thread_id = t.id
  LEFT JOIN public.prospects p ON p.id = t.prospect_id
  WHERE (p_tenant_id IS NULL OR t.tenant_id = p_tenant_id)
  GROUP BY t.id, c.connection_name, t.platform, t.source_handle, p.business_name, p.display_name, m.message_text, t.last_message_at, t.unread_count, t.assigned_to, wq.status, t.matching_status, c.connection_status
  ORDER BY t.last_message_at DESC NULLS LAST;
$$;

CREATE OR REPLACE FUNCTION public.get_engagement_thread(p_thread_id uuid)
RETURNS public.engagement_threads
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT *
  FROM public.engagement_threads
  WHERE id = p_thread_id;
$$;

CREATE OR REPLACE FUNCTION public.mark_engagement_thread_read(p_thread_id uuid)
RETURNS public.engagement_threads
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_threads;
BEGIN
  UPDATE public.engagement_threads
  SET unread_count = 0,
      metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object('read_at', NOW()),
      updated_at = NOW()
  WHERE id = p_thread_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.assign_engagement_thread(p_thread_id uuid, p_assigned_to uuid)
RETURNS public.engagement_threads
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_threads;
BEGIN
  UPDATE public.engagement_threads
  SET assigned_to = p_assigned_to,
      metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object('assigned_at', NOW()),
      updated_at = NOW()
  WHERE id = p_thread_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.route_engagement_response_to_work_queue(
  p_thread_id uuid,
  p_message_id uuid,
  p_prospect_id uuid DEFAULT NULL,
  p_reason text DEFAULT 'inbound_response',
  p_priority text DEFAULT 'normal'
)
RETURNS public.engagement_work_queue_items
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_work_queue_items;
BEGIN
  INSERT INTO public.engagement_work_queue_items (
    tenant_id, thread_id, message_id, prospect_id, queue_reason, priority, status, source_platform, details, created_at, updated_at
  )
  SELECT t.tenant_id, t.id, p_message_id, p_prospect_id, p_reason, p_priority, 'unassigned', t.platform, jsonb_build_object('thread_id', t.id, 'message_id', p_message_id), NOW(), NOW()
  FROM public.engagement_threads t
  WHERE t.id = p_thread_id
  ON CONFLICT (thread_id, message_id, queue_reason)
  WHERE status IN ('unassigned', 'assigned', 'in_progress', 'waiting')
  DO NOTHING
  RETURNING * INTO v_row;

  IF v_row.id IS NULL THEN
    SELECT * INTO v_row
    FROM public.engagement_work_queue_items
    WHERE thread_id = p_thread_id
      AND message_id = p_message_id
      AND queue_reason = p_reason
    ORDER BY created_at DESC
    LIMIT 1;
  END IF;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_engagement_outbound_activity(
  p_connection_id uuid,
  p_thread_id uuid,
  p_platform text,
  p_prospect_id uuid DEFAULT NULL,
  p_channel text DEFAULT 'email',
  p_status text DEFAULT 'sent',
  p_reason text DEFAULT NULL
)
RETURNS public.engagement_messages
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_row public.engagement_messages;
  v_consent_result record;
BEGIN
  SELECT * INTO v_consent_result
  FROM public.evaluate_outreach_eligibility('prospect', COALESCE(p_prospect_id, '00000000-0000-0000-0000-000000000000'::uuid), p_channel, 'general_communication', NULL);

  IF v_consent_result.allowed = false THEN
    RAISE EXCEPTION 'Outbound activity blocked by consent or suppression: %', v_consent_result.reason;
  END IF;

  INSERT INTO public.engagement_messages (
    tenant_id, connection_id, thread_id, prospect_id, direction, platform,
    original_source, original_handle, message_type, message_text, received_at,
    delivery_status, raw_payload, metadata, created_at
  )
  SELECT c.tenant_id, c.id, p_thread_id, p_prospect_id, 'outbound', p_platform,
         c.platform, c.external_handle, 'text', COALESCE(p_reason, 'Outbound activity recorded'), NOW(),
         p_status, jsonb_build_object('channel', p_channel, 'reason', p_reason), jsonb_build_object('outbound_activity', true), NOW()
  FROM public.engagement_connections c
  WHERE c.id = p_connection_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_engagement_connection_health(p_connection_id uuid)
RETURNS TABLE (
  id uuid,
  connection_name text,
  platform text,
  connection_status text,
  authorization_status text,
  last_validated_at timestamptz,
  last_sync_at timestamptz,
  restrictions jsonb,
  capabilities jsonb,
  metadata jsonb
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT c.id, c.connection_name, c.platform, c.connection_status, c.authorization_status,
         c.last_validated_at, c.last_sync_at, c.restrictions, c.capabilities, c.metadata
  FROM public.engagement_connections c
  WHERE c.id = p_connection_id;
$$;

COMMIT;
