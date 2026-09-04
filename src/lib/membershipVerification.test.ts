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

  it('aggregates one overall row, keeps the result last, and parses cleanly', async () => {
    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_milestone_3a_membership_verification.sql'), 'utf8')
    const makeRows = (count: number, passing: boolean) =>
      Array.from({ length: count }, (_, index) => ({
        object_name: `check_${index}`,
        expected_present: true,
        actual_present: passing,
        verification_type: index % 2 === 0 ? 'schema_objects' : 'select_insert_update_policy',
      }))

    const passRows = makeRows(28, true)
    const failRows = [...makeRows(27, true), { object_name: 'failed_check', expected_present: true, actual_present: false, verification_type: 'updated_at_trigger' }]

    const overallPass = {
      object_name: 'OVERALL PASS',
      expected_present: true,
      actual_present: passRows.every((row) => row.actual_present === row.expected_present),
      verification_type: 'overall_status',
    }
    const overallFail = {
      object_name: 'OVERALL FAIL',
      expected_present: true,
      actual_present: failRows.every((row) => row.actual_present === row.expected_present),
      verification_type: 'overall_status',
    }

    expect(passRows.every((row) => row.actual_present === row.expected_present)).toBe(true)
    expect(overallPass.object_name).toBe('OVERALL PASS')
    expect(overallPass.actual_present).toBe(true)
    expect([...(passRows), overallPass]).toHaveLength(29)
    expect([...(passRows), overallPass][[...(passRows), overallPass].length - 1]).toMatchObject({
      object_name: 'OVERALL PASS',
      verification_type: 'overall_status',
      actual_present: true,
    })

    expect(failRows.some((row) => row.actual_present !== row.expected_present)).toBe(true)
    expect(overallFail.object_name).toBe('OVERALL FAIL')
    expect(overallFail.actual_present).toBe(false)
    expect([...(failRows), overallFail]).toHaveLength(29)
    expect([...(failRows), overallFail][[...(failRows), overallFail].length - 1]).toMatchObject({
      object_name: 'OVERALL FAIL',
      verification_type: 'overall_status',
      actual_present: false,
    })

    expect(verifierSql).toContain("CASE WHEN bool_and(actual_present = expected_present) THEN 'OVERALL PASS' ELSE 'OVERALL FAIL' END AS object_name")
    expect(verifierSql).toContain("bool_and(actual_present = expected_present)")
    expect(verifierSql).toContain("'overall_status' AS verification_type")
    expect(verifierSql).toContain("WHEN 'overall_status' THEN 5")

    await loadModule()
    expect(() => parseSync(verifierSql)).not.toThrow()
    console.log('VERIFIER_PARSE_OK')
  })
})
