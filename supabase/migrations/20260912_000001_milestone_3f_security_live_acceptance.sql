BEGIN;

CREATE TABLE IF NOT EXISTS public.export_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_type text NOT NULL CHECK (resource_type IN ('verification_cases', 'verification_batches', 'consent_preferences', 'verification_results', 'engagement_messages', 'ai_engagement_suggestions', 'registration_invitations', 'registration_handoffs')),
  export_scope text NOT NULL CHECK (export_scope IN ('verification', 'consent', 'engagement', 'registration', 'security', 'operational')),
  target_tenant_id uuid,
  requested_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied', 'expired', 'generated', 'downloaded', 'failed', 'cancelled')),
  file_name text,
  file_format text CHECK (file_format IN ('csv', 'xlsx', 'json', 'pdf')),
  row_count integer NOT NULL DEFAULT 0 CHECK (row_count >= 0),
  file_sha256 text,
  expires_at timestamptz,
  approved_at timestamptz,
  generated_at timestamptz,
  downloaded_at timestamptz,
  generated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  downloaded_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  request_reason text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.export_audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NOT NULL REFERENCES public.export_requests(id) ON DELETE CASCADE,
  event_type text NOT NULL CHECK (event_type IN ('generated', 'downloaded', 'denied', 'expired', 'rejected')),
  actor_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  event_scope text NOT NULL,
  resource_type text NOT NULL,
  file_name text,
  file_format text,
  row_count integer NOT NULL DEFAULT 0 CHECK (row_count >= 0),
  file_sha256 text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_export_requests_status
  ON public.export_requests (status, requested_by, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_export_requests_resource
  ON public.export_requests (resource_type, export_scope, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_export_audit_events_request
  ON public.export_audit_events (request_id, event_type, created_at DESC);

ALTER TABLE public.export_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.export_audit_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can create export requests when authorized" ON public.export_requests;
CREATE POLICY "Members can create export requests when authorized"
  ON public.export_requests
  FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND (
      public.current_user_is_platform_admin()
      OR public.user_has_permission('view_platform')
      OR public.user_has_permission('view_verification_modules')
      OR public.user_has_permission('view_operational_modules')
      OR public.user_has_permission('view_executive_reporting')
    )
    AND requested_by = auth.uid()
  );

DROP POLICY IF EXISTS "Authorized staff can read export requests" ON public.export_requests;
CREATE POLICY "Authorized staff can read export requests"
  ON public.export_requests
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND (
      requested_by = auth.uid()
      OR public.current_user_is_platform_admin()
      OR public.user_has_permission('view_platform')
      OR public.user_has_permission('view_verification_modules')
      OR public.user_has_permission('view_operational_modules')
      OR public.user_has_permission('view_executive_reporting')
    )
  );

DROP POLICY IF EXISTS "Authorized staff can update export requests" ON public.export_requests;
CREATE POLICY "Authorized staff can update export requests"
  ON public.export_requests
  FOR UPDATE
  USING (
    auth.uid() IS NOT NULL
    AND (
      requested_by = auth.uid()
      OR public.current_user_is_platform_admin()
      OR public.user_has_permission('view_platform')
      OR public.user_has_permission('view_verification_modules')
      OR public.user_has_permission('view_operational_modules')
      OR public.user_has_permission('view_executive_reporting')
    )
  )
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND (
      requested_by = auth.uid()
      OR public.current_user_is_platform_admin()
      OR public.user_has_permission('view_platform')
      OR public.user_has_permission('view_verification_modules')
      OR public.user_has_permission('view_operational_modules')
      OR public.user_has_permission('view_executive_reporting')
    )
  );

DROP POLICY IF EXISTS "Authorized staff can read export audit trail" ON public.export_audit_events;
CREATE POLICY "Authorized staff can read export audit trail"
  ON public.export_audit_events
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND (
      actor_user_id = auth.uid()
      OR public.current_user_is_platform_admin()
      OR public.user_has_permission('view_platform')
      OR public.user_has_permission('view_audit_events')
      OR public.user_has_permission('view_verification_modules')
      OR public.user_has_permission('view_operational_modules')
    )
  );

