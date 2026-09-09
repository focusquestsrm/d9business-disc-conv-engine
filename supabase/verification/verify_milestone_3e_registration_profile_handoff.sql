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
