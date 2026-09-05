import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { parseSync, loadModule } from 'pgsql-parser'
import { createRetentionDispositionEligible, evaluateOutreachEligibility, evaluateVerificationSharingEligibility, normalizeConsentChannel, normalizeConsentStatus, type ConsentPreference } from './consent'

describe('consent governance', () => {
  it('restricts channel and status values', () => {
    expect(normalizeConsentChannel('email')).toBe('email')
    expect(normalizeConsentChannel('fax')).toBeNull()
    expect(normalizeConsentStatus('granted')).toBe('granted')
    expect(normalizeConsentStatus('banned')).toBeNull()
  })

  it('denies missing and withdrawn consent by default', () => {
    expect(evaluateOutreachEligibility({ channel: 'email', purpose: 'general_communication', consentPreferences: [] }).allowed).toBe(false)
    expect(evaluateOutreachEligibility({
      channel: 'text',
      purpose: 'general_communication',
      consentPreferences: [{ subject_type: 'prospect', subject_id: '11111111-1111-4111-8111-111111111111', channel: 'text', purpose: 'general_communication', status: 'withdrawn' }],
    }).allowed).toBe(false)
  })

  it('allows valid active channel consent and blocks mismatched channel usage', () => {
    const allowed = evaluateOutreachEligibility({
      channel: 'email',
      purpose: 'general_communication',
      consentPreferences: [{ subject_type: 'prospect', subject_id: '11111111-1111-4111-8111-111111111111', channel: 'email', purpose: 'general_communication', status: 'granted', effective_at: new Date().toISOString() }],
    })
    expect(allowed.allowed).toBe(true)

    const notAllowed = evaluateOutreachEligibility({
      channel: 'text',
      purpose: 'general_communication',
      consentPreferences: [{ subject_type: 'prospect', subject_id: '11111111-1111-4111-8111-111111111111', channel: 'email', purpose: 'general_communication', status: 'granted', effective_at: new Date().toISOString() }],
    })
    expect(notAllowed.allowed).toBe(false)
  })

  it('applies global and channel suppression precedence', () => {
    const globalSuppressed = evaluateOutreachEligibility({
      channel: 'phone',
      purpose: 'general_communication',
      consentPreferences: [{ subject_type: 'prospect', subject_id: '11111111-1111-4111-8111-111111111111', channel: 'phone', purpose: 'general_communication', status: 'granted', effective_at: new Date().toISOString() }],
      suppressions: [{ kind: 'global', active: true }],
    })
    expect(globalSuppressed.allowed).toBe(false)

    const channelSuppressed = evaluateOutreachEligibility({
      channel: 'phone',
      purpose: 'general_communication',
      consentPreferences: [{ subject_type: 'prospect', subject_id: '11111111-1111-4111-8111-111111111111', channel: 'phone', purpose: 'general_communication', status: 'granted', effective_at: new Date().toISOString() }],
      suppressions: [{ kind: 'channel', channel: 'phone', active: true }],
    })
    expect(channelSuppressed.allowed).toBe(false)
  })

  it('keeps verification-sharing separate from general communication consent', () => {
    const generalConsent: ConsentPreference[] = [{ subject_type: 'prospect', subject_id: '11111111-1111-4111-8111-111111111111', channel: 'email', purpose: 'general_communication', status: 'granted', effective_at: new Date().toISOString() }]
    const shareAllowed = evaluateVerificationSharingEligibility({
      generalConsent,
      organizationConsent: [{ subject_id: '11111111-1111-4111-8111-111111111111', selected_organization: 'Alpha Phi Alpha', status: 'granted', effective_at: new Date().toISOString() }],
      selectedOrganization: 'Alpha Phi Alpha',
      channel: 'email',
      purpose: 'general_communication',
    })
    expect(shareAllowed.allowed).toBe(true)

    const wrongOrg = evaluateVerificationSharingEligibility({
      generalConsent,
      organizationConsent: [{ subject_id: '11111111-1111-4111-8111-111111111111', selected_organization: 'Kappa Alpha Psi', status: 'granted', effective_at: new Date().toISOString() }],
      selectedOrganization: 'Alpha Phi Alpha',
      channel: 'email',
      purpose: 'general_communication',
    })
    expect(wrongOrg.allowed).toBe(false)
  })

  it('calculates retention eligibility and respects deletion holds', () => {
    const eligible = createRetentionDispositionEligible({ retention_days: 30, enabled: true }, new Date(Date.now() - 40 * 86400000).toISOString())
    expect(eligible).toBe(true)
    expect(createRetentionDispositionEligible({ retention_days: 30, enabled: false }, new Date().toISOString())).toBe(false)
  })

  it('parses the release 3B migration and verifier SQL without syntax issues', async () => {
    const migrationSql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20260906_000001_milestone_3b_consent_preferences.sql'), 'utf8')
    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_milestone_3b_consent_preferences.sql'), 'utf8')

    await loadModule()
    expect(() => parseSync(migrationSql)).not.toThrow()
    expect(() => parseSync(verifierSql)).not.toThrow()
    console.log('MIGRATION_3B_PARSE_OK')
    console.log('VERIFIER_3B_PARSE_OK')
  })
})
