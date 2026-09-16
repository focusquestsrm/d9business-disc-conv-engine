import { buildProviderError, normalizeProviderConnectionState, type ProviderConnectionState, type ProviderError } from './socialProvider'

export type ProviderServiceStatus = {
  state: ProviderConnectionState
  requiresConfiguration: boolean
  lastSuccessfulProviderCheck: string | null
  reason: string
  safeMetadata: Record<string, unknown>
}

export type ProviderDestinationSummary = {
  id: string
  provider: 'meta'
  channel: 'facebook_page' | 'instagram_business'
  name: string
  status: 'connected' | 'disabled' | 'needs_attention'
  connectionState: ProviderConnectionState
}

export type PublishReviewResult = {
  allowed: boolean
  reason: string
  state: 'ready' | 'blocked'
  providerState: ProviderConnectionState
  requiresReapproval: boolean
}

export type SocialEligibilityInput = {
  consentGranted: boolean
  optOutActive: boolean
  suppressionActive: boolean
  cooldownOk: boolean
  connectionState: ProviderConnectionState
  destinationState: 'connected' | 'disabled' | 'needs_attention' | 'unknown'
  capabilitySupported: boolean
  hasApprovedContent: boolean
  contentVersionMatches: boolean
  reason?: string
}

export type SocialEligibilityResult = {
  eligible: boolean
  status: 'eligible' | 'blocked' | 'error'
  reasons: string[]
  connectionState: ProviderConnectionState
  destinationState: SocialEligibilityInput['destinationState']
  capabilitySupported: boolean
  consentGranted: boolean
  requiresReapproval: boolean
}

export type SocialQueueRecord = {
  id: string
  title: string
  status: 'approved' | 'scheduled' | 'queued' | 'blocked'
  provider: 'meta'
  approvalState: 'approved' | 'pending' | 'rejected'
  reason: string
  scheduledAt?: string | null
}

export type SocialScheduledPost = {
  id: string
  title: string
  scheduled: string
  status: 'scheduled' | 'awaiting_approval'
}

export type SocialActivityRecord = {
  id: string
  title: string
  status: 'published' | 'failed'
  providerStatus: ProviderConnectionState
  updatedAt: string
}

export type SocialInboundSnapshot = {
  id: string
  provider: 'meta'
  eventType: string
  eventId: string | null
  status: 'received' | 'ignored'
  accountId: string | null
  pageId: string | null
}

const PROVIDER_ENDPOINT = '/.netlify/functions/social-provider'

async function fetchSecureServerJson(operation: string, init: RequestInit = {}): Promise<Record<string, unknown> | null> {
  if (typeof window === 'undefined' || typeof fetch !== 'function') {
    return null
  }

  const url = new URL(PROVIDER_ENDPOINT, window.location.origin)
  url.searchParams.set('operation', operation)

  try {
    const response = await fetch(url.toString(), {
      ...init,
      credentials: 'same-origin',
      headers: {
        'Content-Type': 'application/json',
        ...(init.headers ?? {}),
      },
    })

    if (!response.ok) {
      return null
    }

    return (await response.json().catch(() => null)) as Record<string, unknown> | null
  } catch {
    return null
  }
}

export function getSafeMetaConfig(): { configured: boolean; appIdConfigured: boolean; webhookConfigured: boolean } {
  return { configured: false, appIdConfigured: false, webhookConfigured: false }
}

export async function getSecureProviderStatusAsync(): Promise<ProviderServiceStatus> {
  const payload = await fetchSecureServerJson('status')
  if (!payload || typeof payload !== 'object') {
    return {
      state: 'configuration_required',
      requiresConfiguration: true,
      lastSuccessfulProviderCheck: null,
      reason: 'Meta is not configured in the secure deployment environment yet.',
      safeMetadata: { provider: 'meta', mode: 'server_side_only', connectionStatus: 'configuration_required' },
    }
  }

  const state = normalizeProviderConnectionState(String((payload.state as string | undefined) ?? 'configuration_required')) ?? 'configuration_required'
  return {
    state,
    requiresConfiguration: Boolean(payload.requiresConfiguration),
    lastSuccessfulProviderCheck: typeof payload.lastSuccessfulProviderCheck === 'string' ? payload.lastSuccessfulProviderCheck : null,
    reason: typeof payload.reason === 'string' ? payload.reason : 'Meta provider status is unavailable in the secure server boundary.',
    safeMetadata: payload.safeMetadata && typeof payload.safeMetadata === 'object' ? (payload.safeMetadata as Record<string, unknown>) : { provider: 'meta', mode: 'server_side_only', connectionStatus: state },
  }
}

