import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { parseSync } from 'pgsql-parser'
import { describe, expect, it } from 'vitest'
import { assertRepositoryRoleAccess, evaluateSecurityAccess, getRepositoryRoleDefinition, repositoryRoleDefinitions } from './securityLiveAcceptance'

const normalizeSource = (source: string) => source.replace(/\s+/g, ' ').toLowerCase()

const createExportRequestNoClientActorId = (fn: { proargnames?: string[] | null; prosrc?: string | null }) => {
  const argNames = fn.proargnames ?? []
  const canonicalArgs = ['p_resource_type', 'p_export_scope', 'p_target_tenant_id', 'p_request_reason', 'p_expires_at']
  const forbidden = ['p_actor_id', 'p_requested_by', 'p_generated_by', 'p_downloaded_by', 'actor_id', 'requested_by', 'generated_by', 'downloaded_by']

  const hasCanonicalSignature = argNames.length === canonicalArgs.length
    && canonicalArgs.every((name, index) => argNames[index] === name)

  const hasNoActorArgument = forbidden.every((name) => !argNames.includes(name))

  return hasCanonicalSignature && hasNoActorArgument
}

const createExportRequestTrustedActorAttribution = (fn: { proargnames?: string[] | null; prosrc?: string | null }) => {
  const argNames = fn.proargnames ?? []
  const normalized = normalizeSource(fn.prosrc ?? '')
  const canonicalArgs = ['p_resource_type', 'p_export_scope', 'p_target_tenant_id', 'p_request_reason', 'p_expires_at']
  const forbidden = ['p_actor_id', 'p_requested_by', 'p_generated_by', 'p_downloaded_by', 'actor_id', 'requested_by', 'generated_by', 'downloaded_by']

  const hasCanonicalSignature = argNames.length === canonicalArgs.length
    && canonicalArgs.every((name, index) => argNames[index] === name)
  const hasNoActorArgument = forbidden.every((name) => !argNames.includes(name))
  const hasAuthUid = normalized.includes('auth.uid()') && normalized.includes('v_actor := auth.uid()')
  const rejectsAnonymous = normalized.includes('if v_actor is null') && normalized.includes('anonymous export requests are denied')
  const assertsAuthorization = normalized.includes('public.assert_repository_export_authorization')
  const mentionsRequestedBy = normalized.includes('requested_by')
  const writesVActorAsRequestor = /insert\s+into\s+public\.export_requests\s*\([^)]*requested_by[^)]*\)\s*values\s*\([^)]*v_actor[^)]*\)/.test(normalized)

  return hasCanonicalSignature && hasNoActorArgument && hasAuthUid && rejectsAnonymous && assertsAuthorization && mentionsRequestedBy && writesVActorAsRequestor
}

