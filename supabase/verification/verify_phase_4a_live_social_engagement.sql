BEGIN;

WITH checks AS (
  SELECT
    'TABLE'::text AS category,
    'public.social_provider_connections'::text AS object_name,
    'table_exists'::text AS check_name,
    'EXISTS'::text AS expected_result,
    CASE WHEN to_regclass('public.social_provider_connections') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END AS actual_result,
    CASE WHEN to_regclass('public.social_provider_connections') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END AS status,
    CASE WHEN to_regclass('public.social_provider_connections') IS NOT NULL THEN 'Provider connections table exists.'::text ELSE 'Provider connections table is missing.'::text END AS details
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.social_provider_destinations'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.social_provider_destinations') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.social_provider_destinations') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.social_provider_destinations') IS NOT NULL THEN 'Provider destinations table exists.'::text ELSE 'Provider destinations table is missing.'::text END
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.social_publishing_jobs'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.social_publishing_jobs') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.social_publishing_jobs') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.social_publishing_jobs') IS NOT NULL THEN 'Publishing jobs table exists.'::text ELSE 'Publishing jobs table is missing.'::text END
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.social_provider_events'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.social_provider_events') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.social_provider_events') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.social_provider_events') IS NOT NULL THEN 'Webhook events table exists.'::text ELSE 'Webhook events table is missing.'::text END
  UNION ALL
  SELECT
    'FUNCTION'::text,
    'public.enforce_social_connection_state()'::text,
    'function_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regprocedure('public.enforce_social_connection_state()') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regprocedure('public.enforce_social_connection_state()') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regprocedure('public.enforce_social_connection_state()') IS NOT NULL THEN 'Social connection state guard exists.'::text ELSE 'Social connection state guard is missing.'::text END
  UNION ALL
  SELECT
    'FUNCTION'::text,
    'public.enforce_social_publishing_job_transition()'::text,
    'function_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regprocedure('public.enforce_social_publishing_job_transition()') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regprocedure('public.enforce_social_publishing_job_transition()') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regprocedure('public.enforce_social_publishing_job_transition()') IS NOT NULL THEN 'Publishing job transition guard exists.'::text ELSE 'Publishing job transition guard is missing.'::text END
  UNION ALL
  SELECT
    'FUNCTION'::text,
    'public.record_social_publishing_attempt()'::text,
    'function_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regprocedure('public.record_social_publishing_attempt()') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regprocedure('public.record_social_publishing_attempt()') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regprocedure('public.record_social_publishing_attempt()') IS NOT NULL THEN 'Publishing attempt recording guard exists.'::text ELSE 'Publishing attempt guard is missing.'::text END
  UNION ALL
  SELECT
    'TRIGGER'::text,
    'social_provider_connections_state_guard'::text,
    'trigger_exists'::text,
    'EXISTS'::text,
    CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_provider_connections_state_guard') THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_provider_connections_state_guard') THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_provider_connections_state_guard') THEN 'Connection state trigger exists.'::text ELSE 'Connection state trigger is missing.'::text END
  UNION ALL
  SELECT
    'TRIGGER'::text,
    'social_publishing_jobs_state_guard'::text,
    'trigger_exists'::text,
    'EXISTS'::text,
    CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_publishing_jobs_state_guard') THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_publishing_jobs_state_guard') THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_publishing_jobs_state_guard') THEN 'Publishing job trigger exists.'::text ELSE 'Publishing job trigger is missing.'::text END
  UNION ALL
  SELECT
    'RLS'::text,
    'public.social_provider_connections'::text,
    'rls_enabled'::text,
    'TRUE'::text,
    CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_provider_connections'::regclass) THEN 'TRUE'::text ELSE 'FALSE'::text END,
    CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_provider_connections'::regclass) THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_provider_connections'::regclass) THEN 'RLS enabled on provider connections.'::text ELSE 'RLS not enabled on provider connections.'::text END
  UNION ALL
  SELECT
    'RLS'::text,
    'public.social_publishing_jobs'::text,
    'rls_enabled'::text,
    'TRUE'::text,
    CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_publishing_jobs'::regclass) THEN 'TRUE'::text ELSE 'FALSE'::text END,
    CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_publishing_jobs'::regclass) THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_publishing_jobs'::regclass) THEN 'RLS enabled on publishing jobs.'::text ELSE 'RLS not enabled on publishing jobs.'::text END
  UNION ALL
  SELECT
    'SECURITY'::text,
    'public.current_user_can_manage_social_connections()'::text,
    'search_path_restricted'::text,
    'SET search_path'::text,
    CASE
      WHEN to_regprocedure('public.current_user_can_manage_social_connections()') IS NULL THEN 'MISSING'::text
      WHEN pg_get_functiondef(to_regprocedure('public.current_user_can_manage_social_connections()')) ILIKE '%SET search_path = public, auth, pg_catalog%' THEN 'SET search_path'::text
      ELSE 'UNCONSTRAINED'::text
    END AS actual_result,
    CASE
      WHEN to_regprocedure('public.current_user_can_manage_social_connections()') IS NULL THEN 'FAIL'::text
      WHEN pg_get_functiondef(to_regprocedure('public.current_user_can_manage_social_connections()')) ILIKE '%SET search_path = public, auth, pg_catalog%' THEN 'PASS'::text
      ELSE 'FAIL'::text
    END AS status,
    CASE
      WHEN to_regprocedure('public.current_user_can_manage_social_connections()') IS NULL THEN 'The social connection permission helper is missing.'::text
      WHEN pg_get_functiondef(to_regprocedure('public.current_user_can_manage_social_connections()')) ILIKE '%SET search_path = public, auth, pg_catalog%' THEN 'Function definition constrains search_path to public, auth, pg_catalog.'::text
      ELSE 'Function exists but does not show a safe, constrained search_path setting.'::text
    END AS details
  UNION ALL
  SELECT
    'POLICY'::text,
    'public.social_provider_connections'::text,
    'anonymous_denied'::text,
    'NO_ANON'::text,
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM pg_policies p
        WHERE p.schemaname = 'public'
          AND p.tablename = 'social_provider_connections'
          AND EXISTS (
            SELECT 1
            FROM unnest(p.roles) AS policy_role
            WHERE lower(policy_role) IN ('anon', 'public')
          )
      ) THEN 'ANON_PRESENT'::text
      ELSE 'NO_ANON'::text
    END AS actual_result,
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM pg_policies p
        WHERE p.schemaname = 'public'
          AND p.tablename = 'social_provider_connections'
          AND EXISTS (
            SELECT 1
            FROM unnest(p.roles) AS policy_role
            WHERE lower(policy_role) IN ('anon', 'public')
          )
      ) THEN 'FAIL'::text
      ELSE 'PASS'::text
    END AS status,
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM pg_policies p
        WHERE p.schemaname = 'public'
          AND p.tablename = 'social_provider_connections'
          AND EXISTS (
            SELECT 1
            FROM unnest(p.roles) AS policy_role
            WHERE lower(policy_role) IN ('anon', 'public')
          )
      ) THEN 'Anonymous/public roles are granted privileges on provider connections by policy rows.'::text
      ELSE 'No anonymous/public roles are granted provider connection privileges.'::text
    END AS details
  UNION ALL
  SELECT
    'DATA'::text,
    'public.social_publishing_jobs'::text,
    'approval_required'::text,
    'APPROVAL'::text,
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class cl ON cl.oid = c.conrelid
        WHERE cl.relname = 'social_publishing_jobs'
          AND c.contype = 'c'
          AND pg_get_constraintdef(c.oid) ILIKE '%approval_state%'
          AND pg_get_constraintdef(c.oid) ILIKE '%approved%'
      ) THEN 'APPROVAL'::text
      ELSE 'MISSING'::text
    END AS actual_result,
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class cl ON cl.oid = c.conrelid
        WHERE cl.relname = 'social_publishing_jobs'
          AND c.contype = 'c'
          AND pg_get_constraintdef(c.oid) ILIKE '%approval_state%'
          AND pg_get_constraintdef(c.oid) ILIKE '%approved%'
      ) THEN 'PASS'::text
      ELSE 'FAIL'::text
    END AS status,
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class cl ON cl.oid = c.conrelid
        WHERE cl.relname = 'social_publishing_jobs'
          AND c.contype = 'c'
          AND pg_get_constraintdef(c.oid) ILIKE '%approval_state%'
          AND pg_get_constraintdef(c.oid) ILIKE '%approved%'
      ) THEN 'Publishing job approval enforcement is represented in a schema constraint.'::text
      ELSE 'Approval requirements are not represented in the schema constraint set.'::text
    END AS details
),
summary AS (
  SELECT
    'OVERALL'::text AS category,
    'phase_4a_live_social_engagement_verification'::text AS object_name,
    'overall_status'::text AS check_name,
    '0 FAIL'::text AS expected_result,
    (CAST(COUNT(*) FILTER (WHERE status = 'PASS') AS text) || ' PASS, ' || CAST(COUNT(*) FILTER (WHERE status = 'FAIL') AS text) || ' FAIL')::text AS actual_result,
    CASE WHEN COUNT(*) FILTER (WHERE status = 'FAIL') = 0 THEN 'PASS'::text ELSE 'FAIL'::text END AS status,
    (CAST(COUNT(*) FILTER (WHERE status = 'PASS') AS text) || ' PASS, ' || CAST(COUNT(*) FILTER (WHERE status = 'FAIL') AS text) || ' FAIL')::text AS details
  FROM checks
)
SELECT category, object_name, check_name, expected_result, actual_result, status, details
FROM (
  SELECT * FROM checks
  UNION ALL
  SELECT * FROM summary
) combined;

ROLLBACK;
