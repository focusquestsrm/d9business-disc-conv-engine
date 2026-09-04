import ExcelJS from 'exceljs'
import { buildVerificationExportColumns, validateVerificationResult } from './membershipVerification'

export const VERIFICATION_WORKBOOK_SHEET_NAME = 'Verification Request'
export const VERIFICATION_INSTRUCTIONS_SHEET_NAME = 'Instructions'
export const MAX_VERIFICATION_WORKBOOK_BYTES = 5 * 1024 * 1024
export const MAX_VERIFICATION_WORKBOOK_ROWS = 2000

export type VerificationWorkbookRow = {
  batchId: string
  verificationCaseId: string
  recordId: string
  legalFirstName: string
  legalMiddleName: string
  legalLastName: string
  suffix: string
  preferredName: string
  email: string
  phone: string
  claimedOrganization: string
  chapterName: string
  chapterType: string
  chapterCity: string
  chapterState: string
  collegeOrUniversity: string
  initiationYear: string
  initiationSeason: string
  membershipCardNumber: string
  lineName: string
  lineNumber: string
  organizationResult: string
  organizationReason: string
  organizationNotes: string
  verifiedBy: string
  verificationDate: string
}

export type VerificationWorkbookPreview = {
  validRows: number
  invalidRows: number
  conflictingRows: number
  alreadyProcessedRows: number
  acceptedRows: VerificationWorkbookRow[]
  rejectedRows: VerificationWorkbookRow[]
}

const requiredHeaders = buildVerificationExportColumns()
const expectedWorkbookSheets = new Set([VERIFICATION_WORKBOOK_SHEET_NAME, VERIFICATION_INSTRUCTIONS_SHEET_NAME])

const toCellText = (value: unknown): string => {
  if (value === null || value === undefined) return ''
  if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean' || value instanceof Date) {
    return String(value).trim()
  }
  if (typeof value === 'object' && 'result' in (value as Record<string, unknown>)) {
    const nested = value as { result?: unknown; richText?: unknown }
    if (typeof nested.result === 'string') return nested.result.trim()
    if (Array.isArray(nested.richText)) {
      return nested.richText.map((part) => (typeof part === 'object' && part && 't' in part ? String((part as { t?: unknown }).t ?? '') : '')).join('').trim()
    }
  }
  return ''
}

const normalizeRow = (values: unknown[]): Partial<VerificationWorkbookRow> => ({
  batchId: toCellText(values[0]),
  verificationCaseId: toCellText(values[1]),
  recordId: toCellText(values[2]),
  legalFirstName: toCellText(values[3]),
  legalMiddleName: toCellText(values[4]),
  legalLastName: toCellText(values[5]),
  suffix: toCellText(values[6]),
  preferredName: toCellText(values[7]),
  email: toCellText(values[8]),
  phone: toCellText(values[9]),
  claimedOrganization: toCellText(values[10]),
  chapterName: toCellText(values[11]),
  chapterType: toCellText(values[12]),
  chapterCity: toCellText(values[13]),
  chapterState: toCellText(values[14]),
  collegeOrUniversity: toCellText(values[15]),
  initiationYear: toCellText(values[16]),
  initiationSeason: toCellText(values[17]),
  membershipCardNumber: toCellText(values[18]),
  lineName: toCellText(values[19]),
  lineNumber: toCellText(values[20]),
  organizationResult: toCellText(values[21]),
  organizationReason: toCellText(values[22]),
  organizationNotes: toCellText(values[23]),
  verifiedBy: toCellText(values[24]),
  verificationDate: toCellText(values[25]),
})

