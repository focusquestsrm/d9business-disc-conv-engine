export type AiEngagementSuggestionRecord = {
  id: string
  tenant_id?: string | null
  prospect_id?: string | null
  engagement_thread_id?: string | null
  connection_id?: string | null
  platform?: string | null
  channel?: string | null
  suggestion_type?: string | null
  subject_line?: string | null
  content?: string | null
  status?: string | null
  generation_source?: string | null
  personalization_fields?: Record<string, unknown> | null
  source_context?: Record<string, unknown> | null
  model_provider?: string | null
  model_name?: string | null
  prompt_template_id?: string | null
  prompt_version?: string | null
  confidence_score?: number | null
  uncertainty_reasons?: unknown[] | null
  safety_labels?: unknown[] | null
  sensitivity_level?: string | null
  created_by?: string | null
  generated_at?: string | null
  updated_at?: string | null
  expires_at?: string | null
}

export type AiEngagementApprovalRecord = {
  id: string
  suggestion_id?: string | null
  decision?: string | null
  decided_by?: string | null
  decided_at?: string | null
  edited_content_snapshot?: string | null
  decision_reason?: string | null
  eligibility_snapshot?: Record<string, unknown> | null
  frequency_snapshot?: Record<string, unknown> | null
  provider_capability_snapshot?: Record<string, unknown> | null
}

export type EngagementFollowUpRecord = {
  id: string
  prospect_id?: string | null
  thread_id?: string | null
  suggestion_id?: string | null
  outreach_attempt_id?: string | null
  due_at?: string | null
  reminder_type?: string | null
  priority?: string | null
  status?: string | null
  assigned_to?: string | null
  reason?: string | null
  created_by?: string | null
  completed_by?: string | null
  completed_at?: string | null
  snoozed_until?: string | null
  created_at?: string | null
  updated_at?: string | null
}

export type EngagementEscalationRecord = {
  id: string
  prospect_id?: string | null
  thread_id?: string | null
  message_id?: string | null
  classification_id?: string | null
  escalation_type?: string | null
  severity?: string | null
  reason?: string | null
  status?: string | null
  assigned_to?: string | null
  work_queue_item_id?: string | null
  created_at?: string | null
  resolved_at?: string | null
  resolved_by?: string | null
  resolution_notes?: string | null
}

export type EngagementOutcomeRecord = {
  id: string
  prospect_id?: string | null
  thread_id?: string | null
  message_id?: string | null
  outcome?: string | null
  confidence_score?: number | null
  classification_source?: string | null
  sensitivity_level?: string | null
  uncertainty_reasons?: unknown[] | null
  evidence_summary?: string | null
  requires_staff_review?: boolean | null
  reviewed_by?: string | null
  reviewed_at?: string | null
  final_outcome?: string | null
  created_at?: string | null
}

export type OutreachAttemptRecord = {
  id: string
  suggestion_id?: string | null
  prospect_id?: string | null
  thread_id?: string | null
  connection_id?: string | null
  platform?: string | null
  channel?: string | null
  attempt_type?: string | null
  status?: string | null
  attempted_by?: string | null
  provider_message_id?: string | null
  provider_status?: string | null
  eligibility_result?: string | null
  block_reason?: string | null
  failure_reason?: string | null
  content_snapshot?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string | null
}

