export type D9ConnectionStatus =
  | 'known_greek'
  | 'unknown'
  | 'community_business'
  | 'existing_member'
  | 'duplicate'
  | 'opt_out'

export type MatchConfidence = 'exact' | 'probable' | 'possible' | 'no_match'

export type MatchCandidate = {
  matchReason: string
  confidence: MatchConfidence
  fieldsMatched: string[]
  fieldsConflicting: string[]
  recommendedAction: 'use_existing' | 'manual_review' | 'new_record' | 'duplicate_review'
}

export type ProspectRecord = {
  id: string
  businessName: string
  displayName: string
  primaryContactName?: string
  email?: string
  phone?: string
  website?: string
  instagramHandle?: string
  facebookUrl?: string
  linkedInUrl?: string
  city?: string
  state?: string
  industry?: string
  shortDescription?: string
  d9ConnectionStatus: D9ConnectionStatus
  workflowStatus: string
  consentStatus: string
  sourceUrl?: string
}

export const normalizeText = (value?: string) => (value ?? '').trim().toLowerCase()

export const normalizeEmail = (value?: string) => normalizeText(value).replace(/\s+/g, '')

export const normalizePhone = (value?: string) =>
  normalizeText(value)
    .replace(/[^\d+]/g, '')
    .replace(/^\+?1/, '')

export const normalizeHandle = (value?: string) => normalizeText(value).replace(/^@/, '')

export const normalizeWebsite = (value?: string) => {
  const normalized = normalizeText(value)
  return normalized.replace(/^https?:\/\//, '').replace(/\/$/, '')
}

export const classifyD9Status = (record: Partial<ProspectRecord>): D9ConnectionStatus => {
  const normalized = normalizeText(record.d9ConnectionStatus)

  if (normalized === 'known_greek') return 'known_greek'
  if (normalized === 'community_business') return 'community_business'
  if (normalized === 'existing_member') return 'existing_member'
  if (normalized === 'duplicate') return 'duplicate'
  if (normalized === 'opt_out') return 'opt_out'

  return 'unknown'
}

export const getWorkflowRoutingLabel = (status?: string) => {
  const normalized = normalizeText(status)

  if (normalized === 'known_greek') return 'Known Greek'
  if (normalized === 'community_business') return 'Community Business'
  if (normalized === 'existing_member') return 'Existing Member'
  if (normalized === 'duplicate') return 'Duplicate'
  if (normalized === 'opt_out') return 'Opt-out'
  return 'Unknown'
}

export const getWorkflowNextAction = (status?: string) => {
  const normalized = normalizeText(status)

  if (normalized === 'opt_out') return 'Do not contact; preserve opt-out history and suppress outreach.'
  if (normalized === 'duplicate') return 'Route to duplicate review and require human approval before any merge.'
  if (normalized === 'existing_member') return 'Use existing member path and maintain relationship continuity.'
  if (normalized === 'community_business') return 'Queue for community-fit review and outreach sequencing.'
  if (normalized === 'known_greek') return 'Advance to trusted-path workflow and relationship-based outreach.'
  return 'Unknown status; keep in discovery intake and revisit with validation.'
}

export const findMatchCandidates = (candidate: Partial<ProspectRecord>): MatchCandidate[] => {
  const results: MatchCandidate[] = []
  const businessName = normalizeText(candidate.businessName)
  const email = normalizeEmail(candidate.email)
  const website = normalizeWebsite(candidate.website)
  const phone = normalizePhone(candidate.phone)
  const instagram = normalizeHandle(candidate.instagramHandle)

  if (businessName && candidate.city && candidate.state) {
    results.push({
      matchReason: 'Normalized business name plus city/state match',
      confidence: 'probable',
      fieldsMatched: ['businessName', 'city', 'state'],
      fieldsConflicting: [],
      recommendedAction: 'manual_review',
    })
  }

  if (email) {
    results.push({
      matchReason: 'Exact normalized email match',
      confidence: 'exact',
      fieldsMatched: ['email'],
      fieldsConflicting: [],
      recommendedAction: 'use_existing',
    })
  }

  if (website) {
    results.push({
      matchReason: 'Exact normalized website match',
      confidence: 'exact',
      fieldsMatched: ['website'],
      fieldsConflicting: [],
      recommendedAction: 'use_existing',
    })
  }

  if (phone) {
    results.push({
      matchReason: 'Normalized phone number match',
      confidence: 'probable',
      fieldsMatched: ['phone'],
      fieldsConflicting: [],
      recommendedAction: 'manual_review',
    })
  }

  if (instagram) {
    results.push({
      matchReason: 'Exact normalized social handle match',
      confidence: 'probable',
      fieldsMatched: ['instagramHandle'],
      fieldsConflicting: [],
      recommendedAction: 'manual_review',
    })
  }

  if (!results.length) {
    return [{
      matchReason: 'No deterministic match found',
      confidence: 'no_match',
      fieldsMatched: [],
      fieldsConflicting: [],
      recommendedAction: 'new_record',
    }]
  }

  return results
}
