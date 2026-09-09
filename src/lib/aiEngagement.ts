export const AI_SUGGESTION_TYPES = ['comment', 'direct_message', 'email', 'follow_up', 'staff_response'] as const
export const AI_SUGGESTION_STATUSES = ['draft', 'generated', 'needs_review', 'approved', 'rejected', 'expired', 'blocked', 'pending_delivery', 'delivered', 'delivery_failed', 'cancelled'] as const
export const AI_OUTCOMES = ['positive_interest', 'information_requested', 'verification_question', 'follow_up_needed', 'not_interested', 'opt_out_request', 'wrong_person', 'out_of_office', 'delivery_failure', 'complaint', 'sensitive', 'unclear', 'other'] as const
export const AI_ESCALATION_TYPES = ['sensitive_content', 'low_confidence', 'consent_uncertain', 'identity_uncertain', 'legal_or_compliance', 'complaint', 'threat_or_safety', 'discrimination_or_harassment', 'financial_request', 'medical_or_personal_crisis', 'platform_restriction', 'manual_review'] as const

export type AiSuggestionType = (typeof AI_SUGGESTION_TYPES)[number]
export type AiSuggestionStatus = (typeof AI_SUGGESTION_STATUSES)[number]
export type AiOutcome = (typeof AI_OUTCOMES)[number]
export type AiEscalationType = (typeof AI_ESCALATION_TYPES)[number]

export type AiSuggestionInput = {
  channel: 'comment' | 'direct_message' | 'email'
  platform: 'instagram' | 'facebook' | 'linkedin' | 'email'
  prospectName?: string | null
  businessName?: string | null
  handle?: string | null
  purpose?: string
  reason?: string
  notes?: string | null
  sourceContext?: Record<string, unknown>
}

export function generateLocalAiSuggestion(input: AiSuggestionInput): { suggestionType: AiSuggestionType; subjectLine?: string; content: string; confidence: number; source: 'template'; safetyLabels: string[] } {
  const name = input.prospectName?.trim() || 'there'
  const business = input.businessName?.trim() || 'your team'
  const handle = input.handle?.trim() || 'there'
  const note = input.notes?.trim() || 'Thanks for your interest.'

  if (input.channel === 'email') {
    return {
      suggestionType: 'email',
      subjectLine: `Following up on ${business}`,
      content: `Hi ${name},\n\nThank you for connecting with ${business}. I would be glad to continue the conversation and share a bit more about our work. ${note}\n\nBest,\n${handle}`,
      confidence: 0.78,
      source: 'template',
      safetyLabels: ['low_risk', 'human_review_required'],
    }
  }

  if (input.channel === 'direct_message') {
    return {
      suggestionType: 'direct_message',
      content: `Hi ${name}, thanks for reaching out. I’d be happy to share a bit more about ${business} and continue the conversation. ${note}`,
      confidence: 0.8,
      source: 'template',
      safetyLabels: ['low_risk', 'human_review_required'],
    }
  }

  return {
    suggestionType: 'comment',
    content: `Thanks for the note, ${name}. We’d love to learn more and keep the conversation going with ${business}. ${note}`,
    confidence: 0.74,
    source: 'template',
    safetyLabels: ['low_risk', 'human_review_required'],
  }
}

export type EngagementEligibilityInput = {
  platform: string
  channel: string
  purpose?: string
  suppressions?: Array<{ kind: 'global' | 'channel'; channel?: string | null; active: boolean }>
  consentAllowed?: boolean
  consentStatus?: string | null
  sensitiveResponseHold?: boolean
  providerConnected?: boolean
  providerActivityPermitted?: boolean
  prospectMatchRequired?: boolean
  prospectMatched?: boolean
  requiresHumanApproval?: boolean
  humanApprovalGranted?: boolean
  frequencyOk?: boolean
  frequencyReason?: string | null
  cooldownActive?: boolean
}

