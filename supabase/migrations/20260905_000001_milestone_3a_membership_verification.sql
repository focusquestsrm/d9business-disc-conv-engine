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

CREATE TABLE IF NOT EXISTS public.verification_case_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  verification_case_id uuid NOT NULL REFERENCES public.verification_cases(id) ON DELETE CASCADE,
  actor_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  action text NOT NULL,
  previous_status text,
  new_status text,
  previous_result text,
  new_result text,
  reason text,
  notes text,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
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

CREATE OR REPLACE FUNCTION public.write_verification_case_history(
  p_case_id uuid,
  p_action text,
  p_actor_user_id uuid,
  p_previous_status text DEFAULT NULL,
  p_new_status text DEFAULT NULL,
  p_previous_result text DEFAULT NULL,
  p_new_result text DEFAULT NULL,
  p_reason text DEFAULT NULL,
  p_notes text DEFAULT NULL,
  p_details jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  INSERT INTO public.verification_case_history (
    verification_case_id,
    actor_user_id,
    action,
    previous_status,
    new_status,
    previous_result,
    new_result,
    reason,
    notes,
    details
  ) VALUES (
    p_case_id,
    p_actor_user_id,
    p_action,
    p_previous_status,
    p_new_status,
    p_previous_result,
    p_new_result,
    p_reason,
    p_notes,
    COALESCE(p_details, '{}'::jsonb)
  );

  INSERT INTO public.audit_events (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    previous_values,
    new_values,
    source,
    reason,
    correlation_id
  ) VALUES (
    p_actor_user_id,
    p_action,
    'verification_case',
    p_case_id::text,
    jsonb_build_object(
      'status', p_previous_status,
      'result', p_previous_result,
      'reason', p_reason
    ),
    jsonb_build_object(
      'status', p_new_status,
      'result', p_new_result,
      'reason', p_reason,
      'details', COALESCE(p_details, '{}'::jsonb)
    ),
    'verification',
    p_reason,
    gen_random_uuid()::text
  );

  INSERT INTO public.workflow_events (
    entity_type,
    entity_id,
    event_type,
    actor_user_id,
    details
  ) VALUES (
    'verification_case',
    p_case_id,
    p_action,
    p_actor_user_id,
    COALESCE(p_details, '{}'::jsonb)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.assign_verification_reviewer(
  p_case_id uuid,
  p_reviewer_user_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  current_record public.verification_cases%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required to assign a verification reviewer.';
  END IF;

  IF NOT (public.current_user_is_platform_admin() OR public.user_has_permission('view_verification_modules')) THEN
    RAISE EXCEPTION 'Permission denied: reviewer assignment requires verification access.';
  END IF;

  IF p_reviewer_user_id IS NULL THEN
    RAISE EXCEPTION 'A reviewer user id is required.';
  END IF;

  SELECT * INTO current_record
  FROM public.verification_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF current_record.id IS NULL THEN
    RAISE EXCEPTION 'Verification case % was not found.', p_case_id;
  END IF;

  IF current_record.status NOT IN ('ready_for_batch', 'batched', 'exported', 'sent_to_organization', 'response_received') THEN
    RAISE EXCEPTION 'Verification case % cannot be assigned a reviewer while in status %.', p_case_id, current_record.status;
  END IF;

  UPDATE public.verification_cases
  SET verified_by = p_reviewer_user_id,
      updated_at = now()
  WHERE id = p_case_id;

  PERFORM public.write_verification_case_history(
    p_case_id,
    'assign_reviewer',
    auth.uid(),
    current_record.status,
    current_record.status,
    current_record.result,
    current_record.result,
    p_reason,
    NULL,
    jsonb_build_object('reviewer_user_id', p_reviewer_user_id)
  );

  RETURN jsonb_build_object(
    'case_id', p_case_id,
    'reviewer_user_id', p_reviewer_user_id,
    'status', current_record.status,
    'assigned_at', now()
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.transition_verification_case_status(
  p_case_id uuid,
  p_new_status text,
  p_reason text DEFAULT NULL,
  p_result text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  current_record public.verification_cases%ROWTYPE;
  next_result text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required to transition verification status.';
  END IF;

  IF NOT (public.current_user_is_platform_admin() OR public.user_has_permission('view_verification_modules')) THEN
    RAISE EXCEPTION 'Permission denied: verification status changes require authorized staff access.';
  END IF;

  SELECT * INTO current_record
  FROM public.verification_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF current_record.id IS NULL THEN
    RAISE EXCEPTION 'Verification case % was not found.', p_case_id;
  END IF;

  IF p_new_status IS NULL THEN
    RAISE EXCEPTION 'A new verification status is required.';
  END IF;

  IF p_new_status = 'verified' AND current_record.status <> 'response_received' THEN
    RAISE EXCEPTION 'Verification cases can only move to verified from response_received.';
  END IF;

  IF p_new_status IN ('rejected', 'unable_to_verify', 'needs_follow_up') AND NULLIF(trim(COALESCE(p_reason, '')), '') IS NULL THEN
    RAISE EXCEPTION 'A reason is required before moving a verification case to %.', p_new_status;
  END IF;

  IF p_new_status NOT IN ('not_requested', 'information_incomplete', 'ready_for_batch', 'batched', 'exported', 'sent_to_organization', 'response_received', 'verified', 'unable_to_verify', 'rejected', 'needs_follow_up', 'expired') THEN
    RAISE EXCEPTION 'Unsupported state % for verification case.', p_new_status;
  END IF;

  IF current_record.status = 'not_requested' AND p_new_status NOT IN ('information_incomplete', 'ready_for_batch') THEN
    RAISE EXCEPTION 'Invalid transition from % to %.', current_record.status, p_new_status;
  END IF;

  IF current_record.status = 'information_incomplete' AND p_new_status NOT IN ('ready_for_batch', 'expired') THEN
    RAISE EXCEPTION 'Invalid transition from % to %.', current_record.status, p_new_status;
  END IF;

  IF current_record.status = 'ready_for_batch' AND p_new_status NOT IN ('batched', 'rejected', 'needs_follow_up', 'expired') THEN
    RAISE EXCEPTION 'Invalid transition from % to %.', current_record.status, p_new_status;
  END IF;

  IF current_record.status = 'batched' AND p_new_status NOT IN ('exported', 'expired') THEN
    RAISE EXCEPTION 'Invalid transition from % to %.', current_record.status, p_new_status;
  END IF;

  IF current_record.status = 'exported' AND p_new_status NOT IN ('sent_to_organization', 'expired') THEN
    RAISE EXCEPTION 'Invalid transition from % to %.', current_record.status, p_new_status;
  END IF;

  IF current_record.status = 'sent_to_organization' AND p_new_status NOT IN ('response_received', 'expired') THEN
    RAISE EXCEPTION 'Invalid transition from % to %.', current_record.status, p_new_status;
  END IF;

  IF current_record.status = 'response_received' AND p_new_status NOT IN ('verified', 'unable_to_verify', 'rejected', 'needs_follow_up') THEN
    RAISE EXCEPTION 'Invalid transition from % to %.', current_record.status, p_new_status;
  END IF;

  IF current_record.status = 'verified' AND p_new_status <> 'expired' THEN
    RAISE EXCEPTION 'Invalid transition from % to %.', current_record.status, p_new_status;
  END IF;

  IF current_record.status = 'unable_to_verify' AND p_new_status NOT IN ('needs_follow_up', 'expired') THEN
    RAISE EXCEPTION 'Invalid transition from % to %.', current_record.status, p_new_status;
  END IF;

  IF current_record.status = 'rejected' AND p_new_status NOT IN ('needs_follow_up', 'expired') THEN
    RAISE EXCEPTION 'Invalid transition from % to %.', current_record.status, p_new_status;
  END IF;

  IF current_record.status = 'needs_follow_up' AND p_new_status NOT IN ('ready_for_batch', 'expired') THEN
    RAISE EXCEPTION 'Invalid transition from % to %.', current_record.status, p_new_status;
  END IF;

  IF current_record.status = 'expired' AND p_new_status <> 'ready_for_batch' THEN
    RAISE EXCEPTION 'Invalid transition from % to %.', current_record.status, p_new_status;
  END IF;

  next_result := current_record.result;
  IF p_result IS NOT NULL THEN
    next_result := upper(p_result);
  ELSIF p_new_status = 'verified' THEN
    next_result := 'VERIFIED';
  ELSIF p_new_status = 'unable_to_verify' THEN
    next_result := 'UNABLE_TO_VERIFY';
  ELSIF p_new_status = 'rejected' THEN
    next_result := 'REJECTED';
  ELSIF p_new_status = 'needs_follow_up' THEN
    next_result := 'NEEDS_FOLLOW_UP';
  END IF;

  UPDATE public.verification_cases
  SET status = p_new_status,
      result = CASE WHEN next_result IS NOT NULL THEN next_result ELSE current_record.result END,
      verification_reason = CASE WHEN p_reason IS NOT NULL THEN p_reason ELSE current_record.verification_reason END,
      verified_by = CASE WHEN p_new_status = 'verified' THEN auth.uid() ELSE current_record.verified_by END,
      verified_at = CASE WHEN p_new_status = 'verified' THEN now() ELSE current_record.verified_at END,
      updated_at = now()
  WHERE id = p_case_id;

  PERFORM public.write_verification_case_history(
    p_case_id,
    'status_transition',
    auth.uid(),
    current_record.status,
    p_new_status,
    current_record.result,
    CASE WHEN next_result IS NOT NULL THEN next_result ELSE current_record.result END,
    p_reason,
    NULL,
    jsonb_build_object('requested_status', p_new_status, 'requested_result', next_result)
  );

  RETURN jsonb_build_object(
    'case_id', p_case_id,
    'previous_status', current_record.status,
    'new_status', p_new_status,
    'result', CASE WHEN next_result IS NOT NULL THEN next_result ELSE current_record.result END,
    'reason', p_reason
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_verification_batch_exported(
  p_batch_id uuid,
  p_exported_by uuid DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  current_batch public.verification_batches%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required to export a verification batch.';
  END IF;

  IF NOT (public.current_user_is_platform_admin() OR public.user_has_permission('view_verification_modules')) THEN
    RAISE EXCEPTION 'Permission denied: batch export requires verification access.';
  END IF;

  SELECT * INTO current_batch
  FROM public.verification_batches
  WHERE id = p_batch_id
  FOR UPDATE;

  IF current_batch.id IS NULL THEN
    RAISE EXCEPTION 'Verification batch % was not found.', p_batch_id;
  END IF;

  IF current_batch.status NOT IN ('draft', 'ready_for_export') THEN
    RAISE EXCEPTION 'Verification batch % cannot be exported while in status %.', p_batch_id, current_batch.status;
  END IF;

  UPDATE public.verification_batches
  SET status = 'exported',
      notes = COALESCE(NULLIF(trim(p_notes), ''), current_batch.notes),
      updated_at = now()
  WHERE id = p_batch_id;

  UPDATE public.verification_cases
  SET status = 'exported',
      updated_at = now()
  WHERE batch_id = p_batch_id
    AND status IN ('ready_for_batch', 'batched');

  INSERT INTO public.audit_events (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    previous_values,
    new_values,
    source,
    reason
  ) VALUES (
    COALESCE(p_exported_by, auth.uid()),
    'batch_exported',
    'verification_batch',
    p_batch_id::text,
    jsonb_build_object('status', current_batch.status),
    jsonb_build_object('status', 'exported', 'notes', COALESCE(p_notes, current_batch.notes)),
    'verification',
    p_notes
  );

  RETURN jsonb_build_object(
    'batch_id', p_batch_id,
    'status', 'exported',
    'updated_at', now()
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_verification_batch_sent(
  p_batch_id uuid,
  p_sent_by uuid DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  current_batch public.verification_batches%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required to send a verification batch.';
  END IF;

  IF NOT (public.current_user_is_platform_admin() OR public.user_has_permission('view_verification_modules')) THEN
    RAISE EXCEPTION 'Permission denied: sending a batch requires verification access.';
  END IF;

  SELECT * INTO current_batch
  FROM public.verification_batches
  WHERE id = p_batch_id
  FOR UPDATE;

  IF current_batch.id IS NULL THEN
    RAISE EXCEPTION 'Verification batch % was not found.', p_batch_id;
  END IF;

  IF current_batch.status NOT IN ('exported', 'ready_for_export') THEN
    RAISE EXCEPTION 'Verification batch % cannot be sent while in status %.', p_batch_id, current_batch.status;
  END IF;

  UPDATE public.verification_batches
  SET status = 'sent_to_organization',
      notes = COALESCE(NULLIF(trim(p_notes), ''), current_batch.notes),
      updated_at = now()
  WHERE id = p_batch_id;

  UPDATE public.verification_cases
  SET status = 'sent_to_organization',
      updated_at = now()
  WHERE batch_id = p_batch_id
    AND status IN ('exported', 'ready_for_batch', 'batched');

  INSERT INTO public.audit_events (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    previous_values,
    new_values,
    source,
    reason
  ) VALUES (
    COALESCE(p_sent_by, auth.uid()),
    'batch_sent',
    'verification_batch',
    p_batch_id::text,
    jsonb_build_object('status', current_batch.status),
    jsonb_build_object('status', 'sent_to_organization', 'notes', COALESCE(p_notes, current_batch.notes)),
    'verification',
    p_notes
  );

  RETURN jsonb_build_object(
    'batch_id', p_batch_id,
    'status', 'sent_to_organization',
    'updated_at', now()
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.record_verification_response_received(
  p_case_id uuid,
  p_organization_name text,
  p_result text,
  p_reason text DEFAULT NULL,
  p_notes text DEFAULT NULL,
  p_verification_date timestamptz DEFAULT now()
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  current_record public.verification_cases%ROWTYPE;
  normalized_result text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required to record an organization response.';
  END IF;

  IF NOT (public.current_user_is_platform_admin() OR public.user_has_permission('view_verification_modules')) THEN
    RAISE EXCEPTION 'Permission denied: response recording requires verification access.';
  END IF;

  IF p_result IS NULL OR UPPER(TRIM(p_result)) NOT IN ('VERIFIED', 'UNABLE_TO_VERIFY', 'REJECTED', 'NEEDS_FOLLOW_UP') THEN
    RAISE EXCEPTION 'Verification organization result must be one of VERIFIED, UNABLE_TO_VERIFY, REJECTED, NEEDS_FOLLOW_UP.';
  END IF;

  SELECT * INTO current_record
  FROM public.verification_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF current_record.id IS NULL THEN
    RAISE EXCEPTION 'Verification case % was not found.', p_case_id;
  END IF;

  IF current_record.status NOT IN ('sent_to_organization', 'response_received') THEN
    RAISE EXCEPTION 'Verification case % cannot record an organization response while in status %.', p_case_id, current_record.status;
  END IF;

  normalized_result := upper(trim(p_result));

  INSERT INTO public.verification_results (
    verification_case_id,
    organization_name,
    organization_result,
    reason,
    notes,
    verification_date,
    created_by
  ) VALUES (
    p_case_id,
    COALESCE(NULLIF(trim(p_organization_name), ''), current_record.claimed_organization),
    normalized_result,
    NULLIF(trim(p_reason), ''),
    NULLIF(trim(p_notes), ''),
    COALESCE(p_verification_date, now()),
    auth.uid()
  );

  UPDATE public.verification_cases
  SET status = 'response_received',
      result = normalized_result,
      verification_reason = NULLIF(trim(p_reason), ''),
      updated_at = now()
  WHERE id = p_case_id;

  PERFORM public.write_verification_case_history(
    p_case_id,
    'response_received',
    auth.uid(),
    current_record.status,
    'response_received',
    current_record.result,
    normalized_result,
    p_reason,
    p_notes,
    jsonb_build_object('organization_name', COALESCE(NULLIF(trim(p_organization_name), ''), current_record.claimed_organization), 'result', normalized_result)
  );

  RETURN jsonb_build_object(
    'case_id', p_case_id,
    'status', 'response_received',
    'result', normalized_result,
    'reason', NULLIF(trim(p_reason), '')
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.close_verification_batch(
  p_batch_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  current_batch public.verification_batches%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required to close a verification batch.';
  END IF;

  IF NOT (public.current_user_is_platform_admin() OR public.user_has_permission('view_verification_modules')) THEN
    RAISE EXCEPTION 'Permission denied: closing a batch requires verification access.';
  END IF;

  SELECT * INTO current_batch
  FROM public.verification_batches
  WHERE id = p_batch_id
  FOR UPDATE;

  IF current_batch.id IS NULL THEN
    RAISE EXCEPTION 'Verification batch % was not found.', p_batch_id;
  END IF;

  IF current_batch.status NOT IN ('response_received', 'completed', 'sent_to_organization', 'exported') THEN
    RAISE EXCEPTION 'Verification batch % cannot be closed while in status %.', p_batch_id, current_batch.status;
  END IF;

  UPDATE public.verification_batches
  SET status = 'closed',
      notes = COALESCE(NULLIF(trim(p_reason), ''), current_batch.notes),
      updated_at = now()
  WHERE id = p_batch_id;

  UPDATE public.verification_cases
  SET status = CASE WHEN result IN ('VERIFIED', 'UNABLE_TO_VERIFY', 'REJECTED', 'NEEDS_FOLLOW_UP') THEN status ELSE 'expired' END,
      updated_at = now()
  WHERE batch_id = p_batch_id;

  INSERT INTO public.audit_events (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    previous_values,
    new_values,
    source,
    reason
  ) VALUES (
    auth.uid(),
    'batch_closed',
    'verification_batch',
    p_batch_id::text,
    jsonb_build_object('status', current_batch.status),
    jsonb_build_object('status', 'closed', 'reason', p_reason),
    'verification',
    p_reason
  );

  RETURN jsonb_build_object(
    'batch_id', p_batch_id,
    'status', 'closed',
    'reason', p_reason
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_verification_batch(
  p_batch_id uuid,
  p_reason text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  current_batch public.verification_batches%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required to cancel a verification batch.';
  END IF;

  IF NOT (public.current_user_is_platform_admin() OR public.user_has_permission('view_verification_modules')) THEN
    RAISE EXCEPTION 'Permission denied: batch cancellation requires verification access.';
  END IF;

  IF NULLIF(trim(COALESCE(p_reason, '')), '') IS NULL THEN
    RAISE EXCEPTION 'A cancellation reason is required.';
  END IF;

  SELECT * INTO current_batch
  FROM public.verification_batches
  WHERE id = p_batch_id
  FOR UPDATE;

  IF current_batch.id IS NULL THEN
    RAISE EXCEPTION 'Verification batch % was not found.', p_batch_id;
  END IF;

  UPDATE public.verification_batches
  SET status = 'closed',
      notes = COALESCE(NULLIF(trim(p_reason), ''), current_batch.notes),
      updated_at = now()
  WHERE id = p_batch_id;

  UPDATE public.verification_cases
  SET status = 'expired',
      updated_at = now()
  WHERE batch_id = p_batch_id
    AND status IN ('ready_for_batch', 'batched', 'exported', 'sent_to_organization', 'response_received');

  INSERT INTO public.audit_events (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    previous_values,
    new_values,
    source,
    reason
  ) VALUES (
    auth.uid(),
    'batch_cancelled',
    'verification_batch',
    p_batch_id::text,
    jsonb_build_object('status', current_batch.status),
    jsonb_build_object('status', 'closed', 'reason', p_reason),
    'verification',
    p_reason
  );

  RETURN jsonb_build_object(
    'batch_id', p_batch_id,
    'status', 'closed',
    'reason', p_reason
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.save_manual_verification_result(
  p_case_id uuid,
  p_result text,
  p_reason text DEFAULT NULL,
  p_notes text DEFAULT NULL,
  p_verified_by uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  current_record public.verification_cases%ROWTYPE;
  normalized_result text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required to save a manual verification result.';
  END IF;

  IF NOT (public.current_user_is_platform_admin() OR public.user_has_permission('view_verification_modules')) THEN
    RAISE EXCEPTION 'Permission denied: manual verification results require verification access.';
  END IF;

  IF p_result IS NULL OR UPPER(TRIM(p_result)) NOT IN ('VERIFIED', 'UNABLE_TO_VERIFY', 'REJECTED', 'NEEDS_FOLLOW_UP') THEN
    RAISE EXCEPTION 'Manual verification result must be one of VERIFIED, UNABLE_TO_VERIFY, REJECTED, NEEDS_FOLLOW_UP.';
  END IF;

  SELECT * INTO current_record
  FROM public.verification_cases
  WHERE id = p_case_id
  FOR UPDATE;

  IF current_record.id IS NULL THEN
    RAISE EXCEPTION 'Verification case % was not found.', p_case_id;
  END IF;

  IF current_record.status NOT IN ('response_received', 'sent_to_organization', 'ready_for_batch') THEN
    RAISE EXCEPTION 'Verification case % cannot be manually updated while in status %.', p_case_id, current_record.status;
  END IF;

  normalized_result := upper(trim(p_result));

  INSERT INTO public.verification_results (
    verification_case_id,
    organization_name,
    organization_result,
    reason,
    notes,
    verification_date,
    created_by
  ) VALUES (
    p_case_id,
    COALESCE(current_record.claimed_organization, 'Manual verification'),
    normalized_result,
    NULLIF(trim(p_reason), ''),
    NULLIF(trim(p_notes), ''),
    now(),
    COALESCE(p_verified_by, auth.uid())
  );

  UPDATE public.verification_cases
  SET status = CASE
        WHEN normalized_result = 'VERIFIED' THEN 'verified'
        WHEN normalized_result = 'UNABLE_TO_VERIFY' THEN 'unable_to_verify'
        WHEN normalized_result = 'REJECTED' THEN 'rejected'
        ELSE 'needs_follow_up'
      END,
      result = normalized_result,
      verification_reason = NULLIF(trim(p_reason), ''),
      verified_by = COALESCE(p_verified_by, auth.uid()),
      verified_at = now(),
      updated_at = now()
  WHERE id = p_case_id;

  PERFORM public.write_verification_case_history(
    p_case_id,
    'manual_verification_result',
    COALESCE(p_verified_by, auth.uid()),
    current_record.status,
    CASE
      WHEN normalized_result = 'VERIFIED' THEN 'verified'
      WHEN normalized_result = 'UNABLE_TO_VERIFY' THEN 'unable_to_verify'
      WHEN normalized_result = 'REJECTED' THEN 'rejected'
      ELSE 'needs_follow_up'
    END,
    current_record.result,
    normalized_result,
    p_reason,
    p_notes,
    jsonb_build_object('verified_by', COALESCE(p_verified_by, auth.uid()), 'result', normalized_result)
  );

  RETURN jsonb_build_object(
    'case_id', p_case_id,
    'status', CASE
      WHEN normalized_result = 'VERIFIED' THEN 'verified'
      WHEN normalized_result = 'UNABLE_TO_VERIFY' THEN 'unable_to_verify'
      WHEN normalized_result = 'REJECTED' THEN 'rejected'
      ELSE 'needs_follow_up'
    END,
    'result', normalized_result,
    'verified_by', COALESCE(p_verified_by, auth.uid())
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_verification_case_history(p_case_id uuid)
RETURNS TABLE (
  id uuid,
  action text,
  actor_user_id uuid,
  previous_status text,
  new_status text,
  previous_result text,
  new_result text,
  reason text,
  notes text,
  details jsonb,
  created_at timestamptz
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT
    vch.id,
    vch.action,
    vch.actor_user_id,
    vch.previous_status,
    vch.new_status,
    vch.previous_result,
    vch.new_result,
    vch.reason,
    vch.notes,
    vch.details,
    vch.created_at
  FROM public.verification_case_history vch
  WHERE vch.verification_case_id = p_case_id
  ORDER BY vch.created_at ASC;
$$;

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
ALTER TABLE public.verification_case_history ENABLE ROW LEVEL SECURITY;

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

DROP POLICY IF EXISTS "Verification case history is readable to authorized users" ON public.verification_case_history;
CREATE POLICY "Verification case history is readable to authorized users"
ON public.verification_case_history
FOR SELECT
USING (
  auth.uid() IS NOT NULL
  AND (
    public.current_user_is_platform_admin()
    OR public.user_has_permission('view_verification_modules')
    OR public.user_has_permission('view_platform')
  )
);

DROP POLICY IF EXISTS "Verification case history is writable to authorized staff" ON public.verification_case_history;
CREATE POLICY "Verification case history is writable to authorized staff"
ON public.verification_case_history
FOR INSERT
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
