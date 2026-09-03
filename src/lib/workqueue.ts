export type WorkPriority = 'low' | 'normal' | 'high' | 'urgent'
export type WorkQueueStatus = 'unassigned' | 'assigned' | 'in_progress' | 'waiting' | 'completed' | 'canceled'
export type WorkItemType = 'new_discovery_review' | 'outreach_needed' | 'd9_affiliation_review' | 'membership_match_review' | 'duplicate_review' | 'nomination_review' | 'import_error_review' | 'incomplete_record' | 'opt_out_review' | 'campaign_follow_up'

export type WorkQueueRecord = {
  id: string
  title: string
  workType: WorkItemType
  relatedRecordType: string
  relatedRecordId: string
  assignee: string
  priority: WorkPriority
  status: WorkQueueStatus
  dueDate?: string | null
  campaign?: string | null
  source?: string | null
  createdAt: string
  startedAt?: string | null
  completedAt?: string | null
  completionNotes?: string | null
  waitingReason?: string | null
  cancellationReason?: string | null
}

export const WORK_PRIORITY_RANK: Record<WorkPriority, number> = {
  low: 1,
  normal: 2,
  high: 3,
  urgent: 4,
}

export const WORK_STATUS_TRANSITIONS: Record<WorkQueueStatus, WorkQueueStatus[]> = {
  unassigned: ['assigned', 'in_progress'],
  assigned: ['in_progress', 'waiting', 'completed', 'canceled'],
  in_progress: ['waiting', 'completed', 'canceled'],
  waiting: ['assigned', 'in_progress', 'completed', 'canceled'],
  completed: [],
  canceled: [],
}

export const normalizeWorkItem = (input: {
  id?: string
  title?: string
  workType?: WorkItemType | string
  relatedRecordType?: string
  relatedRecordId?: string
  assignee?: string
  priority?: WorkPriority | string
  status?: WorkQueueStatus | string
  dueDate?: string | null
  campaign?: string | null
  source?: string | null
  createdAt?: string
  startedAt?: string | null
  completedAt?: string | null
  completionNotes?: string | null
  waitingReason?: string | null
  cancellationReason?: string | null
}): WorkQueueRecord => {
  const normalizedType = ((input.workType ?? 'new_discovery_review') as string).trim().toLowerCase() as WorkItemType
  const normalizedPriority = ((input.priority ?? 'normal') as string).trim().toLowerCase() as WorkPriority
  const normalizedStatus = ((input.status ?? 'unassigned') as string).trim().toLowerCase() as WorkQueueStatus

  return {
    id: input.id ?? `work-${Date.now()}`,
    title: (input.title ?? 'Operational follow-up').trim() || 'Operational follow-up',
    workType: ['new_discovery_review', 'outreach_needed', 'd9_affiliation_review', 'membership_match_review', 'duplicate_review', 'nomination_review', 'import_error_review', 'incomplete_record', 'opt_out_review', 'campaign_follow_up'].includes(normalizedType) ? normalizedType : 'new_discovery_review',
    relatedRecordType: (input.relatedRecordType ?? 'prospect').trim() || 'prospect',
    relatedRecordId: (input.relatedRecordId ?? '').trim(),
    assignee: (input.assignee ?? 'unassigned').trim() || 'unassigned',
    priority: ['low', 'normal', 'high', 'urgent'].includes(normalizedPriority) ? normalizedPriority : 'normal',
    status: ['unassigned', 'assigned', 'in_progress', 'waiting', 'completed', 'canceled'].includes(normalizedStatus) ? normalizedStatus : 'unassigned',
    dueDate: input.dueDate ?? null,
    campaign: input.campaign ?? null,
    source: input.source ?? null,
    createdAt: input.createdAt ?? new Date().toISOString(),
    startedAt: input.startedAt ?? null,
    completedAt: input.completedAt ?? null,
    completionNotes: input.completionNotes ?? null,
    waitingReason: input.waitingReason ?? null,
    cancellationReason: input.cancellationReason ?? null,
  }
}

export const canTransitionWorkItem = (from: string, to: string) => {
  const current = (from ?? 'unassigned') as WorkQueueStatus
  const next = (to ?? 'unassigned') as WorkQueueStatus
  return (WORK_STATUS_TRANSITIONS[current] ?? []).includes(next)
}

export const isOverdue = (item: WorkQueueRecord, now = new Date()) => {
  if (!item.dueDate || item.status === 'completed' || item.status === 'canceled') return false
  return new Date(item.dueDate).getTime() < now.getTime()
}

export const preventDuplicateOpenWork = (items: WorkQueueRecord[], candidate: Pick<WorkQueueRecord, 'relatedRecordType' | 'relatedRecordId' | 'workType'>) => {
  return items.some((item) => item.relatedRecordType === candidate.relatedRecordType && item.relatedRecordId === candidate.relatedRecordId && item.workType === candidate.workType && ['unassigned', 'assigned', 'in_progress', 'waiting'].includes(item.status))
}

export const buildWorkQueueSummary = (items: WorkQueueRecord[]) => ({
  total: items.length,
  open: items.filter((item) => !['completed', 'canceled'].includes(item.status)).length,
  overdue: items.filter((item) => isOverdue(item)).length,
  urgent: items.filter((item) => item.priority === 'urgent').length,
  unassigned: items.filter((item) => item.status === 'unassigned').length,
})

export const filterWorkItems = (items: WorkQueueRecord[], filters: { search?: string; status?: string; priority?: string; assignee?: string; campaign?: string; dueDate?: string; type?: string }) => {
  const search = (filters.search ?? '').trim().toLowerCase()

  return items.filter((item) => {
    const matchesSearch = !search || [item.title, item.relatedRecordType, item.assignee, item.campaign ?? '', item.source ?? ''].join(' ').toLowerCase().includes(search)
    const matchesStatus = !filters.status || filters.status === 'all' || item.status === filters.status
    const matchesPriority = !filters.priority || filters.priority === 'all' || item.priority === filters.priority
    const matchesAssignee = !filters.assignee || filters.assignee === 'all' || item.assignee.toLowerCase() === filters.assignee.toLowerCase()
    const matchesCampaign = !filters.campaign || filters.campaign === 'all' || (item.campaign ?? '').toLowerCase() === filters.campaign.toLowerCase()
    const matchesType = !filters.type || filters.type === 'all' || item.workType === filters.type
    const matchesDueDate = !filters.dueDate || filters.dueDate === 'all' || (item.dueDate ? new Date(item.dueDate).toISOString().slice(0, 10) === filters.dueDate : false)

    return matchesSearch && matchesStatus && matchesPriority && matchesAssignee && matchesCampaign && matchesType && matchesDueDate
  })
}

export const createOperationalWorkItem = (input: Partial<WorkQueueRecord> & { optOut?: boolean }) => {
  const normalized = normalizeWorkItem(input)
  if (input.optOut) {
    return {
      ...normalized,
      status: 'canceled',
      cancellationReason: 'Opted-out record suppressed from outreach work.',
    }
  }

  return normalized
}