export function evaluateEngagementSendEligibility(input: EngagementEligibilityInput): { allowed: boolean; reason: string; code: string } {
  if ((input.suppressions ?? []).some((item) => item.kind === 'global' && item.active)) {
    return { allowed: false, reason: 'Global opt-out is active and blocks outreach.', code: 'global_opt_out' }
  }

  const channelSuppression = (input.suppressions ?? []).find((item) => item.kind === 'channel' && item.channel === input.channel && item.active)
  if (channelSuppression) {
    return { allowed: false, reason: `Channel opt-out is active for ${input.channel}.`, code: 'channel_opt_out' }
  }

  if (input.consentAllowed === false) {
    if (input.consentStatus === 'expired') return { allowed: false, reason: 'Consent expired.', code: 'consent_expired' }
    if (input.consentStatus === 'withdrawn') return { allowed: false, reason: 'Consent withdrawn.', code: 'consent_withdrawn' }
    return { allowed: false, reason: 'Consent is missing or denied.', code: 'consent_missing' }
  }

  if (input.sensitiveResponseHold) {
    return { allowed: false, reason: 'Sensitive response hold prevents outreach.', code: 'sensitive_response_hold' }
  }

  if (input.providerConnected === false) {
    return { allowed: false, reason: 'Connected provider is required for delivery.', code: 'provider_not_connected' }
  }

  if (input.providerActivityPermitted === false) {
    return { allowed: false, reason: 'Provider activity is not permitted for this connection.', code: 'provider_activity_not_permitted' }
  }

  if (input.frequencyOk === false) {
    return {
      allowed: false,
      reason: input.frequencyReason || 'Frequency limit reached.',
      code: input.cooldownActive ? 'cooldown_active' : 'frequency_limit_reached',
    }
  }

  if (input.prospectMatchRequired && input.prospectMatched === false) {
    return { allowed: false, reason: 'Prospect match is required before outreach proceeds.', code: 'prospect_match_required' }
  }

  if (input.requiresHumanApproval && input.humanApprovalGranted !== true) {
    return { allowed: false, reason: 'Human approval is required before this outreach can be sent.', code: 'human_approval_required' }
  }

  return { allowed: true, reason: 'Eligible for approved outreach.', code: 'eligible' }
}

export function classifyEngagementOutcome(input: { text?: string | null; source?: string | null }): { outcome: AiOutcome; confidence: number; requiresStaffReview: boolean; reasons: string[]; sensitivityLevel: 'low' | 'medium' | 'high' } {
  const normalized = (input.text ?? '').toLowerCase()

  if (/opt[- ]?out|unsubscribe|do not contact|stop contacting/i.test(normalized)) {
    return { outcome: 'opt_out_request', confidence: 0.96, requiresStaffReview: true, reasons: ['opt_out_request'], sensitivityLevel: 'high' }
  }

  if (/complaint|abuse|harassment|discrimination|threat|unsafe|scam|fraud/i.test(normalized)) {
    return { outcome: 'complaint', confidence: 0.92, requiresStaffReview: true, reasons: ['complaint_or_safety_concern'], sensitivityLevel: 'high' }
  }

  if (/interested|love to learn|happy to|can you send/i.test(normalized)) {
    return { outcome: 'positive_interest', confidence: 0.88, requiresStaffReview: false, reasons: ['positive_interest_signal'], sensitivityLevel: 'low' }
  }

  if (/send info|share details|what is the cost|pricing|how much/i.test(normalized)) {
    return { outcome: 'information_requested', confidence: 0.81, requiresStaffReview: false, reasons: ['information_requested'], sensitivityLevel: 'medium' }
  }

  if (normalized.length === 0 || normalized.length < 20) {
    return { outcome: 'unclear', confidence: 0.42, requiresStaffReview: true, reasons: ['unclear_intent'], sensitivityLevel: 'medium' }
  }

  return { outcome: 'follow_up_needed', confidence: 0.68, requiresStaffReview: false, reasons: ['follow_up_needed'], sensitivityLevel: 'low' }
}

export function createEngagementFollowUp(input: { reason: string; dueAt: string; priority?: 'low' | 'normal' | 'high'; status?: 'pending' | 'due' | 'snoozed' | 'completed' | 'cancelled' }) {
  return {
    dueAt: input.dueAt,
    priority: input.priority ?? 'normal',
    status: input.status ?? 'pending',
    reason: input.reason,
  }
}

export function deriveReviewState(status: string): 'draft' | 'generated' | 'needs_review' | 'approved' | 'rejected' | 'blocked' | 'pending_delivery' | 'delivered' | 'delivery_failed' | 'cancelled' {
  switch (status) {
    case 'draft':
      return 'draft'
    case 'generated':
      return 'generated'
    case 'review':
      return 'needs_review'
    case 'approved':
      return 'approved'
    case 'rejected':
      return 'rejected'
    case 'blocked':
      return 'blocked'
    case 'pending_delivery':
      return 'pending_delivery'
    case 'delivered':
      return 'delivered'
    case 'delivery_failed':
      return 'delivery_failed'
    default:
      return 'cancelled'
  }
}

export function isStudentSafetySensitive(text: string | null | undefined): boolean {
  return /suicide|self-harm|mental health|medical crisis|urgent help|safety/i.test((text ?? '').toLowerCase())
}
