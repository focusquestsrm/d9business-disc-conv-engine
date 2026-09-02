import { type FormEvent, useMemo, useState } from 'react'
import {
  BarChart3,
  BriefcaseBusiness,
  Building2,
  CheckCircle2,
  CircleDashed,
  FileText,
  FolderKanban,
  LayoutDashboard,
  Megaphone,
  MessageSquareText,
  Plus,
  Search,
  ShieldCheck,
  Sparkles,
  Users,
  Wand2,
} from 'lucide-react'
import { Link, NavLink, Route, Routes } from 'react-router-dom'
import './App.css'
import { activityFeed, campaigns, metrics, priorityWork, prospects } from './data/mockData'

const navItems = [
  { label: 'Dashboard', icon: LayoutDashboard, to: '/dashboard' },
  { label: 'Work Queue', icon: CircleDashed, to: '/queue' },
  { label: 'Prospects', icon: Users, to: '/prospects' },
  { label: 'Businesses', icon: Building2, to: '/businesses' },
  { label: 'Campaigns', icon: Megaphone, to: '/campaigns' },
  { label: 'Verification', icon: ShieldCheck, to: '/verification' },
  { label: 'Spotlights', icon: Sparkles, to: '/spotlights' },
  { label: 'Membership', icon: BriefcaseBusiness, to: '/membership' },
  { label: 'Growth Handoffs', icon: Wand2, to: '/growth' },
  { label: 'Reports', icon: BarChart3, to: '/reports' },
  { label: 'Imports', icon: FileText, to: '/imports' },
  { label: 'Templates', icon: FolderKanban, to: '/templates' },
  { label: 'Administration', icon: CheckCircle2, to: '/admin' },
]

function AppRoot() {
  return (
    <div className="app-shell">
      <aside className="sidebar" aria-label="Main navigation">
        <div className="brand-wrap">
          <div className="brand-mark" aria-label="D9Network">
            D9
          </div>
          <div>
            <div className="brand-name">D9Network</div>
            <div className="brand-subtitle">Discovery Engine</div>
          </div>
        </div>

        <nav className="nav-list">
          {navItems.map(({ label, icon: Icon, to }) => (
            <NavLink
              key={label}
              to={to}
              className={({ isActive }) =>
                `nav-item ${isActive ? 'nav-item-active' : ''}`
              }
            >
              <Icon size={18} />
              <span>{label}</span>
            </NavLink>
          ))}
        </nav>
      </aside>

      <main className="main-panel">
        <header className="topbar">
          <div className="search-box" role="search">
            <Search size={16} />
            <input aria-label="Search workspace" placeholder="Search records, campaigns, or owners" />
          </div>
          <div className="header-actions">
            <button type="button" className="ghost-button">Export</button>
            <button type="button" className="primary-button">New prospect</button>
          </div>
        </header>

        <Routes>
          <Route path="/" element={<DashboardPage />} />
          <Route path="/dashboard" element={<DashboardPage />} />
          <Route path="/queue" element={<QueuePage />} />
          <Route path="/campaigns" element={<CampaignsPage />} />
          <Route path="/intake" element={<IntakePage />} />
          <Route path="*" element={<DashboardPage />} />
        </Routes>
      </main>
    </div>
  )
}

