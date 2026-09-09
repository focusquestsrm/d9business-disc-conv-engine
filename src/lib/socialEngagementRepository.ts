import type { SocialConnection, SocialMessage } from './socialEngagement'

export const socialEngagementRepository = {
  async loadConnections() {
    return [] as SocialConnection[]
  },

  async loadInbox() {
    return [] as Array<Record<string, unknown>>
  },

  async upsertConnection(_connection: Partial<SocialConnection>) {
    return { ok: true, connection: _connection }
  },

  async ingestMessage(_message: Partial<SocialMessage>) {
    return { ok: true, message: _message }
  },

  isDuplicateEvent(event: { connectionId?: string | null; platform?: string | null; externalEventId?: string | null; eventType?: string | null; payloadHash?: string | null }) {
    return Boolean(event.connectionId && event.platform && event.externalEventId && event.eventType && event.payloadHash)
  },

  isDuplicateMessage(message: { threadId?: string | null; externalMessageId?: string | null }) {
    return Boolean(message.threadId && message.externalMessageId)
  },
}
