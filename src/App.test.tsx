import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { AppRoot } from './App'
import {
  classifyDuplicateMatch,
  getWorkflowRoute,
  isTransitionAllowed,
} from './lib/workflow'
import {
  deriveWorkflowStatus,
  validateQuickCaptureForm,
} from './lib/quickCapture'

const { mockSupabase } = vi.hoisted(() => ({
  mockSupabase: {
    auth: {
      getSession: vi.fn(),
      onAuthStateChange: vi.fn(() => ({ data: { subscription: { unsubscribe: vi.fn() } } })),
      signInWithPassword: vi.fn(),
      signOut: vi.fn(),
    },
    from: vi.fn(),
  },
}))

vi.mock('./lib/supabaseClient', () => ({
  supabase: mockSupabase,
  supabaseStatusMessage: 'Supabase connection configured and ready for authenticated session management.',
  isSupabaseConfigured: true,
}))

describe('workflow engine', () => {
  it('routes reported Greek affiliations to verification and blocks unsafe transitions', () => {
    const result = getWorkflowRoute('unknown', 'known_greek', { reportedGreek: true })
    expect(result.allowed).toBe(true)
    expect(result.requiresVerification).toBe(true)
    expect(result.route).toBe('verification')

    expect(isTransitionAllowed('opt_out', 'unknown', { renewedConsent: false })).toBe(false)
    expect(isTransitionAllowed('opt_out', 'unknown', { renewedConsent: true })).toBe(true)
  })

  it('keeps unknown records in outreach follow-up and prevents invalid duplicates', () => {
    const unknownRoute = getWorkflowRoute('unknown', 'unknown', {})
    expect(unknownRoute.route).toBe('outreach')
    expect(isTransitionAllowed('unknown', 'duplicate', {})).toBe(true)
    expect(isTransitionAllowed('duplicate', 'unknown', {})).toBe(false)
  })

  it('classifies duplicate candidate strength and requires review for uncertain matches', () => {
    expect(classifyDuplicateMatch(['email', 'phone'], [])).toBe('exact')
    expect(classifyDuplicateMatch(['business_name', 'city'], ['email'])).toBe('probable')
    expect(classifyDuplicateMatch(['city'], ['email', 'phone'])).toBe('possible')
    expect(classifyDuplicateMatch([], [])).toBe('no_match')
  })
})

