BEGIN;

WITH substantive_results AS (
  SELECT 'TABLE' AS category, 'public.registration_invitations' AS object_name, 'table_exists' AS check_name,
         'EXISTS' AS expected_result,
         CASE WHEN to_regclass('public.registration_invitations') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END AS actual_result,
         CASE WHEN to_regclass('public.registration_invitations') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS status,
         CASE WHEN to_regclass('public.registration_invitations') IS NOT NULL THEN 'public.registration_invitations exists.' ELSE 'public.registration_invitations is missing.' END AS details
  UNION ALL
  SELECT 'TABLE', 'public.registration_handoffs', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.registration_handoffs') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.registration_handoffs') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.registration_handoffs') IS NOT NULL THEN 'public.registration_handoffs exists.' ELSE 'public.registration_handoffs is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.member_profile_links', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.member_profile_links') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.member_profile_links') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.member_profile_links') IS NOT NULL THEN 'public.member_profile_links exists.' ELSE 'public.member_profile_links is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.registration_journey_events', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.registration_journey_events') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.registration_journey_events') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.registration_journey_events') IS NOT NULL THEN 'public.registration_journey_events exists.' ELSE 'public.registration_journey_events is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.registration_match_candidates', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.registration_match_candidates') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.registration_match_candidates') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.registration_match_candidates') IS NOT NULL THEN 'public.registration_match_candidates exists.' ELSE 'public.registration_match_candidates is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.brilliant_directories_sync_events', 'table_exists', 'EXISTS',
         CASE WHEN to_regclass('public.brilliant_directories_sync_events') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regclass('public.brilliant_directories_sync_events') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regclass('public.brilliant_directories_sync_events') IS NOT NULL THEN 'public.brilliant_directories_sync_events exists.' ELSE 'public.brilliant_directories_sync_events is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.registration_invitations', 'token_index', 'PRESENT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_invitations' AND indexname = 'ux_registration_invitations_token') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_invitations' AND indexname = 'ux_registration_invitations_token') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_invitations' AND indexname = 'ux_registration_invitations_token') THEN 'Unique invitation token index exists.' ELSE 'Unique invitation token index is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.registration_invitations', 'single_use_index', 'PRESENT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_invitations' AND indexname = 'ux_registration_invitations_single_use') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_invitations' AND indexname = 'ux_registration_invitations_single_use') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_invitations' AND indexname = 'ux_registration_invitations_single_use') THEN 'Single-use invitation index exists.' ELSE 'Single-use invitation index is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.registration_handoffs', 'provider_member_index', 'PRESENT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_handoffs' AND indexname = 'ux_registration_handoffs_active_provider_member') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_handoffs' AND indexname = 'ux_registration_handoffs_active_provider_member') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_handoffs' AND indexname = 'ux_registration_handoffs_active_provider_member') THEN 'Active provider-member uniqueness index exists.' ELSE 'Active provider-member uniqueness index is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.member_profile_links', 'external_profile_index', 'PRESENT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'member_profile_links' AND indexname = 'ux_member_profile_links_external_profile') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'member_profile_links' AND indexname = 'ux_member_profile_links_external_profile') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'member_profile_links' AND indexname = 'ux_member_profile_links_external_profile') THEN 'External profile index exists.' ELSE 'External profile index is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.registration_journey_events', 'journey_stage_index', 'PRESENT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_journey_events' AND indexname = 'ux_registration_journey_stage') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_journey_events' AND indexname = 'ux_registration_journey_stage') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_journey_events' AND indexname = 'ux_registration_journey_stage') THEN 'Journey stage index exists.' ELSE 'Journey stage index is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.registration_match_candidates', 'candidate_identity_index', 'PRESENT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_match_candidates' AND indexname = 'ux_registration_match_candidates_identity') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_match_candidates' AND indexname = 'ux_registration_match_candidates_identity') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_match_candidates' AND indexname = 'ux_registration_match_candidates_identity') THEN 'Match candidate identity index exists.' ELSE 'Match candidate identity index is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.brilliant_directories_sync_events', 'sync_event_idempotency', 'PRESENT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'brilliant_directories_sync_events' AND indexname = 'ux_brilliant_directories_sync_events_idempotency') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'brilliant_directories_sync_events' AND indexname = 'ux_brilliant_directories_sync_events_idempotency') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'brilliant_directories_sync_events' AND indexname = 'ux_brilliant_directories_sync_events_idempotency') THEN 'Sync event idempotency index exists.' ELSE 'Sync event idempotency index is missing.' END
  UNION ALL
  SELECT 'RLS', 'public.registration_invitations', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.registration_invitations'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.registration_invitations'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.registration_invitations'::regclass) THEN 'RLS is enabled on public.registration_invitations.' ELSE 'RLS is not enabled on public.registration_invitations.' END
  UNION ALL
  SELECT 'RLS', 'public.registration_handoffs', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.registration_handoffs'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.registration_handoffs'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.registration_handoffs'::regclass) THEN 'RLS is enabled on public.registration_handoffs.' ELSE 'RLS is not enabled on public.registration_handoffs.' END
  UNION ALL
  SELECT 'RLS', 'public.member_profile_links', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.member_profile_links'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.member_profile_links'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.member_profile_links'::regclass) THEN 'RLS is enabled on public.member_profile_links.' ELSE 'RLS is not enabled on public.member_profile_links.' END
  UNION ALL
  SELECT 'RLS', 'public.registration_journey_events', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.registration_journey_events'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.registration_journey_events'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.registration_journey_events'::regclass) THEN 'RLS is enabled on public.registration_journey_events.' ELSE 'RLS is not enabled on public.registration_journey_events.' END
  UNION ALL
  SELECT 'RLS', 'public.registration_match_candidates', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.registration_match_candidates'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.registration_match_candidates'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.registration_match_candidates'::regclass) THEN 'RLS is enabled on public.registration_match_candidates.' ELSE 'RLS is not enabled on public.registration_match_candidates.' END
  UNION ALL
  SELECT 'RLS', 'public.brilliant_directories_sync_events', 'rls_enabled', 'TRUE',
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.brilliant_directories_sync_events'::regclass) THEN 'TRUE' ELSE 'FALSE' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.brilliant_directories_sync_events'::regclass) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.brilliant_directories_sync_events'::regclass) THEN 'RLS is enabled on public.brilliant_directories_sync_events.' ELSE 'RLS is not enabled on public.brilliant_directories_sync_events.' END
  UNION ALL
  SELECT 'POLICY', 'public.registration_invitations', 'select_policy', 'SELECT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'registration_invitations' AND cmd = 'SELECT') THEN 'SELECT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'registration_invitations' AND cmd = 'SELECT') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'registration_invitations' AND cmd = 'SELECT') THEN 'Read policy exists for registration invitations.' ELSE 'Read policy is missing for registration invitations.' END
  UNION ALL
  SELECT 'POLICY', 'public.registration_handoffs', 'select_policy', 'SELECT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'registration_handoffs' AND cmd = 'SELECT') THEN 'SELECT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'registration_handoffs' AND cmd = 'SELECT') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'registration_handoffs' AND cmd = 'SELECT') THEN 'Read policy exists for registration handoffs.' ELSE 'Read policy is missing for registration handoffs.' END
  UNION ALL
  SELECT 'POLICY', 'public.member_profile_links', 'select_policy', 'SELECT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'member_profile_links' AND cmd = 'SELECT') THEN 'SELECT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'member_profile_links' AND cmd = 'SELECT') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'member_profile_links' AND cmd = 'SELECT') THEN 'Read policy exists for member profile links.' ELSE 'Read policy is missing for member profile links.' END
  UNION ALL
  SELECT 'POLICY', 'public.registration_journey_events', 'select_policy', 'SELECT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'registration_journey_events' AND cmd = 'SELECT') THEN 'SELECT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'registration_journey_events' AND cmd = 'SELECT') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'registration_journey_events' AND cmd = 'SELECT') THEN 'Read policy exists for registration journey events.' ELSE 'Read policy is missing for registration journey events.' END
  UNION ALL
  SELECT 'POLICY', 'public.registration_match_candidates', 'select_policy', 'SELECT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'registration_match_candidates' AND cmd = 'SELECT') THEN 'SELECT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'registration_match_candidates' AND cmd = 'SELECT') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'registration_match_candidates' AND cmd = 'SELECT') THEN 'Read policy exists for registration match candidates.' ELSE 'Read policy is missing for registration match candidates.' END
  UNION ALL
  SELECT 'POLICY', 'public.brilliant_directories_sync_events', 'select_policy', 'SELECT',
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'brilliant_directories_sync_events' AND cmd = 'SELECT') THEN 'SELECT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'brilliant_directories_sync_events' AND cmd = 'SELECT') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'brilliant_directories_sync_events' AND cmd = 'SELECT') THEN 'Read policy exists for Brilliant Directories sync events.' ELSE 'Read policy is missing for Brilliant Directories sync events.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.evaluate_registration_invitation_eligibility(uuid,uuid,text,boolean,boolean,boolean,boolean,boolean,boolean,text)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.evaluate_registration_invitation_eligibility(uuid,uuid,text,boolean,boolean,boolean,boolean,boolean,boolean,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.evaluate_registration_invitation_eligibility(uuid,uuid,text,boolean,boolean,boolean,boolean,boolean,boolean,text)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.evaluate_registration_invitation_eligibility(uuid,uuid,text,boolean,boolean,boolean,boolean,boolean,boolean,text)') IS NOT NULL THEN 'Function exists in the migration signature set.' ELSE 'Function is missing from the migration signature set.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)') IS NOT NULL THEN 'Function exists in the migration signature set.' ELSE 'Function is missing from the migration signature set.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.approve_registration_invitation(uuid,uuid,text,boolean,boolean)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.approve_registration_invitation(uuid,uuid,text,boolean,boolean)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.approve_registration_invitation(uuid,uuid,text,boolean,boolean)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.approve_registration_invitation(uuid,uuid,text,boolean,boolean)') IS NOT NULL THEN 'Function exists in the migration signature set.' ELSE 'Function is missing from the migration signature set.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.record_registration_invitation_sent(uuid,uuid,text)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.record_registration_invitation_sent(uuid,uuid,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.record_registration_invitation_sent(uuid,uuid,text)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.record_registration_invitation_sent(uuid,uuid,text)') IS NOT NULL THEN 'Function exists in the migration signature set.' ELSE 'Function is missing from the migration signature set.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.start_registration_handoff(uuid,uuid,uuid,text,text,text,text,text,jsonb)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.start_registration_handoff(uuid,uuid,uuid,text,text,text,text,text,jsonb)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.start_registration_handoff(uuid,uuid,uuid,text,text,text,text,text,jsonb)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.start_registration_handoff(uuid,uuid,uuid,text,text,text,text,text,jsonb)') IS NOT NULL THEN 'Function exists in the migration signature set.' ELSE 'Function is missing from the migration signature set.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.link_prospect_to_member_profile(uuid,uuid,text,text,text,text,numeric,text,text,text)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.link_prospect_to_member_profile(uuid,uuid,text,text,text,text,numeric,text,text,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.link_prospect_to_member_profile(uuid,uuid,text,text,text,text,numeric,text,text,text)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.link_prospect_to_member_profile(uuid,uuid,text,text,text,text,numeric,text,text,text)') IS NOT NULL THEN 'Function exists in the migration signature set.' ELSE 'Function is missing from the migration signature set.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)') IS NOT NULL THEN 'Function exists in the migration signature set.' ELSE 'Function is missing from the migration signature set.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.record_registration_journey_event(uuid,uuid,text,text,uuid,uuid,uuid,uuid,text,text,text,jsonb)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.record_registration_journey_event(uuid,uuid,text,text,uuid,uuid,uuid,uuid,text,text,text,jsonb)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.record_registration_journey_event(uuid,uuid,text,text,uuid,uuid,uuid,uuid,text,text,text,jsonb)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.record_registration_journey_event(uuid,uuid,text,text,uuid,uuid,uuid,uuid,text,text,text,jsonb)') IS NOT NULL THEN 'Function exists in the migration signature set.' ELSE 'Function is missing from the migration signature set.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.advance_registration_stage(uuid,uuid,text,text,text,uuid,uuid,text)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.advance_registration_stage(uuid,uuid,text,text,text,uuid,uuid,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.advance_registration_stage(uuid,uuid,text,text,text,uuid,uuid,text)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.advance_registration_stage(uuid,uuid,text,text,text,uuid,uuid,text)') IS NOT NULL THEN 'Function exists in the migration signature set.' ELSE 'Function is missing from the migration signature set.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.ingest_brilliant_directories_sync_event(uuid,uuid,text,uuid,uuid,text,text,jsonb,text)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.ingest_brilliant_directories_sync_event(uuid,uuid,text,uuid,uuid,text,text,jsonb,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.ingest_brilliant_directories_sync_event(uuid,uuid,text,uuid,uuid,text,text,jsonb,text)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.ingest_brilliant_directories_sync_event(uuid,uuid,text,uuid,uuid,text,text,jsonb,text)') IS NOT NULL THEN 'Function exists in the migration signature set.' ELSE 'Function is missing from the migration signature set.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.get_registration_journey(uuid,uuid,integer)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.get_registration_journey(uuid,uuid,integer)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.get_registration_journey(uuid,uuid,integer)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.get_registration_journey(uuid,uuid,integer)') IS NOT NULL THEN 'Function exists in the migration signature set.' ELSE 'Function is missing from the migration signature set.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.get_registration_review_queue(uuid,text)', 'function_exists', 'EXISTS',
         CASE WHEN to_regprocedure('public.get_registration_review_queue(uuid,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.get_registration_review_queue(uuid,text)') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.get_registration_review_queue(uuid,text)') IS NOT NULL THEN 'Function exists in the migration signature set.' ELSE 'Function is missing from the migration signature set.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.evaluate_registration_invitation_eligibility(uuid,uuid,text,boolean,boolean,boolean,boolean,boolean,boolean,text)', 'human_approval_gate', 'EXISTS',
         CASE WHEN to_regprocedure('public.evaluate_registration_invitation_eligibility(uuid,uuid,text,boolean,boolean,boolean,boolean,boolean,boolean,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.evaluate_registration_invitation_eligibility(uuid,uuid,text,boolean,boolean,boolean,boolean,boolean,boolean,text)') IS NOT NULL AND lower(pg_get_functiondef('public.evaluate_registration_invitation_eligibility(uuid,uuid,text,boolean,boolean,boolean,boolean,boolean,boolean,text)'::regprocedure)) LIKE '%p_human_approval_granted is not true%' AND lower(pg_get_functiondef('public.evaluate_registration_invitation_eligibility(uuid,uuid,text,boolean,boolean,boolean,boolean,boolean,boolean,text)'::regprocedure)) LIKE '%human approval is required before this invitation can be sent%' THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.evaluate_registration_invitation_eligibility(uuid,uuid,text,boolean,boolean,boolean,boolean,boolean,boolean,text)') IS NOT NULL AND lower(pg_get_functiondef('public.evaluate_registration_invitation_eligibility(uuid,uuid,text,boolean,boolean,boolean,boolean,boolean,boolean,text)'::regprocedure)) LIKE '%p_human_approval_granted is not true%' AND lower(pg_get_functiondef('public.evaluate_registration_invitation_eligibility(uuid,uuid,text,boolean,boolean,boolean,boolean,boolean,boolean,text)'::regprocedure)) LIKE '%human approval is required before this invitation can be sent%' THEN 'Invitation eligibility is gated by consent, opt-out, frequency, and human approval.' ELSE 'Invitation eligibility gate is missing or does not enforce human approval.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)', 'token_hash_generation', 'EXISTS',
         CASE WHEN to_regprocedure('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)') IS NOT NULL AND lower(pg_get_functiondef('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)'::regprocedure)) LIKE '%token_hash%' AND lower(pg_get_functiondef('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)'::regprocedure)) LIKE '%encode(digest%' THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)') IS NOT NULL AND lower(pg_get_functiondef('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)'::regprocedure)) LIKE '%token_hash%' AND lower(pg_get_functiondef('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)'::regprocedure)) LIKE '%encode(digest%' THEN 'Invitation creation hashes tokens and persists a one-time invitation contract.' ELSE 'Invitation creation does not generate a verifiable token hash.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.approve_registration_invitation(uuid,uuid,text,boolean,boolean)', 'approval_writeback', 'EXISTS',
         CASE WHEN to_regprocedure('public.approve_registration_invitation(uuid,uuid,text,boolean,boolean)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.approve_registration_invitation(uuid,uuid,text,boolean,boolean)') IS NOT NULL AND lower(pg_get_functiondef('public.approve_registration_invitation(uuid,uuid,text,boolean,boolean)'::regprocedure)) LIKE '%approved_by%' AND lower(pg_get_functiondef('public.approve_registration_invitation(uuid,uuid,text,boolean,boolean)'::regprocedure)) LIKE '%human_approval_granted%' THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.approve_registration_invitation(uuid,uuid,text,boolean,boolean)') IS NOT NULL AND lower(pg_get_functiondef('public.approve_registration_invitation(uuid,uuid,text,boolean,boolean)'::regprocedure)) LIKE '%approved_by%' AND lower(pg_get_functiondef('public.approve_registration_invitation(uuid,uuid,text,boolean,boolean)'::regprocedure)) LIKE '%human_approval_granted%' THEN 'Invitation approval writes reviewer and consent state back to the invitation.' ELSE 'Invitation approval does not persist approval metadata correctly.' END
  UNION ALL
  SELECT 'CONSTRAINT', 'public.registration_invitations', 'invitation_status_constraint', 'status in (...)',
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_invitations' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%status%' AND pg_get_constraintdef(c.oid) ILIKE '%approved%' AND pg_get_constraintdef(c.oid) ILIKE '%sent%' AND pg_get_constraintdef(c.oid) ILIKE '%accepted%' AND pg_get_constraintdef(c.oid) ILIKE '%expired%' AND pg_get_constraintdef(c.oid) ILIKE '%revoked%' AND pg_get_constraintdef(c.oid) ILIKE '%rejected%') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_invitations' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%status%' AND pg_get_constraintdef(c.oid) ILIKE '%approved%' AND pg_get_constraintdef(c.oid) ILIKE '%sent%' AND pg_get_constraintdef(c.oid) ILIKE '%accepted%' AND pg_get_constraintdef(c.oid) ILIKE '%expired%' AND pg_get_constraintdef(c.oid) ILIKE '%revoked%' AND pg_get_constraintdef(c.oid) ILIKE '%rejected%') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_invitations' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%status%' AND pg_get_constraintdef(c.oid) ILIKE '%approved%' AND pg_get_constraintdef(c.oid) ILIKE '%sent%' AND pg_get_constraintdef(c.oid) ILIKE '%accepted%' AND pg_get_constraintdef(c.oid) ILIKE '%expired%' AND pg_get_constraintdef(c.oid) ILIKE '%revoked%' AND pg_get_constraintdef(c.oid) ILIKE '%rejected%') THEN 'Invitation status constraint enumerates valid lifecycle states.' ELSE 'Invitation status constraint is missing or incomplete.' END
  UNION ALL
  SELECT 'STAGE', 'public.registration_journey_events', 'required_stage_invitation_sent', 'invitation_sent',
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%invitation_sent%') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%invitation_sent%') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%invitation_sent%') THEN 'The invitation_sent stage is present in the journey lifecycle.' ELSE 'The invitation_sent stage is missing from the lifecycle definition.' END
  UNION ALL
  SELECT 'STAGE', 'public.registration_journey_events', 'required_stage_registration_started', 'registration_started',
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%registration_started%') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%registration_started%') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%registration_started%') THEN 'The registration_started stage is present in the journey lifecycle.' ELSE 'The registration_started stage is missing from the lifecycle definition.' END
  UNION ALL
  SELECT 'STAGE', 'public.registration_journey_events', 'required_stage_profile_created', 'profile_created',
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%profile_created%') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%profile_created%') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%profile_created%') THEN 'The profile_created stage is present in the journey lifecycle.' ELSE 'The profile_created stage is missing from the lifecycle definition.' END
  UNION ALL
  SELECT 'STAGE', 'public.registration_journey_events', 'required_stage_profile_claimed', 'profile_claimed',
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%profile_claimed%') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%profile_claimed%') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%profile_claimed%') THEN 'The profile_claimed stage is present in the journey lifecycle.' ELSE 'The profile_claimed stage is missing from the lifecycle definition.' END
  UNION ALL
  SELECT 'STAGE', 'public.registration_journey_events', 'required_stage_profile_completed', 'profile_completed',
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%profile_completed%') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%profile_completed%') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%profile_completed%') THEN 'The profile_completed stage is present in the journey lifecycle.' ELSE 'The profile_completed stage is missing from the lifecycle definition.' END
  UNION ALL
  SELECT 'STAGE', 'public.registration_journey_events', 'required_stage_verification_pending', 'verification_pending',
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%verification_pending%') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%verification_pending%') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%verification_pending%') THEN 'The verification_pending stage is present in the journey lifecycle.' ELSE 'The verification_pending stage is missing from the lifecycle definition.' END
  UNION ALL
  SELECT 'STAGE', 'public.registration_journey_events', 'required_stage_verified', 'verified',
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%verified%') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%verified%') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_journey_events' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%verified%') THEN 'The verified stage is present in the journey lifecycle.' ELSE 'The verified stage is missing from the lifecycle definition.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.advance_registration_stage(uuid,uuid,text,text,text,uuid,uuid,text)', 'valid_transition_enforcement', 'transition_guard',
         CASE WHEN to_regprocedure('public.advance_registration_stage(uuid,uuid,text,text,text,uuid,uuid,text)') IS NOT NULL THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.advance_registration_stage(uuid,uuid,text,text,text,uuid,uuid,text)') IS NOT NULL AND lower(pg_get_functiondef('public.advance_registration_stage(uuid,uuid,text,text,text,uuid,uuid,text)'::regprocedure)) LIKE '%p_previous_stage%' AND lower(pg_get_functiondef('public.advance_registration_stage(uuid,uuid,text,text,text,uuid,uuid,text)'::regprocedure)) LIKE '%p_new_stage%' AND lower(pg_get_functiondef('public.advance_registration_stage(uuid,uuid,text,text,text,uuid,uuid,text)'::regprocedure)) LIKE '%event_source%' THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.advance_registration_stage(uuid,uuid,text,text,text,uuid,uuid,text)') IS NOT NULL AND lower(pg_get_functiondef('public.advance_registration_stage(uuid,uuid,text,text,text,uuid,uuid,text)'::regprocedure)) LIKE '%p_previous_stage%' AND lower(pg_get_functiondef('public.advance_registration_stage(uuid,uuid,text,text,text,uuid,uuid,text)'::regprocedure)) LIKE '%p_new_stage%' AND lower(pg_get_functiondef('public.advance_registration_stage(uuid,uuid,text,text,text,uuid,uuid,text)'::regprocedure)) LIKE '%event_source%' THEN 'Advance stage captures previous/new stage transitions and event source metadata.' ELSE 'Advance stage does not preserve transition metadata for validation.' END
  UNION ALL
  SELECT 'TRIGGER', 'public.registration_journey_events', 'journey_append_only_update_protection', 'UPDATE',
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_trigger t
           WHERE t.tgname = 'registration_journey_events_append_only'
             AND NOT t.tgisinternal
             AND t.tgrelid = 'public.registration_journey_events'::regclass
         ) THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_trigger t
           JOIN pg_proc p ON p.oid = t.tgfoid
           WHERE t.tgname = 'registration_journey_events_append_only'
             AND NOT t.tgisinternal
             AND t.tgrelid = 'public.registration_journey_events'::regclass
             AND p.proname = 'prevent_registration_journey_append_mutation'
             AND ((t.tgtype & 1) <> 0)
             AND ((t.tgtype & 2) <> 0)
             AND ((t.tgtype & 16) <> 0)
         ) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_trigger t
           JOIN pg_proc p ON p.oid = t.tgfoid
           WHERE t.tgname = 'registration_journey_events_append_only'
             AND NOT t.tgisinternal
             AND t.tgrelid = 'public.registration_journey_events'::regclass
             AND p.proname = 'prevent_registration_journey_append_mutation'
             AND ((t.tgtype & 1) <> 0)
             AND ((t.tgtype & 2) <> 0)
             AND ((t.tgtype & 16) <> 0)
         ) THEN 'Journey updates are blocked by append-only trigger protection.' ELSE 'Journey update protection is missing.' END
  UNION ALL
  SELECT 'TRIGGER', 'public.registration_journey_events', 'journey_append_only_delete_protection', 'DELETE',
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_trigger t
           WHERE t.tgname = 'registration_journey_events_append_only'
             AND NOT t.tgisinternal
             AND t.tgrelid = 'public.registration_journey_events'::regclass
         ) THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_trigger t
           JOIN pg_proc p ON p.oid = t.tgfoid
           WHERE t.tgname = 'registration_journey_events_append_only'
             AND NOT t.tgisinternal
             AND t.tgrelid = 'public.registration_journey_events'::regclass
             AND p.proname = 'prevent_registration_journey_append_mutation'
             AND ((t.tgtype & 1) <> 0)
             AND ((t.tgtype & 2) <> 0)
             AND ((t.tgtype & 8) <> 0)
         ) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_trigger t
           JOIN pg_proc p ON p.oid = t.tgfoid
           WHERE t.tgname = 'registration_journey_events_append_only'
             AND NOT t.tgisinternal
             AND t.tgrelid = 'public.registration_journey_events'::regclass
             AND p.proname = 'prevent_registration_journey_append_mutation'
             AND ((t.tgtype & 1) <> 0)
             AND ((t.tgtype & 2) <> 0)
             AND ((t.tgtype & 8) <> 0)
         ) THEN 'Journey deletes are blocked by append-only trigger protection.' ELSE 'Journey delete protection is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.record_registration_invitation_sent(uuid,uuid,text)', 'release_3b_consent_dependency', 'consent_allowed',
         CASE WHEN to_regprocedure('public.record_registration_invitation_sent(uuid,uuid,text)') IS NOT NULL THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.record_registration_invitation_sent(uuid,uuid,text)') IS NOT NULL AND lower(pg_get_functiondef('public.record_registration_invitation_sent(uuid,uuid,text)'::regprocedure)) LIKE '%consent_allowed is true%' THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.record_registration_invitation_sent(uuid,uuid,text)') IS NOT NULL AND lower(pg_get_functiondef('public.record_registration_invitation_sent(uuid,uuid,text)'::regprocedure)) LIKE '%consent_allowed is true%' THEN 'Invite transmission depends on consent being enabled.' ELSE 'Consent dependency is missing before invitation send.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.record_registration_invitation_sent(uuid,uuid,text)', 'release_3b_opt_out_dependency', 'opt_out_active',
         CASE WHEN to_regprocedure('public.record_registration_invitation_sent(uuid,uuid,text)') IS NOT NULL THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.record_registration_invitation_sent(uuid,uuid,text)') IS NOT NULL AND lower(pg_get_functiondef('public.record_registration_invitation_sent(uuid,uuid,text)'::regprocedure)) LIKE '%opt_out_active is false%' THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.record_registration_invitation_sent(uuid,uuid,text)') IS NOT NULL AND lower(pg_get_functiondef('public.record_registration_invitation_sent(uuid,uuid,text)'::regprocedure)) LIKE '%opt_out_active is false%' THEN 'Invite transmission depends on opt-out being inactive.' ELSE 'Opt-out dependency is missing before invitation send.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.record_registration_journey_event(uuid,uuid,text,text,uuid,uuid,uuid,uuid,text,text,text,jsonb)', 'release_3c_engagement_thread_message_linkage', 'thread_message_linkage',
         CASE WHEN to_regprocedure('public.record_registration_journey_event(uuid,uuid,text,text,uuid,uuid,uuid,uuid,text,text,text,jsonb)') IS NOT NULL THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.record_registration_journey_event(uuid,uuid,text,text,uuid,uuid,uuid,uuid,text,text,text,jsonb)') IS NOT NULL AND lower(pg_get_functiondef('public.record_registration_journey_event(uuid,uuid,text,text,uuid,uuid,uuid,uuid,text,text,text,jsonb)'::regprocedure)) LIKE '%related_thread_id%' AND lower(pg_get_functiondef('public.record_registration_journey_event(uuid,uuid,text,text,uuid,uuid,uuid,uuid,text,text,text,jsonb)'::regprocedure)) LIKE '%related_message_id%' THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.record_registration_journey_event(uuid,uuid,text,text,uuid,uuid,uuid,uuid,text,text,text,jsonb)') IS NOT NULL AND lower(pg_get_functiondef('public.record_registration_journey_event(uuid,uuid,text,text,uuid,uuid,uuid,uuid,text,text,text,jsonb)'::regprocedure)) LIKE '%related_thread_id%' AND lower(pg_get_functiondef('public.record_registration_journey_event(uuid,uuid,text,text,uuid,uuid,uuid,uuid,text,text,text,jsonb)'::regprocedure)) LIKE '%related_message_id%' THEN 'Journey events preserve engagement thread and message linkage.' ELSE 'Journey event thread/message linkage is incomplete.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)', 'release_3d_approval_outreach_linkage', 'approval_outreach_linkage',
         CASE WHEN to_regprocedure('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)') IS NOT NULL THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)') IS NOT NULL AND lower(pg_get_functiondef('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)'::regprocedure)) LIKE '%source_message_id%' AND lower(pg_get_functiondef('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)'::regprocedure)) LIKE '%campaign_id%' THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)') IS NOT NULL AND lower(pg_get_functiondef('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)'::regprocedure)) LIKE '%source_message_id%' AND lower(pg_get_functiondef('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)'::regprocedure)) LIKE '%campaign_id%' THEN 'Invitation creation retains outreach campaign/message linkage for later approval review.' ELSE 'Invitation outreach linkage is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.registration_invitations', 'invitation_single_use_enforcement', 'single_use',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_invitations' AND indexname = 'ux_registration_invitations_single_use') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_invitations' AND indexname = 'ux_registration_invitations_single_use') AND lower(pg_get_functiondef('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)'::regprocedure)) LIKE '%p_single_use%' THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_invitations' AND indexname = 'ux_registration_invitations_single_use') AND lower(pg_get_functiondef('public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)'::regprocedure)) LIKE '%p_single_use%' THEN 'Invitation single-use enforcement is represented by the single-use index and contract parameter.' ELSE 'Single-use enforcement is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.registration_invitations', 'invitation_token_uniqueness', 'token_uniqueness',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_invitations' AND indexname = 'ux_registration_invitations_token') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_invitations' AND indexname = 'ux_registration_invitations_token') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_invitations' AND indexname = 'ux_registration_invitations_token') THEN 'Invitation token uniqueness is enforced by a unique partial index.' ELSE 'Invitation token uniqueness is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.brilliant_directories_sync_events', 'provider_sync_event_idempotency', 'idempotent_sync',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'brilliant_directories_sync_events' AND indexname = 'ux_brilliant_directories_sync_events_idempotency') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'brilliant_directories_sync_events' AND indexname = 'ux_brilliant_directories_sync_events_idempotency') AND lower(pg_get_functiondef('public.ingest_brilliant_directories_sync_event(uuid,uuid,text,uuid,uuid,text,text,jsonb,text)'::regprocedure)) LIKE '%on conflict%' THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'brilliant_directories_sync_events' AND indexname = 'ux_brilliant_directories_sync_events_idempotency') AND lower(pg_get_functiondef('public.ingest_brilliant_directories_sync_event(uuid,uuid,text,uuid,uuid,text,text,jsonb,text)'::regprocedure)) LIKE '%on conflict%' THEN 'Provider sync events are idempotent and deduplicated by payload hash.' ELSE 'Provider sync event idempotency is missing.' END
  UNION ALL
  SELECT 'INDEX', 'public.registration_handoffs', 'external_provider_member_uniqueness', 'provider_member_uniqueness',
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_handoffs' AND indexname = 'ux_registration_handoffs_active_provider_member') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_handoffs' AND indexname = 'ux_registration_handoffs_active_provider_member') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'registration_handoffs' AND indexname = 'ux_registration_handoffs_active_provider_member') THEN 'External provider-member uniqueness is enforced for active handoffs.' ELSE 'External provider-member uniqueness is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.registration_match_candidates', 'ambiguous_match_review_support', 'ambiguous_match_support',
         CASE WHEN EXISTS (SELECT 1 FROM pg_class c JOIN pg_attribute a ON a.attrelid = c.oid WHERE c.relname = 'registration_match_candidates' AND a.attname = 'candidate_type') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_class c JOIN pg_attribute a ON a.attrelid = c.oid WHERE c.relname = 'registration_match_candidates' AND a.attname = 'candidate_type') AND lower(pg_get_functiondef('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)'::regprocedure)) LIKE '%duplicate_review%' THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_class c JOIN pg_attribute a ON a.attrelid = c.oid WHERE c.relname = 'registration_match_candidates' AND a.attname = 'candidate_type') AND lower(pg_get_functiondef('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)'::regprocedure)) LIKE '%duplicate_review%' THEN 'Ambiguous and duplicate review support is represented in the candidate model.' ELSE 'Ambiguous match review support is missing.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)', 'deterministic_duplicate_match_support', 'deterministic_match_support',
         CASE WHEN to_regprocedure('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)') IS NOT NULL THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)') IS NOT NULL AND lower(pg_get_functiondef('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)'::regprocedure)) LIKE '%p_normalized_email%' AND lower(pg_get_functiondef('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)'::regprocedure)) LIKE '%p_normalized_phone%' AND lower(pg_get_functiondef('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)'::regprocedure)) LIKE '%union all%' THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)') IS NOT NULL AND lower(pg_get_functiondef('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)'::regprocedure)) LIKE '%p_normalized_email%' AND lower(pg_get_functiondef('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)'::regprocedure)) LIKE '%p_normalized_phone%' AND lower(pg_get_functiondef('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)'::regprocedure)) LIKE '%union all%' THEN 'Duplicate detection is deterministic and combines exact match evidence with review candidates.' ELSE 'Deterministic duplicate-match support is missing.' END
  UNION ALL
  SELECT 'TRIGGER', 'public.registration_invitations', 'human_approval_before_invitation_sent', 'approval_gate',
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_trigger t
           WHERE t.tgname = 'registration_invitations_approval_gate'
             AND NOT t.tgisinternal
             AND t.tgrelid = 'public.registration_invitations'::regclass
         ) THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_trigger t
           JOIN pg_proc p ON p.oid = t.tgfoid
           WHERE t.tgname = 'registration_invitations_approval_gate'
             AND NOT t.tgisinternal
             AND t.tgrelid = 'public.registration_invitations'::regclass
             AND p.proname = 'require_registration_invitation_approval'
             AND ((t.tgtype & 1) <> 0)
             AND ((t.tgtype & 2) <> 0)
             AND ((t.tgtype & 4) <> 0)
             AND ((t.tgtype & 16) <> 0)
             AND regexp_replace(lower(COALESCE(pg_get_functiondef(p.oid)::text, p.prosrc)), E'\\s+', ' ', 'g') LIKE '%new.status = ''sent''%'
             AND regexp_replace(lower(COALESCE(pg_get_functiondef(p.oid)::text, p.prosrc)), E'\\s+', ' ', 'g') LIKE '%new.human_approval_granted is not true%'
             AND regexp_replace(lower(COALESCE(pg_get_functiondef(p.oid)::text, p.prosrc)), E'\\s+', ' ', 'g') LIKE '%new.approved_by is null%'
             AND regexp_replace(lower(COALESCE(pg_get_functiondef(p.oid)::text, p.prosrc)), E'\\s+', ' ', 'g') LIKE '%new.approved_at is null%'
             AND regexp_replace(lower(COALESCE(pg_get_functiondef(p.oid)::text, p.prosrc)), E'\\s+', ' ', 'g') LIKE '%new.consent_allowed is not true%'
             AND regexp_replace(lower(COALESCE(pg_get_functiondef(p.oid)::text, p.prosrc)), E'\\s+', ' ', 'g') LIKE '%new.opt_out_active is true%'
             AND regexp_replace(lower(COALESCE(pg_get_functiondef(p.oid)::text, p.prosrc)), E'\\s+', ' ', 'g') LIKE '%new.frequency_ok is not true%'
         ) THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (
           SELECT 1
           FROM pg_trigger t
           JOIN pg_proc p ON p.oid = t.tgfoid
           WHERE t.tgname = 'registration_invitations_approval_gate'
             AND NOT t.tgisinternal
             AND t.tgrelid = 'public.registration_invitations'::regclass
             AND p.proname = 'require_registration_invitation_approval'
             AND ((t.tgtype & 1) <> 0)
             AND ((t.tgtype & 2) <> 0)
             AND ((t.tgtype & 4) <> 0)
             AND ((t.tgtype & 16) <> 0)
             AND regexp_replace(lower(COALESCE(pg_get_functiondef(p.oid)::text, p.prosrc)), E'\\s+', ' ', 'g') LIKE '%new.status = ''sent''%'
             AND regexp_replace(lower(COALESCE(pg_get_functiondef(p.oid)::text, p.prosrc)), E'\\s+', ' ', 'g') LIKE '%new.human_approval_granted is not true%'
             AND regexp_replace(lower(COALESCE(pg_get_functiondef(p.oid)::text, p.prosrc)), E'\\s+', ' ', 'g') LIKE '%new.approved_by is null%'
             AND regexp_replace(lower(COALESCE(pg_get_functiondef(p.oid)::text, p.prosrc)), E'\\s+', ' ', 'g') LIKE '%new.approved_at is null%'
             AND regexp_replace(lower(COALESCE(pg_get_functiondef(p.oid)::text, p.prosrc)), E'\\s+', ' ', 'g') LIKE '%new.consent_allowed is not true%'
             AND regexp_replace(lower(COALESCE(pg_get_functiondef(p.oid)::text, p.prosrc)), E'\\s+', ' ', 'g') LIKE '%new.opt_out_active is true%'
             AND regexp_replace(lower(COALESCE(pg_get_functiondef(p.oid)::text, p.prosrc)), E'\\s+', ' ', 'g') LIKE '%new.frequency_ok is not true%'
         ) THEN 'A human approval gate blocks unsanctioned invitation sends.' ELSE 'The human approval gate before invitation send is missing or failed.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.record_registration_invitation_sent(uuid,uuid,text)', 'consent_and_opt_out_enforcement_before_invitation_sent', 'enforcement_before_send',
         CASE WHEN to_regprocedure('public.record_registration_invitation_sent(uuid,uuid,text)') IS NOT NULL THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.record_registration_invitation_sent(uuid,uuid,text)') IS NOT NULL AND lower(pg_get_functiondef('public.record_registration_invitation_sent(uuid,uuid,text)'::regprocedure)) LIKE '%consent_allowed is true%' AND lower(pg_get_functiondef('public.record_registration_invitation_sent(uuid,uuid,text)'::regprocedure)) LIKE '%opt_out_active is false%' THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.record_registration_invitation_sent(uuid,uuid,text)') IS NOT NULL AND lower(pg_get_functiondef('public.record_registration_invitation_sent(uuid,uuid,text)'::regprocedure)) LIKE '%consent_allowed is true%' AND lower(pg_get_functiondef('public.record_registration_invitation_sent(uuid,uuid,text)'::regprocedure)) LIKE '%opt_out_active is false%' THEN 'Consent and opt-out guardrails are enforced before invitation send.' ELSE 'Consent and opt-out enforcement before send is missing.' END
  UNION ALL
  SELECT 'TABLE', 'public.registration_handoffs', 'provider_neutral_disconnected_brilliant_directories_state', 'disconnected_state',
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_handoffs' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%disconnected%') THEN 'PRESENT' ELSE 'MISSING' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_handoffs' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%disconnected%') AND EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_handoffs' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%brilliant_directories%') THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_handoffs' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%disconnected%') AND EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid WHERE t.relname = 'registration_handoffs' AND c.contype = 'c' AND pg_get_constraintdef(c.oid) ILIKE '%brilliant_directories%') THEN 'The provider model explicitly allows a disconnected state without claiming live provider activation.' ELSE 'Disconnected Brilliant Directories state is not represented.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.start_registration_handoff(uuid,uuid,uuid,text,text,text,text,text,jsonb)', 'provider_handoff_creation', 'EXISTS',
         CASE WHEN to_regprocedure('public.start_registration_handoff(uuid,uuid,uuid,text,text,text,text,text,jsonb)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.start_registration_handoff(uuid,uuid,uuid,text,text,text,text,text,jsonb)') IS NOT NULL AND lower(pg_get_functiondef('public.start_registration_handoff(uuid,uuid,uuid,text,text,text,text,text,jsonb)'::regprocedure)) LIKE '%on conflict%' AND lower(pg_get_functiondef('public.start_registration_handoff(uuid,uuid,uuid,text,text,text,text,text,jsonb)'::regprocedure)) LIKE '%provider_status%' THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.start_registration_handoff(uuid,uuid,uuid,text,text,text,text,text,jsonb)') IS NOT NULL AND lower(pg_get_functiondef('public.start_registration_handoff(uuid,uuid,uuid,text,text,text,text,text,jsonb)'::regprocedure)) LIKE '%on conflict%' AND lower(pg_get_functiondef('public.start_registration_handoff(uuid,uuid,uuid,text,text,text,text,text,jsonb)'::regprocedure)) LIKE '%provider_status%' THEN 'Handoff creation is idempotent and records provider state.' ELSE 'Handoff creation is not idempotent or does not persist provider state.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.link_prospect_to_member_profile(uuid,uuid,text,text,text,text,numeric,text,text,text)', 'profile_linking', 'EXISTS',
         CASE WHEN to_regprocedure('public.link_prospect_to_member_profile(uuid,uuid,text,text,text,text,numeric,text,text,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.link_prospect_to_member_profile(uuid,uuid,text,text,text,text,numeric,text,text,text)') IS NOT NULL AND lower(pg_get_functiondef('public.link_prospect_to_member_profile(uuid,uuid,text,text,text,text,numeric,text,text,text)'::regprocedure)) LIKE '%claim_state%' AND lower(pg_get_functiondef('public.link_prospect_to_member_profile(uuid,uuid,text,text,text,text,numeric,text,text,text)'::regprocedure)) LIKE '%match_confidence%' THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.link_prospect_to_member_profile(uuid,uuid,text,text,text,text,numeric,text,text,text)') IS NOT NULL AND lower(pg_get_functiondef('public.link_prospect_to_member_profile(uuid,uuid,text,text,text,text,numeric,text,text,text)'::regprocedure)) LIKE '%claim_state%' AND lower(pg_get_functiondef('public.link_prospect_to_member_profile(uuid,uuid,text,text,text,text,numeric,text,text,text)'::regprocedure)) LIKE '%match_confidence%' THEN 'Profile links carry claim state and match evidence for provider reconciliation.' ELSE 'Profile linking does not persist claim state and confidence metadata.' END
  UNION ALL
  SELECT 'FUNCTION', 'public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)', 'duplicate_candidate_search', 'EXISTS',
         CASE WHEN to_regprocedure('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)') IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
         CASE WHEN to_regprocedure('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)') IS NOT NULL AND lower(pg_get_functiondef('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)'::regprocedure)) LIKE '%union all%' AND lower(pg_get_functiondef('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)'::regprocedure)) LIKE '%prospect_match%' THEN 'PASS' ELSE 'FAIL' END,
         CASE WHEN to_regprocedure('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)') IS NOT NULL AND lower(pg_get_functiondef('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)'::regprocedure)) LIKE '%union all%' AND lower(pg_get_functiondef('public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)'::regprocedure)) LIKE '%prospect_match%' THEN 'Duplicate candidate search combines member links and review candidates with a unioned match model.' ELSE 'Duplicate candidate search is not implemented as a combined match model.' END
), all_results AS (
  SELECT category, object_name, check_name, expected_result, actual_result, status, details FROM substantive_results
), overall_result AS (
  SELECT 'OVERALL' AS category,
         'release_3e_registration_profile_handoff' AS object_name,
         'overall_status' AS check_name,
         'All required checks pass' AS expected_result,
         CAST(COALESCE(COUNT(*) FILTER (WHERE status = 'PASS'), 0) || ' PASS, ' || COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) || ' FAIL' AS text) AS actual_result,
         CASE WHEN COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
         CASE WHEN COALESCE(COUNT(*) FILTER (WHERE status = 'FAIL'), 0) = 0 THEN 'Release 3E registration and profile handoff verification PASSED' ELSE 'Release 3E registration and profile handoff verification FAILED' END AS details
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

