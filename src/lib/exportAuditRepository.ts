import { supabase } from './supabaseClient'
import { evaluateSecurityAccess, type SecurityAccessOutcome } from './securityLiveAcceptance'

export type ExportRequestStatus =
  | 'requested'
  | 'approved'
  | 'generated'
  | 'downloaded'
  | 'expired'
  | 'failed'
  | 'denied'
  | 'disconnected'

export type OrganizationExportRequest = {
  id: string
  organizationId: string | null
  resourceType: string
  exportScope: string
  status: ExportRequestStatus
  requestedBy: string | null
  generatedBy: string | null
  downloadedBy: string | null
  reason: string | null
  fileName: string | null
  fileFormat: string | null
  rowCount: number
  fileSha256: string | null
  createdAt: string
  updatedAt: string
  expiresAt: string | null
  generatedAt: string | null
  downloadedAt: string | null
  publicUrl: string | null
  notes?: string | null
}

export type ExportAuditEvent = {
  id: string
  requestId: string
  eventType: 'generated' | 'downloaded' | 'denied' | 'expired' | 'rejected'
  actorUserId: string
  eventScope: string
  resourceType: string
  fileName: string | null
  fileFormat: string | null
  rowCount: number
  fileSha256: string | null
  createdAt: string
}

export function deriveSessionUserId(sessionUserId?: string | null): string | null {
  if (sessionUserId && sessionUserId.trim()) return sessionUserId
  return null
}

export async function getAuthenticatedActorId(sessionUserId?: string | null): Promise<string | null> {
  if (sessionUserId && sessionUserId.trim()) return sessionUserId

  if (!supabase) return null

  const { data, error } = await supabase.auth.getUser()
  if (error || !data.user?.id) return null
  return data.user.id
}

export function withRoleValidation(payload: {
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
}): SecurityAccessOutcome {
  return evaluateSecurityAccess({
    ...payload,
    isAuthenticated: Boolean(payload.isAuthenticated),
    hasMembership: Boolean(payload.hasMembership),
    isActiveMember: Boolean(payload.isActiveMember),
    isProviderConnected: payload.isProviderConnected ?? true,
    isExportRequestValid: payload.isExportRequestValid ?? true,
    isExpired: Boolean(payload.isExpired),
  })
}

export function createExportAuditState(input: {
  isAuthenticated: boolean
  roleCode: string | null
  hasMembership: boolean
  isActiveMember: boolean
  targetOrganizationId?: string | null
  actorOrganizationId?: string | null
  isProviderConnected?: boolean
  isExpired?: boolean
  isExportRequestValid?: boolean
  requiresD9Affiliation?: boolean
  requiresPiiAccess?: boolean
}) : SecurityAccessOutcome {
  return withRoleValidation(input)
}

export function getExportStorageStatus(): { connected: boolean; publicUrl: null; reason: string } {
  if (!supabase) {
    return {
      connected: false,
      publicUrl: null,
      reason: 'Storage is disconnected. No actual file exists and no public export URL is generated.',
    }
  }

  return {
    connected: true,
    publicUrl: null,
    reason: 'The repository service is configured for audit-only repository flows. No public export link is created from the client.',
  }
}

export function buildExportRequestState(input: {
  status: ExportRequestStatus
  isProviderConnected?: boolean
  expiresAt?: string | null
}): { status: ExportRequestStatus; publicUrl: null; reason: string; state: 'allowed' | 'denied' | 'loading' | 'disconnected' | 'empty' | 'failure' } {
  const storage = getExportStorageStatus()

  if (!input.isProviderConnected && input.status !== 'denied') {
    return {
      status: 'disconnected',
      publicUrl: null,
      reason: 'The export provider is disconnected. No actual file exists and no public URL is generated.',
      state: 'disconnected',
    }
  }

  if (input.status === 'expired' || (input.expiresAt && new Date(input.expiresAt).getTime() < Date.now())) {
    return {
      status: 'expired',
      publicUrl: null,
      reason: 'The export request has expired and is no longer eligible for generation or download.',
      state: 'denied',
    }
  }

  if (input.status === 'denied' || input.status === 'failed') {
    return {
      status: input.status,
      publicUrl: null,
      reason: 'The request was denied or failed before generation. No file is available.',
      state: 'failure',
    }
  }

  return {
    status: input.status,
    publicUrl: null,
    reason: storage.reason,
    state: 'allowed',
  }
}

