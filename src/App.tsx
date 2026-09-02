import { useEffect, useState } from 'react'
import {
  AlertTriangle,
  ArrowRight,
  BarChart3,
  BriefcaseBusiness,
  Building2,
  CalendarCheck2,
  CheckCircle2,
  CircleDashed,
  FileText,
  FolderKanban,
  LayoutDashboard,
  Lock,
  LogOut,
  Megaphone,
  Menu,
  MessageSquareText,
  Search,
  ShieldCheck,
  Sparkles,
  Users,
  Wand2,
  X,
} from 'lucide-react'
import { Link, NavLink, Navigate, Route, Routes } from 'react-router-dom'
import './App.css'
import { isSupabaseConfigured, supabase, supabaseStatusMessage } from './lib/supabaseClient'

type NavItem = {
  label: string
  icon: typeof LayoutDashboard
  to: string
  future?: boolean
  requiresAdmin?: boolean
}

type NavGroup = {
  label: string
  items: NavItem[]
}

type SessionUser = {
  id: string
  email: string
  full_name: string
  roleCode: string | null
  roleDisplayName: string
}

const navGroups: NavGroup[] = [
  { label: 'Overview', items: [{ label: 'Dashboard', icon: LayoutDashboard, to: '/dashboard' }, { label: 'Work Queue', icon: CircleDashed, to: '/queue' }] },
  { label: 'Discovery', items: [{ label: 'Prospects', icon: Users, to: '/prospects', future: true }, { label: 'Businesses', icon: Building2, to: '/businesses', future: true }, { label: 'Campaigns', icon: Megaphone, to: '/campaigns' }, { label: 'Nominations', icon: ArrowRight, to: '/nominations', future: true }, { label: 'Imports', icon: FileText, to: '/imports', future: true }] },
  { label: 'Social Engagement', items: [{ label: 'Social Inbox', icon: MessageSquareText, to: '/social-inbox', future: true }, { label: 'Content Studio', icon: Sparkles, to: '/content-studio', future: true }, { label: 'Publishing Calendar', icon: CalendarCheck2, to: '/publishing-calendar', future: true }, { label: 'Published Posts', icon: CheckCircle2, to: '/published-posts', future: true }, { label: 'Social Performance', icon: BarChart3, to: '/social-performance', future: true }, { label: 'Templates', icon: FolderKanban, to: '/templates', future: true }] },
  { label: 'Review and Approval', items: [{ label: 'D9 Verification', icon: ShieldCheck, to: '/verification' }, { label: 'Consent Review', icon: Lock, to: '/consent-review', future: true }, { label: 'Content Approvals', icon: CheckCircle2, to: '/content-approvals', future: true }, { label: 'Duplicate Review', icon: AlertTriangle, to: '/duplicate-review', future: true }, { label: 'Exceptions', icon: AlertTriangle, to: '/exceptions', future: true }] },
  { label: 'Conversion and Growth', items: [{ label: 'Profile Claims', icon: BriefcaseBusiness, to: '/profile-claims', future: true }, { label: 'Marketplace Handoffs', icon: Building2, to: '/marketplace-handoffs', future: true }, { label: 'Membership Handoffs', icon: BriefcaseBusiness, to: '/membership-handoffs', future: true }, { label: 'Growth Handoffs', icon: Wand2, to: '/growth-handoffs', future: true }, { label: 'Spotlights', icon: Sparkles, to: '/spotlights', future: true }] },
  { label: 'Intelligence', items: [{ label: 'Engine Reports', icon: BarChart3, to: '/engine-reports', future: true }, { label: 'Campaign Attribution', icon: Megaphone, to: '/campaign-attribution', future: true }, { label: 'Social-to-Membership Funnel', icon: ArrowRight, to: '/social-membership-funnel', future: true }, { label: 'D9 Intelligence Dashboard', icon: BarChart3, to: '/d9-intelligence', future: true }] },
  { label: 'System', items: [{ label: 'Users and Roles', icon: Users, to: '/admin/users', requiresAdmin: true }, { label: 'Social Connections', icon: Users, to: '/social-connections', future: true }, { label: 'Integrations', icon: FileText, to: '/integrations' }, { label: 'Workflow Rules', icon: CircleDashed, to: '/workflow-rules', future: true }, { label: 'Organization Settings', icon: Building2, to: '/organization-settings' }, { label: 'Audit Log', icon: FileText, to: '/audit-log' }] },
]

