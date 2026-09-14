BEGIN;

WITH substantive_results AS (
  SELECT 'TABLE' AS category, 'public.security_role_matrix' AS object_name, 'table_exists' AS check_name,
         'EXISTS' AS expected_result,
         CASE WHEN to_regclass('public.security_role_matrix') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END AS actual_result,
         CASE WHEN to_regclass('public.security_role_matrix') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS status,
         CASE WHEN to_regclass('public.security_role_matrix') IS NOT NULL THEN 'public.security_role_matrix exists.' ELSE 'public.security_role_matrix is missing.' END AS details
  UNION ALL
  SELECT 'TABLE', 'public.export_audit_events', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.export_audit_events') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.export_audit_events') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.export_audit_events') IS NOT NULL THEN 'public.export_audit_events exists.' ELSE 'public.export_audit_events is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.security_role_matrix', 'role_matrix_index', 'PRESENT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'security_role_matrix' AND indexname = 'ux_security_role_matrix_permission') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'security_role_matrix' AND indexname = 'ux_security_role_matrix_permission') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'security_role_matrix' AND indexname = 'ux_security_role_matrix_permission') THEN 'Role-matrix index is present.' ELSE 'Role-matrix index is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.export_audit_events', 'export_audit_actor_index', 'PRESENT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'export_audit_events' AND indexname = 'idx_export_audit_events_actor') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'export_audit_events' AND indexname = 'idx_export_audit_events_actor') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'export_audit_events' AND indexname = 'idx_export_audit_events_actor') THEN 'Export audit actor index is present.' ELSE 'Export audit actor index is missing.' END
  UNION ALL
  SELECT 'RLS', 'public.security_role_matrix', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.security_role_matrix'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.security_role_matrix'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.security_role_matrix'::regclass) THEN 'RLS is enabled on public.security_role_matrix.' ELSE 'RLS is not enabled on public.security_role_matrix.' END
  UNION ALL
  SELECT 'RLS', 'public.export_audit_events', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.export_audit_events'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.export_audit_events'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.export_audit_events'::regclass) THEN 'RLS is enabled on public.export_audit_events.' ELSE 'RLS is not enabled on public.export_audit_events.' END
  UNION ALL
  SELECT 'POLICY', 'public.security_role_matrix', 'select_policy', 'SELECT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'security_role_matrix' AND cmd = 'SELECT') THEN 'SELECT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'security_role_matrix' AND cmd = 'SELECT') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'security_role_matrix' AND cmd = 'SELECT') THEN 'Read policy exists for security role matrix.' ELSE 'Read policy is missing for security role matrix.' END
  UNION ALL
  SELECT 'POLICY', 'public.export_audit_events', 'select_policy', 'SELECT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'export_audit_events' AND cmd = 'SELECT') THEN 'SELECT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'export_audit_events' AND cmd = 'SELECT') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'export_audit_events' AND cmd = 'SELECT') THEN 'Read policy exists for export audit events.' ELSE 'Read policy is missing for export audit events.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.assert_security_role_matrix(text,text,text)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.assert_security_role_matrix(text,text,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.assert_security_role_matrix(text,text,text)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.assert_security_role_matrix(text,text,text)') IS NOT NULL THEN 'Security role matrix function exists.' ELSE 'Security role matrix function is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.record_export_audit_event(text,text,text,text,text,integer,uuid,uuid,text,text,jsonb)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.record_export_audit_event(text,text,text,text,text,integer,uuid,uuid,text,text,jsonb)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.record_export_audit_event(text,text,text,text,text,integer,uuid,uuid,text,text,jsonb)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.record_export_audit_event(text,text,text,text,text,integer,uuid,uuid,text,text,jsonb)') IS NOT NULL THEN 'Export audit event function exists.' ELSE 'Export audit event function is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.record_export_download_event(uuid,uuid,timestamptz,text)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.record_export_download_event(uuid,uuid,timestamptz,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.record_export_download_event(uuid,uuid,timestamptz,text)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.record_export_download_event(uuid,uuid,timestamptz,text)') IS NOT NULL THEN 'Export download audit function exists.' ELSE 'Export download audit function is missing.' END
  UNION ALL
  SELECT 'SECURITY', 'public.security_role_matrix', 'role_matrix_guardrails', 'ROLE_MATRIX',
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_proc p
           WHERE p.proname = 'assert_security_role_matrix'
             AND position('public.current_user_is_platform_admin()' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
             AND position('manage_security' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
         ) THEN 'ROLE_MATRIX' ELSE 'MISSING' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_proc p
           WHERE p.proname = 'assert_security_role_matrix'
             AND position('public.current_user_is_platform_admin()' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
             AND position('manage_security' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
         ) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_proc p
           WHERE p.proname = 'assert_security_role_matrix'
             AND position('public.current_user_is_platform_admin()' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
             AND position('manage_security' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
         ) THEN 'Role matrix guardrails are enforced by the canonical access assertion.' ELSE 'Role matrix guardrails are missing or too weak.' END
  UNION ALL
  SELECT 'EXPORT', 'public.export_audit_events', 'download_audit_guardrails', 'AUDIT',
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_proc p
           WHERE p.proname = 'record_export_audit_event'
             AND position('public.current_user_is_platform_admin()' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
             AND position('public.user_has_permission(''manage_security'')' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
             AND position('p_export_status' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
         ) THEN 'AUDIT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_proc p
           WHERE p.proname = 'record_export_audit_event'
             AND position('public.current_user_is_platform_admin()' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
             AND position('public.user_has_permission(''manage_security'')' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
             AND position('p_export_status' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
         ) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_proc p
           WHERE p.proname = 'record_export_audit_event'
             AND position('public.current_user_is_platform_admin()' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
             AND position('public.user_has_permission(''manage_security'')' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
             AND position('p_export_status' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
         ) THEN 'Export generation and download auditing are recorded with platform/security access enforcement.' ELSE 'Export generation and download auditing are not constrained by the approved gate.' END
), all_results AS (
  SELECT category, object_name, check_name, expected_result, actual_result, status, details FROM substantive_results
), overall_result AS (
  SELECT 'OVERALL' AS category,
         'release_3f_security_live_acceptance' AS object_name,
         'overall_status' AS check_name,
         'All required checks pass' AS expected_result,
         CAST(COALESCE(COUNT(*) FILTER (WHERE status = 'PASS'), 0) || ' PASS, ' || COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) || ' FAIL' AS text) AS actual_result,
         CASE WHEN COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
         CASE WHEN COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) = 0 THEN 'Release 3F security and live acceptance verification PASSED' ELSE 'Release 3F security and live acceptance verification FAILED' END AS details
  FROM all_results
)
SELECT category, object_name, check_name, expected_result, actual_result, status, details
FROM (
  SELECT category, object_name, check_name, expected_result, actual_result, status, details FROM all_results
  UNION ALL
  SELECT category, object_name, check_name, expected_result, actual_result, status, details FROM overall_result
) wrapped_results
ORDER BY CASE WHEN category = 'OVERALL' THEN 1 ELSE 0 END, object_name, check_name;

COMMIT;
