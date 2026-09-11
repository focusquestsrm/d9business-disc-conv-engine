import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'
import { parseSync, loadModule } from 'pgsql-parser'
import {
  REGISTRATION_LIFECYCLE_STAGES,
  canAdvanceRegistrationStage,
  evaluateRegistrationInvitationEligibility,
  normalizeEmail,
  normalizePhone,
  normalizeSourceHandle,
  buildRegistrationJourneyEvent,
} from './registrationHandoff'
import { registrationHandoffRepository } from './registrationHandoffRepository'

const REQUIRED_MIGRATION_RPC_SIGNATURES = [
  'public.evaluate_registration_invitation_eligibility(uuid,uuid,text,boolean,boolean,boolean,boolean,boolean,boolean,text)',
  'public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)',
  'public.approve_registration_invitation(uuid,uuid,text,boolean,boolean)',
  'public.record_registration_invitation_sent(uuid,uuid,text)',
  'public.start_registration_handoff(uuid,uuid,uuid,text,text,text,text,text,jsonb)',
  'public.link_prospect_to_member_profile(uuid,uuid,text,text,text,text,numeric,text,text,text)',
  'public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)',
  'public.record_registration_journey_event(uuid,uuid,text,text,uuid,uuid,uuid,uuid,text,text,text,jsonb)',
  'public.advance_registration_stage(uuid,uuid,text,text,text,uuid,uuid,text)',
  'public.ingest_brilliant_directories_sync_event(uuid,uuid,text,uuid,uuid,text,text,jsonb,text)',
  'public.get_registration_journey(uuid,uuid,integer)',
  'public.get_registration_review_queue(uuid,text)',
] as const

const REQUIRED_VERIFIER_RPC_SIGNATURES = [
  'public.evaluate_registration_invitation_eligibility(uuid,uuid,text,boolean,boolean,boolean,boolean,boolean,boolean,text)',
  'public.create_registration_invitation(uuid,uuid,text,text,boolean,boolean,boolean,boolean,boolean,jsonb,uuid,text,text,uuid,text,timestamptz,boolean,jsonb)',
  'public.approve_registration_invitation(uuid,uuid,text,boolean,boolean)',
  'public.record_registration_invitation_sent(uuid,uuid,text)',
  'public.start_registration_handoff(uuid,uuid,uuid,text,text,text,text,text,jsonb)',
  'public.link_prospect_to_member_profile(uuid,uuid,text,text,text,text,numeric,text,text,text)',
  'public.find_registration_duplicate_candidates(uuid,uuid,text,text,text,text,text)',
  'public.record_registration_journey_event(uuid,uuid,text,text,uuid,uuid,uuid,uuid,text,text,text,jsonb)',
  'public.advance_registration_stage(uuid,uuid,text,text,text,uuid,uuid,text)',
  'public.ingest_brilliant_directories_sync_event(uuid,uuid,text,uuid,uuid,text,text,jsonb,text)',
  'public.get_registration_journey(uuid,uuid,integer)',
  'public.get_registration_review_queue(uuid,text)',
] as const

const REQUIRED_BEHAVIORAL_VERIFIER_CHECKS = [
  'invitation_status_constraint',
  'required_stage_invitation_sent',
  'required_stage_registration_started',
  'required_stage_profile_created',
  'required_stage_profile_claimed',
  'required_stage_profile_completed',
  'required_stage_verification_pending',
  'required_stage_verified',
  'valid_transition_enforcement',
  'journey_append_only_update_protection',
  'journey_append_only_delete_protection',
  'release_3b_consent_dependency',
  'release_3b_opt_out_dependency',
  'release_3c_engagement_thread_message_linkage',
  'release_3d_approval_outreach_linkage',
  'invitation_single_use_enforcement',
  'invitation_token_uniqueness',
  'provider_sync_event_idempotency',
  'external_provider_member_uniqueness',
  'ambiguous_match_review_support',
  'deterministic_duplicate_match_support',
  'human_approval_before_invitation_sent',
  'consent_and_opt_out_enforcement_before_invitation_sent',
  'provider_neutral_disconnected_brilliant_directories_state',
] as const

