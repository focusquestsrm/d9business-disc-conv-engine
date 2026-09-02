import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { AppRoot } from './App'

describe('App', () => {
  it('renders the dashboard and the quick intake page', () => {
    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <AppRoot />
      </MemoryRouter>,
    )

    expect(screen.getByRole('heading', { name: /dashboard/i })).toBeInTheDocument()

    fireEvent.click(screen.getByRole('link', { name: /intake/i }))

    expect(screen.getByRole('heading', { name: /quick prospect intake/i })).toBeInTheDocument()
    expect(screen.getByLabelText(/business or person name/i)).toBeInTheDocument()
  })
})
