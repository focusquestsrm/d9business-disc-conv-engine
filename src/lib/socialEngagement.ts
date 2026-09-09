export const PLATFORM_VALUES = ['instagram', 'facebook', 'linkedin', 'email'] as const
export const CONNECTION_STATUSES = ['draft', 'pending', 'connected', 'restricted', 'disconnected', 'error'] as const
export type SocialPlatform = (typeof PLATFORM_VALUES)[number]
export type ConnectionStatus = (typeof CONNECTION_STATUSES)[number]

export type SocialConnection = {
  id: string
  tenantId?: string | null
  organizationId?: string | null
  platform: SocialPlatform
  connectionName: string
  externalAccountId?: string | null
  externalAccountName?: string | null
  externalHandle?: string | null
  connectionStatus: ConnectionStatus
  authorizationStatus?: string | null
  capabilities?: Record<string, unknown> | null
  restrictions?: Record<string, unknown> | null
  connectedBy?: string | null
  connectedAt?: string | null
  lastValidatedAt?: string | null
  lastSyncAt?: string | null
  disconnectedAt?: string | null
  metadata?: Record<string, unknown> | null
  createdAt?: string
  updatedAt?: string
}

export type SocialMessage = {
  id: string
  tenantId?: string | null
  connectionId?: string | null
  threadId?: string | null
  prospectId?: string | null
  direction: 'inbound' | 'outbound'
  platform: SocialPlatform
  externalMessageId?: string | null
  externalThreadId?: string | null
  originalSource?: string | null
  originalHandle?: string | null
  originalUrl?: string | null
  senderExternalId?: string | null
  senderDisplayName?: string | null
  recipientExternalId?: string | null
  messageType?: string | null
  messageText?: string | null
  providerCreatedAt?: string | null
  receivedAt?: string | null
  deliveryStatus?: string | null
  rawPayload?: Record<string, unknown> | null
  metadata?: Record<string, unknown> | null
  createdAt?: string
}

export type SocialInboxItem = {
  id: string
  platform: SocialPlatform
  connectionName?: string | null
  handle?: string | null
  prospectName?: string | null
  preview?: string | null
  lastMessageAt?: string | null
  unread: boolean
  matched: boolean
  assignee?: string | null
  queueStatus?: string | null
}

export type SocialMatchCandidate = {
  prospectId: string
  confidence: number
  reason: string
}

export function normalizePlatform(value: string | null | undefined): SocialPlatform | null {
  const normalized = (value ?? '').trim().toLowerCase()
  return PLATFORM_VALUES.includes(normalized as SocialPlatform) ? (normalized as SocialPlatform) : null
}

export function normalizeSocialConnectionState(value: string | null | undefined): ConnectionStatus | null {
  const normalized = (value ?? '').trim().toLowerCase()
  return CONNECTION_STATUSES.includes(normalized as ConnectionStatus) ? (normalized as ConnectionStatus) : null
}

export function createConnection(input: Partial<SocialConnection> & Pick<SocialConnection, 'platform' | 'connectionName'>): SocialConnection {
  const connectionStatus = normalizeSocialConnectionState(input.connectionStatus ?? 'draft') ?? 'draft'
  const createdAt = new Date().toISOString()
  return {
    id: input.id ?? `conn-${Math.random().toString(36).slice(2, 10)}`,
    tenantId: input.tenantId ?? null,
    organizationId: input.organizationId ?? null,
    platform: normalizePlatform(input.platform) ?? 'email',
    connectionName: input.connectionName,
    externalAccountId: input.externalAccountId ?? null,
    externalAccountName: input.externalAccountName ?? null,
    externalHandle: input.externalHandle ?? null,
    connectionStatus,
    authorizationStatus: input.authorizationStatus ?? null,
    capabilities: input.capabilities ?? { available: true },
    restrictions: input.restrictions ?? {},
    connectedBy: input.connectedBy ?? null,
    connectedAt: input.connectedAt ?? null,
    lastValidatedAt: input.lastValidatedAt ?? null,
    lastSyncAt: input.lastSyncAt ?? null,
    disconnectedAt: input.disconnectedAt ?? null,
    metadata: {
      ...(input.metadata ?? {}),
      isDraft: connectionStatus === 'draft',
      isLive: connectionStatus === 'connected',
    },
    createdAt,
    updatedAt: input.updatedAt ?? createdAt,
  }
}

export function normalizeSocialMessage(input: Partial<SocialMessage> & Pick<SocialMessage, 'platform' | 'direction'>): SocialMessage {
  const createdAt = new Date().toISOString()
  const platform = normalizePlatform(input.platform) ?? 'email'
  return {
    id: input.id ?? `msg-${Math.random().toString(36).slice(2, 10)}`,
    tenantId: input.tenantId ?? null,
    connectionId: input.connectionId ?? null,
    threadId: input.threadId ?? null,
    prospectId: input.prospectId ?? null,
    direction: input.direction,
    platform,
    externalMessageId: input.externalMessageId ?? null,
    externalThreadId: input.externalThreadId ?? input.threadId ?? null,
    originalSource: input.originalSource ?? input.platform ?? null,
    originalHandle: input.originalHandle ?? null,
    originalUrl: input.originalUrl ?? null,
    senderExternalId: input.senderExternalId ?? null,
    senderDisplayName: input.senderDisplayName ?? null,
    recipientExternalId: input.recipientExternalId ?? null,
    messageType: input.messageType ?? 'text',
    messageText: input.messageText ?? '',
    providerCreatedAt: input.providerCreatedAt ?? createdAt,
    receivedAt: input.receivedAt ?? createdAt,
    deliveryStatus: input.deliveryStatus ?? 'received',
    rawPayload: input.rawPayload ?? {},
    metadata: input.metadata ?? {},
    createdAt,
  }
}

