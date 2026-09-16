export const PROVIDER_CONNECTION_STATES = ['disconnected', 'configuration_required', 'connected', 'permission_limited', 'token_expiring', 'reconnect_required', 'suspended', 'provider_error'] as const
export const SOCIAL_PROVIDER_CHANNELS = ['facebook_page', 'instagram_business'] as const
export const PUBLISHING_LIFECYCLE_STATES = ['draft', 'submitted_for_review', 'approved', 'scheduled', 'ready', 'publishing', 'published', 'partially_published', 'failed', 'cancelled'] as const

export type ProviderConnectionState = (typeof PROVIDER_CONNECTION_STATES)[number]
export type SocialProviderChannel = (typeof SOCIAL_PROVIDER_CHANNELS)[number]
export type PublishingLifecycleState = (typeof PUBLISHING_LIFECYCLE_STATES)[number]

export type ProviderDestination = {
  id: string
  provider: 'meta'
  channel: SocialProviderChannel
  name: string
  status: 'connected' | 'disabled'
  connectionStatus: ProviderConnectionState
  accountId?: string | null
  pageId?: string | null
}

export type ProviderCapability = {
  name: 'text' | 'link' | 'image' | 'video'
  enabled: boolean
  maxLength?: number
  supportedMedia?: string[]
  requiresApproval?: boolean
}

export type SocialProviderContent = {
  text?: string | null
  link?: string | null
  imageUrl?: string | null
  videoUrl?: string | null
  contentVersion?: number | string | null
  approved?: boolean
  approvedBy?: string | null
  approvedAt?: string | null
  assetRightsConfirmed?: boolean
  d9AffiliationPublished?: boolean
}

export type ProviderPublishingResult = {
  ok: boolean
  jobId?: string | null
  status: PublishingLifecycleState | 'blocked'
  providerStatus?: string | null
  message?: string
  retryable?: boolean
}

export type ProviderError = {
  code: string
  message: string
  retryable: boolean
  state: ProviderConnectionState
}

export type ProviderHealth = {
  state: ProviderConnectionState
  lastSuccessfulProviderCheck: string | null
  nextAction: string
  provider: 'meta'
}

export type SocialProviderAdapter = {
  provider: 'meta'
  getConnectionStatus(): ProviderConnectionState
  discoverAccounts(): Array<{ id: string; type: SocialProviderChannel; name: string; status: 'connected' | 'needs_attention' | 'disabled' }>
  selectApprovedDestination(destinations: ProviderDestination[], channel: SocialProviderChannel): ProviderDestination | null
  discoverCapabilities(destination: ProviderDestination): ProviderCapability[]
  validateContent(content: SocialProviderContent, destination: ProviderDestination, capabilities: ProviderCapability[]): { allowed: boolean; issues: string[]; normalizedText?: string | null }
  publishContent(content: SocialProviderContent, destination: ProviderDestination, actorId: string): ProviderPublishingResult
  getPublishingStatus(jobId: string): { jobId: string; status: PublishingLifecycleState; providerStatus?: string | null }
  normalizeInboundWebhook(payload: Record<string, unknown>): { accountId?: string | null; pageId?: string | null; eventId?: string | null; type?: string | null; prospectId?: string | null; raw?: Record<string, unknown> }
  normalizeProviderError(error: unknown): ProviderError
  getConnectionHealth(): ProviderHealth
}

export function normalizeProviderConnectionState(value: string | null | undefined): ProviderConnectionState | null {
  const normalized = (value ?? '').trim().toLowerCase().replace(/[^a-z_]/g, '_')
  return PROVIDER_CONNECTION_STATES.includes(normalized as ProviderConnectionState) ? (normalized as ProviderConnectionState) : null
}

export function normalizePublishingLifecycle(value: string | null | undefined): PublishingLifecycleState | null {
  const normalized = (value ?? '').trim().toLowerCase().replace(/[^a-z_]/g, '_')
  return PUBLISHING_LIFECYCLE_STATES.includes(normalized as PublishingLifecycleState) ? (normalized as PublishingLifecycleState) : null
}

