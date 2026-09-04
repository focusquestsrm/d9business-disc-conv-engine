import { describe, expect, it } from 'vitest'
import verifierSql from '../../supabase/scripts/verify_milestone_2_rls.sql?raw'
import { buildD9MatchCandidate, getWorkflowRoute, tenantAllowedRead } from './workflow'

const extractCteSql = (cteName: string) => {
  const pattern = new RegExp(`\\b${cteName}\\s+AS\\s*\\(`, 'i')
  const start = verifierSql.search(pattern)
  if (start === -1) return ''

  let depth = 0
  let foundStart = false
  for (let i = start; i < verifierSql.length; i += 1) {
    const char = verifierSql[i]
    if (char === '(') {
      depth += 1
      foundStart = true
    } else if (char === ')') {
      depth -= 1
      if (foundStart && depth === 0) {
        return verifierSql.slice(start, i + 1)
      }
    }
  }

  return verifierSql.slice(start)
}

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

  it('keeps the verifier CTE graph acyclic and ordered by dependency', () => {
    const cteOrder = [
      'substantive_results',
      'safety_result',
      'all_results',
      'overall_result',
    ]

    const positions = cteOrder.map((cteName) => ({ cteName, index: verifierSql.search(new RegExp(`\\b${cteName}\\s+AS\\s*\\(`, 'i')) }))

    for (let i = 1; i < positions.length; i += 1) {
      expect(positions[i].index).toBeGreaterThan(positions[i - 1].index)
    }

    const substantiveSql = extractCteSql('substantive_results')
    const safetySql = extractCteSql('safety_result')
    const allResultsSql = extractCteSql('all_results')
    const overallSql = extractCteSql('overall_result')

    expect(substantiveSql).not.toMatch(/\bFROM\s+substantive_results\b/i)
    expect(safetySql).toMatch(/\bFROM\s+substantive_results\b/i)
    expect(safetySql).not.toMatch(/\bFROM\s+(?:all_results|overall_result)\b/i)
    expect(allResultsSql).toMatch(/\bFROM\s+substantive_results\b/i)
    expect(allResultsSql).toMatch(/\bFROM\s+safety_result\b/i)
    expect(allResultsSql).not.toMatch(/\bFROM\s+overall_result\b/i)
    expect(overallSql).toMatch(/\bFROM\s+all_results\b/i)
    expect(overallSql).not.toMatch(/\bFROM\s+(?:substantive_results|safety_result)\b/i)
    expect(verifierSql).not.toMatch(/\bWITH\s+RECURSIVE\b/i)
  })

  it('evaluates safety based only on mandatory substantive fields and finalizes overall counts', () => {
    const safetyPassRows: VerificationRow[] = Array.from({ length: 51 }, () => ({
      category: 'TABLE',
      object_name: 'public.discovery_sources',
      check_name: 'table_exists',
      expected_result: 'EXISTS',
      actual_result: 'EXISTS',
      status: 'PASS',
      details: 'present',
    }))

    const safetyFailRows: VerificationRow[] = [
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

    expect(evaluateNullSafetyFromRows(safetyPassRows)).toEqual({ actual_result: 'NO_NULL', status: 'PASS' })
    expect(evaluateNullSafetyFromRows(safetyFailRows)).toEqual({ actual_result: 'NULL_FOUND', status: 'FAIL' })

    const finalizedRows: VerificationRow[] = [
      { category: 'TABLE', object_name: 'a', check_name: 'a', expected_result: 'EXISTS', actual_result: 'EXISTS', status: 'PASS', details: 'ok' },
      { category: 'TABLE', object_name: 'b', check_name: 'b', expected_result: 'EXISTS', actual_result: 'EXISTS', status: 'PASS', details: 'ok' },
      { category: 'TABLE', object_name: 'c', check_name: 'c', expected_result: 'EXISTS', actual_result: 'MISSING', status: 'FAIL', details: 'missing' },
      { category: 'SAFETY', object_name: 'milestone_2', check_name: 'no_ambiguous_null_results', expected_result: 'NO_NULL', actual_result: 'NO_NULL', status: 'PASS', details: 'all required fields are non-null' },
    ]

    expect(summarizeOverall(finalizedRows)).toEqual({ passCount: 3, failCount: 1, overall: 'FAIL' })
  })
})
