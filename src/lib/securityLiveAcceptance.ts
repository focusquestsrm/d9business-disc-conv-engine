export type RepositoryRoleCode =
  | 'platform_admin'
  | 'product_owner'
  | 'campaign_manager'
  | 'operator'
  | 'intern_or_researcher'
  | 'verification_reviewer'
  | 'content_manager'
  | 'membership_growth_owner'
  | 'executive_leader'

export type RepositoryRoleDefinition = {
  code: RepositoryRoleCode
  label: string
  permissions: string[]
  d9AffiliationAccess: 'all' | 'review_only' | 'restricted'
  piiAccess: 'all' | 'verification_only' | 'none'
  organizationScope: 'global' | 'tenant' | 'restricted'
}

export const repositoryRoleDefinitions: RepositoryRoleDefinition[] = [
  {
    code: 'platform_admin',
    label: 'Platform Administrator',
    permissions: ['view_platform', 'manage_users', 'manage_roles', 'manage_application_settings', 'manage_organization_settings', 'manage_integrations', 'view_audit_events', 'view_operational_modules', 'view_verification_modules', 'view_content_modules', 'view_conversion_modules', 'view_executive_reporting'],
    d9AffiliationAccess: 'all',
    piiAccess: 'all',
    organizationScope: 'global',
  },
  {
    code: 'product_owner',
    label: 'Product Owner',
    permissions: ['view_platform', 'view_operational_modules', 'view_verification_modules', 'view_content_modules', 'view_conversion_modules', 'view_executive_reporting'],
    d9AffiliationAccess: 'all',
    piiAccess: 'verification_only',
    organizationScope: 'global',
  },
  {
    code: 'campaign_manager',
    label: 'Campaign Manager',
    permissions: ['view_platform', 'view_operational_modules', 'view_verification_modules', 'view_content_modules', 'view_conversion_modules', 'view_executive_reporting'],
    d9AffiliationAccess: 'review_only',
    piiAccess: 'verification_only',
    organizationScope: 'tenant',
  },
  {
    code: 'operator',
    label: 'Operator',
    permissions: ['view_platform', 'view_operational_modules'],
    d9AffiliationAccess: 'review_only',
    piiAccess: 'verification_only',
    organizationScope: 'tenant',
  },
  {
    code: 'intern_or_researcher',
    label: 'Intern or Researcher',
    permissions: ['view_platform', 'view_operational_modules'],
    d9AffiliationAccess: 'restricted',
    piiAccess: 'none',
    organizationScope: 'tenant',
  },
  {
    code: 'verification_reviewer',
    label: 'Verification Reviewer',
    permissions: ['view_platform', 'view_verification_modules'],
    d9AffiliationAccess: 'all',
    piiAccess: 'verification_only',
    organizationScope: 'tenant',
  },
  {
    code: 'content_manager',
    label: 'Content Manager',
    permissions: ['view_platform', 'view_content_modules'],
    d9AffiliationAccess: 'review_only',
    piiAccess: 'none',
    organizationScope: 'tenant',
  },
  {
    code: 'membership_growth_owner',
    label: 'Membership or Growth Owner',
    permissions: ['view_platform', 'view_conversion_modules', 'view_verification_modules'],
    d9AffiliationAccess: 'all',
    piiAccess: 'verification_only',
    organizationScope: 'tenant',
  },
  {
    code: 'executive_leader',
    label: 'Executive or Leader',
    permissions: ['view_platform', 'view_executive_reporting'],
    d9AffiliationAccess: 'review_only',
    piiAccess: 'none',
    organizationScope: 'tenant',
  },
]

export function getRepositoryRoleDefinition(roleCode: string | null): RepositoryRoleDefinition | undefined {
  return repositoryRoleDefinitions.find((role) => role.code === roleCode)
}

export function assertRepositoryRoleAccess(roleCode: string | null, permission: string): boolean {
  const role = getRepositoryRoleDefinition(roleCode)
  if (!role) return false
  return role.permissions.includes(permission)
}

export type SecurityAccessOutcome = {
  allowed: boolean
  reason: string
  state: 'allowed' | 'denied' | 'loading' | 'disconnected' | 'empty' | 'failure'
}

export function evaluateSecurityAccess(payload: {
  isAuthenticated: boolean
  roleCode: string | null
  hasMembership: boolean
  isActiveMember: boolean
  targetOrganizationId?: string | null
  actorOrganizationId?: string | null
  requiresD9Affiliation?: boolean
  requiresPiiAccess?: boolean
  isProviderConnected?: boolean
  isExportRequestValid?: boolean
  isExpired?: boolean
}) : SecurityAccessOutcome {
  if (!payload.isAuthenticated) {
    return { allowed: false, reason: 'Anonymous access is denied. Authenticated staff membership is required.', state: 'denied' }
  }

  if (!payload.hasMembership || !payload.isActiveMember) {
    return { allowed: false, reason: 'Authenticated user has no active membership record or membership is inactive or revoked.', state: 'denied' }
  }

  const role = payload.roleCode ? getRepositoryRoleDefinition(payload.roleCode) : undefined
  if (!role) {
    return { allowed: false, reason: 'Unknown or forged repository role is denied before any export action can proceed.', state: 'denied' }
  }

  if (!payload.isProviderConnected) {
    return { allowed: false, reason: 'Required provider integration is disconnected. No generated or downloaded export may be claimed while the provider is disabled.', state: 'disconnected' }
  }

  if (payload.targetOrganizationId && payload.actorOrganizationId && payload.targetOrganizationId !== payload.actorOrganizationId) {
    return { allowed: false, reason: 'Cross-organization access is denied. The actor does not match the target organization boundary.', state: 'denied' }
  }

  if (payload.requiresD9Affiliation && payload.roleCode) {
    const role = getRepositoryRoleDefinition(payload.roleCode)
    if (!role || (role.d9AffiliationAccess === 'restricted' && payload.requiresD9Affiliation)) {
      return { allowed: false, reason: 'D9 affiliation access is restricted for the current role.', state: 'denied' }
    }
  }

  if (payload.requiresPiiAccess && payload.roleCode) {
    const role = getRepositoryRoleDefinition(payload.roleCode)
    if (!role || role.piiAccess === 'none' || role.piiAccess === 'verification_only' && !payload.requiresPiiAccess) {
      return { allowed: false, reason: 'PII access is not permitted for the current role.', state: 'denied' }
    }
  }

  if (payload.isExpired) {
    return { allowed: false, reason: 'The export or approval request has expired and cannot continue.', state: 'denied' }
  }

  if (payload.isExportRequestValid === false) {
    return { allowed: false, reason: 'Export request validation failed. This action is rejected until the request is complete.', state: 'failure' }
  }

  return { allowed: true, reason: 'Authorization matches the repository role model and organization scope.', state: 'allowed' }
}

export function getSecurityStatusSummary(): { items: Array<{ label: string; value: string; state: 'ok' | 'warning' | 'alert' }> } {
  return {
    items: [
      { label: 'Role model', value: 'Repository-backed roles + permissions', state: 'ok' },
      { label: 'Anonymous access', value: 'Blocked', state: 'alert' },
      { label: 'Cross-org access', value: 'Denied by scope check', state: 'alert' },
      { label: 'Provider connectivity', value: 'Disconnected by default', state: 'warning' },
      { label: 'Export auditing', value: 'Requires auth.uid() and organization scoping', state: 'ok' },
    ],
  }
}
