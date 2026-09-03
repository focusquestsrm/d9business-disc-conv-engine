import { describe, expect, it } from 'vitest'
import {
  canProcessNomination,
  canReviewNomination,
  createProspectFromNomination,
  normalizeNomination,
  screenNominationForDuplicate,
  validateNominationDecision,
  validateNominationTransition,
} from './nomination'

describe('nomination workflow', () => {
  it('allows a valid nomination lifecycle transition', () => {
    expect(validateNominationTransition('submitted', 'under_review')).toBe(true)
    expect(validateNominationTransition('under_review', 'more_information_needed')).toBe(true)
    expect(validateNominationTransition('accepted', 'rejected')).toBe(false)
    expect(validateNominationTransition('duplicate_review', 'accepted')).toBe(true)
  })

  it('blocks processing for finalized nominations', () => {
    expect(canProcessNomination({ status: 'accepted' })).toBe(false)
    expect(canProcessNomination({ status: 'rejected' })).toBe(false)
    expect(canProcessNomination({ status: 'submitted' })).toBe(true)
  })

  it('screens duplicate nominations before acceptance', () => {
    const result = screenNominationForDuplicate({
      nominatedBusinessName: 'Northside Studio',
      email: 'hello@northside.com',
      website: 'https://northside.com',
      phone: '+1 (415) 555-0105',
    })

    expect(result.duplicate).toBe(true)
    expect(result.confidence).toMatch(/exact|probable/)
  })

  it('requires a rejection reason for reject decisions', () => {
    expect(validateNominationDecision('rejected', 'Out of scope')).toBe(true)
    expect(validateNominationDecision('rejected', '    ')).toBe(false)
  })

  it('enforces role-based review permissions', () => {
    expect(canReviewNomination({ status: 'under_review' }, 'platform_admin')).toBe(true)
    expect(canReviewNomination({ status: 'under_review' }, 'viewer')).toBe(false)
    expect(canReviewNomination({ status: 'accepted' }, 'platform_admin')).toBe(false)
  })

  it('creates a prospect payload from an accepted nomination', () => {
    const nomination = normalizeNomination({
      nominatedBusinessName: 'Greenfield Coffee',
      primaryContactName: 'Rosa Chen',
      email: 'rosa@greenfieldcoffee.com',
      website: 'https://greenfieldcoffee.com',
      source: 'internal_staff',
      reportedD9Status: 'unknown',
      status: 'accepted',
    })

    const prospect = createProspectFromNomination(nomination)

    expect(prospect.businessName).toBe('Greenfield Coffee')
    expect(prospect.displayName).toBe('Greenfield Coffee')
    expect(prospect.d9ConnectionStatus).toBe('unknown')
    expect(prospect.workflowStatus).toBe('new')
  })
})
