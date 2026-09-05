import { supabase } from './supabaseClient'
import type { ConsentChannel, ConsentPreference, ConsentPurpose, ConsentStatus } from './consent'

export type ConsentDecisionResult = {
  allowed: boolean
  reason: string
  channel: ConsentChannel
  purpose: ConsentPurpose
  consentStatus: ConsentStatus | null
}

export type ConsentHistoryItem = {
  id: string
  subject_type: string
  subject_id: string
  channel?: string | null
  purpose?: string | null
  organization_name?: string | null
  previous_state?: string | null
  new_state?: string | null
  reason?: string | null
  source?: string | null
  actor_user_id?: string | null
  created_at?: string | null
}

export type RetentionPolicy = {
  id: string
  category: string
  retention_days: number
  enabled: boolean
  disposition: 'retain' | 'delete' | 'anonymize'
  policy_version: string
  effective_from?: string | null
  notes?: string | null
}

export const consentRepository = {
  async loadEffectiveConsent(subjectType: string, subjectId: string) {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { data, error } = await supabase.rpc('get_effective_consent_preferences', {
      p_subject_type: subjectType,
      p_subject_id: subjectId,
    })
    if (error) throw error
    return (data ?? []) as ConsentPreference[]
  },

  async grantChannelConsent(payload: Partial<ConsentPreference>) {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { data, error } = await supabase.rpc('upsert_communication_consent', {
      p_subject_type: payload.subject_type,
      p_subject_id: payload.subject_id,
      p_channel: payload.channel,
      p_purpose: payload.purpose,
      p_status: payload.status ?? 'granted',
      p_capture_source: payload.capture_source ?? 'manual',
      p_privacy_notice_version: payload.privacy_notice_version ?? 'v1',
      p_expires_at: payload.expires_at ?? null,
      p_created_by: payload.created_by ?? null,
      p_updated_by: payload.updated_by ?? null,
    })
    if (error) throw error
    return data
  },

  async withdrawChannelConsent(payload: { subject_type: string; subject_id: string; channel: ConsentChannel; purpose: ConsentPurpose; reason?: string | null; actor_user_id?: string | null }) {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { data, error } = await supabase.rpc('withdraw_communication_consent', {
      p_subject_type: payload.subject_type,
      p_subject_id: payload.subject_id,
      p_channel: payload.channel,
      p_purpose: payload.purpose,
      p_reason: payload.reason ?? null,
      p_actor_user_id: payload.actor_user_id ?? null,
    })
    if (error) throw error
    return data
  },

  async grantVerificationSharingConsent(payload: { subject_type: string; subject_id: string; selected_organization: string; verification_case_id?: string | null; purpose?: string; actor_user_id?: string | null }) {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { data, error } = await supabase.rpc('grant_verification_sharing_consent', {
      p_subject_type: payload.subject_type,
      p_subject_id: payload.subject_id,
      p_selected_organization: payload.selected_organization,
      p_verification_case_id: payload.verification_case_id ?? null,
      p_purpose: payload.purpose ?? 'verification_share',
      p_actor_user_id: payload.actor_user_id ?? null,
    })
    if (error) throw error
    return data
  },

  async withdrawVerificationSharingConsent(payload: { subject_type: string; subject_id: string; selected_organization: string; actor_user_id?: string | null; reason?: string | null }) {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { data, error } = await supabase.rpc('withdraw_verification_sharing_consent', {
      p_subject_type: payload.subject_type,
      p_subject_id: payload.subject_id,
      p_selected_organization: payload.selected_organization,
      p_actor_user_id: payload.actor_user_id ?? null,
      p_reason: payload.reason ?? null,
    })
    if (error) throw error
    return data
  },

  async recordOptOut(payload: { entity_type: string; entity_id: string; source: string; reason?: string | null; channel?: ConsentChannel | null; actor_user_id?: string | null }) {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { data, error } = await supabase.rpc('record_opt_out', {
      p_entity_type: payload.entity_type,
      p_entity_id: payload.entity_id,
      p_source: payload.source,
      p_reason: payload.reason ?? null,
      p_channel: payload.channel ?? null,
      p_actor_user_id: payload.actor_user_id ?? null,
    })
    if (error) throw error
    return data
  },

  async reverseOptOut(payload: { entity_type: string; entity_id: string; reason: string; actor_user_id?: string | null; authorized: boolean }) {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { data, error } = await supabase.rpc('reverse_opt_out', {
      p_entity_type: payload.entity_type,
      p_entity_id: payload.entity_id,
      p_reason: payload.reason,
      p_actor_user_id: payload.actor_user_id ?? null,
      p_authorized: payload.authorized,
    })
    if (error) throw error
    return data
  },

  async evaluateOutreachEligibility(payload: { subject_type: string; subject_id: string; channel: ConsentChannel; purpose: ConsentPurpose; tenant_id?: string | null }) {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { data, error } = await supabase.rpc('evaluate_outreach_eligibility', {
      p_subject_type: payload.subject_type,
      p_subject_id: payload.subject_id,
      p_channel: payload.channel,
      p_purpose: payload.purpose,
      p_tenant_id: payload.tenant_id ?? null,
    })
    if (error) throw error
    return (data ?? []) as ConsentDecisionResult[]
  },

  async evaluateVerificationSharingEligibility(payload: { subject_type: string; subject_id: string; selected_organization: string; verification_case_id?: string | null }) {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { data, error } = await supabase.rpc('evaluate_verification_sharing_eligibility', {
      p_subject_type: payload.subject_type,
      p_subject_id: payload.subject_id,
      p_selected_organization: payload.selected_organization,
      p_verification_case_id: payload.verification_case_id ?? null,
    })
    if (error) throw error
    return (data ?? []) as Array<{ allowed: boolean; reason: string }>
  },

  async loadHistory(subjectType: string, subjectId: string) {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { data, error } = await supabase.rpc('get_consent_history', {
      p_subject_type: subjectType,
      p_subject_id: subjectId,
    })
    if (error) throw error
    return (data ?? []) as ConsentHistoryItem[]
  },

  async loadRetentionPolicies() {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { data, error } = await supabase.from('retention_policies').select('*').order('effective_from', { ascending: false })
    if (error) throw error
    return (data ?? []) as RetentionPolicy[]
  },

  async updateRetentionPolicy(payload: { id: string; category: string; retention_days: number; enabled: boolean; disposition: 'retain' | 'delete' | 'anonymize'; policy_version?: string | null; effective_from?: string | null; notes?: string | null }) {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { data, error } = await supabase.from('retention_policies').update({
      category: payload.category,
      retention_days: payload.retention_days,
      enabled: payload.enabled,
      disposition: payload.disposition,
      policy_version: payload.policy_version ?? 'v1',
      effective_from: payload.effective_from ?? new Date().toISOString(),
      notes: payload.notes ?? null,
      updated_at: new Date().toISOString(),
    }).eq('id', payload.id).select('*')
    if (error) throw error
    return (data ?? []) as RetentionPolicy[]
  },

  async createDeletionRequest(payload: { subject_type: string; subject_id: string; request_type: string; reason: string; requested_by?: string | null }) {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { data, error } = await supabase.rpc('request_data_deletion', {
      p_subject_type: payload.subject_type,
      p_subject_id: payload.subject_id,
      p_request_type: payload.request_type,
      p_reason: payload.reason,
      p_requested_by: payload.requested_by ?? null,
    })
    if (error) throw error
    return data
  },

  async processDeletionRequest(payload: { request_id: string; status: string; actor_user_id?: string | null; reason?: string | null; action?: string | null }) {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { data, error } = await supabase.rpc('process_deletion_request', {
      p_request_id: payload.request_id,
      p_status: payload.status,
      p_actor_user_id: payload.actor_user_id ?? null,
      p_reason: payload.reason ?? null,
      p_action: payload.action ?? null,
    })
    if (error) throw error
    return data
  },

  async loadSuppressionStatus(subjectType: string, subjectId: string) {
    if (!supabase) throw new Error('Supabase is not configured.')
    const { data, error } = await supabase.rpc('load_suppression_status', {
      p_subject_type: subjectType,
      p_subject_id: subjectId,
    })
    if (error) throw error
    return data ?? []
  },
}