describe('quick capture', () => {
  beforeEach(() => {
    mockSupabase.auth.getSession.mockReset()
    mockSupabase.auth.onAuthStateChange.mockReset()
    mockSupabase.auth.signInWithPassword.mockReset()
    mockSupabase.auth.signOut.mockReset()
    mockSupabase.from.mockReset()

    mockSupabase.auth.onAuthStateChange.mockReturnValue({
      data: { subscription: { unsubscribe: vi.fn() } },
    })
  })

  it('accepts social handle, profile URL, and name-only entries and routes them through outreach', () => {
    const handleValues = {
      prospectType: 'Business',
      socialPlatform: 'Instagram',
      socialHandle: '@northsidecreative',
      socialProfileUrl: '',
      websiteUrl: '',
      firstName: '',
      lastName: '',
      businessName: '',
      email: '',
      phone: '',
      suspectedAffiliation: '',
      city: '',
      state: '',
      sourceType: 'social',
      sourceName: 'Instagram',
      notes: '',
      followUpPriority: 'high',
      assignedTo: '',
    }

    const profileUrlValues = {
      ...handleValues,
      socialHandle: '',
      socialProfileUrl: 'https://linkedin.com/in/leahmorgan',
    }

    const nameOnlyValues = {
      ...handleValues,
      socialHandle: '',
      socialProfileUrl: '',
      firstName: 'Leah',
      lastName: 'Morgan',
      businessName: 'Northside Studio',
      email: '',
      phone: '',
    }

    expect(validateQuickCaptureForm(handleValues)).toEqual({})
    expect(validateQuickCaptureForm(profileUrlValues)).toEqual({})
    expect(validateQuickCaptureForm(nameOnlyValues)).toEqual({})
    expect(deriveWorkflowStatus(handleValues)).toBe('outreach_needed')
    expect(deriveWorkflowStatus(nameOnlyValues)).toBe('outreach_needed')
  })

  it('blocks invalid email, phone, and profile URL values before save', async () => {
    mockSupabase.auth.getSession.mockResolvedValue({
      data: { session: { user: { id: 'user-123', email: 'admin@example.com', user_metadata: { full_name: 'Tina Morgan' } } } },
      error: null,
    })

    mockSupabase.from.mockImplementation((table: string) => {
      if (table === 'user_role_assignments') {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              eq: vi.fn(async () => ({ data: [{ role_id: 'role-123' }], error: null })),
            })),
          })),
        }
      }

      if (table === 'roles') {
        return {
          select: vi.fn(() => ({
            in: vi.fn(async () => ({ data: [{ code: 'platform_admin', display_name: 'Platform Administrator' }], error: null })),
          })),
        }
      }

      return { select: vi.fn() }
    })

    render(
      <MemoryRouter initialEntries={['/quick-capture']}>
        <AppRoot />
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByLabelText(/social handle/i)).toBeInTheDocument()
    })

    fireEvent.change(screen.getByLabelText(/social handle/i), { target: { value: '@northside' } })
    fireEvent.change(screen.getByLabelText(/email/i), { target: { value: 'not-an-email' } })
    fireEvent.change(screen.getByLabelText(/phone/i), { target: { value: 'not-a-number' } })
    fireEvent.change(screen.getByLabelText(/social profile url/i), { target: { value: 'bad-url' } })
    fireEvent.click(screen.getByRole('button', { name: /save quick capture/i }))

    await waitFor(() => {
      expect(screen.getByText(/enter a valid email address/i)).toBeInTheDocument()
      expect(screen.getByText(/enter a valid phone number/i)).toBeInTheDocument()
      expect(screen.getByText(/enter a valid social or profile url/i)).toBeInTheDocument()
    })
  })

  it('blocks duplicate submission and surfaces the duplicate review message', async () => {
    mockSupabase.auth.getSession.mockResolvedValue({
      data: { session: { user: { id: 'user-123', email: 'admin@example.com', user_metadata: { full_name: 'Tina Morgan' } } } },
      error: null,
    })

    mockSupabase.from.mockImplementation((table: string) => {
      if (table === 'user_role_assignments') {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              eq: vi.fn(async () => ({ data: [{ role_id: 'role-123' }], error: null })),
            })),
          })),
        }
      }

      if (table === 'roles') {
        return {
          select: vi.fn(() => ({
            in: vi.fn(async () => ({ data: [{ code: 'platform_admin', display_name: 'Platform Administrator' }], error: null })),
          })),
        }
      }

      if (table === 'prospects') {
        return {
          select: vi.fn(() => ({
            or: vi.fn(async () => ({ data: [{ id: 'duplicate-1', business_name: 'Northside Studio' }], error: null })),
          })),
          insert: vi.fn(async () => ({ data: [{ id: 'p-90' }], error: null })),
        }
      }

      return { select: vi.fn() }
    })

    render(
      <MemoryRouter initialEntries={['/quick-capture']}>
        <AppRoot />
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByLabelText(/social handle/i)).toBeInTheDocument()
    })

    fireEvent.change(screen.getByLabelText(/social handle/i), { target: { value: '@northside' } })
    fireEvent.change(screen.getByLabelText(/business name/i), { target: { value: 'Northside Studio' } })
    fireEvent.change(screen.getByLabelText(/email/i), { target: { value: 'hello@northside.com' } })
    fireEvent.click(screen.getByRole('button', { name: /save quick capture/i }))

    await waitFor(() => {
      expect(screen.getByText(/duplicate prospect detected/i)).toBeInTheDocument()
    })
  })
})

