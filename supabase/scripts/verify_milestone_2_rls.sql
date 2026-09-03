-- Verify milestone 2 schema and RLS readiness.
-- Run after the Milestone 2 migration and the project role bootstrap are in place.
-- This script is intentionally safe to run in the target Supabase project; it does not
-- claim that the live project was executed from this local environment.

SELECT 'public.discovery_sources' AS table_name, to_regclass('public.discovery_sources') AS exists;
SELECT 'public.businesses' AS table_name, to_regclass('public.businesses') AS exists;
SELECT 'public.business_contacts' AS table_name, to_regclass('public.business_contacts') AS exists;
SELECT 'public.prospects' AS table_name, to_regclass('public.prospects') AS exists;
SELECT 'public.campaigns' AS table_name, to_regclass('public.campaigns') AS exists;
SELECT 'public.nominations' AS table_name, to_regclass('public.nominations') AS exists;
SELECT 'public.import_jobs' AS table_name, to_regclass('public.import_jobs') AS exists;
SELECT 'public.import_rows' AS table_name, to_regclass('public.import_rows') AS exists;
SELECT 'public.workflow_assignments' AS table_name, to_regclass('public.workflow_assignments') AS exists;
SELECT 'public.workflow_events' AS table_name, to_regclass('public.workflow_events') AS exists;
SELECT 'public.possible_duplicates' AS table_name, to_regclass('public.possible_duplicates') AS exists;
SELECT 'public.opt_outs' AS table_name, to_regclass('public.opt_outs') AS exists;
SELECT 'public.prospect_source_events' AS table_name, to_regclass('public.prospect_source_events') AS exists;
SELECT 'public.integration_statuses' AS table_name, to_regclass('public.integration_statuses') AS exists;

SELECT 'public.set_updated_at' AS function_name, to_regprocedure('public.set_updated_at') AS exists;
SELECT 'public.build_d9_match_candidate' AS function_name, to_regprocedure('public.build_d9_match_candidate') AS exists;
SELECT 'public.tenant_allowed_read' AS function_name, to_regprocedure('public.tenant_allowed_read') AS exists;
SELECT 'public.enforce_workflow_transition' AS function_name, to_regprocedure('public.enforce_workflow_transition') AS exists;
SELECT 'public.record_workflow_transition' AS function_name, to_regprocedure('public.record_workflow_transition') AS exists;

SELECT 'milestone_2_schema_objects_present' AS check_name,
       COUNT(*) AS expected_objects
FROM (
  SELECT unnest(ARRAY[
    'public.discovery_sources',
    'public.businesses',
    'public.business_contacts',
    'public.prospects',
    'public.campaigns',
    'public.nominations',
    'public.import_jobs',
    'public.import_rows',
    'public.workflow_assignments',
    'public.workflow_events',
    'public.possible_duplicates',
    'public.opt_outs',
    'public.prospect_source_events',
    'public.integration_statuses'
  ]) AS table_name
) t
WHERE to_regclass(t.table_name) IS NOT NULL;

-- Manual policy validation checklist for the target Supabase project:
-- 1. Confirm anon users cannot read discovery or operational tables.
-- 2. Confirm authenticated users can read only the rows permitted by their role.
-- 3. Confirm platform admins can manage assignments and workflow data.
-- 4. Confirm non-admin users cannot update or delete protected audit/workflow records.
-- 5. Confirm duplicate, opt-out, and nomination transitions enforce project-approved workflow rules.

SELECT 'Milestone 2 RLS verification script is ready for execution in the target Supabase project.' AS status;
