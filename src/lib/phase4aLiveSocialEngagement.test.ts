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

  it('requires a read-only Phase 4A live database preflight package', () => {
    const preflightSql = readFileSync(resolve(process.cwd(), 'supabase/verification/preflight_phase_4a_live_database.sql'), 'utf8')

    expect(preflightSql).toContain('Phase 4A live database preflight')
    expect(preflightSql).toContain('public.social_provider_connections')
    expect(preflightSql).toContain('public.export_requests')
    expect(preflightSql).toContain('overall_status')
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

    expect(() => parseSync(preflightSql)).not.toThrow()
  })
})
