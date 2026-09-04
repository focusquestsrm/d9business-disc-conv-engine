import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { loadModule, parseSync } from 'pgsql-parser'
import { describe, expect, it } from 'vitest'
import {
  buildVerificationExportColumns,
  canTransitionVerificationStatus,
  previewVerificationImport,
  validateMembershipClaim,
  validateVerificationResult,
  buildVerificationMetrics,
  nextOpenBatchDuplicateCheck,
} from './membershipVerification'

describe('membership verification logic', () => {
  it('requires a claimant, organization, consent, and real identity data', () => {
    const errors = validateMembershipClaim({
      legalFirstName: '',
      legalLastName: '',
      claimedOrganization: '',
      consentAcknowledged: false,
      consentDate: '',
    })

    expect(errors.legalFirstName).toMatch(/required/i)
    expect(errors.claimedOrganization).toMatch(/required/i)
    expect(errors.consentAcknowledged).toMatch(/consent/i)
  })

  it('prevents invalid lifecycle transitions and requires reasons for non-verified outcomes', () => {
    expect(canTransitionVerificationStatus('not_requested', 'ready_for_batch', { authorized: true })).toBe(true)
    expect(canTransitionVerificationStatus('ready_for_batch', 'verified', { authorized: true })).toBe(false)
    expect(canTransitionVerificationStatus('ready_for_batch', 'rejected', { authorized: true, reason: 'No chapter record' })).toBe(true)
    expect(canTransitionVerificationStatus('ready_for_batch', 'rejected', { authorized: true })).toBe(false)
    expect(canTransitionVerificationStatus('ready_for_batch', 'verified', { authorized: false })).toBe(false)
  })

  it('enforces batch organization consistency and duplicate open-batch prevention', () => {
    expect(nextOpenBatchDuplicateCheck('Alpha Phi Alpha', ['alpha phi alpha', 'kappa alpha psi'])).toBe(false)
    expect(nextOpenBatchDuplicateCheck('Alpha Phi Alpha', ['alpha phi alpha', 'alpha phi alpha'])).toBe(true)
  })

  it('exports a controlled workbook column order and validates result values', () => {
    const columns = buildVerificationExportColumns()
    expect(columns[0]).toBe('Batch ID')
    expect(columns).toContain('Verification Case ID')
    expect(columns).toContain('Claimed Organization')

    expect(validateVerificationResult('VERIFIED')).toBe(true)
    expect(validateVerificationResult('NEEDS_FOLLOW_UP')).toBe(true)
    expect(validateVerificationResult('UNKNOWN')).toBe(false)
  })

  it('previews import rows, rejects identifier mismatches, and counts duplicates', () => {
    const preview = previewVerificationImport([
      {
        batchId: 'B-100',
        verificationCaseId: 'VC-1',
        recordId: 'R-1',
        legalFirstName: 'Janice',
        legalLastName: 'Smith',
        claimedOrganization: 'Alpha Phi Alpha',
        organizationResult: 'VERIFIED',
        organizationReason: 'Confirmed',
      },
      {
        batchId: 'B-100',
        verificationCaseId: 'VC-1',
        recordId: 'R-1',
        legalFirstName: 'Janice',
        legalLastName: 'Smith',
        claimedOrganization: 'Alpha Phi Alpha',
        organizationResult: 'VERIFIED',
        organizationReason: 'Confirmed',
      },
      {
        batchId: 'B-100',
        verificationCaseId: 'VC-2',
        recordId: 'R-2',
        legalFirstName: 'Marcus',
        legalLastName: 'Brown',
        claimedOrganization: 'Kappa Alpha Psi',
        organizationResult: 'REJECTED',
        organizationReason: '',
      },
    ], 'B-100', 'Alpha Phi Alpha', new Set(['VC-1']))

    expect(preview.validRows).toBe(0)
    expect(preview.invalidRows).toBe(1)
    expect(preview.conflictingRows).toBe(0)
    expect(preview.alreadyProcessedRows).toBe(2)
  })

  it('tracks conflicting batch or organization rows during workbook preview', () => {
    const preview = previewVerificationImport([
      {
        batchId: 'B-100',
        verificationCaseId: 'VC-1',
        recordId: 'R-1',
        legalFirstName: 'Janice',
        legalLastName: 'Smith',
        claimedOrganization: 'Alpha Phi Alpha',
        organizationResult: 'VERIFIED',
        organizationReason: 'Confirmed',
      },
      {
        batchId: 'B-999',
        verificationCaseId: 'VC-2',
        recordId: 'R-2',
        legalFirstName: 'Marcus',
        legalLastName: 'Brown',
        claimedOrganization: 'Alpha Phi Alpha',
        organizationResult: 'VERIFIED',
        organizationReason: 'Confirmed',
      },
    ], 'B-100', 'Alpha Phi Alpha', new Set())

    expect(preview.validRows).toBe(1)
    expect(preview.conflictingRows).toBe(1)
    expect(preview.invalidRows).toBe(1)
  })

  it('aggregates dashboard metrics from real persisted verification states', () => {
    const metrics = buildVerificationMetrics([
      { status: 'ready_for_batch' },
      { status: 'ready_for_batch' },
      { status: 'sent_to_organization' },
      { status: 'verified' },
      { status: 'rejected' },
      { status: 'needs_follow_up' },
      { status: 'unable_to_verify' },
    ])

    expect(metrics.readyToBatch).toBe(2)
    expect(metrics.sentToOrganizations).toBe(1)
    expect(metrics.verified).toBe(1)
    expect(metrics.rejected).toBe(1)
    expect(metrics.needsFollowUp).toBe(1)
    expect(metrics.unableToVerify).toBe(1)
  })

  it('includes the full batch, history, and lifecycle reconciliation schema expected by Release 3A', () => {
    const migrationSql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20260905_000001_milestone_3a_membership_verification.sql'), 'utf8')
    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_milestone_3a_membership_verification.sql'), 'utf8')

    expect(migrationSql).toContain('verification_batch_items')
    expect(migrationSql).toContain('verification_imports')
    expect(migrationSql).toContain('verification_import_rows')
    expect(migrationSql).toContain('verification_case_history')
    expect(migrationSql).toContain('assign_verification_reviewer')
    expect(migrationSql).toContain('transition_verification_case_status')
    expect(migrationSql).toContain('record_verification_response_received')
    expect(migrationSql).toContain('get_verification_case_history')
    expect(migrationSql).not.toContain('ON CONFLICT DO NOTHING')

    expect(verifierSql).toContain('verification_batch_items')
    expect(verifierSql).toContain('verification_imports')
    expect(verifierSql).toContain('verification_import_rows')
    expect(verifierSql).toContain('verification_case_history')
    expect(verifierSql).toContain('assign_verification_reviewer')
    expect(verifierSql).toContain('transition_verification_case_status')
    expect(verifierSql).toContain('record_verification_response_received')
    expect(verifierSql).toContain('OVERALL PASS')
  })

  it('wraps the union before ordering and keeps the overall row last', async () => {
    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_milestone_3a_membership_verification.sql'), 'utf8')
    const finalQueryBlock = verifierSql.match(/SELECT\s+object_name,\s+expected_present,\s+actual_present,\s+verification_type\s+FROM\s+\(\s+SELECT\s+\*\s+FROM\s+final_status[\s\S]*?\)\s+AS\s+ordered_results\s+ORDER\s+BY\s+CASE\s+verification_type[\s\S]*?END,\s*object_name\s*;/i)?.[0]
    const fromPosition = verifierSql.indexOf('FROM (')
    const orderByPosition = verifierSql.indexOf('ORDER BY')

    expect(finalQueryBlock).toBeTruthy()
    expect(fromPosition).toBeGreaterThan(-1)
    expect(orderByPosition).toBeGreaterThan(fromPosition)
    expect(finalQueryBlock).toMatch(/FROM\s+\(\s+SELECT\s+\*\s+FROM\s+final_status/i)
    expect(finalQueryBlock).toMatch(/\)\s+AS\s+ordered_results\s+ORDER\s+BY\s+CASE\s+verification_type/i)
    expect(finalQueryBlock).toMatch(/WHEN\s+'overall_status'\s+THEN\s+5/i)

    await loadModule()
    expect(() => parseSync(verifierSql)).not.toThrow()
    console.log('VERIFIER_PARSE_OK')
  })
})