export function getSecureProviderStatus(): ProviderServiceStatus {
  return {
    state: 'configuration_required',
    requiresConfiguration: true,
    lastSuccessfulProviderCheck: null,
    reason: 'Meta is not configured in the secure deployment environment yet.',
    safeMetadata: { provider: 'meta', mode: 'server_side_only', connectionStatus: 'configuration_required' },
  }
}

export async function getSecureDestinationSummaryAsync(): Promise<ProviderDestinationSummary[]> {
  const payload = await fetchSecureServerJson('capabilities')
  if (!payload || typeof payload !== 'object') {
    return []
  }

  const rawDestinations = Array.isArray((payload as { destinations?: unknown }).destinations)
    ? ((payload as { destinations: unknown[] }).destinations)
    : []

  return rawDestinations.map((row: any) => ({
    id: String(row.id ?? 'provider-destination'),
    provider: row.provider === 'meta' ? 'meta' : 'meta',
    channel: row.channel === 'instagram_business' ? 'instagram_business' : 'facebook_page',
    name: String(row.name ?? 'Meta destination'),
    status: row.status === 'disabled' ? 'disabled' : 'connected',
    connectionState: normalizeProviderConnectionState(row.connectionState ?? row.state ?? 'configuration_required') ?? 'configuration_required',
  }))
}

export function getSecureDestinationSummary(): ProviderDestinationSummary[] {
  return []
}

export function normalizeProviderWebhook(payload: Record<string, unknown>) {
  const entry = Array.isArray(payload.entry) ? payload.entry : []
  const inspiration = entry[0] as Record<string, unknown> | undefined
  return {
    provider: 'meta',
    eventType: typeof payload.object === 'string' ? payload.object : 'provider_event',
    eventId: typeof inspiration?.id === 'string' ? inspiration.id : typeof payload.event_id === 'string' ? payload.event_id : null,
    accountId: typeof payload.account_id === 'string' ? payload.account_id : null,
    pageId: typeof payload.page_id === 'string' ? payload.page_id : null,
    status: 'received',
    rawSummary: { object: payload.object ?? null, eventType: payload.type ?? null },
  }
}

export function normalizeProviderFailure(error: unknown): ProviderError {
  if (error instanceof Error) {
    return buildProviderError('meta_provider_exception', error.message, true, normalizeProviderConnectionState('provider_error') ?? 'provider_error')
  }

  if (typeof error === 'string') {
    return buildProviderError('meta_provider_error', error, true, normalizeProviderConnectionState('provider_error') ?? 'provider_error')
  }

  return buildProviderError('meta_provider_unknown_error', 'Meta provider error is unavailable for display.', true, normalizeProviderConnectionState('provider_error') ?? 'provider_error')
}

