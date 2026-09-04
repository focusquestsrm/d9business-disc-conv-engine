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
