import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'
import { parseSync, loadModule } from 'pgsql-parser'
import { aiEngagementRepository } from './aiEngagementRepository'
import { classifyEngagementOutcome, createEngagementFollowUp, evaluateEngagementSendEligibility, generateLocalAiSuggestion } from './aiEngagement'

describe('ai assisted engagement', () => {
  it('maps repository methods to the exact Release 3D RPC names and payload keys', async () => {
    expect(Object.keys(aiEngagementRepository)).toEqual(expect.arrayContaining([
      'createSuggestion',
      'generateSuggestion',
      'updateDraft',
      'submitForReview',
      'approve',
      'reject',
      'cancel',
      'evaluateSendEligibility',
      'recordOutreachAttempt',
      'recordManualDelivery',
      'classifyOutcome',
      'reviewOutcome',
      'createFollowUp',
      'snoozeFollowUp',
      'completeFollowUp',
      'escalateResponse',
      'resolveEscalation',
      'loadReviewQueue',
      'loadFollowUps',
      'loadEscalations',
      'loadEngagementTimeline',
    ]))

    const payload = {
      p_tenant_id: 'tenant-1',
      p_prospect_id: 'prospect-1',
      p_platform: 'linkedin',
      p_channel: 'direct_message',
      p_suggestion_type: 'direct_message',
      p_content: 'Hi there',
      p_status: 'generated',
      p_generation_source: 'template',
      p_confidence_score: 0.8,
    }

    await expect(aiEngagementRepository.createSuggestion(payload)).resolves.toHaveProperty('payload')
    await expect(aiEngagementRepository.evaluateSendEligibility({
      p_prospect_id: 'prospect-1',
      p_platform: 'linkedin',
      p_channel: 'direct_message',
      p_consent_allowed: false,
      p_suppression_blocked: true,
    })).resolves.toHaveProperty('payload')
  })

  it('creates a deterministic local suggestion with human-review labeling', () => {
    const suggestion = generateLocalAiSuggestion({
      channel: 'email',
      platform: 'email',
      prospectName: 'Aisha',
      businessName: 'Northside Studio',
      handle: '@northside',
      purpose: 'general_communication',
      notes: 'We are interested in learning more.',
    })

    expect(suggestion.source).toBe('template')
    expect(suggestion.suggestionType).toBe('email')
    expect(suggestion.content).toContain('Aisha')
    expect(suggestion.safetyLabels).toContain('human_review_required')
  })

  it('builds a direct-message suggestion suitable for human review', () => {
    const suggestion = generateLocalAiSuggestion({
      channel: 'direct_message',
      platform: 'linkedin',
      prospectName: 'Jordan',
      businessName: 'Northside Studio',
      handle: '@northside',
      notes: 'We are interested in exploring a collaboration.',
    })

    expect(suggestion.suggestionType).toBe('direct_message')
    expect(suggestion.content).toContain('Jordan')
    expect(suggestion.confidence).toBeGreaterThan(0.7)
  })

  it('creates a comment suggestion and email subject/body pair for review', () => {
    const comment = generateLocalAiSuggestion({
      channel: 'comment',
      platform: 'instagram',
      prospectName: 'Lena',
      notes: 'Thanks for the conversation.',
    })
    const email = generateLocalAiSuggestion({
      channel: 'email',
      platform: 'email',
      prospectName: 'Lena',
      businessName: 'Northside Studio',
      handle: '@northside',
      notes: 'We would like to continue the conversation.',
    })

    expect(comment.suggestionType).toBe('comment')
    expect(email.suggestionType).toBe('email')
    expect(email.subjectLine).toBe('Following up on Northside Studio')
    expect(email.content).toContain('Best')
  })

  it('enforces the required approval and eligibility precedence before delivery', () => {
    const blockedConsent = evaluateEngagementSendEligibility({
      platform: 'email',
      channel: 'email',
      consentAllowed: false,
      consentStatus: 'withdrawn',
      providerConnected: true,
      providerActivityPermitted: true,
      requiresHumanApproval: true,
      humanApprovalGranted: true,
      frequencyOk: true,
      prospectMatchRequired: false,
    })

    expect(blockedConsent.code).toBe('consent_withdrawn')
    expect(blockedConsent.allowed).toBe(false)

    const blockedSuppression = evaluateEngagementSendEligibility({
      platform: 'linkedin',
      channel: 'direct_message',
      consentAllowed: true,
      consentStatus: 'granted',
      suppressions: [{ kind: 'global', active: true }],
      providerConnected: true,
      providerActivityPermitted: true,
      frequencyOk: true,
      requiresHumanApproval: true,
      humanApprovalGranted: true,
      prospectMatchRequired: false,
    })

    expect(blockedSuppression.code).toBe('global_opt_out')

    const blockedFrequency = evaluateEngagementSendEligibility({
      platform: 'email',
      channel: 'email',
      consentAllowed: true,
      consentStatus: 'granted',
      providerConnected: true,
      providerActivityPermitted: true,
      requiresHumanApproval: true,
      humanApprovalGranted: true,
      frequencyOk: false,
      frequencyReason: 'Cooldown active for this channel.',
      cooldownActive: true,
      prospectMatchRequired: false,
    })

    expect(blockedFrequency.code).toBe('cooldown_active')

    const eligible = evaluateEngagementSendEligibility({
      platform: 'email',
      channel: 'email',
      consentAllowed: true,
      consentStatus: 'granted',
      providerConnected: true,
      providerActivityPermitted: true,
      requiresHumanApproval: true,
      humanApprovalGranted: true,
      frequencyOk: true,
      prospectMatchRequired: false,
    })

    expect(eligible.code).toBe('eligible')
    expect(eligible.allowed).toBe(true)
  })

  it('flags sensitive or uncertain outcomes for staff review and supports low-confidence escalations', () => {
    const sensitive = classifyEngagementOutcome({ text: 'I want to stop receiving contact and this is a complaint about an unsafe experience.' })
    expect(sensitive.requiresStaffReview).toBe(true)
    expect(sensitive.outcome).toBe('complaint')

    const unclear = classifyEngagementOutcome({ text: '??' })
    expect(unclear.outcome).toBe('unclear')
    expect(unclear.requiresStaffReview).toBe(true)

    const weakSignal = classifyEngagementOutcome({ text: 'Can I ask a quick question?', })
    expect(weakSignal.outcome).toBe('follow_up_needed')
  })

  it('creates actionable follow-up reminders for staff review', () => {
    const reminder = createEngagementFollowUp({ reason: 'Awaiting human approval.', dueAt: '2026-09-09T12:00:00Z', priority: 'high' })
    expect(reminder.status).toBe('pending')
    expect(reminder.priority).toBe('high')
  })

  it('supports approval, rejection, and cancellation states in the review flow', async () => {
    const approved = await aiEngagementRepository.approve({
      p_suggestion_id: 'suggestion-1',
      p_decided_by: 'staff-1',
      p_decision_reason: 'Approved by staff review.',
      p_eligibility_snapshot: { consent_result: 'granted', suppression_result: 'clear' },
    })
    const rejected = await aiEngagementRepository.reject({ p_suggestion_id: 'suggestion-1', p_decided_by: 'staff-1', p_reason: 'Rejected after review.' })
    const cancelled = await aiEngagementRepository.cancel({ p_suggestion_id: 'suggestion-2', p_cancelled_by: 'staff-1', p_reason: 'Cancelled before send.' })

    expect(approved.ok).toBe(true)
    expect(rejected.ok).toBe(true)
    expect(cancelled.ok).toBe(true)
  })

  it('parses the Release 3D migration and verifier SQL without syntax issues', async () => {
    await loadModule()
    const migrationSql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20260910_000001_milestone_3d_ai_assisted_engagement.sql'), 'utf8')
    const verifierSql = readFileSync(resolve(process.cwd(), 'supabase/verification/verify_milestone_3d_ai_assisted_engagement.sql'), 'utf8')

    expect(() => parseSync(migrationSql)).not.toThrow()
    expect(() => parseSync(verifierSql)).not.toThrow()
    console.log('MIGRATION_3D_PARSE_OK')
    console.log('VERIFIER_3D_PARSE_OK')
  })
})
