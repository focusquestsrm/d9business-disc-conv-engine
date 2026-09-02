import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { AppRoot } from './App'

describe('App', () => {
  it('renders the dashboard and a future milestone placeholder page', () => {
    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <AppRoot />
      </MemoryRouter>,
    )

    expect(screen.getByRole('heading', { name: /dashboard/i })).toBeInTheDocument()

    fireEvent.click(screen.getByRole('link', { name: /D9 Verification/i }))

    expect(screen.getByRole('heading', { level: 1, name: /D9 Verification/i })).toBeInTheDocument()
    expect(screen.getByText(/not yet active/i)).toBeInTheDocument()
  })
})