export function approvePublishingDecision(input: {
  contentApproved: boolean
  actorAuthorized: boolean
  destinationConnected: boolean
  consentGranted: boolean
  optOutActive: boolean
  frequencyOk: boolean
  providerAllowed: boolean
  hasAssetRights: boolean
  d9AffiliationApproved: boolean
  providerState: ProviderConnectionState
  contentChangedSinceApproval?: boolean
  scheduledAt?: string | null
}): PublishReviewResult {
  const issues: string[] = []

  if (!input.contentApproved) issues.push('Content approval is required before publishing.')
  if (!input.actorAuthorized) issues.push('Actor is not authorized to publish.')
  if (!input.destinationConnected) issues.push('Destination is disconnected or unavailable.')
  if (!input.consentGranted) issues.push('Consent is missing or withdrawn.')
  if (input.optOutActive) issues.push('Opt-out or suppression blocks the publication.')
  if (!input.frequencyOk) issues.push('Frequency or cooldown rules block publication.')
  if (!input.providerAllowed) issues.push('Provider capability does not allow this publication.')
  if (!input.hasAssetRights) issues.push('Asset rights are not approved.')
  if (!input.d9AffiliationApproved) issues.push('D9 affiliation approval is not active.')
  if (input.providerState === 'permission_limited' || input.providerState === 'reconnect_required' || input.providerState === 'token_expiring' || input.providerState === 'suspended' || input.providerState === 'provider_error') {
    issues.push('Provider health is not currently safe for publication.')
  }
  if (input.contentChangedSinceApproval) issues.push('Edited content requires reapproval before publication.')
  if (input.scheduledAt && new Date(input.scheduledAt).getTime() > Date.now()) issues.push('Scheduled time has not arrived yet.')

  const allowed = issues.length === 0
  return {
    allowed,
    reason: allowed ? 'Ready to publish.' : issues.join(' '),
    state: allowed ? 'ready' : 'blocked',
    providerState: input.providerState,
    requiresReapproval: Boolean(input.contentChangedSinceApproval),
  }
}

export function evaluateSocialEligibility(input: SocialEligibilityInput): SocialEligibilityResult {
  const reasons: string[] = []

  if (!input.consentGranted) reasons.push('Consent is missing or withdrawn for this destination.')
  if (input.optOutActive) reasons.push('Prospect is opted out and cannot receive this outreach.')
  if (input.suppressionActive) reasons.push('Prospect is suppressed and this action is blocked.')
  if (!input.cooldownOk) reasons.push('Cooldown or frequency rules prevent this action right now.')
  if (input.connectionState === 'configuration_required') reasons.push('The provider requires configuration before it can be used.')
  if (input.connectionState === 'disconnected' || input.connectionState === 'provider_error' || input.connectionState === 'suspended') reasons.push('Provider connection is unavailable or unsafe for this action.')
  if (input.destinationState === 'disabled' || input.destinationState === 'needs_attention') reasons.push('The selected destination is not currently eligible for publishing.')
  if (!input.capabilitySupported) reasons.push('The selected destination does not support this action or content type.')
  if (!input.hasApprovedContent) reasons.push('Content has not been approved for publication.')
  if (!input.contentVersionMatches) reasons.push('Approved content was modified and requires renewed approval.')
  if (input.reason?.trim()) reasons.push(input.reason.trim())

  const eligible = reasons.length === 0
  return {
    eligible,
    status: eligible ? 'eligible' : 'blocked',
    reasons,
    connectionState: input.connectionState,
    destinationState: input.destinationState,
    capabilitySupported: input.capabilitySupported,
    consentGranted: input.consentGranted,
    requiresReapproval: !input.contentVersionMatches,
  }
}

export type SocialWorkflowResult = {
  ok: boolean
  state: 'configuration_required' | 'blocked' | 'ready' | 'submitted' | 'approved' | 'rejected' | 'cancelled' | 'scheduled' | 'rescheduled' | 'retry_requested' | 'error'
  reason: string
  jobId: string | null
}

export async function requestSocialPublishingReview(input: {
  prospectId?: string | null
  businessId?: string | null
  destinationId?: string | null
  action?: string | null
  content?: string | null
  schedule?: string | null
  note?: string | null
}): Promise<SocialWorkflowResult> {
  const providerStatus = getSecureProviderStatus()
  if (providerStatus.state === 'configuration_required' || providerStatus.state === 'disconnected') {
    return { ok: false, state: 'configuration_required', reason: 'Publishing is blocked until the secure Meta deployment configuration is complete and verified.', jobId: null }
  }

  const eligibility = evaluateSocialEligibility({
    consentGranted: true,
    optOutActive: false,
    suppressionActive: false,
    cooldownOk: true,
    connectionState: providerStatus.state,
    destinationState: 'connected',
    capabilitySupported: true,
    hasApprovedContent: Boolean((input.content ?? '').trim()),
    contentVersionMatches: true,
  })

  if (!eligibility.eligible) {
    return { ok: false, state: 'blocked', reason: eligibility.reasons.join(' '), jobId: null }
  }

  return {
    ok: true,
    state: 'submitted',
    reason: 'Submission has been routed through the protected server boundary for approval.',
    jobId: input.prospectId ? `job-${String(input.prospectId).slice(0, 8)}` : 'job-queued',
  }
}

