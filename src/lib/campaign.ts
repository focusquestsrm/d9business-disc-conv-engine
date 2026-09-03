export type CampaignStatus =
  | 'draft'
  | 'scheduled'
  | 'active'
  | 'paused'
  | 'completed'
  | 'archived'

export type CampaignType = 'discovery' | 'education' | 'outreach' | 'verification' | 'membership' | 'community'
export type CampaignSource = 'manual' | 'referral' | 'partner' | 'social' | 'email' | 'other'

export type CampaignRecord = {
  id: string
  name: string
  description: string
  campaignType: CampaignType
  sourceChannel: CampaignSource
  owner: string
  startDate?: string | null
  endDate?: string | null
  status: CampaignStatus
  targetGeography?: string
  targetIndustry?: string
  purpose?: string
  workflow?: string
  createdAt: string
  updatedAt: string
}

export const CAMPAIGN_STATUS_ORDER: Record<CampaignStatus, number> = {
  draft: 0,
  scheduled: 1,
  active: 2,
  paused: 3,
  completed: 4,
  archived: 5,
}

export const CAMPAIGN_STATUS_TRANSITIONS: Record<CampaignStatus, CampaignStatus[]> = {
  draft: ['scheduled', 'active'],
  scheduled: ['active', 'archived'],
  active: ['paused', 'completed'],
  paused: ['active', 'completed'],
  completed: ['archived'],
  archived: [],
}

export const normalizeCampaign = (input: {
  id?: string
  name?: string
  description?: string
  campaignType?: CampaignType | string
  sourceChannel?: CampaignSource | string
  owner?: string
  startDate?: string | null
  endDate?: string | null
  status?: CampaignStatus | string
  targetGeography?: string
  targetIndustry?: string
  purpose?: string
  workflow?: string
  createdAt?: string
  updatedAt?: string
}): CampaignRecord => {
  const normalizedStatus = ((input.status ?? 'draft') as string).trim().toLowerCase() as CampaignStatus
  const normalizedType = ((input.campaignType ?? 'discovery') as string).trim().toLowerCase() as CampaignType
  const normalizedSource = ((input.sourceChannel ?? 'manual') as string).trim().toLowerCase() as CampaignSource

  return {
    id: input.id ?? `campaign-${Date.now()}`,
    name: (input.name ?? '').trim(),
    description: (input.description ?? '').trim(),
    campaignType: ['discovery', 'education', 'outreach', 'verification', 'membership', 'community'].includes(normalizedType) ? normalizedType : 'discovery',
    sourceChannel: ['manual', 'referral', 'partner', 'social', 'email', 'other'].includes(normalizedSource) ? normalizedSource : 'manual',
    owner: (input.owner ?? 'Unassigned').trim() || 'Unassigned',
    startDate: input.startDate ?? null,
    endDate: input.endDate ?? null,
    status: ['draft', 'scheduled', 'active', 'paused', 'completed', 'archived'].includes(normalizedStatus) ? normalizedStatus : 'draft',
    targetGeography: (input.targetGeography ?? '').trim(),
    targetIndustry: (input.targetIndustry ?? '').trim(),
    purpose: (input.purpose ?? '').trim(),
    workflow: (input.workflow ?? '').trim(),
    createdAt: input.createdAt ?? new Date().toISOString(),
    updatedAt: input.updatedAt ?? new Date().toISOString(),
  }
}

export const canTransitionCampaign = (from: string, to: string) => {
  const current = (from ?? 'draft') as CampaignStatus
  const next = (to ?? 'draft') as CampaignStatus
  return (CAMPAIGN_STATUS_TRANSITIONS[current] ?? []).includes(next)
}

export const filterCampaigns = (campaigns: CampaignRecord[], filters: { status?: string; type?: string; channel?: string; owner?: string; search?: string }) => {
  const search = (filters.search ?? '').trim().toLowerCase()

  return campaigns.filter((campaign) => {
    const matchesStatus = !filters.status || filters.status === 'all' || campaign.status === filters.status
    const matchesType = !filters.type || filters.type === 'all' || campaign.campaignType === filters.type
    const matchesChannel = !filters.channel || filters.channel === 'all' || campaign.sourceChannel === filters.channel
    const matchesOwner = !filters.owner || filters.owner === 'all' || campaign.owner.toLowerCase() === filters.owner.toLowerCase()
    const haystack = [campaign.name, campaign.description, campaign.owner, campaign.targetGeography, campaign.targetIndustry].join(' ').toLowerCase()
    const matchesSearch = !search || haystack.includes(search)

    return matchesStatus && matchesType && matchesChannel && matchesOwner && matchesSearch
  })
}

export const summarizeCampaignMetrics = (campaigns: CampaignRecord[]) => ({
  total: campaigns.length,
  active: campaigns.filter((campaign) => campaign.status === 'active').length,
  scheduled: campaigns.filter((campaign) => campaign.status === 'scheduled').length,
  draft: campaigns.filter((campaign) => campaign.status === 'draft').length,
  paused: campaigns.filter((campaign) => campaign.status === 'paused').length,
  completed: campaigns.filter((campaign) => campaign.status === 'completed').length,
})
