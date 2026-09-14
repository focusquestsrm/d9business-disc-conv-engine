import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { parseSync } from 'pgsql-parser'
import { describe, expect, it } from 'vitest'

describe('release 3F security and live acceptance', () => {
  it('keeps the 3F migration and verifier aligned to the security matrix and export audit model', () => {
    const migrationSql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20260912_000001_milestone_3f_security_live_acceptance.sql'), 'utf8')
    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_milestone_3f_security_live_acceptance.sql'), 'utf8')

    expect(migrationSql).toContain('CREATE TABLE IF NOT EXISTS public.security_role_matrix')
    expect(migrationSql).toContain('CREATE TABLE IF NOT EXISTS public.export_audit_events')
    expect(migrationSql).toContain('CREATE OR REPLACE FUNCTION public.assert_security_role_matrix')
    expect(migrationSql).toContain('CREATE OR REPLACE FUNCTION public.record_export_audit_event')
    expect(migrationSql).toContain('CREATE OR REPLACE FUNCTION public.record_export_download_event')
    expect(migrationSql).toContain('DROP POLICY IF EXISTS "Platform admins can read security role matrix"')
    expect(migrationSql).toContain('DROP POLICY IF EXISTS "Platform admins can read export audit events"')
    expect(migrationSql).toContain('role_code')
    expect(migrationSql).toContain('export_status')
    expect(migrationSql).toContain('downloaded_at')

    expect(verifierSql).toContain('public.security_role_matrix')
    expect(verifierSql).toContain('public.export_audit_events')
    expect(verifierSql).toContain('regexp_replace(lower(p.prosrc),')
    expect(verifierSql).toContain("position('public.current_user_is_platform_admin()' in regexp_replace(lower(p.prosrc), '\\s+', ' ', 'g')) > 0")
    expect(verifierSql).toContain("position('manage_security' in regexp_replace(lower(p.prosrc), '\\s+', ' ', 'g')) > 0")
    expect(verifierSql).toContain("position('p_export_status' in regexp_replace(lower(p.prosrc), '\\s+', ' ', 'g')) > 0")
    expect(verifierSql).toContain('overall_status')
    expect(verifierSql).toContain('Release 3F security and live acceptance verification PASSED')

    expect(() => parseSync(migrationSql)).not.toThrow()
    expect(() => parseSync(verifierSql)).not.toThrow()
    console.log('MIGRATION_3F_PARSE_OK')
    console.log('VERIFIER_3F_PARSE_OK')
  })
})