function AppRoot() {
  const [mobileNavOpen, setMobileNavOpen] = useState(false)
  const [session, setSession] = useState<any>(null)
  const [authUser, setAuthUser] = useState<SessionUser | null>(null)
  const [authLoading, setAuthLoading] = useState(true)
  const [authError, setAuthError] = useState<string | null>(null)
  const [loginError, setLoginError] = useState<string | null>(null)
  const [signingIn, setSigningIn] = useState(false)
  const [signingOut, setSigningOut] = useState(false)

  useEffect(() => {
    const client = supabase
    if (!client) {
      setSession(null)
      setAuthUser(null)
      setAuthLoading(false)
      return
    }

    let isMounted = true

    const syncSession = async () => {
      const { data, error } = await client.auth.getSession()
      if (!isMounted) return

      if (error) {
        setAuthError(error.message)
      }

      setSession(data.session ?? null)
      setAuthLoading(false)
    }

    syncSession()

    const { data: authListener } = client.auth.onAuthStateChange((_event, nextSession) => {
      if (!isMounted) return

      setSession(nextSession)
      setAuthError(null)
      setLoginError(null)
    })

    return () => {
      isMounted = false
      authListener.subscription.unsubscribe()
    }
  }, [])

  useEffect(() => {
    if (!supabase || !session?.user?.id) {
      setAuthUser(null)
      return
    }

    let isMounted = true

    const loadActiveRole = async () => {
      const client = supabase
      if (!client) return

      const { data: assignments, error: assignmentError } = await client
        .from('user_role_assignments')
        .select('role_id')
        .eq('user_id', session.user.id)
        .eq('is_active', true)

      if (!isMounted) return

      if (assignmentError) {
        setAuthError(assignmentError.message)
        setAuthUser({
          id: session.user.id,
          email: session.user.email ?? 'Unknown user',
          full_name: session.user.user_metadata?.full_name ?? session.user.email ?? 'Staff member',
          roleCode: null,
          roleDisplayName: 'No active role assigned',
        })
        return
      }

      const roleIds = (assignments ?? []).map((row: any) => row.role_id).filter(Boolean)

      if (!roleIds.length) {
        setAuthUser({
          id: session.user.id,
          email: session.user.email ?? 'Unknown user',
          full_name: session.user.user_metadata?.full_name ?? session.user.email ?? 'Staff member',
          roleCode: null,
          roleDisplayName: 'No active role assigned',
        })
        return
      }

      const { data: roleRows, error: roleError } = await client
        .from('roles')
        .select('code, display_name')
        .in('id', roleIds)

      if (!isMounted) return

      if (roleError) {
        setAuthError(roleError.message)
        setAuthUser({
          id: session.user.id,
          email: session.user.email ?? 'Unknown user',
          full_name: session.user.user_metadata?.full_name ?? session.user.email ?? 'Staff member',
          roleCode: null,
          roleDisplayName: 'Role lookup failed',
        })
        return
      }

      const activeRole = roleRows?.[0]
      setAuthUser({
        id: session.user.id,
        email: session.user.email ?? 'Unknown user',
        full_name: session.user.user_metadata?.full_name ?? session.user.email ?? 'Staff member',
        roleCode: activeRole?.code ?? null,
        roleDisplayName: activeRole?.display_name ?? 'No active role assigned',
      })
    }

    loadActiveRole()

    return () => {
      isMounted = false
    }
  }, [session])

  const isAuthenticated = Boolean(session)
  const isPlatformAdmin = authUser?.roleCode === 'platform_admin'
  const userDisplayName = authUser?.full_name || session?.user?.email || 'Staff member'
  const userRoleDisplay = authUser?.roleDisplayName || 'No active role assigned'

  const handleSignIn = async (email: string, password: string) => {
    if (!supabase) {
      setLoginError('Authentication is temporarily unavailable. Please contact your administrator.')
      return
    }

    setSigningIn(true)
    setLoginError(null)

    const { data, error } = await supabase.auth.signInWithPassword({ email, password })

    setSigningIn(false)

    if (error) {
      setLoginError(error.message || 'Invalid email or password.')
      return
    }

    setSession(data.session)
  }

  const handleSignOut = async () => {
    if (!supabase) return

    setSigningOut(true)
    const { error } = await supabase.auth.signOut()
    setSigningOut(false)

    if (error) {
      setAuthError(error.message)
      return
    }

    setSession(null)
    setAuthUser(null)
    setLoginError(null)
  }

  const normalizedRoutes = navGroups.map((group) => ({
    ...group,
    items: group.items.filter((item) => !item.requiresAdmin || isPlatformAdmin),
  }))

  return (
    <Routes>
      <Route path="/" element={<Navigate to={isAuthenticated ? '/dashboard' : '/login'} replace />} />
      <Route
        path="/login"
        element={
          isAuthenticated ? (
            <Navigate to="/dashboard" replace />
          ) : (
            <LoginPage
              isConfigured={isSupabaseConfigured}
              loading={authLoading || signingIn}
              error={loginError || authError}
              onSignIn={handleSignIn}
            />
          )
        }
      />
      <Route
        path="/dashboard"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={false}>
            <AuthenticatedAppShell
              navGroups={normalizedRoutes}
              userDisplayName={userDisplayName}
              userRoleDisplay={userRoleDisplay}
              mobileNavOpen={mobileNavOpen}
              setMobileNavOpen={setMobileNavOpen}
              onSignOut={handleSignOut}
              signingOut={signingOut}
            >
              <DashboardPage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/queue"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={false}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut}>
              <QueuePage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/campaigns"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={false}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut}>
              <CampaignPage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/verification"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={false}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut}>
              <PlaceholderPage moduleName="D9 Verification" purpose="Review and confirm D9 connection submissions and organization-aware public language approval before moving records toward conversion and membership steps." milestone="Milestone 3" relatedSystem="Verification reviewer workflow and consent ledger" />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/prospects"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={false}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut}>
              <PlaceholderPage moduleName="Prospects" purpose="Create and manage prospect intake, matching, and routing for discovery and conversion workflows." milestone="Milestone 2" relatedSystem="Prospect intake and operator queue" />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/integrations"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={false}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut}>
              <IntegrationsPage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/organization-settings"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={true}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut}>
              <SettingsPage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/audit-log"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={true}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut}>
              <AuditPage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/admin/users"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={true}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut}>
              <UsersAndRolesPage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route path="/admin" element={<Navigate to={isPlatformAdmin ? '/admin/users' : '/unauthorized'} replace />} />
      <Route path="/unauthorized" element={<UnauthorizedPage />} />
      <Route path="/404" element={<NotFoundPage />} />
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  )
}

