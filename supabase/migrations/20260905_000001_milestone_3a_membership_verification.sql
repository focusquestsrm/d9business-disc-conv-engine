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

ALTER TABLE public.verification_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_results ENABLE ROW LEVEL SECURITY;

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

COMMIT;
