-- Canonical Milestone 2 read-only verification script.
-- Path: C:\Users\danie\d9business-disc-conv-engine\supabase\scripts\verify_milestone_2_rls.sql
-- This script is intentionally read-only and does not create, alter, or delete any schema,
-- policies, data, roles, or configuration.
-- It must return exactly one consolidated PASS/FAIL result set for every required check.

WITH required_results AS (
  SELECT 'TABLE' AS category, 'public.discovery_sources' AS object_name, 'table_exists' AS check_name,
         'EXISTS' AS expected_result,
         CASE WHEN to_regclass('public.discovery_sources') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END AS actual_result,
         CASE WHEN to_regclass('public.discovery_sources') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS status,
         CASE WHEN to_regclass('public.discovery_sources') IS NOT NULL THEN 'public.discovery_sources exists.' ELSE 'public.discovery_sources is missing.' END AS details
  UNION ALL
  SELECT 'TABLE', 'public.businesses', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.businesses') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.businesses') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.businesses') IS NOT NULL THEN 'public.businesses exists.' ELSE 'public.businesses is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.business_contacts', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.business_contacts') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.business_contacts') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.business_contacts') IS NOT NULL THEN 'public.business_contacts exists.' ELSE 'public.business_contacts is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.prospects', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.prospects') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.prospects') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.prospects') IS NOT NULL THEN 'public.prospects exists.' ELSE 'public.prospects is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.campaigns', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.campaigns') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.campaigns') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.campaigns') IS NOT NULL THEN 'public.campaigns exists.' ELSE 'public.campaigns is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.nominations', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.nominations') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.nominations') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.nominations') IS NOT NULL THEN 'public.nominations exists.' ELSE 'public.nominations is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.import_jobs', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.import_jobs') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.import_jobs') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.import_jobs') IS NOT NULL THEN 'public.import_jobs exists.' ELSE 'public.import_jobs is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.import_rows', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.import_rows') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.import_rows') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.import_rows') IS NOT NULL THEN 'public.import_rows exists.' ELSE 'public.import_rows is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.workflow_assignments', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.workflow_assignments') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.workflow_assignments') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.workflow_assignments') IS NOT NULL THEN 'public.workflow_assignments exists.' ELSE 'public.workflow_assignments is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.workflow_events', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.workflow_events') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.workflow_events') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.workflow_events') IS NOT NULL THEN 'public.workflow_events exists.' ELSE 'public.workflow_events is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.possible_duplicates', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.possible_duplicates') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.possible_duplicates') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.possible_duplicates') IS NOT NULL THEN 'public.possible_duplicates exists.' ELSE 'public.possible_duplicates is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.opt_outs', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.opt_outs') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.opt_outs') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.opt_outs') IS NOT NULL THEN 'public.opt_outs exists.' ELSE 'public.opt_outs is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.prospect_source_events', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.prospect_source_events') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.prospect_source_events') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.prospect_source_events') IS NOT NULL THEN 'public.prospect_source_events exists.' ELSE 'public.prospect_source_events is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.integration_statuses', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.integration_statuses') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.integration_statuses') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.integration_statuses') IS NOT NULL THEN 'public.integration_statuses exists.' ELSE 'public.integration_statuses is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.set_updated_at()', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.set_updated_at()') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.set_updated_at()') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.set_updated_at()') IS NOT NULL THEN 'public.set_updated_at() exists.' ELSE 'public.set_updated_at() is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.enforce_workflow_transition()', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.enforce_workflow_transition()') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.enforce_workflow_transition()') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.enforce_workflow_transition()') IS NOT NULL THEN 'public.enforce_workflow_transition() exists.' ELSE 'public.enforce_workflow_transition() is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.record_workflow_transition()', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.record_workflow_transition()') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.record_workflow_transition()') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.record_workflow_transition()') IS NOT NULL THEN 'public.record_workflow_transition() exists.' ELSE 'public.record_workflow_transition() is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.build_d9_match_candidate(text,uuid,text)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.build_d9_match_candidate(text,uuid,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.build_d9_match_candidate(text,uuid,text)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.build_d9_match_candidate(text,uuid,text)') IS NOT NULL THEN 'public.build_d9_match_candidate(text,uuid,text) exists.' ELSE 'public.build_d9_match_candidate(text,uuid,text) is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.tenant_allowed_read()', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.tenant_allowed_read()') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.tenant_allowed_read()') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.tenant_allowed_read()') IS NOT NULL THEN 'public.tenant_allowed_read() exists.' ELSE 'public.tenant_allowed_read() is missing.' END
  UNION ALL
  SELECT 'TABLE', 'milestone_2', 'core_object_count', '14',
         CAST((SELECT COUNT(*) FROM (
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
         ) t WHERE to_regclass(t.table_name) IS NOT NULL) AS text),
         CASE WHEN (SELECT COUNT(*) FROM (
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
         ) t WHERE to_regclass(t.table_name) IS NOT NULL) = 14 THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT COUNT(*) FROM (
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
         ) t WHERE to_regclass(t.table_name) IS NOT NULL) = 14 THEN 'Milestone 2 required tables count is correct.' ELSE 'Milestone 2 required tables count is not 14.' END
  UNION ALL
  SELECT 'TABLE', 'public.discovery_sources', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.discovery_sources'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.discovery_sources'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.discovery_sources'::regclass) THEN 'RLS enabled on public.discovery_sources.' ELSE 'RLS is not enabled on public.discovery_sources.' END
  UNION ALL
  SELECT 'TABLE', 'public.businesses', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.businesses'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.businesses'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.businesses'::regclass) THEN 'RLS enabled on public.businesses.' ELSE 'RLS is not enabled on public.businesses.' END
  UNION ALL
  SELECT 'TABLE', 'public.business_contacts', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.business_contacts'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.business_contacts'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.business_contacts'::regclass) THEN 'RLS enabled on public.business_contacts.' ELSE 'RLS is not enabled on public.business_contacts.' END
  UNION ALL
  SELECT 'TABLE', 'public.prospects', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.prospects'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.prospects'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.prospects'::regclass) THEN 'RLS enabled on public.prospects.' ELSE 'RLS is not enabled on public.prospects.' END
  UNION ALL
  SELECT 'TABLE', 'public.workflow_assignments', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.workflow_assignments'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.workflow_assignments'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.workflow_assignments'::regclass) THEN 'RLS enabled on public.workflow_assignments.' ELSE 'RLS is not enabled on public.workflow_assignments.' END
  UNION ALL
  SELECT 'TABLE', 'public.workflow_events', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.workflow_events'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.workflow_events'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.workflow_events'::regclass) THEN 'RLS enabled on public.workflow_events.' ELSE 'RLS is not enabled on public.workflow_events.' END
  UNION ALL
  SELECT 'TABLE', 'public.opt_outs', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.opt_outs'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.opt_outs'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.opt_outs'::regclass) THEN 'RLS enabled on public.opt_outs.' ELSE 'RLS is not enabled on public.opt_outs.' END
  UNION ALL
  SELECT 'POLICY', 'public.discovery_sources', 'rls_policy_exists', 'AT_LEAST_ONE_POLICY',
         CAST((SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'discovery_sources') AS text),
         CASE WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'discovery_sources') > 0 THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'discovery_sources') > 0 THEN 'At least one policy exists for public.discovery_sources.' ELSE 'No RLS policy exists for public.discovery_sources.' END
  UNION ALL
  SELECT 'POLICY', 'public.businesses', 'rls_policy_exists', 'AT_LEAST_ONE_POLICY',
         CAST((SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'businesses') AS text),
         CASE WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'businesses') > 0 THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'businesses') > 0 THEN 'At least one policy exists for public.businesses.' ELSE 'No RLS policy exists for public.businesses.' END
  UNION ALL
  SELECT 'POLICY', 'public.prospects', 'rls_policy_exists', 'AT_LEAST_ONE_POLICY',
         CAST((SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'prospects') AS text),
         CASE WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'prospects') > 0 THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'prospects') > 0 THEN 'At least one policy exists for public.prospects.' ELSE 'No RLS policy exists for public.prospects.' END
  UNION ALL
  SELECT 'POLICY', 'public.workflow_assignments', 'policy_roles_match', 'authenticated_with_platform_admin_expression',
         COALESCE(array_to_string((SELECT ARRAY(SELECT DISTINCT unnest(roles) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'workflow_assignments')), ', '), 'NONE'),
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_policies
           WHERE schemaname = 'public'
             AND tablename = 'workflow_assignments'
             AND array_to_string(roles, ',') ILIKE '%authenticated%'
             AND (
               qual ILIKE '%current_user_is_platform_admin()%' OR
               qual ILIKE '%current_user_is_platform_admin %%' OR
               qual ILIKE '%current_user_is_platform_admin%' 
             )
         ) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_policies
           WHERE schemaname = 'public'
             AND tablename = 'workflow_assignments'
             AND array_to_string(roles, ',') ILIKE '%authenticated%'
             AND (
               qual ILIKE '%current_user_is_platform_admin()%' OR
               qual ILIKE '%current_user_is_platform_admin %%' OR
               qual ILIKE '%current_user_is_platform_admin%'
             )
         ) THEN 'Policy targets authenticated and uses the application platform-admin helper for public.workflow_assignments.' ELSE 'Workflow assignment policy does not target authenticated and prove application-level platform-admin authorization.' END
  UNION ALL
  SELECT 'PRIMARY_KEY', 'public.discovery_sources', 'primary_key_exists', 'pkey_present',
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'discovery_sources' AND c.contype = 'p') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'discovery_sources' AND c.contype = 'p') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'discovery_sources' AND c.contype = 'p') THEN 'Primary key exists on public.discovery_sources.' ELSE 'Primary key is missing on public.discovery_sources.' END
  UNION ALL
  SELECT 'PRIMARY_KEY', 'public.prospects', 'primary_key_exists', 'pkey_present',
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'prospects' AND c.contype = 'p') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'prospects' AND c.contype = 'p') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'prospects' AND c.contype = 'p') THEN 'Primary key exists on public.prospects.' ELSE 'Primary key is missing on public.prospects.' END
  UNION ALL
  SELECT 'PRIMARY_KEY', 'public.workflow_assignments', 'primary_key_exists', 'pkey_present',
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'workflow_assignments' AND c.contype = 'p') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'workflow_assignments' AND c.contype = 'p') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'workflow_assignments' AND c.contype = 'p') THEN 'Primary key exists on public.workflow_assignments.' ELSE 'Primary key is missing on public.workflow_assignments.' END
  UNION ALL
  SELECT 'FOREIGN_KEY', 'public.business_contacts.business_id', 'foreign_key_exists', 'fkey_present',
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'business_contacts' AND c.contype = 'f') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'business_contacts' AND c.contype = 'f') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'business_contacts' AND c.contype = 'f') THEN 'Foreign key exists on public.business_contacts.' ELSE 'Foreign key is missing on public.business_contacts.' END
  UNION ALL
  SELECT 'FOREIGN_KEY', 'public.prospects.discovery_source_id', 'foreign_key_exists', 'fkey_present',
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'prospects' AND c.contype = 'f') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'prospects' AND c.contype = 'f') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'prospects' AND c.contype = 'f') THEN 'Foreign key exists on public.prospects.' ELSE 'Foreign key is missing on public.prospects.' END
  UNION ALL
  SELECT 'FOREIGN_KEY', 'public.import_rows.import_job_id', 'foreign_key_exists', 'fkey_present',
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'import_rows' AND c.contype = 'f') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'import_rows' AND c.contype = 'f') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid WHERE cl.relname = 'import_rows' AND c.contype = 'f') THEN 'Foreign key exists on public.import_rows.' ELSE 'Foreign key is missing on public.import_rows.' END
  UNION ALL
  SELECT 'INDEX', 'public.businesses', 'required_index_exists', 'idx_businesses_d9_status',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'businesses' AND indexname = 'idx_businesses_d9_status') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'businesses' AND indexname = 'idx_businesses_d9_status') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'businesses' AND indexname = 'idx_businesses_d9_status') THEN 'Index idx_businesses_d9_status exists.' ELSE 'Index idx_businesses_d9_status is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.prospects', 'required_index_exists', 'idx_prospects_status',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'prospects' AND indexname = 'idx_prospects_status') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'prospects' AND indexname = 'idx_prospects_status') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'prospects' AND indexname = 'idx_prospects_status') THEN 'Index idx_prospects_status exists.' ELSE 'Index idx_prospects_status is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.workflow_assignments', 'required_index_exists', 'idx_workflow_assignments_entity',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'workflow_assignments' AND indexname = 'idx_workflow_assignments_entity') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'workflow_assignments' AND indexname = 'idx_workflow_assignments_entity') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'workflow_assignments' AND indexname = 'idx_workflow_assignments_entity') THEN 'Index idx_workflow_assignments_entity exists.' ELSE 'Index idx_workflow_assignments_entity is missing.' END
  UNION ALL
  SELECT 'QUICK_CAPTURE_DEPENDENCY', 'public.prospects', 'dependency_exists', 'EXISTS',
         CASE WHEN to_regclass('public.prospects') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.prospects') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.prospects') IS NOT NULL THEN 'public.prospects is available for Quick Capture.' ELSE 'public.prospects is missing for Quick Capture.' END
  UNION ALL
  SELECT 'QUICK_CAPTURE_DEPENDENCY', 'public.workflow_events', 'dependency_exists', 'EXISTS',
         CASE WHEN to_regclass('public.workflow_events') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.workflow_events') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.workflow_events') IS NOT NULL THEN 'public.workflow_events is available for Quick Capture.' ELSE 'public.workflow_events is missing for Quick Capture.' END
  UNION ALL
  SELECT 'QUICK_CAPTURE_DEPENDENCY', 'public.prospect_source_events', 'dependency_exists', 'EXISTS',
         CASE WHEN to_regclass('public.prospect_source_events') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.prospect_source_events') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.prospect_source_events') IS NOT NULL THEN 'public.prospect_source_events is available for Quick Capture.' ELSE 'public.prospect_source_events is missing for Quick Capture.' END
  UNION ALL
  SELECT 'QUICK_CAPTURE_DEPENDENCY', 'public.workflow_assignments', 'dependency_exists', 'EXISTS',
         CASE WHEN to_regclass('public.workflow_assignments') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.workflow_assignments') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.workflow_assignments') IS NOT NULL THEN 'public.workflow_assignments is available for Quick Capture.' ELSE 'public.workflow_assignments is missing for Quick Capture.' END
  UNION ALL
  SELECT 'QUICK_CAPTURE_DEPENDENCY', 'public.opt_outs', 'dependency_exists', 'EXISTS',
         CASE WHEN to_regclass('public.opt_outs') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.opt_outs') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.opt_outs') IS NOT NULL THEN 'public.opt_outs is available for Quick Capture.' ELSE 'public.opt_outs is missing for Quick Capture.' END
  UNION ALL
  SELECT 'QUICK_CAPTURE_DEPENDENCY', 'public.audit_events', 'dependency_exists', 'EXISTS',
         CASE WHEN to_regclass('public.audit_events') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.audit_events') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.audit_events') IS NOT NULL THEN 'public.audit_events is available for Quick Capture.' ELSE 'public.audit_events is missing for Quick Capture.' END
  UNION ALL
  SELECT 'QUICK_CAPTURE_DEPENDENCY', 'public.user_role_assignments', 'dependency_exists', 'EXISTS',
         CASE WHEN to_regclass('public.user_role_assignments') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.user_role_assignments') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.user_role_assignments') IS NOT NULL THEN 'public.user_role_assignments is available for Quick Capture.' ELSE 'public.user_role_assignments is missing for Quick Capture.' END
  UNION ALL
  SELECT 'QUICK_CAPTURE_DEPENDENCY', 'public.roles', 'dependency_exists', 'EXISTS',
         CASE WHEN to_regclass('public.roles') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.roles') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.roles') IS NOT NULL THEN 'public.roles is available for Quick Capture.' ELSE 'public.roles is missing for Quick Capture.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.enforce_workflow_transition()', 'workflow_function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.enforce_workflow_transition()') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.enforce_workflow_transition()') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.enforce_workflow_transition()') IS NOT NULL THEN 'Workflow transition enforcement function exists.' ELSE 'Workflow transition enforcement function is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.record_workflow_transition()', 'workflow_function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.record_workflow_transition()') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.record_workflow_transition()') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.record_workflow_transition()') IS NOT NULL THEN 'Workflow audit function exists.' ELSE 'Workflow audit function is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.build_d9_match_candidate(text,uuid,text)', 'duplicate_management_function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.build_d9_match_candidate(text,uuid,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.build_d9_match_candidate(text,uuid,text)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.build_d9_match_candidate(text,uuid,text)') IS NOT NULL THEN 'Duplicate candidate function exists.' ELSE 'Duplicate candidate function is missing.' END
  UNION ALL
  SELECT 'SAFETY', 'milestone_2', 'no_ambiguous_null_results', 'NO_NULL',
         CASE WHEN EXISTS (
           SELECT 1
           FROM (
             SELECT category,
                    object_name,
                    check_name,
                    expected_result,
                    actual_result,
                    status
             FROM required_results
             WHERE category <> 'SAFETY'
               AND category <> 'OVERALL'
           ) substantive
           WHERE category IS NULL
              OR object_name IS NULL
              OR check_name IS NULL
              OR expected_result IS NULL
              OR actual_result IS NULL
              OR status IS NULL
         ) THEN 'NULL_FOUND' ELSE 'NO_NULL' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM (
             SELECT category,
                    object_name,
                    check_name,
                    expected_result,
                    actual_result,
                    status
             FROM required_results
             WHERE category <> 'SAFETY'
               AND category <> 'OVERALL'
           ) substantive
           WHERE category IS NULL
              OR object_name IS NULL
              OR check_name IS NULL
              OR expected_result IS NULL
              OR actual_result IS NULL
              OR status IS NULL
         ) THEN 'FAIL' ELSE 'PASS' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM (
             SELECT category,
                    object_name,
                    check_name,
                    expected_result,
                    actual_result,
                    status
             FROM required_results
             WHERE category <> 'SAFETY'
               AND category <> 'OVERALL'
           ) substantive
           WHERE category IS NULL
              OR object_name IS NULL
              OR check_name IS NULL
              OR expected_result IS NULL
              OR actual_result IS NULL
              OR status IS NULL
         ) THEN 'A required substantive verification field is NULL.' ELSE 'All required substantive verification fields are non-NULL.' END
),
substantive_rows AS (
  SELECT category, object_name, check_name, expected_result, actual_result, status, details
  FROM required_results
  WHERE category <> 'SAFETY'
    AND category <> 'OVERALL'
),
overall AS (
  SELECT 'OVERALL' AS category,
         'milestone_2' AS object_name,
         'milestone_2_verification' AS check_name,
         'All required checks pass' AS expected_result,
         CAST((COUNT(*) FILTER (WHERE status = 'PASS')) || ' PASS, ' || (COUNT(*) FILTER (WHERE status = 'FAIL')) || ' FAIL' AS text) AS actual_result,
         CASE WHEN COUNT(*) FILTER (WHERE status = 'FAIL') = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
         CASE WHEN COUNT(*) FILTER (WHERE status = 'FAIL') = 0 THEN 'Milestone 2 verification PASSED' ELSE 'Milestone 2 verification FAILED' END AS details
  FROM substantive_rows
),
final_result AS (
  SELECT * FROM substantive_rows
  UNION ALL
  SELECT * FROM required_results
  WHERE category = 'SAFETY'
  UNION ALL
  SELECT * FROM overall
)
SELECT category, object_name, check_name, expected_result, actual_result, status, details
FROM final_result
ORDER BY CASE WHEN category = 'OVERALL' THEN 1 ELSE 0 END, object_name, check_name;
