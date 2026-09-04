BEGIN;

CREATE OR REPLACE FUNCTION public.set_updated_at()
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

CREATE OR REPLACE FUNCTION public.tenant_allowed_read()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT auth.uid() IS NOT NULL
    AND (
      public.current_user_is_platform_admin()
      OR public.user_has_permission('view_platform')
      OR public.user_has_permission('view_operational_modules')
    );
$$;

CREATE OR REPLACE FUNCTION public.build_d9_match_candidate(
  record_type text,
  record_id uuid,
  target_text text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  normalized_text text;
BEGIN
  normalized_text := lower(regexp_replace(trim(COALESCE(target_text, '')), '[^a-z0-9]+', ' ', 'g'));
  normalized_text := regexp_replace(normalized_text, '\s+', ' ', 'g');

  RETURN jsonb_build_object(
    'entity_type', record_type,
    'entity_id', record_id,
    'match_reason', 'normalized_text_match',
    'confidence_level', CASE WHEN normalized_text = '' THEN 'no_match' ELSE 'possible' END,
    'normalized_text', normalized_text,
    'fields_matched', CASE WHEN normalized_text <> '' THEN jsonb_build_array('display_name') ELSE '[]'::jsonb END,
    'fields_conflicting', '[]'::jsonb,
    'recommended_action', 'manual_review'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.enforce_workflow_transition()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF OLD.d9_connection_status = 'opt_out' AND NEW.d9_connection_status <> 'opt_out' AND COALESCE(NEW.consent_status, 'unknown') <> 'allowed' THEN
      RAISE EXCEPTION 'Opted-out records require renewed consent before reactivation is allowed.';
    END IF;

    IF NEW.d9_connection_status = 'duplicate' THEN
      NEW.workflow_status = 'duplicate_review';
    ELSIF NEW.d9_connection_status = 'known_greek' THEN
      NEW.workflow_status = 'd9_connection_reported';
    ELSIF NEW.d9_connection_status = 'unknown' THEN
      NEW.workflow_status = 'outreach_needed';
    ELSIF NEW.d9_connection_status = 'opt_out' THEN
      NEW.workflow_status = 'opt_out_review';
    ELSIF NEW.d9_connection_status = 'community_business' THEN
      NEW.workflow_status = 'outreach_needed';
    ELSIF NEW.d9_connection_status = 'existing_member' THEN
      NEW.workflow_status = 'membership_match_review';
    END IF;

    IF OLD.d9_connection_status = 'duplicate' AND NEW.d9_connection_status = 'unknown' THEN
      RAISE EXCEPTION 'Duplicate records cannot be moved back to unknown without review.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_workflow_transition()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  actor_user_id uuid;
  entity_type_name text;
BEGIN
  IF TG_OP <> 'UPDATE' OR OLD.d9_connection_status IS NOT DISTINCT FROM NEW.d9_connection_status THEN
    RETURN NEW;
  END IF;

  actor_user_id := auth.uid();
  entity_type_name := COALESCE(TG_ARGV[0], TG_TABLE_NAME);

  INSERT INTO public.workflow_events (
    entity_type,
    entity_id,
    event_type,
    actor_user_id,
    details
  )
  VALUES (
    entity_type_name,
    NEW.id,
    'status_transition',
    actor_user_id,
    jsonb_build_object(
      'previous_status', OLD.d9_connection_status,
      'new_status', NEW.d9_connection_status,
      'workflow_status', NEW.workflow_status,
      'reason', 'status_changed',
      'entity_table', TG_TABLE_NAME
    )
  )
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$;

ALTER TABLE IF EXISTS public.discovery_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.business_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.prospects ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.nominations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.import_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.import_rows ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.workflow_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.workflow_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.possible_duplicates ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.opt_outs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.prospect_source_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.integration_statuses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read discovery sources" ON public.discovery_sources;
CREATE POLICY "Authenticated users can read discovery sources"
ON public.discovery_sources
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_platform')
    OR public.user_has_permission('view_operational_modules')
  )
);

DROP POLICY IF EXISTS "Authenticated staff can manage discovery sources" ON public.discovery_sources;
CREATE POLICY "Authenticated staff can manage discovery sources"
ON public.discovery_sources
FOR INSERT
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
);

DROP POLICY IF EXISTS "Discovery source updates are limited to authorized staff" ON public.discovery_sources;
CREATE POLICY "Discovery source updates are limited to authorized staff"
ON public.discovery_sources
FOR UPDATE
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
)
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
);

DROP POLICY IF EXISTS "Authenticated users can read businesses" ON public.businesses;
CREATE POLICY "Authenticated users can read businesses"
ON public.businesses
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_platform')
    OR public.user_has_permission('view_operational_modules')
    OR created_by = auth.uid()
  )
);

DROP POLICY IF EXISTS "Authenticated users can create businesses" ON public.businesses;
CREATE POLICY "Authenticated users can create businesses"
ON public.businesses
FOR INSERT
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
    OR created_by = auth.uid()
  )
);

DROP POLICY IF EXISTS "Business ownership and update access is constrained" ON public.businesses;
CREATE POLICY "Business ownership and update access is constrained"
ON public.businesses
FOR UPDATE
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR created_by = auth.uid()
  )
)
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR (created_by = auth.uid() AND created_by IS NOT DISTINCT FROM OLD.created_by)
  )
);

DROP POLICY IF EXISTS "Platform admins may manage business contacts" ON public.business_contacts;
CREATE POLICY "Platform admins may manage business contacts"
ON public.business_contacts
FOR ALL
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
)
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
);

