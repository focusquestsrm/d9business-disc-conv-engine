export type D9WorkflowStatus =
  | 'known_greek'
  | 'unknown'
  | 'community_business'
  | 'existing_member'
  | 'duplicate'
  | 'opt_out'

export type WorkflowRouteDecision = {
  allowed: boolean
  route: 'verification' | 'outreach' | 'community' | 'membership' | 'duplicate_review' | 'blocked'
  requiresVerification: boolean
  reason: string
}

const transitionMatrix: Record<string, string[]> = {
  known_greek: ['community_business', 'existing_member', 'duplicate', 'opt_out'],
  unknown: ['known_greek', 'community_business', 'existing_member', 'duplicate', 'opt_out'],
  community_business: ['existing_member', 'duplicate', 'opt_out'],
  existing_member: ['duplicate', 'opt_out'],
  duplicate: ['opt_out'],
  opt_out: [],
}

export const isTransitionAllowed = (
  currentStatus: D9WorkflowStatus,
  nextStatus: D9WorkflowStatus,
  context: { renewedConsent?: boolean; reportedGreek?: boolean } = {},
): boolean => {
  if (currentStatus === 'opt_out' && nextStatus === 'opt_out') return true
  if (currentStatus === 'opt_out' && context.renewedConsent) return true
  if (currentStatus === 'opt_out') return false
  if (nextStatus === 'opt_out' && !context.renewedConsent) return true
  if (currentStatus === 'duplicate' && nextStatus === 'unknown') return false
  if (currentStatus === 'duplicate' && nextStatus === 'opt_out') return true

  const allowedTargets = transitionMatrix[currentStatus] ?? []
  return allowedTargets.includes(nextStatus)
}

export const getWorkflowRoute = (
  currentStatus: D9WorkflowStatus,
  nextStatus: D9WorkflowStatus,
  context: { renewedConsent?: boolean; reportedGreek?: boolean } = {},
): WorkflowRouteDecision => {
  if (currentStatus === 'opt_out' && !context.renewedConsent) {
    return {
      allowed: false,
      route: 'blocked',
      requiresVerification: true,
      reason: 'Opted-out records cannot return to outreach without renewed consent.',
    }
  }

  if (nextStatus === 'opt_out') {
    return {
      allowed: true,
      route: 'blocked',
      requiresVerification: true,
      reason: 'Opt-out recorded; suppress future outreach until consent is renewed.',
    }
  }

  if (context.reportedGreek || nextStatus === 'known_greek') {
    return {
      allowed: true,
      route: 'verification',
      requiresVerification: true,
      reason: 'Reported Greek affiliation requires verification before any outreach.',
    }
  }

  if (nextStatus === 'unknown') {
    return {
      allowed: true,
      route: 'outreach',
      requiresVerification: false,
      reason: 'Unknown D9 connection remains in outreach and questionnaire follow-up.',
    }
  }

  if (nextStatus === 'community_business') {
    return {
      allowed: true,
      route: 'community',
      requiresVerification: false,
      reason: 'Community business routes to the community pathway.',
    }
  }

  if (nextStatus === 'existing_member') {
    return {
      allowed: true,
      route: 'membership',
      requiresVerification: false,
      reason: 'External membership match routes to existing-member review.',
    }
  }

  if (nextStatus === 'duplicate') {
    return {
      allowed: true,
      route: 'duplicate_review',
      requiresVerification: true,
      reason: 'Duplicate or suspected duplicate requires duplicate review and human approval.',
    }
  }

  return {
    allowed: isTransitionAllowed(currentStatus, nextStatus, context),
    route: 'outreach',
    requiresVerification: false,
    reason: 'No special routing required for this transition.',
  }
}

export const classifyDuplicateMatch = (
  fieldsMatched: string[],
  fieldsConflicting: string[],
): 'exact' | 'probable' | 'possible' | 'no_match' => {
  if (fieldsMatched.length >= 2 && fieldsConflicting.length === 0) return 'exact'
  if (fieldsMatched.length >= 2 && fieldsConflicting.length <= 1) return 'probable'
  if (fieldsMatched.length >= 1 && fieldsConflicting.length <= 2) return 'possible'
  return 'no_match'
}
