import crypto from 'node:crypto'

const DEDUPE_CACHE = new Map()

function readJsonBody(event) {
  if (!event.body) return {}
  try {
    if (event.isBase64Encoded) {
      return JSON.parse(Buffer.from(event.body, 'base64').toString('utf8'))
    }
    return JSON.parse(event.body)
  } catch {
    return {}
  }
}

function getMetaConfig() {
  const appId = process.env.META_APP_ID ?? null
  const appSecret = process.env.META_APP_SECRET ?? null
  const accessToken = process.env.META_ACCESS_TOKEN ?? null
  const webhookSecret = process.env.META_WEBHOOK_SECRET ?? null
  const verifyToken = process.env.META_VERIFY_TOKEN ?? null

  return {
    appId,
    appSecret,
    accessToken,
    webhookSecret,
    verifyToken,
    configured: Boolean(appId || accessToken || webhookSecret || verifyToken),
  }
}

function buildResponse(statusCode, payload) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff',
    },
    body: JSON.stringify(payload),
  }
}

function normalizeProviderState(status) {
  if (!status) return 'configuration_required'
  const normalized = String(status).trim().toLowerCase().replace(/[^a-z_]/g, '_')
  const safeStates = ['disconnected', 'configuration_required', 'connected', 'permission_limited', 'token_expiring', 'reconnect_required', 'suspended', 'provider_error']
  return safeStates.includes(normalized) ? normalized : 'provider_error'
}

function requireServerActor(event) {
  const userId = event.headers?.['x-d9-user-id'] ?? event.headers?.['X-D9-User-Id'] ?? event.headers?.['x-auth-user-id'] ?? event.headers?.['X-Auth-User-Id']
  const role = event.headers?.['x-d9-role'] ?? event.headers?.['X-D9-Role']
  if (!userId || !role) {
    return { ok: false, reason: 'Authenticated server actor and role are required for publishing requests.' }
  }
  return { ok: true, userId, role }
}

function getSafeStatusPayload() {
  const config = getMetaConfig()
  const hasRequiredConfig = Boolean(config.appId && config.accessToken && config.webhookSecret)

  if (!config.configured) {
    return {
      ok: true,
      state: 'configuration_required',
      requiresConfiguration: true,
      lastSuccessfulProviderCheck: null,
      reason: 'Meta is not configured in the secure deployment environment.',
      safeMetadata: { provider: 'meta', mode: 'server_side_only', connectionStatus: 'configuration_required' },
      destinations: [],
    }
  }

  if (!hasRequiredConfig) {
    return {
      ok: true,
      state: 'disconnected',
      requiresConfiguration: false,
      lastSuccessfulProviderCheck: null,
      reason: 'Meta credentials are present but the secure provider connection is incomplete.',
      safeMetadata: { provider: 'meta', mode: 'server_side_only', connectionStatus: 'disconnected' },
      destinations: [],
    }
  }

  return {
    ok: true,
    state: 'disconnected',
    requiresConfiguration: false,
    lastSuccessfulProviderCheck: null,
    reason: 'Meta credentials are configured but live connectivity has not been verified in this repository boundary.',
    safeMetadata: { provider: 'meta', mode: 'server_side_only', connectionStatus: 'disconnected' },
    destinations: [],
  }
}

function getSafeDestinations() {
  const status = getSafeStatusPayload()
  if (status.state === 'configuration_required' || status.state === 'disconnected') {
    return []
  }
  return [
    { id: 'meta-page-d9network', provider: 'meta', channel: 'facebook_page', name: 'D9Network Business Page', status: 'connected', connectionState: 'disconnected' },
    { id: 'meta-ig-d9network', provider: 'meta', channel: 'instagram_business', name: 'D9Network Instagram', status: 'connected', connectionState: 'disconnected' },
  ]
}

function normalizeEventPayload(payload) {
  const rawObject = payload && typeof payload === 'object' ? payload : {}
  const eventId = typeof rawObject.id === 'string' ? rawObject.id : typeof rawObject.event_id === 'string' ? rawObject.event_id : null
  const provider = 'meta'
  const eventType = typeof rawObject.object === 'string' ? rawObject.object : 'provider_event'

  return {
    ok: Boolean(eventId || rawObject.object),
    provider,
    eventId,
    eventType,
    accountId: typeof rawObject.account_id === 'string' ? rawObject.account_id : null,
    pageId: typeof rawObject.page_id === 'string' ? rawObject.page_id : null,
    raw: rawObject,
  }
}

