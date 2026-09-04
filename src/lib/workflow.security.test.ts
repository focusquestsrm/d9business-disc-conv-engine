import { describe, expect, it } from 'vitest'
import { buildD9MatchCandidate, getWorkflowRoute, tenantAllowedRead } from './workflow'

type RequiredNullSafetyInputs = {
  discovery_sources: string | null
  businesses: string | null
  prospects: string | null
  enforceWorkflowTransition: string | null
  recordWorkflowTransition: string | null
  setUpdatedAt: string | null
  buildD9MatchCandidate: string | null
  tenantAllowedRead: string | null
}

type OverallRow = {
  status: 'PASS' | 'FAIL'
}

const evaluateNullSafety = (required: RequiredNullSafetyInputs) => {
  const requiredValues = [
    required.discovery_sources,
    required.businesses,
    required.prospects,
    required.enforceWorkflowTransition,
    required.recordWorkflowTransition,
    required.setUpdatedAt,
    required.buildD9MatchCandidate,
    required.tenantAllowedRead,
  ]

  return requiredValues.some((value) => value == null) ? 'NULL_FOUND' : 'NO_NULL'
}

const summarizeOverall = (rows: OverallRow[]) => {
  const passCount = rows.filter((row) => row.status === 'PASS').length
  const failCount = rows.filter((row) => row.status === 'FAIL').length

  return {
    passCount,
    failCount,
    overall: failCount === 0 ? 'PASS' : 'FAIL',
  }
}

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

  it('keeps the verifier null-safety logic focused on required substantive results and counts overall status correctly', () => {
    const livePassRows: OverallRow[] = [
      { status: 'PASS' },
      { status: 'PASS' },
      { status: 'PASS' },
      { status: 'FAIL' },
    ]

    expect(
      evaluateNullSafety({
        discovery_sources: 'EXISTS',
        businesses: 'EXISTS',
        prospects: 'EXISTS',
        enforceWorkflowTransition: 'EXISTS',
        recordWorkflowTransition: 'EXISTS',
        setUpdatedAt: 'EXISTS',
        buildD9MatchCandidate: 'EXISTS',
        tenantAllowedRead: 'EXISTS',
      }),
    ).toBe('NO_NULL')

    expect(
      evaluateNullSafety({
        discovery_sources: 'EXISTS',
        businesses: 'EXISTS',
        prospects: 'EXISTS',
        enforceWorkflowTransition: null,
        recordWorkflowTransition: 'EXISTS',
        setUpdatedAt: 'EXISTS',
        buildD9MatchCandidate: 'EXISTS',
        tenantAllowedRead: 'EXISTS',
      }),
    ).toBe('NULL_FOUND')

    expect(summarizeOverall(livePassRows)).toEqual({
      passCount: 3,
      failCount: 1,
      overall: 'FAIL',
    })
  })
})
