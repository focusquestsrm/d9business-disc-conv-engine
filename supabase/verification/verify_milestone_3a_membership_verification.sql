-- Canonical read-only verifier for the Release 3A membership verification objects.
-- Intended for local validation only; do not execute against live Supabase.

WITH expected_objects AS (
  SELECT 'public.verification_batches' AS object_name, true AS expected_present
  UNION ALL SELECT 'public.verification_cases', true
  UNION ALL SELECT 'public.verification_results', true
  UNION ALL SELECT 'public.verification_batch_items', true
  UNION ALL SELECT 'public.verification_imports', true
  UNION ALL SELECT 'public.verification_import_rows', true
  UNION ALL SELECT 'public.verification_case_history', true
  UNION ALL SELECT 'public.set_verification_updated_at', true
  UNION ALL SELECT 'public.assign_verification_reviewer', true
  UNION ALL SELECT 'public.transition_verification_case_status', true
  UNION ALL SELECT 'public.mark_verification_batch_exported', true
  UNION ALL SELECT 'public.mark_verification_batch_sent', true
  UNION ALL SELECT 'public.record_verification_response_received', true
  UNION ALL SELECT 'public.close_verification_batch', true
  UNION ALL SELECT 'public.cancel_verification_batch', true
  UNION ALL SELECT 'public.save_manual_verification_result', true
  UNION ALL SELECT 'public.get_verification_case_history', true
  UNION ALL SELECT 'public.commit_verification_import', true
),
actual_objects AS (
  SELECT table_schema || '.' || table_name AS object_name
  FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_name IN (
      'verification_batches', 'verification_cases', 'verification_results',
      'verification_batch_items', 'verification_imports', 'verification_import_rows',
      'verification_case_history'
    )
  UNION ALL
  SELECT 'public.' || routine_name AS object_name
  FROM information_schema.routines
  WHERE routine_schema = 'public'
    AND routine_name IN (
      'set_verification_updated_at', 'assign_verification_reviewer',
      'transition_verification_case_status', 'mark_verification_batch_exported',
      'mark_verification_batch_sent', 'record_verification_response_received',
      'close_verification_batch', 'cancel_verification_batch',
      'save_manual_verification_result', 'get_verification_case_history',
      'commit_verification_import'
    )
),
object_status AS (
  SELECT e.object_name,
         CASE WHEN a.object_name IS NOT NULL THEN TRUE ELSE FALSE END AS present
  FROM expected_objects e
  LEFT JOIN actual_objects a ON a.object_name = e.object_name
),
policy_status AS (
  SELECT 'public.verification_batches' AS object_name,
         EXISTS (
           SELECT 1 FROM pg_policies
           WHERE schemaname = 'public'
             AND tablename = 'verification_batches'
             AND policyname LIKE '%Verification batches%'
         ) AS policy_present,
         'select_insert_update_policy' AS expected_check
  UNION ALL
  SELECT 'public.verification_cases',
         EXISTS (
           SELECT 1 FROM pg_policies
           WHERE schemaname = 'public'
             AND tablename = 'verification_cases'
             AND policyname LIKE '%Verification cases%'
         ),
         'select_insert_update_policy'
  UNION ALL
  SELECT 'public.verification_results',
         EXISTS (
           SELECT 1 FROM pg_policies
           WHERE schemaname = 'public'
             AND tablename = 'verification_results'
             AND policyname LIKE '%Verification results%'
         ),
         'select_insert_update_policy'
  UNION ALL
  SELECT 'public.verification_case_history',
         EXISTS (
           SELECT 1 FROM pg_policies
           WHERE schemaname = 'public'
             AND tablename = 'verification_case_history'
             AND policyname LIKE '%Verification case history%'
         ),
         'select_insert_policy'
  UNION ALL
  SELECT 'public.verification_batch_items',
         EXISTS (
           SELECT 1 FROM pg_policies
           WHERE schemaname = 'public'
             AND tablename = 'verification_batch_items'
             AND policyname LIKE '%Verification batch items%'
         ),
         'select_insert_update_policy'
  UNION ALL
  SELECT 'public.verification_imports',
         EXISTS (
           SELECT 1 FROM pg_policies
           WHERE schemaname = 'public'
             AND tablename = 'verification_imports'
             AND policyname LIKE '%Verification imports%'
         ),
         'select_insert_update_policy'
  UNION ALL
  SELECT 'public.verification_import_rows',
         EXISTS (
           SELECT 1 FROM pg_policies
           WHERE schemaname = 'public'
             AND tablename = 'verification_import_rows'
             AND policyname LIKE '%Verification import rows%'
         ),
         'select_insert_update_policy'
),
trigger_status AS (
  SELECT 'public.verification_batches' AS object_name,
         EXISTS (
           SELECT 1 FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
           WHERE c.relname = 'verification_batches'
             AND t.tgname = 'verification_batches_set_updated_at'
         ) AS trigger_present,
         'updated_at_trigger' AS verification_type
  UNION ALL
  SELECT 'public.verification_cases',
         EXISTS (
           SELECT 1 FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
           WHERE c.relname = 'verification_cases'
             AND t.tgname = 'verification_cases_set_updated_at'
         ),
         'updated_at_trigger'
  UNION ALL
  SELECT 'public.verification_results',
         EXISTS (
           SELECT 1 FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
           WHERE c.relname = 'verification_results'
             AND t.tgname = 'verification_results_set_updated_at'
         ),
         'updated_at_trigger'
),
final_status AS (
  SELECT o.object_name,
         o.present AS expected_present,
         o.present AS actual_present,
         'schema_objects' AS verification_type
  FROM object_status o
  UNION ALL
  SELECT p.object_name,
         TRUE AS expected_present,
         p.policy_present AS actual_present,
         p.expected_check AS verification_type
  FROM policy_status p
  UNION ALL
  SELECT t.object_name,
         TRUE AS expected_present,
         t.trigger_present AS actual_present,
         t.verification_type
  FROM trigger_status t
),
summary AS (
  SELECT verification_type,
         COUNT(*) AS total_checks,
         COUNT(*) FILTER (WHERE actual_present) AS passed_checks,
         COUNT(*) FILTER (WHERE NOT actual_present) AS failed_checks
  FROM final_status
  GROUP BY verification_type
)
SELECT * FROM final_status
UNION ALL
SELECT 'OVERALL PASS' AS object_name,
       TRUE AS expected_present,
       CASE WHEN EXISTS (SELECT 1 FROM final_status WHERE actual_present = FALSE) THEN FALSE ELSE TRUE END AS actual_present,
       'overall_status' AS verification_type
FROM final_status
ORDER BY CASE verification_type
  WHEN 'schema_objects' THEN 1
  WHEN 'select_insert_update_policy' THEN 2
  WHEN 'select_insert_policy' THEN 3
  WHEN 'updated_at_trigger' THEN 4
  WHEN 'overall_status' THEN 5
  ELSE 6
END, object_name;
