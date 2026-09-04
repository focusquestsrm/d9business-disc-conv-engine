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
})
