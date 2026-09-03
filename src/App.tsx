import { useEffect, useState } from 'react'
import {
  AlertTriangle,
  ArrowRight,
  BarChart3,
  Building2,
  CalendarCheck2,
  CircleDashed,
  FileText,
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
  X,
} from 'lucide-react'
import { Link, NavLink, Navigate, Route, Routes, useLocation } from 'react-router-dom'
import './App.css'
import { classifyD9Status, getWorkflowRoutingLabel, normalizeText, normalizeWebsite } from './lib/discovery'
import { CSV_TEMPLATE_HEADERS, buildImportSummary, createIdempotencyKey, parseCsvRows, requiresConfirmation, validateCsvRow } from './lib/imports'
import { canProcessNomination, normalizeNomination, screenNominationForDuplicate, validateNominationDecision, validateNominationTransition } from './lib/nomination'
import { isSupabaseConfigured, supabase } from './lib/supabaseClient'

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
  {
    label: 'Overview',
    items: [{ label: 'Dashboard', icon: LayoutDashboard, to: '/dashboard' }, { label: 'Work Queue', icon: CircleDashed, to: '/queue' }],
  },
  {
    label: 'Discovery',
    items: [{ label: 'Prospects', icon: Users, to: '/prospects' }, { label: 'Businesses', icon: Building2, to: '/businesses' }, { label: 'Campaigns', icon: Megaphone, to: '/campaigns' }, { label: 'Nominations', icon: ArrowRight, to: '/nominations' }, { label: 'Imports', icon: FileText, to: '/imports' }],
  },
  {
    label: 'Verification',
    items: [{ label: 'Verification Queue', icon: ShieldCheck, to: '/verification' }, { label: 'Consent Review', icon: Lock, to: '/consent-review', future: true }, { label: 'Duplicate Review', icon: AlertTriangle, to: '/duplicate-review' }],
  },
  {
    label: 'Social Engagement',
    items: [{ label: 'Social Inbox', icon: MessageSquareText, to: '/social-inbox', future: true }, { label: 'Content Queue', icon: Sparkles, to: '/content-queue', future: true }, { label: 'Publishing Calendar', icon: CalendarCheck2, to: '/publishing-calendar', future: true }],
  },
  {
    label: 'Integrations',
    items: [{ label: 'D9 Intelligence', icon: BarChart3, to: '/d9-intelligence', future: true }, { label: 'Brilliant Directories', icon: Building2, to: '/brilliant-directories', future: true }, { label: 'Social Connections', icon: Users, to: '/social-connections', future: true }, { label: 'Integration Health', icon: FileText, to: '/integrations' }],
  },
  {
    label: 'Administration',
    items: [{ label: 'Users & Roles', icon: Users, to: '/admin/users', requiresAdmin: true }, { label: 'Audit Log', icon: FileText, to: '/audit-log' }, { label: 'Settings', icon: Building2, to: '/organization-settings' }],
  },
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
  const [expandedSections, setExpandedSections] = useState<Record<string, boolean>>(() => {
    if (typeof window === 'undefined') {
      return {
        Overview: true,
        Discovery: true,
        Verification: true,
        'Social Engagement': false,
        Integrations: false,
        Administration: false,
      }
    }

    try {
      const stored = window.localStorage.getItem('d9network-nav-expanded')
      if (!stored) {
        return {
          Overview: true,
          Discovery: true,
          Verification: true,
          'Social Engagement': false,
          Integrations: false,
          Administration: false,
        }
      }
      return { ...{
        Overview: true,
        Discovery: true,
        Verification: true,
        'Social Engagement': false,
        Integrations: false,
        Administration: false,
      }, ...JSON.parse(stored) }
    } catch {
      return {
        Overview: true,
        Discovery: true,
        Verification: true,
        'Social Engagement': false,
        Integrations: false,
        Administration: false,
      }
    }
  })

  useEffect(() => {
    if (typeof window !== 'undefined') {
      window.localStorage.setItem('d9network-nav-expanded', JSON.stringify(expandedSections))
    }
  }, [expandedSections])

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
              expandedSections={expandedSections}
              setExpandedSections={setExpandedSections}
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
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut} expandedSections={expandedSections} setExpandedSections={setExpandedSections}>
              <WorkQueuePage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/campaigns"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={false}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut} expandedSections={expandedSections} setExpandedSections={setExpandedSections}>
              <CampaignPage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/verification"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={false}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut} expandedSections={expandedSections} setExpandedSections={setExpandedSections}>
              <VerificationQueuePage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/prospects"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={false}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut} expandedSections={expandedSections} setExpandedSections={setExpandedSections}>
              <ProspectsPage currentUserId={session?.user?.id ?? null} />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/businesses"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={false}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut} expandedSections={expandedSections} setExpandedSections={setExpandedSections}>
              <BusinessesPage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/nominations"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={false}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut} expandedSections={expandedSections} setExpandedSections={setExpandedSections}>
              <NominationsPage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/imports"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={false}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut} expandedSections={expandedSections} setExpandedSections={setExpandedSections}>
              <ImportsPage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/duplicate-review"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={false}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut} expandedSections={expandedSections} setExpandedSections={setExpandedSections}>
              <DuplicateReviewPage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/integrations"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={false}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut} expandedSections={expandedSections} setExpandedSections={setExpandedSections}>
              <IntegrationsPage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/organization-settings"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={true}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut} expandedSections={expandedSections} setExpandedSections={setExpandedSections}>
              <SettingsPage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/audit-log"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={true}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut} expandedSections={expandedSections} setExpandedSections={setExpandedSections}>
              <AuditPage />
            </AuthenticatedAppShell>
          </ProtectedRoute>
        }
      />
      <Route
        path="/admin/users"
        element={
          <ProtectedRoute isAuthenticated={isAuthenticated} authLoading={authLoading} isPlatformAdmin={isPlatformAdmin} requireAdmin={true}>
            <AuthenticatedAppShell navGroups={normalizedRoutes} userDisplayName={userDisplayName} userRoleDisplay={userRoleDisplay} mobileNavOpen={mobileNavOpen} setMobileNavOpen={setMobileNavOpen} onSignOut={handleSignOut} signingOut={signingOut} expandedSections={expandedSections} setExpandedSections={setExpandedSections}>
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
              Forgot password? (coming soon)
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
  expandedSections,
  setExpandedSections,
  children,
}: {
  navGroups: NavGroup[]
  userDisplayName: string
  userRoleDisplay: string
  mobileNavOpen: boolean
  setMobileNavOpen: (value: boolean) => void
  onSignOut: () => Promise<void>
  signingOut: boolean
  expandedSections: Record<string, boolean>
  setExpandedSections: React.Dispatch<React.SetStateAction<Record<string, boolean>>>
  children: React.ReactNode
}) {
  const location = useLocation()

  useEffect(() => {
    const activeGroup = navGroups.find((group) => group.items.some((item) => item.to === location.pathname))
    if (!activeGroup || !activeGroup.label) {
      return
    }

    setExpandedSections((current: Record<string, boolean>) => {
      if (current[activeGroup.label] === true) {
        return current
      }

      return { ...current, [activeGroup.label]: true }
    })
  }, [location.pathname, navGroups, setExpandedSections])

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
          {navGroups.map((group) => {
            const isExpanded = expandedSections[group.label] ?? true
            return (
              <div key={group.label} className="nav-group">
                <button
                  type="button"
                  className="nav-group-toggle"
                  onClick={() => setExpandedSections((current) => ({ ...current, [group.label]: !isExpanded }))}
                  aria-expanded={isExpanded}
                >
                  <span className="nav-group-label">{group.label}</span>
                  <span className="nav-chevron">{isExpanded ? '▾' : '▸'}</span>
                </button>
                {isExpanded && (
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
                )}
              </div>
            )
          })}
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
  const [stats, setStats] = useState({
    prospects: 0,
    businesses: 0,
    campaigns: 0,
    nominations: 0,
    openWorkItems: 0,
    overdueWorkItems: 0,
    optOuts: 0,
    duplicates: 0,
  })
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const loadStats = async () => {
      const client = supabase
      if (!client) {
        setStats({ prospects: 0, businesses: 0, campaigns: 0, nominations: 0, openWorkItems: 0, overdueWorkItems: 0, optOuts: 0, duplicates: 0 })
        setLoading(false)
        return
      }

      const countTable = async (tableName: string, modifier?: (query: any) => any) => {
        const baseQuery = client.from(tableName).select('id', { count: 'exact', head: true })
        const query = modifier ? modifier(baseQuery) : baseQuery
        const result = query ? await query : null
        return result?.count ?? 0
      }

      const [prospects, businesses, campaigns, nominations, queue, duplicates, optOuts] = await Promise.all([
        countTable('prospects'),
        countTable('businesses'),
        countTable('campaigns'),
        countTable('nominations'),
        countTable('workflow_assignments', (query) => typeof query?.neq === 'function' ? query.neq('status', 'completed') : null),
        countTable('possible_duplicates', (query) => typeof query?.eq === 'function' ? query.eq('review_status', 'pending') : null),
        countTable('opt_outs'),
      ])

      setStats({
        prospects,
        businesses,
        campaigns,
        nominations,
        openWorkItems: queue,
        duplicates,
        optOuts,
        overdueWorkItems: 0,
      })
      setLoading(false)
    }

    void loadStats()
  }, [])

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
          <span className="metric-label">Prospects</span>
          <strong>{loading ? '—' : stats.prospects}</strong>
          <span className="metric-delta">Live records</span>
        </article>
        <article className="metric-card tone-orange">
          <span className="metric-label">Businesses</span>
          <strong>{loading ? '—' : stats.businesses}</strong>
          <span className="metric-delta">Canonical records</span>
        </article>
        <article className="metric-card tone-muted">
          <span className="metric-label">Campaigns</span>
          <strong>{loading ? '—' : stats.campaigns}</strong>
          <span className="metric-delta">Active coverage</span>
        </article>
        <article className="metric-card tone-navy">
          <span className="metric-label">Nominations</span>
          <strong>{loading ? '—' : stats.nominations}</strong>
          <span className="metric-delta">Review queue</span>
        </article>
      </section>

      <section className="content-grid two-col">
        <div className="panel">
          <div className="panel-header"><h2>Operational snapshot</h2></div>
          <div className="stack-list">
            <div className="list-row"><div><strong>Open work items</strong><span>Assigned or awaiting action</span></div><span className="pill neutral">{loading ? '—' : stats.openWorkItems}</span></div>
            <div className="list-row"><div><strong>Possible duplicates</strong><span>Needs review or resolution</span></div><span className="pill neutral">{loading ? '—' : stats.duplicates}</span></div>
            <div className="list-row"><div><strong>Recent opt-outs</strong><span>Suppressed outreach records</span></div><span className="pill neutral">{loading ? '—' : stats.optOuts}</span></div>
            <div className="list-row"><div><strong>Overdue work</strong><span>Needs escalation</span></div><span className="pill neutral">{loading ? '—' : stats.overdueWorkItems}</span></div>
          </div>
        </div>

        <div className="panel">
          <div className="panel-header"><h2>Discovery pulse</h2></div>
          <ul className="activity-feed">
            <li>Prospect intake captures partial data and resolves duplicates before persistence.</li>
            <li>Business and nomination flows are aligned to D9 connection status and review steps.</li>
            <li>Campaign, import, and work-queue records are routed through the operational review engine.</li>
          </ul>
        </div>
      </section>
    </div>
  )
}