DROP POLICY IF EXISTS "Authenticated users can read prospects" ON public.prospects;
CREATE POLICY "Authenticated users can read prospects"
ON public.prospects
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_platform')
    OR public.user_has_permission('view_operational_modules')
    OR created_by = auth.uid()
    OR assigned_staff_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Authenticated users can create permitted prospects" ON public.prospects;
CREATE POLICY "Authenticated users can create permitted prospects"
ON public.prospects
FOR INSERT
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
    OR created_by = auth.uid()
  )
);

DROP POLICY IF EXISTS "Prospect ownership and assignment are protected" ON public.prospects;
CREATE POLICY "Prospect ownership and assignment are protected"
ON public.prospects
FOR UPDATE
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR created_by = auth.uid()
    OR assigned_staff_id = auth.uid()
  )
)
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR (created_by = auth.uid() AND created_by IS NOT DISTINCT FROM OLD.created_by)
    OR (assigned_staff_id = auth.uid() AND assigned_staff_id IS NOT DISTINCT FROM OLD.assigned_staff_id)
  )
);

DROP POLICY IF EXISTS "Authenticated staff can read workflow assignments" ON public.workflow_assignments;
CREATE POLICY "Authenticated staff can read workflow assignments"
ON public.workflow_assignments
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_platform')
    OR public.user_has_permission('view_operational_modules')
    OR assigned_to = auth.uid()
    OR assigned_by = auth.uid()
  )
);

DROP POLICY IF EXISTS "Authenticated staff can create workflow assignments" ON public.workflow_assignments;
CREATE POLICY "Authenticated staff can create workflow assignments"
ON public.workflow_assignments
FOR INSERT
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
    OR assigned_by = auth.uid()
  )
);

DROP POLICY IF EXISTS "Workflow assignment ownership is protected" ON public.workflow_assignments;
CREATE POLICY "Workflow assignment ownership is protected"
ON public.workflow_assignments
FOR UPDATE
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR assigned_by = auth.uid()
    OR assigned_to = auth.uid()
  )
)
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR (assigned_by = auth.uid() AND assigned_by IS NOT DISTINCT FROM OLD.assigned_by)
    OR (assigned_to = auth.uid() AND assigned_to IS NOT DISTINCT FROM OLD.assigned_to)
  )
);

DROP POLICY IF EXISTS "Authenticated users can read workflow events" ON public.workflow_events;
CREATE POLICY "Authenticated users can read workflow events"
ON public.workflow_events
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_platform')
    OR public.user_has_permission('view_operational_modules')
    OR actor_user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Workflow event writes are restricted to authenticated actors" ON public.workflow_events;
CREATE POLICY "Workflow event writes are restricted to authenticated actors"
ON public.workflow_events
FOR INSERT
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR actor_user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Authenticated users can read duplicate candidates" ON public.possible_duplicates;
CREATE POLICY "Authenticated users can read duplicate candidates"
ON public.possible_duplicates
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
);

DROP POLICY IF EXISTS "Duplicate candidates are restricted to authorized reviewers" ON public.possible_duplicates;
CREATE POLICY "Duplicate candidates are restricted to authorized reviewers"
ON public.possible_duplicates
FOR INSERT
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
);

DROP POLICY IF EXISTS "Authenticated users can read opt outs" ON public.opt_outs;
CREATE POLICY "Authenticated users can read opt outs"
ON public.opt_outs
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
    OR created_by = auth.uid()
  )
);

DROP POLICY IF EXISTS "Opt out records require authorized writes" ON public.opt_outs;
CREATE POLICY "Opt out records require authorized writes"
ON public.opt_outs
FOR INSERT
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
    OR created_by = auth.uid()
  )
);

DROP POLICY IF EXISTS "Authenticated users can read prospect source events" ON public.prospect_source_events;
CREATE POLICY "Authenticated users can read prospect source events"
ON public.prospect_source_events
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
);

DROP POLICY IF EXISTS "Prospect source events are restricted to authorized staff" ON public.prospect_source_events;
CREATE POLICY "Prospect source events are restricted to authorized staff"
ON public.prospect_source_events
FOR INSERT
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
);

DROP POLICY IF EXISTS "Campaign read access is limited to operational staff" ON public.campaigns;
CREATE POLICY "Campaign read access is limited to operational staff"
ON public.campaigns
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
);

DROP POLICY IF EXISTS "Campaign writes require operational authorization" ON public.campaigns;
CREATE POLICY "Campaign writes require operational authorization"
ON public.campaigns
FOR ALL
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
)
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
);

DROP POLICY IF EXISTS "Nomination read access is limited to operational staff" ON public.nominations;
CREATE POLICY "Nomination read access is limited to operational staff"
ON public.nominations
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
);

DROP POLICY IF EXISTS "Nomination writes require operational authorization" ON public.nominations;
CREATE POLICY "Nomination writes require operational authorization"
ON public.nominations
FOR ALL
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
)
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
);

DROP POLICY IF EXISTS "Import job access requires authenticated operational roles" ON public.import_jobs;
CREATE POLICY "Import job access requires authenticated operational roles"
ON public.import_jobs
FOR ALL
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
    OR uploaded_by = auth.uid()
  )
)
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
    OR uploaded_by = auth.uid()
  )
);

DROP POLICY IF EXISTS "Import rows require authenticated operational access" ON public.import_rows;
CREATE POLICY "Import rows require authenticated operational access"
ON public.import_rows
FOR ALL
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
)
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_operational_modules')
  )
);

DROP POLICY IF EXISTS "Integration statuses require authenticated operational access" ON public.integration_statuses;
CREATE POLICY "Integration statuses require authenticated operational access"
ON public.integration_statuses
FOR ALL
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_platform')
  )
)
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_platform')
  )
);

COMMIT;
