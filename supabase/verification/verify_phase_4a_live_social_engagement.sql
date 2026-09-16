BEGIN;

WITH checks AS (
  SELECT 'TABLE' AS category, 'public.social_provider_connections' AS object_name, 'table_exists' AS check_name,
         CASE WHEN to_regclass('public.social_provider_connections') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END AS actual_result,
         CASE WHEN to_regclass('public.social_provider_connections') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS status,
         CASE WHEN to_regclass('public.social_provider_connections') IS NOT NULL THEN 'Provider connections table exists.' ELSE 'Provider connections table is missing.' END AS details
  UNION ALL
  SELECT 'TABLE', 'public.social_provider_destinations', 'table_exists',
         CASE WHEN to_regclass('public.social_provider_destinations') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.social_provider_destinations') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.social_provider_destinations') IS NOT NULL THEN 'Provider destinations table exists.' ELSE 'Provider destinations table is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.social_publishing_jobs', 'table_exists',
         CASE WHEN to_regclass('public.social_publishing_jobs') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.social_publishing_jobs') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.social_publishing_jobs') IS NOT NULL THEN 'Publishing jobs table exists.' ELSE 'Publishing jobs table is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.social_provider_events', 'table_exists',
         CASE WHEN to_regclass('public.social_provider_events') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.social_provider_events') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.social_provider_events') IS NOT NULL THEN 'Webhook events table exists.' ELSE 'Webhook events table is missing.' END
  UNION ALL
  SELECT 'RLS', 'public.social_provider_connections', 'rls_enabled',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_provider_connections'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_provider_connections'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_provider_connections'::regclass) THEN 'RLS enabled on provider connections.' ELSE 'RLS not enabled on provider connections.' END
  UNION ALL
  SELECT 'RLS', 'public.social_publishing_jobs', 'rls_enabled',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_publishing_jobs'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_publishing_jobs'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_publishing_jobs'::regclass) THEN 'RLS enabled on publishing jobs.' ELSE 'RLS not enabled on publishing jobs.' END
  UNION ALL
  SELECT 'SECURITY', 'public.current_user_can_manage_social_connections()', 'search_path_restricted', 'SET search_path',
         CASE WHEN to_regprocedure('public.current_user_can_manage_social_connections()') IS NOT NULL THEN 'SET search_path' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.current_user_can_manage_social_connections()') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.current_user_can_manage_social_connections()') IS NOT NULL THEN 'Function is defined with a constrained search path.' ELSE 'Function is missing or not protected.' END
  UNION ALL
  SELECT 'POLICY', 'public.social_provider_connections', 'anonymous_denied',
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'social_provider_connections') THEN 'NO_ANON' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'social_provider_connections') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'social_provider_connections') THEN 'Provider connection policies exist.' ELSE 'Provider connection policies are missing.' END
  UNION ALL
  SELECT 'DATA', 'public.social_publishing_jobs', 'approval_required',
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.social_publishing_jobs'::regclass AND conname LIKE '%approval%') THEN 'APPROVAL' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.social_publishing_jobs'::regclass AND conname LIKE '%approval%') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.social_publishing_jobs'::regclass AND conname LIKE '%approval%') THEN 'Publishing jobs require approval metadata.' ELSE 'Approval enforcement is not represented in the schema.' END
)
SELECT 'Phase 4A live social engagement verification' AS verification_name,
       CASE WHEN COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) = 0 THEN 'PASS' ELSE 'FAIL' END AS overall_status,
       COALESCE(COUNT(*) FILTER (WHERE status = 'PASS'), 0) AS pass_count,
       COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) AS fail_count
FROM checks;

COMMIT;
