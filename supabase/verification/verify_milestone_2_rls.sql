-- Safe local verification script for the Milestone 2 schema and RLS package.
-- This script does not modify production data and does not claim successful live execution.

DO $$
BEGIN
  RAISE NOTICE 'Milestone 2 verification script loaded. Execute against the target Supabase project after migration.';
END $$;

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
SELECT 'public.enforce_workflow_transition' AS function_name, to_regprocedure('public.enforce_workflow_transition') AS exists;
SELECT 'public.record_workflow_transition' AS function_name, to_regprocedure('public.record_workflow_transition') AS exists;
SELECT 'public.build_d9_match_candidate' AS function_name, to_regprocedure('public.build_d9_match_candidate') AS exists;
SELECT 'public.tenant_allowed_read' AS function_name, to_regprocedure('public.tenant_allowed_read') AS exists;

SELECT 'Milestone 2 verification script ready. Manual policy checks still required in the target Supabase project.' AS status;
