import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { loadModule, parseSync } from 'pgsql-parser'
import { beforeAll, describe, expect, it } from 'vitest'

describe('phase 4A live social engagement enforcement', () => {
  beforeAll(async () => {
    await loadModule()
  })

  it('requires the migration and verifier to contain the repository-side social publishing guardrails', () => {
    const migrationSql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20260917_000001_phase_4a_live_social_engagement.sql'), 'utf8')
    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_phase_4a_live_social_engagement.sql'), 'utf8')

    expect(migrationSql).toContain('CREATE OR REPLACE FUNCTION public.enforce_social_connection_state()')
    expect(migrationSql).toContain('CREATE OR REPLACE FUNCTION public.enforce_social_publishing_job_transition()')
    expect(migrationSql).toContain('CREATE OR REPLACE FUNCTION public.record_social_publishing_attempt()')
    expect(migrationSql).toContain('CREATE TRIGGER social_provider_connections_state_guard')
    expect(migrationSql).toContain('CREATE TRIGGER social_publishing_jobs_state_guard')
    expect(migrationSql).toContain('approval_state = \'approved\'')
    expect(migrationSql).toContain('content_hash')
    expect(migrationSql).toContain('provider_account_id')
    expect(migrationSql).toContain('provider_page_id')

    expect(verifierSql).toContain('public.enforce_social_connection_state()')
    expect(verifierSql).toContain('public.enforce_social_publishing_job_transition()')
    expect(verifierSql).toContain('public.record_social_publishing_attempt()')
    expect(verifierSql).toContain('overall_status')

    expect(() => parseSync(migrationSql)).not.toThrow()
    expect(() => parseSync(verifierSql)).not.toThrow()
  })

  it('requires a read-only Phase 4A live verifier with a seven-column UNION contract and evidence-backed checks', () => {
    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_phase_4a_live_social_engagement.sql'), 'utf8')

    expect(verifierSql).toContain('BEGIN;')
    expect(verifierSql).toContain('ROLLBACK;')
    expect(verifierSql).not.toContain('COMMIT;')
    expect(verifierSql).toContain('SELECT category, object_name, check_name, expected_result, actual_result, status, details')
    expect(verifierSql).toContain("'TABLE'::text")
    expect(verifierSql).toContain("'FUNCTION'::text")
    expect(verifierSql).toContain("'RLS'::text")
    expect(verifierSql).toContain("'SECURITY'::text")
    expect(verifierSql).toContain("'POLICY'::text")
    expect(verifierSql).toContain("'DATA'::text")
    expect(verifierSql).toContain("'OVERALL'::text")
    expect(verifierSql).toContain("'table_exists'::text")
    expect(verifierSql).toContain("'function_exists'::text")
    expect(verifierSql).toContain("'trigger_exists'::text")
    expect(verifierSql).toContain("'rls_enabled'::text")
    expect(verifierSql).toContain("'search_path_restricted'::text")
    expect(verifierSql).toContain("'anonymous_denied'::text")
    expect(verifierSql).toContain("'approval_required'::text")
    expect(verifierSql).toContain("'EXISTS'::text")
    expect(verifierSql).toContain("'TRUE'::text")
    expect(verifierSql).toContain("'search_path=public, auth, pg_catalog'::text")
    expect(verifierSql).toContain("'NO_ANON'::text")
    expect(verifierSql).toContain("'APPROVAL'::text")
    expect(verifierSql).toContain('pg_proc.proconfig')
    expect(verifierSql).toContain('search_path=public,auth,pg_catalog')
    expect(verifierSql).toContain('unnest(p.roles)')
    expect(verifierSql).toContain("lower(policy_role) = 'anon'")
    expect(verifierSql).toContain("lower(policy_role) = 'public'")
    expect(verifierSql).toContain('concat_ws(')
    expect(verifierSql).toContain('coalesce(p.qual')
    expect(verifierSql).toContain('coalesce(p.with_check')
    expect(verifierSql).toContain('COUNT(*) FILTER (WHERE status = \'FAIL\')')
    expect(verifierSql).not.toMatch(/pg_get_policydef\s*\(\s*p\s*\.\s*oid\s*\)/i)
    expect(verifierSql).not.toMatch(/FROM\s+pg_policies\s+p[\s\S]*?p\.oid/i)
    expect(verifierSql).not.toContain('pg_get_policydef(p.oid)')

    // The contract is enforced by the first explicit SELECT and by the final projection, which keeps the positional UNION output aligned.
    const firstBranch = verifierSql.match(/SELECT[\s\S]*?UNION ALL/)
    expect(firstBranch).not.toBeNull()
    expect(firstBranch![0]).toContain('AS category')
    expect(firstBranch![0]).toContain('AS object_name')
    expect(firstBranch![0]).toContain('AS check_name')
    expect(firstBranch![0]).toContain('AS expected_result')
    expect(firstBranch![0]).toContain('AS actual_result')
    expect(firstBranch![0]).toContain('AS status')
    expect(firstBranch![0]).toContain('AS details')

    expect(verifierSql).toContain('SELECT category, object_name, check_name, expected_result, actual_result, status, details')
    expect(verifierSql).toContain('phase_4a_live_social_engagement_verification')
    expect(verifierSql).toContain("'0 FAIL'::text")
    expect(verifierSql).toContain('PASS')
    expect(verifierSql).toContain('FAIL')

    expect(() => parseSync(verifierSql)).not.toThrow()
  })

  it('recognizes the live proconfig and guarded public-role policy evidence without false positives', () => {
    const normalize = (input: string) => input
      .toLowerCase()
      .replace(/['"]/g, '')
      .replace(/\s+/g, ' ')
      .trim()

    const hasSafeSearchPath = (configs: string[]) => configs.some((cfg) => {
      const normalized = normalize(cfg)
        .replace(/^set\s+/, '')
        .replace(/\s+to\s+/g, '=')
        .replace(/["']/g, '')
        .replace(/\s+/g, '')

      return normalized.includes('search_path=public,auth,pg_catalog')
    })

    const isGuardedPublicPolicy = (definition: string) => {
      const normalized = normalize(definition)
      return normalized.includes('auth.uid() is not null') && normalized.includes('current_user_can_manage_social_connections()')
    }

    const guardedPolicyDefinition = "USING ((auth.uid() IS NOT NULL AND current_user_can_manage_social_connections())) WITH CHECK ((auth.uid() IS NOT NULL AND current_user_can_manage_social_connections()))"
    const unguardedPolicyDefinition = 'USING (true) WITH CHECK (true)'
    const explicitAnonPolicyDefinition = 'USING ((auth.uid() IS NULL)) WITH CHECK ((auth.uid() IS NULL))'
    const missingAuthUidPolicyDefinition = 'USING ((current_user_can_manage_social_connections())) WITH CHECK ((current_user_can_manage_social_connections()))'
    const missingPermissionGateDefinition = 'USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL))'

    expect(hasSafeSearchPath(['search_path=public, auth, pg_catalog'])).toBe(true)
    expect(hasSafeSearchPath(["SET search_path TO 'public', 'auth', 'pg_catalog'"])).toBe(true)
    expect(isGuardedPublicPolicy(guardedPolicyDefinition)).toBe(true)
    expect(isGuardedPublicPolicy(unguardedPolicyDefinition)).toBe(false)
    expect(isGuardedPublicPolicy(explicitAnonPolicyDefinition)).toBe(false)
    expect(isGuardedPublicPolicy(missingAuthUidPolicyDefinition)).toBe(false)
    expect(isGuardedPublicPolicy(missingPermissionGateDefinition)).toBe(false)

    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_phase_4a_live_social_engagement.sql'), 'utf8')
    expect(verifierSql).toContain('pg_proc.proconfig')
    expect(verifierSql).toContain('search_path=public,auth,pg_catalog')
    expect(verifierSql).toContain('auth.uid()')
    expect(verifierSql).toContain('current_user_can_manage_social_connections()')
    expect(verifierSql).toContain('concat_ws(')
    expect(verifierSql).toContain('coalesce(p.qual')
    expect(verifierSql).toContain('coalesce(p.with_check')
    expect(verifierSql).not.toMatch(/pg_get_policydef\s*\(\s*p\s*\.\s*oid\s*\)/i)
    expect(verifierSql).not.toMatch(/FROM\s+pg_policies\s+p[\s\S]*?p\.oid/i)
    expect(verifierSql).toContain('ANON_PRESENT')
    expect(verifierSql).toContain('NO_ANON')
    expect(verifierSql).toContain('BEGIN;')
    expect(verifierSql).toContain('ROLLBACK;')
    expect(verifierSql).toContain('SELECT category, object_name, check_name, expected_result, actual_result, status, details')
    expect(verifierSql).toContain('phase_4a_live_social_engagement_verification')
    expect(verifierSql).toContain('overall_status')
    expect(() => parseSync(verifierSql)).not.toThrow()
  })

  it('requires a read-only Phase 4A live database preflight package', () => {
    const preflightSql = readFileSync(resolve(process.cwd(), 'supabase/verification/preflight_phase_4a_live_database.sql'), 'utf8')

    expect(preflightSql).toContain('Phase 4A live database preflight')
    expect(preflightSql).toContain('public.social_provider_connections')
    expect(preflightSql).toContain('public.export_requests')
    expect(preflightSql).toContain('READY_TO_APPLY_4A')
    expect(preflightSql).toContain('4A_ALREADY_APPLIED_RUN_VERIFIER')
    expect(preflightSql).toContain('BLOCKED_MISSING_3E')
    expect(preflightSql).toContain('BLOCKED_MISSING_3F')
    expect(preflightSql).toContain('BLOCKED_PARTIAL_4A')
    expect(preflightSql).toContain('BLOCKED_OTHER_DEPENDENCY')
    expect(preflightSql).toContain('SELECT')
    expect(preflightSql).not.toContain('CREATE TABLE')
    expect(preflightSql).not.toContain('ALTER TABLE')
    expect(preflightSql).not.toContain('CREATE POLICY')
    expect(preflightSql).not.toContain('CREATE TRIGGER')

    const sevenColumnMarkers = [
      "'TABLE'::text AS category",
      "'FUNCTION'::text",
      "'TRIGGER'::text",
      "'RLS'::text",
      "'POLICY'::text",
      "'SAFETY'::text",
      "'SUMMARY'::text AS category",
      'SELECT category, object_name, check_name, expected_result, actual_result, status, details'
    ]

    for (const marker of sevenColumnMarkers) {
      expect(preflightSql).toContain(marker)
    }

    expect(preflightSql).toContain('category')
    expect(preflightSql).toContain('object_name')
    expect(preflightSql).toContain('check_name')
    expect(preflightSql).toContain('expected_result')
    expect(preflightSql).toContain('actual_result')
    expect(preflightSql).toContain('status')
    expect(preflightSql).toContain('details')
    expect(() => parseSync(preflightSql)).not.toThrow()
  })
})