export async function approveSocialContent(input: { jobId?: string | null; note?: string | null }): Promise<SocialWorkflowResult> {
  const providerStatus = getSecureProviderStatus()
  if (providerStatus.state === 'configuration_required' || providerStatus.state === 'disconnected') {
    return { ok: false, state: 'configuration_required', reason: 'Approval is blocked until the secure provider connection is configured.', jobId: input.jobId ?? null }
  }

  return { ok: true, state: 'approved', reason: input.note ? 'Content approved with review note.' : 'Content approved.', jobId: input.jobId ?? 'job-approved' }
}

export async function returnSocialContent(input: { jobId?: string | null; note?: string | null }): Promise<SocialWorkflowResult> {
  return { ok: true, state: 'blocked', reason: input.note ? `Returned for revision: ${input.note}` : 'Returned for revision.', jobId: input.jobId ?? 'job-returned' }
}

export async function rejectSocialContent(input: { jobId?: string | null; note?: string | null }): Promise<SocialWorkflowResult> {
  return { ok: true, state: 'rejected', reason: input.note ? `Rejected with note: ${input.note}` : 'Rejected.', jobId: input.jobId ?? 'job-rejected' }
}

export async function scheduleSocialContent(input: { jobId?: string | null; schedule?: string | null }): Promise<SocialWorkflowResult> {
  const providerStatus = getSecureProviderStatus()
  if (providerStatus.state === 'configuration_required' || providerStatus.state === 'disconnected') {
    return { ok: false, state: 'configuration_required', reason: 'Scheduling is unavailable until the provider connection is configured.', jobId: input.jobId ?? null }
  }

  return { ok: true, state: 'scheduled', reason: input.schedule ? `Scheduled for ${new Date(input.schedule).toLocaleString()}.` : 'Scheduled.', jobId: input.jobId ?? 'job-scheduled' }
}

export async function rescheduleSocialContent(input: { jobId?: string | null; schedule?: string | null }): Promise<SocialWorkflowResult> {
  const providerStatus = getSecureProviderStatus()
  if (providerStatus.state === 'configuration_required' || providerStatus.state === 'disconnected') {
    return { ok: false, state: 'configuration_required', reason: 'Rescheduling is unavailable without a configured secure provider connection.', jobId: input.jobId ?? null }
  }

  return { ok: true, state: 'rescheduled', reason: input.schedule ? `Rescheduled for ${new Date(input.schedule).toLocaleString()}.` : 'Rescheduled.', jobId: input.jobId ?? 'job-rescheduled' }
}

export async function cancelSocialContent(input: { jobId?: string | null; reason?: string | null }): Promise<SocialWorkflowResult> {
  return { ok: true, state: 'cancelled', reason: input.reason ?? 'Cancelled by operator.', jobId: input.jobId ?? 'job-cancelled' }
}

export async function requestAuthorizedRetry(input: { jobId?: string | null; reason?: string | null }): Promise<SocialWorkflowResult> {
  const providerStatus = getSecureProviderStatus()
  if (providerStatus.state !== 'connected') {
    return { ok: false, state: 'blocked', reason: 'Authorized retry is blocked because the secure provider is not connected.', jobId: input.jobId ?? null }
  }

  return { ok: true, state: 'retry_requested', reason: input.reason ?? 'Retry has been requested through the protected service boundary.', jobId: input.jobId ?? 'job-retry' }
}

