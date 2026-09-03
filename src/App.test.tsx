import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { AppRoot } from './App'
import {
  classifyDuplicateMatch,
  getWorkflowRoute,
  isTransitionAllowed,
} from './lib/workflow'

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
})