export function buildProviderError(code: string, message: string, retryable = false, state: ProviderConnectionState = 'provider_error'): ProviderError {
  return { code, message, retryable, state }
}

export function createProviderDestination(input: Partial<ProviderDestination> & Pick<ProviderDestination, 'id' | 'provider' | 'channel' | 'name' | 'status'>): ProviderDestination {
  return {
    id: input.id,
    provider: input.provider,
    channel: input.channel,
    name: input.name,
    status: input.status,
    connectionStatus: normalizeProviderConnectionState(input.connectionStatus ?? 'disconnected') ?? 'disconnected',
    accountId: input.accountId ?? null,
    pageId: input.pageId ?? null,
  }
}

export function evaluateProviderPublishing(input: {
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
}): { allowed: boolean; reason: string; status: 'ready' | 'blocked'; requiresReapproval: boolean } {
  const issues: string[] = []

  if (!input.contentApproved) issues.push('Content approval is required before publishing.')
  if (!input.actorAuthorized) issues.push('Actor is not authorized to publish this content.')
  if (!input.destinationConnected) issues.push('The provider destination is disconnected or unavailable.')
  if (!input.consentGranted) issues.push('Consent and channel permission are missing or withdrawn.')
  if (input.optOutActive) issues.push('A prospect opt-out or suppression blocks publication.')
  if (!input.frequencyOk) issues.push('Frequency and cooldown rules block this action.')
  if (!input.providerAllowed) issues.push('The provider capability denies this publication format.')
  if (!input.hasAssetRights) issues.push('Asset rights and usage authorization are missing.')
  if (!input.d9AffiliationApproved) issues.push('D9 affiliation publication permission is not approved.')
  if (input.providerState === 'permission_limited') issues.push('Provider permissions are limited and require a recheck.')
  if (input.providerState === 'reconnect_required' || input.providerState === 'token_expiring') issues.push('Provider reconnect or token refresh is required.')
  if (input.providerState === 'provider_error' || input.providerState === 'suspended') issues.push('The provider is in a failed or suspended state.')
  if (input.contentChangedSinceApproval) issues.push('Edited content requires reapproval before publication.')
  if (input.scheduledAt && new Date(input.scheduledAt).getTime() > Date.now()) {
    issues.push('Scheduled time has not arrived yet.')
  }

  const allowed = issues.length === 0
  return {
    allowed,
    reason: allowed ? 'Ready to publish.' : issues.join(' '),
    status: allowed ? 'ready' : 'blocked',
    requiresReapproval: Boolean(input.contentChangedSinceApproval),
  }
}

export class MetaSocialProvider implements SocialProviderAdapter {
  readonly provider = 'meta' as const

  getConnectionStatus(): ProviderConnectionState {
    return 'connected'
  }

  discoverAccounts() {
    return [
      { id: 'page-101', type: 'facebook_page' as const, name: 'D9Network Business Page', status: 'connected' as const },
      { id: 'ig-101', type: 'instagram_business' as const, name: 'D9Network Instagram', status: 'connected' as const },
    ]
  }

  selectApprovedDestination(destinations: ProviderDestination[], channel: SocialProviderChannel): ProviderDestination | null {
    return destinations.find((destination) => destination.channel === channel && destination.status === 'connected' && destination.connectionStatus === 'connected') ?? null
  }

  discoverCapabilities(destination: ProviderDestination): ProviderCapability[] {
    const isInstagram = destination.channel === 'instagram_business'
    const base: ProviderCapability[] = [
      { name: 'text', enabled: true, maxLength: isInstagram ? 2200 : 63206 },
      { name: 'link', enabled: true },
      { name: 'image', enabled: true, supportedMedia: ['jpg', 'png'] },
    ]

    if (destination.channel === 'facebook_page') {
      base.push({ name: 'video', enabled: true, supportedMedia: ['mp4'], requiresApproval: true })
    }

    return base
  }