function ProtectedRoute({
  isAuthenticated,
  authLoading,
  isPlatformAdmin,
  requireAdmin,
  children,
}: {
  isAuthenticated: boolean
  authLoading: boolean
  isPlatformAdmin: boolean
  requireAdmin: boolean
  children: React.ReactNode
}) {
  if (authLoading) {
    return <LoadingPage />
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  if (requireAdmin && !isPlatformAdmin) {
    return <Navigate to="/unauthorized" replace />
  }

  return children
}

function LoadingPage() {
  return (
    <div className="page auth-page">
      <div className="panel auth-card loading-card">
        <div className="brand-mark large" aria-label="D9Network">D9</div>
        <h1>Loading D9Network</h1>
        <p className="auth-copy">Restoring your secure session and platform access.</p>
      </div>
    </div>
  )
}

function LoginPage({
  isConfigured,
  loading,
  error,
  onSignIn,
}: {
  isConfigured: boolean
  loading: boolean
  error: string | null
  onSignIn: (email: string, password: string) => Promise<void>
}) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')

  const submit = async (event: React.FormEvent) => {
    event.preventDefault()

    if (!email || !password) {
      return
    }

    await onSignIn(email, password)
  }

  return (
    <div className="login-page-shell">
      <div className="login-backdrop" aria-hidden="true" />

      <div className="login-card" role="main">
        <div className="login-brand" aria-label="D9Network logo">
          <img src="/images/d9network-logo.png" alt="D9Network" className="login-logo" />
        </div>

        <div className="login-header">
          <h1>Welcome back</h1>
          <p>Sign in to manage business discovery, verification, outreach, and growth opportunities.</p>
        </div>

        {!isConfigured && (
          <div className="login-alert" role="alert">
            <strong>Authentication unavailable</strong>
            <span>Authentication is temporarily unavailable. Please contact your administrator.</span>
          </div>
        )}

        {error && (
          <div className="login-alert login-alert-error" role="alert">
            <strong>Sign in failed</strong>
            <span>{error}</span>
          </div>
        )}

        <form className="login-form" onSubmit={submit}>
          <label className="login-field">
            <span>Email</span>
            <input
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="name@company.com"
              autoComplete="email"
              disabled={!isConfigured || loading}
              required
            />
          </label>

          <label className="login-field">
            <span>Password</span>
            <input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              placeholder="Enter your password"
              autoComplete="current-password"
              disabled={!isConfigured || loading}
              required
            />
          </label>

          <div className="login-actions">
            <button type="button" className="login-secondary-link" aria-label="Forgot password is coming soon" disabled={loading}>
              Forgot password?
            </button>
          </div>

          <button type="submit" className="primary-button login-submit" disabled={!isConfigured || loading || !email || !password}>
            {loading ? 'Signing in...' : 'Sign in'}
          </button>
        </form>

        <footer className="login-footer">D9Network Business Discovery &amp; Conversion Engine</footer>
      </div>
    </div>
  )
}