describe('release 3F security and live acceptance', () => {
  it('keeps the 3F migration and verifier aligned to the real repository role model and export audit flow', () => {
    const migrationSql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20260912_000001_milestone_3f_security_live_acceptance.sql'), 'utf8')
    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_milestone_3f_security_live_acceptance.sql'), 'utf8')

    expect(migrationSql).toContain('CREATE TABLE IF NOT EXISTS public.export_requests')
    expect(migrationSql).toContain('CREATE TABLE IF NOT EXISTS public.export_audit_events')
    expect(migrationSql).toContain('CREATE OR REPLACE FUNCTION public.create_export_request')
    expect(migrationSql).toContain('CREATE OR REPLACE FUNCTION public.record_export_generation')
    expect(migrationSql).toContain('CREATE OR REPLACE FUNCTION public.record_export_download')
    expect(migrationSql).toContain('DROP FUNCTION IF EXISTS public.record_export_download(uuid, text, uuid)')
    expect(migrationSql).toContain('auth.uid()')
    expect(migrationSql).toContain('requested_by = auth.uid()')
    expect(migrationSql).toContain('v_actor := auth.uid()')
    expect(migrationSql).toContain('p_target_tenant_id')
    expect(migrationSql).not.toContain('p_actor_id')
    expect(migrationSql).not.toContain('p_downloaded_by')
    expect(migrationSql).not.toContain('p_requested_by')
    expect(migrationSql).toContain('public.current_user_is_platform_admin()')
    expect(migrationSql).toContain('public.user_has_permission')
    expect(migrationSql).toContain('REVOKE ALL ON FUNCTION public.record_export_download')
    expect(migrationSql).toContain('DROP TRIGGER IF EXISTS export_requests_set_updated_at')

    expect(verifierSql).toContain('public.export_requests')
    expect(verifierSql).toContain('public.export_audit_events')
    expect(verifierSql).toContain('overall_status')
    expect(verifierSql).toContain('public.record_export_download(uuid,text)')
    expect(verifierSql).toContain('array_position(p.proargnames, \'p_actor_id\') IS NULL')
    expect(verifierSql).toContain("array_position(p.proargnames, 'p_requested_by') IS NULL")
    expect(verifierSql).not.toContain('public.record_export_download(uuid,text,uuid)')
    expect(verifierSql).not.toContain('coalesce(p_downloaded_by, auth.uid())')
    expect(verifierSql).toContain('Release 3F security and live acceptance verification PASSED')

    expect(() => parseSync(migrationSql)).not.toThrow()
    expect(() => parseSync(verifierSql)).not.toThrow()
    console.log('MIGRATION_3F_PARSE_OK')
    console.log('VERIFIER_3F_PARSE_OK')
  })

  it('rejects stale client actor arguments and preserves the canonical live create_export_request definition', () => {
    const canonicalSource = `
      v_actor := auth.uid();
      if v_actor is null then
        raise exception 'Anonymous export requests are denied. Authentication is required.';
      end if;
      if not public.assert_repository_export_authorization(p_resource_type, p_export_scope, p_target_tenant_id) then
        raise exception 'Permission denied';
      end if;
      insert into public.export_requests (
        resource_type,
        export_scope,
        target_tenant_id,
        requested_by,
        status,
        request_reason,
        expires_at,
        metadata
      ) values (
        p_resource_type,
        p_export_scope,
        p_target_tenant_id,
        v_actor,
        'pending',
        p_request_reason,
        coalesce(p_expires_at, now() + interval '24 hours'),
        jsonb_build_object('source', 'repository_workflow', 'actor_user_id', v_actor::text, 'resource_type', p_resource_type)
      );
    `

    const canonical = {
      proargnames: ['p_resource_type', 'p_export_scope', 'p_target_tenant_id', 'p_request_reason', 'p_expires_at'],
      prosrc: canonicalSource,
    }

    const liveDiagnosticMatch = {
      proargnames: ['p_resource_type', 'p_export_scope', 'p_target_tenant_id', 'p_request_reason', 'p_expires_at'],
      prosrc: `
        v_actor := auth.uid();
        if v_actor is null then
          raise exception 'Anonymous export requests are denied. Authentication is required.';
        end if;
        if not public.assert_repository_export_authorization(p_resource_type, p_export_scope, p_target_tenant_id) then
          raise exception 'Permission denied';
        end if;
        insert into public.export_requests (
          resource_type,
          export_scope,
          target_tenant_id,
          requested_by,
          status,
          request_reason,
          expires_at,
          metadata
        ) values (
          p_resource_type,
          p_export_scope,
          p_target_tenant_id,
          v_actor,
          'pending',
          p_request_reason,
          coalesce(p_expires_at, now() + interval '24 hours'),
          jsonb_build_object('source', 'repository_workflow', 'actor_user_id', v_actor::text, 'resource_type', p_resource_type)
        );
      `,
    }

    const staleActor = {
      proargnames: ['p_resource_type', 'p_export_scope', 'p_target_tenant_id', 'p_actor_id', 'p_request_reason', 'p_expires_at'],
      prosrc: canonicalSource,
    }

    const staleRequestedBy = {
      proargnames: ['p_resource_type', 'p_export_scope', 'p_target_tenant_id', 'p_requested_by', 'p_expires_at'],
      prosrc: canonicalSource,
    }

    const targetTenantAllowed = {
      proargnames: ['p_resource_type', 'p_export_scope', 'p_target_tenant_id', 'p_request_reason', 'p_expires_at'],
      prosrc: canonicalSource,
    }

    const targetTenantUsedAsActor = {
      proargnames: ['p_resource_type', 'p_export_scope', 'p_target_tenant_id', 'p_request_reason', 'p_expires_at'],
      prosrc: canonicalSource,
    }

    const clientControlledRequestor = {
      proargnames: ['p_resource_type', 'p_export_scope', 'p_target_tenant_id', 'p_request_reason', 'p_expires_at'],
      prosrc: canonicalSource.replace('v_actor,', 'p_request_reason,').replace("'actor_user_id', v_actor::text", "'actor_user_id', p_request_reason::text"),
    }

    const noAuthUid = {
      proargnames: ['p_resource_type', 'p_export_scope', 'p_target_tenant_id', 'p_request_reason', 'p_expires_at'],
      prosrc: canonicalSource.replace('v_actor := auth.uid();', 'v_actor := null;'),
    }

    const wrongAttribution = {
      proargnames: ['p_resource_type', 'p_export_scope', 'p_target_tenant_id', 'p_request_reason', 'p_expires_at'],
      prosrc: canonicalSource.replace('v_actor,', "'system',").replace("'actor_user_id', v_actor::text", "'actor_user_id', 'system'::text"),
    }

    expect(createExportRequestNoClientActorId(canonical)).toBe(true)
    expect(createExportRequestNoClientActorId(liveDiagnosticMatch)).toBe(true)
    expect(createExportRequestNoClientActorId(targetTenantAllowed)).toBe(true)
    expect(createExportRequestNoClientActorId(staleActor)).toBe(false)
    expect(createExportRequestNoClientActorId(staleRequestedBy)).toBe(false)
    expect(createExportRequestNoClientActorId(targetTenantUsedAsActor)).toBe(true)
    expect(createExportRequestNoClientActorId(clientControlledRequestor)).toBe(true)
    expect(createExportRequestTrustedActorAttribution(canonical)).toBe(true)
    expect(createExportRequestTrustedActorAttribution(noAuthUid)).toBe(false)
    expect(createExportRequestTrustedActorAttribution(clientControlledRequestor)).toBe(false)
    expect(createExportRequestTrustedActorAttribution(wrongAttribution)).toBe(false)
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