function WorkQueuePage() {
  const [items, setItems] = useState<Array<{ id: string; title: string; owner: string; priority: string; status: string; due: string }>>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const loadQueue = async () => {
      if (!supabase) {
        setItems([])
        setLoading(false)
        return
      }

      const { data, error } = await supabase
        .from('workflow_assignments')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) {
        setItems([])
        setLoading(false)
        return
      }

      const mapped = (data ?? []).map((row: any) => ({
        id: row.id,
        title: `${row.entity_type ?? 'record'} review`,
        owner: row.assigned_to ?? 'Unassigned',
        priority: row.priority ?? 'normal',
        status: row.status ?? 'assigned',
        due: row.due_at ? new Date(row.due_at).toLocaleDateString() : 'No due date',
      }))

      setItems(mapped)
      setLoading(false)
    }

    void loadQueue()
  }, [])

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Operations</p>
          <h1>Work Queue</h1>
        </div>
        <button type="button" className="primary-button">Assign tasks</button>
      </div>
      <div className="panel">
        <div className="panel-header">
          <h2>Priority queue</h2>
          <span className="pill navy">{items.length || 0} active</span>
        </div>
        {loading ? (
          <p>Loading queue…</p>
        ) : items.length ? (
          <div className="stack-list">
            {items.map((item) => (
              <div key={item.id} className="list-row">
                <div>
                  <strong>{item.title}</strong>
                  <span>{item.owner} · {item.due}</span>
                </div>
                <div className="header-inline-actions">
                  <span className="pill neutral">{item.priority}</span>
                  <span className="pill navy">{item.status}</span>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="panel empty-state">
            <h2>No active assignments</h2>
            <p>New operational workflow items will appear here when they are routed to the team.</p>
          </div>
        )}
      </div>
    </div>
  )
}

function VerificationQueuePage() {
  const items = [
    { company: 'Northside Studio', status: 'Manual review', confidence: '93%' },
    { company: 'Greene & Co Events', status: 'Ready', confidence: '88%' },
    { company: 'Atlas Brewing Co.', status: 'Blocked by consent', confidence: '76%' },
  ]

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Verification</p>
          <h1>Verification Queue</h1>
        </div>
        <button type="button" className="primary-button">New verification</button>
      </div>
      <div className="panel table-panel">
        <table className="data-table">
          <thead>
            <tr><th>Company</th><th>Verification status</th><th>Confidence</th></tr>
          </thead>
          <tbody>
            {items.map((item) => (
              <tr key={item.company}>
                <td>{item.company}</td>
                <td><span className="pill neutral">{item.status}</span></td>
                <td>{item.confidence}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function ProspectsPage({ currentUserId }: { currentUserId: string | null }) {
  type ProspectRow = {
    id: string
    business_name: string
    display_name: string
    primary_contact_name: string | null
    email: string | null
    phone: string | null
    website: string | null
    city: string | null
    state: string | null
    industry: string | null
    workflow_status: string
    d9_connection_status: string
    consent_status: string
    source_url: string | null
    created_at: string
  }

  const [prospects, setProspects] = useState<ProspectRow[]>([])
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [sortKey, setSortKey] = useState('created_at')
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [saveStatus, setSaveStatus] = useState<string | null>(null)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [selectedProspect, setSelectedProspect] = useState<ProspectRow | null>(null)
  const [selectedProspectDraft, setSelectedProspectDraft] = useState<Partial<ProspectRow>>({})
  const [selectedProspectHistory, setSelectedProspectHistory] = useState<Array<{ id: string; event_type: string; created_at: string; details?: Record<string, any> }>>([])
  const [selectedProspectOptOuts, setSelectedProspectOptOuts] = useState<Array<{ id: string; source: string; opt_out_reason?: string; created_at: string }>>([])
  const [businessOptions, setBusinessOptions] = useState<Array<{ id: string; display_name: string }>>([])
  const [form, setForm] = useState({
    business_name: '',
    primary_contact_name: '',
    email: '',
    phone: '',
    website: '',
    city: '',
    state: '',
    industry: '',
    source_url: '',
    d9_connection_status: 'unknown',
    workflow_status: 'new',
    consent_status: 'unknown',
  })

  const pageSize = 5

  const fetchProspects = async () => {
    if (!supabase) {
      setProspects([])
      setLoading(false)
      return
    }

    const { data, error } = await supabase
      .from('prospects')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      setProspects([])
      setLoading(false)
      return
    }

    setProspects((data ?? []) as ProspectRow[])
    setLoading(false)
  }

  useEffect(() => { void fetchProspects() }, [])

  useEffect(() => {
    const loadBusinessOptions = async () => {
      if (!supabase) {
        setBusinessOptions([])
        return
      }

      const { data, error } = await supabase.from('businesses').select('id, display_name').order('display_name', { ascending: true })
      if (!error) {
        setBusinessOptions((data ?? []) as Array<{ id: string; display_name: string }>)
      }
    }

    void loadBusinessOptions()
  }, [])

  useEffect(() => {
    if (!selectedProspect) {
      setSelectedProspectDraft({})
      setSelectedProspectHistory([])
      setSelectedProspectOptOuts([])
      return
    }

    setSelectedProspectDraft({ ...selectedProspect })

    const loadSelectedProspectDetails = async () => {
      if (!supabase) {
        setSelectedProspectHistory([])
        setSelectedProspectOptOuts([])
        return
      }

      const [eventsResult, optOutResult] = await Promise.all([
        supabase.from('workflow_events').select('*').eq('entity_id', selectedProspect.id).order('created_at', { ascending: false }),
        supabase.from('opt_outs').select('*').eq('entity_id', selectedProspect.id).order('created_at', { ascending: false }),
      ])

      if (!eventsResult.error) {
        setSelectedProspectHistory((eventsResult.data ?? []) as Array<{ id: string; event_type: string; created_at: string; details?: Record<string, any> }>)
      }

      if (!optOutResult.error) {
        setSelectedProspectOptOuts((optOutResult.data ?? []) as Array<{ id: string; source: string; opt_out_reason?: string; created_at: string }>)
      }
    }

    void loadSelectedProspectDetails()
  }, [selectedProspect])

  const normalizedSearch = search.trim().toLowerCase()
  const filteredProspects = prospects.filter((prospect) => {
    const matchesStatus = statusFilter === 'all' || prospect.workflow_status === statusFilter
    const haystack = [
      prospect.business_name,
      prospect.display_name,
      prospect.primary_contact_name,
      prospect.email,
      prospect.phone,
      prospect.city,
      prospect.state,
      prospect.industry,
    ].filter(Boolean).join(' ').toLowerCase()

    const matchesSearch = !normalizedSearch || haystack.includes(normalizedSearch)
    return matchesStatus && matchesSearch
  })

  const sortedProspects = [...filteredProspects].sort((a, b) => {
    if (sortKey === 'business_name') {
      return (a.business_name || '').localeCompare(b.business_name || '')
    }

    if (sortKey === 'workflow_status') {
      return (a.workflow_status || '').localeCompare(b.workflow_status || '')
    }

    return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  })

  const totalPages = Math.max(1, Math.ceil(sortedProspects.length / pageSize))
  const currentPage = Math.min(page, totalPages)
  const pagedProspects = sortedProspects.slice((currentPage - 1) * pageSize, currentPage * pageSize)

  const handleInputChange = (field: string, value: string) => {
    setForm((current) => ({ ...current, [field]: value }))
  }

  const handleDuplicateCheck = async (payload: Record<string, string | null | undefined>) => {
    if (!supabase) return null

    const filters = [] as string[]
    if (payload.email) filters.push(`email.eq.${payload.email}`)
    if (payload.phone) filters.push(`phone.eq.${payload.phone}`)
    if (payload.website) filters.push(`website.eq.${payload.website}`)
    if (payload.business_name) filters.push(`business_name.eq.${payload.business_name}`)

    if (!filters.length) return null

    const { data, error } = await supabase
      .from('prospects')
      .select('id, business_name, email, phone, website, workflow_status')
      .or(filters.join(',') as string)

    if (!error && data?.length) {
      return data[0]
    }

    return null
  }

  const handleSaveProspect = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setSaving(true)
    setSaveError(null)
    setSaveStatus(null)

    const payload: {
      business_name: string
      display_name: string
      primary_contact_name: string | null
      email: string | null
      phone: string | null
      website: string | null
      city: string | null
      state: string | null
      industry: string | null
      source_url: string | null
      d9_connection_status: string
      workflow_status: string
      consent_status: string
      created_by: string | null
    } = {
      business_name: form.business_name,
      display_name: form.business_name || form.primary_contact_name || 'Untitled prospect',
      primary_contact_name: form.primary_contact_name || null,
      email: form.email || null,
      phone: form.phone || null,
      website: form.website || null,
      city: form.city || null,
      state: form.state || null,
      industry: form.industry || null,
      source_url: form.source_url || null,
      d9_connection_status: form.d9_connection_status,
      workflow_status: form.workflow_status || 'incomplete',
      consent_status: form.consent_status,
      created_by: currentUserId,
    }

    if (!supabase) {
      setSaveStatus('Prospect saved locally for the current browser session.')
      setSaving(false)
      return
    }

    const duplicate = await handleDuplicateCheck(payload)
    if (duplicate) {
      setSaving(false)
      setSaveError(`Duplicate prospect detected for ${duplicate.business_name || 'this record'}. Review the existing opportunity before creating a second entry.`)
      return
    }

    const { data, error } = await supabase.from('prospects').insert(payload).select('id')
    if (error) {
      setSaving(false)
      setSaveError(error.message || 'Unable to save the prospect.')
      return
    }

    const prospectId = data?.[0]?.id
    if (prospectId) {
      await supabase.from('workflow_events').insert({
        entity_type: 'prospect',
        entity_id: prospectId,
        event_type: 'created',
        actor_user_id: currentUserId,
        details: { source: 'quick_intake', workflow_status: payload.workflow_status },
      })
    }

    setSaveStatus('Prospect saved.')
    setForm({
      business_name: '',
      primary_contact_name: '',
      email: '',
      phone: '',
      website: '',
      city: '',
      state: '',
      industry: '',
      source_url: '',
      d9_connection_status: 'unknown',
      workflow_status: 'new',
      consent_status: 'unknown',
    })
    setSaving(false)
    await fetchProspects()
  }

  const handleSelectedProspectDraftChange = (field: keyof ProspectRow, value: string) => {
    setSelectedProspectDraft((current) => ({ ...(current ?? {}), [field]: value }))
  }

  const handleUpdateSelectedProspect = async () => {
    if (!selectedProspect || !supabase) return

    const draft = selectedProspectDraft as Partial<ProspectRow>
    const { error } = await supabase.from('prospects').update({
      business_name: draft.business_name ?? selectedProspect.business_name,
      primary_contact_name: draft.primary_contact_name ?? selectedProspect.primary_contact_name,
      email: draft.email ?? selectedProspect.email,
      phone: draft.phone ?? selectedProspect.phone,
      website: draft.website ?? selectedProspect.website,
      city: draft.city ?? selectedProspect.city,
      state: draft.state ?? selectedProspect.state,
      industry: draft.industry ?? selectedProspect.industry,
      d9_connection_status: draft.d9_connection_status ?? selectedProspect.d9_connection_status,
      workflow_status: draft.workflow_status ?? selectedProspect.workflow_status,
      consent_status: draft.consent_status ?? selectedProspect.consent_status,
      source_url: draft.source_url ?? selectedProspect.source_url,
    }).eq('id', selectedProspect.id)

    if (!error) {
      setSelectedProspect({ ...selectedProspect, ...draft } as ProspectRow)
      await fetchProspects()
    }
  }

  const handleOptOutSelectedProspect = async () => {
    if (!selectedProspect || !supabase) return

    const { error: optOutError } = await supabase.from('opt_outs').insert({
      entity_type: 'prospect',
      entity_id: selectedProspect.id,
      source: 'manual_review',
      opt_out_reason: 'Marked opt-out by authorized staff',
      created_by: currentUserId,
    })

    if (optOutError) return

    const { error: updateError } = await supabase.from('prospects').update({
      workflow_status: 'opt_out_review',
      d9_connection_status: 'opt_out',
      consent_status: 'opt_out',
    }).eq('id', selectedProspect.id)

    if (!updateError) {
      await supabase.from('workflow_events').insert({
        entity_type: 'prospect',
        entity_id: selectedProspect.id,
        event_type: 'opt_out',
        actor_user_id: currentUserId,
        details: { source: 'manual_review', reason: 'Marked opt-out by authorized staff' },
      })

      await fetchProspects()
      setSelectedProspect((current) => current ? { ...current, workflow_status: 'opt_out_review', d9_connection_status: 'opt_out', consent_status: 'opt_out' } : current)
    }
  }

  const handleLinkProspectToBusiness = async (businessId: string) => {
    if (!selectedProspect || !supabase || !businessId) return

    await supabase.from('workflow_events').insert({
      entity_type: 'prospect',
      entity_id: selectedProspect.id,
      event_type: 'matched',
      actor_user_id: currentUserId,
      details: { linked_business_id: businessId, match_type: 'canonical_business_link' },
    })

    await fetchProspects()
  }

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Discovery</p>
          <h1>Prospects</h1>
        </div>
        <button type="button" className="primary-button">Add prospect</button>
      </div>

      <div className="panel">
        <div className="panel-header"><h2>Quick prospect intake</h2></div>
        <form className="stack-form" onSubmit={handleSaveProspect}>
          <div className="form-grid two-col">
            <label className="field">
              <span>Business name</span>
              <input aria-label="Business name" value={form.business_name} onChange={(event) => handleInputChange('business_name', event.target.value)} />
            </label>
            <label className="field">
              <span>Primary contact</span>
              <input aria-label="Primary contact" value={form.primary_contact_name} onChange={(event) => handleInputChange('primary_contact_name', event.target.value)} />
            </label>
            <label className="field">
              <span>Email</span>
              <input aria-label="Email" type="email" value={form.email} onChange={(event) => handleInputChange('email', event.target.value)} />
            </label>
            <label className="field">
              <span>Phone</span>
              <input aria-label="Phone" value={form.phone} onChange={(event) => handleInputChange('phone', event.target.value)} />
            </label>
            <label className="field">
              <span>Website</span>
              <input aria-label="Website" value={form.website} onChange={(event) => handleInputChange('website', event.target.value)} />
            </label>
            <label className="field">
              <span>Source URL</span>
              <input aria-label="Source URL" value={form.source_url} onChange={(event) => handleInputChange('source_url', event.target.value)} />
            </label>
            <label className="field">
              <span>City</span>
              <input aria-label="City" value={form.city} onChange={(event) => handleInputChange('city', event.target.value)} />
            </label>
            <label className="field">
              <span>State</span>
              <input aria-label="State" value={form.state} onChange={(event) => handleInputChange('state', event.target.value)} />
            </label>
            <label className="field">
              <span>Industry</span>
              <input aria-label="Industry" value={form.industry} onChange={(event) => handleInputChange('industry', event.target.value)} />
            </label>
            <label className="field">
              <span>Workflow status</span>
              <select aria-label="Workflow status" value={form.workflow_status} onChange={(event) => handleInputChange('workflow_status', event.target.value)}>
                <option value="new">new</option>
                <option value="incomplete">incomplete</option>
                <option value="outreach_needed">outreach_needed</option>
                <option value="duplicate_review">duplicate_review</option>
              </select>
            </label>
            <label className="field">
              <span>D9 connection status</span>
              <select aria-label="D9 connection status" value={form.d9_connection_status} onChange={(event) => handleInputChange('d9_connection_status', event.target.value)}>
                <option value="unknown">Unknown</option>
                <option value="known_greek">Known Greek</option>
                <option value="community_business">Community Business</option>
                <option value="existing_member">Existing Member</option>
                <option value="duplicate">Duplicate</option>
                <option value="opt_out">Opt-out</option>
              </select>
            </label>
            <label className="field">
              <span>Consent status</span>
              <select aria-label="Consent status" value={form.consent_status} onChange={(event) => handleInputChange('consent_status', event.target.value)}>
                <option value="unknown">Unknown</option>
                <option value="allowed">Allowed</option>
                <option value="restricted">Restricted</option>
                <option value="pending">Pending</option>
                <option value="opt_out">Opt-out</option>
              </select>
            </label>
          </div>

          {saveError && <div className="login-alert login-alert-error" role="alert"><strong>Duplicate detected</strong><span>{saveError}</span></div>}
          {saveStatus && <div className="login-alert" role="alert"><strong>Prospect saved</strong><span>{saveStatus}</span></div>}

          <div className="form-actions">
            <button type="submit" className="primary-button" disabled={saving}>
              {saving ? 'Saving...' : 'Save prospect'}
            </button>
          </div>
        </form>
      </div>

      <div className="panel">
        <div className="panel-header">
          <h2>Prospect roster</h2>
          <div className="header-inline-actions">
            <input aria-label="Search prospects" value={search} onChange={(event) => { setSearch(event.target.value); setPage(1) }} placeholder="Search prospects" />
            <select aria-label="Filter status" value={statusFilter} onChange={(event) => { setStatusFilter(event.target.value); setPage(1) }}>
              <option value="all">All statuses</option>
              <option value="new">new</option>
              <option value="incomplete">incomplete</option>
              <option value="outreach_needed">outreach_needed</option>
              <option value="duplicate_review">duplicate_review</option>
            </select>
            <select aria-label="Sort by" value={sortKey} onChange={(event) => setSortKey(event.target.value)}>
              <option value="created_at">Newest</option>
              <option value="business_name">Business name</option>
              <option value="workflow_status">Workflow status</option>
            </select>
          </div>
        </div>

        {loading ? <p>Loading prospects...</p> : (
          <table className="data-table">
            <thead>
              <tr><th>Business</th><th>Contact</th><th>Location</th><th>D9 status</th><th>Workflow</th></tr>
            </thead>
            <tbody>
              {pagedProspects.length ? pagedProspects.map((prospect) => (
                <tr key={prospect.id} onClick={() => setSelectedProspect(prospect)} className="clickable-row">
                  <td>
                    <strong>{prospect.business_name || prospect.display_name}</strong>
                    <div>{prospect.email || 'No email'}</div>
                  </td>
                  <td>{prospect.primary_contact_name || '—'}</td>
                  <td>{[prospect.city, prospect.state].filter(Boolean).join(', ') || '—'}</td>
                  <td><span className="pill neutral">{prospect.d9_connection_status || 'unknown'}</span></td>
                  <td>{prospect.workflow_status}</td>
                </tr>
              )) : <tr><td colSpan={5}>No prospects match the current filters.</td></tr>}
            </tbody>
          </table>
        )}

        <div className="pager">
          <button type="button" className="ghost-button" disabled={currentPage === 1} onClick={() => setPage((value) => Math.max(1, value - 1))}>Previous</button>
          <span>Page {currentPage} of {totalPages}</span>
          <button type="button" className="ghost-button" disabled={currentPage >= totalPages} onClick={() => setPage((value) => Math.min(totalPages, value + 1))}>Next</button>
        </div>
      </div>

      {selectedProspect && (
        <div className="panel">
          <div className="panel-header"><h2>Prospect detail</h2></div>
          <div className="stack-form">
            <div className="form-grid two-col">
              <label className="field">
                <span>Business name</span>
                <input value={selectedProspectDraft.business_name ?? selectedProspect.business_name ?? ''} onChange={(event) => handleSelectedProspectDraftChange('business_name', event.target.value)} />
              </label>
              <label className="field">
                <span>Primary contact</span>
                <input value={selectedProspectDraft.primary_contact_name ?? selectedProspect.primary_contact_name ?? ''} onChange={(event) => handleSelectedProspectDraftChange('primary_contact_name', event.target.value)} />
              </label>
              <label className="field">
                <span>Email</span>
                <input value={selectedProspectDraft.email ?? selectedProspect.email ?? ''} onChange={(event) => handleSelectedProspectDraftChange('email', event.target.value)} />
              </label>
              <label className="field">
                <span>Phone</span>
                <input value={selectedProspectDraft.phone ?? selectedProspect.phone ?? ''} onChange={(event) => handleSelectedProspectDraftChange('phone', event.target.value)} />
              </label>
              <label className="field">
                <span>Workflow</span>
                <select value={selectedProspectDraft.workflow_status ?? selectedProspect.workflow_status ?? 'new'} onChange={(event) => handleSelectedProspectDraftChange('workflow_status', event.target.value)}>
                  <option value="new">new</option>
                  <option value="outreach_needed">outreach_needed</option>
                  <option value="duplicate_review">duplicate_review</option>
                  <option value="opt_out_review">opt_out_review</option>
                </select>
              </label>
              <label className="field">
                <span>D9 status</span>
                <select value={selectedProspectDraft.d9_connection_status ?? selectedProspect.d9_connection_status ?? 'unknown'} onChange={(event) => handleSelectedProspectDraftChange('d9_connection_status', event.target.value)}>
                  <option value="unknown">Unknown</option>
                  <option value="known_greek">Known Greek</option>
                  <option value="community_business">Community Business</option>
                  <option value="existing_member">Existing Member</option>
                  <option value="duplicate">Duplicate</option>
                  <option value="opt_out">Opt-out</option>
                </select>
              </label>
            </div>
            <div className="form-actions">
              <button type="button" className="primary-button" onClick={() => void handleUpdateSelectedProspect()}>Save changes</button>
              <button type="button" className="ghost-button" onClick={() => void handleOptOutSelectedProspect()}>Mark opt-out</button>
            </div>
          </div>

          <div className="panel-header compact"><h3>Link to canonical business</h3></div>
          <div className="header-inline-actions">
            <select aria-label="Link to canonical business" value={selectedProspectDraft.business_name ?? selectedProspect.business_name ?? ''} onChange={(event) => { const selected = businessOptions.find((option) => option.display_name === event.target.value); if (selected) { void handleLinkProspectToBusiness(selected.id) } }}>
              <option value="">No business selected</option>
              {businessOptions.map((business) => (
                <option key={business.id} value={business.display_name}>{business.display_name}</option>
              ))}
            </select>
          </div>

          <div className="panel-header compact"><h3>History</h3></div>
          <ul className="activity-feed">
            {selectedProspectHistory.length ? selectedProspectHistory.map((event) => (
              <li key={event.id}>{event.event_type} · {new Date(event.created_at).toLocaleString()}</li>
            )) : <li>No prospect events recorded yet.</li>}
          </ul>

          {selectedProspectOptOuts.length > 0 && (
            <>
              <div className="panel-header compact"><h3>Opt-out records</h3></div>
              <ul className="activity-feed">
                {selectedProspectOptOuts.map((optOut) => (
                  <li key={optOut.id}>{optOut.source} · {optOut.opt_out_reason || 'Opted out'} · {new Date(optOut.created_at).toLocaleString()}</li>
                ))}
              </ul>
            </>
          )}
        </div>
      )}
    </div>
  )
}

function BusinessesPage() {
  const [businesses, setBusinesses] = useState<Array<{ id: string; display_name: string; website?: string; industry?: string; d9_connection_status?: string; city?: string; state?: string; profile_completeness?: number }>>([])
  const [prospects, setProspects] = useState<Array<{ id: string; business_name?: string; display_name?: string; primary_contact_name?: string | null; email?: string | null }>>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [form, setForm] = useState({ display_name: '', website: '', industry: '', city: '', state: '', d9_connection_status: 'unknown' })
  const [selectedBusiness, setSelectedBusiness] = useState<{ id: string; display_name: string; website?: string; industry?: string; d9_connection_status?: string; city?: string; state?: string; profile_completeness?: number } | null>(null)

  const loadBusinesses = async () => {
    if (!supabase) {
      setBusinesses([])
      setLoading(false)
      return
    }

    const { data, error } = await supabase
      .from('businesses')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      setBusinesses([])
      setLoading(false)
      return
    }

    setBusinesses((data ?? []) as Array<{ id: string; display_name: string; website?: string; industry?: string; d9_connection_status?: string; city?: string; state?: string; profile_completeness?: number }>)
    setLoading(false)
  }

  const loadProspects = async () => {
    if (!supabase) return

    const { data } = await supabase.from('prospects').select('*').order('created_at', { ascending: false })
    setProspects((data ?? []) as Array<{ id: string; business_name?: string; display_name?: string; primary_contact_name?: string | null; email?: string | null }>)
  }

  useEffect(() => {
    void loadBusinesses()
    void loadProspects()
  }, [])

  const filteredBusinesses = businesses.filter((business) => {
    const matchesStatus = statusFilter === 'all' || (business.d9_connection_status ?? 'unknown') === statusFilter
    const haystack = [business.display_name, business.industry, business.city, business.state].join(' ').toLowerCase()
    const matchesSearch = !search.trim() || haystack.includes(search.trim().toLowerCase())
    return matchesStatus && matchesSearch
  })

  const linkedProspects = selectedBusiness ? prospects.filter((prospect) => {
    const target = selectedBusiness.display_name.toLowerCase()
    return [prospect.business_name, prospect.display_name].filter(Boolean).some((value) => (value ?? '').toLowerCase() === target)
  }) : []

  const profileCompletion = selectedBusiness ? Math.min(100, Math.max(0, Math.round(((selectedBusiness.display_name ? 25 : 0) + (selectedBusiness.website ? 25 : 0) + (selectedBusiness.industry ? 25 : 0) + (selectedBusiness.city || selectedBusiness.state ? 25 : 0))))) : 0

  const handleSaveBusiness = async (event: React.FormEvent) => {
    event.preventDefault()
    if (!supabase) return

    const payload = {
      display_name: form.display_name,
      website: form.website || null,
      industry: form.industry || null,
      city: form.city || null,
      state: form.state || null,
      d9_connection_status: form.d9_connection_status,
      profile_completeness: 0,
    }

    if (selectedBusiness) {
      await supabase.from('businesses').update(payload).eq('id', selectedBusiness.id)
    } else {
      await supabase.from('businesses').insert(payload)
    }

    setForm({ display_name: '', website: '', industry: '', city: '', state: '', d9_connection_status: 'unknown' })
    setSelectedBusiness(null)
    await loadBusinesses()
  }

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Discovery</p>
          <h1>Businesses</h1>
        </div>
      </div>

      <div className="panel">
        <div className="panel-header"><h2>Canonical business record</h2></div>
        <form className="stack-form" onSubmit={handleSaveBusiness}>
          <div className="form-grid two-col">
            <label className="field"><span>Display name</span><input value={form.display_name} onChange={(event) => setForm((current) => ({ ...current, display_name: event.target.value }))} /></label>
            <label className="field"><span>Website</span><input value={form.website} onChange={(event) => setForm((current) => ({ ...current, website: event.target.value }))} /></label>
            <label className="field"><span>Industry</span><input value={form.industry} onChange={(event) => setForm((current) => ({ ...current, industry: event.target.value }))} /></label>
            <label className="field"><span>Workflow status</span><select value={form.d9_connection_status} onChange={(event) => setForm((current) => ({ ...current, d9_connection_status: event.target.value }))}><option value="unknown">Unknown</option><option value="known_greek">Known Greek</option><option value="community_business">Community business</option><option value="existing_member">Existing member</option><option value="duplicate">Duplicate</option><option value="opt_out">Opt-out</option></select></label>
            <label className="field"><span>City</span><input value={form.city} onChange={(event) => setForm((current) => ({ ...current, city: event.target.value }))} /></label>
            <label className="field"><span>State</span><input value={form.state} onChange={(event) => setForm((current) => ({ ...current, state: event.target.value }))} /></label>
          </div>
          <div className="form-actions">
            <button type="submit" className="primary-button">{selectedBusiness ? 'Save business' : 'Create business'}</button>
            {selectedBusiness && <button type="button" className="ghost-button" onClick={() => setSelectedBusiness(null)}>Clear</button>}
          </div>
        </form>
      </div>

      <div className="panel">
        <div className="panel-header">
          <h2>Business roster</h2>
          <div className="header-inline-actions">
            <input aria-label="Search businesses" value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search businesses" />
            <select aria-label="Filter business status" value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)}>
              <option value="all">All statuses</option>
              <option value="unknown">Unknown</option>
              <option value="known_greek">Known Greek</option>
              <option value="community_business">Community business</option>
              <option value="existing_member">Existing member</option>
              <option value="duplicate">Duplicate</option>
              <option value="opt_out">Opt-out</option>
            </select>
          </div>
        </div>

        {loading ? <div className="panel empty-state"><h2>Loading businesses</h2><p>Restoring the canonical operating record set.</p></div> : filteredBusinesses.length ? (
          <div className="cards-grid equal-grid">
            {filteredBusinesses.map((business) => (
              <article key={business.id} className="panel card-panel" onClick={() => setSelectedBusiness(business)}>
                <div className="panel-header compact">
                  <h3>{business.display_name}</h3>
                  <span className="pill navy">{normalizeText(classifyD9Status({ d9ConnectionStatus: (business.d9_connection_status as 'known_greek' | 'unknown' | 'community_business' | 'existing_member' | 'duplicate' | 'opt_out') ?? 'unknown' })).replace(/_/g, ' ')}</span>
                </div>
                <dl className="meta-list">
                  <div><dt>Website</dt><dd>{normalizeWebsite(business.website)}</dd></div>
                  <div><dt>Industry</dt><dd>{business.industry || 'Not specified'}</dd></div>
                  <div><dt>Location</dt><dd>{[business.city, business.state].filter(Boolean).join(', ') || 'Not specified'}</dd></div>
                  <div><dt>Profile</dt><dd>{business.profile_completeness ?? 0}%</dd></div>
                </dl>
              </article>
            ))}
          </div>
        ) : (
          <div className="panel empty-state"><h2>No canonical businesses</h2><p>Business records will appear here after a verified record is created or imported.</p></div>
        )}
      </div>

      {selectedBusiness && (
        <div className="panel">
          <div className="panel-header"><h2>{selectedBusiness.display_name} · profile</h2><span className="pill navy">{profileCompletion}% complete</span></div>
          <div className="meta-list">
            <div><dt>Website</dt><dd>{normalizeWebsite(selectedBusiness.website)}</dd></div>
            <div><dt>Industry</dt><dd>{selectedBusiness.industry || 'Not specified'}</dd></div>
            <div><dt>Location</dt><dd>{[selectedBusiness.city, selectedBusiness.state].filter(Boolean).join(', ') || 'Not specified'}</dd></div>
            <div><dt>Routing</dt><dd>{getWorkflowRoutingLabel(selectedBusiness.d9_connection_status)}</dd></div>
          </div>

          <div className="panel-header compact"><h3>Linked prospects</h3></div>
          <ul className="activity-feed">
            {linkedProspects.length ? linkedProspects.map((prospect) => <li key={prospect.id}>{prospect.business_name || prospect.display_name || 'Prospect'} · {prospect.primary_contact_name || prospect.email || 'No contact'}</li>) : <li>No linked prospects yet.</li>}
          </ul>
        </div>
      )}
    </div>
  )
}