function AuthenticatedAppShell({
  navGroups,
  userDisplayName,
  userRoleDisplay,
  mobileNavOpen,
  setMobileNavOpen,
  onSignOut,
  signingOut,
  children,
}: {
  navGroups: NavGroup[]
  userDisplayName: string
  userRoleDisplay: string
  mobileNavOpen: boolean
  setMobileNavOpen: (value: boolean) => void
  onSignOut: () => Promise<void>
  signingOut: boolean
  children: React.ReactNode
}) {
  return (
    <div className="app-shell">
      <button type="button" className="mobile-menu-button" aria-label="Open navigation" onClick={() => setMobileNavOpen(true)}>
        <Menu size={18} />
      </button>

      <aside className={`sidebar ${mobileNavOpen ? 'sidebar-open' : ''}`} aria-label="Main navigation">
        <div className="sidebar-header">
          <div className="brand-wrap">
            <div className="brand-mark" aria-label="D9Network">D9</div>
            <div>
              <div className="brand-name">D9Network</div>
              <div className="brand-subtitle">Discovery Engine</div>
            </div>
          </div>
          <button type="button" className="sidebar-close" aria-label="Close navigation" onClick={() => setMobileNavOpen(false)}>
            <X size={16} />
          </button>
        </div>

        <nav className="nav-groups" aria-label="Navigation groups">
          {navGroups.map((group) => (
            <div key={group.label} className="nav-group">
              <div className="nav-group-label">{group.label}</div>
              <div className="nav-items">
                {group.items.map(({ label, icon: Icon, to, future, requiresAdmin }) => (
                  <NavLink
                    key={label}
                    to={to}
                    onClick={() => setMobileNavOpen(false)}
                    className={({ isActive }) => `nav-item ${isActive ? 'nav-item-active' : ''} ${future ? 'nav-item-future' : ''} ${requiresAdmin ? 'nav-item-admin' : ''}`}
                  >
                    <Icon size={18} />
                    <span>{label}</span>
                    {future && <span className="coming-soon">Later</span>}
                  </NavLink>
                ))}
              </div>
            </div>
          ))}
        </nav>
      </aside>

      <main className="main-panel">
        <header className="topbar">
          <div className="search-box" role="search">
            <Search size={16} />
            <input aria-label="Global search" placeholder="Global search (future functionality)" />
          </div>
          <div className="topbar-actions">
            <button type="button" className="ghost-button">New prospect</button>
            <button type="button" className="primary-button">Coming in Milestone 2</button>
          </div>
          <div className="user-menu">
            <div className="user-avatar">{userDisplayName.slice(0, 2).toUpperCase()}</div>
            <div className="user-meta">
              <strong>{userDisplayName}</strong>
              <span>{userRoleDisplay}</span>
            </div>
            <button type="button" className="icon-button" aria-label="Log out" onClick={() => void onSignOut()} disabled={signingOut}>
              <LogOut size={16} />
            </button>
          </div>
        </header>

        <div className="page-shell">{children}</div>
      </main>
    </div>
  )
}

