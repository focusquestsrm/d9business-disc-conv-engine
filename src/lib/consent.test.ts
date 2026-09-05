import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { parseSync, loadModule } from 'pgsql-parser'
import { createRetentionDispositionEligible, evaluateOutreachEligibility, evaluateVerificationSharingEligibility, normalizeConsentChannel, normalizeConsentStatus, type ConsentPreference } from './consent'

describe('consent governance', () => {
  it('restricts channel and status values', () => {
    expect(normalizeConsentChannel('email')).toBe('email')
    expect(normalizeConsentChannel('fax')).toBeNull()
    expect(normalizeConsentStatus('granted')).toBe('granted')
    expect(normalizeConsentStatus('banned')).toBeNull()
  })

  it('denies missing and withdrawn consent by default', () => {
    expect(evaluateOutreachEligibility({ channel: 'email', purpose: 'general_communication', consentPreferences: [] }).allowed).toBe(false)
    expect(evaluateOutreachEligibility({
      channel: 'text',
      purpose: 'general_communication',
      consentPreferences: [{ subject_type: 'prospect', subject_id: '11111111-1111-4111-8111-111111111111', channel: 'text', purpose: 'general_communication', status: 'withdrawn' }],
    }).allowed).toBe(false)
  })

  it('allows valid active channel consent and blocks mismatched channel usage', () => {
    const allowed = evaluateOutreachEligibility({
      channel: 'email',
      purpose: 'general_communication',
      consentPreferences: [{ subject_type: 'prospect', subject_id: '11111111-1111-4111-8111-111111111111', channel: 'email', purpose: 'general_communication', status: 'granted', effective_at: new Date().toISOString() }],
    })
    expect(allowed.allowed).toBe(true)

    const notAllowed = evaluateOutreachEligibility({
      channel: 'text',
      purpose: 'general_communication',
      consentPreferences: [{ subject_type: 'prospect', subject_id: '11111111-1111-4111-8111-111111111111', channel: 'email', purpose: 'general_communication', status: 'granted', effective_at: new Date().toISOString() }],
    })
    expect(notAllowed.allowed).toBe(false)
  })

  it('applies global and channel suppression precedence', () => {
    const globalSuppressed = evaluateOutreachEligibility({
      channel: 'phone',
      purpose: 'general_communication',
      consentPreferences: [{ subject_type: 'prospect', subject_id: '11111111-1111-4111-8111-111111111111', channel: 'phone', purpose: 'general_communication', status: 'granted', effective_at: new Date().toISOString() }],
      suppressions: [{ kind: 'global', active: true }],
    })
    expect(globalSuppressed.allowed).toBe(false)

    const channelSuppressed = evaluateOutreachEligibility({
      channel: 'phone',
      purpose: 'general_communication',
      consentPreferences: [{ subject_type: 'prospect', subject_id: '11111111-1111-4111-8111-111111111111', channel: 'phone', purpose: 'general_communication', status: 'granted', effective_at: new Date().toISOString() }],
      suppressions: [{ kind: 'channel', channel: 'phone', active: true }],
    })
    expect(channelSuppressed.allowed).toBe(false)
  })

  it('keeps verification-sharing separate from general communication consent', () => {
    const generalConsent: ConsentPreference[] = [{ subject_type: 'prospect', subject_id: '11111111-1111-4111-8111-111111111111', channel: 'email', purpose: 'general_communication', status: 'granted', effective_at: new Date().toISOString() }]
    const shareAllowed = evaluateVerificationSharingEligibility({
      generalConsent,
      organizationConsent: [{ subject_id: '11111111-1111-4111-8111-111111111111', selected_organization: 'Alpha Phi Alpha', status: 'granted', effective_at: new Date().toISOString() }],
      selectedOrganization: 'Alpha Phi Alpha',
      channel: 'email',
      purpose: 'general_communication',
    })
    expect(shareAllowed.allowed).toBe(true)

    const wrongOrg = evaluateVerificationSharingEligibility({
      generalConsent,
      organizationConsent: [{ subject_id: '11111111-1111-4111-8111-111111111111', selected_organization: 'Kappa Alpha Psi', status: 'granted', effective_at: new Date().toISOString() }],
      selectedOrganization: 'Alpha Phi Alpha',
      channel: 'email',
      purpose: 'general_communication',
    })
    expect(wrongOrg.allowed).toBe(false)
  })

  it('calculates retention eligibility and respects deletion holds', () => {
    const eligible = createRetentionDispositionEligible({ retention_days: 30, enabled: true }, new Date(Date.now() - 40 * 86400000).toISOString())
    expect(eligible).toBe(true)
    expect(createRetentionDispositionEligible({ retention_days: 30, enabled: false }, new Date().toISOString())).toBe(false)
  })

  it('prevents volatile time predicates in index definitions and checks expiration dynamically', () => {
    const migrationSql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20260906_000001_milestone_3b_consent_preferences.sql'), 'utf8')
    const indexSql = (migrationSql.match(/CREATE\s+(?:UNIQUE\s+)?INDEX[\s\S]*?;/gi) ?? []).join('\n')

    expect(indexSql).toContain("CREATE UNIQUE INDEX IF NOT EXISTS ux_consent_preferences_active")
    expect(indexSql).toContain("WHERE status = 'granted'")
    expect(indexSql).toContain("AND withdrawn_at IS NULL")
    expect(indexSql).not.toMatch(/WHERE[\s\S]*?(?:now\(\)|CURRENT_TIMESTAMP|transaction_timestamp\(\)|statement_timestamp\(\)|clock_timestamp\()/i)
    expect(indexSql).not.toMatch(/WHERE[\s\S]*?(?:expires_at\s*>\s*now\(|withdrawn_at\s*>\s*now\()/i)

    const expired = evaluateOutreachEligibility({
      channel: 'email',
      purpose: 'general_communication',
      consentPreferences: [{
        subject_type: 'prospect',
        subject_id: '11111111-1111-4111-8111-111111111111',
        channel: 'email',
        purpose: 'general_communication',
        status: 'granted',
        effective_at: new Date(Date.now() - 2 * 86400000).toISOString(),
        expires_at: new Date(Date.now() - 60 * 60 * 1000).toISOString(),
      }],
    })

    expect(expired.allowed).toBe(false)
    expect(expired.reason).toMatch(/expired|not currently active/i)
  })

  it('verifies command-specific policy clauses for every Release 3B policy block', () => {
    const migrationSql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20260906_000001_milestone_3b_consent_preferences.sql'), 'utf8')
    const policyBlocks = [...migrationSql.matchAll(/CREATE POLICY[\s\S]*?;/g)].map(match => match[0])

    const selectOptOutPolicy = policyBlocks.find(block =>
      block.includes('"Authenticated users can read active opt-out suppression evidence"') &&
      block.includes('ON public.opt_outs') &&
      block.includes('FOR SELECT') &&
      block.includes('USING (auth.uid() IS NOT NULL)') &&
      !block.includes('WITH CHECK')
    )
    const insertOptOutPolicy = policyBlocks.find(block =>
      block.includes('"Authenticated users can manage opt_outs"') &&
      block.includes('ON public.opt_outs') &&
      block.includes('FOR INSERT') &&
      block.includes('WITH CHECK (auth.uid() IS NOT NULL)') &&
      !block.includes('USING')
    )
    const updateOptOutPolicy = policyBlocks.find(block =>
      block.includes('"Authenticated users can update opt_outs"') &&
      block.includes('ON public.opt_outs') &&
      block.includes('FOR UPDATE') &&
      block.includes('USING (auth.uid() IS NOT NULL)') &&
      block.includes('WITH CHECK (auth.uid() IS NOT NULL)')
    )
    const selectHistoryPolicy = policyBlocks.find(block =>
      block.includes('"Authorized users can read consent history"') &&
      block.includes('ON public.consent_history') &&
      block.includes('FOR SELECT') &&
      block.includes('USING (auth.uid() IS NOT NULL') &&
      !block.includes('WITH CHECK')
    )

    expect(selectOptOutPolicy).toBeTruthy()
    expect(insertOptOutPolicy).toBeTruthy()
    expect(updateOptOutPolicy).toBeTruthy()
    expect(selectHistoryPolicy).toBeTruthy()
    expect(policyBlocks.some(block => block.includes('ON public.consent_preferences') && block.includes('FOR ALL'))).toBe(true)
    expect(policyBlocks.some(block => block.includes('ON public.verification_sharing_consents') && block.includes('FOR ALL'))).toBe(true)
    expect(policyBlocks.some(block => block.includes('ON public.retention_policies') && block.includes('FOR ALL'))).toBe(true)
    expect(policyBlocks.some(block => block.includes('ON public.deletion_requests') && block.includes('FOR ALL'))).toBe(true)
    expect(policyBlocks.some(block => block.includes('ON public.consent_history') && block.includes('FOR SELECT'))).toBe(true)
    expect(policyBlocks.some(block => block.includes('ON public.opt_outs') && block.includes('FOR INSERT'))).toBe(true)
    expect(policyBlocks.some(block => block.includes('ON public.opt_outs') && block.includes('FOR UPDATE'))).toBe(true)
    expect(migrationSql).toContain('DROP POLICY IF EXISTS "Authenticated users can read active opt-out suppression evidence" ON public.opt_outs;')
    expect(migrationSql).toContain('DROP TRIGGER IF EXISTS consent_history_block_update ON public.consent_history;')
    expect(migrationSql).toContain('DROP POLICY IF EXISTS "Authenticated users can manage opt_outs" ON public.opt_outs;')
    expect(migrationSql).toContain('ALTER TABLE public.consent_preferences ENABLE ROW LEVEL SECURITY;')
    expect(migrationSql).toContain('ALTER TABLE public.retention_policies ENABLE ROW LEVEL SECURITY;')
  })

  it('requires correct PostgreSQL catalog columns for policy checks', () => {
    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_milestone_3b_consent_preferences.sql'), 'utf8')

    expect(verifierSql).not.toMatch(/cmdname/i)
    expect(verifierSql).toMatch(/FROM\s+pg_policies\s+WHERE\s+schemaname\s*=\s*'public'\s+AND\s+tablename\s*=\s*'consent_history'\s+AND\s+cmd\s*=\s*'SELECT'/i)
    expect(verifierSql).toMatch(/FROM\s+pg_policies\s+WHERE\s+schemaname\s*=\s*'public'\s+AND\s+tablename\s*=\s*'opt_outs'\s+AND\s+cmd\s*=\s*'INSERT'/i)
    expect(verifierSql).toMatch(/FROM\s+pg_policies\s+WHERE\s+schemaname\s*=\s*'public'\s+AND\s+tablename\s*=\s*'opt_outs'\s+AND\s+cmd\s*=\s*'UPDATE'/i)
  })

  it('parses the release 3B migration and verifier SQL without syntax issues', async () => {
    const migrationSql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20260906_000001_milestone_3b_consent_preferences.sql'), 'utf8')
    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_milestone_3b_consent_preferences.sql'), 'utf8')

    await loadModule()
    expect(() => parseSync(migrationSql)).not.toThrow()
    expect(() => parseSync(verifierSql)).not.toThrow()
    console.log('MIGRATION_3B_PARSE_OK')
    console.log('VERIFIER_3B_PARSE_OK')
  })
})
