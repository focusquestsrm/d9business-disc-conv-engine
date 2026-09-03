export type NominationStatus =
  | 'submitted'
  | 'under_review'
  | 'more_information_needed'
  | 'accepted'
  | 'linked_to_existing'
  | 'duplicate_review'
  | 'rejected'
  | 'withdrawn'

export type NominationDecisionContext = {
  status: NominationStatus
  decisionReason?: string
  hasDuplicateMatch?: boolean
  existingRecordId?: string | null
  businessName?: string
  email?: string
  phone?: string
  website?: string
}

export const NOMINATION_TRANSITIONS: Record<NominationStatus, NominationStatus[]> = {
  submitted: ['under_review', 'more_information_needed', 'duplicate_review', 'rejected', 'withdrawn'],
  under_review: ['more_information_needed', 'accepted', 'linked_to_existing', 'duplicate_review', 'rejected', 'withdrawn'],
  more_information_needed: ['under_review', 'accepted', 'linked_to_existing', 'duplicate_review', 'rejected', 'withdrawn'],
  accepted: [],
  linked_to_existing: [],
  duplicate_review: ['accepted', 'linked_to_existing', 'rejected', 'withdrawn'],
  rejected: [],
  withdrawn: [],
}

export const normalizeNomination = (input: Partial<NominationDecisionContext> & { nominatedBusinessName?: string; primaryContactName?: string; source?: string; reportedD9Status?: string; status?: NominationStatus | string; existingRecordId?: string | null }) => ({
  nominatedBusinessName: (input.nominatedBusinessName ?? '').trim(),
  primaryContactName: (input.primaryContactName ?? '').trim() || undefined,
  email: (input.email ?? '').trim() || undefined,
  phone: (input.phone ?? '').trim() || undefined,
  website: (input.website ?? '').trim() || undefined,
  source: (input.source ?? 'public_submission').trim() || 'public_submission',
  reportedD9Status: (input.reportedD9Status ?? 'unknown').trim() || 'unknown',
  status: (input.status ?? 'submitted') as NominationStatus,
  decisionReason: (input.decisionReason ?? '').trim(),
  businessName: (input.businessName ?? '').trim(),
  existingRecordId: input.existingRecordId ?? null,
})

export const validateNominationTransition = (from: string, to: string) => {
  const fromState = from as NominationStatus
  const toState = to as NominationStatus
  if (!NOMINATION_TRANSITIONS[fromState]) return false
  return NOMINATION_TRANSITIONS[fromState].includes(toState)
}

export const canProcessNomination = (nomination: { status?: string | null }) => {
  const status = (nomination?.status ?? 'submitted') as NominationStatus
  return !['accepted', 'linked_to_existing', 'rejected', 'withdrawn'].includes(status)
}

export const canReviewNomination = (nomination: { status?: string | null }, role?: string | null) => {
  const status = (nomination?.status ?? 'submitted') as NominationStatus
  const authorizedRole = role ? ['platform_admin', 'reviewer', 'manager'].includes(role) : false
  return authorizedRole && canProcessNomination({ status })
}

export const validateNominationDecision = (status: string, reason: string | undefined) => {
  if (status !== 'rejected') return true
  return Boolean((reason ?? '').trim())
}

export const screenNominationForDuplicate = (candidate: {
  nominatedBusinessName?: string
  email?: string
  website?: string
  phone?: string
}) => {
  const businessName = (candidate.nominatedBusinessName ?? '').trim().toLowerCase()
  const email = (candidate.email ?? '').trim().toLowerCase()
  const website = (candidate.website ?? '').trim().toLowerCase().replace(/https?:\/\//, '').replace(/\/$/, '')
  const phone = (candidate.phone ?? '').trim().replace(/\D/g, '')

  const fieldsMatched: string[] = []
  if (businessName) fieldsMatched.push('business_name')
  if (email) fieldsMatched.push('email')
  if (website) fieldsMatched.push('website')
  if (phone) fieldsMatched.push('phone')

  const duplicate = fieldsMatched.length >= 2 || (businessName && (email || website || phone))
  const confidence = duplicate ? (fieldsMatched.length >= 3 ? 'exact' : 'probable') : 'no_match'

  return {
    duplicate,
    confidence,
    fieldsMatched,
    action: duplicate ? 'duplicate_review' : 'new_record',
  }
}

export const createProspectFromNomination = (nomination: ReturnType<typeof normalizeNomination>) => ({
  id: `prospect-${Date.now()}`,
  businessName: nomination.nominatedBusinessName || nomination.businessName || 'New Prospect',
  displayName: nomination.nominatedBusinessName || nomination.businessName || 'New Prospect',
  primaryContactName: nomination.primaryContactName,
  email: nomination.email,
  phone: nomination.phone,
  website: nomination.website,
  d9ConnectionStatus: (nomination.reportedD9Status ?? 'unknown') as any,
  workflowStatus: 'new',
  consentStatus: 'pending',
})
