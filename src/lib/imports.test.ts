import { describe, expect, it } from 'vitest'
import { CSV_TEMPLATE_HEADERS, buildImportSummary, createIdempotencyKey, parseCsvRows, requiresConfirmation, validateCsvRow } from './imports'

describe('csv import validation', () => {
  it('accepts valid CSV rows', () => {
    const row = validateCsvRow({ business_name: 'Northside Studio', email: 'hello@northside.com', phone: '+1 415 555 0105', website: 'https://northside.com', city: 'Seattle', state: 'WA' })
    expect(row.valid).toBe(true)
    expect(row.errors).toHaveLength(0)
  })

  it('flags malformed rows and missing required data', () => {
    const row = validateCsvRow({ business_name: '', email: 'bad-email', state: 'ZZ' })
    expect(row.valid).toBe(false)
    expect(row.errors).toEqual(expect.arrayContaining(['Missing business name', 'Invalid email format', 'State code not recognized']))
  })

  it('normalizes common column aliases before validation', () => {
    const rows = parseCsvRows('name,email\nNorthside Studio,hello@northside.com')
    expect(rows.length).toBe(1)
    expect(rows[0].header).toEqual(['business_name', 'email'])
    expect(rows[0].record.business_name).toBe('Northside Studio')
  })

  it('builds a summary for import results', () => {
    const summary = buildImportSummary([
      { valid: true, errors: [], warnings: [] },
      { valid: false, errors: ['Missing business name'], warnings: ['Needs review'] },
    ])

    expect(summary.total).toBe(2)
    expect(summary.valid).toBe(1)
    expect(summary.invalid).toBe(1)
  })

  it('requires explicit confirmation for rows ready to import', () => {
    expect(requiresConfirmation([{ valid: true }, { valid: false }])).toBe(true)
    expect(requiresConfirmation([{ valid: false }, { valid: false }])).toBe(false)
  })

  it('creates an idempotency key', () => {
    const key = createIdempotencyKey('sample.csv', 'name,email\nNorthside Studio,hello@northside.com')
    expect(key).toContain('sample.csv')
    expect(key.length).toBeGreaterThan(20)
  })

  it('exposes a downloadable template header set', () => {
    expect(CSV_TEMPLATE_HEADERS).toEqual(expect.arrayContaining(['business_name', 'email']))
  })
})
