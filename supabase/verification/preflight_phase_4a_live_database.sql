BEGIN;

-- Phase 4A live database preflight
WITH checks AS (
  SELECT
    'TABLE'::text AS category,
    'public.registration_invitations'::text AS object_name,
    'table_exists'::text AS check_name,
    'EXISTS'::text AS expected_result,
    CASE WHEN to_regclass('public.registration_invitations') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END AS actual_result,
    CASE WHEN to_regclass('public.registration_invitations') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END AS status,
    CASE WHEN to_regclass('public.registration_invitations') IS NOT NULL THEN 'Release 3E registration invitations table is present.'::text ELSE 'Release 3E registration invitations table is missing.'::text END AS details
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.registration_handoffs'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.registration_handoffs') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.registration_handoffs') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.registration_handoffs') IS NOT NULL THEN 'Release 3E registration handoffs table is present.'::text ELSE 'Release 3E registration handoffs table is missing.'::text END
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.member_profile_links'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.member_profile_links') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.member_profile_links') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.member_profile_links') IS NOT NULL THEN 'Release 3E member profile links table is present.'::text ELSE 'Release 3E member profile links table is missing.'::text END
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.registration_journey_events'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.registration_journey_events') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.registration_journey_events') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.registration_journey_events') IS NOT NULL THEN 'Release 3E registration journey events table is present.'::text ELSE 'Release 3E registration journey events table is missing.'::text END
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.registration_match_candidates'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.registration_match_candidates') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.registration_match_candidates') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.registration_match_candidates') IS NOT NULL THEN 'Release 3E registration match candidates table is present.'::text ELSE 'Release 3E registration match candidates table is missing.'::text END
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.brilliant_directories_sync_events'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.brilliant_directories_sync_events') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.brilliant_directories_sync_events') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.brilliant_directories_sync_events') IS NOT NULL THEN 'Release 3E direct sync events table is present.'::text ELSE 'Release 3E direct sync events table is missing.'::text END
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.export_requests'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.export_requests') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.export_requests') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.export_requests') IS NOT NULL THEN 'Release 3F export requests table is present.'::text ELSE 'Release 3F export requests table is missing.'::text END
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.export_audit_events'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.export_audit_events') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.export_audit_events') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.export_audit_events') IS NOT NULL THEN 'Release 3F export audit events table is present.'::text ELSE 'Release 3F export audit events table is missing.'::text END
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.social_provider_connections'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.social_provider_connections') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.social_provider_connections') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.social_provider_connections') IS NOT NULL THEN 'Phase 4A provider connections table is present.'::text ELSE 'Phase 4A provider connections table is missing.'::text END
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.social_provider_destinations'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.social_provider_destinations') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.social_provider_destinations') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.social_provider_destinations') IS NOT NULL THEN 'Phase 4A provider destinations table is present.'::text ELSE 'Phase 4A provider destinations table is missing.'::text END
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.social_provider_capabilities'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.social_provider_capabilities') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.social_provider_capabilities') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.social_provider_capabilities') IS NOT NULL THEN 'Phase 4A provider capabilities table is present.'::text ELSE 'Phase 4A provider capabilities table is missing.'::text END
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.social_publishing_jobs'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.social_publishing_jobs') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.social_publishing_jobs') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.social_publishing_jobs') IS NOT NULL THEN 'Phase 4A publishing jobs table is present.'::text ELSE 'Phase 4A publishing jobs table is missing.'::text END
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.social_publishing_attempts'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.social_publishing_attempts') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.social_publishing_attempts') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.social_publishing_attempts') IS NOT NULL THEN 'Phase 4A publishing attempts table is present.'::text ELSE 'Phase 4A publishing attempts table is missing.'::text END
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.social_provider_events'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.social_provider_events') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.social_provider_events') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.social_provider_events') IS NOT NULL THEN 'Phase 4A provider events table is present.'::text ELSE 'Phase 4A provider events table is missing.'::text END
  UNION ALL
  SELECT
    'TABLE'::text,
    'public.social_provider_health_events'::text,
    'table_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regclass('public.social_provider_health_events') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regclass('public.social_provider_health_events') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regclass('public.social_provider_health_events') IS NOT NULL THEN 'Phase 4A provider health events table is present.'::text ELSE 'Phase 4A provider health events table is missing.'::text END
  UNION ALL
  SELECT
    'FUNCTION'::text,
    'public.current_user_can_manage_social_connections()'::text,
    'function_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regprocedure('public.current_user_can_manage_social_connections()') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regprocedure('public.current_user_can_manage_social_connections()') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regprocedure('public.current_user_can_manage_social_connections()') IS NOT NULL THEN 'Social connection permission gate exists.'::text ELSE 'Social connection permission gate is missing.'::text END
  UNION ALL
  SELECT
    'FUNCTION'::text,
    'public.enforce_social_connection_state()'::text,
    'function_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regprocedure('public.enforce_social_connection_state()') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regprocedure('public.enforce_social_connection_state()') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regprocedure('public.enforce_social_connection_state()') IS NOT NULL THEN 'Connection-state enforcement exists.'::text ELSE 'Connection-state enforcement is missing.'::text END
  UNION ALL
  SELECT
    'FUNCTION'::text,
    'public.enforce_social_publishing_job_transition()'::text,
    'function_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regprocedure('public.enforce_social_publishing_job_transition()') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regprocedure('public.enforce_social_publishing_job_transition()') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regprocedure('public.enforce_social_publishing_job_transition()') IS NOT NULL THEN 'Publishing transition enforcement exists.'::text ELSE 'Publishing transition enforcement is missing.'::text END
  UNION ALL
  SELECT
    'FUNCTION'::text,
    'public.record_social_publishing_attempt()'::text,
    'function_exists'::text,
    'EXISTS'::text,
    CASE WHEN to_regprocedure('public.record_social_publishing_attempt()') IS NOT NULL THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN to_regprocedure('public.record_social_publishing_attempt()') IS NOT NULL THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN to_regprocedure('public.record_social_publishing_attempt()') IS NOT NULL THEN 'Publishing attempt guard exists.'::text ELSE 'Publishing attempt guard is missing.'::text END
  UNION ALL
  SELECT
    'TRIGGER'::text,
    'social_provider_connections_state_guard'::text,
    'trigger_exists'::text,
    'EXISTS'::text,
    CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_provider_connections_state_guard') THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_provider_connections_state_guard') THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_provider_connections_state_guard') THEN 'Connection trigger guard is present.'::text ELSE 'Connection trigger guard is missing.'::text END
  UNION ALL
  SELECT
    'TRIGGER'::text,
    'social_publishing_jobs_state_guard'::text,
    'trigger_exists'::text,
    'EXISTS'::text,
    CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_publishing_jobs_state_guard') THEN 'EXISTS'::text ELSE 'MISSING'::text END,
    CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_publishing_jobs_state_guard') THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'social_publishing_jobs_state_guard') THEN 'Publishing job trigger guard is present.'::text ELSE 'Publishing job trigger guard is missing.'::text END
  UNION ALL
  SELECT
    'RLS'::text,
    'public.social_provider_connections'::text,
    'rls_enabled'::text,
    'TRUE'::text,
    CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_provider_connections'::regclass) THEN 'TRUE'::text ELSE 'FALSE'::text END,
    CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_provider_connections'::regclass) THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_provider_connections'::regclass) THEN 'RLS enabled for social provider connections.'::text ELSE 'RLS is not enabled for social provider connections.'::text END
  UNION ALL
  SELECT
    'RLS'::text,
    'public.social_publishing_jobs'::text,
    'rls_enabled'::text,
    'TRUE'::text,
    CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_publishing_jobs'::regclass) THEN 'TRUE'::text ELSE 'FALSE'::text END,
    CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_publishing_jobs'::regclass) THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.social_publishing_jobs'::regclass) THEN 'RLS enabled for social publishing jobs.'::text ELSE 'RLS is not enabled for social publishing jobs.'::text END
  UNION ALL
  SELECT
    'POLICY'::text,
    'public.social_provider_connections'::text,
    'policy_presence'::text,
    'PRESENT'::text,
    CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'social_provider_connections') THEN 'PRESENT'::text ELSE 'MISSING'::text END,
    CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'social_provider_connections') THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'social_provider_connections') THEN 'Provider connection policies are present.'::text ELSE 'Provider connection policies are missing.'::text END
  UNION ALL
  SELECT
    'POLICY'::text,
    'public.social_publishing_jobs'::text,
    'policy_presence'::text,
    'PRESENT'::text,
    CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'social_publishing_jobs') THEN 'PRESENT'::text ELSE 'MISSING'::text END,
    CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'social_publishing_jobs') THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'social_publishing_jobs') THEN 'Publishing job policies are present.'::text ELSE 'Publishing job policies are missing.'::text END
  UNION ALL
  SELECT
    'SAFETY'::text,
    'public.social_provider_connections'::text,
    'no_client_secret_fields'::text,
    'NO_SECRET_FIELDS'::text,
    CASE WHEN EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'social_provider_connections'
        AND column_name IN ('provider_access_token', 'provider_app_secret', 'webhook_secret')
    ) THEN 'SECRET_FIELDS_PRESENT'::text ELSE 'NO_SECRET_FIELDS'::text END,
    CASE WHEN NOT EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'social_provider_connections'
        AND column_name IN ('provider_access_token', 'provider_app_secret', 'webhook_secret')
    ) THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN NOT EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'social_provider_connections'
        AND column_name IN ('provider_access_token', 'provider_app_secret', 'webhook_secret')
    ) THEN 'No provider secret columns are stored in the database table.'::text ELSE 'Provider secret columns are present in the table definition and should be removed from the live schema.'::text END
  UNION ALL
  SELECT
    'SAFETY'::text,
    'public.social_provider_events'::text,
    'raw_payload_not_enforced'::text,
    'SAFE_NORMALIZATION'::text,
    CASE WHEN EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'social_provider_events'
        AND column_name = 'raw_payload'
    ) THEN 'RAW_PAYLOAD_PRESENT'::text ELSE 'MISSING_RAW_PAYLOAD'::text END,
    CASE WHEN EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'social_provider_events'
        AND column_name = 'raw_payload'
    ) THEN 'PASS'::text ELSE 'FAIL'::text END,
    CASE WHEN EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'social_provider_events'
        AND column_name = 'raw_payload'
    ) THEN 'Raw provider payload is preserved as a normalized event record in a controlled table.'::text ELSE 'Raw payload column is absent; the database is not storing provider secrets in a raw form.'::text END
),
overall_summary AS (
  SELECT
    'SUMMARY'::text AS category,
    'phase_4a_live_database_preflight'::text AS object_name,
    'overall_status'::text AS check_name,
    CASE
      WHEN NOT (
        to_regclass('public.registration_invitations') IS NOT NULL
        AND to_regclass('public.registration_handoffs') IS NOT NULL
        AND to_regclass('public.member_profile_links') IS NOT NULL
        AND to_regclass('public.registration_journey_events') IS NOT NULL
        AND to_regclass('public.registration_match_candidates') IS NOT NULL
        AND to_regclass('public.brilliant_directories_sync_events') IS NOT NULL
      ) THEN 'BLOCKED_MISSING_3E'::text
      WHEN NOT (
        to_regclass('public.export_requests') IS NOT NULL
        AND to_regclass('public.export_audit_events') IS NOT NULL
      ) THEN 'BLOCKED_MISSING_3F'::text
      WHEN (
        to_regclass('public.social_provider_connections') IS NOT NULL
        OR to_regclass('public.social_provider_destinations') IS NOT NULL
        OR to_regclass('public.social_provider_capabilities') IS NOT NULL
        OR to_regclass('public.social_publishing_jobs') IS NOT NULL
        OR to_regclass('public.social_publishing_attempts') IS NOT NULL
        OR to_regclass('public.social_provider_events') IS NOT NULL
        OR to_regclass('public.social_provider_health_events') IS NOT NULL
      ) AND NOT (
        to_regclass('public.social_provider_connections') IS NOT NULL
        AND to_regclass('public.social_provider_destinations') IS NOT NULL
        AND to_regclass('public.social_provider_capabilities') IS NOT NULL
        AND to_regclass('public.social_publishing_jobs') IS NOT NULL
        AND to_regclass('public.social_publishing_attempts') IS NOT NULL
        AND to_regclass('public.social_provider_events') IS NOT NULL
        AND to_regclass('public.social_provider_health_events') IS NOT NULL
      ) THEN 'BLOCKED_PARTIAL_4A'::text
      WHEN (
        to_regclass('public.social_provider_connections') IS NOT NULL
        AND to_regclass('public.social_provider_destinations') IS NOT NULL
        AND to_regclass('public.social_provider_capabilities') IS NOT NULL
        AND to_regclass('public.social_publishing_jobs') IS NOT NULL
        AND to_regclass('public.social_publishing_attempts') IS NOT NULL
        AND to_regclass('public.social_provider_events') IS NOT NULL
        AND to_regclass('public.social_provider_health_events') IS NOT NULL
      ) THEN '4A_ALREADY_APPLIED_RUN_VERIFIER'::text
      WHEN (
        to_regclass('public.registration_invitations') IS NOT NULL
        AND to_regclass('public.registration_handoffs') IS NOT NULL
        AND to_regclass('public.member_profile_links') IS NOT NULL
        AND to_regclass('public.registration_journey_events') IS NOT NULL
        AND to_regclass('public.registration_match_candidates') IS NOT NULL
        AND to_regclass('public.brilliant_directories_sync_events') IS NOT NULL
        AND to_regclass('public.export_requests') IS NOT NULL
        AND to_regclass('public.export_audit_events') IS NOT NULL
      ) THEN 'READY_TO_APPLY_4A'::text
      ELSE 'BLOCKED_OTHER_DEPENDENCY'::text
    END AS expected_result,
    CASE
      WHEN NOT (
        to_regclass('public.registration_invitations') IS NOT NULL
        AND to_regclass('public.registration_handoffs') IS NOT NULL
        AND to_regclass('public.member_profile_links') IS NOT NULL
        AND to_regclass('public.registration_journey_events') IS NOT NULL
        AND to_regclass('public.registration_match_candidates') IS NOT NULL
        AND to_regclass('public.brilliant_directories_sync_events') IS NOT NULL
      ) THEN 'BLOCKED_MISSING_3E'::text
      WHEN NOT (
        to_regclass('public.export_requests') IS NOT NULL
        AND to_regclass('public.export_audit_events') IS NOT NULL
      ) THEN 'BLOCKED_MISSING_3F'::text
      WHEN (
        to_regclass('public.social_provider_connections') IS NOT NULL
        OR to_regclass('public.social_provider_destinations') IS NOT NULL
        OR to_regclass('public.social_provider_capabilities') IS NOT NULL
        OR to_regclass('public.social_publishing_jobs') IS NOT NULL
        OR to_regclass('public.social_publishing_attempts') IS NOT NULL
        OR to_regclass('public.social_provider_events') IS NOT NULL
        OR to_regclass('public.social_provider_health_events') IS NOT NULL
      ) AND NOT (
        to_regclass('public.social_provider_connections') IS NOT NULL
        AND to_regclass('public.social_provider_destinations') IS NOT NULL
        AND to_regclass('public.social_provider_capabilities') IS NOT NULL
        AND to_regclass('public.social_publishing_jobs') IS NOT NULL
        AND to_regclass('public.social_publishing_attempts') IS NOT NULL
        AND to_regclass('public.social_provider_events') IS NOT NULL
        AND to_regclass('public.social_provider_health_events') IS NOT NULL
      ) THEN 'BLOCKED_PARTIAL_4A'::text
      WHEN (
        to_regclass('public.social_provider_connections') IS NOT NULL
        AND to_regclass('public.social_provider_destinations') IS NOT NULL
        AND to_regclass('public.social_provider_capabilities') IS NOT NULL
        AND to_regclass('public.social_publishing_jobs') IS NOT NULL
        AND to_regclass('public.social_publishing_attempts') IS NOT NULL
        AND to_regclass('public.social_provider_events') IS NOT NULL
        AND to_regclass('public.social_provider_health_events') IS NOT NULL
      ) THEN '4A_ALREADY_APPLIED_RUN_VERIFIER'::text
      WHEN (
        to_regclass('public.registration_invitations') IS NOT NULL
        AND to_regclass('public.registration_handoffs') IS NOT NULL
        AND to_regclass('public.member_profile_links') IS NOT NULL
        AND to_regclass('public.registration_journey_events') IS NOT NULL
        AND to_regclass('public.registration_match_candidates') IS NOT NULL
        AND to_regclass('public.brilliant_directories_sync_events') IS NOT NULL
        AND to_regclass('public.export_requests') IS NOT NULL
        AND to_regclass('public.export_audit_events') IS NOT NULL
      ) THEN 'READY_TO_APPLY_4A'::text
      ELSE 'BLOCKED_OTHER_DEPENDENCY'::text
    END AS actual_result,
    CASE
      WHEN NOT (
        to_regclass('public.registration_invitations') IS NOT NULL
        AND to_regclass('public.registration_handoffs') IS NOT NULL
        AND to_regclass('public.member_profile_links') IS NOT NULL
        AND to_regclass('public.registration_journey_events') IS NOT NULL
        AND to_regclass('public.registration_match_candidates') IS NOT NULL
        AND to_regclass('public.brilliant_directories_sync_events') IS NOT NULL
      ) THEN 'BLOCKED_MISSING_3E'::text
      WHEN NOT (
        to_regclass('public.export_requests') IS NOT NULL
        AND to_regclass('public.export_audit_events') IS NOT NULL
      ) THEN 'BLOCKED_MISSING_3F'::text
      WHEN (
        to_regclass('public.social_provider_connections') IS NOT NULL
        OR to_regclass('public.social_provider_destinations') IS NOT NULL
        OR to_regclass('public.social_provider_capabilities') IS NOT NULL
        OR to_regclass('public.social_publishing_jobs') IS NOT NULL
        OR to_regclass('public.social_publishing_attempts') IS NOT NULL
        OR to_regclass('public.social_provider_events') IS NOT NULL
        OR to_regclass('public.social_provider_health_events') IS NOT NULL
      ) AND NOT (
        to_regclass('public.social_provider_connections') IS NOT NULL
        AND to_regclass('public.social_provider_destinations') IS NOT NULL
        AND to_regclass('public.social_provider_capabilities') IS NOT NULL
        AND to_regclass('public.social_publishing_jobs') IS NOT NULL
        AND to_regclass('public.social_publishing_attempts') IS NOT NULL
        AND to_regclass('public.social_provider_events') IS NOT NULL
        AND to_regclass('public.social_provider_health_events') IS NOT NULL
      ) THEN 'BLOCKED_PARTIAL_4A'::text
      WHEN (
        to_regclass('public.social_provider_connections') IS NOT NULL
        AND to_regclass('public.social_provider_destinations') IS NOT NULL
        AND to_regclass('public.social_provider_capabilities') IS NOT NULL
        AND to_regclass('public.social_publishing_jobs') IS NOT NULL
        AND to_regclass('public.social_publishing_attempts') IS NOT NULL
        AND to_regclass('public.social_provider_events') IS NOT NULL
        AND to_regclass('public.social_provider_health_events') IS NOT NULL
      ) THEN '4A_ALREADY_APPLIED_RUN_VERIFIER'::text
      WHEN (
        to_regclass('public.registration_invitations') IS NOT NULL
        AND to_regclass('public.registration_handoffs') IS NOT NULL
        AND to_regclass('public.member_profile_links') IS NOT NULL
        AND to_regclass('public.registration_journey_events') IS NOT NULL
        AND to_regclass('public.registration_match_candidates') IS NOT NULL
        AND to_regclass('public.brilliant_directories_sync_events') IS NOT NULL
        AND to_regclass('public.export_requests') IS NOT NULL
        AND to_regclass('public.export_audit_events') IS NOT NULL
      ) THEN 'READY_TO_APPLY_4A'::text
      ELSE 'BLOCKED_OTHER_DEPENDENCY'::text
    END AS status,
    CASE
      WHEN NOT (
        to_regclass('public.registration_invitations') IS NOT NULL
        AND to_regclass('public.registration_handoffs') IS NOT NULL
        AND to_regclass('public.member_profile_links') IS NOT NULL
        AND to_regclass('public.registration_journey_events') IS NOT NULL
        AND to_regclass('public.registration_match_candidates') IS NOT NULL
        AND to_regclass('public.brilliant_directories_sync_events') IS NOT NULL
      ) THEN 'Required Milestone 3E registration and sync tables are missing before applying Phase 4A.'::text
      WHEN NOT (
        to_regclass('public.export_requests') IS NOT NULL
        AND to_regclass('public.export_audit_events') IS NOT NULL
      ) THEN 'Required Milestone 3F export and audit tables are missing before applying Phase 4A.'::text
      WHEN (
        to_regclass('public.social_provider_connections') IS NOT NULL
        OR to_regclass('public.social_provider_destinations') IS NOT NULL
        OR to_regclass('public.social_provider_capabilities') IS NOT NULL
        OR to_regclass('public.social_publishing_jobs') IS NOT NULL
        OR to_regclass('public.social_publishing_attempts') IS NOT NULL
        OR to_regclass('public.social_provider_events') IS NOT NULL
        OR to_regclass('public.social_provider_health_events') IS NOT NULL
      ) AND NOT (
        to_regclass('public.social_provider_connections') IS NOT NULL
        AND to_regclass('public.social_provider_destinations') IS NOT NULL
        AND to_regclass('public.social_provider_capabilities') IS NOT NULL
        AND to_regclass('public.social_publishing_jobs') IS NOT NULL
        AND to_regclass('public.social_publishing_attempts') IS NOT NULL
        AND to_regclass('public.social_provider_events') IS NOT NULL
        AND to_regclass('public.social_provider_health_events') IS NOT NULL
      ) THEN 'Partial 4A state detected; stop and resolve the missing or incomplete 4A objects before proceeding.'::text
      WHEN (
        to_regclass('public.social_provider_connections') IS NOT NULL
        AND to_regclass('public.social_provider_destinations') IS NOT NULL
        AND to_regclass('public.social_provider_capabilities') IS NOT NULL
        AND to_regclass('public.social_publishing_jobs') IS NOT NULL
        AND to_regclass('public.social_publishing_attempts') IS NOT NULL
        AND to_regclass('public.social_provider_events') IS NOT NULL
        AND to_regclass('public.social_provider_health_events') IS NOT NULL
      ) THEN 'Phase 4A is already applied in the target database; run the verifier instead of the migration.'::text
      WHEN (
        to_regclass('public.registration_invitations') IS NOT NULL
        AND to_regclass('public.registration_handoffs') IS NOT NULL
        AND to_regclass('public.member_profile_links') IS NOT NULL
        AND to_regclass('public.registration_journey_events') IS NOT NULL
        AND to_regclass('public.registration_match_candidates') IS NOT NULL
        AND to_regclass('public.brilliant_directories_sync_events') IS NOT NULL
        AND to_regclass('public.export_requests') IS NOT NULL
        AND to_regclass('public.export_audit_events') IS NOT NULL
      ) THEN 'All required 3E and 3F dependency checks passed; ready to apply the Phase 4A migration.'::text
      ELSE 'Dependency state does not match the recognized Phase 4A safe-apply conditions.'::text
    END AS details
  FROM checks
)
SELECT category, object_name, check_name, expected_result, actual_result, status, details
FROM (
  SELECT * FROM checks
  UNION ALL
  SELECT * FROM overall_summary
) combined;

COMMIT;