  validateContent(content: SocialProviderContent, _destination: ProviderDestination, capabilities: ProviderCapability[]): { allowed: boolean; issues: string[]; normalizedText?: string | null } {
    const issues: string[] = []
    const text = (content.text ?? '').trim()

    if (text.length > 0) {
      const textCapability = capabilities.find((capability) => capability.name === 'text')
      if (!textCapability?.enabled) {
        issues.push('Text publishing is not enabled for this destination.')
      }
      if (typeof textCapability?.maxLength === 'number' && text.length > textCapability.maxLength) {
        issues.push(`Text content exceeds the platform limit of ${textCapability.maxLength} characters.`)
      }
    }

    if (content.link) {
      const linkCapability = capabilities.find((capability) => capability.name === 'link')
      if (!linkCapability?.enabled) {
        issues.push('Link publishing is not enabled for this destination.')
      }
    }

    if (content.imageUrl) {
      const imageCapability = capabilities.find((capability) => capability.name === 'image')
      if (!imageCapability?.enabled) {
        issues.push('Image publishing is not enabled for this destination.')
      }
    }

    if (content.videoUrl) {
      const videoCapability = capabilities.find((capability) => capability.name === 'video')
      if (!videoCapability?.enabled) {
        issues.push('Video publishing is not enabled for this destination.')
      }
    }

    if (!content.assetRightsConfirmed) {
      issues.push('Asset rights are not approved for publication.')
    }

    if (!content.d9AffiliationPublished) {
      issues.push('D9 affiliation publication permission is not approved.')
    }

    if (!text && !content.link && !content.imageUrl && !content.videoUrl) {
      issues.push('At least one supported content format is required.')
    }

    return { allowed: issues.length === 0, issues, normalizedText: text || null }
  }

  publishContent(content: SocialProviderContent, destination: ProviderDestination, _actorId: string): ProviderPublishingResult {
    const capabilities = this.discoverCapabilities(destination)
    const validation = this.validateContent(content, destination, capabilities)

    if (!validation.allowed) {
      return {
        ok: false,
        status: 'blocked',
        message: validation.issues.join(' '),
        retryable: false,
      }
    }

    const providerStatus = destination.connectionStatus === 'connected' ? 'published' : 'failed'
    const jobId = `meta-job-${Math.random().toString(36).slice(2, 10)}`

    if (providerStatus === 'failed') {
      return {
        ok: false,
        jobId,
        status: 'failed',
        providerStatus: 'failed',
        message: 'The selected destination is not currently connected for live publishing.',
        retryable: true,
      }
    }

    return {
      ok: true,
      jobId,
      status: 'published',
      providerStatus: 'published',
      message: 'Provider acknowledged the publishing request.',
      retryable: false,
    }
  }

  getPublishingStatus(jobId: string): { jobId: string; status: PublishingLifecycleState; providerStatus?: string | null } {
    return { jobId, status: 'published', providerStatus: 'published' }
  }

  normalizeInboundWebhook(payload: Record<string, unknown>) {
    const pageId = typeof payload.page_id === 'string' ? payload.page_id : null
    const accountId = typeof payload.account_id === 'string' ? payload.account_id : null
    const entry = Array.isArray(payload.entry) ? payload.entry : []
    const firstEntry = entry[0] as Record<string, unknown> | undefined
    const eventId = typeof firstEntry?.id === 'string' ? firstEntry.id : typeof payload.object === 'string' ? payload.object : undefined

    return {
      accountId,
      pageId,
      eventId,
      type: typeof payload.object === 'string' ? payload.object : 'provider_event',
      prospectId: typeof payload.prospect_id === 'string' ? payload.prospect_id : null,
      raw: payload,
    }
  }

  normalizeProviderError(error: unknown): ProviderError {
    if (error instanceof Error) {
      return buildProviderError('provider_exception', error.message, true, 'provider_error')
    }

    if (typeof error === 'string') {
      return buildProviderError('provider_error', error, true, 'provider_error')
    }

    return buildProviderError('provider_unknown_error', 'An unknown provider error occurred.', true, 'provider_error')
  }

  getConnectionHealth(): ProviderHealth {
    return {
      state: 'connected',
      lastSuccessfulProviderCheck: new Date().toISOString(),
      nextAction: 'Continue monitoring provider health and permissions.',
      provider: 'meta',
    }
  }
}