function NominationsPage() {
  const [nominations, setNominations] = useState<Array<{ id: string; nominated_business_name: string; source?: string; reason?: string; review_status?: string }>>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [form, setForm] = useState({
    nominated_business_name: '',
    source: 'public_submission',
    reason: '',
    nominator_name: '',
    nominator_email: '',
    city: '',
    state: '',
    website: '',
  })

  const loadNominations = async () => {
    if (!supabase) {
      setNominations([])
      setLoading(false)
      return
    }

    const { data, error } = await supabase.from('nominations').select('*').order('created_at', { ascending: false })
    if (error) {
      setNominations([])
      setLoading(false)
      return
    }

    setNominations((data ?? []) as Array<{ id: string; nominated_business_name: string; source?: string; reason?: string; review_status?: string }>)
    setLoading(false)
  }

  useEffect(() => { void loadNominations() }, [])

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault()
    if (!supabase || !form.nominated_business_name.trim()) return

    const normalized = normalizeNomination({
      nominatedBusinessName: form.nominated_business_name,
      primaryContactName: form.nominator_name,
      email: form.nominator_email,
      source: form.source,
      businessName: form.nominated_business_name,
      status: 'submitted',
      decisionReason: form.reason,
      phone: '',
      website: form.website,
      reportedD9Status: 'unknown',
    })

    if (!canProcessNomination({ status: normalized.status })) {
      return
    }

    const duplicateSignal = screenNominationForDuplicate({
      nominatedBusinessName: normalized.nominatedBusinessName,
      email: normalized.email,
      website: normalized.website,
      phone: normalized.phone,
    })

    setSaving(true)

    const payload = {
      nominated_business_name: normalized.nominatedBusinessName,
      source: normalized.source,
      reason: normalized.decisionReason || 'No reason supplied',
      nominator_name: normalized.primaryContactName || null,
      nominator_email: normalized.email || null,
      created_by: null,
      review_status: duplicateSignal.duplicate ? 'duplicate_review' : 'submitted',
      known_d9_connection: null,
      permission_status: duplicateSignal.duplicate ? 'pending' : 'pending',
    }

    const { data, error } = await supabase.from('nominations').insert(payload).select('id')

    setSaving(false)

    if (!error && data?.[0]?.id) {
      await supabase.from('workflow_events').insert({
        entity_type: 'nomination',
        entity_id: data[0].id,
        event_type: duplicateSignal.duplicate ? 'duplicate_review' : 'submitted',
        actor_user_id: null,
        details: { source: payload.source, reason: payload.reason, duplicate: duplicateSignal.duplicate },
      })
      setForm({
        nominated_business_name: '',
        source: 'public_submission',
        reason: '',
        nominator_name: '',
        nominator_email: '',
        city: '',
        state: '',
        website: '',
      })
      await loadNominations()
    }
  }

  const updateStatus = async (id: string, nextStatus: string) => {
    if (!supabase) return

    const next = nextStatus as any
    const allowed = validateNominationTransition('submitted', next)
    if (!allowed && next === 'rejected') {
      const reason = window.prompt('Provide the reason for rejection:') ?? ''
      if (!validateNominationDecision('rejected', reason)) {
        return
      }
    }

    if (next === 'rejected' && !validateNominationDecision('rejected', window.prompt('Provide the reason for rejection:') ?? '')) {
      return
    }

    await supabase.from('nominations').update({ review_status: next, updated_at: new Date().toISOString() }).eq('id', id)
    await loadNominations()
  }

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Discovery</p>
          <h1>Nominations</h1>
        </div>
        <button type="button" className="primary-button">Review nomination</button>
      </div>

      <div className="panel">
        <div className="panel-header"><h2>Submit nomination</h2></div>
        <form className="stack-form" onSubmit={handleSubmit}>
          <div className="form-grid two-col">
            <label className="field"><span>Business name</span><input aria-label="Business name" value={form.nominated_business_name} onChange={(event) => setForm((current) => ({ ...current, nominated_business_name: event.target.value }))} /></label>
            <label className="field"><span>Source</span><select aria-label="Source" value={form.source} onChange={(event) => setForm((current) => ({ ...current, source: event.target.value }))}><option value="public_submission">public_submission</option><option value="internal_staff">internal_staff</option><option value="social_media">social_media</option><option value="campaign_referral">campaign_referral</option><option value="partner_referral">partner_referral</option><option value="member_referral">member_referral</option><option value="manual_entry">manual_entry</option></select></label>
            <label className="field"><span>Nominator name</span><input aria-label="Nominator name" value={form.nominator_name} onChange={(event) => setForm((current) => ({ ...current, nominator_name: event.target.value }))} /></label>
            <label className="field"><span>Nominator email</span><input aria-label="Nominator email" type="email" value={form.nominator_email} onChange={(event) => setForm((current) => ({ ...current, nominator_email: event.target.value }))} /></label>
            <label className="field"><span>City</span><input aria-label="City" value={form.city} onChange={(event) => setForm((current) => ({ ...current, city: event.target.value }))} /></label>
            <label className="field"><span>State</span><input aria-label="State" value={form.state} onChange={(event) => setForm((current) => ({ ...current, state: event.target.value }))} /></label>
            <label className="field"><span>Website</span><input aria-label="Website" value={form.website} onChange={(event) => setForm((current) => ({ ...current, website: event.target.value }))} /></label>
            <label className="field wide"><span>Nomination reason</span><textarea aria-label="Nomination reason" value={form.reason} onChange={(event) => setForm((current) => ({ ...current, reason: event.target.value }))} rows={3} /></label>
          </div>
          <div className="form-actions"><button type="submit" className="primary-button" disabled={saving || !form.nominated_business_name.trim()}>{saving ? 'Submitting...' : 'Submit nomination'}</button></div>
        </form>
      </div>

      {loading ? (
        <div className="panel empty-state"><h2>Loading nominations</h2><p>Restoring the review queue.</p></div>
      ) : nominations.length ? (
        <div className="panel table-panel">
          <table className="data-table">
            <thead>
              <tr><th>Business</th><th>Source</th><th>Status</th><th>Reason</th><th>Action</th></tr>
            </thead>
            <tbody>
              {nominations.map((nomination) => (
                <tr key={nomination.id}>
                  <td>{nomination.nominated_business_name}</td>
                  <td>{nomination.source || '—'}</td>
                  <td><span className="pill neutral">{nomination.review_status || 'submitted'}</span></td>
                  <td>{nomination.reason || '—'}</td>
                  <td><div className="header-inline-actions"><button type="button" className="ghost-button" onClick={() => void updateStatus(nomination.id, 'under_review')}>Review</button><button type="button" className="ghost-button" onClick={() => void updateStatus(nomination.id, 'accepted')}>Accept</button></div></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="panel empty-state">
          <h2>No nominations yet</h2>
          <p>Incoming nominations will appear here once they are submitted or imported.</p>
        </div>
      )}
    </div>
  )
}

function ImportsPage() {
  const [fileName, setFileName] = useState('')
  const [rows, setRows] = useState<Array<{ rowNumber: number; values: string[]; valid: boolean; errors: string[] }>>([])
  const [preview, setPreview] = useState<{ total: number; valid: number; invalid: number; exact: number; probable: number; possible: number; new: number; warnings: string[] } | null>(null)
  const [status, setStatus] = useState('Awaiting file')
  const [confirming, setConfirming] = useState(false)

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    const text = await file.text()
    const rows = parseCsvRows(text)
    if (!rows.length) {
      setFileName(file.name)
      setRows([])
      setPreview(null)
      setStatus('No rows detected')
      return
    }

    const header = rows[0].header
    const required = ['business_name', 'email']
    const missingColumns = required.filter((column) => !header.includes(column))

    if (missingColumns.length) {
      setFileName(file.name)
      setRows([])
      setPreview({
        total: 0,
        valid: 0,
        invalid: 0,
        exact: 0,
        probable: 0,
        possible: 0,
        new: 0,
        warnings: [`Missing required columns: ${missingColumns.join(', ')}`],
      })
      setStatus('Missing required columns')
      return
    }

    const matches = rows.map(({ record, rowNumber, values }) => {
      const validation = validateCsvRow(record, required)
      return {
        rowNumber,
        values,
        valid: validation.valid,
        errors: validation.errors,
      }
    })

    const summary = buildImportSummary(matches.map((row) => ({ valid: row.valid, errors: row.errors, warnings: [] })))

    setFileName(file.name)
    setRows(matches)
    setPreview({
      total: summary.total,
      valid: summary.valid,
      invalid: summary.invalid,
      exact: summary.exact,
      probable: summary.probable,
      possible: summary.possible,
      new: summary.new,
      warnings: summary.warnings.length ? summary.warnings : ['CSV validation passed for all accepted rows.'],
    })

    const nextStatus = matches.some((row) => !row.valid) ? 'Validation issues found' : 'Ready to commit'
    setStatus(nextStatus)

    if (!matches.some((row) => !row.valid) && requiresConfirmation(matches)) {
      const idempotencyKey = createIdempotencyKey(file.name, text)
      setStatus(`Ready to commit · ${idempotencyKey.slice(0, 18)}...`)
    }
  }

  const validRows = rows.filter((row) => row.valid).length
  const invalidRows = rows.length - validRows

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Discovery</p>
          <h1>Imports</h1>
        </div>
      </div>

      <div className="panel">
        <div className="panel-header">
          <h2>CSV import</h2>
          <span className="pill navy">{status}</span>
        </div>

        <div className="stack-form">
          <label className="field">
            <span>Upload a CSV file</span>
            <input type="file" accept=".csv,text/csv" onChange={(event) => void handleFileUpload(event)} aria-label="Upload a CSV file" />
          </label>
          <a
            className="ghost-button"
            href={`data:text/csv;charset=utf-8,${encodeURIComponent(`${CSV_TEMPLATE_HEADERS.join(',')}\nNorthside Studio,hello@northside.com,+1 (415) 555-0105,https://northside.com,Seattle,WA,Leah Morris,public_submission` )}`}
            download="d9-import-template.csv"
          >
            Download CSV template
          </a>
        </div>

        {fileName ? (
          <div className="list-row">
            <div>
              <strong>{fileName}</strong>
              <span>{validRows} valid rows · {invalidRows} invalid rows</span>
            </div>
            <button type="button" className="primary-button" disabled={confirming || validRows === 0} onClick={() => setConfirming(true)}>{confirming ? 'Confirming...' : 'Confirm import'}</button>
          </div>
        ) : (
          <div className="panel empty-state">
            <h2>No import uploaded</h2>
            <p>Upload a CSV file to preview columns and validation results before committing.</p>
          </div>
        )}
      </div>

      {preview && (
        <div className="panel">
          <div className="panel-header"><h2>Import preview</h2></div>
          <div className="summary-row">
            <article className="metric-card tone-navy"><span className="metric-label">Total rows</span><strong>{preview.total}</strong><span className="metric-delta">Processed</span></article>
            <article className="metric-card tone-orange"><span className="metric-label">Valid</span><strong>{preview.valid}</strong><span className="metric-delta">Ready</span></article>
            <article className="metric-card tone-muted"><span className="metric-label">Invalid</span><strong>{preview.invalid}</strong><span className="metric-delta">Blocked</span></article>
            <article className="metric-card tone-navy"><span className="metric-label">New records</span><strong>{preview.new}</strong><span className="metric-delta">Unmatched</span></article>
          </div>
          <ul className="activity-feed">
            {preview.warnings.map((warning) => <li key={warning}>{warning}</li>)}
          </ul>
        </div>
      )}

      {rows.length > 0 && (
        <div className="panel table-panel">
          <table className="data-table">
            <thead>
              <tr><th>Row</th><th>Values</th><th>Status</th><th>Errors</th></tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.rowNumber}>
                  <td>{row.rowNumber}</td>
                  <td>{row.values.join(' | ') || '—'}</td>
                  <td><span className={`pill ${row.valid ? 'navy' : 'neutral'}`}>{row.valid ? 'Valid' : 'Invalid'}</span></td>
                  <td>{row.errors.length ? row.errors.join(', ') : '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

function DuplicateReviewPage() {
  const [duplicates, setDuplicates] = useState<Array<{ id: string; entity_type: string; match_reason: string; confidence_level: string; review_status?: string; field_conflicts?: string[]; decision?: string }>>([])
  const [loading, setLoading] = useState(true)
  const [statusFilter, setStatusFilter] = useState('all')

  const loadDuplicates = async () => {
    if (!supabase) {
      setDuplicates([])
      setLoading(false)
      return
    }

    const { data, error } = await supabase
      .from('possible_duplicates')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      setDuplicates([])
      setLoading(false)
      return
    }

    setDuplicates((data ?? []) as Array<{ id: string; entity_type: string; match_reason: string; confidence_level: string; review_status?: string; field_conflicts?: string[]; decision?: string }>)
    setLoading(false)
  }

  useEffect(() => {
    void loadDuplicates()
  }, [])

  const handleDuplicateDecision = async (duplicateId: string, decision: 'keep_separate' | 'merge' | 'dismiss' | 'manual_review') => {
    if (!supabase) return

    await supabase.from('possible_duplicates').update({
      review_status: decision,
      decision: decision,
      updated_at: new Date().toISOString(),
    }).eq('id', duplicateId)

    await loadDuplicates()
  }

  const filteredDuplicates = duplicates.filter((duplicate) => statusFilter === 'all' || (duplicate.review_status || 'pending') === statusFilter)

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Review</p>
          <h1>Duplicate Review</h1>
        </div>
        <select aria-label="Filter duplicate status" value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)}>
          <option value="all">All decisions</option>
          <option value="pending">Pending</option>
          <option value="manual_review">Manual review</option>
          <option value="merge">Merge</option>
          <option value="dismiss">Dismiss</option>
          <option value="keep_separate">Keep separate</option>
        </select>
      </div>
      {loading ? (
        <div className="panel empty-state"><h2>Loading duplicates</h2><p>Checking for matching records and review candidates.</p></div>
      ) : filteredDuplicates.length ? (
        <div className="panel table-panel">
          <table className="data-table">
            <thead>
              <tr><th>Entity</th><th>Match reason</th><th>Confidence</th><th>Conflicts</th><th>Status</th><th>Action</th></tr>
            </thead>
            <tbody>
              {filteredDuplicates.map((duplicate) => (
                <tr key={duplicate.id}>
                  <td>{duplicate.entity_type}</td>
                  <td>{duplicate.match_reason}</td>
                  <td><span className="pill neutral">{duplicate.confidence_level}</span></td>
                  <td>{(duplicate.field_conflicts ?? []).join(', ') || 'None detected'}</td>
                  <td><span className="pill navy">{duplicate.review_status || 'pending'}</span></td>
                  <td>
                    <div className="header-inline-actions">
                      <button type="button" className="ghost-button" onClick={() => void handleDuplicateDecision(duplicate.id, 'keep_separate')}>Keep separate</button>
                      <button type="button" className="ghost-button" onClick={() => void handleDuplicateDecision(duplicate.id, 'merge')}>Merge</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="panel empty-state">
          <h2>No duplicate review items</h2>
          <p>Potential duplicate matches will appear here after routing or import matching is run.</p>
        </div>
      )}
    </div>
  )
}

function CampaignPage() {
  const [campaigns, setCampaigns] = useState<Array<{ id: string; name: string; status: string; campaign_type?: string; source_channel?: string }>>([])
  const [loading, setLoading] = useState(true)
  const [name, setName] = useState('')
  const [status, setStatus] = useState('draft')
  const [saving, setSaving] = useState(false)

  const loadCampaigns = async () => {
    if (!supabase) {
      setCampaigns([])
      setLoading(false)
      return
    }

    const { data, error } = await supabase.from('campaigns').select('*').order('created_at', { ascending: false })
    if (error) {
      setCampaigns([])
      setLoading(false)
      return
    }

    setCampaigns((data ?? []) as Array<{ id: string; name: string; status: string; campaign_type?: string; source_channel?: string }>)
    setLoading(false)
  }

  useEffect(() => { void loadCampaigns() }, [])

  const handleCreateCampaign = async (event: React.FormEvent) => {
    event.preventDefault()
    if (!supabase || !name.trim()) return

    setSaving(true)
    const { error } = await supabase.from('campaigns').insert({ name: name.trim(), status, campaign_type: 'discovery', source_channel: 'manual' })
    setSaving(false)

    if (!error) {
      setName('')
      setStatus('draft')
      await loadCampaigns()
    }
  }

  const updateCampaignStatus = async (campaignId: string, nextStatus: string) => {
    if (!supabase) return

    await supabase.from('campaigns').update({ status: nextStatus, updated_at: new Date().toISOString() }).eq('id', campaignId)
    await loadCampaigns()
  }

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <p className="eyebrow">Discovery foundation</p>
          <h1>Campaigns</h1>
        </div>
      </div>

      <div className="panel">
        <div className="panel-header"><h2>Create campaign</h2></div>
        <form className="stack-form" onSubmit={handleCreateCampaign}>
          <div className="form-grid two-col">
            <label className="field">
              <span>Campaign name</span>
              <input value={name} onChange={(event) => setName(event.target.value)} placeholder="Neighborhood outreach" />
            </label>
            <label className="field">
              <span>Status</span>
              <select value={status} onChange={(event) => setStatus(event.target.value)}>
                <option value="draft">draft</option>
                <option value="scheduled">scheduled</option>
                <option value="active">active</option>
                <option value="paused">paused</option>
                <option value="completed">completed</option>
                <option value="archived">archived</option>
              </select>
            </label>
          </div>
          <div className="form-actions">
            <button type="submit" className="primary-button" disabled={saving || !name.trim()}>{saving ? 'Saving…' : 'Save campaign'}</button>
          </div>
        </form>
      </div>

      {loading ? (
        <div className="panel empty-state"><h2>Loading campaigns</h2><p>Restoring the active campaign portfolio.</p></div>
      ) : campaigns.length ? (
        <div className="panel table-panel">
          <table className="data-table">
            <thead>
              <tr><th>Name</th><th>Type</th><th>Status</th><th>Action</th></tr>
            </thead>
            <tbody>
              {campaigns.map((campaign) => (
                <tr key={campaign.id}>
                  <td>{campaign.name}</td>
                  <td>{campaign.campaign_type || 'discovery'}</td>
                  <td><span className="pill navy">{campaign.status}</span></td>
                  <td><div className="header-inline-actions"><button type="button" className="ghost-button" onClick={() => void updateCampaignStatus(campaign.id, 'active')}>Activate</button><button type="button" className="ghost-button" onClick={() => void updateCampaignStatus(campaign.id, 'paused')}>Pause</button></div></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="panel empty-state">
          <h2>No campaign records</h2>
          <p>Campaign records will appear here once discovery outreach is launched.</p>
        </div>
      )}
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
