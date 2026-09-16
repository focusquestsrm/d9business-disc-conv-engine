BEGIN;

WITH checks AS (
  SELECT 'TABLE' AS category, 'public.registration_invitations' AS object_name, 'table_exists' AS check_name,
         'EXISTS' AS expected_result,
         CASE WHEN to_regclass('public.registration_invitations') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END AS actual_result,
         CASE WHEN to_regclass('public.registration_invitations') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS status,
         CASE WHEN to_regclass('public.registration_invitations') IS NOT NULL THEN 'Release 3E registration invitations table is present.' ELSE 'Release 3E registration invitations table is missing.' END AS details
  UNION ALL
  SELECT 'TABLE', 'public.registration_handoffs', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.registration_handoffs') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.registration_handoffs') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.registration_handoffs') IS NOT NULL THEN 'Release 3E registration handoffs table is present.' ELSE 'Release 3E registration handoffs table is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.member_profile_links', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.member_profile_links') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.member_profile_links') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.member_profile_links') IS NOT NULL THEN 'Release 3E member profile links table is present.' ELSE 'Release 3E member profile links table is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.registration_journey_events', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.registration_journey_events') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.registration_journey_events') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.registration_journey_events') IS NOT NULL THEN 'Release 3E registration journey events table is present.' ELSE 'Release 3E registration journey events table is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.registration_match_candidates', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.registration_match_candidates') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.registration_match_candidates') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.registration_match_candidates') IS NOT NULL THEN 'Release 3E registration match candidates table is present.' ELSE 'Release 3E registration match candidates table is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.brilliant_directories_sync_events', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.brilliant_directories_sync_events') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.brilliant_directories_sync_events') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.brilliant_directories_sync_events') IS NOT NULL THEN 'Release 3E direct sync events table is present.' ELSE 'Release 3E direct sync events table is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.export_requests', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.export_requests') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.export_requests') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.export_requests') IS NOT NULL THEN 'Release 3F export requests table is present.' ELSE 'Release 3F export requests table is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.export_audit_events', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.export_audit_events') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.export_audit_events') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.export_audit_events') IS NOT NULL THEN 'Release 3F export audit events table is present.' ELSE 'Release 3F export audit events table is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.social_provider_connections', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.social_provider_connections') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.social_provider_connections') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.social_provider_connections') IS NOT NULL THEN 'Phase 4A provider connections table is present.' ELSE 'Phase 4A provider connections table is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.social_provider_destinations', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.social_provider_destinations') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.social_provider_destinations') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.social_provider_destinations') IS NOT NULL THEN 'Phase 4A provider destinations table is present.' ELSE 'Phase 4A provider destinations table is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.social_provider_capabilities', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.social_provider_capabilities') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.social_provider_capabilities') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.social_provider_capabilities') IS NOT NULL THEN 'Phase 4A provider capabilities table is present.' ELSE 'Phase 4A provider capabilities table is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.social_publishing_jobs', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.social_publishing_jobs') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.social_publishing_jobs') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.social_publishing_jobs') IS NOT NULL THEN 'Phase 4A publishing jobs table is present.' ELSE 'Phase 4A publishing jobs table is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.social_publishing_attempts', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.social_publishing_attempts') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.social_publishing_attempts') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.social_publishing_attempts') IS NOT NULL THEN 'Phase 4A publishing attempts table is present.' ELSE 'Phase 4A publishing attempts table is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.social_provider_events', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.social_provider_events') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.social_provider_events') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.social_provider_events') IS NOT NULL THEN 'Phase 4A provider events table is present.' ELSE 'Phase 4A provider events table is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.social_provider_health_events', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.social_provider_health_events') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.social_provider_health_events') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.social_provider_health_events') IS NOT NULL THEN 'Phase 4A provider health events table is present.' ELSE 'Phase 4A provider health events table is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.current_user_can_manage_social_connections()', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.current_user_can_manage_social_connections()') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.current_user_can_manage_social_connections()') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.current_user_can_manage_social_connections()') IS NOT NULL THEN 'Social connection permission gate exists.' ELSE 'Social connection permission gate is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.enforce_social_connection_state()', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.enforce_social_connection_state()') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.enforce_social_connection_state()') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.enforce_social_connection_state()') IS NOT NULL THEN 'Connection-state enforcement exists.' ELSE 'Connection-state enforcement is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.enforce_social_publishing_job_transition()', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.enforce_social_publishing_job_transition()') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.enforce_social_publishing_job_transition()') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.enforce_social_publishing_job_transition()') IS NOT NULL THEN 'Publishing transition enforcement exists.' ELSE 'Publishing transition enforcement is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.record_social_publishing_attempt()', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.record_social_publishing_attempt()') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.record_social_publishing_attempt()') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.record_social_publishing_attempt()') IS NOT NULL THEN 'Publishing attempt guard exists.' ELSE 'Publishing attempt guard is missing.' END
  UNION ALL
  SELECT 'TRIGGER', 'social_provider_connections_state_guard', 'trigger_exists', 'EXISTS',
         CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_provider_connections_state_guard') THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_provider_connections_state_guard') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_provider_connections_state_guard') THEN 'Connection trigger guard is present.' ELSE 'Connection trigger guard is missing.' END
  UNION ALL
  SELECT 'TRIGGER', 'social_publishing_jobs_state_guard', 'trigger_exists', 'EXISTS',
         CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_publishing_jobs_state_guard') THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_publishing_jobs_state_guard') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_publishing_jobs_state_guard') THEN 'Publishing job trigger guard is present.' ELSE 'Publishing job trigger guard is missing.' END
  UNION ALL
  SELECT 'RLS', 'public.social_provider_connections', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_provider_connections'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_provider_connections'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_provider_connections'::regclass) THEN 'RLS enabled for social provider connections.' ELSE 'RLS is not enabled for social provider connections.' END
  UNION ALL
  SELECT 'RLS', 'public.social_publishing_jobs', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_publishing_jobs'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_publishing_jobs'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_publishing_jobs'::regclass) THEN 'RLS enabled for social publishing jobs.' ELSE 'RLS is not enabled for social publishing jobs.' END
  UNION ALL
  SELECT 'POLICY', 'public.social_provider_connections', 'policy_presence', 'PRESENT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'social_provider_connections') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'social_provider_connections') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'social_provider_connections') THEN 'Provider connection policies are present.' ELSE 'Provider connection policies are missing.' END
  UNION ALL
  SELECT 'POLICY', 'public.social_publishing_jobs', 'policy_presence', 'PRESENT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'social_publishing_jobs') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'social_publishing_jobs') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'social_publishing_jobs') THEN 'Publishing job policies are present.' ELSE 'Publishing job policies are missing.' END
  UNION ALL
  SELECT 'SAFETY', 'public.social_provider_connections', 'no_client_secret_fields', 'NO_SECRET_FIELDS',
         CASE WHEN EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'social_provider_connections'
             AND column_name IN ('provider_access_token', 'provider_app_secret', 'webhook_secret')
         ) THEN 'SECRET_FIELDS_PRESENT' ELSE 'NO_SECRET_FIELDS' END,
         CASE WHEN NOT EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'social_provider_connections'
             AND column_name IN ('provider_access_token', 'provider_app_secret', 'webhook_secret')
         ) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN NOT EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'social_provider_connections'
             AND column_name IN ('provider_access_token', 'provider_app_secret', 'webhook_secret')
         ) THEN 'No provider secret columns are stored in the database table.' ELSE 'Provider secret columns are present in the table definition and should be removed from the live schema.' END
  UNION ALL
  SELECT 'SAFETY', 'public.social_provider_events', 'raw_payload_not_enforced', 'SAFE_NORMALIZATION',
         CASE WHEN EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'social_provider_events'
             AND column_name = 'raw_payload'
         ) THEN 'RAW_PAYLOAD_PRESENT' ELSE 'MISSING_RAW_PAYLOAD' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'social_provider_events'
             AND column_name = 'raw_payload'
         ) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'social_provider_events'
             AND column_name = 'raw_payload'
         ) THEN 'Raw provider payload is preserved as a normalized event record in a controlled table.' ELSE 'Raw payload column is absent; the database is not storing provider secrets in a raw form.' END
)
SELECT 'Phase 4A live database preflight' AS verification_name,
       CASE WHEN COUNT(*) FILTER (WHERE status = 'FAIL') = 0 THEN 'PASS' ELSE 'BLOCK' END AS overall_status,
       COUNT(*) FILTER (WHERE status = 'PASS') AS pass_count,
       COUNT(*) FILTER (WHERE status = 'FAIL') AS fail_count,
       MAX(CASE WHEN status = 'FAIL' THEN details END) AS blocking_failure
FROM checks;

COMMIT;