export function buildVerificationWorkbook(rows: Array<Partial<VerificationWorkbookRow>> = []): ExcelJS.Workbook {
  const workbook = new ExcelJS.Workbook()
  workbook.creator = 'D9Network'
  workbook.created = new Date()
  workbook.modified = new Date()

  const worksheet = workbook.addWorksheet(VERIFICATION_WORKBOOK_SHEET_NAME)
  worksheet.views = [{ state: 'frozen', ySplit: 1 }]
  worksheet.columns = requiredHeaders.map((headerName, index) => ({
    header: headerName,
    key: `column_${index}`,
    width: Math.max(16, Math.min(32, headerName.length + 4)),
  }))

  for (const row of rows) {
    worksheet.addRow([
      row.batchId ?? '',
      row.verificationCaseId ?? '',
      row.recordId ?? '',
      row.legalFirstName ?? '',
      row.legalMiddleName ?? '',
      row.legalLastName ?? '',
      row.suffix ?? '',
      row.preferredName ?? '',
      row.email ?? '',
      row.phone ?? '',
      row.claimedOrganization ?? '',
      row.chapterName ?? '',
      row.chapterType ?? '',
      row.chapterCity ?? '',
      row.chapterState ?? '',
      row.collegeOrUniversity ?? '',
      row.initiationYear ?? '',
      row.initiationSeason ?? '',
      row.membershipCardNumber ?? '',
      row.lineName ?? '',
      row.lineNumber ?? '',
      row.organizationResult ?? '',
      row.organizationReason ?? '',
      row.organizationNotes ?? '',
      row.verifiedBy ?? '',
      row.verificationDate ?? '',
    ])
  }

  worksheet.getRow(1).font = { bold: true }
  worksheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFD9EAF7' } }

  const instructions = workbook.addWorksheet(VERIFICATION_INSTRUCTIONS_SHEET_NAME)
  instructions.columns = [{ header: 'Instructions', key: 'instruction', width: 120 }]
  instructions.addRow(['Verification workbook export for D9 organization review.'])
  instructions.addRow(['Use the controlled Organization Result values: VERIFIED, UNABLE_TO_VERIFY, REJECTED, NEEDS_FOLLOW_UP.'])
  instructions.addRow(['Batch ID, Verification Case ID, and D9Network Record ID must remain unchanged.'])
  instructions.addRow(['Do not include internal-only assignment metadata, personal notes, or confidential audit data.'])
  instructions.addRow(['Return only the approved verification request sheet and do not evaluate formulas.'])

  return workbook
}

export async function exportVerificationWorkbook(rows: Array<Partial<VerificationWorkbookRow>> = []): Promise<Buffer> {
  const workbook = buildVerificationWorkbook(rows)
  return Buffer.from(await workbook.xlsx.writeBuffer())
}

