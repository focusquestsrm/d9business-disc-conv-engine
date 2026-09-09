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

describe('registration profile handoff', () => {
  it('tracks the required lifecycle stages and valid transitions', () => {
    expect(REGISTRATION_LIFECYCLE_STAGES).toEqual(expect.arrayContaining([
      'invitation_sent',
      'registration_started',
      'profile_created',
      'profile_claimed',
      'profile_completed',
      'verification_pending',
      'verified',
    ]))

    expect(canAdvanceRegistrationStage('invitation_sent', 'registration_started')).toBe(true)
    expect(canAdvanceRegistrationStage('profile_completed', 'verified')).toBe(true)
    expect(canAdvanceRegistrationStage('verified', 'profile_completed')).toBe(false)
    expect(canAdvanceRegistrationStage('profile_created', 'profile_completed')).toBe(false)
  })

  it('requires consent, opt-out, human approval, and frequency checks', () => {
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

    const consentBlocked = evaluateRegistrationInvitationEligibility({
      channel: 'email',
      consentAllowed: false,
      optOutActive: false,
      frequencyOk: true,
      humanApprovalGranted: true,
      isExpired: false,
      isRevoked: false,
    })
    expect(consentBlocked.code).toBe('consent_missing')

    const optOutBlocked = evaluateRegistrationInvitationEligibility({
      channel: 'email',
      consentAllowed: true,
      optOutActive: true,
      frequencyOk: true,
      humanApprovalGranted: true,
      isExpired: false,
      isRevoked: false,
    })
    expect(optOutBlocked.code).toBe('opt_out_active')

    const humanApprovalBlocked = evaluateRegistrationInvitationEligibility({
      channel: 'email',
      consentAllowed: true,
      optOutActive: false,
      frequencyOk: true,
      humanApprovalGranted: false,
      isExpired: false,
      isRevoked: false,
    })
    expect(humanApprovalBlocked.code).toBe('human_approval_required')

    const frequencyBlocked = evaluateRegistrationInvitationEligibility({
      channel: 'email',
      consentAllowed: true,
      optOutActive: false,
      frequencyOk: false,
      frequencyReason: 'Cooldown active for this channel.',
      humanApprovalGranted: true,
      isExpired: false,
      isRevoked: false,
    })
    expect(frequencyBlocked.code).toBe('frequency_limit_reached')
  })

  it('normalizes identifiers and keeps duplicate detection deterministic', () => {
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
  })

  it('maps repository methods to the expected 3E RPC names and payload keys', async () => {
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
  })

  it('parses the 3E migration and verifier SQL without syntax issues', async () => {
    await loadModule()
    const migrationSql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20260911_000001_milestone_3e_registration_profile_handoff.sql'), 'utf8')
    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_milestone_3e_registration_profile_handoff.sql'), 'utf8')

    expect(() => parseSync(migrationSql)).not.toThrow()
    expect(() => parseSync(verifierSql)).not.toThrow()
    console.log('MIGRATION_3E_PARSE_OK')
    console.log('VERIFIER_3E_PARSE_OK')
  })
})
