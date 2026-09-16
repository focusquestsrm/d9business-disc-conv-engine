BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.social_provider_connections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  organization_id uuid,
  provider text NOT NULL CHECK (provider IN ('meta')),
  connection_name text NOT NULL,
  connection_state text NOT NULL DEFAULT 'disconnected' CHECK (connection_state IN ('disconnected', 'configuration_required', 'connected', 'permission_limited', 'token_expiring', 'reconnect_required', 'suspended', 'provider_error')),
  provider_account_id text,
  provider_page_id text,
  channel_type text NOT NULL CHECK (channel_type IN ('facebook_page', 'instagram_business')),
  display_name text,
  last_successful_provider_check timestamptz,
  token_expires_at timestamptz,
  permissions jsonb NOT NULL DEFAULT '{}'::jsonb,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.social_provider_destinations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  organization_id uuid,
  connection_id uuid NOT NULL REFERENCES public.social_provider_connections(id) ON DELETE CASCADE,
  provider text NOT NULL CHECK (provider IN ('meta')),
  channel_type text NOT NULL CHECK (channel_type IN ('facebook_page', 'instagram_business')),
  destination_name text NOT NULL,
  destination_id text NOT NULL,
  destination_status text NOT NULL DEFAULT 'connected' CHECK (destination_status IN ('connected', 'disabled')),
  approved_for_publishing boolean NOT NULL DEFAULT false,
  capabilities jsonb NOT NULL DEFAULT '{}'::jsonb,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, connection_id, destination_id)
);

CREATE TABLE IF NOT EXISTS public.social_provider_capabilities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  organization_id uuid,
  connection_id uuid NOT NULL REFERENCES public.social_provider_connections(id) ON DELETE CASCADE,
  destination_id uuid REFERENCES public.social_provider_destinations(id) ON DELETE CASCADE,
  capability_name text NOT NULL CHECK (capability_name IN ('text', 'link', 'image', 'video')),
  enabled boolean NOT NULL DEFAULT true,
  max_length integer,
  media_types text[] NOT NULL DEFAULT ARRAY[]::text[],
  requires_approval boolean NOT NULL DEFAULT false,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (connection_id, destination_id, capability_name)
);

CREATE TABLE IF NOT EXISTS public.social_publishing_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  organization_id uuid,
  prospect_id uuid,
  connection_id uuid REFERENCES public.social_provider_connections(id) ON DELETE SET NULL,
  destination_id uuid REFERENCES public.social_provider_destinations(id) ON DELETE SET NULL,
  content_id uuid,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted_for_review', 'approved', 'scheduled', 'ready', 'publishing', 'published', 'partially_published', 'failed', 'cancelled')),
  actor_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  approval_state text NOT NULL DEFAULT 'pending' CHECK (approval_state IN ('pending', 'approved', 'rejected', 'edited')),
  content_hash text,
  content_version integer NOT NULL DEFAULT 1,
  scheduled_for timestamptz,
  provider_job_id text,
  provider_status text,
  provider_error_code text,
  retry_count integer NOT NULL DEFAULT 0 CHECK (retry_count >= 0),
  published_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.social_publishing_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  organization_id uuid,
  job_id uuid NOT NULL REFERENCES public.social_publishing_jobs(id) ON DELETE CASCADE,
  attempt_number integer NOT NULL CHECK (attempt_number >= 1),
  result text NOT NULL CHECK (result IN ('attempted', 'success', 'partial', 'failed', 'cancelled')),
  provider_response_code text,
  provider_response_payload jsonb,
  error_message text,
  actor_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.social_provider_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  organization_id uuid,
  connection_id uuid REFERENCES public.social_provider_connections(id) ON DELETE SET NULL,
  destination_id uuid REFERENCES public.social_provider_destinations(id) ON DELETE SET NULL,
  provider_event_id text NOT NULL,
  event_type text NOT NULL,
  status text NOT NULL DEFAULT 'received' CHECK (status IN ('received', 'processed', 'duplicate', 'review_required')),
  raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  normalized_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  matched_prospect_id uuid,
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, provider_event_id)
);

CREATE TABLE IF NOT EXISTS public.social_provider_health_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid,
  organization_id uuid,
  connection_id uuid NOT NULL REFERENCES public.social_provider_connections(id) ON DELETE CASCADE,
  provider_state text NOT NULL CHECK (provider_state IN ('disconnected', 'configuration_required', 'connected', 'permission_limited', 'token_expiring', 'reconnect_required', 'suspended', 'provider_error')),
  status_detail text,
  actor_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_social_provider_connections_org_state
  ON public.social_provider_connections (organization_id, connection_state, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_social_provider_destinations_org
  ON public.social_provider_destinations (organization_id, destination_status, channel_type);

CREATE INDEX IF NOT EXISTS idx_social_publishing_jobs_org_status
  ON public.social_publishing_jobs (organization_id, status, scheduled_for, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_social_provider_events_provider_event_id
  ON public.social_provider_events (tenant_id, provider_event_id);

CREATE INDEX IF NOT EXISTS idx_social_provider_health_events_connection
  ON public.social_provider_health_events (connection_id, created_at DESC);

ALTER TABLE public.social_provider_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_provider_destinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_provider_capabilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_publishing_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_publishing_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_provider_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_provider_health_events ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.current_user_can_manage_social_connections()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth, pg_catalog
AS $$
  SELECT auth.uid() IS NOT NULL
    AND (
      public.current_user_is_platform_admin()
      OR public.user_has_permission('view_platform')
      OR public.user_has_permission('view_content_modules')
      OR public.user_has_permission('manage_integrations')
    );
$$;

CREATE POLICY "Authenticated platform staff can read provider connections"
  ON public.social_provider_connections
  FOR SELECT
  USING (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated platform staff can manage provider connections"
  ON public.social_provider_connections
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated platform staff can update provider connections"
  ON public.social_provider_connections
  FOR UPDATE
  USING (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections())
  WITH CHECK (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated platform staff can read provider destinations"
  ON public.social_provider_destinations
  FOR SELECT
  USING (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated platform staff can manage provider destinations"
  ON public.social_provider_destinations
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated platform staff can update provider destinations"
  ON public.social_provider_destinations
  FOR UPDATE
  USING (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections())
  WITH CHECK (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated platform staff can read provider capabilities"
  ON public.social_provider_capabilities
  FOR SELECT
  USING (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated platform staff can manage provider capabilities"
  ON public.social_provider_capabilities
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated platform staff can update provider capabilities"
  ON public.social_provider_capabilities
  FOR UPDATE
  USING (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections())
  WITH CHECK (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated staff can read publishing jobs"
  ON public.social_publishing_jobs
  FOR SELECT
  USING (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated staff can insert publishing jobs"
  ON public.social_publishing_jobs
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated staff can update publishing jobs"
  ON public.social_publishing_jobs
  FOR UPDATE
  USING (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections())
  WITH CHECK (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated staff can read publishing attempts"
  ON public.social_publishing_attempts
  FOR SELECT
  USING (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated staff can insert publishing attempts"
  ON public.social_publishing_attempts
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated staff can read provider events"
  ON public.social_provider_events
  FOR SELECT
  USING (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated staff can insert provider events"
  ON public.social_provider_events
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated staff can update provider events"
  ON public.social_provider_events
  FOR UPDATE
  USING (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections())
  WITH CHECK (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated staff can read provider health events"
  ON public.social_provider_health_events
  FOR SELECT
  USING (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

CREATE POLICY "Authenticated staff can insert provider health events"
  ON public.social_provider_health_events
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND public.current_user_can_manage_social_connections());

COMMIT;