describe('App', () => {
  beforeEach(() => {
    mockSupabase.auth.getSession.mockReset()
    mockSupabase.auth.onAuthStateChange.mockReset()
    mockSupabase.auth.signInWithPassword.mockReset()
    mockSupabase.auth.signOut.mockReset()
    mockSupabase.from.mockReset()

    mockSupabase.auth.onAuthStateChange.mockReturnValue({
      data: { subscription: { unsubscribe: vi.fn() } },
    })
  })

  it('redirects unauthenticated users to the login page', async () => {
    mockSupabase.auth.getSession.mockResolvedValue({ data: { session: null }, error: null })

    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <AppRoot />
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByRole('heading', { name: /welcome back/i })).toBeInTheDocument()
    })
  })

  it('keeps navigation sections collapsed until the active route expands only its parent section', async () => {
    mockSupabase.auth.getSession.mockResolvedValue({
      data: {
        session: {
          user: {
            id: 'user-123',
            email: 'admin@example.com',
            user_metadata: { full_name: 'Tina Morgan' },
          },
        },
      },
      error: null,
    })

    mockSupabase.from.mockImplementation((table: string) => {
      if (table === 'user_role_assignments') {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              eq: vi.fn(async () => ({ data: [{ role_id: 'role-123' }], error: null })),
            })),
          })),
        }
      }

      if (table === 'roles') {
        return {
          select: vi.fn(() => ({
            in: vi.fn(async () => ({ data: [{ code: 'platform_admin', display_name: 'Platform Administrator' }], error: null })),
          })),
        }
      }

      return { select: vi.fn() }
    })

    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <AppRoot />
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /overview/i })).toHaveAttribute('aria-expanded', 'true')
    })

    const navRegion = screen.getByRole('navigation', { name: /navigation groups/i })

    expect(screen.getByRole('button', { name: /discovery/i })).toHaveAttribute('aria-expanded', 'false')
    expect(screen.getByRole('button', { name: /social engagement/i })).toHaveAttribute('aria-expanded', 'false')
    expect(within(navRegion).getByRole('link', { name: /dashboard/i })).toBeInTheDocument()
    expect(within(navRegion).queryByRole('link', { name: /quick capture/i })).not.toBeInTheDocument()
  })

  it('supports accordion toggling with visible chevrons and keyboard activation', async () => {
    mockSupabase.auth.getSession.mockResolvedValue({
      data: {
        session: {
          user: {
            id: 'user-123',
            email: 'admin@example.com',
            user_metadata: { full_name: 'Tina Morgan' },
          },
        },
      },
      error: null,
    })

    mockSupabase.from.mockImplementation((table: string) => {
      if (table === 'user_role_assignments') {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              eq: vi.fn(async () => ({ data: [{ role_id: 'role-123' }], error: null })),
            })),
          })),
        }
      }

      if (table === 'roles') {
        return {
          select: vi.fn(() => ({
            in: vi.fn(async () => ({ data: [{ code: 'platform_admin', display_name: 'Platform Administrator' }], error: null })),
          })),
        }
      }

      return { select: vi.fn() }
    })

    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <AppRoot />
      </MemoryRouter>,
    )

    const discoveryToggle = await screen.findByRole('button', { name: /discovery/i })
    const navRegion = screen.getByRole('navigation', { name: /navigation groups/i })

    expect(discoveryToggle).toHaveAttribute('aria-controls')
    expect(discoveryToggle).toHaveTextContent('▸')

    fireEvent.keyDown(discoveryToggle, { key: 'Enter', code: 'Enter' })
    await waitFor(() => {
      expect(discoveryToggle).toHaveAttribute('aria-expanded', 'true')
    })

    expect(within(navRegion).getByRole('link', { name: /quick capture/i })).toBeInTheDocument()

    fireEvent.click(discoveryToggle)
    await waitFor(() => {
      expect(discoveryToggle).toHaveAttribute('aria-expanded', 'false')
    })
    expect(within(navRegion).queryByRole('link', { name: /quick capture/i })).not.toBeInTheDocument()
  })

  it('keeps the quick-capture route standalone and without the dashboard sidebar for authorized users', async () => {
    mockSupabase.auth.getSession.mockResolvedValue({
      data: {
        session: {
          user: {
            id: 'user-123',
            email: 'admin@example.com',
            user_metadata: { full_name: 'Tina Morgan' },
          },
        },
      },
      error: null,
    })

    mockSupabase.from.mockImplementation((table: string) => {
      if (table === 'user_role_assignments') {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              eq: vi.fn(async () => ({ data: [{ role_id: 'role-123' }], error: null })),
            })),
          })),
        }
      }

      if (table === 'roles') {
        return {
          select: vi.fn(() => ({
            in: vi.fn(async () => ({ data: [{ code: 'platform_admin', display_name: 'Platform Administrator' }], error: null })),
          })),
        }
      }

      return { select: vi.fn() }
    })

    render(
      <MemoryRouter initialEntries={['/quick-capture']}>
        <AppRoot />
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByRole('heading', { name: /quick capture/i })).toBeInTheDocument()
    })

    expect(screen.queryByRole('navigation', { name: /main navigation/i })).not.toBeInTheDocument()
  })

  it('routes the New Prospect CTA to the standalone quick capture flow', async () => {
    mockSupabase.auth.getSession.mockResolvedValue({
      data: {
        session: {
          user: {
            id: 'user-123',
            email: 'admin@example.com',
            user_metadata: { full_name: 'Tina Morgan' },
          },
        },
      },
      error: null,
    })

    mockSupabase.from.mockImplementation((table: string) => {
      if (table === 'user_role_assignments') {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              eq: vi.fn(async () => ({ data: [{ role_id: 'role-123' }], error: null })),
            })),
          })),
        }
      }

      if (table === 'roles') {
        return {
          select: vi.fn(() => ({
            in: vi.fn(async () => ({ data: [{ code: 'platform_admin', display_name: 'Platform Administrator' }], error: null })),
          })),
        }
      }

      return { select: vi.fn() }
    })

    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <AppRoot />
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByRole('link', { name: /new prospect/i })).toHaveAttribute('href', '/quick-capture')
    })
  })

  it('loads the active platform admin role for a signed in user', async () => {
    mockSupabase.auth.getSession.mockResolvedValue({
      data: {
        session: {
          user: {
            id: 'user-123',
            email: 'admin@example.com',
            user_metadata: { full_name: 'Tina Morgan' },
          },
        },
      },
      error: null,
    })

    mockSupabase.from.mockImplementation((table: string) => {
      if (table === 'user_role_assignments') {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              eq: vi.fn(async () => ({ data: [{ role_id: 'role-123' }], error: null })),
            })),
          })),
        }
      }

      if (table === 'roles') {
        return {
          select: vi.fn(() => ({
            in: vi.fn(async () => ({ data: [{ code: 'platform_admin', display_name: 'Platform Administrator' }], error: null })),
          })),
        }
      }

      return { select: vi.fn() }
    })

    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <AppRoot />
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByText(/platform administrator/i)).toBeInTheDocument()
    })
  })

  it('renders a quick prospect intake form and prevents duplicate submission', async () => {
    mockSupabase.auth.getSession.mockResolvedValue({
      data: {
        session: {
          user: {
            id: 'user-123',
            email: 'admin@example.com',
            user_metadata: { full_name: 'Tina Morgan' },
          },
        },
      },
      error: null,
    })

    mockSupabase.from.mockImplementation((table: string) => {
      if (table === 'user_role_assignments') {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              eq: vi.fn(async () => ({ data: [{ role_id: 'role-123' }], error: null })),
            })),
          })),
        }
      }

      if (table === 'roles') {
        return {
          select: vi.fn(() => ({
            in: vi.fn(async () => ({ data: [{ code: 'platform_admin', display_name: 'Platform Administrator' }], error: null })),
          })),
        }
      }

      if (table === 'prospects') {
        return {
          select: vi.fn(() => ({
            or: vi.fn(async () => ({ data: [], error: null })),
            order: vi.fn(async () => ({ data: [], error: null })),
          })),
          insert: vi.fn(() => ({
            select: vi.fn(async () => ({ data: [{ id: 'p-1' }], error: null })),
          })),
        }
      }

      if (table === 'businesses') {
        return {
          select: vi.fn(() => ({
            order: vi.fn(async () => ({ data: [], error: null })),
          })),
        }
      }

      if (table === 'campaigns') {
        return { select: vi.fn(() => ({ count: 0, data: [] })) }
      }

      if (table === 'nominations') {
        return { select: vi.fn(() => ({ count: 0, data: [] })) }
      }

      if (table === 'workflow_events') {
        return {
          insert: vi.fn(async () => ({ data: [{ id: 'we-1' }], error: null })),
        }
      }

      return { select: vi.fn() }
    })

    render(
      <MemoryRouter initialEntries={['/prospects']}>
        <AppRoot />
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByLabelText(/business name/i)).toBeInTheDocument()
    })

    fireEvent.change(screen.getByLabelText(/business name/i), { target: { value: 'Northside Studio' } })
    fireEvent.change(screen.getByLabelText(/primary contact/i), { target: { value: 'Leah Morris' } })
    fireEvent.change(screen.getByLabelText(/email/i), { target: { value: 'leah@northsidestudio.com' } })
    fireEvent.click(screen.getByRole('button', { name: /save prospect/i }))

    await waitFor(() => {
      expect(mockSupabase.from).toHaveBeenCalledWith('prospects')
    })
  })

  it('shows the empty canonical business state when no businesses exist', async () => {
    mockSupabase.auth.getSession.mockResolvedValue({
      data: {
        session: {
          user: { id: 'user-123', email: 'admin@example.com', user_metadata: { full_name: 'Tina Morgan' } },
        },
      },
      error: null,
    })

    mockSupabase.from.mockImplementation((table: string) => {
      if (table === 'user_role_assignments') {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              eq: vi.fn(async () => ({ data: [{ role_id: 'role-123' }], error: null })),
            })),
          })),
        }
      }

      if (table === 'roles') {
        return {
          select: vi.fn(() => ({
            in: vi.fn(async () => ({ data: [{ code: 'platform_admin', display_name: 'Platform Administrator' }], error: null })),
          })),
        }
      }

      if (table === 'businesses') {
        return {
          select: vi.fn(() => ({
            order: vi.fn(async () => ({ data: [], error: null })),
          })),
        }
      }

      if (table === 'prospects') {
        return {
          select: vi.fn(() => ({
            order: vi.fn(async () => ({ data: [], error: null })),
          })),
        }
      }

      if (table === 'campaigns') {
        return { select: vi.fn(() => ({ order: vi.fn(async () => ({ data: [], error: null })) })) }
      }

      if (table === 'nominations') {
        return { select: vi.fn(() => ({ order: vi.fn(async () => ({ data: [], error: null })) })) }
      }

      return { select: vi.fn() }
    })

    render(
      <MemoryRouter initialEntries={['/businesses']}>
        <AppRoot />
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByText(/No canonical businesses/i)).toBeInTheDocument()
    })
  })

  it('validates uploaded CSV rows before import commit', async () => {
    mockSupabase.auth.getSession.mockResolvedValue({
      data: {
        session: {
          user: { id: 'user-123', email: 'admin@example.com', user_metadata: { full_name: 'Tina Morgan' } },
        },
      },
      error: null,
    })

    mockSupabase.from.mockImplementation((table: string) => {
      if (table === 'user_role_assignments') {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              eq: vi.fn(async () => ({ data: [{ role_id: 'role-123' }], error: null })),
            })),
          })),
        }
      }

      if (table === 'roles') {
        return {
          select: vi.fn(() => ({
            in: vi.fn(async () => ({ data: [{ code: 'platform_admin', display_name: 'Platform Administrator' }], error: null })),
          })),
        }
      }

      if (table === 'imports') {
        return { select: vi.fn() }
      }

      return { select: vi.fn() }
    })

    render(
      <MemoryRouter initialEntries={['/imports']}>
        <AppRoot />
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByText(/platform administrator/i)).toBeInTheDocument()
    })

    const file = new File(['name,email,city\nNorthside Studio,hello@northside.com,Seattle\nBad Entry,not-an-email,'], 'sample.csv', { type: 'text/csv' })
    const input = screen.getByLabelText(/upload a csv file/i)

    await waitFor(() => {
      fireEvent.change(input, { target: { files: [file] } })
    })

    await waitFor(() => {
      expect(screen.getByText(/Validation issues found/i)).toBeInTheDocument()
    })
  })

  it('supports nomination submission and review actions', async () => {
    mockSupabase.auth.getSession.mockResolvedValue({
      data: {
        session: {
          user: {
            id: 'user-123',
            email: 'reviewer@example.com',
            user_metadata: { full_name: 'Jordan Park' },
          },
        },
      },
      error: null,
    })

    mockSupabase.from.mockImplementation((table: string) => {
      if (table === 'user_role_assignments') {
        return {
          select: vi.fn(() => ({
            eq: vi.fn(() => ({
              eq: vi.fn(async () => ({ data: [{ role_id: 'role-456' }], error: null })),
            })),
          })),
        }
      }

      if (table === 'roles') {
        return {
          select: vi.fn(() => ({
            in: vi.fn(async () => ({ data: [{ code: 'reviewer', display_name: 'Reviewer' }], error: null })),
          })),
        }
      }

      if (table === 'nominations') {
        return {
          select: vi.fn(() => ({
            order: vi.fn(async () => ({ data: [{ id: 'n-1', nominated_business_name: 'Sierra Studio', source: 'public_submission', reason: 'Strong D9 fit', review_status: 'submitted' }], error: null })),
          })),
          insert: vi.fn(() => ({
            select: vi.fn(async () => ({ data: [{ id: 'n-2' }], error: null })),
          })),
          update: vi.fn(() => ({
            eq: vi.fn(async () => ({ data: [{ id: 'n-1' }], error: null })),
          })),
        }
      }

      if (table === 'workflow_events') {
        return {
          insert: vi.fn(async () => ({ data: [{ id: 'we-1' }], error: null })),
        }
      }

      return { select: vi.fn() }
    })

    render(
      <MemoryRouter initialEntries={['/nominations']}>
        <AppRoot />
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(screen.getByRole('heading', { name: /nominations/i })).toBeInTheDocument()
    })

    fireEvent.change(screen.getByLabelText(/business name/i), { target: { value: 'Northside Studio' } })
    fireEvent.change(screen.getByLabelText(/source/i), { target: { value: 'public_submission' } })
    fireEvent.change(screen.getByLabelText(/nomination reason/i), { target: { value: 'Strong community referral' } })
    fireEvent.click(screen.getByRole('button', { name: /submit nomination/i }))

    await waitFor(() => {
      expect(mockSupabase.from).toHaveBeenCalledWith('nominations')
    })

    expect(screen.getByRole('button', { name: /review nomination/i })).toBeInTheDocument()
  })
})