const splitTopLevel = (value: string) => {
  const parts: string[] = []
  let current = ''
  let depth = 0
  let inSingleQuote = false
  let inDoubleQuote = false

  for (let i = 0; i < value.length; i += 1) {
    const char = value[i]

    if (char === "'" && !inDoubleQuote) {
      inSingleQuote = !inSingleQuote
      current += char
      continue
    }

    if (char === '"' && !inSingleQuote) {
      inDoubleQuote = !inDoubleQuote
      current += char
      continue
    }

    if (!inSingleQuote && !inDoubleQuote) {
      if (char === '(') depth += 1
      if (char === ')') depth -= 1
      if (char === ',' && depth === 0) {
        parts.push(current.trim())
        current = ''
        continue
      }
    }

    current += char
  }

  if (current.trim()) {
    parts.push(current.trim())
  }

  return parts.filter(Boolean)
}

const normalizeSqlSignature = (sql: string) =>
  sql
    .replace(/\r/g, '')
    .replace(/\s+/g, ' ')
    .replace(/\s*,\s*/g, ',')
    .replace(/\s*\(\s*/g, '(')
    .replace(/\s*\)\s*/g, ')')
    .replace(/\s*;\s*$/g, '')

const extractArgumentList = (sql: string, functionName: string) => {
  const functionStart = sql.indexOf(functionName)
  if (functionStart === -1) return null

  let openIndex = sql.indexOf('(', functionStart)
  if (openIndex === -1) return null

  let depth = 0
  let inSingleQuote = false
  let inDoubleQuote = false

  for (let i = openIndex; i < sql.length; i += 1) {
    const char = sql[i]

    if (char === "'" && !inDoubleQuote) {
      inSingleQuote = !inSingleQuote
      continue
    }

    if (char === '"' && !inSingleQuote) {
      inDoubleQuote = !inDoubleQuote
      continue
    }

    if (!inSingleQuote && !inDoubleQuote) {
      if (char === '(') depth += 1
      if (char === ')') {
        depth -= 1
        if (depth === 0) {
          const argText = sql.slice(openIndex + 1, i)
          return argText
        }
      }
    }
  }

  return null
}

const extractFunctionSignature = (sql: string, functionName: string) => {
  const canonical = [...REQUIRED_MIGRATION_RPC_SIGNATURES, ...REQUIRED_VERIFIER_RPC_SIGNATURES].find((signature) =>
    signature.startsWith(`${functionName}(`),
  )

  if (canonical) {
    const normalizedSql = normalizeSqlSignature(sql)
    const normalizedCanonical = normalizeSqlSignature(canonical)

    if (normalizedSql.includes(normalizedCanonical)) {
      return canonical
    }
  }

  const argText = extractArgumentList(sql, functionName)
  if (!argText) return null

  const types = splitTopLevel(argText).map((part) => {
    const trimmed = part.trim()
    const withoutName = trimmed.replace(/^[A-Za-z_][A-Za-z0-9_]*\s+/, '')
    const withoutDefault = withoutName.replace(/\s+DEFAULT\s+.*$/i, '').trim()
    return withoutDefault.replace(/\s*::\s*[^\s]+$/i, '').replace(/\s*\([^)]*\)/g, '').replace(/\s+/g, '')
  })

  return `${functionName}(${types.join(',')})`
}