DROP POLICY IF EXISTS "Authorized staff can insert export audit trail" ON public.export_audit_events;
CREATE POLICY "Authorized staff can insert export audit trail"
  ON public.export_audit_events
  FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND actor_user_id = auth.uid()
    AND (
      public.current_user_is_platform_admin()
      OR public.user_has_permission('view_platform')
      OR public.user_has_permission('view_audit_events')
      OR public.user_has_permission('view_verification_modules')
      OR public.user_has_permission('view_operational_modules')
    )
  );

CREATE OR REPLACE FUNCTION public.assert_repository_export_authorization(
  p_resource_type text,
  p_export_scope text,
  p_target_tenant_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth, pg_catalog
AS $$
  SELECT auth.uid() IS NOT NULL
    AND (
      public.current_user_is_platform_admin()
      OR public.user_has_permission('view_platform')
      OR (
        p_export_scope = 'verification' AND public.user_has_permission('view_verification_modules')
      )
      OR (
        p_export_scope IN ('operational', 'engagement', 'registration') AND public.user_has_permission('view_operational_modules')
      )
      OR (
        p_export_scope = 'security' AND public.user_has_permission('view_audit_events')
      )
    )
    AND (
      p_target_tenant_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.verification_cases vc
        WHERE vc.id = p_target_tenant_id
           OR vc.case_id = p_target_tenant_id::text
      )
      OR EXISTS (
        SELECT 1
        FROM public.verification_batches vb
        WHERE vb.id = p_target_tenant_id
      )
      OR EXISTS (
        SELECT 1
        FROM public.consent_preferences cp
        WHERE cp.subject_id = p_target_tenant_id
      )
      OR EXISTS (
        SELECT 1
        FROM public.registration_invitations ri
        WHERE ri.id = p_target_tenant_id
      )
    );
$$;