export function createInboundMessage(input: Partial<SocialMessage> & { platform: SocialPlatform; externalMessageId: string; externalThreadId?: string | null; providerCreatedAt?: string; messageText?: string; originalHandle?: string | null }): SocialMessage {
  return normalizeSocialMessage({
    ...input,
    direction: 'inbound',
    originalSource: input.originalSource ?? input.platform,
    messageType: input.messageType ?? 'text',
    providerCreatedAt: input.providerCreatedAt ?? new Date().toISOString(),
    receivedAt: input.receivedAt ?? new Date().toISOString(),
  })
}

export function determineMatchDecision(input: {
  knownProspects?: Array<{ id: string; email?: string | null; displayName?: string | null; linkedHandles?: Record<string, string | null> }>
  platform: SocialPlatform | string
  originalHandle?: string | null
  originalUrl?: string | null
  email?: string | null
  prospectId?: string | null
}) {
  const platform = normalizePlatform(String(input.platform)) ?? 'email'
  const email = (input.email ?? '').trim().toLowerCase()
  const handle = (input.originalHandle ?? '').trim().toLowerCase()

  const candidates = (input.knownProspects ?? []).filter((prospect) => {
    const emailMatches = Boolean(prospect.email && email && prospect.email.toLowerCase() === email)
    const handleMatches = Boolean(handle) && Boolean(prospect.linkedHandles?.[platform]) && prospect.linkedHandles?.[platform]?.toLowerCase() === handle
    return emailMatches || handleMatches
  })

  if (candidates.length === 1) {
    return { autoLink: true, needsReview: false, prospectId: candidates[0].id, confidence: 0.98, matchCandidates: [] }
  }

  if (candidates.length > 1) {
    return {
      autoLink: false,
      needsReview: true,
      prospectId: null,
      confidence: 0.62,
      matchCandidates: candidates.map((candidate) => ({ prospectId: candidate.id, confidence: 0.62, reason: 'Ambiguous platform handle or email mapping' })),
    }
  }

  if (input.prospectId) {
    return { autoLink: false, needsReview: false, prospectId: input.prospectId, confidence: 0.7, matchCandidates: [] }
  }

  return { autoLink: false, needsReview: true, prospectId: null, confidence: 0.15, matchCandidates: [] }
}

export function buildInboxFilters(input: { platform?: string; unreadOnly?: boolean; matchState?: string; queueStatus?: string; assignee?: string; search?: string }) {
  return {
    platform: normalizePlatform(input.platform ?? 'all') ?? 'all',
    unreadOnly: Boolean(input.unreadOnly),
    matchState: input.matchState ?? 'all',
    queueStatus: input.queueStatus ?? 'all',
    assignee: input.assignee ?? 'all',
    search: input.search ?? '',
  }
}

export function routeResponseToQueue(input: {
  platform: SocialPlatform | string
  content?: string | null
  consentPreferences?: Array<{ channel: string; purpose: string; status: string; effective_at?: string | null }>
  suppressions?: Array<{ kind: 'global' | 'channel'; channel?: string | null; active: boolean }>
  reason?: string
  prospectId?: string | null
}) {
  const explicitReason = (input.reason ?? '').trim()
  const hasGlobalSuppression = (input.suppressions ?? []).some((suppression) => suppression.kind === 'global' && suppression.active)
  const channelSuppression = (input.suppressions ?? []).find((suppression) => suppression.kind === 'channel' && suppression.channel === input.platform && suppression.active)
  const consent = (input.consentPreferences ?? []).find((record) => record.channel === 'email' || record.channel === 'social_media')
  const consentAllowed = consent && consent.status === 'granted' && (!consent.effective_at || new Date(consent.effective_at) <= new Date())

  if (hasGlobalSuppression) {
    return { allowed: false, reason: 'Global opt-out is active and blocks outreach.', queueItem: null }
  }

  if (channelSuppression) {
    return { allowed: false, reason: `Channel opt-out is active for ${input.platform}.`, queueItem: null }
  }

  if (!consentAllowed) {
    return { allowed: false, reason: 'Outreach is blocked because consent is missing or withdrawn for this channel.', queueItem: null }
  }

  return {
    allowed: true,
    reason: explicitReason || 'Eligible response ready for follow-up.',
    queueItem: {
      type: 'inbound_response',
      platform: normalizePlatform(String(input.platform)) ?? 'email',
      prospectId: input.prospectId ?? null,
      content: input.content ?? '',
    },
  }
}

export const socialEngagementRepository = {
  isDuplicateEvent(event: { connectionId?: string | null; platform?: string | null; externalEventId?: string | null; eventType?: string | null; payloadHash?: string | null }) {
    return Boolean(event.connectionId && event.platform && event.externalEventId && event.eventType && event.payloadHash)
  },
  isDuplicateMessage(message: { threadId?: string | null; externalMessageId?: string | null }) {
    return Boolean(message.threadId && message.externalMessageId)
  },
}
