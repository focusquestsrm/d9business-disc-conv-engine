BEGIN;

WITH substantive_results AS (
  SELECT 'TABLE' AS category, 'public.export_requests' AS object_name, 'table_exists' AS check_name,
         'EXISTS' AS expected_result,
         CASE WHEN to_regclass('public.export_requests') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END AS actual_result,
         CASE WHEN to_regclass('public.export_requests') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS status,
         CASE WHEN to_regclass('public.export_requests') IS NOT NULL THEN 'public.export_requests exists.' ELSE 'public.export_requests is missing.' END AS details
  UNION ALL
  SELECT 'TABLE', 'public.export_audit_events', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.export_audit_events') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.export_audit_events') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.export_audit_events') IS NOT NULL THEN 'public.export_audit_events exists.' ELSE 'public.export_audit_events is missing.' END
  UNION ALL
  SELECT 'RLS', 'public.export_requests', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.export_requests'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.export_requests'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.export_requests'::regclass) THEN 'RLS is enabled on public.export_requests.' ELSE 'RLS is not enabled on public.export_requests.' END
  UNION ALL
  SELECT 'RLS', 'public.export_audit_events', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.export_audit_events'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.export_audit_events'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.export_audit_events'::regclass) THEN 'RLS is enabled on public.export_audit_events.' ELSE 'RLS is not enabled on public.export_audit_events.' END
  UNION ALL
  SELECT 'POLICY', 'public.export_requests', 'insert_policy', 'INSERT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'export_requests' AND cmd = 'INSERT') THEN 'INSERT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'export_requests' AND cmd = 'INSERT') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'export_requests' AND cmd = 'INSERT') THEN 'Insert policy exists for export requests.' ELSE 'Insert policy is missing for export requests.' END
  UNION ALL
  SELECT 'POLICY', 'public.export_audit_events', 'insert_policy', 'INSERT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'export_audit_events' AND cmd = 'INSERT') THEN 'INSERT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'export_audit_events' AND cmd = 'INSERT') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'export_audit_events' AND cmd = 'INSERT') THEN 'Insert policy exists for export audit events.' ELSE 'Insert policy is missing for export audit events.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.create_export_request(text,text,uuid,text,timestamptz)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.create_export_request(text,text,uuid,text,timestamptz)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.create_export_request(text,text,uuid,text,timestamptz)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.create_export_request(text,text,uuid,text,timestamptz)') IS NOT NULL THEN 'Export request creation function exists.' ELSE 'Export request creation function is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.record_export_generation(uuid,text,text,integer,text,text)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.record_export_generation(uuid,text,text,integer,text,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.record_export_generation(uuid,text,text,integer,text,text)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.record_export_generation(uuid,text,text,integer,text,text)') IS NOT NULL THEN 'Export generation function exists.' ELSE 'Export generation function is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.record_export_download(uuid,text)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.record_export_download(uuid,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.record_export_download(uuid,text)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.record_export_download(uuid,text)') IS NOT NULL THEN 'Export download function exists.' ELSE 'Export download function is missing.' END
  UNION ALL
  SELECT 'SECURITY', 'public.create_export_request', 'no_client_actor_id', 'NO_CLIENT_ID',
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_proc p
           JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public'
             AND p.proname = 'create_export_request'
             AND pg_get_function_identity_arguments(p.oid) = 'text, text, uuid, text, timestamp with time zone'
             AND COALESCE(p.proargnames, ARRAY[]::text[]) = ARRAY[
               'p_resource_type',
               'p_export_scope',
               'p_target_tenant_id',
               'p_request_reason',
               'p_expires_at'
             ]
             AND 'p_actor_id' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'p_requested_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'p_generated_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'p_downloaded_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'actor_id' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'requested_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'generated_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'downloaded_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND position('auth.uid()' in regexp_replace(lower(COALESCE(p.prosrc, '')), '\s+', ' ', 'g')) > 0
             AND position('v_actor := auth.uid()' in regexp_replace(lower(COALESCE(p.prosrc, '')), '\s+', ' ', 'g')) > 0
             AND position('if v_actor is null' in regexp_replace(lower(COALESCE(p.prosrc, '')), '\s+', ' ', 'g')) > 0
             AND regexp_like(
               regexp_replace(lower(COALESCE(p.prosrc, '')), '\s+', ' ', 'g'),
               'insert\\s+into\\s+public\\.export_requests\\s*\\([^)]*requested_by[^)]*\\)\\s*values\\s*\\([^)]*p_target_tenant_id[^)]*v_actor[^)]*\\)'
             )
         ) THEN 'NO_CLIENT_ID' ELSE 'MISSING' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_proc p
           JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public'
             AND p.proname = 'create_export_request'
             AND pg_get_function_identity_arguments(p.oid) = 'text, text, uuid, text, timestamp with time zone'
             AND COALESCE(p.proargnames, ARRAY[]::text[]) = ARRAY[
               'p_resource_type',
               'p_export_scope',
               'p_target_tenant_id',
               'p_request_reason',
               'p_expires_at'
             ]
             AND 'p_actor_id' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'p_requested_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'p_generated_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'p_downloaded_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'actor_id' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'requested_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'generated_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'downloaded_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND position('auth.uid()' in regexp_replace(lower(COALESCE(p.prosrc, '')), '\s+', ' ', 'g')) > 0
             AND position('v_actor := auth.uid()' in regexp_replace(lower(COALESCE(p.prosrc, '')), '\s+', ' ', 'g')) > 0
             AND position('if v_actor is null' in regexp_replace(lower(COALESCE(p.prosrc, '')), '\s+', ' ', 'g')) > 0
             AND regexp_like(
               regexp_replace(lower(COALESCE(p.prosrc, '')), '\s+', ' ', 'g'),
               'insert\\s+into\\s+public\\.export_requests\\s*\\([^)]*requested_by[^)]*\\)\\s*values\\s*\\([^)]*p_target_tenant_id[^)]*v_actor[^)]*\\)'
             )
         ) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_proc p
           JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public'
             AND p.proname = 'create_export_request'
             AND pg_get_function_identity_arguments(p.oid) = 'text, text, uuid, text, timestamp with time zone'
             AND COALESCE(p.proargnames, ARRAY[]::text[]) = ARRAY[
               'p_resource_type',
               'p_export_scope',
               'p_target_tenant_id',
               'p_request_reason',
               'p_expires_at'
             ]
             AND 'p_actor_id' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'p_requested_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'p_generated_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'p_downloaded_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'actor_id' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'requested_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'generated_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND 'downloaded_by' <> ALL(COALESCE(p.proargnames, ARRAY[]::text[]))
             AND position('auth.uid()' in regexp_replace(lower(COALESCE(p.prosrc, '')), '\s+', ' ', 'g')) > 0
             AND position('v_actor := auth.uid()' in regexp_replace(lower(COALESCE(p.prosrc, '')), '\s+', ' ', 'g')) > 0
             AND position('if v_actor is null' in regexp_replace(lower(COALESCE(p.prosrc, '')), '\s+', ' ', 'g')) > 0
             AND regexp_like(
               regexp_replace(lower(COALESCE(p.prosrc, '')), '\s+', ' ', 'g'),
               'insert\\s+into\\s+public\\.export_requests\\s*\\([^)]*requested_by[^)]*\\)\\s*values\\s*\\([^)]*p_target_tenant_id[^)]*v_actor[^)]*\\)'
             )
         ) THEN 'The request function derives the actor from auth.uid(), rejects anonymous callers, asserts authorization, and writes requested_by from the authenticated actor.' ELSE 'The request function still permits a client-supplied actor ID.' END
  UNION ALL
  SELECT 'SECURITY', 'public.record_export_download', 'no_client_actor_id', 'NO_CLIENT_ID',
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_proc p
           WHERE p.proname = 'record_export_download'
             AND p.proargnames IS NOT NULL
             AND array_position(p.proargnames, 'p_actor_id') IS NULL
             AND array_position(p.proargnames, 'p_requested_by') IS NULL
             AND array_position(p.proargnames, 'p_generated_by') IS NULL
             AND array_position(p.proargnames, 'p_downloaded_by') IS NULL
             AND position('auth.uid()' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
             AND position('v_actor := auth.uid()' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
             AND position('v_actor is null' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
         ) THEN 'NO_CLIENT_ID' ELSE 'MISSING' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_proc p
           WHERE p.proname = 'record_export_download'
             AND p.proargnames IS NOT NULL
             AND array_position(p.proargnames, 'p_actor_id') IS NULL
             AND array_position(p.proargnames, 'p_requested_by') IS NULL
             AND array_position(p.proargnames, 'p_generated_by') IS NULL
             AND array_position(p.proargnames, 'p_downloaded_by') IS NULL
             AND position('auth.uid()' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
             AND position('v_actor := auth.uid()' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
             AND position('v_actor is null' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
         ) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_proc p
           WHERE p.proname = 'record_export_download'
             AND p.proargnames IS NOT NULL
             AND array_position(p.proargnames, 'p_actor_id') IS NULL
             AND array_position(p.proargnames, 'p_requested_by') IS NULL
             AND array_position(p.proargnames, 'p_generated_by') IS NULL
             AND array_position(p.proargnames, 'p_downloaded_by') IS NULL
             AND position('auth.uid()' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
             AND position('v_actor := auth.uid()' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
             AND position('v_actor is null' in regexp_replace(lower(p.prosrc), '\s+', ' ', 'g')) > 0
         ) THEN 'Download auditing uses auth.uid() as the trusted actor source and never accepts a client actor argument.' ELSE 'Download auditing still accepts a client-supplied actor ID.' END
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
