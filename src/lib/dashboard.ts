export type DashboardMetricState = {
  prospects: number
  newDiscoveries: number
  activeBusinesses: number
  pendingNominations: number
  outreachNeeded: number
  reportedD9Connections: number
  membershipMatches: number
  possibleDuplicates: number
  activeCampaigns: number
  openWorkItems: number
  overdueWorkItems: number
  recentOptOuts: number
}

export const defaultDashboardState: DashboardMetricState = {
  prospects: 0,
  newDiscoveries: 0,
  activeBusinesses: 0,
  pendingNominations: 0,
  outreachNeeded: 0,
  reportedD9Connections: 0,
  membershipMatches: 0,
  possibleDuplicates: 0,
  activeCampaigns: 0,
  openWorkItems: 0,
  overdueWorkItems: 0,
  recentOptOuts: 0,
}

export const summarizeDashboardMetrics = (values: Partial<DashboardMetricState>) => ({
  ...defaultDashboardState,
  ...values,
})

export const createDashboardLoadError = (message: string) => ({
  message,
  type: 'dashboard_query_error' as const,
})
