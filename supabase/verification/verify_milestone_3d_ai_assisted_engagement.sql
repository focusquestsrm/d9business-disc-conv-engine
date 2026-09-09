WITH substantive_results AS (
  SELECT 'TABLE' AS category, 'public.ai_engagement_suggestions' AS object_name, 'table_exists' AS check_name,
         'EXISTS' AS expected_result,
         CASE WHEN to_regclass('public.ai_engagement_suggestions') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END AS actual_result,
         CASE WHEN to_regclass('public.ai_engagement_suggestions') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS status,
         CASE WHEN to_regclass('public.ai_engagement_suggestions') IS NOT NULL THEN 'public.ai_engagement_suggestions exists.' ELSE 'public.ai_engagement_suggestions is missing.' END AS details
  UNION ALL
  SELECT 'TABLE', 'public.ai_engagement_approvals', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.ai_engagement_approvals') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.ai_engagement_approvals') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.ai_engagement_approvals') IS NOT NULL THEN 'public.ai_engagement_approvals exists.' ELSE 'public.ai_engagement_approvals is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.engagement_outreach_attempts', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.engagement_outreach_attempts') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.engagement_outreach_attempts') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.engagement_outreach_attempts') IS NOT NULL THEN 'public.engagement_outreach_attempts exists.' ELSE 'public.engagement_outreach_attempts is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.engagement_follow_up_reminders', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.engagement_follow_up_reminders') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.engagement_follow_up_reminders') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.engagement_follow_up_reminders') IS NOT NULL THEN 'public.engagement_follow_up_reminders exists.' ELSE 'public.engagement_follow_up_reminders is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.engagement_outcome_classifications', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.engagement_outcome_classifications') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.engagement_outcome_classifications') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.engagement_outcome_classifications') IS NOT NULL THEN 'public.engagement_outcome_classifications exists.' ELSE 'public.engagement_outcome_classifications is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.engagement_escalations', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.engagement_escalations') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.engagement_escalations') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.engagement_escalations') IS NOT NULL THEN 'public.engagement_escalations exists.' ELSE 'public.engagement_escalations is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.engagement_frequency_rules', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.engagement_frequency_rules') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.engagement_frequency_rules') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.engagement_frequency_rules') IS NOT NULL THEN 'public.engagement_frequency_rules exists.' ELSE 'public.engagement_frequency_rules is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.ai_prompt_templates', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.ai_prompt_templates') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.ai_prompt_templates') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.ai_prompt_templates') IS NOT NULL THEN 'public.ai_prompt_templates exists.' ELSE 'public.ai_prompt_templates is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.create_ai_engagement_suggestion(uuid,uuid,uuid,uuid,text,text,text,text,text,text,jsonb,jsonb,text,text,uuid,text,numeric,jsonb,jsonb,text,uuid)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.create_ai_engagement_suggestion(uuid,uuid,uuid,uuid,text,text,text,text,text,text,jsonb,jsonb,text,text,uuid,text,numeric,jsonb,jsonb,text,uuid)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.create_ai_engagement_suggestion(uuid,uuid,uuid,uuid,text,text,text,text,text,text,jsonb,jsonb,text,text,uuid,text,numeric,jsonb,jsonb,text,uuid)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.create_ai_engagement_suggestion(uuid,uuid,uuid,uuid,text,text,text,text,text,text,jsonb,jsonb,text,text,uuid,text,numeric,jsonb,jsonb,text,uuid)') IS NOT NULL THEN 'AI suggestion creation RPC exists.' ELSE 'AI suggestion creation RPC is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.evaluate_engagement_send_eligibility(uuid,uuid,uuid,text,text,text,boolean,boolean,boolean,boolean,boolean,boolean,boolean)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.evaluate_engagement_send_eligibility(uuid,uuid,uuid,text,text,text,boolean,boolean,boolean,boolean,boolean,boolean,boolean)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.evaluate_engagement_send_eligibility(uuid,uuid,uuid,text,text,text,boolean,boolean,boolean,boolean,boolean,boolean,boolean)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.evaluate_engagement_send_eligibility(uuid,uuid,uuid,text,text,text,boolean,boolean,boolean,boolean,boolean,boolean,boolean)') IS NOT NULL THEN 'AI send eligibility RPC exists.' ELSE 'AI send eligibility RPC is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.classify_engagement_outcome(uuid,uuid,uuid,text,text,text,jsonb)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.classify_engagement_outcome(uuid,uuid,uuid,text,text,text,jsonb)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.classify_engagement_outcome(uuid,uuid,uuid,text,text,text,jsonb)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.classify_engagement_outcome(uuid,uuid,uuid,text,text,text,jsonb)') IS NOT NULL THEN 'Outcome classification RPC exists.' ELSE 'Outcome classification RPC is missing.' END
), all_results AS (
  SELECT category, object_name, check_name, expected_result, actual_result, status, details FROM substantive_results
), overall_result AS (
  SELECT 'OVERALL' AS category,
         'release_3d_ai_assisted_engagement' AS object_name,
         'overall_status' AS check_name,
         'All required checks pass' AS expected_result,
         CAST(COALESCE(COUNT(*) FILTER (WHERE status = 'PASS'), 0) || ' PASS, ' || COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) || ' FAIL' AS text) AS actual_result,
         CASE WHEN COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
         CASE WHEN COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) = 0 THEN 'Release 3D AI-assisted engagement verification PASSED' ELSE 'Release 3D AI-assisted engagement verification FAILED' END AS details
  FROM all_results
)
SELECT category, object_name, check_name, expected_result, actual_result, status, details
FROM (
  SELECT category, object_name, check_name, expected_result, actual_result, status, details FROM all_results
  UNION ALL
  SELECT category, object_name, check_name, expected_result, actual_result, status, details FROM overall_result
) wrapped_results
ORDER BY CASE WHEN category = 'OVERALL' THEN 1 ELSE 0 END, object_name, check_name;
