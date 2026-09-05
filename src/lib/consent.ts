export const CONSENT_CHANNELS = ['email', 'phone', 'text', 'social_media'] as const
export const CONSENT_STATUSES = ['granted', 'denied', 'withdrawn', 'expired'] as const
export const CONSENT_PURPOSES = ['general_communication', 'verification', 'marketing', 'service_updates', 'security_notice'] as const

export type ConsentChannel = (typeof CONSENT_CHANNELS)[number]
export type ConsentStatus = (typeof CONSENT_STATUSES)[number]
export type ConsentPurpose = (typeof CONSENT_PURPOSES)[number]

export type ConsentPreference = {
  id?: string
  subject_type: string
  subject_id: string
  tenant_id?: string | null
  channel: ConsentChannel
  purpose: ConsentPurpose
  status: ConsentStatus
  capture_source?: string | null
  captured_at?: string | null
  effective_at?: string | null
  expires_at?: string | null
  withdrawn_at?: string | null
  privacy_notice_version?: string | null
  created_by?: string | null
  updated_by?: string | null
  created_at?: string | null
  updated_at?: string | null
}

export type ConsentDecision = {
  allowed: boolean
  reason: string
  channel: ConsentChannel
  purpose: ConsentPurpose
  consentStatus: ConsentStatus | null
}

export type SuppressionRecord = {
  kind: 'global' | 'channel'
  channel?: ConsentChannel | null
  active: boolean
  reason?: string | null
  effective_at?: string | null
  expires_at?: string | null
}

export function normalizeConsentChannel(value: string): ConsentChannel | null {
  return CONSENT_CHANNELS.includes(value as ConsentChannel) ? (value as ConsentChannel) : null
}

export function normalizeConsentStatus(value: string): ConsentStatus | null {
  return CONSENT_STATUSES.includes(value as ConsentStatus) ? (value as ConsentStatus) : null
}

export function isConsentCurrentlyActive(preference: Pick<ConsentPreference, 'status' | 'effective_at' | 'expires_at' | 'withdrawn_at'> | null | undefined, now = new Date()): boolean {
  if (!preference) return false
  if (preference.status !== 'granted') return false
  const effective = preference.effective_at ? new Date(preference.effective_at) : new Date(0)
  if (effective > now) return false
  if (preference.withdrawn_at && new Date(preference.withdrawn_at) <= now) return false
  if (preference.expires_at && new Date(preference.expires_at) <= now) return false
  return true
}

export function evaluateOutreachEligibility(input: {
  consentPreferences?: Array<ConsentPreference>
  suppressions?: Array<SuppressionRecord>
  channel: ConsentChannel
  purpose: ConsentPurpose
  now?: Date
}): ConsentDecision {
  const now = input.now ?? new Date()
  const channelOptOut = (input.suppressions ?? []).find((suppression) => suppression.kind === 'channel' && suppression.channel === input.channel && suppression.active)
  const globalOptOut = (input.suppressions ?? []).find((suppression) => suppression.kind === 'global' && suppression.active)

  if (globalOptOut) {
    return { allowed: false, reason: 'Global opt-out is active and overrides all outreach.', channel: input.channel, purpose: input.purpose, consentStatus: null }
  }

  if (channelOptOut) {
    return { allowed: false, reason: `Channel opt-out is active for ${input.channel}.`, channel: input.channel, purpose: input.purpose, consentStatus: null }
  }

  const preference = (input.consentPreferences ?? []).find((record) => record.channel === input.channel && record.purpose === input.purpose)
  if (!preference) {
    return { allowed: false, reason: 'No active consent exists for this channel and purpose.', channel: input.channel, purpose: input.purpose, consentStatus: null }
  }

  if (preference.status === 'withdrawn') {
    return { allowed: false, reason: 'Consent was withdrawn and is no longer valid.', channel: input.channel, purpose: input.purpose, consentStatus: preference.status }
  }

  if (preference.status === 'expired') {
    return { allowed: false, reason: 'Consent has expired.', channel: input.channel, purpose: input.purpose, consentStatus: preference.status }
  }

  if (preference.status === 'denied') {
    return { allowed: false, reason: 'Consent was explicitly denied.', channel: input.channel, purpose: input.purpose, consentStatus: preference.status }
  }

  if (!isConsentCurrentlyActive(preference, now)) {
    return { allowed: false, reason: 'Consent is not currently active for this channel and purpose.', channel: input.channel, purpose: input.purpose, consentStatus: preference.status }
  }

  return { allowed: true, reason: 'Valid active consent exists and no suppression is in effect.', channel: input.channel, purpose: input.purpose, consentStatus: preference.status }
}

export function evaluateVerificationSharingEligibility(input: {
  generalConsent?: Array<ConsentPreference>
  organizationConsent?: Array<{ subject_id: string; selected_organization: string; status: 'granted' | 'withdrawn' | 'denied' | 'expired'; effective_at?: string | null; expires_at?: string | null; withdrawn_at?: string | null }>
  selectedOrganization?: string | null
  channel?: ConsentChannel
  purpose?: ConsentPurpose
  now?: Date
}): { allowed: boolean; reason: string } {
  const now = input.now ?? new Date()
  if (!input.selectedOrganization) {
    return { allowed: false, reason: 'No organization was selected for verification sharing.' }
  }

  const orgConsent = (input.organizationConsent ?? []).find((record) => record.selected_organization === input.selectedOrganization)
  if (!orgConsent) {
    return { allowed: false, reason: 'No active verification-sharing consent exists for the selected organization.' }
  }

  if (orgConsent.status !== 'granted') {
    return { allowed: false, reason: `Verification-sharing consent is ${orgConsent.status}.` }
  }

  const effective = orgConsent.effective_at ? new Date(orgConsent.effective_at) : new Date(0)
  if (effective > now) return { allowed: false, reason: 'Verification-sharing consent has not taken effect yet.' }
  if (orgConsent.withdrawn_at && new Date(orgConsent.withdrawn_at) <= now) return { allowed: false, reason: 'Verification-sharing consent was withdrawn.' }
  if (orgConsent.expires_at && new Date(orgConsent.expires_at) <= now) return { allowed: false, reason: 'Verification-sharing consent expired.' }

  const general = (input.generalConsent ?? []).find((record) => record.channel === (input.channel ?? 'email') && record.purpose === (input.purpose ?? 'general_communication'))
  if (!general || general.status !== 'granted' || !isConsentCurrentlyActive(general, now)) {
    return { allowed: false, reason: 'General communication consent is not active; it does not satisfy verification-sharing consent.' }
  }

  return { allowed: true, reason: 'Verification-sharing consent is active and specific to the selected organization.' }
}

export function explainSuppressionPrecedence(suppressions: Array<SuppressionRecord>): string {
  const globalActive = suppressions.some((item) => item.kind === 'global' && item.active)
  if (globalActive) return 'Global opt-out is active and suppresses all channels.'

  const channels = suppressions.filter((item) => item.kind === 'channel' && item.active)
  if (channels.length === 0) return 'No active suppressions.'

  return channels.map((item) => `${item.channel ?? 'channel'} suppression is active`).join('; ')
}

export function createRetentionDispositionEligible(policy: { retention_days: number; effective_from?: string | null; enabled?: boolean }, createdAt: string, now = new Date()): boolean {
  if (!policy.enabled) return false
  const effectiveFrom = policy.effective_from ? new Date(policy.effective_from) : new Date(0)
  if (effectiveFrom > now) return false
  const created = new Date(createdAt)
  const elapsedDays = (now.getTime() - created.getTime()) / 86_400_000
  return elapsedDays >= policy.retention_days
}
