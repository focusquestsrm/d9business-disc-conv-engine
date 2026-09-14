import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { parseSync } from 'pgsql-parser'
import { describe, expect, it } from 'vitest'
import { assertRepositoryRoleAccess, evaluateSecurityAccess, getRepositoryRoleDefinition, repositoryRoleDefinitions } from './securityLiveAcceptance'

describe('release 3F security and live acceptance', () => {
  it('keeps the 3F migration and verifier aligned to the real repository role model and export audit flow', () => {
    const migrationSql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20260912_000001_milestone_3f_security_live_acceptance.sql'), 'utf8')
    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_milestone_3f_security_live_acceptance.sql'), 'utf8')

    expect(migrationSql).toContain('CREATE TABLE IF NOT EXISTS public.export_requests')
    expect(migrationSql).toContain('CREATE TABLE IF NOT EXISTS public.export_audit_events')
    expect(migrationSql).toContain('CREATE OR REPLACE FUNCTION public.create_export_request')
    expect(migrationSql).toContain('CREATE OR REPLACE FUNCTION public.record_export_generation')
    expect(migrationSql).toContain('CREATE OR REPLACE FUNCTION public.record_export_download')
    expect(migrationSql).toContain('auth.uid()')
    expect(migrationSql).toContain('requested_by = auth.uid()')
    expect(migrationSql).toContain('public.current_user_is_platform_admin()')
    expect(migrationSql).toContain('public.user_has_permission')
    expect(migrationSql).toContain('REVOKE ALL ON FUNCTION public.record_export_download')
    expect(migrationSql).toContain('DROP TRIGGER IF EXISTS export_requests_set_updated_at')

    expect(verifierSql).toContain('public.export_requests')
    expect(verifierSql).toContain('public.export_audit_events')
    expect(verifierSql).toContain('overall_status')
    expect(verifierSql).toContain('Release 3F security and live acceptance verification PASSED')

    expect(() => parseSync(migrationSql)).not.toThrow()
    expect(() => parseSync(verifierSql)).not.toThrow()
    console.log('MIGRATION_3F_PARSE_OK')
    console.log('VERIFIER_3F_PARSE_OK')
  })

  it('uses the real repository role model and blocks anonymous or cross-organization access', () => {
    expect(repositoryRoleDefinitions.length).toBeGreaterThan(0)
    expect(getRepositoryRoleDefinition('platform_admin')?.permissions).toContain('manage_users')
    expect(getRepositoryRoleDefinition('verification_reviewer')?.permissions).toContain('view_verification_modules')
    expect(assertRepositoryRoleAccess('platform_admin', 'manage_roles')).toBe(true)
    expect(assertRepositoryRoleAccess('intern_or_researcher', 'view_verification_modules')).toBe(false)

    expect(evaluateSecurityAccess({
      isAuthenticated: false,
      roleCode: 'platform_admin',
      hasMembership: true,
      isActiveMember: true,
      isProviderConnected: true,
    }).allowed).toBe(false)

    expect(evaluateSecurityAccess({
      isAuthenticated: true,
      roleCode: 'platform_admin',
      hasMembership: true,
      isActiveMember: true,
      targetOrganizationId: 'org-1',
      actorOrganizationId: 'org-2',
      isProviderConnected: true,
    }).allowed).toBe(false)

    expect(evaluateSecurityAccess({
      isAuthenticated: true,
      roleCode: 'platform_admin',
      hasMembership: true,
      isActiveMember: true,
      isProviderConnected: true,
      isExportRequestValid: true,
    }).allowed).toBe(true)
  })

  it('rejects inactive, revoked, and forged role or org access before any export is allowed', () => {
    expect(evaluateSecurityAccess({
      isAuthenticated: true,
      roleCode: 'intern_or_researcher',
      hasMembership: true,
      isActiveMember: false,
      isProviderConnected: true,
      targetOrganizationId: 'org-1',
      actorOrganizationId: 'org-1',
    }).allowed).toBe(false)

    expect(evaluateSecurityAccess({
      isAuthenticated: true,
      roleCode: 'product_owner',
      hasMembership: false,
      isActiveMember: false,
      isProviderConnected: true,
    }).allowed).toBe(false)

    expect(evaluateSecurityAccess({
      isAuthenticated: true,
      roleCode: 'forged_role',
      hasMembership: true,
      isActiveMember: true,
      targetOrganizationId: 'org-1',
      actorOrganizationId: 'org-1',
      isProviderConnected: true,
    }).allowed).toBe(false)
  })

  it('requires provider connectivity and rejects expired export requests', () => {
    expect(evaluateSecurityAccess({
      isAuthenticated: true,
      roleCode: 'platform_admin',
      hasMembership: true,
      isActiveMember: true,
      isProviderConnected: false,
      isExportRequestValid: true,
    }).state).toBe('disconnected')

    expect(evaluateSecurityAccess({
      isAuthenticated: true,
      roleCode: 'platform_admin',
      hasMembership: true,
      isActiveMember: true,
      isProviderConnected: true,
      isExpired: true,
      isExportRequestValid: true,
    }).state).toBe('denied')
  })

  it('enforces D9-affiliation and PII protections for restricted roles', () => {
    expect(evaluateSecurityAccess({
      isAuthenticated: true,
      roleCode: 'intern_or_researcher',
      hasMembership: true,
      isActiveMember: true,
      requiresD9Affiliation: true,
      isProviderConnected: true,
    }).allowed).toBe(false)

    expect(evaluateSecurityAccess({
      isAuthenticated: true,
      roleCode: 'content_manager',
      hasMembership: true,
      isActiveMember: true,
      requiresPiiAccess: true,
      isProviderConnected: true,
    }).allowed).toBe(false)
  })

  it('requires an active provider and denies export generation when the request itself is invalid', () => {
    expect(evaluateSecurityAccess({
      isAuthenticated: true,
      roleCode: 'verification_reviewer',
      hasMembership: true,
      isActiveMember: true,
      isProviderConnected: true,
      isExportRequestValid: false,
      requiresD9Affiliation: true,
    }).state).toBe('failure')
  })

  it('allows the approved repository roles to continue when organization and provider conditions are valid', () => {
    expect(evaluateSecurityAccess({
      isAuthenticated: true,
      roleCode: 'platform_admin',
      hasMembership: true,
      isActiveMember: true,
      targetOrganizationId: 'org-1',
      actorOrganizationId: 'org-1',
      isProviderConnected: true,
      isExportRequestValid: true,
      requiresD9Affiliation: true,
      requiresPiiAccess: true,
    }).allowed).toBe(true)

    expect(evaluateSecurityAccess({
      isAuthenticated: true,
      roleCode: 'verification_reviewer',
      hasMembership: true,
      isActiveMember: true,
      targetOrganizationId: 'org-2',
      actorOrganizationId: 'org-2',
      isProviderConnected: true,
      isExportRequestValid: true,
      requiresD9Affiliation: true,
    }).allowed).toBe(true)
  })

  it('keeps the export workflow state consistent with no-public-url and provider-disabled rules', () => {
    const state = evaluateSecurityAccess({
      isAuthenticated: true,
      roleCode: 'platform_admin',
      hasMembership: true,
      isActiveMember: true,
      isProviderConnected: false,
      isExportRequestValid: true,
    })

    expect(state.state).toBe('disconnected')
    expect(state.allowed).toBe(false)
    expect(state.reason).toContain('provider')
  })
})
