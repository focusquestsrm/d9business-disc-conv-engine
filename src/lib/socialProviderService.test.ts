import { describe, expect, it } from 'vitest'
import { getSafeMetaConfig, getSecureProviderStatus, getSecureProviderStatusAsync, getSecureDestinationSummary, getSecureDestinationSummaryAsync, normalizeProviderFailure, normalizeProviderWebhook, approvePublishingDecision } from './socialProviderService'

describe('secure social provider foundation', () => {
  it('returns a secure configuration_required state when credentials are absent', () => {
    const config = getSafeMetaConfig()
    const status = getSecureProviderStatus()

    expect(config.configured).toBe(false)
    expect(status.state).toBe('configuration_required')
    expect(status.reason).toMatch(/secure deployment environment|configured/i)
    expect(status.safeMetadata).toBeTruthy()
  })

  it('exposes no secrets to the browser client', () => {
    const config = getSafeMetaConfig()
    expect(JSON.stringify(config)).not.toMatch(/META_APP_SECRET|META_ACCESS_TOKEN|META_WEBHOOK_SECRET|SUPABASE_SERVICE_ROLE_KEY/)
    expect(JSON.stringify(getSecureProviderStatus())).not.toMatch(/secret|token/i)
  })

  it('normalizes provider error values without fabricating success states', () => {
    const error = normalizeProviderFailure('provider denied request')
    expect(error.state).toBe('provider_error')
    expect(error.code).toMatch(/meta_provider/i)
    expect(error.retryable).toBe(true)
  })

  it('rejects invalid webhook payloads without claiming successful delivery', () => {
    const normalized = normalizeProviderWebhook({ status: 'received' })
    expect(normalized.provider).toBe('meta')
    expect(normalized.eventId).toBeNull()
    expect(normalized.status).toBe('received')
    expect(normalized.rawSummary.object).toBeNull()
  })

  it('blocks publishing when approval or provider eligibility is missing', () => {
    const decision = approvePublishingDecision({
      contentApproved: false,
      actorAuthorized: true,
      destinationConnected: true,
      consentGranted: true,
      optOutActive: false,
      frequencyOk: true,
      providerAllowed: true,
      hasAssetRights: true,
      d9AffiliationApproved: true,
      providerState: 'connected',
    })

    expect(decision.allowed).toBe(false)
    expect(decision.state).toBe('blocked')
  })

  it('does not fabricate provider destination success states', async () => {
    const destinations = await getSecureDestinationSummaryAsync()
    expect(Array.isArray(destinations)).toBe(true)
    expect(destinations.length).toBe(0)
    const summary = getSecureDestinationSummary()
    expect(summary).toEqual([])
  })

  it('keeps async status safe and config-driven', async () => {
    const status = await getSecureProviderStatusAsync()
    expect(status.state).toBe('configuration_required')
    expect(status.requiresConfiguration).toBe(true)
  })
})