CREATE OR REPLACE FUNCTION public.create_export_request(
  p_resource_type text,
  p_export_scope text,
  p_target_tenant_id uuid DEFAULT NULL,
  p_request_reason text DEFAULT NULL,
  p_expires_at timestamptz DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_catalog
AS $$
DECLARE
  v_actor uuid;
  v_request_id uuid;
BEGIN
  v_actor := auth.uid();
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'Anonymous export requests are denied. Authentication is required.';
  END IF;

  IF NOT public.assert_repository_export_authorization(p_resource_type, p_export_scope, p_target_tenant_id) THEN
    RAISE EXCEPTION 'Permission denied: current role cannot request this export for the requested scope.';
  END IF;

  INSERT INTO public.export_requests (
    resource_type,
    export_scope,
    target_tenant_id,
    requested_by,
    status,
    request_reason,
    expires_at,
    metadata
  ) VALUES (
    p_resource_type,
    p_export_scope,
    p_target_tenant_id,
    v_actor,
    'pending',
    p_request_reason,
    COALESCE(p_expires_at, now() + interval '24 hours'),
    jsonb_build_object('source', 'repository_workflow', 'actor_user_id', v_actor::text, 'resource_type', p_resource_type)
  ) RETURNING id INTO v_request_id;

  RETURN v_request_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_export_generation(
  p_request_id uuid,
  p_file_name text,
  p_file_format text,
  p_row_count integer DEFAULT 0,
  p_file_sha256 text DEFAULT NULL,
  p_status text DEFAULT 'generated'
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_catalog
AS $$
DECLARE
  v_actor uuid;
  v_request public.export_requests%ROWTYPE;
BEGIN
  v_actor := auth.uid();
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'Export generation requires an authenticated actor.';
  END IF;

  SELECT * INTO v_request
  FROM public.export_requests
  WHERE id = p_request_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Export request not found for generation audit.';
  END IF;

  IF v_request.expires_at IS NOT NULL AND now() > v_request.expires_at THEN
    RAISE EXCEPTION 'Expired export request cannot be generated.';
  END IF;

  IF NOT public.assert_repository_export_authorization(v_request.resource_type, v_request.export_scope, v_request.target_tenant_id) THEN
    RAISE EXCEPTION 'Role is not authorized to generate this export.';
  END IF;

  UPDATE public.export_requests
  SET file_name = p_file_name,
      file_format = p_file_format,
      row_count = p_row_count,
      file_sha256 = p_file_sha256,
      status = p_status,
      generated_by = v_actor,
      generated_at = now(),
      updated_at = now()
  WHERE id = p_request_id;

  INSERT INTO public.export_audit_events (
    request_id,
    event_type,
    actor_user_id,
    event_scope,
    resource_type,
    file_name,
    file_format,
    row_count,
    file_sha256,
    metadata
  ) VALUES (
    p_request_id,
    'generated',
    v_actor,
    COALESCE((SELECT export_scope FROM public.export_requests WHERE id = p_request_id), 'operational'),
    COALESCE((SELECT resource_type FROM public.export_requests WHERE id = p_request_id), 'verification_cases'),
    p_file_name,
    p_file_format,
    p_row_count,
    p_file_sha256,
    jsonb_build_object('generated_by', v_actor::text, 'status', p_status)
  );

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_export_download(
  p_request_id uuid,
  p_file_name text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_catalog
AS $$
DECLARE
  v_actor uuid;
  v_request public.export_requests%ROWTYPE;
BEGIN
  v_actor := auth.uid();
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'Download audit requires an authenticated user. The actor is derived from the active session only.';
  END IF;

  SELECT * INTO v_request
  FROM public.export_requests
  WHERE id = p_request_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Export request not found for download audit.';
  END IF;

  IF v_request.expires_at IS NOT NULL AND now() > v_request.expires_at THEN
    RAISE EXCEPTION 'Expired export request cannot be downloaded.';
  END IF;

  IF v_request.status NOT IN ('generated', 'downloaded') THEN
    RAISE EXCEPTION 'Only generated exports may be downloaded.';
  END IF;

  IF NOT (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_platform')
    OR public.user_has_permission('view_verification_modules')
    OR public.user_has_permission('view_operational_modules')
    OR public.user_has_permission('view_executive_reporting')
    OR v_request.requested_by = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Role is not authorized to record a download for this request.';
  END IF;

  UPDATE public.export_requests
  SET downloaded_by = v_actor,
      downloaded_at = now(),
      status = 'downloaded',
      updated_at = now(),
      file_name = COALESCE(p_file_name, file_name)
  WHERE id = p_request_id;

  INSERT INTO public.export_audit_events (
    request_id,
    event_type,
    actor_user_id,
    event_scope,
    resource_type,
    file_name,
    row_count,
    metadata
  ) VALUES (
    p_request_id,
    'downloaded',
    v_actor,
    v_request.export_scope,
    v_request.resource_type,
    COALESCE(p_file_name, v_request.file_name),
    COALESCE(v_request.row_count, 0),
    jsonb_build_object('downloaded_by', v_actor::text, 'request_status', 'downloaded')
  );

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_export_request_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_catalog
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS export_requests_set_updated_at ON public.export_requests;
CREATE TRIGGER export_requests_set_updated_at
BEFORE UPDATE ON public.export_requests
FOR EACH ROW EXECUTE FUNCTION public.set_export_request_updated_at();

REVOKE ALL ON FUNCTION public.assert_repository_export_authorization(text, text, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.assert_repository_export_authorization(text, text, uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.assert_repository_export_authorization(text, text, uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.create_export_request(text, text, uuid, text, timestamptz) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_export_request(text, text, uuid, text, timestamptz) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_export_request(text, text, uuid, text, timestamptz) TO authenticated;

REVOKE ALL ON FUNCTION public.record_export_generation(uuid, text, text, integer, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.record_export_generation(uuid, text, text, integer, text, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.record_export_generation(uuid, text, text, integer, text, text) TO authenticated;

REVOKE ALL ON FUNCTION public.record_export_download(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.record_export_download(uuid, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.record_export_download(uuid, text) TO authenticated;

REVOKE ALL ON FUNCTION public.set_export_request_updated_at() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.set_export_request_updated_at() FROM anon;
GRANT EXECUTE ON FUNCTION public.set_export_request_updated_at() TO authenticated;

COMMIT;
