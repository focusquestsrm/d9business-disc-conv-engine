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
