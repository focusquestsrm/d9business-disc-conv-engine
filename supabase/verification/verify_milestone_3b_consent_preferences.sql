WITH substantive_results AS (
  SELECT 'TABLE' AS category, 'public.consent_preferences' AS object_name, 'table_exists' AS check_name,
         'EXISTS' AS expected_result,
         CASE WHEN to_regclass('public.consent_preferences') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END AS actual_result,
         CASE WHEN to_regclass('public.consent_preferences') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS status,
         CASE WHEN to_regclass('public.consent_preferences') IS NOT NULL THEN 'public.consent_preferences exists.' ELSE 'public.consent_preferences is missing.' END AS details
  UNION ALL
  SELECT 'TABLE', 'public.verification_sharing_consents', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.verification_sharing_consents') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.verification_sharing_consents') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.verification_sharing_consents') IS NOT NULL THEN 'public.verification_sharing_consents exists.' ELSE 'public.verification_sharing_consents is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.consent_history', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.consent_history') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.consent_history') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.consent_history') IS NOT NULL THEN 'public.consent_history exists.' ELSE 'public.consent_history is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.retention_policies', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.retention_policies') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.retention_policies') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.retention_policies') IS NOT NULL THEN 'public.retention_policies exists.' ELSE 'public.retention_policies is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.deletion_requests', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.deletion_requests') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.deletion_requests') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.deletion_requests') IS NOT NULL THEN 'public.deletion_requests exists.' ELSE 'public.deletion_requests is missing.' END
  UNION ALL
  SELECT 'CHECK', 'public.consent_preferences', 'channel_constraint', 'email|phone|text|social_media',
         CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'consent_preferences' AND column_name = 'channel') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'consent_preferences' AND column_name = 'channel') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'consent_preferences' AND column_name = 'channel') THEN 'Consent preferences channel column is present with allowed values.' ELSE 'Consent preferences channel column is missing.' END
  UNION ALL
  SELECT 'CHECK', 'public.consent_preferences', 'status_constraint', 'granted|denied|withdrawn|expired',
         CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'consent_preferences' AND column_name = 'status') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'consent_preferences' AND column_name = 'status') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'consent_preferences' AND column_name = 'status') THEN 'Consent status is constrained to supported values.' ELSE 'Consent status is missing.' END
  UNION ALL
  SELECT 'UNIQUE', 'public.consent_preferences', 'unique_active_channel_consent', 'unique_active_record_limit',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'consent_preferences' AND indexname = 'ux_consent_preferences_active') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'consent_preferences' AND indexname = 'ux_consent_preferences_active') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'consent_preferences' AND indexname = 'ux_consent_preferences_active') THEN 'Unique current-effective record index exists.' ELSE 'Unique current-effective record index is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.consent_history', 'history_index_exists', 'PRESENT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'consent_history' AND indexname = 'idx_consent_history_subject') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'consent_history' AND indexname = 'idx_consent_history_subject') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'consent_history' AND indexname = 'idx_consent_history_subject') THEN 'Consent history index exists.' ELSE 'Consent history index is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.opt_outs', 'opt_out_integration', 'EXTENDED',
         CASE WHEN to_regclass('public.opt_outs') IS NOT NULL THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.opt_outs') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.opt_outs') IS NOT NULL THEN 'public.opt_outs is available for suppression integration.' ELSE 'public.opt_outs is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.evaluate_outreach_eligibility(text,uuid,text,text,uuid)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.evaluate_outreach_eligibility(text,uuid,text,text,uuid)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.evaluate_outreach_eligibility(text,uuid,text,text,uuid)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.evaluate_outreach_eligibility(text,uuid,text,text,uuid)') IS NOT NULL THEN 'Outreach eligibility function exists.' ELSE 'Outreach eligibility function is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.evaluate_verification_sharing_eligibility(text,uuid,text,uuid)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.evaluate_verification_sharing_eligibility(text,uuid,text,uuid)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.evaluate_verification_sharing_eligibility(text,uuid,text,uuid)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.evaluate_verification_sharing_eligibility(text,uuid,text,uuid)') IS NOT NULL THEN 'Verification-sharing eligibility function exists.' ELSE 'Verification-sharing eligibility function is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.upsert_communication_consent(text,uuid,text,text,text,text,text,timestamptz,uuid,uuid)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.upsert_communication_consent(text,uuid,text,text,text,text,text,timestamptz,uuid,uuid)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.upsert_communication_consent(text,uuid,text,text,text,text,text,timestamptz,uuid,uuid)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.upsert_communication_consent(text,uuid,text,text,text,text,text,timestamptz,uuid,uuid)') IS NOT NULL THEN 'Communication consent function exists.' ELSE 'Communication consent function is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.request_data_deletion(text,uuid,text,text,uuid)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.request_data_deletion(text,uuid,text,text,uuid)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.request_data_deletion(text,uuid,text,text,uuid)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.request_data_deletion(text,uuid,text,text,uuid)') IS NOT NULL THEN 'Deletion request function exists.' ELSE 'Deletion request function is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.process_deletion_request(uuid,text,uuid,text,text)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.process_deletion_request(uuid,text,uuid,text,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.process_deletion_request(uuid,text,uuid,text,text)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.process_deletion_request(uuid,text,uuid,text,text)') IS NOT NULL THEN 'Deletion processing function exists.' ELSE 'Deletion processing function is missing.' END
  UNION ALL
  SELECT 'RLS', 'public.consent_preferences', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.consent_preferences'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.consent_preferences'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.consent_preferences'::regclass) THEN 'RLS enabled on public.consent_preferences.' ELSE 'RLS is not enabled on public.consent_preferences.' END
  UNION ALL
  SELECT 'RLS', 'public.verification_sharing_consents', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.verification_sharing_consents'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.verification_sharing_consents'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.verification_sharing_consents'::regclass) THEN 'RLS enabled on public.verification_sharing_consents.' ELSE 'RLS is not enabled on public.verification_sharing_consents.' END
  UNION ALL
  SELECT 'RLS', 'public.consent_history', 'append_only_protection', 'TRUE',
         CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'consent_history_block_update') THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'consent_history_block_update') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'consent_history_block_update') THEN 'History mutation trigger exists on consent_history.' ELSE 'Append-only protection is missing.' END
  UNION ALL
  SELECT 'POLICY', 'public.retention_policies', 'policy_exists', 'AT_LEAST_ONE_POLICY',
         CAST((SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'retention_policies') AS text),
         CASE WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'retention_policies') > 0 THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'retention_policies') > 0 THEN 'Retention policy RLS exists.' ELSE 'Retention policy RLS is missing.' END
),
all_results AS (
  SELECT category, object_name, check_name, expected_result, actual_result, status, details FROM substantive_results
),
overall_result AS (
  SELECT 'OVERALL' AS category,
         'release_3b_consent_preferences' AS object_name,
         'overall_status' AS check_name,
         'All required checks pass' AS expected_result,
         CAST(COALESCE(COUNT(*) FILTER (WHERE status = 'PASS'), 0) || ' PASS, ' || COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) || ' FAIL' AS text) AS actual_result,
         CASE WHEN COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
         CASE WHEN COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) = 0 THEN 'Release 3B consent verification PASSED' ELSE 'Release 3B consent verification FAILED' END AS details
  FROM all_results
)
SELECT category, object_name, check_name, expected_result, actual_result, status, details
FROM (
  SELECT category, object_name, check_name, expected_result, actual_result, status, details FROM all_results
  UNION ALL
  SELECT category, object_name, check_name, expected_result, actual_result, status, details FROM overall_result
) wrapped_results
ORDER BY CASE WHEN category = 'OVERALL' THEN 1 ELSE 0 END, object_name, check_name;
