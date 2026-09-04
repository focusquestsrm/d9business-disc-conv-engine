BEGIN;

CREATE TABLE IF NOT EXISTS public.verification_batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_code text NOT NULL UNIQUE,
  organization text NOT NULL,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'ready_for_export', 'exported', 'sent_to_organization', 'response_received', 'completed', 'closed')),
  submission_window_start timestamptz,
  submission_window_end timestamptz,
  notes text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.verification_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id text NOT NULL UNIQUE,
  batch_id uuid REFERENCES public.verification_batches(id) ON DELETE SET NULL,
  source_record_id uuid,
  claimant_name text NOT NULL,
  legal_first_name text,
  legal_last_name text,
  email text,
  phone text,
  claimed_organization text,
  chapter_name text,
  chapter_city text,
  chapter_state text,
  consent_acknowledged boolean NOT NULL DEFAULT false,
  consent_date date,
  status text NOT NULL DEFAULT 'not_requested' CHECK (status IN ('not_requested', 'information_incomplete', 'ready_for_batch', 'batched', 'exported', 'sent_to_organization', 'response_received', 'verified', 'unable_to_verify', 'rejected', 'needs_follow_up', 'expired')),
  result text NOT NULL DEFAULT 'PENDING' CHECK (result IN ('PENDING', 'VERIFIED', 'UNABLE_TO_VERIFY', 'REJECTED', 'NEEDS_FOLLOW_UP')),
  confidence_score integer CHECK (confidence_score BETWEEN 0 AND 100),
  verification_reason text,
  verified_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  verified_at timestamptz,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.verification_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  verification_case_id uuid NOT NULL REFERENCES public.verification_cases(id) ON DELETE CASCADE,
  organization_name text NOT NULL,
  organization_result text NOT NULL CHECK (organization_result IN ('VERIFIED', 'UNABLE_TO_VERIFY', 'REJECTED', 'NEEDS_FOLLOW_UP')),
  reason text,
  notes text,
  verification_date timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.verification_batch_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id uuid NOT NULL REFERENCES public.verification_batches(id) ON DELETE CASCADE,
  case_id uuid NOT NULL REFERENCES public.verification_cases(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'exported', 'returned', 'processed', 'rejected')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (batch_id, case_id)
);

CREATE TABLE IF NOT EXISTS public.verification_imports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id uuid REFERENCES public.verification_batches(id) ON DELETE SET NULL,
  organization text NOT NULL,
  source_file_name text,
  imported_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  imported_at timestamptz NOT NULL DEFAULT now(),
  total_rows integer NOT NULL DEFAULT 0,
  valid_rows integer NOT NULL DEFAULT 0,
  invalid_rows integer NOT NULL DEFAULT 0,
  already_processed_rows integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'previewed' CHECK (status IN ('previewed', 'committed', 'rejected')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.verification_import_rows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  verification_import_id uuid NOT NULL REFERENCES public.verification_imports(id) ON DELETE CASCADE,
  row_number integer NOT NULL,
  case_id text NOT NULL,
  source_record_id text,
  batch_id text,
  organization text,
  result text,
  reason text,
  notes text,
  raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (verification_import_id, row_number)
);

CREATE INDEX IF NOT EXISTS idx_verification_batches_status
  ON public.verification_batches (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_verification_cases_status
  ON public.verification_cases (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_verification_cases_batch
  ON public.verification_cases (batch_id, status);

CREATE INDEX IF NOT EXISTS idx_verification_cases_organization
  ON public.verification_cases (claimed_organization, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_verification_results_case
  ON public.verification_results (verification_case_id, verification_date DESC);

CREATE INDEX IF NOT EXISTS idx_verification_batch_items_batch
  ON public.verification_batch_items (batch_id, status);

CREATE INDEX IF NOT EXISTS idx_verification_imports_batch
  ON public.verification_imports (batch_id, imported_at DESC);

CREATE INDEX IF NOT EXISTS idx_verification_import_rows_import
  ON public.verification_import_rows (verification_import_id, row_number);

CREATE OR REPLACE FUNCTION public.set_verification_updated_at()
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

CREATE TRIGGER verification_batches_set_updated_at
BEFORE UPDATE ON public.verification_batches
FOR EACH ROW
EXECUTE FUNCTION public.set_verification_updated_at();

CREATE TRIGGER verification_cases_set_updated_at
BEFORE UPDATE ON public.verification_cases
FOR EACH ROW
EXECUTE FUNCTION public.set_verification_updated_at();

CREATE TRIGGER verification_results_set_updated_at
BEFORE UPDATE ON public.verification_results
FOR EACH ROW
EXECUTE FUNCTION public.set_verification_updated_at();

CREATE TRIGGER verification_batch_items_set_updated_at
BEFORE UPDATE ON public.verification_batch_items
FOR EACH ROW
EXECUTE FUNCTION public.set_verification_updated_at();

CREATE TRIGGER verification_imports_set_updated_at
BEFORE UPDATE ON public.verification_imports
FOR EACH ROW
EXECUTE FUNCTION public.set_verification_updated_at();

CREATE TRIGGER verification_import_rows_set_updated_at
BEFORE UPDATE ON public.verification_import_rows
FOR EACH ROW
EXECUTE FUNCTION public.set_verification_updated_at();

CREATE OR REPLACE FUNCTION public.commit_verification_import(
  p_import_id uuid,
  p_batch_id uuid,
  p_organization text,
  p_rows jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  row_payload jsonb;
  row_count integer := 0;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required to commit verification imports.';
  END IF;

  IF NOT (public.current_user_is_platform_admin() OR public.user_has_permission('view_verification_modules')) THEN
    RAISE EXCEPTION 'Permission denied: verification import commit requires authorized staff access.';
  END IF;

  IF p_rows IS NULL THEN
    p_rows := '[]'::jsonb;
  END IF;

  FOR row_payload IN SELECT * FROM jsonb_array_elements(p_rows)
  LOOP
    UPDATE public.verification_cases
    SET status = 'response_received',
        result = COALESCE(NULLIF(upper(row_payload->>'organizationResult'), ''), result),
        verification_reason = NULLIF(row_payload->>'organizationReason', ''),
        claimed_organization = COALESCE(NULLIF(trim(row_payload->>'claimedOrganization'), ''), claimed_organization),
        batch_id = COALESCE(p_batch_id, batch_id),
        updated_at = now()
    WHERE case_id = row_payload->>'verificationCaseId';

    row_count := row_count + 1;
  END LOOP;

  UPDATE public.verification_imports
  SET status = 'committed',
      organization = COALESCE(NULLIF(trim(p_organization), ''), organization),
      updated_at = now(),
      valid_rows = row_count,
      total_rows = row_count
  WHERE id = p_import_id;

  RETURN jsonb_build_object(
    'import_id', p_import_id,
    'batch_id', p_batch_id,
    'organization', p_organization,
    'committed_rows', row_count
  );
END;
$$;

ALTER TABLE public.verification_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_batch_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_imports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_import_rows ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Verification batches are readable to authorized users" ON public.verification_batches;
CREATE POLICY "Verification batches are readable to authorized users"
ON public.verification_batches
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
    OR public.user_has_permission('view_platform')
  )
);

DROP POLICY IF EXISTS "Verification batches are writable to authorized staff" ON public.verification_batches;
CREATE POLICY "Verification batches are writable to authorized staff"
ON public.verification_batches
FOR INSERT
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
);

DROP POLICY IF EXISTS "Verification batches are updateable by authorized staff" ON public.verification_batches;
CREATE POLICY "Verification batches are updateable by authorized staff"
ON public.verification_batches
FOR UPDATE
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
)
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
);