function UnauthorizedPage() {
  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Access</p>
          <h1>Unauthorized</h1>
        </div>
      </div>
      <div className="panel empty-state">
        <h2>Insufficient access</h2>
        <p>Your current role does not permit access to this area. Contact an administrator for permission review.</p>
        <Link className="primary-button" to="/dashboard">Return to dashboard</Link>
      </div>
    </div>
  )
}

function DashboardPage() {
  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Platform status</p>
          <h1>Dashboard</h1>
        </div>
        <button type="button" className="primary-button">Platform review</button>
      </div>

      <section className="summary-row">
        <article className="metric-card tone-navy">
          <span className="metric-label">Authentication</span>
          <strong>Configured</strong>
          <span className="metric-delta">Supabase hook present</span>
        </article>
        <article className="metric-card tone-orange">
          <span className="metric-label">Active staff</span>
          <strong>12</strong>
          <span className="metric-delta">Demo set</span>
        </article>
        <article className="metric-card tone-muted">
          <span className="metric-label">Role distribution</span>
          <strong>9 roles</strong>
          <span className="metric-delta">Seeded</span>
        </article>
        <article className="metric-card tone-navy">
          <span className="metric-label">Integrations</span>
          <strong>4</strong>
          <span className="metric-delta">Ready for registry</span>
        </article>
      </section>

      <section className="content-grid two-col">
        <div className="panel">
          <div className="panel-header"><h2>Platform readiness</h2></div>
          <div className="stack-list">
            <div className="list-row"><div><strong>Authentication</strong><span>Protected local session flow</span></div><span className="pill neutral">Configured</span></div>
            <div className="list-row"><div><strong>Role model</strong><span>Admin, operator, intern, reviewer</span></div><span className="pill neutral">Seeded</span></div>
            <div className="list-row"><div><strong>Audit log</strong><span>Platform change tracking</span></div><span className="pill neutral">Ready</span></div>
            <div className="list-row"><div><strong>Netlify routing</strong><span>SPA redirect configured</span></div><span className="pill neutral">Ready</span></div>
          </div>
        </div>

        <div className="panel">
          <div className="panel-header"><h2>Upcoming milestones</h2></div>
          <ul className="activity-feed">
            <li>Milestone 2: discovery intake, matching, and workflow routing.</li>
            <li>Milestone 3: D9 verification, consent, and social engagement flows.</li>
            <li>Milestone 4: marketplace conversion, membership, and intelligence integration.</li>
          </ul>
        </div>
      </section>

      <section className="content-grid three-col">
        <div className="panel">
          <div className="panel-header"><h2>Recent admin activity</h2></div>
          <ul className="activity-feed">
            <li>Platform settings view requested by Tina Morgan.</li>
            <li>Integration registry reviewed for readiness.</li>
            <li>Audit log initialized for admin events.</li>
          </ul>
        </div>

        <div className="panel">
          <div className="panel-header"><h2>Integrations</h2></div>
          <div className="distribution-list">
            <div><span>Brilliant Directories</span><strong>Read-only</strong></div>
            <div><span>D9 Intelligence</span><strong>Read-only</strong></div>
            <div><span>Instagram</span><strong>Blocked</strong></div>
            <div><span>Email Provider</span><strong>Ready</strong></div>
          </div>
        </div>

        <div className="panel">
          <div className="panel-header"><h2>Configuration alerts</h2></div>
          <div className="distribution-list">
            <div><span>Supabase env</span><strong>{supabaseStatusMessage.includes('not configured') ? 'Pending' : 'Ready'}</strong></div>
            <div><span>Login flow</span><strong>Guarded</strong></div>
            <div><span>Netlify redirect</span><strong>Enabled</strong></div>
            <div><span>Milestone 2</span><strong>Locked</strong></div>
          </div>
        </div>
      </section>
    </div>
  )
}

function QueuePage() {
  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Milestone 1</p>
          <h1>Work Queue</h1>
        </div>
      </div>
      <div className="panel empty-state">
        <h2>Platform setup queue</h2>
        <p>This queue is reserved for Milestone 2 operational workflows. Current work is focused on authentication, roles, routing, and integration readiness.</p>
      </div>
    </div>
  )
}

