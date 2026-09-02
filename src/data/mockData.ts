export type Metric = {
  label: string
  value: string
  delta: string
  tone: 'navy' | 'orange' | 'muted'
}

export type Prospect = {
  id: string
  name: string
  source: string
  campaign: string
  status: string
  owner: string
  due: string
  org?: string
  match: string
}

export type Campaign = {
  name: string
  code: string
  status: 'Active' | 'Draft' | 'Paused'
  source: string
  owner: string
  progress: number
  region: string
}

export const metrics: Metric[] = [
  { label: 'Prospects received', value: '1,284', delta: '+12.4%', tone: 'navy' },
  { label: 'Awaiting outreach', value: '89', delta: '-7.1%', tone: 'orange' },
  { label: 'Confirmed D9', value: '142', delta: '+9.3%', tone: 'muted' },
  { label: 'MRR pipeline', value: '$86.2K', delta: '+18.0%', tone: 'navy' },
  { label: 'Profile claims', value: '41', delta: '+4.7%', tone: 'orange' },
  { label: 'Opt-outs', value: '14', delta: '-2.5%', tone: 'muted' },
]

export const prospects: Prospect[] = [
  {
    id: 'PR-1042',
    name: 'Northside Realty Group',
    source: 'Partner referral',
    campaign: 'Spring Partner Push',
    status: 'Awaiting verification',
    owner: 'A. Martin',
    due: 'Today',
    org: 'Alpha Phi Alpha',
    match: 'Duplicate candidate',
  },
  {
    id: 'PR-1046',
    name: 'Harbor & Co. Consulting',
    source: 'Social discovery',
    campaign: 'Citywide outreach',
    status: 'Awaiting outreach',
    owner: 'J. Patel',
    due: 'Tomorrow',
    match: 'No duplicate',
  },
  {
    id: 'PR-1051',
    name: 'Mosaic Collective',
    source: 'Community list',
    campaign: 'Community network',
    status: 'Questionnaire submitted',
    owner: 'S. Brown',
    due: 'Fri',
    org: 'Delta Sigma Theta',
    match: 'Existing member',
  },
  {
    id: 'PR-1080',
    name: 'The Woodson Group',
    source: 'Website intake',
    campaign: 'Executive referrals',
    status: 'Owner approval',
    owner: 'M. Ruiz',
    due: 'Due in 2 days',
    match: 'Member match',
  },
]

export const campaigns: Campaign[] = [
  { name: 'Spring Partner Push', code: 'SPP-24', status: 'Active', source: 'Partner referral', owner: 'L. Jenks', progress: 68, region: 'Atlanta' },
  { name: 'Citywide outreach', code: 'CWO-24', status: 'Active', source: 'Social media', owner: 'A. Gomez', progress: 54, region: 'Washington, DC' },
  { name: 'Community network', code: 'CN-24', status: 'Draft', source: 'Community list', owner: 'S. Owens', progress: 31, region: 'National' },
  { name: 'Executive referrals', code: 'EXR-24', status: 'Paused', source: 'Leadership outreach', owner: 'T. Reed', progress: 44, region: 'Chicago' },
]

export const priorityWork = [
  { title: 'Known-Greek confirmations', count: 11, owner: 'Verification team', due: 'Due today' },
  { title: 'Profile claim follow-up', count: 7, owner: 'Membership team', due: 'Due tomorrow' },
  { title: 'Duplicate review queue', count: 4, owner: 'Ops desk', due: 'Needs review' },
  { title: 'Campaign approvals', count: 3, owner: 'Campaign managers', due: 'This week' },
]

export const activityFeed = [
  'Alpha Phi Alpha verification approved for Northside Realty Group',
  'Citywide outreach reminder delivered to 24 prospects',
  'Community pathway record added for Mosaic Collective',
  'Membership conversion invitation sent to 3 active profile claims',
]