DROP POLICY IF EXISTS "Verification cases are readable to authorized users" ON public.verification_cases;
CREATE POLICY "Verification cases are readable to authorized users"
ON public.verification_cases
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
    OR public.user_has_permission('view_platform')
  )
);

DROP POLICY IF EXISTS "Verification cases are writable to authorized staff" ON public.verification_cases;
CREATE POLICY "Verification cases are writable to authorized staff"
ON public.verification_cases
FOR INSERT
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
);

DROP POLICY IF EXISTS "Verification cases are updateable by authorized staff" ON public.verification_cases;
CREATE POLICY "Verification cases are updateable by authorized staff"
ON public.verification_cases
FOR UPDATE
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
)
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
);

DROP POLICY IF EXISTS "Verification results are readable to authorized users" ON public.verification_results;
CREATE POLICY "Verification results are readable to authorized users"
ON public.verification_results
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
    OR public.user_has_permission('view_platform')
  )
);

DROP POLICY IF EXISTS "Verification results are writable to authorized staff" ON public.verification_results;
CREATE POLICY "Verification results are writable to authorized staff"
ON public.verification_results
FOR INSERT
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
);

DROP POLICY IF EXISTS "Verification results are updateable by authorized staff" ON public.verification_results;
CREATE POLICY "Verification results are updateable by authorized staff"
ON public.verification_results
FOR UPDATE
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
)
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
);

DROP POLICY IF EXISTS "Verification batch items are readable to authorized users" ON public.verification_batch_items;
CREATE POLICY "Verification batch items are readable to authorized users"
ON public.verification_batch_items
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
    OR public.user_has_permission('view_platform')
  )
);

DROP POLICY IF EXISTS "Verification batch items are writable to authorized staff" ON public.verification_batch_items;
CREATE POLICY "Verification batch items are writable to authorized staff"
ON public.verification_batch_items
FOR INSERT
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
);

DROP POLICY IF EXISTS "Verification batch items are updateable by authorized staff" ON public.verification_batch_items;
CREATE POLICY "Verification batch items are updateable by authorized staff"
ON public.verification_batch_items
FOR UPDATE
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
)
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
);

DROP POLICY IF EXISTS "Verification imports are readable to authorized users" ON public.verification_imports;
CREATE POLICY "Verification imports are readable to authorized users"
ON public.verification_imports
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
    OR public.user_has_permission('view_platform')
  )
);

DROP POLICY IF EXISTS "Verification imports are writable to authorized staff" ON public.verification_imports;
CREATE POLICY "Verification imports are writable to authorized staff"
ON public.verification_imports
FOR INSERT
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
);

DROP POLICY IF EXISTS "Verification imports are updateable by authorized staff" ON public.verification_imports;
CREATE POLICY "Verification imports are updateable by authorized staff"
ON public.verification_imports
FOR UPDATE
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
)
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
);

DROP POLICY IF EXISTS "Verification import rows are readable to authorized users" ON public.verification_import_rows;
CREATE POLICY "Verification import rows are readable to authorized users"
ON public.verification_import_rows
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
    OR public.user_has_permission('view_platform')
  )
);

DROP POLICY IF EXISTS "Verification import rows are writable to authorized staff" ON public.verification_import_rows;
CREATE POLICY "Verification import rows are writable to authorized staff"
ON public.verification_import_rows
FOR INSERT
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
);

DROP POLICY IF EXISTS "Verification import rows are updateable by authorized staff" ON public.verification_import_rows;
CREATE POLICY "Verification import rows are updateable by authorized staff"
ON public.verification_import_rows
FOR UPDATE
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
)
WITH CHECK (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
  )
);

COMMIT;
