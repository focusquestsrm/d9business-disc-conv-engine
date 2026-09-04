export type QuickCaptureFormValues = {
  prospectType: string
  socialPlatform: string
  socialHandle: string
  socialProfileUrl: string
  websiteUrl: string
  firstName: string
  lastName: string
  businessName: string
  email: string
  phone: string
  suspectedAffiliation: string
  city: string
  state: string
  sourceType: string
  sourceName: string
  notes: string
  followUpPriority: string
  assignedTo: string
}

export type QuickCaptureErrors = Partial<Record<keyof QuickCaptureFormValues, string>>

const socialPlatformMap: Record<string, string> = {
  instagram: 'Instagram',
  facebook: 'Facebook',
  linkedin: 'LinkedIn',
  tiktok: 'TikTok',
  x: 'X',
  twitter: 'X',
  website: 'Website',
  other: 'Other',
  unknown: 'Unknown',
}

export function normalizeText(value: string | null | undefined): string {
  return (value ?? '').trim()
}

export function normalizeEmail(value: string | null | undefined): string {
  return normalizeText(value).toLowerCase()
}

export function normalizePhone(value: string | null | undefined): string {
  return normalizeText(value).replace(/[^\d+]/g, '')
}

export function normalizeUrl(value: string | null | undefined): string {
  const text = normalizeText(value)
  if (!text) return ''
  if (/^https?:\/\//i.test(text) || /^www\./i.test(text)) return text
  return `https://${text}`
}

export function detectSocialPlatformFromUrl(url: string): string | null {
  const candidate = normalizeUrl(url)
  if (!candidate) return null

  try {
    const parsed = new URL(candidate)
    const host = parsed.hostname.toLowerCase()

    if (host.includes('instagram.com')) return 'Instagram'
    if (host.includes('facebook.com')) return 'Facebook'
    if (host.includes('linkedin.com')) return 'LinkedIn'
    if (host.includes('tiktok.com')) return 'TikTok'
    if (host.includes('x.com') || host.includes('twitter.com')) return 'X'
    if (host.includes('www.') || host.includes('.')) return 'Website'
  } catch {
    return null
  }

  return null
}

export function extractSocialHandleFromUrl(url: string, platform: string): string | null {
  const candidate = normalizeUrl(url)
  if (!candidate) return null

  try {
    const parsed = new URL(candidate)
    const host = parsed.hostname.toLowerCase()
    const pathname = parsed.pathname.replace(/^\/+|\/+$/g, '')

    if (platform === 'Instagram' && host.includes('instagram.com')) {
      return pathname.split('/')[0] || null
    }
    if (platform === 'Facebook' && host.includes('facebook.com')) {
      return pathname.split('/')[0] || null
    }
    if (platform === 'LinkedIn' && host.includes('linkedin.com')) {
      return pathname.split('/')[0] || null
    }
    if (platform === 'TikTok' && host.includes('tiktok.com')) {
      return pathname.split('/')[0] || null
    }
    if ((platform === 'X' || platform === 'Twitter') && (host.includes('x.com') || host.includes('twitter.com'))) {
      return pathname.split('/')[0] || null
    }
  } catch {
    return null
  }

  return null
}

export function inferPlatformAndHandleFromUrl(url: string): { platform: string; handle: string } | null {
  const platform = detectSocialPlatformFromUrl(url)
  if (!platform) return null

  const handle = extractSocialHandleFromUrl(url, platform)
  if (!handle) return null

  return { platform, handle }
}

export function hasMeaningfulIdentifier(values: QuickCaptureFormValues): boolean {
  const identifiers = [
    values.socialHandle,
    values.socialProfileUrl,
    values.email,
    values.phone,
    [values.firstName, values.lastName].join(' ').trim(),
    values.businessName,
  ]

  return identifiers.some((value) => normalizeText(value).length > 0)
}

function isValidHttpUrl(value: string): boolean {
  const candidate = normalizeText(value)
  if (!candidate) return false

  try {
    const normalized = /^https?:\/\//i.test(candidate) ? candidate : `https://${candidate}`
    const parsed = new URL(normalized)
    return Boolean(parsed.hostname) && parsed.hostname.includes('.')
  } catch {
    return false
  }
}

export function validateQuickCaptureForm(values: QuickCaptureFormValues): QuickCaptureErrors {
  const errors: QuickCaptureErrors = {}

  const cleanedEmail = normalizeEmail(values.email)
  const cleanedPhone = normalizePhone(values.phone)
  const cleanedWebsite = normalizeUrl(values.websiteUrl)

  if (!hasMeaningfulIdentifier(values)) {
    errors.socialHandle = 'Add at least one meaningful identifier such as a handle, URL, email, phone, name, or business name.'
  }

  if (values.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(cleanedEmail)) {
    errors.email = 'Enter a valid email address.'
  }

  if (values.phone && !/^\+?[0-9()\-\s]{7,20}$/.test(cleanedPhone)) {
    errors.phone = 'Enter a valid phone number.'
  }

  if (values.socialProfileUrl && !isValidHttpUrl(values.socialProfileUrl)) {
    errors.socialProfileUrl = 'Enter a valid social or profile URL.'
  }

  if (values.websiteUrl && !isValidHttpUrl(cleanedWebsite)) {
    errors.websiteUrl = 'Enter a valid website URL.'
  }

  return errors
}

export function deriveWorkflowStatus(values: QuickCaptureFormValues): 'new' | 'incomplete' | 'outreach_needed' | 'duplicate_review' | 'opt_out_review' {
  const hasContact = Boolean(normalizeText(values.email) || normalizeText(values.phone))
  const hasHandleOrUrl = Boolean(normalizeText(values.socialHandle) || normalizeText(values.socialProfileUrl))
  const hasName = Boolean(normalizeText(values.firstName) || normalizeText(values.lastName))
  const hasBusinessName = Boolean(normalizeText(values.businessName))

  if (hasHandleOrUrl && !hasContact && !hasName && !hasBusinessName) {
    return 'outreach_needed'
  }

  if (hasContact || hasName || hasBusinessName || hasHandleOrUrl) {
    return 'outreach_needed'
  }

  return 'new'
}

export function normalizeQuickCapturePayload(values: QuickCaptureFormValues) {
  const platform = socialPlatformMap[normalizeText(values.socialPlatform).toLowerCase()] ?? 'Unknown'
  const handle = normalizeText(values.socialHandle)
  const profileUrl = normalizeUrl(values.socialProfileUrl)
  const websiteUrl = normalizeUrl(values.websiteUrl)
  const firstName = normalizeText(values.firstName)
  const lastName = normalizeText(values.lastName)
  const businessName = normalizeText(values.businessName)
  const email = normalizeEmail(values.email)
  const phone = normalizePhone(values.phone)
  const fullName = [firstName, lastName].filter(Boolean).join(' ')

  return {
    prospectType: normalizeText(values.prospectType) || 'Unknown',
    socialPlatform: platform,
    socialHandle: handle,
    socialProfileUrl: profileUrl,
    websiteUrl,
    firstName,
    lastName,
    fullName,
    businessName,
    displayName: businessName || fullName || handle || 'Quick Capture Prospect',
    email,
    phone,
    city: normalizeText(values.city),
    state: normalizeText(values.state),
    sourceType: normalizeText(values.sourceType) || 'Other',
    sourceName: normalizeText(values.sourceName),
    notes: normalizeText(values.notes),
    followUpPriority: normalizeText(values.followUpPriority) || 'Normal',
    assignedTo: normalizeText(values.assignedTo),
  }
}
