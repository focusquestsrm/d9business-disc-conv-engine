import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { AppRoot } from './App'

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
})
