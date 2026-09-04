import { describe, expect, it } from 'vitest'
import { buildD9MatchCandidate, getWorkflowRoute, tenantAllowedRead } from './workflow'

type VerificationRow = {
  category: string
  object_name: string
  check_name: string
  expected_result: string | null
  actual_result: string | null
  status: 'PASS' | 'FAIL' | null
  details?: string | null
}

const evaluateNullSafetyFromRows = (rows: VerificationRow[]) => {
  const hasNullRequiredField = rows.some((row) =>
    [
      row.category,
      row.object_name,
      row.check_name,
      row.expected_result,
      row.actual_result,
      row.status,
    ].some((value) => value == null),
  )

  return hasNullRequiredField ? { actual_result: 'NULL_FOUND', status: 'FAIL' } : { actual_result: 'NO_NULL', status: 'PASS' }
}

const summarizeOverall = (rows: VerificationRow[]) => {
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

  it('derives safety from finalized substantive rows and ignores optional fields', () => {
    const completeRows: VerificationRow[] = Array.from({ length: 51 }, () => ({
      category: 'TABLE',
      object_name: 'public.discovery_sources',
      check_name: 'table_exists',
      expected_result: 'EXISTS',
      actual_result: 'EXISTS',
      status: 'PASS',
      details: 'present',
    }))

    const nullActualResultRows: VerificationRow[] = [
      {
        category: 'TABLE',
        object_name: 'public.discovery_sources',
        check_name: 'table_exists',
        expected_result: 'EXISTS',
        actual_result: null,
        status: 'PASS',
        details: 'present',
      },
    ]

    const nullStatusRows: VerificationRow[] = [
      {
        category: 'TABLE',
        object_name: 'public.discovery_sources',
        check_name: 'table_exists',
        expected_result: 'EXISTS',
        actual_result: 'EXISTS',
        status: null,
        details: 'present',
      },
    ]

    const optionalNullDetailsRows: VerificationRow[] = [
      {
        category: 'TABLE',
        object_name: 'public.discovery_sources',
        check_name: 'table_exists',
        expected_result: 'EXISTS',
        actual_result: 'EXISTS',
        status: 'PASS',
        details: null,
      },
    ]

    expect(evaluateNullSafetyFromRows(completeRows)).toEqual({ actual_result: 'NO_NULL', status: 'PASS' })
    expect(evaluateNullSafetyFromRows(nullActualResultRows)).toEqual({ actual_result: 'NULL_FOUND', status: 'FAIL' })
    expect(evaluateNullSafetyFromRows(nullStatusRows)).toEqual({ actual_result: 'NULL_FOUND', status: 'FAIL' })
    expect(evaluateNullSafetyFromRows(optionalNullDetailsRows)).toEqual({ actual_result: 'NO_NULL', status: 'PASS' })

    const overallRows: VerificationRow[] = [
      { category: 'TABLE', object_name: 'a', check_name: 'a', expected_result: 'EXISTS', actual_result: 'EXISTS', status: 'PASS', details: 'ok' },
      { category: 'TABLE', object_name: 'b', check_name: 'b', expected_result: 'EXISTS', actual_result: 'EXISTS', status: 'PASS', details: 'ok' },
      { category: 'TABLE', object_name: 'c', check_name: 'c', expected_result: 'EXISTS', actual_result: 'MISSING', status: 'FAIL', details: 'missing' },
    ]

    expect(summarizeOverall(overallRows)).toEqual({ passCount: 2, failCount: 1, overall: 'FAIL' })
  })
})
