import { describe, expect, it } from 'vitest'
import { buildD9MatchCandidate, getWorkflowRoute, tenantAllowedRead } from './workflow'

describe('milestone 2 workflow security', () => {
  it('blocks opt-out re-entry without renewed consent and allows platform admins to read guarded records', () => {
    expect(getWorkflowRoute('opt_out', 'unknown', { renewedConsent: false }).allowed).toBe(false)
    expect(getWorkflowRoute('opt_out', 'unknown', { renewedConsent: true }).allowed).toBe(true)
    expect(tenantAllowedRead({ isAuthenticated: true, roleCode: 'platform_admin' })).toBe(true)
    expect(tenantAllowedRead({ isAuthenticated: true, roleCode: 'operator' })).toBe(false)
  })

  it('builds a sanitized duplicate candidate without exposing raw PII', () => {
    const candidate = buildD9MatchCandidate(
      'prospect',
      '11111111-1111-4111-8111-111111111111',
      ' Acme Family Restaurant 555-123-4567 ',
    )

    expect(candidate.entity_type).toBe('prospect')
    expect(candidate.entity_id).toBe('11111111-1111-4111-8111-111111111111')
    expect(candidate.normalized_text).toContain('acme family restaurant')
    expect(candidate.normalized_text).not.toContain('555-123-4567')
    expect(candidate.match_reason).toBe('normalized_text_match')
  })
})
