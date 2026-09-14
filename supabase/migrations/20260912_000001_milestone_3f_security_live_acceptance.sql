BEGIN;

CREATE TABLE IF NOT EXISTS public.security_role_matrix (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  role_code text NOT NULL CHECK (role_code IN ('platform_admin', 'operations_admin', 'reviewer', 'operator', 'analyst', 'auditor', 'membership_owner')),
  module_code text NOT NULL CHECK (module_code IN ('security', 'verification', 'consent', 'campaigns', 'social', 'profile_handoff', 'exports')),
  permission_code text NOT NULL CHECK (permission_code IN ('read', 'write', 'approve', 'export', 'review', 'manage_security')),
  read_access boolean NOT NULL DEFAULT false,
  write_access boolean NOT NULL DEFAULT false,
  require_approval boolean NOT NULL DEFAULT false,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (role_code, module_code, permission_code)
);

CREATE TABLE IF NOT EXISTS public.export_audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  export_scope text NOT NULL,
  export_type text NOT NULL CHECK (export_type IN ('workbook', 'spreadsheet', 'report', 'json')),
  resource_type text NOT NULL,
  file_name text NOT NULL,
  file_format text NOT NULL CHECK (file_format IN ('xlsx', 'csv', 'json', 'pdf')),
  row_count integer NOT NULL DEFAULT 0 CHECK (row_count >= 0),
  file_sha256 text,
  generated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  downloaded_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  generated_at timestamptz NOT NULL DEFAULT now(),
  downloaded_at timestamptz,
  export_status text NOT NULL DEFAULT 'generated' CHECK (export_status IN ('generated', 'downloaded', 'rejected', 'failed')),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (downloaded_at IS NULL OR export_status IN ('downloaded', 'rejected', 'failed'))
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_security_role_matrix_permission
  ON public.security_role_matrix (role_code, module_code, permission_code);

CREATE INDEX IF NOT EXISTS idx_export_audit_events_actor
  ON public.export_audit_events (generated_by, downloaded_by, export_status, generated_at);

CREATE INDEX IF NOT EXISTS idx_export_audit_events_status
  ON public.export_audit_events (export_status, generated_at);

ALTER TABLE public.security_role_matrix ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.export_audit_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Platform admins can read security role matrix" ON public.security_role_matrix;
CREATE POLICY "Platform admins can read security role matrix"
  ON public.security_role_matrix
  FOR SELECT
  USING (public.current_user_is_platform_admin() OR public.user_has_permission('view_platform') OR public.user_has_permission('manage_security'));

DROP POLICY IF EXISTS "Platform admins can update security role matrix" ON public.security_role_matrix;
CREATE POLICY "Platform admins can update security role matrix"
  ON public.security_role_matrix
  FOR INSERT
  WITH CHECK (public.current_user_is_platform_admin() OR public.user_has_permission('manage_security'));

DROP POLICY IF EXISTS "Platform admins can modify security role matrix" ON public.security_role_matrix;
CREATE POLICY "Platform admins can modify security role matrix"
  ON public.security_role_matrix
  FOR UPDATE
  USING (public.current_user_is_platform_admin() OR public.user_has_permission('manage_security'))
  WITH CHECK (public.current_user_is_platform_admin() OR public.user_has_permission('manage_security'));

DROP POLICY IF EXISTS "Platform admins can read export audit events" ON public.export_audit_events;
CREATE POLICY "Platform admins can read export audit events"
  ON public.export_audit_events
  FOR SELECT
  USING (public.current_user_is_platform_admin() OR public.user_has_permission('view_platform') OR public.user_has_permission('manage_security'));

DROP POLICY IF EXISTS "Platform admins can record export audit events" ON public.export_audit_events;
CREATE POLICY "Platform admins can record export audit events"
  ON public.export_audit_events
  FOR INSERT
  WITH CHECK (public.current_user_is_platform_admin() OR public.user_has_permission('manage_security') OR public.user_has_permission('export'));

DROP POLICY IF EXISTS "Platform admins can update export audit events" ON public.export_audit_events;
CREATE POLICY "Platform admins can update export audit events"
  ON public.export_audit_events
  FOR UPDATE
  USING (public.current_user_is_platform_admin() OR public.user_has_permission('manage_security'))
  WITH CHECK (public.current_user_is_platform_admin() OR public.user_has_permission('manage_security'));