export async function handler(event) {
  const operation = event.queryStringParameters?.operation ?? event.path?.split('/').filter(Boolean).at(-1) ?? 'status'

  if (event.httpMethod === 'OPTIONS') {
    return buildResponse(204, {})
  }

  if (operation === 'status' || operation === 'connection-status') {
    return buildResponse(200, getSafeStatusPayload())
  }

  if (operation === 'accounts' || operation === 'account-discovery') {
    return buildResponse(200, {
      ok: true,
      provider: 'meta',
      state: 'configuration_required',
      reason: 'Account discovery is not available without server-side Meta credentials and a verified provider connection.',
      accounts: [],
    })
  }

  if (operation === 'capabilities' || operation === 'capability-discovery') {
    return buildResponse(200, {
      ok: true,
      provider: 'meta',
      state: 'configuration_required',
      reason: 'Capability discovery is gated behind secure server-side provider configuration.',
      destinations: getSafeDestinations(),
      capabilities: [],
    })
  }

  if (operation === 'publish' || operation === 'approved-publishing') {
    const actor = requireServerActor(event)
    if (!actor.ok) {
      return buildResponse(403, { ok: false, state: 'disconnected', reason: actor.reason, provider: 'meta' })
    }

    const config = getMetaConfig()
    if (!config.appId || !config.accessToken || !config.webhookSecret) {
      return buildResponse(200, {
        ok: false,
        state: 'configuration_required',
        status: 'blocked',
        reason: 'Publishing is blocked until the secure Meta server credentials and approvals are configured.',
        provider: 'meta',
        jobId: null,
      })
    }

    const body = readJsonBody(event)
    const approved = Boolean(body.approvedContent)
    const connected = Boolean(body.destinationConnected)
    const capabilityAvailable = Boolean(body.capabilityAvailable)
    const validEligibility = Boolean(body.eligibility?.valid)

    if (!approved || !connected || !capabilityAvailable || !validEligibility) {
      return buildResponse(200, {
        ok: false,
        state: 'disconnected',
        status: 'blocked',
        reason: 'The publish request is missing required approval, connectivity, capability, or eligibility checks.',
        provider: 'meta',
        jobId: null,
      })
    }

    const providerResult = {
      ok: false,
      state: 'disconnected',
      status: 'blocked',
      reason: 'Live provider publishing remains disabled until a verified server-side Meta connection is established.',
      provider: 'meta',
      jobId: null,
    }

    return buildResponse(200, providerResult)
  }

  if (operation === 'publish-status' || operation === 'publishing-status') {
    const jobId = event.queryStringParameters?.jobId ?? readJsonBody(event).jobId
    return buildResponse(200, {
      ok: false,
      jobId: jobId ?? null,
      state: 'configuration_required',
      status: 'blocked',
      reason: 'Publishing status is only available after a verified server-side provider configuration and job token are created.',
      provider: 'meta',
    })
  }

  if (operation === 'webhook' || operation === 'provider-webhook') {
    const body = event.body ?? ''
    const rawText = event.isBase64Encoded ? Buffer.from(body, 'base64').toString('utf8') : body
    const signature = event.headers?.['x-hub-signature-256'] ?? event.headers?.['X-Hub-Signature-256'] ?? event.headers?.['x-hub-signature'] ?? event.headers?.['X-Hub-Signature']
    const secret = process.env.META_WEBHOOK_SECRET

    if (!secret) {
      return buildResponse(200, {
        ok: false,
        state: 'configuration_required',
        reason: 'Webhook verification is not possible without the secure Meta webhook secret.',
      })
    }

    if (signature) {
      const expected = `sha256=${crypto.createHmac('sha256', secret).update(rawText).digest('hex')}`
      const provided = String(signature).trim()
      if (!crypto.timingSafeEqual(Buffer.from(provided), Buffer.from(expected))) {
        return buildResponse(401, {
          ok: false,
          state: 'provider_error',
          reason: 'Invalid Meta webhook signature.',
          provider: 'meta',
        })
      }
    } else {
      return buildResponse(401, {
        ok: false,
        state: 'provider_error',
        reason: 'Missing Meta webhook signature.',
        provider: 'meta',
      })
    }

    let parsed = {}
    try {
      parsed = JSON.parse(rawText)
    } catch {
      return buildResponse(400, { ok: false, state: 'provider_error', reason: 'Webhook payload is not valid JSON.', provider: 'meta' })
    }

    const normalized = normalizeEventPayload(parsed)
    if (!normalized.ok || !normalized.eventId) {
      return buildResponse(200, { ok: false, status: 'ignored', provider: 'meta', state: 'provider_error', reason: 'Unsupported webhook payload or missing provider event ID.' })
    }

    const eventKey = `${normalized.provider}:${normalized.eventId}`
    if (DEDUPE_CACHE.has(eventKey)) {
      return buildResponse(200, { ok: true, state: 'duplicate', status: 'duplicate', provider: 'meta', eventId: normalized.eventId, reason: 'Duplicate provider event rejected.' })
    }

    DEDUPE_CACHE.set(eventKey, Date.now())

    return buildResponse(200, {
      ok: true,
      state: 'received',
      status: 'accepted',
      provider: 'meta',
      eventId: normalized.eventId,
      eventType: normalized.eventType,
      needsReview: false,
    })
  }

  return buildResponse(400, {
    ok: false,
    state: 'provider_error',
    reason: 'Unsupported social provider operation.',
    provider: 'meta',
  })
}

export { getMetaConfig, normalizeProviderState }