function DashboardPage() {
  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Operations overview</p>
          <h1>Dashboard</h1>
        </div>
        <div className="header-inline-actions">
          <Link className="ghost-button" to="/campaigns">Campaigns</Link>
          <Link className="primary-button" to="/intake">Quick intake</Link>
        </div>
      </div>

      <section className="summary-row">
        {metrics.map((metric) => (
          <article key={metric.label} className={`metric-card tone-${metric.tone}`}>
            <span className="metric-label">{metric.label}</span>
            <strong>{metric.value}</strong>
            <span className="metric-delta">{metric.delta}</span>
          </article>
        ))}
      </section>

      <section className="content-grid two-col">
        <div className="panel">
          <div className="panel-header">
            <h2>Work requiring attention</h2>
            <button type="button" className="ghost-button small">View all</button>
          </div>
          <div className="stack-list">
            {priorityWork.map((item) => (
              <div key={item.title} className="list-row">
                <div>
                  <strong>{item.title}</strong>
                  <span>{item.owner}</span>
                </div>
                <div className="list-right">
                  <span className="pill neutral">{item.count}</span>
                  <span className="muted-text">{item.due}</span>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="panel">
          <div className="panel-header">
            <h2>Campaign funnel</h2>
            <button type="button" className="ghost-button small">Compare</button>
          </div>
          <div className="funnel-list">
            {campaigns.map((campaign) => (
              <div key={campaign.code} className="campaign-row">
                <div>
                  <strong>{campaign.name}</strong>
                  <span>{campaign.code}</span>
                </div>
                <div className="progress-wrap">
                  <div className="progress-bar">
                    <span style={{ width: `${campaign.progress}%` }} />
                  </div>
                  <small>{campaign.progress}%</small>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="content-grid three-col">
        <div className="panel">
          <div className="panel-header">
            <h2>Greek-status distribution</h2>
          </div>
          <div className="distribution-list">
            <div><span>Known Greek</span><strong>38%</strong></div>
            <div><span>Unknown</span><strong>27%</strong></div>
            <div><span>Community</span><strong>22%</strong></div>
            <div><span>Existing Member</span><strong>13%</strong></div>
          </div>
        </div>

        <div className="panel">
          <div className="panel-header">
            <h2>Recent activity</h2>
          </div>
          <ul className="activity-feed">
            {activityFeed.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </div>

        <div className="panel">
          <div className="panel-header">
            <h2>Quick actions</h2>
          </div>
          <div className="quick-actions">
            <Link className="action-card" to="/intake">
              <Plus size={18} />
              Add prospect
            </Link>
            <Link className="action-card" to="/queue">
              <MessageSquareText size={18} />
              Review queue
            </Link>
            <Link className="action-card" to="/campaigns">
              <Megaphone size={18} />
              Launch campaign
            </Link>
          </div>
        </div>
      </section>
    </div>
  )
}

function QueuePage() {
  const rows = useMemo(() => prospects, [])

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Operational workflow</p>
          <h1>Operator work queue</h1>
        </div>
        <button type="button" className="primary-button">Assign to me</button>
      </div>

      <div className="filter-bar">
        <span className="pill navy">Campaign: All</span>
        <span className="pill navy">Organization: All</span>
        <span className="pill navy">Status: Open</span>
      </div>

      <div className="panel table-panel">
        <table className="data-table">
          <thead>
            <tr>
              <th>Prospect</th>
              <th>Source</th>
              <th>Status</th>
              <th>Owner</th>
              <th>Due</th>
              <th>Match</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.id}>
                <td>
                  <div className="record-cell">
                    <strong>{row.name}</strong>
                    <span>{row.id}</span>
                  </div>
                </td>
                <td>{row.source}</td>
                <td><span className="pill orange">{row.status}</span></td>
                <td>{row.owner}</td>
                <td>{row.due}</td>
                <td>{row.match}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function CampaignsPage() {
  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Campaigns</p>
          <h1>Campaign management</h1>
        </div>
        <button type="button" className="primary-button">Create campaign</button>
      </div>

      <div className="cards-grid equal-grid">
        {campaigns.map((campaign) => (
          <article key={campaign.code} className="panel card-panel">
            <div className="panel-header compact">
              <h3>{campaign.name}</h3>
              <span className="pill navy">{campaign.status}</span>
            </div>
            <dl className="meta-list">
              <div><dt>Code</dt><dd>{campaign.code}</dd></div>
              <div><dt>Source</dt><dd>{campaign.source}</dd></div>
              <div><dt>Owner</dt><dd>{campaign.owner}</dd></div>
              <div><dt>Region</dt><dd>{campaign.region}</dd></div>
            </dl>
            <div className="progress-wrap stacked">
              <div className="progress-bar">
                <span style={{ width: `${campaign.progress}%` }} />
              </div>
              <small>{campaign.progress}% complete</small>
            </div>
          </article>
        ))}
      </div>
    </div>
  )
}

function IntakePage() {
  const [submitted, setSubmitted] = useState(false)
  const [status, setStatus] = useState('Unknown')

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setSubmitted(true)
  }

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Prospect intake</p>
          <h1>Quick prospect intake</h1>
        </div>
        <Link className="ghost-button" to="/queue">Review queue</Link>
      </div>

      <form className="panel form-panel" onSubmit={handleSubmit}>
        <div className="form-grid">
          <label>
            Source channel
            <select defaultValue="Partner referral">
              <option>Partner referral</option>
              <option>Social discovery</option>
              <option>Website intake</option>
              <option>Community list</option>
            </select>
          </label>

          <label>
            Prospect identifier, URL, or social handle
            <input type="text" defaultValue="https://instagram.com/nextgenco" />
          </label>

          <label>
            Business or person name
            <input type="text" defaultValue="Northside Realty Group" />
          </label>

          <label>
            Greek status
            <select value={status} onChange={(event) => setStatus(event.target.value)}>
              <option>Yes</option>
              <option>Unknown</option>
              <option>No</option>
              <option>Not Disclosed</option>
            </select>
          </label>

          <label>
            D9 organization when known
            <select defaultValue="Alpha Phi Alpha">
              <option>Alpha Phi Alpha</option>
              <option>Delta Sigma Theta</option>
              <option>Kappa Alpha Psi</option>
              <option>Other</option>
            </select>
          </label>

          <label>
            Campaign
            <select defaultValue="Spring Partner Push">
              <option>Spring Partner Push</option>
              <option>Citywide outreach</option>
              <option>Community network</option>
            </select>
          </label>

          <label>
            Assigned operator
            <input type="text" defaultValue="A. Martin" />
          </label>

          <label>
            City and state
            <input type="text" defaultValue="Atlanta, GA" />
          </label>

          <label>
            Email
            <input type="email" defaultValue="hello@northsiderealty.com" />
          </label>

          <label>
            Phone
            <input type="tel" defaultValue="(404) 555-0124" />
          </label>

          <label className="full-width">
            Notes
            <textarea rows={4} defaultValue="Introduced via partner and needs cohort verification before listing." />
          </label>
        </div>

        <div className="form-actions">
          <button type="button" className="ghost-button">Save draft</button>
          <button type="submit" className="primary-button">Save and route</button>
        </div>

        {submitted && (
          <div className="success-banner" aria-live="polite">
            Prospect saved and routed to the {status} workflow review queue.
          </div>
        )}
      </form>
    </div>
  )
}

export { AppRoot }
export default AppRoot
