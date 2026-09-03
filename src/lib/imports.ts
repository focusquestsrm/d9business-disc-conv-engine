export type ImportValidationResult = {
  valid: boolean
  errors: string[]
  warnings: string[]
  normalizedRow: Record<string, string>
}

export const CSV_TEMPLATE_HEADERS = ['business_name', 'email', 'phone', 'website', 'city', 'state', 'contact_name', 'source']

export const normalizeCsvCell = (value: string | undefined) => (value ?? '').trim()

export const normalizeCsvHeader = (header: string) => {
  const normalized = normalizeCsvCell(header).toLowerCase().replace(/[^a-z0-9_]+/g, '_')
  const aliasMap: Record<string, string> = {
    name: 'business_name',
    company: 'business_name',
    business: 'business_name',
    business_name: 'business_name',
    company_name: 'business_name',
    contact: 'contact_name',
    contact_name: 'contact_name',
    primary_contact: 'contact_name',
    contact_email: 'email',
    email_address: 'email',
    e_mail: 'email',
    phone_number: 'phone',
    mobile: 'phone',
    website_url: 'website',
    url: 'website',
    source_name: 'source',
    lead_source: 'source',
    lead_source_name: 'source',
  }

  return aliasMap[normalized] ?? normalized
}

export const parseCsvRows = (raw: string) => {
  const rows = raw.split(/\r?\n/).filter((line) => line.trim().length > 0)
  if (!rows.length) return []

  const header = rows[0].split(',').map((cell) => normalizeCsvHeader(cell))
  return rows.slice(1).map((line, index) => {
    const parts = line.split(',')
    const values = parts.map((cell) => normalizeCsvCell(cell))
    const record: Record<string, string> = {}
    header.forEach((column, columnIndex) => {
      record[column] = values[columnIndex] ?? ''
    })

    return {
      rowNumber: index + 2,
      header,
      record,
      values,
    }
  })
}

export const validateCsvRow = (row: Record<string, string>, required = ['business_name', 'email']): ImportValidationResult => {
  const errors: string[] = []
  const warnings: string[] = []

  const businessName = normalizeCsvCell(row.business_name)
  const email = normalizeCsvCell(row.email)
  const phone = normalizeCsvCell(row.phone)
  const website = normalizeCsvCell(row.website)
  const state = normalizeCsvCell(row.state).toUpperCase()

  if (!businessName) errors.push('Missing business name')
  if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) errors.push('Invalid email format')
  if (phone && !/^\+?[0-9()\-\s]{7,}$/.test(phone)) warnings.push('Phone format may need review')
  if (website && !/^https?:\/\//i.test(website)) warnings.push('Website should include a protocol')
  if (state && !['AL', 'AK', 'AZ', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'HI', 'IA', 'ID', 'IL', 'IN', 'KS', 'KY', 'LA', 'MA', 'MD', 'ME', 'MI', 'MN', 'MO', 'MS', 'MT', 'NC', 'ND', 'NE', 'NH', 'NJ', 'NM', 'NV', 'NY', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VA', 'VT', 'WA', 'WI', 'WV', 'WY'].includes(state)) {
    errors.push('State code not recognized')
  }

  const valid = required.every((field) => Boolean(normalizeCsvCell(row[field]))) && errors.length === 0
  return {
    valid,
    errors,
    warnings,
    normalizedRow: Object.fromEntries(Object.entries(row).map(([key, value]) => [key, normalizeCsvCell(value)])),
  }
}

export const buildImportSummary = (rows: Array<{ valid: boolean; errors: string[]; warnings: string[] }>) => {
  const total = rows.length
  const valid = rows.filter((row) => row.valid).length
  const invalid = total - valid
  const exact = rows.filter((row) => row.valid).length

  return {
    total,
    valid,
    invalid,
    exact,
    probable: 0,
    possible: 0,
    new: valid,
    warnings: rows.flatMap((row) => row.warnings).slice(0, 10),
    errors: rows.flatMap((row) => row.errors),
  }
}

export const requiresConfirmation = (rows: Array<{ valid: boolean }>) => rows.some((row) => row.valid)

export const createIdempotencyKey = (filename: string, content: string) => {
  const hash = Array.from(content).reduce((accumulator, character) => {
    const code = character.charCodeAt(0).toString(16).padStart(2, '0')
    return `${accumulator}${code}`
  }, '')

  return `${filename}:${hash.slice(0, 32)}`
}
