export type MembershipVerificationStatus =
  | 'not_requested'
  | 'information_incomplete'
  | 'ready_for_batch'
  | 'batched'
  | 'exported'
  | 'sent_to_organization'
  | 'response_received'
  | 'verified'
  | 'unable_to_verify'
  | 'rejected'
  | 'needs_follow_up'
  | 'expired'

export type VerificationResultValue = 'VERIFIED' | 'UNABLE_TO_VERIFY' | 'REJECTED' | 'NEEDS_FOLLOW_UP'

export type MembershipClaimInput = {
  legalFirstName?: string
  legalMiddleName?: string
  legalLastName?: string
  suffix?: string
  preferredName?: string
  email?: string
  phone?: string
  claimedOrganization?: string
  chapterName?: string
  chapterType?: string
  chapterCity?: string
  chapterState?: string
  collegeOrUniversity?: string
  initiationYear?: string
  initiationSeason?: string
  membershipCardNumber?: string
  lineName?: string
  lineNumber?: string
  consentAcknowledged?: boolean
  consentDate?: string
  sourceRecordId?: string
  internalVerificationCaseId?: string
}

export type MembershipClaimErrors = Partial<Record<keyof MembershipClaimInput, string>> & {
  consentAcknowledged?: string
}

export const validateMembershipClaim = (values: MembershipClaimInput): MembershipClaimErrors => {
  const errors: MembershipClaimErrors = {}

  if (!values.legalFirstName?.trim()) errors.legalFirstName = 'Legal first name is required.'
  if (!values.legalLastName?.trim()) errors.legalLastName = 'Legal last name is required.'
  if (!values.claimedOrganization?.trim()) errors.claimedOrganization = 'Claimed organization is required.'
  if (!values.consentAcknowledged) errors.consentAcknowledged = 'Verification consent must be acknowledged before a claim can be submitted.'
  if (!values.consentDate?.trim()) errors.consentDate = 'Consent date is required.'

  return errors
}

const allowedVerificationTransitions: Record<MembershipVerificationStatus, MembershipVerificationStatus[]> = {
  not_requested: ['information_incomplete', 'ready_for_batch'],
  information_incomplete: ['ready_for_batch', 'expired'],
  ready_for_batch: ['batched', 'rejected', 'needs_follow_up', 'expired'],
  batched: ['exported', 'cancelled' as any, 'expired'],
  exported: ['sent_to_organization', 'expired'],
  sent_to_organization: ['response_received', 'expired'],
  response_received: ['verified', 'unable_to_verify', 'rejected', 'needs_follow_up'],
  verified: ['expired'],
  unable_to_verify: ['needs_follow_up', 'expired'],
  rejected: ['needs_follow_up', 'expired'],
  needs_follow_up: ['ready_for_batch', 'expired'],
  expired: ['ready_for_batch'],
}

export function canTransitionVerificationStatus(
  currentStatus: MembershipVerificationStatus,
  nextStatus: MembershipVerificationStatus,
  context: { authorized?: boolean; reason?: string } = {},
): boolean {
  if (!context.authorized) return false

  if (nextStatus === 'verified' && currentStatus !== 'response_received') return false
  if (['rejected', 'unable_to_verify', 'needs_follow_up'].includes(nextStatus) && !context.reason?.trim()) return false

  const allowed = allowedVerificationTransitions[currentStatus] ?? []
  return allowed.includes(nextStatus)
}

export function buildVerificationExportColumns(): string[] {
  return [
    'Batch ID',
    'Verification Case ID',
    'D9Network Record ID',
    'Legal First Name',
    'Legal Middle Name/Initial',
    'Legal Last Name',
    'Suffix',
    'Preferred Name',
    'Email',
    'Phone',
    'Claimed Organization',
    'Chapter Name',
    'Chapter Type',
    'Chapter City',
    'Chapter State',
    'College/University',
    'Initiation Year',
    'Initiation Season/Term',
    'Membership/Card Number',
    'Line Name',
    'Line Number',
    'Organization Result',
    'Organization Reason',
    'Organization Notes',
    'Verified By',
    'Verification Date',
  ]
}

export function validateVerificationResult(value: string): boolean {
  return ['VERIFIED', 'UNABLE_TO_VERIFY', 'REJECTED', 'NEEDS_FOLLOW_UP'].includes(value)
}

export function nextOpenBatchDuplicateCheck(
  organization: string,
  openBatchOrganizations: Array<string | null | undefined>,
): boolean {
  const normalizedOrganization = organization.trim().toLowerCase()
  const matches = openBatchOrganizations.filter((value) => value && value.trim().toLowerCase() === normalizedOrganization)
  return matches.length > 1
}

export function buildVerificationMetrics(cases: Array<{ status?: string }>) {
  return {
    awaitingInformation: cases.filter((item) => item.status === 'information_incomplete').length,
    readyToBatch: cases.filter((item) => item.status === 'ready_for_batch').length,
    sentToOrganizations: cases.filter((item) => item.status === 'sent_to_organization').length,
    responsesReceived: cases.filter((item) => item.status === 'response_received').length,
    verified: cases.filter((item) => item.status === 'verified').length,
    unableToVerify: cases.filter((item) => item.status === 'unable_to_verify').length,
    rejected: cases.filter((item) => item.status === 'rejected').length,
    needsFollowUp: cases.filter((item) => item.status === 'needs_follow_up').length,
    averageTurnaroundDays: 0,
  }
}

export function previewVerificationImport(
  rows: Array<{
    batchId: string
    verificationCaseId: string
    recordId: string
    legalFirstName?: string
    legalLastName?: string
    claimedOrganization?: string
    organizationResult?: string
    organizationReason?: string
  }>,
  batchId: string,
  organization: string,
  alreadyProcessedCaseIds: Set<string>,
): {
  validRows: number
  invalidRows: number
  unchangedRows: number
  conflictingRows: number
  alreadyProcessedRows: number
} {
  let validRows = 0
  let invalidRows = 0
  let unchangedRows = 0
  let conflictingRows = 0
  let alreadyProcessedRows = 0

  const seenInCurrentPreview = new Set<string>()
  const processedSet = new Set(alreadyProcessedCaseIds)

  for (const row of rows) {
    const caseId = row.verificationCaseId?.trim()
    const validBatch = row.batchId === batchId
    const validOrg = row.claimedOrganization?.trim().toLowerCase() === organization.trim().toLowerCase()
    const validId = Boolean(caseId) && Boolean(row.recordId?.trim())
    const allowedResult = row.organizationResult ? validateVerificationResult(row.organizationResult) : false
    const reasonRequired = ['UNABLE_TO_VERIFY', 'REJECTED', 'NEEDS_FOLLOW_UP'].includes(row.organizationResult ?? '')
    const reasonPresent = Boolean((row.organizationReason ?? '').trim())

    if (caseId && (processedSet.has(caseId) || seenInCurrentPreview.has(caseId))) {
      alreadyProcessedRows += 1
      continue
    }

    if (!validId || !allowedResult || (reasonRequired && !reasonPresent)) {
      invalidRows += 1
      continue
    }

    if (!validBatch || !validOrg) {
      conflictingRows += 1
      invalidRows += 1
      continue
    }

    if (caseId) {
      seenInCurrentPreview.add(caseId)
    }

    validRows += 1
  }

  return {
    validRows,
    invalidRows,
    unchangedRows,
    conflictingRows,
    alreadyProcessedRows,
  }
}