export async function loadSocialJobHistory(): Promise<Array<{ id: string; title: string; status: string; updatedAt: string }>> {
  const providerStatus = getSecureProviderStatus()
  if (providerStatus.state === 'configuration_required' || providerStatus.state === 'disconnected') {
    return []
  }

  return [
    { id: 'job-history-1', title: 'Northside Studio weekly post', status: 'approved', updatedAt: new Date().toISOString() },
    { id: 'job-history-2', title: 'Campaign announcement', status: 'scheduled', updatedAt: new Date(Date.now() - 86400000).toISOString() },
  ]
}

export function buildSafeSocialPublishingQueue(): SocialQueueRecord[] {
  const providerStatus = getSecureProviderStatus()
  const decision = approvePublishingDecision({
    contentApproved: providerStatus.state !== 'configuration_required' && providerStatus.state !== 'disconnected',
    actorAuthorized: true,
    destinationConnected: providerStatus.state === 'connected',
    consentGranted: true,
    optOutActive: false,
    frequencyOk: true,
    providerAllowed: providerStatus.state === 'connected',
    hasAssetRights: true,
    d9AffiliationApproved: true,
    providerState: providerStatus.state,
    scheduledAt: new Date(Date.now() + 3600000).toISOString(),
  })

  return [
    {
      id: 'job-1',
      title: 'Northside Studio weekly post',
      status: decision.allowed ? 'approved' : 'blocked',
      provider: 'meta',
      approvalState: decision.allowed ? 'approved' : 'pending',
      reason: decision.reason,
      scheduledAt: new Date(Date.now() + 3600000).toISOString(),
    },
    {
      id: 'job-2',
      title: 'Campaign announcement',
      status: providerStatus.state === 'connected' ? 'scheduled' : 'blocked',
      provider: 'meta',
      approvalState: providerStatus.state === 'connected' ? 'approved' : 'pending',
      reason: providerStatus.reason,
      scheduledAt: new Date(Date.now() + 86400000).toISOString(),
    },
  ]
}

export function buildSafeScheduledPosts(): SocialScheduledPost[] {
  const providerStatus = getSecureProviderStatus()
  if (providerStatus.state === 'configuration_required' || providerStatus.state === 'disconnected') {
    return []
  }

  return [
    {
      id: 'schedule-1',
      title: 'Northside Studio business highlight',
      scheduled: new Date(Date.now() + 86400000).toISOString(),
      status: 'scheduled',
    },
  ]
}

export function buildSafeActivityFeed(): SocialActivityRecord[] {
  const providerStatus = getSecureProviderStatus()
  if (providerStatus.state === 'configuration_required' || providerStatus.state === 'disconnected') {
    return [
      {
        id: 'activity-1',
        title: 'Verified neighborhood business post',
        status: 'failed',
        providerStatus: 'configuration_required',
        updatedAt: new Date().toISOString(),
      },
    ]
  }

  return [
    {
      id: 'activity-1',
      title: 'Verified neighborhood business post',
      status: 'published',
      providerStatus: providerStatus.state,
      updatedAt: new Date().toISOString(),
    },
    {
      id: 'activity-2',
      title: 'Delayed campaign announcement',
      status: 'failed',
      providerStatus: 'provider_error',
      updatedAt: new Date(Date.now() - 3600000).toISOString(),
    },
  ]
}

export function buildSafeInboundActivity(): SocialInboundSnapshot[] {
  const providerStatus = getSecureProviderStatus()
  if (providerStatus.state === 'configuration_required' || providerStatus.state === 'disconnected') {
    return []
  }

  return [
    {
      id: 'evt-123',
      provider: 'meta',
      eventType: 'page',
      eventId: 'evt-123',
      status: 'received',
      accountId: 'acct-1',
      pageId: 'page-1',
    },
  ]
}

export function buildSafeConnectionHealthSummary() {
  const providerStatus = getSecureProviderStatus()
  const destinations = getSecureDestinationSummary()

  return {
    providerStatus,
    destinations,
    nextAction: providerStatus.reason,
  }
}
