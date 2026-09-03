CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.discovery_sources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  name text NOT NULL,
  source_type text NOT NULL DEFAULT 'manual' CHECK (source_type IN ('manual', 'social', 'website', 'partner', 'campaign', 'import', 'other')),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.businesses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  display_name text NOT NULL,
  legal_name text,
  website text,
  email text,
  phone text,
  city text,
  state text,
  industry text,
  description text,
  d9_connection_status text NOT NULL DEFAULT 'unknown' CHECK (d9_connection_status IN ('known_greek', 'unknown', 'community_business', 'existing_member', 'duplicate', 'opt_out')),
  membership_match_status text NOT NULL DEFAULT 'not_reviewed' CHECK (membership_match_status IN ('not_reviewed', 'match_found', 'no_match', 'manual_review')),
  profile_completeness integer NOT NULL DEFAULT 0 CHECK (profile_completeness BETWEEN 0 AND 100),
  source_url text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.business_contacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  full_name text,
  title text,
  email text,
  phone text,
  linked_in_url text,
  instagram_handle text,
  facebook_url text,
  is_primary boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.prospects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_name text,
  display_name text,
  primary_contact_name text,
  email text,
  phone text,
  website text,
  instagram_handle text,
  facebook_url text,
  linked_in_url text,
  city text,
  state text,
  industry text,
  short_description text,
  discovery_source_id uuid REFERENCES public.discovery_sources(id) ON DELETE SET NULL,
  source_url text,
  campaign_id uuid,
  assigned_staff_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  workflow_status text NOT NULL DEFAULT 'new' CHECK (workflow_status IN ('new', 'outreach_needed', 'd9_connection_reported', 'membership_match_review', 'duplicate_review', 'incomplete', 'opt_out_review', 'assigned', 'closed', 'converted')),
  d9_connection_status text NOT NULL DEFAULT 'unknown' CHECK (d9_connection_status IN ('known_greek', 'unknown', 'community_business', 'existing_member', 'duplicate', 'opt_out')),
  membership_match_status text NOT NULL DEFAULT 'not_reviewed' CHECK (membership_match_status IN ('not_reviewed', 'match_found', 'no_match', 'manual_review')),
  consent_status text NOT NULL DEFAULT 'unknown' CHECK (consent_status IN ('unknown', 'allowed', 'restricted', 'opt_out', 'pending')),
  is_duplicate boolean NOT NULL DEFAULT false,
  duplicate_score numeric(4,2) NOT NULL DEFAULT 0,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.campaigns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  campaign_type text NOT NULL DEFAULT 'discovery' CHECK (campaign_type IN ('discovery', 'outreach', 'community', 'spotlight', 'verification')),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'paused', 'completed')),
  source_channel text,
  owner_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  start_date date,
  end_date date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.nominations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nominated_business_name text NOT NULL,
  nominator_name text,
  nominator_email text,
  source text,
  source_url text,
  reason text,
  known_d9_connection text,
  permission_status text NOT NULL DEFAULT 'pending' CHECK (permission_status IN ('pending', 'allowed', 'restricted', 'opt_out')),
  review_status text NOT NULL DEFAULT 'new' CHECK (review_status IN ('new', 'under_review', 'accepted', 'rejected', 'duplicate', 'more_info_needed')),
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.import_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  file_name text NOT NULL,
  uploaded_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'validating', 'ready_to_commit', 'committed', 'failed')),
  total_rows integer NOT NULL DEFAULT 0,
  valid_rows integer NOT NULL DEFAULT 0,
  invalid_rows integer NOT NULL DEFAULT 0,
  template_version text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.import_rows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  import_job_id uuid NOT NULL REFERENCES public.import_jobs(id) ON DELETE CASCADE,
  row_number integer NOT NULL,
  row_data jsonb NOT NULL,
  validation_status text NOT NULL DEFAULT 'pending' CHECK (validation_status IN ('pending', 'valid', 'invalid')),
  validation_errors jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.workflow_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type text NOT NULL CHECK (entity_type IN ('prospect', 'business', 'nomination', 'campaign')),
  entity_id uuid NOT NULL,
  assigned_to uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  assigned_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  due_at timestamptz,
  priority text NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused', 'reassigned')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.workflow_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type text NOT NULL CHECK (entity_type IN ('prospect', 'business', 'nomination', 'campaign', 'import')),
  entity_id uuid NOT NULL,
  event_type text NOT NULL,
  actor_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.possible_duplicates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type text NOT NULL CHECK (entity_type IN ('prospect', 'business')),
  entity_id uuid NOT NULL,
  candidate_entity_type text NOT NULL CHECK (candidate_entity_type IN ('prospect', 'business')),
  candidate_entity_id uuid NOT NULL,
  match_reason text NOT NULL,
  confidence_level text NOT NULL CHECK (confidence_level IN ('exact', 'probable', 'possible', 'no_match')),
  fields_matched jsonb NOT NULL DEFAULT '[]'::jsonb,
  fields_conflicting jsonb NOT NULL DEFAULT '[]'::jsonb,
  recommended_action text NOT NULL DEFAULT 'manual_review',
  review_status text NOT NULL DEFAULT 'pending' CHECK (review_status IN ('pending', 'accepted', 'dismissed', 'manual_review')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.opt_outs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type text NOT NULL CHECK (entity_type IN ('prospect', 'business', 'contact')),
  entity_id uuid NOT NULL,
  source text NOT NULL,
  opt_out_reason text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.prospect_source_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prospect_id uuid NOT NULL REFERENCES public.prospects(id) ON DELETE CASCADE,
  source_id uuid REFERENCES public.discovery_sources(id) ON DELETE SET NULL,
  source_url text,
  event_type text NOT NULL DEFAULT 'discovered' CHECK (event_type IN ('discovered', 'matched', 'contacted', 'outreach', 'opt_out', 'duplicate_review')),
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.integration_statuses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  name text NOT NULL,
  status text NOT NULL DEFAULT 'not_configured' CHECK (status IN ('not_configured', 'configured', 'healthy', 'degraded', 'failed')),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.enforce_workflow_transition()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.d9_connection_status IS DISTINCT FROM NEW.d9_connection_status THEN
    IF OLD.d9_connection_status = 'opt_out' AND NEW.d9_connection_status <> 'opt_out' AND COALESCE(NEW.consent_status, 'unknown') <> 'allowed' THEN
      RAISE EXCEPTION 'Opted-out records require renewed consent before returning to active outreach.';
    END IF;

    IF NEW.d9_connection_status = 'duplicate' THEN
      NEW.workflow_status = 'duplicate_review';
    END IF;

    IF NEW.d9_connection_status = 'known_greek' THEN
      NEW.workflow_status = 'd9_connection_reported';
    END IF;

    IF NEW.d9_connection_status = 'unknown' THEN
      NEW.workflow_status = 'outreach_needed';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_workflow_transition()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.d9_connection_status IS DISTINCT FROM NEW.d9_connection_status THEN
    INSERT INTO public.workflow_events (
      entity_type,
      entity_id,
      event_type,
      actor_user_id,
      details
    ) VALUES (
      TG_ARGV[0],
      NEW.id,
      'status_transition',
      NULL,
      jsonb_build_object(
        'previous_status', OLD.d9_connection_status,
        'new_status', NEW.d9_connection_status,
        'reason', 'status_changed',
        'entity_table', TG_TABLE_NAME
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_prospect_workflow_transition
BEFORE UPDATE ON public.prospects
FOR EACH ROW
WHEN (OLD.d9_connection_status IS DISTINCT FROM NEW.d9_connection_status)
EXECUTE FUNCTION public.enforce_workflow_transition();

CREATE TRIGGER trg_business_workflow_transition
BEFORE UPDATE ON public.businesses
FOR EACH ROW
WHEN (OLD.d9_connection_status IS DISTINCT FROM NEW.d9_connection_status)
EXECUTE FUNCTION public.enforce_workflow_transition();

CREATE TRIGGER trg_prospect_workflow_audit
AFTER UPDATE ON public.prospects
FOR EACH ROW
WHEN (OLD.d9_connection_status IS DISTINCT FROM NEW.d9_connection_status)
EXECUTE FUNCTION public.record_workflow_transition('prospect');

CREATE TRIGGER trg_business_workflow_audit
AFTER UPDATE ON public.businesses
FOR EACH ROW
WHEN (OLD.d9_connection_status IS DISTINCT FROM NEW.d9_connection_status)
EXECUTE FUNCTION public.record_workflow_transition('business');

CREATE INDEX IF NOT EXISTS idx_businesses_d9_status ON public.businesses (d9_connection_status);
CREATE INDEX IF NOT EXISTS idx_businesses_city_state ON public.businesses (city, state);
CREATE INDEX IF NOT EXISTS idx_prospects_status ON public.prospects (workflow_status, d9_connection_status);
CREATE INDEX IF NOT EXISTS idx_prospects_assigned ON public.prospects (assigned_staff_id, workflow_status);
CREATE INDEX IF NOT EXISTS idx_nominations_review ON public.nominations (review_status, created_at);
CREATE INDEX IF NOT EXISTS idx_import_jobs_status ON public.import_jobs (status, created_at);
CREATE INDEX IF NOT EXISTS idx_workflow_assignments_entity ON public.workflow_assignments (entity_type, entity_id, status);

CREATE OR REPLACE TRIGGER set_discovery_sources_updated_at
BEFORE UPDATE ON public.discovery_sources
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE TRIGGER set_businesses_updated_at
BEFORE UPDATE ON public.businesses
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE TRIGGER set_business_contacts_updated_at
BEFORE UPDATE ON public.business_contacts
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE TRIGGER set_prospects_updated_at
BEFORE UPDATE ON public.prospects
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE TRIGGER set_campaigns_updated_at
BEFORE UPDATE ON public.campaigns
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE TRIGGER set_nominations_updated_at
BEFORE UPDATE ON public.nominations
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE TRIGGER set_import_jobs_updated_at
BEFORE UPDATE ON public.import_jobs
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE TRIGGER set_import_rows_updated_at
BEFORE UPDATE ON public.import_rows
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE TRIGGER set_workflow_assignments_updated_at
BEFORE UPDATE ON public.workflow_assignments
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE TRIGGER set_possible_duplicates_updated_at
BEFORE UPDATE ON public.possible_duplicates
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE TRIGGER set_opt_outs_updated_at
BEFORE UPDATE ON public.opt_outs
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE TRIGGER set_integration_statuses_updated_at
BEFORE UPDATE ON public.integration_statuses
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

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
BEGIN
  RETURN jsonb_build_object(
    'entity_type', record_type,
    'entity_id', record_id,
    'match_reason', 'normalized_text_match',
    'confidence_level', 'possible',
    'target_text', lower(trim(target_text)),
    'fields_matched', jsonb_build_array('display_name'),
    'fields_conflicting', jsonb_build_array(),
    'recommended_action', 'manual_review'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.tenant_allowed_read()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT true;
$$;
