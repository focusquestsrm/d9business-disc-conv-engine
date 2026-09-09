import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'
import { parseSync, loadModule } from 'pgsql-parser'
import {
  CONNECTION_STATUSES,
  PLATFORM_VALUES,
  buildInboxFilters,
  createConnection,
  createInboundMessage,
  determineMatchDecision,
  normalizePlatform,
  normalizeSocialConnectionState,
  normalizeSocialMessage,
  routeResponseToQueue,
  type SocialConnection,
  type SocialMessage,
} from './socialEngagement'
import { socialEngagementRepository } from './socialEngagementRepository'

describe('social engagement', () => {
  it('supports configured platforms and connection lifecycle states', () => {
    expect(PLATFORM_VALUES).toContain('instagram')
    expect(PLATFORM_VALUES).toContain('facebook')
    expect(PLATFORM_VALUES).toContain('linkedin')
    expect(PLATFORM_VALUES).toContain('email')
    expect(CONNECTION_STATUSES).toContain('draft')
    expect(CONNECTION_STATUSES).toContain('pending')
    expect(CONNECTION_STATUSES).toContain('connected')
    expect(CONNECTION_STATUSES).toContain('restricted')
    expect(CONNECTION_STATUSES).toContain('disconnected')
    expect(CONNECTION_STATUSES).toContain('error')
    expect(normalizePlatform('Instagram')).toBe('instagram')
    expect(normalizePlatform('unknown')).toBeNull()
    expect(normalizeSocialConnectionState('PENDING')).toBe('pending')
    expect(normalizeSocialConnectionState('ghost')).toBeNull()
  })

  it('preserves original social source metadata without mutating the record', () => {
    const message = normalizeSocialMessage({
      platform: 'instagram',
      originalSource: 'instagram',
      originalHandle: '@democreator',
      originalUrl: 'https://instagram.com/p/123/',
      externalThreadId: 'thread_123',
      externalMessageId: 'msg_456',
      senderExternalId: 'acct_789',
      senderDisplayName: 'Demo Creator',
      providerCreatedAt: '2026-09-08T12:00:00.000Z',
      messageText: 'Hello there',
      direction: 'inbound',
    } satisfies Partial<SocialMessage>)

    expect(message.originalHandle).toBe('@democreator')
    expect(message.originalUrl).toBe('https://instagram.com/p/123/')
    expect(message.platform).toBe('instagram')
    expect(message.externalThreadId).toBe('thread_123')
    expect(message.externalMessageId).toBe('msg_456')
    expect(message.providerCreatedAt).toBe('2026-09-08T12:00:00.000Z')
    expect(message.messageText).toBe('Hello there')
  })

  it('provides idempotent handling for duplicate events and messages', () => {
    const connection: SocialConnection = createConnection({
      platform: 'facebook',
      connectionName: 'Demo Facebook',
      connectionStatus: 'connected',
      authorizationStatus: 'approved',
    })

    expect(connection.connectionStatus).toBe('connected')
    expect(connection.metadata?.isDraft).toBe(false)

    const message = createInboundMessage({
      platform: 'facebook',
      connectionId: 'conn-1',
      threadId: 'thread-1',
      externalMessageId: 'msg-dup',
      externalThreadId: 'thread-1',
      originalHandle: '@business',
      providerCreatedAt: '2026-09-08T12:00:00.000Z',
      messageText: 'We are interested.',
    })

    const duplicateEvent = { connectionId: connection.id, platform: 'facebook', externalEventId: 'evt-1', eventType: 'message_received', payloadHash: 'abc' }
    const duplicateMessage = { ...message, externalMessageId: 'msg-dup', threadId: 'thread-1' }

    expect(socialEngagementRepository.isDuplicateEvent(duplicateEvent)).toBe(true)
    expect(socialEngagementRepository.isDuplicateMessage(duplicateMessage)).toBe(true)
  })

  it('uses deterministic matching rules and sends ambiguous matches to review', () => {
    const strongMatch = determineMatchDecision({
      knownProspects: [{ id: 'prospect-1', email: 'alice@example.com', displayName: 'Alice Harper', linkedHandles: { instagram: '@alice' } }],
      platform: 'instagram',
      originalHandle: '@alice',
      originalUrl: 'https://instagram.com/alice',
      email: 'alice@example.com',
      prospectId: null,
    })
    expect(strongMatch.autoLink).toBe(true)
    expect(strongMatch.prospectId).toBe('prospect-1')

    const ambiguous = determineMatchDecision({
      knownProspects: [{ id: 'prospect-1', email: 'someone@example.com', displayName: 'Alice', linkedHandles: { instagram: '@social' } }, { id: 'prospect-2', email: 'other@example.com', displayName: 'Alicia', linkedHandles: { instagram: '@social' } }],
      platform: 'instagram',
      originalHandle: '@social',
      originalUrl: 'https://instagram.com/social',
      email: null,
      prospectId: null,
    })
    expect(ambiguous.autoLink).toBe(false)
    expect(ambiguous.needsReview).toBe(true)
    expect(ambiguous.matchCandidates).toHaveLength(2)
  })

  it('enforces consent and suppression before a response can be routed outbound', () => {
    const eligible = routeResponseToQueue({
      platform: 'email',
      content: 'Would love to learn more.',
      consentPreferences: [{ channel: 'email', purpose: 'general_communication', status: 'granted', effective_at: new Date().toISOString() }],
      suppressions: [],
    })
    expect(eligible.allowed).toBe(true)

    const blocked = routeResponseToQueue({
      platform: 'email',
      content: 'We are interested.',
      consentPreferences: [{ channel: 'email', purpose: 'general_communication', status: 'withdrawn', effective_at: new Date().toISOString() }],
      suppressions: [{ kind: 'global', active: true }],
    })
    expect(blocked.allowed).toBe(false)
    expect(blocked.reason).toMatch(/opt-out|withdrawn|consent/i)
  })

  it('builds inbox filters and keeps a unified list of platform entries', () => {
    const items = [
      { platform: 'instagram', unread: true, matched: true, queueStatus: 'unassigned', assignee: 'alice', prospectName: 'Alice', handle: '@alice', preview: 'Hello', lastMessageAt: '2026-09-08T12:00:00Z' },
      { platform: 'linkedin', unread: false, matched: false, queueStatus: 'assigned', assignee: 'bob', prospectName: null, handle: '@demo', preview: 'Can you share more?', lastMessageAt: '2026-09-07T12:00:00Z' },
    ]

    const filters = buildInboxFilters({ platform: 'instagram', unreadOnly: true, matchState: 'matched', queueStatus: 'unassigned' })
    expect(filters.platform).toBe('instagram')
    expect(filters.unreadOnly).toBe(true)

    const filtered = items.filter((item) => {
      const matches = filters.platform === 'all' || item.platform === filters.platform
      return matches && (!filters.unreadOnly || item.unread) && (!filters.matchState || filters.matchState === 'all' || item.matched === (filters.matchState === 'matched')) && (!filters.queueStatus || filters.queueStatus === 'all' || item.queueStatus === filters.queueStatus)
    })
    expect(filtered).toHaveLength(1)
  })

  it('keeps required parameters before any defaulted parameters in Release 3C RPCs', () => {
    const migrationSql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20260909_000001_milestone_3c_social_engagement.sql'), 'utf8')
    const functionMatches = [...migrationSql.matchAll(/CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+[^\(]+\(([^)]*?)\)\s+RETURNS/gim)]

    for (const match of functionMatches) {
      const params = match[1]
        .split(',')
        .map((item) => item.trim())
        .filter(Boolean)

      let hasSeenDefaultedParam = false
      for (const param of params) {
        const hasDefault = /\bDEFAULT\b/i.test(param)
        const isRequired = !hasDefault

        if (hasSeenDefaultedParam && isRequired) {
          throw new Error(`Release 3C RPC parameter ordering violation: ${match[0]}`)
        }

        if (hasDefault) {
          hasSeenDefaultedParam = true
        }
      }
    }

    expect(functionMatches.length).toBeGreaterThan(0)
  })

  it('parses the Release 3C migration and verifier SQL without syntax issues', async () => {
    await loadModule()
    const migrationSql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20260909_000001_milestone_3c_social_engagement.sql'), 'utf8')
    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_milestone_3c_social_engagement.sql'), 'utf8')

    expect(() => parseSync(migrationSql)).not.toThrow()
    expect(() => parseSync(verifierSql)).not.toThrow()
    console.log('MIGRATION_3C_PARSE_OK')
    console.log('VERIFIER_3C_PARSE_OK')
  })
})
