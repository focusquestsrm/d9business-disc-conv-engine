import { describe, expect, it } from 'vitest'
import { CAMPAIGN_STATUS_TRANSITIONS, canTransitionCampaign, filterCampaigns, normalizeCampaign, summarizeCampaignMetrics } from './campaign'

describe('campaign engine', () => {
  it('allows valid transitions and blocks invalid ones', () => {
    expect(canTransitionCampaign('draft', 'active')).toBe(true)
    expect(canTransitionCampaign('active', 'paused')).toBe(true)
    expect(canTransitionCampaign('draft', 'completed')).toBe(false)
    expect(canTransitionCampaign('completed', 'active')).toBe(false)
  })

  it('normalizes campaign values and enforces defaults', () => {
    const campaign = normalizeCampaign({
      name: ' We See You. We Celebrate You. ',
      status: 'draft',
      campaignType: 'discovery',
      sourceChannel: 'manual',
      owner: 'Jordan Park',
    })

    expect(campaign.name).toBe('We See You. We Celebrate You.')
    expect(campaign.status).toBe('draft')
    expect(campaign.campaignType).toBe('discovery')
    expect(campaign.owner).toBe('Jordan Park')
    expect(CAMPAIGN_STATUS_TRANSITIONS.draft).toContain('active')
  })

  it('filters campaigns by search and status', () => {
    const list = [
      normalizeCampaign({ name: 'Social Business Discovery', status: 'active', campaignType: 'discovery', sourceChannel: 'social', owner: 'Jordan Park' }),
      normalizeCampaign({ name: 'Community Business Outreach', status: 'paused', campaignType: 'community', sourceChannel: 'partner', owner: 'Leah Morris' }),
    ]

    const filtered = filterCampaigns(list, { status: 'active', search: 'social' })
    expect(filtered).toHaveLength(1)
    expect(filtered[0].name).toBe('Social Business Discovery')
  })

  it('summarizes campaign metrics', () => {
    const summary = summarizeCampaignMetrics([
      normalizeCampaign({ name: 'Campaign A', status: 'active' }),
      normalizeCampaign({ name: 'Campaign B', status: 'scheduled' }),
      normalizeCampaign({ name: 'Campaign C', status: 'draft' }),
      normalizeCampaign({ name: 'Campaign D', status: 'paused' }),
      normalizeCampaign({ name: 'Campaign E', status: 'completed' }),
    ])

    expect(summary.active).toBe(1)
    expect(summary.scheduled).toBe(1)
    expect(summary.completed).toBe(1)
    expect(summary.total).toBe(5)
  })
})
