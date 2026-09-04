import { describe, expect, it } from 'vitest'
import {
  MAX_VERIFICATION_WORKBOOK_BYTES,
  MAX_VERIFICATION_WORKBOOK_ROWS,
  buildVerificationWorkbook,
  parseVerificationWorkbook,
} from './verificationWorkbook'

const makeValidRow = (overrides: Record<string, string> = {}) => ({
  batchId: 'B-100',
  verificationCaseId: 'VC-1',
  recordId: 'R-1',
  legalFirstName: 'Aisha',
  legalMiddleName: '',
  legalLastName: 'Sanders',
  suffix: '',
  preferredName: '',
  email: 'aisha@example.com',
  phone: '5551234567',
  claimedOrganization: 'Alpha Phi Alpha',
  chapterName: 'Lambda',
  chapterType: 'Undergraduate',
  chapterCity: 'Atlanta',
  chapterState: 'GA',
  collegeOrUniversity: 'Georgia State University',
  initiationYear: '2018',
  initiationSeason: 'Spring',
  membershipCardNumber: 'M-100',
  lineName: 'Lambda Line',
  lineNumber: '5',
  organizationResult: 'VERIFIED',
  organizationReason: 'Confirmed',
  organizationNotes: '',
  verifiedBy: 'reviewer_1',
  verificationDate: '2026-09-04',
  ...overrides,
})

describe('verification workbook validation', () => {
  it('supports a real ExcelJS in-memory export/import round trip', async () => {
    const rows = [makeValidRow()]
    const workbook = buildVerificationWorkbook(rows)
    const buffer = await workbook.xlsx.writeBuffer()

    const preview = await parseVerificationWorkbook(buffer, {
      batchId: 'B-100',
      organization: 'Alpha Phi Alpha',
      alreadyProcessedCaseIds: new Set(),
    })

    expect(preview.validRows).toBe(1)
    expect(preview.acceptedRows).toHaveLength(1)
    expect(preview.acceptedRows[0]?.verificationCaseId).toBe('VC-1')
    expect(preview.rejectedRows).toHaveLength(0)
    console.log('WORKBOOK_ROUND_TRIP_PASS')
  })

  it('rejects wrong sheet names or headers before import commit', async () => {
    const workbook = buildVerificationWorkbook([makeValidRow()])
    const sheet = workbook.getWorksheet('Verification Request')!
    sheet.name = 'Wrong Sheet'
    sheet.getRow(1).values = ['Wrong', 'Header', 'Values']

    const buffer = await workbook.xlsx.writeBuffer()

    await expect(parseVerificationWorkbook(buffer, { batchId: 'B-100', organization: 'Alpha Phi Alpha', alreadyProcessedCaseIds: new Set() })).rejects.toThrow(/required|headers|Verification Request|unexpected/i)
  })

  it('enforces file-size and row-count limits', async () => {
    await expect(parseVerificationWorkbook(new Uint8Array(MAX_VERIFICATION_WORKBOOK_BYTES + 1), { batchId: 'B-100', organization: 'Alpha Phi Alpha' })).rejects.toThrow(/byte limit/i)

    const oversizedWorkbook = buildVerificationWorkbook(Array.from({ length: MAX_VERIFICATION_WORKBOOK_ROWS + 1 }, (_, index) => makeValidRow({ verificationCaseId: `VC-${index + 1}`, recordId: `R-${index + 1}` })))
    const buffer = await oversizedWorkbook.xlsx.writeBuffer()
    await expect(parseVerificationWorkbook(buffer, { batchId: 'B-100', organization: 'Alpha Phi Alpha', alreadyProcessedCaseIds: new Set() })).rejects.toThrow(/row limit/i)
  })

  it('rejects unexpected extra worksheets', async () => {
    const workbook = buildVerificationWorkbook([makeValidRow()])
    workbook.addWorksheet('Unexpected Sheet')
    const buffer = await workbook.xlsx.writeBuffer()

    await expect(parseVerificationWorkbook(buffer, { batchId: 'B-100', organization: 'Alpha Phi Alpha', alreadyProcessedCaseIds: new Set() })).rejects.toThrow(/unexpected sheets|required verification request/i)
  })

  it('rejects malformed rows with missing required cells', async () => {
    const workbook = buildVerificationWorkbook([makeValidRow()])
    const sheet = workbook.getWorksheet('Verification Request')!
    sheet.addRow(['B-100', 'VC-2', 'R-2'])
    const buffer = await workbook.xlsx.writeBuffer()

    await expect(parseVerificationWorkbook(buffer, { batchId: 'B-100', organization: 'Alpha Phi Alpha', alreadyProcessedCaseIds: new Set() })).rejects.toThrow(/Malformed row|expected/i)
  })

  it('rejects formula cells and hyperlink cells', async () => {
    const workbook = buildVerificationWorkbook([makeValidRow()])
    const sheet = workbook.getWorksheet('Verification Request')!
    sheet.getCell('A2').value = { formula: '1+1', result: 2 }
    sheet.getCell('B2').value = { text: 'bad', hyperlink: 'https://example.com' }

    const buffer = await workbook.xlsx.writeBuffer()

    await expect(parseVerificationWorkbook(buffer, { batchId: 'B-100', organization: 'Alpha Phi Alpha', alreadyProcessedCaseIds: new Set() })).rejects.toThrow(/formula|hyperlink/i)
  })

  it('detects batch and organization conflicts during preview', async () => {
    const workbook = buildVerificationWorkbook([
      makeValidRow({ verificationCaseId: 'VC-1', recordId: 'R-1', batchId: 'B-100' }),
      makeValidRow({ verificationCaseId: 'VC-2', recordId: 'R-2', batchId: 'B-999', claimedOrganization: 'Alpha Phi Alpha' }),
    ])
    const buffer = await workbook.xlsx.writeBuffer()

    const preview = await parseVerificationWorkbook(buffer, { batchId: 'B-100', organization: 'Alpha Phi Alpha', alreadyProcessedCaseIds: new Set() })

    expect(preview.validRows).toBe(1)
    expect(preview.invalidRows).toBe(1)
    expect(preview.acceptedRows[0]?.verificationCaseId).toBe('VC-1')
    expect(preview.rejectedRows[0]?.verificationCaseId).toBe('VC-2')
  })

  it('prepares a valid-row-only commit payload and blocks already processed rows', async () => {
    const workbook = buildVerificationWorkbook([
      makeValidRow({ verificationCaseId: 'VC-1', recordId: 'R-1', organizationResult: 'VERIFIED', organizationReason: 'Confirmed' }),
      makeValidRow({ verificationCaseId: 'VC-2', recordId: 'R-2', organizationResult: 'REJECTED', organizationReason: 'No match' }),
      makeValidRow({ verificationCaseId: 'VC-1', recordId: 'R-1', organizationResult: 'VERIFIED', organizationReason: 'Duplicate' }),
    ])
    const buffer = await workbook.xlsx.writeBuffer()

    const preview = await parseVerificationWorkbook(buffer, {
      batchId: 'B-100',
      organization: 'Alpha Phi Alpha',
      alreadyProcessedCaseIds: new Set(['VC-2']),
    })

    expect(preview.validRows).toBe(1)
    expect(preview.alreadyProcessedRows).toBe(1)
    expect(preview.acceptedRows).toHaveLength(1)
    expect(preview.acceptedRows[0]?.verificationCaseId).toBe('VC-1')
    expect(preview.invalidRows).toBe(1)
    console.log('IMPORT_ROUND_TRIP_PASS')
  })
})