describe('registration profile handoff', () => {
  it('tracks all seven lifecycle stages and valid/invalid transitions', () => {
    expect(REGISTRATION_LIFECYCLE_STAGES).toEqual([
      'invitation_sent',
      'registration_started',
      'profile_created',
      'profile_claimed',
      'profile_completed',
      'verification_pending',
      'verified',
    ])

    expect(canAdvanceRegistrationStage(null, 'invitation_sent')).toBe(true)
    expect(canAdvanceRegistrationStage('invitation_sent', 'registration_started')).toBe(true)
    expect(canAdvanceRegistrationStage('registration_started', 'profile_created')).toBe(true)
    expect(canAdvanceRegistrationStage('profile_created', 'profile_claimed')).toBe(true)
    expect(canAdvanceRegistrationStage('profile_claimed', 'profile_completed')).toBe(true)
    expect(canAdvanceRegistrationStage('profile_completed', 'verified')).toBe(true)
    expect(canAdvanceRegistrationStage('verified', 'profile_completed')).toBe(false)
    expect(canAdvanceRegistrationStage('profile_created', 'profile_completed')).toBe(false)
    expect(canAdvanceRegistrationStage('profile_completed', 'profile_claimed')).toBe(false)
  })

  it('requires approval, consent, opt-out, expiry, revocation, and frequency gates', () => {
    const eligible = evaluateRegistrationInvitationEligibility({
      channel: 'email',
      consentAllowed: true,
      optOutActive: false,
      frequencyOk: true,
      humanApprovalGranted: true,
      isExpired: false,
      isRevoked: false,
    })
    expect(eligible.allowed).toBe(true)
    expect(eligible.code).toBe('eligible')

    expect(evaluateRegistrationInvitationEligibility({ channel: 'email', consentAllowed: false, optOutActive: false, frequencyOk: true, humanApprovalGranted: true, isExpired: false, isRevoked: false }).code).toBe('consent_missing')
    expect(evaluateRegistrationInvitationEligibility({ channel: 'email', consentAllowed: true, optOutActive: true, frequencyOk: true, humanApprovalGranted: true, isExpired: false, isRevoked: false }).code).toBe('opt_out_active')
    expect(evaluateRegistrationInvitationEligibility({ channel: 'email', consentAllowed: true, optOutActive: false, frequencyOk: true, humanApprovalGranted: false, isExpired: false, isRevoked: false }).code).toBe('human_approval_required')
    expect(evaluateRegistrationInvitationEligibility({ channel: 'email', consentAllowed: true, optOutActive: false, frequencyOk: false, frequencyReason: 'Cooldown active for this channel.', humanApprovalGranted: true, isExpired: false, isRevoked: false }).code).toBe('frequency_limit_reached')
    expect(evaluateRegistrationInvitationEligibility({ channel: 'email', consentAllowed: true, optOutActive: false, frequencyOk: true, humanApprovalGranted: true, isExpired: true, isRevoked: false }).code).toBe('invitation_expired')
    expect(evaluateRegistrationInvitationEligibility({ channel: 'email', consentAllowed: true, optOutActive: false, frequencyOk: true, humanApprovalGranted: true, isExpired: false, isRevoked: true }).code).toBe('invitation_revoked')
  })

  it('normalizes identifiers and prevents duplicate identity collisions', () => {
    expect(normalizeEmail('  User.Name+Tag@Example.com  ')).toBe('username@example.com')
    expect(normalizePhone('+1 (555) 123-4567')).toBe('15551234567')
    expect(normalizeSourceHandle('  @DemoCreator  ')).toBe('democreator')

    const candidate = buildRegistrationJourneyEvent({
      stage: 'profile_created',
      previousStage: 'registration_started',
      newStage: 'profile_created',
      source: 'brilliant_directories',
    })

    expect(candidate.stage).toBe('profile_created')
    expect(candidate.previousStage).toBe('registration_started')
    expect(candidate.newStage).toBe('profile_created')

    const duplicateEmailA = normalizeEmail('  user.name+foo@example.com  ')
    const duplicateEmailB = normalizeEmail('user.name@example.com')
    expect(duplicateEmailA).toBe(duplicateEmailB)
  })

  it('maps the repository RPC contract for the full 3E API and payload keys', async () => {
    expect(Object.keys(registrationHandoffRepository)).toEqual(expect.arrayContaining([
      'evaluateInvitationEligibility',
      'createInvitation',
      'approveInvitation',
      'recordInvitationSent',
      'startHandoff',
      'linkProfile',
      'findDuplicateCandidates',
      'recordJourneyEvent',
      'advanceStage',
      'ingestProviderSyncEvent',
      'getJourney',
      'getReviewQueue',
    ]))

    await expect(registrationHandoffRepository.evaluateInvitationEligibility({
      p_tenant_id: 'tenant-1',
      p_prospect_id: 'prospect-1',
      p_channel: 'email',
      p_consent_allowed: true,
      p_opt_out_active: false,
      p_frequency_ok: true,
      p_human_approval_granted: true,
    })).resolves.toHaveProperty('payload')

    await expect(registrationHandoffRepository.recordInvitationSent({
      p_invitation_id: 'invite-1',
      p_sent_by: 'operator-1',
      p_channel: 'email',
    })).resolves.toHaveProperty('payload')
  })

  it('enforces direct database guardrails for invitation approval and append-only journey history', async () => {
    const migrationSql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20260911_000001_milestone_3e_registration_profile_handoff.sql'), 'utf8')
    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_milestone_3e_registration_profile_handoff.sql'), 'utf8')

    expect(migrationSql).toContain('CREATE OR REPLACE FUNCTION public.require_registration_invitation_approval')
    expect(migrationSql).toContain("NEW.status = 'sent'")
    expect(migrationSql).toContain('NEW.human_approval_granted IS NOT TRUE')
    expect(migrationSql).toContain('BEFORE INSERT OR UPDATE ON public.registration_invitations')
    expect(migrationSql).toContain('CREATE TRIGGER registration_invitations_approval_gate')

    expect(migrationSql).toContain('CREATE OR REPLACE FUNCTION public.prevent_registration_journey_append_mutation')
    expect(migrationSql).toContain("IF TG_OP IN ('UPDATE', 'DELETE')")
    expect(migrationSql).toContain('BEFORE UPDATE OR DELETE ON public.registration_journey_events')
    expect(migrationSql).toContain('CREATE TRIGGER registration_journey_events_append_only')

    expect(verifierSql).toContain('NOT t.tgisinternal')
    expect(verifierSql).toContain('tgtype & 1')
    expect(verifierSql).toContain('tgtype & 2')
    expect(verifierSql).toContain('tgtype & 4')
    expect(verifierSql).toContain('tgtype & 8')
    expect(verifierSql).toContain('tgtype & 16')
    expect(verifierSql).toContain('pg_get_functiondef')
    expect(verifierSql).toMatch(/journey_append_only_update_protection[\s\S]*tgrelid\s*=\s*'public\.registration_journey_events'::regclass[\s\S]*\(\(t\.tgtype & 1\) <> 0\)[\s\S]*\(\(t\.tgtype & 2\) <> 0\)[\s\S]*\(\(t\.tgtype & 16\) <> 0\)/)
    expect(verifierSql).toMatch(/journey_append_only_delete_protection[\s\S]*tgrelid\s*=\s*'public\.registration_journey_events'::regclass[\s\S]*\(\(t\.tgtype & 1\) <> 0\)[\s\S]*\(\(t\.tgtype & 2\) <> 0\)[\s\S]*\(\(t\.tgtype & 8\) <> 0\)/)
    expect(verifierSql).toMatch(/human_approval_before_invitation_sent[\s\S]*tgrelid\s*=\s*'public\.registration_invitations'::regclass[\s\S]*\(\(t\.tgtype & 1\) <> 0\)[\s\S]*\(\(t\.tgtype & 2\) <> 0\)[\s\S]*\(\(t\.tgtype & 4\) <> 0\)[\s\S]*\(\(t\.tgtype & 16\) <> 0\)/)
    expect(verifierSql).toContain("human_approval_granted is not true")
    expect(verifierSql).toContain('approved_by is null')
    expect(verifierSql).toContain('approved_at is null')
    expect(verifierSql).toContain('consent_allowed is not true')
    expect(verifierSql).toContain('opt_out_active is true')
    expect(verifierSql).toContain('frequency_ok is not true')
  })

  it('keeps the migration and verifier aligned to the exact canonical 3E RPC signatures', async () => {
    await loadModule()
    const migrationSql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20260911_000001_milestone_3e_registration_profile_handoff.sql'), 'utf8')
    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_milestone_3e_registration_profile_handoff.sql'), 'utf8')

    for (const signature of REQUIRED_MIGRATION_RPC_SIGNATURES) {
      const functionName = signature.slice(0, signature.indexOf('('))
      const migrationSignature = extractFunctionSignature(migrationSql, functionName)

      expect(migrationSignature).not.toBeNull()
      expect(normalizeSqlSignature(migrationSignature ?? '')).toContain(normalizeSqlSignature(signature))
    }

    for (const signature of REQUIRED_VERIFIER_RPC_SIGNATURES) {
      const functionName = signature.slice(0, signature.indexOf('('))
      const verifierSignature = extractFunctionSignature(verifierSql, functionName)

      expect(verifierSignature).not.toBeNull()
      expect(normalizeSqlSignature(verifierSignature ?? '')).toContain(normalizeSqlSignature(signature))
    }

    for (const behaviorCheck of REQUIRED_BEHAVIORAL_VERIFIER_CHECKS) {
      expect(verifierSql).toContain(`'${behaviorCheck}'`)
      expect(verifierSql).toContain(`'${behaviorCheck}',`)
    }

    expect((verifierSql.match(/overall_status/g) ?? []).length).toBe(1)
    expect((verifierSql.match(/COUNT\(\*\) FILTER \(WHERE status = 'PASS'\)/g) ?? []).length).toBe(1)
    expect(verifierSql).toContain('UNION ALL')
    expect(verifierSql).toContain('ORDER BY CASE WHEN category = \'OVERALL\' THEN 1 ELSE 0 END, object_name, check_name')
    expect(verifierSql).not.toContain('pg_policies.cmdname')
    expect(verifierSql).not.toContain('WITH CHECK')
    expect(() => parseSync(migrationSql)).not.toThrow()
    expect(() => parseSync(verifierSql)).not.toThrow()
    console.log('MIGRATION_3E_PARSE_OK')
    console.log('VERIFIER_3E_PARSE_OK')
  })
})
