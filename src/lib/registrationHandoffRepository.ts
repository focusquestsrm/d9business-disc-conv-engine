export type RegistrationInvitationEligibilityPayload = {
  p_tenant_id: string | null
  p_prospect_id: string | null
  p_channel: 'email' | 'text' | 'social_media' | 'phone'
  p_consent_allowed?: boolean
  p_opt_out_active?: boolean
  p_frequency_ok?: boolean
  p_human_approval_granted?: boolean
  p_is_expired?: boolean
  p_is_revoked?: boolean
  p_frequency_reason?: string | null
}

export const registrationHandoffRepository = {
  async evaluateInvitationEligibility(payload: RegistrationInvitationEligibilityPayload) {
    return { ok: true, data: [{ allowed: true, reason: 'Eligible for invitation approval.', code: 'eligible' }], payload } as const
  },

  async createInvitation(payload: Record<string, unknown>) {
    return { ok: true, data: null, payload } as const
  },

  async approveInvitation(payload: Record<string, unknown>) {
    return { ok: true, data: null, payload } as const
  },

  async recordInvitationSent(payload: Record<string, unknown>) {
    return { ok: true, data: null, payload } as const
  },

  async startHandoff(payload: Record<string, unknown>) {
    return { ok: true, data: null, payload } as const
  },

  async linkProfile(payload: Record<string, unknown>) {
    return { ok: true, data: null, payload } as const
  },

  async findDuplicateCandidates(payload: Record<string, unknown>) {
    return { ok: true, data: [], payload } as const
  },

  async recordJourneyEvent(payload: Record<string, unknown>) {
    return { ok: true, data: null, payload } as const
  },

  async advanceStage(payload: Record<string, unknown>) {
    return { ok: true, data: null, payload } as const
  },

  async ingestProviderSyncEvent(payload: Record<string, unknown>) {
    return { ok: true, data: null, payload } as const
  },

  async getJourney(payload: Record<string, unknown>) {
    return { ok: true, data: [], payload } as const
  },

  async getReviewQueue(payload: Record<string, unknown>) {
    return { ok: true, data: [], payload } as const
  },
}
