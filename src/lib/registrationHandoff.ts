export const REGISTRATION_LIFECYCLE_STAGES = [
  'invitation_sent',
  'registration_started',
  'profile_created',
  'profile_claimed',
  'profile_completed',
  'verification_pending',
  'verified',
] as const

export type RegistrationLifecycleStage = (typeof REGISTRATION_LIFECYCLE_STAGES)[number]

export type RegistrationInvitationEligibilityInput = {
  channel: 'email' | 'text' | 'social_media' | 'phone'
  consentAllowed?: boolean
  optOutActive?: boolean
  frequencyOk?: boolean
  frequencyReason?: string | null
  humanApprovalGranted?: boolean
  isExpired?: boolean
  isRevoked?: boolean
}

export function normalizeEmail(value: string | null | undefined): string | null {
  const clean = (value ?? '').trim().toLowerCase()
  if (!clean) return null

  const atIndex = clean.indexOf('@')
  if (atIndex <= 0 || atIndex === clean.length - 1) return null

  const localPart = clean.slice(0, atIndex).replace(/\./g, '').split('+')[0]
  const domainPart = clean.slice(atIndex + 1)
  const normalized = `${localPart}@${domainPart}`

  return normalized
}

export function normalizePhone(value: string | null | undefined): string | null {
  const digits = (value ?? '').replace(/\D/g, '')
  if (!digits) return null
  return digits
}

export function normalizeSourceHandle(value: string | null | undefined): string | null {
  const clean = (value ?? '').trim().toLowerCase().replace(/^@+/, '').replace(/[^a-z0-9._-]/g, '')
  return clean || null
}

export function evaluateRegistrationInvitationEligibility(input: RegistrationInvitationEligibilityInput): { allowed: boolean; reason: string; code: string } {
  if (input.consentAllowed === false) {
    return { allowed: false, reason: 'Consent is missing or denied.', code: 'consent_missing' }
  }

  if (input.optOutActive) {
    return { allowed: false, reason: 'Opt-out is active and blocks invitation delivery.', code: 'opt_out_active' }
  }

  if (input.frequencyOk === false) {
    return { allowed: false, reason: input.frequencyReason || 'Frequency limit reached.', code: 'frequency_limit_reached' }
  }

  if (input.isExpired) {
    return { allowed: false, reason: 'Invitation has expired.', code: 'invitation_expired' }
  }

  if (input.isRevoked) {
    return { allowed: false, reason: 'Invitation has been revoked.', code: 'invitation_revoked' }
  }

  if (input.humanApprovalGranted !== true) {
    return { allowed: false, reason: 'Human approval is required before this invitation can be sent.', code: 'human_approval_required' }
  }

  return { allowed: true, reason: 'Eligible for invitation approval and delivery.', code: 'eligible' }
}

export function canAdvanceRegistrationStage(currentStage: RegistrationLifecycleStage | null | undefined, nextStage: RegistrationLifecycleStage): boolean {
  if (!currentStage) {
    return nextStage === 'invitation_sent' || nextStage === 'registration_started'
  }

  const currentIndex = REGISTRATION_LIFECYCLE_STAGES.indexOf(currentStage)
  const nextIndex = REGISTRATION_LIFECYCLE_STAGES.indexOf(nextStage)

  if (currentIndex === -1 || nextIndex === -1) return false
  if (nextIndex <= currentIndex) return false

  if (nextStage === 'verified') return currentIndex >= REGISTRATION_LIFECYCLE_STAGES.indexOf('profile_completed')
  if (nextStage === 'profile_completed') return currentStage === 'profile_claimed'
  if (nextStage === 'profile_claimed') return currentStage === 'profile_created'
  if (nextStage === 'profile_created') return currentStage === 'registration_started'
  if (nextStage === 'registration_started') return currentStage === 'invitation_sent'
  if (nextStage === 'invitation_sent') return currentStage === 'invitation_sent' || currentStage === 'registration_started'

  return true
}

export function buildRegistrationJourneyEvent(input: {
  stage: RegistrationLifecycleStage
  previousStage?: RegistrationLifecycleStage | null
  newStage?: RegistrationLifecycleStage | null
  source?: string | null
  actor?: string | null
  metadata?: Record<string, unknown> | null
}) {
  return {
    stage: input.stage,
    previousStage: input.previousStage ?? null,
    newStage: input.newStage ?? input.stage,
    source: input.source ?? 'system',
    actor: input.actor ?? null,
    metadata: input.metadata ?? {},
  }
}
