import crypto from 'node:crypto'

const DEDUPE_CACHE = new Map()

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

function normalizeMetaWebhook(payload) {
  const objectValue = payload && typeof payload === 'object' ? payload : {}
  const eventId = typeof objectValue.id === 'string' ? objectValue.id : typeof objectValue.event_id === 'string' ? objectValue.event_id : null
  const objectType = typeof objectValue.object === 'string' ? objectValue.object : 'provider_event'
  const type = typeof objectValue.type === 'string' ? objectValue.type : objectType

  return {
    ok: Boolean(eventId || objectType),
    eventId,
    objectType,
    type,
    raw: objectValue,
  }
}

export async function handler(event) {
  const rawBody = event.isBase64Encoded ? Buffer.from(event.body ?? '', 'base64').toString('utf8') : (event.body ?? '')
  const metaSecret = process.env.META_WEBHOOK_SECRET

  if (!metaSecret) {
    return buildResponse(200, { ok: false, state: 'configuration_required', reason: 'Webhook secret is not configured on the secure server.' })
  }

  const challenge = event.queryStringParameters?.['hub.challenge']
  const verifyToken = event.queryStringParameters?.['hub.verify_token']
  if (challenge && verifyToken && verifyToken === process.env.META_VERIFY_TOKEN) {
    return buildResponse(200, { hub: { challenge, mode: 'subscribe' } })
  }

  const signature = event.headers?.['x-hub-signature-256'] ?? event.headers?.['X-Hub-Signature-256'] ?? event.headers?.['x-hub-signature'] ?? event.headers?.['X-Hub-Signature']
  if (!signature) {
    return buildResponse(401, { ok: false, state: 'provider_error', reason: 'Missing Meta webhook signature.' })
  }

  const expected = `sha256=${crypto.createHmac('sha256', metaSecret).update(rawBody).digest('hex')}`
  if (!crypto.timingSafeEqual(Buffer.from(String(signature).trim()), Buffer.from(expected))) {
    return buildResponse(401, { ok: false, state: 'provider_error', reason: 'Invalid Meta webhook signature.' })
  }

  let payload
  try {
    payload = JSON.parse(rawBody)
  } catch {
    return buildResponse(400, { ok: false, state: 'provider_error', reason: 'Webhook payload must be valid JSON.' })
  }

  const normalized = normalizeMetaWebhook(payload)
  if (!normalized.ok) {
    return buildResponse(200, { ok: false, state: 'provider_error', status: 'ignored', reason: 'Unsupported or incomplete webhook object.' })
  }

  const dedupeKey = `meta:${normalized.eventId ?? normalized.objectType}`
  if (DEDUPE_CACHE.has(dedupeKey)) {
    return buildResponse(200, { ok: true, state: 'duplicate', status: 'duplicate', provider: 'meta', eventId: normalized.eventId, reason: 'Duplicate provider event rejected.' })
  }

  DEDUPE_CACHE.set(dedupeKey, Date.now())

  return buildResponse(200, {
    ok: true,
    state: 'received',
    status: 'accepted',
    provider: 'meta',
    eventId: normalized.eventId,
    eventType: normalized.type,
  })
}

export default { handler }
