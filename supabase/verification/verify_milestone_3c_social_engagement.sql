WITH substantive_results AS (
  SELECT 'TABLE' AS category, 'public.engagement_connections' AS object_name, 'table_exists' AS check_name,
         'EXISTS' AS expected_result,
         CASE WHEN to_regclass('public.engagement_connections') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END AS actual_result,
         CASE WHEN to_regclass('public.engagement_connections') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS status,
         CASE WHEN to_regclass('public.engagement_connections') IS NOT NULL THEN 'public.engagement_connections exists.' ELSE 'public.engagement_connections is missing.' END AS details
  UNION ALL
  SELECT 'TABLE', 'public.engagement_threads', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.engagement_threads') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.engagement_threads') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.engagement_threads') IS NOT NULL THEN 'public.engagement_threads exists.' ELSE 'public.engagement_threads is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.engagement_messages', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.engagement_messages') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.engagement_messages') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.engagement_messages') IS NOT NULL THEN 'public.engagement_messages exists.' ELSE 'public.engagement_messages is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.engagement_match_candidates', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.engagement_match_candidates') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.engagement_match_candidates') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.engagement_match_candidates') IS NOT NULL THEN 'public.engagement_match_candidates exists.' ELSE 'public.engagement_match_candidates is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.engagement_ingestion_events', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.engagement_ingestion_events') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.engagement_ingestion_events') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.engagement_ingestion_events') IS NOT NULL THEN 'public.engagement_ingestion_events exists.' ELSE 'public.engagement_ingestion_events is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.engagement_work_queue_items', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.engagement_work_queue_items') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.engagement_work_queue_items') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.engagement_work_queue_items') IS NOT NULL THEN 'public.engagement_work_queue_items exists.' ELSE 'public.engagement_work_queue_items is missing.' END
  UNION ALL
  SELECT 'CHECK', 'public.engagement_connections', 'platform_constraint', 'instagram|facebook|linkedin|email',
         CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'engagement_connections' AND column_name = 'platform') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'engagement_connections' AND column_name = 'platform') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'engagement_connections' AND column_name = 'platform') THEN 'Platform values are constrained to supported social channels.' ELSE 'Platform column is missing.' END
  UNION ALL
  SELECT 'CHECK', 'public.engagement_threads', 'matching_status_constraint', 'matched|unmatched|needs_review|rejected',
         CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'engagement_threads' AND column_name = 'matching_status') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'engagement_threads' AND column_name = 'matching_status') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'engagement_threads' AND column_name = 'matching_status') THEN 'Thread matching status is constrained.' ELSE 'Matching status column is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.engagement_connections', 'provider_account_unique_index', 'PRESENT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'engagement_connections' AND indexname = 'ux_engagement_connections_account') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'engagement_connections' AND indexname = 'ux_engagement_connections_account') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'engagement_connections' AND indexname = 'ux_engagement_connections_account') THEN 'Unique account index exists.' ELSE 'Unique account index is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.engagement_threads', 'provider_thread_unique_index', 'PRESENT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'engagement_threads' AND indexname = 'ux_engagement_threads_provider') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'engagement_threads' AND indexname = 'ux_engagement_threads_provider') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'engagement_threads' AND indexname = 'ux_engagement_threads_provider') THEN 'Unique provider-thread index exists.' ELSE 'Unique provider-thread index is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.engagement_messages', 'provider_message_unique_index', 'PRESENT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'engagement_messages' AND indexname = 'ux_engagement_messages_provider') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'engagement_messages' AND indexname = 'ux_engagement_messages_provider') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'engagement_messages' AND indexname = 'ux_engagement_messages_provider') THEN 'Unique provider-message index exists.' ELSE 'Unique provider-message index is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.engagement_ingestion_events', 'event_idempotency_index', 'PRESENT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'engagement_ingestion_events' AND indexname = 'ux_engagement_ingestion_event_idempotency') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'engagement_ingestion_events' AND indexname = 'ux_engagement_ingestion_event_idempotency') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'engagement_ingestion_events' AND indexname = 'ux_engagement_ingestion_event_idempotency') THEN 'Provider event idempotency index exists.' ELSE 'Provider event idempotency index is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.engagement_work_queue_items', 'work_queue_integration', 'EXISTS',
         CASE WHEN to_regclass('public.engagement_work_queue_items') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.engagement_work_queue_items') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.engagement_work_queue_items') IS NOT NULL THEN 'Work queue integration table exists.' ELSE 'Work queue integration table is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.create_engagement_connection(uuid,uuid,text,text,text,text,text,text,text,jsonb,jsonb,uuid,jsonb)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.create_engagement_connection(uuid,uuid,text,text,text,text,text,text,text,jsonb,jsonb,uuid,jsonb)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.create_engagement_connection(uuid,uuid,text,text,text,text,text,text,text,jsonb,jsonb,uuid,jsonb)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.create_engagement_connection(uuid,uuid,text,text,text,text,text,text,text,jsonb,jsonb,uuid,jsonb)') IS NOT NULL THEN 'Engagement connection creation RPC exists.' ELSE 'Engagement connection creation RPC is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.validate_engagement_connection(uuid,text)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.validate_engagement_connection(uuid,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.validate_engagement_connection(uuid,text)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.validate_engagement_connection(uuid,text)') IS NOT NULL THEN 'Engagement validation RPC exists.' ELSE 'Engagement validation RPC is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.route_engagement_response_to_work_queue(uuid,uuid,uuid,text,text)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.route_engagement_response_to_work_queue(uuid,uuid,uuid,text,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.route_engagement_response_to_work_queue(uuid,uuid,uuid,text,text)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.route_engagement_response_to_work_queue(uuid,uuid,uuid,text,text)') IS NOT NULL THEN 'Engagement queue routing RPC exists.' ELSE 'Engagement queue routing RPC is missing.' END
  UNION ALL
  SELECT 'RLS', 'public.engagement_connections', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.engagement_connections'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.engagement_connections'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.engagement_connections'::regclass) THEN 'RLS enabled on public.engagement_connections.' ELSE 'RLS is not enabled on public.engagement_connections.' END
  UNION ALL
  SELECT 'RLS', 'public.engagement_threads', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.engagement_threads'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.engagement_threads'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.engagement_threads'::regclass) THEN 'RLS enabled on public.engagement_threads.' ELSE 'RLS is not enabled on public.engagement_threads.' END
  UNION ALL
  SELECT 'RLS', 'public.engagement_messages', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.engagement_messages'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.engagement_messages'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.engagement_messages'::regclass) THEN 'RLS enabled on public.engagement_messages.' ELSE 'RLS is not enabled on public.engagement_messages.' END
  UNION ALL
  SELECT 'POLICY', 'public.engagement_connections', 'select_policy_command', 'SELECT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'engagement_connections' AND cmd = 'SELECT') THEN 'SELECT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'engagement_connections' AND cmd = 'SELECT') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'engagement_connections' AND cmd = 'SELECT') THEN 'Connection select policy exists.' ELSE 'Connection select policy is missing.' END
  UNION ALL
  SELECT 'POLICY', 'public.engagement_work_queue_items', 'insert_policy_command', 'INSERT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'engagement_work_queue_items' AND cmd = 'INSERT') THEN 'INSERT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'engagement_work_queue_items' AND cmd = 'INSERT') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'engagement_work_queue_items' AND cmd = 'INSERT') THEN 'Queue insert policy exists.' ELSE 'Queue insert policy is missing.' END
),
all_results AS (
  SELECT category, object_name, check_name, expected_result, actual_result, status, details FROM substantive_results
),
overall_result AS (
  SELECT 'OVERALL' AS category,
         'release_3c_social_engagement' AS object_name,
         'overall_status' AS check_name,
         'All required checks pass' AS expected_result,
         CAST(COALESCE(COUNT(*) FILTER (WHERE status = 'PASS'), 0) || ' PASS, ' || COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) || ' FAIL' AS text) AS actual_result,
         CASE WHEN COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
         CASE WHEN COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) = 0 THEN 'Release 3C social engagement verification PASSED' ELSE 'Release 3C social engagement verification FAILED' END AS details
  FROM all_results
)
SELECT category, object_name, check_name, expected_result, actual_result, status, details
FROM (
  SELECT category, object_name, check_name, expected_result, actual_result, status, details FROM all_results
  UNION ALL
  SELECT category, object_name, check_name, expected_result, actual_result, status, details FROM overall_result
) wrapped_results
ORDER BY CASE WHEN category = 'OVERALL' THEN 1 ELSE 0 END, object_name, check_name;
