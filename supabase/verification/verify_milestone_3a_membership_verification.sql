-- Canonical read-only verifier for the Release 3A membership verification objects.
-- Intended for local validation only; do not execute against live Supabase.

WITH expected_objects AS (
  SELECT 'public.verification_batches' AS object_name, true AS expected_present
  UNION ALL
  SELECT 'public.verification_cases', true
  UNION ALL
  SELECT 'public.verification_results', true
  UNION ALL
  SELECT 'public.verification_batch_items', true
  UNION ALL
  SELECT 'public.verification_imports', true
  UNION ALL
  SELECT 'public.verification_import_rows', true
  UNION ALL
  SELECT 'public.set_verification_updated_at', true
),
actual_objects AS (
  SELECT table_schema || '.' || table_name AS object_name
  FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_name IN ('verification_batches', 'verification_cases', 'verification_results', 'verification_batch_items', 'verification_imports', 'verification_import_rows')
  UNION ALL
  SELECT 'public.set_verification_updated_at'
  FROM information_schema.routines
  WHERE routine_schema = 'public'
    AND routine_name = 'set_verification_updated_at'
),
object_status AS (
  SELECT e.object_name,
         CASE WHEN a.object_name IS NOT NULL THEN true ELSE false END AS present
  FROM expected_objects e
  LEFT JOIN actual_objects a ON a.object_name = e.object_name
),
policy_status AS (
  SELECT 'public.verification_cases' AS object_name,
         EXISTS (
           SELECT 1
           FROM pg_policies
           WHERE schemaname = 'public'
             AND tablename = 'verification_cases'
             AND policyname LIKE '%Verification cases%'
         ) AS policy_present,
         'select_insert_update_policy' AS expected_check
  UNION ALL
  SELECT 'public.verification_batches',
         EXISTS (
           SELECT 1
           FROM pg_policies
           WHERE schemaname = 'public'
             AND tablename = 'verification_batches'
             AND policyname LIKE '%Verification batches%'
         ),
         'select_insert_update_policy'
  UNION ALL
  SELECT 'public.verification_batch_items',
         EXISTS (
           SELECT 1
           FROM pg_policies
           WHERE schemaname = 'public'
             AND tablename = 'verification_batch_items'
             AND policyname LIKE '%Verification batch items%'
         ),
         'select_insert_update_policy'
  UNION ALL
  SELECT 'public.verification_imports',
         EXISTS (
           SELECT 1
           FROM pg_policies
           WHERE schemaname = 'public'
             AND tablename = 'verification_imports'
             AND policyname LIKE '%Verification imports%'
         ),
         'select_insert_update_policy'
  UNION ALL
  SELECT 'public.verification_import_rows',
         EXISTS (
           SELECT 1
           FROM pg_policies
           WHERE schemaname = 'public'
             AND tablename = 'verification_import_rows'
             AND policyname LIKE '%Verification import rows%'
         ),
         'select_insert_update_policy'
),
final_status AS (
  SELECT o.object_name,
         o.present AS expected_present,
         o.present AS actual_present,
         'tables_and_functions' AS verification_type
  FROM object_status o
  UNION ALL
  SELECT p.object_name,
         TRUE AS expected_present,
         p.policy_present AS actual_present,
         p.expected_check AS verification_type
  FROM policy_status p
)
SELECT *
FROM final_status
ORDER BY verification_type, object_name;