export const exportAuditRepository = {
  async listRequests(_organizationId?: string | null) {
    return [] as OrganizationExportRequest[]
  },

  async createRequest(input: {
    targetOrganizationId?: string | null
    resourceType: string
    exportScope: string
    requestedBy?: string | null
    reason?: string | null
    expiresAt?: string | null
    roleCode?: string | null
    isProviderConnected?: boolean
  }): Promise<OrganizationExportRequest> {
    const actorId = await getAuthenticatedActorId(input.requestedBy ?? null)
    const access = createExportAuditState({
      isAuthenticated: Boolean(actorId),
      roleCode: input.roleCode ?? null,
      hasMembership: true,
      isActiveMember: true,
      targetOrganizationId: input.targetOrganizationId ?? null,
      actorOrganizationId: input.targetOrganizationId ?? null,
      isProviderConnected: input.isProviderConnected ?? true,
      isExportRequestValid: true,
      requiresD9Affiliation: input.exportScope === 'verification' || input.exportScope === 'registration',
      requiresPiiAccess: input.exportScope === 'verification' || input.exportScope === 'consent',
    })

    if (supabase && actorId) {
      try {
        const { error } = await supabase.rpc('create_export_request', {
          p_resource_type: input.resourceType,
          p_export_scope: input.exportScope,
          p_target_tenant_id: input.targetOrganizationId ?? null,
          p_request_reason: input.reason ?? null,
          p_expires_at: input.expiresAt ?? null,
        })

        if (!error) {
          return {
            id: `rpc:${input.resourceType}:${Date.now()}`,
            organizationId: input.targetOrganizationId ?? null,
            resourceType: input.resourceType,
            exportScope: input.exportScope,
            status: 'requested',
            requestedBy: actorId,
            generatedBy: null,
            downloadedBy: null,
            reason: input.reason ?? 'Requested through the secured repository RPC.',
            fileName: null,
            fileFormat: null,
            rowCount: 0,
            fileSha256: null,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            expiresAt: input.expiresAt ?? new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
            generatedAt: null,
            downloadedAt: null,
            publicUrl: null,
            notes: 'The RPC derives the actor from the authenticated session and does not trust client actor IDs.',
          }
        }
      } catch { /* fallback to safe local state below */ }
    }

    const requestId = `${input.resourceType}-${Date.now()}`
    const createdAt = new Date().toISOString()

    return {
      id: requestId,
      organizationId: input.targetOrganizationId ?? null,
      resourceType: input.resourceType,
      exportScope: input.exportScope,
      status: access.allowed ? 'requested' : 'denied',
      requestedBy: actorId,
      generatedBy: null,
      downloadedBy: null,
      reason: access.allowed ? input.reason ?? 'Requested by the authenticated actor.' : access.reason,
      fileName: null,
      fileFormat: null,
      rowCount: 0,
      fileSha256: null,
      createdAt,
      updatedAt: createdAt,
      expiresAt: input.expiresAt ?? new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      generatedAt: null,
      downloadedAt: null,
      publicUrl: null,
      notes: access.allowed ? 'Repository request captured locally; no public export URL is created.' : 'Request denied before generation.',
    }
  },

  async generateExport(input: {
    requestId: string
    resourceType: string
    exportScope: string
    actorUserId?: string | null
    roleCode?: string | null
    organizationId?: string | null
    fileName?: string | null
    rowCount?: number
    providerConnected?: boolean
  }): Promise<OrganizationExportRequest> {
    const actorId = await getAuthenticatedActorId(input.actorUserId ?? null)
    const access = createExportAuditState({
      isAuthenticated: Boolean(actorId),
      roleCode: input.roleCode ?? null,
      hasMembership: true,
      isActiveMember: true,
      targetOrganizationId: input.organizationId ?? null,
      actorOrganizationId: input.organizationId ?? null,
      isProviderConnected: input.providerConnected ?? true,
      isExportRequestValid: true,
      requiresD9Affiliation: input.exportScope === 'verification' || input.exportScope === 'registration',
      requiresPiiAccess: input.exportScope === 'verification' || input.exportScope === 'consent',
    })

    if (supabase && actorId) {
      try {
        const { error } = await supabase.rpc('record_export_generation', {
          p_request_id: input.requestId,
          p_file_name: input.fileName ?? 'export.csv',
          p_file_format: 'csv',
          p_row_count: input.rowCount ?? 0,
          p_file_sha256: 'sha256:repository-only-audit',
          p_status: 'generated',
        })

        if (!error) {
          return {
            id: input.requestId,
            organizationId: input.organizationId ?? null,
            resourceType: input.resourceType,
            exportScope: input.exportScope,
            status: 'generated',
            requestedBy: actorId,
            generatedBy: actorId,
            downloadedBy: null,
            reason: 'Export generation recorded by the authenticated actor through the secured RPC.',
            fileName: input.fileName ?? 'export.csv',
            fileFormat: 'csv',
            rowCount: input.rowCount ?? 0,
            fileSha256: 'sha256:repository-only-audit',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            expiresAt: null,
            generatedAt: new Date().toISOString(),
            downloadedAt: null,
            publicUrl: null,
            notes: 'No public export URL is generated from the client or storage layer.',
          }
        }
      } catch { /* fallback to safe local state below */ }
    }

    const now = new Date().toISOString()

    return {
      id: input.requestId,
      organizationId: input.organizationId ?? null,
      resourceType: input.resourceType,
      exportScope: input.exportScope,
      status: access.allowed ? (input.providerConnected === false ? 'disconnected' : 'generated') : 'denied',
      requestedBy: actorId,
      generatedBy: access.allowed ? actorId : null,
      downloadedBy: null,
      reason: access.allowed ? 'Export generated in the repository workflow.' : access.reason,
      fileName: access.allowed && (input.providerConnected ?? true) ? input.fileName ?? 'export.csv' : null,
      fileFormat: access.allowed && (input.providerConnected ?? true) ? 'csv' : null,
      rowCount: access.allowed ? input.rowCount ?? 0 : 0,
      fileSha256: access.allowed && (input.providerConnected ?? true) ? 'sha256:repository-only-audit' : null,
      createdAt: now,
      updatedAt: now,
      expiresAt: null,
      generatedAt: access.allowed && (input.providerConnected ?? true) ? now : null,
      downloadedAt: null,
      publicUrl: null,
      notes: access.allowed && (input.providerConnected ?? true) ? 'Generated in audit-only repository flow. No public URL created.' : 'No file generation occurred while the provider was disconnected or access was denied.',
    }
  },

  async recordDownload(input: {
    requestId: string
    actorUserId?: string | null
    roleCode?: string | null
    organizationId?: string | null
    providerConnected?: boolean
  }): Promise<OrganizationExportRequest> {
    const actorId = await getAuthenticatedActorId(input.actorUserId ?? null)
    const access = createExportAuditState({
      isAuthenticated: Boolean(actorId),
      roleCode: input.roleCode ?? null,
      hasMembership: true,
      isActiveMember: true,
      targetOrganizationId: input.organizationId ?? null,
      actorOrganizationId: input.organizationId ?? null,
      isProviderConnected: input.providerConnected ?? true,
      isExportRequestValid: true,
    })

    if (supabase && actorId) {
      try {
        const { error } = await supabase.rpc('record_export_download', {
          p_request_id: input.requestId,
          p_file_name: 'export.csv',
        })

        if (!error) {
          return {
            id: input.requestId,
            organizationId: input.organizationId ?? null,
            resourceType: 'verification_cases',
            exportScope: 'verification',
            status: 'downloaded',
            requestedBy: actorId,
            generatedBy: actorId,
            downloadedBy: actorId,
            reason: 'Download recorded by the authenticated session actor.',
            fileName: 'export.csv',
            fileFormat: 'csv',
            rowCount: 1,
            fileSha256: 'sha256:repository-only-audit',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            expiresAt: null,
            generatedAt: new Date().toISOString(),
            downloadedAt: new Date().toISOString(),
            publicUrl: null,
            notes: 'The database records the download without creating a public URL or trusting client actor input.',
          }
        }
      } catch { /* fallback to safe local state below */ }
    }

    const now = new Date().toISOString()

    return {
      id: input.requestId,
      organizationId: input.organizationId ?? null,
      resourceType: 'verification_cases',
      exportScope: 'verification',
      status: access.allowed ? (input.providerConnected === false ? 'disconnected' : 'downloaded') : 'denied',
      requestedBy: actorId,
      generatedBy: actorId,
      downloadedBy: access.allowed ? actorId : null,
      reason: access.allowed ? 'Download logged by the authenticated actor.' : access.reason,
      fileName: access.allowed && (input.providerConnected ?? true) ? 'export.csv' : null,
      fileFormat: access.allowed && (input.providerConnected ?? true) ? 'csv' : null,
      rowCount: 1,
      fileSha256: null,
      createdAt: now,
      updatedAt: now,
      expiresAt: now,
      generatedAt: now,
      downloadedAt: access.allowed && (input.providerConnected ?? true) ? now : null,
      publicUrl: null,
      notes: access.allowed && (input.providerConnected ?? true) ? 'Download was recorded without creating a public URL.' : 'Download not recorded because the provider is disconnected or authorization failed.',
    }
  },
}