export async function parseVerificationWorkbook(
  buffer: ArrayBuffer | Uint8Array | Buffer,
  options: { batchId?: string; organization?: string; alreadyProcessedCaseIds?: Set<string> } = {},
): Promise<VerificationWorkbookPreview & { acceptedRows: VerificationWorkbookRow[]; rejectedRows: VerificationWorkbookRow[] }> {
  const bytes = buffer instanceof ArrayBuffer ? new Uint8Array(buffer) : buffer instanceof Uint8Array ? buffer : new Uint8Array(buffer as ArrayBufferLike)
  if (bytes.byteLength > MAX_VERIFICATION_WORKBOOK_BYTES) {
    throw new Error(`Workbook exceeds the ${MAX_VERIFICATION_WORKBOOK_BYTES} byte limit.`)
  }

  const workbook = new ExcelJS.Workbook()
  await workbook.xlsx.load(bytes as any)

  if (workbook.worksheets.length > 2 || workbook.worksheets.some((sheet) => !expectedWorkbookSheets.has(sheet.name))) {
    throw new Error('Workbook contains unexpected sheets or is missing the required verification sheets.')
  }

  const sheet = workbook.getWorksheet(VERIFICATION_WORKBOOK_SHEET_NAME)
  if (!sheet) {
    throw new Error('Workbook does not contain the required Verification Request sheet.')
  }

  const allRows = sheet.getSheetValues()
  const headerRowIndex = allRows.findIndex((row) => Array.isArray(row) && row.some((value) => value === 'Batch ID'))
  if (headerRowIndex < 0) {
    throw new Error('Workbook does not contain the required Batch ID header.')
  }

  const headerRow = allRows[headerRowIndex] as unknown[]
  const normalizedHeaders = headerRow.map((value) => String(value ?? '').trim())
  if (normalizedHeaders.length !== requiredHeaders.length || !requiredHeaders.every((headerName, index) => normalizedHeaders[index] === headerName)) {
    throw new Error('Workbook headers do not match the approved verification request template.')
  }

  const parsedRows: VerificationWorkbookRow[] = []
  let rowNumber = 0

  for (let i = headerRowIndex + 1; i < allRows.length; i += 1) {
    const row = allRows[i]
    if (!Array.isArray(row) || row.every((value) => String(value ?? '').trim() === '')) {
      continue
    }

    rowNumber += 1
    if (rowNumber > MAX_VERIFICATION_WORKBOOK_ROWS) {
      throw new Error(`Workbook exceeds the ${MAX_VERIFICATION_WORKBOOK_ROWS} row limit.`)
    }

    const cellValues = row as unknown[]
    const cellRow = sheet.getRow(i + 1)
    let hasFormulaOrHyperlink = false
    cellRow.eachCell((cell) => {
      const cellValue = cell.value as unknown
      const valueRecord = typeof cellValue === 'object' && cellValue !== null ? (cellValue as Record<string, unknown>) : null
      if (cell.type === ExcelJS.ValueType.Formula || (valueRecord && ('formula' in valueRecord || 'hyperlink' in valueRecord))) {
        hasFormulaOrHyperlink = true
      }
      if (cell.hyperlink) {
        hasFormulaOrHyperlink = true
      }
    })
    if (hasFormulaOrHyperlink) {
      throw new Error('Workbook contains formulas or hyperlinks and cannot be processed.')
    }

    if (cellValues.length < requiredHeaders.length) {
      throw new Error(`Malformed row at index ${i + 1}: expected ${requiredHeaders.length} columns but found ${cellValues.length}.`)
    }

    const normalizedRow = normalizeRow(cellValues)
    if (!normalizedRow.verificationCaseId && !normalizedRow.batchId && !normalizedRow.recordId && !normalizedRow.claimedOrganization) {
      continue
    }

    parsedRows.push({
      batchId: normalizedRow.batchId ?? '',
      verificationCaseId: normalizedRow.verificationCaseId ?? '',
      recordId: normalizedRow.recordId ?? '',
      legalFirstName: normalizedRow.legalFirstName ?? '',
      legalMiddleName: normalizedRow.legalMiddleName ?? '',
      legalLastName: normalizedRow.legalLastName ?? '',
      suffix: normalizedRow.suffix ?? '',
      preferredName: normalizedRow.preferredName ?? '',
      email: normalizedRow.email ?? '',
      phone: normalizedRow.phone ?? '',
      claimedOrganization: normalizedRow.claimedOrganization ?? '',
      chapterName: normalizedRow.chapterName ?? '',
      chapterType: normalizedRow.chapterType ?? '',
      chapterCity: normalizedRow.chapterCity ?? '',
      chapterState: normalizedRow.chapterState ?? '',
      collegeOrUniversity: normalizedRow.collegeOrUniversity ?? '',
      initiationYear: normalizedRow.initiationYear ?? '',
      initiationSeason: normalizedRow.initiationSeason ?? '',
      membershipCardNumber: normalizedRow.membershipCardNumber ?? '',
      lineName: normalizedRow.lineName ?? '',
      lineNumber: normalizedRow.lineNumber ?? '',
      organizationResult: normalizedRow.organizationResult ?? '',
      organizationReason: normalizedRow.organizationReason ?? '',
      organizationNotes: normalizedRow.organizationNotes ?? '',
      verifiedBy: normalizedRow.verifiedBy ?? '',
      verificationDate: normalizedRow.verificationDate ?? '',
    })
  }

  return prepareVerificationWorkbookRows(parsedRows, options.batchId ?? '', options.organization ?? '', options.alreadyProcessedCaseIds ?? new Set())
}