export const aiEngagementRepository = {
  async createSuggestion(payload: {
    p_tenant_id: string | null
    p_prospect_id: string | null
    p_engagement_thread_id?: string | null
    p_connection_id?: string | null
    p_platform: string
    p_channel: string
    p_suggestion_type: string
    p_subject_line?: string | null
    p_content: string
    p_status?: string
    p_generation_source?: string
    p_personalization_fields?: Record<string, unknown> | null
    p_source_context?: Record<string, unknown> | null
    p_model_provider?: string | null
    p_model_name?: string | null
    p_prompt_template_id?: string | null
    p_prompt_version?: string
    p_confidence_score?: number
    p_uncertainty_reasons?: unknown[] | null
    p_safety_labels?: unknown[] | null
    p_sensitivity_level?: string
    p_created_by?: string | null
  }) {
    return { ok: true, data: null as AiEngagementSuggestionRecord | null, payload } as const
  },

  async generateSuggestion(payload: {
    p_tenant_id: string | null
    p_prospect_id: string | null
    p_platform: string
    p_channel: string
    p_suggestion_type: string
    p_business_name?: string | null
    p_prospect_name?: string | null
    p_handle?: string | null
    p_content?: string | null
    p_created_by?: string | null
  }) {
    return { ok: true, data: null as AiEngagementSuggestionRecord | null, payload } as const
  },

  async updateDraft(payload: {
    p_suggestion_id: string
    p_content?: string | null
    p_subject_line?: string | null
    p_status?: string | null
    p_personalization_fields?: Record<string, unknown> | null
    p_source_context?: Record<string, unknown> | null
    p_confidence_score?: number | null
  }) {
    return { ok: true, data: null as AiEngagementSuggestionRecord | null, payload } as const
  },

  async submitForReview(payload: { p_suggestion_id: string; p_reviewed_by?: string | null }) {
    return { ok: true, data: null as AiEngagementSuggestionRecord | null, payload } as const
  },

  async approve(payload: {
    p_suggestion_id: string
    p_decided_by: string
    p_decision_reason?: string
    p_edited_content_snapshot?: string | null
    p_eligibility_snapshot?: Record<string, unknown> | null
    p_frequency_snapshot?: Record<string, unknown> | null
    p_provider_capability_snapshot?: Record<string, unknown> | null
  }) {
    return { ok: true, data: null as AiEngagementSuggestionRecord | null, payload } as const
  },

  async reject(payload: { p_suggestion_id: string; p_decided_by: string; p_reason?: string | null }) {
    return { ok: true, data: null as AiEngagementSuggestionRecord | null, payload } as const
  },

  async cancel(payload: { p_suggestion_id: string; p_cancelled_by?: string | null; p_reason?: string | null }) {
    return { ok: true, data: null as AiEngagementSuggestionRecord | null, payload } as const
  },

  async evaluateSendEligibility(payload: {
    p_prospect_id: string
    p_connection_id?: string | null
    p_thread_id?: string | null
    p_platform: string
    p_channel: string
    p_purpose?: string
    p_consent_allowed?: boolean
    p_suppression_blocked?: boolean
    p_sensitive_response_hold?: boolean
    p_provider_connected?: boolean
    p_provider_activity_permitted?: boolean
    p_frequency_ok?: boolean
    p_frequency_reason?: string | null
    p_cooldown_active?: boolean
    p_prospect_match_required?: boolean
    p_prospect_matched?: boolean
    p_requires_human_approval?: boolean
    p_human_approval_granted?: boolean
  }) {
    return { ok: true, data: [{ allowed: false, reason: 'Deferred provider evaluation', code: 'provider_not_connected' }] as Array<{ allowed: boolean; reason: string; code: string }>, payload } as const
  },

  async recordOutreachAttempt(payload: {
    p_tenant_id: string | null
    p_suggestion_id?: string | null
    p_prospect_id: string
    p_thread_id?: string | null
    p_connection_id?: string | null
    p_platform: string
    p_channel: string
    p_attempt_type?: string
    p_status?: string
    p_attempted_by?: string | null
    p_provider_message_id?: string | null
    p_provider_status?: string | null
    p_eligibility_result?: string
    p_block_reason?: string | null
    p_failure_reason?: string | null
    p_content_snapshot?: string | null
    p_metadata?: Record<string, unknown> | null
  }) {
    return { ok: true, data: null as OutreachAttemptRecord | null, payload } as const
  },

  async recordManualDelivery(payload: {
    p_tenant_id: string | null
    p_suggestion_id: string
    p_prospect_id: string
    p_thread_id?: string | null
    p_connection_id?: string | null
    p_platform: string
    p_channel: string
    p_attempted_by?: string | null
    p_content_snapshot?: string | null
  }) {
    return { ok: true, data: null as OutreachAttemptRecord | null, payload } as const
  },

  async classifyOutcome(payload: {
    p_tenant_id: string | null
    p_prospect_id: string
    p_thread_id: string
    p_message_id?: string | null
    p_outcome: string
    p_confidence_score?: number
    p_classification_source?: string
    p_sensitivity_level?: string
    p_uncertainty_reasons?: unknown[] | null
    p_evidence_summary?: string | null
    p_requires_staff_review?: boolean
    p_reviewed_by?: string | null
  }) {
    return { ok: true, data: null as EngagementOutcomeRecord | null, payload } as const
  },

  async reviewOutcome(payload: { p_classification_id: string; p_final_outcome: string; p_reviewed_by?: string | null }) {
    return { ok: true, data: null as EngagementOutcomeRecord | null, payload } as const
  },

  async createFollowUp(payload: {
    p_tenant_id: string | null
    p_prospect_id: string
    p_thread_id?: string | null
    p_suggestion_id?: string | null
    p_outreach_attempt_id?: string | null
    p_due_at: string
    p_reminder_type: string
    p_priority?: string
    p_status?: string
    p_assigned_to?: string | null
    p_reason?: string | null
    p_created_by?: string | null
  }) {
    return { ok: true, data: null as EngagementFollowUpRecord | null, payload } as const
  },

  async snoozeFollowUp(payload: { p_reminder_id: string; p_snoozed_until: string; p_assigned_to?: string | null }) {
    return { ok: true, data: null as EngagementFollowUpRecord | null, payload } as const
  },

  async completeFollowUp(payload: { p_reminder_id: string; p_completed_by?: string | null }) {
    return { ok: true, data: null as EngagementFollowUpRecord | null, payload } as const
  },

  async escalateResponse(payload: {
    p_tenant_id: string | null
    p_prospect_id?: string | null
    p_thread_id: string
    p_message_id?: string | null
    p_classification_id?: string | null
    p_escalation_type: string
    p_severity?: string
    p_reason: string
    p_status?: string
    p_assigned_to?: string | null
    p_work_queue_item_id?: string | null
  }) {
    return { ok: true, data: null as EngagementEscalationRecord | null, payload } as const
  },

  async resolveEscalation(payload: { p_escalation_id: string; p_resolved_by?: string | null; p_resolution_notes?: string | null }) {
    return { ok: true, data: null as EngagementEscalationRecord | null, payload } as const
  },

  async loadReviewQueue(payload: { p_tenant_id?: string | null } = {}) {
    return { ok: true, data: [] as AiEngagementSuggestionRecord[], payload } as const
  },

  async loadFollowUps(payload: { p_tenant_id?: string | null; p_prospect_id?: string | null } = {}) {
    return { ok: true, data: [] as EngagementFollowUpRecord[], payload } as const
  },

  async loadEscalations(payload: { p_tenant_id?: string | null; p_prospect_id?: string | null } = {}) {
    return { ok: true, data: [] as EngagementEscalationRecord[], payload } as const
  },

  async loadEngagementTimeline(payload: { p_tenant_id?: string | null; p_prospect_id?: string | null } = {}) {
    return { ok: true, data: [] as Array<{ object_type: string; object_id: string; related_thread_id?: string | null; created_at?: string | null; status?: string | null; summary?: string | null }>, payload } as const
  },
}
