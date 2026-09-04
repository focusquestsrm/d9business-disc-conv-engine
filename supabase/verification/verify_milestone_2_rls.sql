-- Deprecated reference copy.
-- Canonical read-only verifier: C:\Users\danie\d9business-disc-conv-engine\supabase\scripts\verify_milestone_2_rls.sql
-- This file is kept only as a documentation/reference copy and is not the authoritative verification script.

SELECT
  'DEPRECATED' AS category,
  'supabase/verification/verify_milestone_2_rls.sql' AS object_name,
  'canonical_verifier' AS check_name,
  'Use supabase/scripts/verify_milestone_2_rls.sql' AS expected_result,
  'reference_only' AS actual_result,
  'PASS' AS status,
  'This file is deprecated and intentionally not authoritative. Use the canonical verifier in supabase/scripts.' AS details;