CREATE OR REPLACE FUNCTION public.assert_security_role_matrix(
  p_role_code text,
  p_permission_code text,
  p_operation text
)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.security_role_matrix s
    WHERE s.role_code = p_role_code
      AND s.permission_code = p_permission_code
      AND (
        (p_operation = 'read' AND s.read_access IS TRUE)
        OR (p_operation = 'write' AND s.write_access IS TRUE)
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.record_export_audit_event(
  p_export_scope text,
  p_export_type text,
  p_file_name text,
  p_file_format text,
  p_resource_type text,
  p_row_count integer,
  p_generated_by uuid,
  p_downloaded_by uuid DEFAULT NULL,
  p_export_status text DEFAULT 'generated',
  p_file_sha256 text DEFAULT NULL,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_catalog
AS $$
DECLARE
  v_event_id uuid;
BEGIN
  IF p_generated_by IS NULL THEN
    RAISE EXCEPTION 'Export generation requires an authenticated actor.';
  END IF;

  IF NOT (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_platform')
    OR public.user_has_permission('manage_security')
  ) THEN
    RAISE EXCEPTION 'Permission denied: export audit requires platform or security access.';
  END IF;

  INSERT INTO public.export_audit_events (
    export_scope,
    export_type,
    file_name,
    file_format,
    resource_type,
    row_count,
    file_sha256,
    generated_by,
    downloaded_by,
    export_status,
    metadata
  )
  VALUES (
    p_export_scope,
    p_export_type,
    p_file_name,
    p_file_format,
    p_resource_type,
    p_row_count,
    p_file_sha256,
    p_generated_by,
    p_downloaded_by,
    p_export_status,
    p_metadata
  )
  RETURNING id INTO v_event_id;

  RETURN v_event_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_export_download_event(
  p_event_id uuid,
  p_downloaded_by uuid,
  p_downloaded_at timestamptz DEFAULT now(),
  p_export_status text DEFAULT 'downloaded'
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_catalog
AS $$
BEGIN
  IF p_event_id IS NULL OR p_downloaded_by IS NULL THEN
    RAISE EXCEPTION 'Download audit requires a valid event and actor.';
  END IF;

  IF NOT (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_platform')
    OR public.user_has_permission('manage_security')
  ) THEN
    RAISE EXCEPTION 'Permission denied: export download auditing requires platform or security access.';
  END IF;

  UPDATE public.export_audit_events
  SET downloaded_by = p_downloaded_by,
      downloaded_at = p_downloaded_at,
      export_status = p_export_status,
      updated_at = now()
  WHERE id = p_event_id;

  RETURN FOUND;
END;
$$;

INSERT INTO public.security_role_matrix (role_code, module_code, permission_code, read_access, write_access, require_approval, notes)
VALUES
  ('platform_admin', 'security', 'manage_security', true, true, true, 'Platform administration retains the highest security-authority scope.'),
  ('platform_admin', 'exports', 'export', true, true, true, 'Platform administrators can export and audit export activity.'),
  ('operations_admin', 'exports', 'export', true, true, false, 'Operational administrators may export audits that remain within approved scope.'),
  ('reviewer', 'verification', 'review', true, true, false, 'Reviewers can review verification outcomes within approved queue scope.'),
  ('operator', 'campaigns', 'read', true, false, false, 'Operators receive read access to campaign and operational work queues.'),
  ('analyst', 'campaigns', 'read', true, false, false, 'Analysts are read-only for reporting and operational insight.'),
  ('auditor', 'security', 'read', true, false, false, 'Auditors can access log evidence without modification rights.'),
  ('membership_owner', 'consent', 'read', true, false, false, 'Membership owners can review consent state for their own records.')
ON CONFLICT (role_code, module_code, permission_code) DO UPDATE
  SET read_access = EXCLUDED.read_access,
      write_access = EXCLUDED.write_access,
      require_approval = EXCLUDED.require_approval,
      notes = EXCLUDED.notes,
      updated_at = now();

COMMIT;