export function prepareVerificationWorkbookRows(
  rows: Array<Partial<VerificationWorkbookRow>>,
  batchId: string,
  organization: string,
  alreadyProcessedCaseIds: Set<string>,
): VerificationWorkbookPreview & { acceptedRows: VerificationWorkbookRow[]; rejectedRows: VerificationWorkbookRow[] } {
  const acceptedRows: VerificationWorkbookRow[] = []
  const rejectedRows: VerificationWorkbookRow[] = []
  let validRows = 0
  let invalidRows = 0
  let conflictingRows = 0
  let alreadyProcessedRows = 0
  const seenInCurrentPreview = new Set<string>()

  for (const rawRow of rows) {
    const row = {
      batchId: rawRow.batchId ?? '',
      verificationCaseId: rawRow.verificationCaseId ?? '',
      recordId: rawRow.recordId ?? '',
      legalFirstName: rawRow.legalFirstName ?? '',
      legalMiddleName: rawRow.legalMiddleName ?? '',
      legalLastName: rawRow.legalLastName ?? '',
      suffix: rawRow.suffix ?? '',
      preferredName: rawRow.preferredName ?? '',
      email: rawRow.email ?? '',
      phone: rawRow.phone ?? '',
      claimedOrganization: rawRow.claimedOrganization ?? '',
      chapterName: rawRow.chapterName ?? '',
      chapterType: rawRow.chapterType ?? '',
      chapterCity: rawRow.chapterCity ?? '',
      chapterState: rawRow.chapterState ?? '',
      collegeOrUniversity: rawRow.collegeOrUniversity ?? '',
      initiationYear: rawRow.initiationYear ?? '',
      initiationSeason: rawRow.initiationSeason ?? '',
      membershipCardNumber: rawRow.membershipCardNumber ?? '',
      lineName: rawRow.lineName ?? '',
      lineNumber: rawRow.lineNumber ?? '',
      organizationResult: rawRow.organizationResult ?? '',
      organizationReason: rawRow.organizationReason ?? '',
      organizationNotes: rawRow.organizationNotes ?? '',
      verifiedBy: rawRow.verifiedBy ?? '',
      verificationDate: rawRow.verificationDate ?? '',
    }

    const caseId = row.verificationCaseId.trim()
    const validId = Boolean(caseId) && Boolean(row.recordId.trim())
    const validBatch = row.batchId === batchId
    const validOrg = row.claimedOrganization.trim().toLowerCase() === organization.trim().toLowerCase()
    const allowedResult = row.organizationResult ? validateVerificationResult(row.organizationResult) : false
    const reasonRequired = ['UNABLE_TO_VERIFY', 'REJECTED', 'NEEDS_FOLLOW_UP'].includes(row.organizationResult ?? '')
    const reasonPresent = Boolean((row.organizationReason ?? '').trim())

    if (caseId && (alreadyProcessedCaseIds.has(caseId) || seenInCurrentPreview.has(caseId))) {
      alreadyProcessedRows += 1
      rejectedRows.push(row)
      continue
    }

    if (!validId || !allowedResult || (reasonRequired && !reasonPresent)) {
      invalidRows += 1
      rejectedRows.push(row)
      continue
    }

    if (!validBatch || !validOrg) {
      conflictingRows += 1
      invalidRows += 1
      rejectedRows.push(row)
      continue
    }

    seenInCurrentPreview.add(caseId)
    validRows += 1
    acceptedRows.push(row)
  }

  return {
    validRows,
    invalidRows,
    conflictingRows,
    alreadyProcessedRows,
    acceptedRows,
    rejectedRows,
  }
}
