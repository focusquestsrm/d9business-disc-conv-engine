import { supabase } from './supabaseClient'

export type VerificationCaseRecord = {
  id: string
  case_id: string
  batch_id?: string | null
  source_record_id?: string | null
  claimant_name: string
  legal_first_name?: string | null
  legal_last_name?: string | null
  email?: string | null
  phone?: string | null
  claimed_organization?: string | null
  chapter_name?: string | null
  chapter_city?: string | null
  chapter_state?: string | null
  consent_acknowledged?: boolean
  consent_date?: string | null
  status: string
  result: string
  confidence_score?: number | null
  verification_reason?: string | null
  verified_by?: string | null
  verified_at?: string | null
  created_by?: string | null
  created_at?: string
  updated_at?: string
}

export type VerificationBatchRecord = {
  id: string
  batch_code: string
  organization: string
  status: string
  submission_window_start?: string | null
  submission_window_end?: string | null
  notes?: string | null
  created_by?: string | null
  created_at?: string
  updated_at?: string
}

const client = supabase

export const verificationRepository = {
  async assignReviewer(caseId: string, reviewerUserId: string, reason?: string | null) {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.rpc('assign_verification_reviewer', {
      p_case_id: caseId,
      p_reviewer_user_id: reviewerUserId,
      p_reason: reason ?? null,
    })
    if (error) throw error
    return data
  },

  async transitionCaseStatus(caseId: string, newStatus: string, reason?: string | null, result?: string | null) {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.rpc('transition_verification_case_status', {
      p_case_id: caseId,
      p_new_status: newStatus,
      p_reason: reason ?? null,
      p_result: result ?? null,
    })
    if (error) throw error
    return data
  },

  async markBatchExported(batchId: string, exportedBy?: string | null, notes?: string | null) {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.rpc('mark_verification_batch_exported', {
      p_batch_id: batchId,
      p_exported_by: exportedBy ?? null,
      p_notes: notes ?? null,
    })
    if (error) throw error
    return data
  },

  async markBatchSent(batchId: string, sentBy?: string | null, notes?: string | null) {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.rpc('mark_verification_batch_sent', {
      p_batch_id: batchId,
      p_sent_by: sentBy ?? null,
      p_notes: notes ?? null,
    })
    if (error) throw error
    return data
  },

  async recordResponseReceived(caseId: string, organizationName: string, result: string, reason?: string | null, notes?: string | null, verificationDate?: string | null) {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.rpc('record_verification_response_received', {
      p_case_id: caseId,
      p_organization_name: organizationName,
      p_result: result,
      p_reason: reason ?? null,
      p_notes: notes ?? null,
      p_verification_date: verificationDate ?? new Date().toISOString(),
    })
    if (error) throw error
    return data
  },

  async closeBatch(batchId: string, reason?: string | null) {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.rpc('close_verification_batch', {
      p_batch_id: batchId,
      p_reason: reason ?? null,
    })
    if (error) throw error
    return data
  },

  async cancelBatch(batchId: string, reason: string) {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.rpc('cancel_verification_batch', {
      p_batch_id: batchId,
      p_reason: reason,
    })
    if (error) throw error
    return data
  },

  async saveManualResult(caseId: string, result: string, reason?: string | null, notes?: string | null, verifiedBy?: string | null) {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.rpc('save_manual_verification_result', {
      p_case_id: caseId,
      p_result: result,
      p_reason: reason ?? null,
      p_notes: notes ?? null,
      p_verified_by: verifiedBy ?? null,
    })
    if (error) throw error
    return data
  },

  async loadCaseHistory(caseId: string) {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.rpc('get_verification_case_history', { p_case_id: caseId })
    if (error) throw error
    return data ?? []
  },

  async listCases() {
    if (!client) {
      throw new Error('Supabase is not configured.')
    }

    const { data, error } = await client.from('verification_cases').select('*').order('created_at', { ascending: false })
    if (error) throw error
    return (data ?? []) as VerificationCaseRecord[]
  },

  async getCase(caseId: string) {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.from('verification_cases').select('*').eq('case_id', caseId).maybeSingle()
    if (error) throw error
    return data as VerificationCaseRecord | null
  },

  async createCase(payload: Partial<VerificationCaseRecord>) {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.from('verification_cases').insert(payload).select('*').single()
    if (error) throw error
    return data as VerificationCaseRecord
  },

  async updateCase(caseId: string, updates: Partial<VerificationCaseRecord>) {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.from('verification_cases').update(updates).eq('case_id', caseId).select('*').single()
    if (error) throw error
    return data as VerificationCaseRecord
  },

  async listBatches() {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.from('verification_batches').select('*').order('created_at', { ascending: false })
    if (error) throw error
    return (data ?? []) as VerificationBatchRecord[]
  },

  async createBatch(payload: Partial<VerificationBatchRecord> & { batch_code: string; organization: string }) {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.from('verification_batches').insert(payload).select('*').single()
    if (error) throw error
    return data as VerificationBatchRecord
  },

  async updateBatch(batchId: string, updates: Partial<VerificationBatchRecord>) {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.from('verification_batches').update(updates).eq('id', batchId).select('*').single()
    if (error) throw error
    return data as VerificationBatchRecord
  },

  async addBatchItems(batchId: string, caseIds: string[]) {
    if (!client) throw new Error('Supabase is not configured.')
    const rows = caseIds.map((caseId) => ({ batch_id: batchId, case_id: caseId }))
    const { error } = await client.from('verification_batch_items').upsert(rows, { onConflict: 'batch_id,case_id' })
    if (error) throw error
    return rows.length
  },

  async removeBatchItems(batchId: string, caseIds: string[]) {
    if (!client) throw new Error('Supabase is not configured.')
    const { error } = await client.from('verification_batch_items').delete().eq('batch_id', batchId).in('case_id', caseIds)
    if (error) throw error
    return caseIds.length
  },

  async createImport(payload: Record<string, any>) {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.from('verification_imports').insert(payload).select('*').single()
    if (error) throw error
    return data
  },

  async saveImportRows(importId: string, rows: Array<Record<string, any>>) {
    if (!client) throw new Error('Supabase is not configured.')
    const prepared = rows.map((row) => ({ ...row, verification_import_id: importId }))
    const { error } = await client.from('verification_import_rows').upsert(prepared, { onConflict: 'verification_import_id,row_number' })
    if (error) throw error
    return prepared.length
  },

  async commitImport(importId: string, batchId: string, organization: string, rows: Array<Record<string, any>>) {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.rpc('commit_verification_import', {
      p_import_id: importId,
      p_batch_id: batchId,
      p_organization: organization,
      p_rows: rows,
    })
    if (error) throw error
    return data
  },

  async loadMetrics() {
    if (!client) throw new Error('Supabase is not configured.')
    const { data, error } = await client.from('verification_cases').select('status')
    if (error) throw error
    return {
      total: data?.length ?? 0,
      readyToBatch: (data ?? []).filter((row) => row.status === 'ready_for_batch').length,
      sentToOrganizations: (data ?? []).filter((row) => row.status === 'sent_to_organization').length,
      verified: (data ?? []).filter((row) => row.status === 'verified').length,
    }
  },
}