function CampaignPage() {
  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Discovery foundation</p>
          <h1>Campaigns</h1>
        </div>
      </div>
      <div className="panel empty-state">
        <h2>Milestone 2 campaign workspace</h2>
        <p>This module will be activated once the public intake and routing foundation is complete.</p>
      </div>
    </div>
  )
}

function PlaceholderPage({ moduleName, purpose, milestone, relatedSystem }: { moduleName: string; purpose: string; milestone: string; relatedSystem: string }) {
  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Future milestone</p>
          <h1>{moduleName}</h1>
        </div>
      </div>
      <div className="panel module-placeholder">
        <div className="placeholder-tag">Not yet active</div>
        <h2>{moduleName}</h2>
        <p><strong>Purpose:</strong> {purpose}</p>
        <p><strong>Planned milestone:</strong> {milestone}</p>
        <p><strong>Related system or integration:</strong> {relatedSystem}</p>
      </div>
    </div>
  )
}

function IntegrationsPage() {
  const integrations = [
    { name: 'Brilliant Directories', status: 'Read-only integration', environment: 'Production-ready interface', owner: 'Membership' },
    { name: 'D9 Intelligence Dashboard', status: 'Read-only integration', environment: 'Reporting interface', owner: 'Leadership' },
    { name: 'Instagram', status: 'Blocked', environment: 'Future social publishing', owner: 'Content' },
    { name: 'Facebook', status: 'Blocked', environment: 'Future social publishing', owner: 'Content' },
    { name: 'Email Provider', status: 'Configurable', environment: 'Approved provider adapter', owner: 'Platform' },
  ]

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">System</p>
          <h1>Integrations</h1>
        </div>
      </div>
      <div className="cards-grid equal-grid">
        {integrations.map((integration) => (
          <article key={integration.name} className="panel card-panel">
            <div className="panel-header compact">
              <h3>{integration.name}</h3>
              <span className="pill navy">{integration.status}</span>
            </div>
            <dl className="meta-list">
              <div><dt>Environment</dt><dd>{integration.environment}</dd></div>
              <div><dt>Owner</dt><dd>{integration.owner}</dd></div>
            </dl>
          </article>
        ))}
      </div>
    </div>
  )
}

function SettingsPage() {
  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">System</p>
          <h1>Organization Settings</h1>
        </div>
      </div>
      <div className="panel empty-state">
        <h2>Configuration controls</h2>
        <p>Platform settings remain guarded and will be managed through approved administrator workflows.</p>
      </div>
    </div>
  )
}

function AuditPage() {
  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">System</p>
          <h1>Audit Log</h1>
        </div>
      </div>
      <div className="panel empty-state">
        <h2>Audit trail ready</h2>
        <p>Administrative actions will be logged as part of the Milestone 1 platform foundation.</p>
      </div>
    </div>
  )
}

function UsersAndRolesPage() {
  const staffUsers = [
    { name: 'Tina Morgan', role: 'Platform Administrator', status: 'Active' },
    { name: 'Elliot Brooks', role: 'Campaign Manager', status: 'Active' },
    { name: 'Jordan Park', role: 'Operator', status: 'Active' },
    { name: 'Ava Lopez', role: 'Intern or Researcher', status: 'Pending' },
  ]

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">System</p>
          <h1>Users and Roles</h1>
        </div>
        <button type="button" className="primary-button">Assign role</button>
      </div>
      <div className="panel table-panel">
        <table className="data-table">
          <thead>
            <tr><th>Name</th><th>Role</th><th>Status</th></tr>
          </thead>
          <tbody>
            {staffUsers.map((person) => (
              <tr key={person.name}><td>{person.name}</td><td>{person.role}</td><td><span className="pill neutral">{person.status}</span></td></tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function NotFoundPage() {
  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Application</p>
          <h1>Page not found</h1>
        </div>
      </div>
      <div className="panel empty-state">
        <h2>Route not available</h2>
        <p>The page you requested is not part of the current Milestone 1 platform configuration.</p>
        <Link className="primary-button" to="/dashboard">Return to dashboard</Link>
      </div>
    </div>
  )
}

export { AppRoot }
export default AppRoot
