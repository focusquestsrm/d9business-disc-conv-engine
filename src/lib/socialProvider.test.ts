import { describe, expect, it } from 'vitest'
import { MetaSocialProvider, evaluateProviderPublishing, normalizeProviderConnectionState, normalizePublishingLifecycle } from './socialProvider'

describe('social provider lifecycle', () => {
  it('normalizes provider status and publishing lifecycle values', () => {
    expect(normalizeProviderConnectionState('TOKEN_EXPIRING')).toBe('token_expiring')
    expect(normalizeProviderConnectionState('permission limited')).toBe('permission_limited')
    expect(normalizePublishingLifecycle('submitted_for_review')).toBe('submitted_for_review')
    expect(normalizePublishingLifecycle('published')).toBe('published')
  })

  it('blocks publication when the destination is disconnected or permissions are limited', () => {
    const decision = evaluateProviderPublishing({
      contentApproved: true,
      actorAuthorized: true,
      destinationConnected: false,
      consentGranted: true,
      optOutActive: false,
      frequencyOk: true,
      providerAllowed: true,
      hasAssetRights: true,
      d9AffiliationApproved: true,
      providerState: 'disconnected',
      scheduledAt: new Date().toISOString(),
    })

    expect(decision.allowed).toBe(false)
    expect(decision.status).toBe('blocked')
    expect(decision.reason).toMatch(/disconnected|unavailable/i)
  })

  it('requires reapproval when content changes after approval and denies unsupported content', () => {
    const provider = new MetaSocialProvider()
    const destination = {
      id: 'dest-1',
      provider: 'meta' as const,
      channel: 'facebook_page' as const,
      name: 'D9Network Business Page',
      status: 'connected' as const,
      connectionStatus: 'connected' as const,
    }

    const decision = evaluateProviderPublishing({
      contentApproved: true,
      actorAuthorized: true,
      destinationConnected: true,
      consentGranted: true,
      optOutActive: false,
      frequencyOk: true,
      providerAllowed: true,
      hasAssetRights: true,
      d9AffiliationApproved: true,
      providerState: 'connected',
      contentChangedSinceApproval: true,
      scheduledAt: new Date().toISOString(),
    })

    expect(decision.requiresReapproval).toBe(true)

    const validation = provider.validateContent(
      { text: 'Hello', videoUrl: 'https://example.com/video.mp4', assetRightsConfirmed: true, d9AffiliationPublished: true },
      destination,
      [{ name: 'text', enabled: true, maxLength: 2200 }, { name: 'image', enabled: true }, { name: 'link', enabled: true }],
    )
    expect(validation.allowed).toBe(false)
    expect(validation.issues.join(' ')).toMatch(/video/i)
  })

  it('records provider failure without fabricating a successful publish result', () => {
    const provider = new MetaSocialProvider()
    const destination = {
      id: 'dest-2',
      provider: 'meta' as const,
      channel: 'instagram_business' as const,
      name: 'D9Network Instagram',
      status: 'connected' as const,
      connectionStatus: 'disconnected' as const,
    }

    const result = provider.publishContent(
      { text: 'Approved content', assetRightsConfirmed: true, d9AffiliationPublished: true },
      destination,
      'user-1',
    )

    expect(result.ok).toBe(false)
    expect(result.status).toBe('failed')
    expect(result.message).toMatch(/not currently connected/i)
  })
})
