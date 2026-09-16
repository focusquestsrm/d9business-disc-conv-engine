# Phase 4A — Live Social Engagement Connections

## Purpose and scope

Phase 4A delivers the controlled, server-side social publishing foundation for the D9 Business Discovery Conversational Engine. It is intentionally scoped to approved Meta page and professional Instagram connections only. The implementation does not claim support for personal profiles, unrestricted direct messaging, unsupported automated comments, or unapproved outbound activity.

This release keeps the operating principle unchanged:

- Celebration first
- Discovery second
- Membership promotion third

The system continues to preserve human approval, consent gating, suppression, frequency controls, and manual fallback behavior.

## Supported and unsupported capabilities

### Supported

- Facebook Pages connected through the Meta Graph API and approved page permissions
- Instagram professional/business accounts connected through Meta and approved app scopes
- Approved text and link publishing for supported destinations
- Approved image publishing where the destination explicitly allows it
- Provider capability checks before content submission
- Safe provider-connection metadata and server-side secret handling
- Webhook event normalization where a provider-authorized integration exists

### Unsupported

- Personal Facebook profiles
- Unrestricted Instagram DMs
- Automated comments or replies without an approved provider contract
- Platform features not explicitly granted by Meta and the D9 admin configuration
- Any claim that a post is live before a verified provider response is received
- Unapproved autonomous outbound messaging or bulk promotional posting

## Architecture

The provider layer sits behind a typed adapter interface so Meta-specific logic remains isolated from application workflows.

- Application layer: content approval, consent checks, suppression rules, work queues, scheduled jobs
- Provider adapter: Meta connection health, page discovery, capability discovery, validation, publish calls, webhook normalization
- Security layer: server-side token storage, safe metadata only, RLS and tenant boundaries, no browser token exposure
- Audit layer: connection changes, approval actions, publication attempts, provider responses, inbound webhooks, manual fallback confirmations

## Provider adapter contract

The repository exposes a typed adapter contract in `src/lib/socialProvider.ts` that covers:

- connection status
- account and page discovery
- approved destination selection
- capability discovery
- content validation
- approved publishing
- publishing-status retrieval
- inbound webhook normalization
- provider error normalization
- token refresh and reconnect state recognition

The supported connection-state model is:

- disconnected
- configuration_required
- connected
- permission_limited
- token_expiring
- reconnect_required
- suspended
- provider_error

The implementation does not mark a provider as connected unless the provider returns a verified response.

## Security model

- Provider secrets remain server-side only.
- Vite client environment variables do not hold access tokens.
- Browser storage never contains plaintext tokens.
- Logs do not capture secrets or full provider payloads containing sensitive data.
- Application tables record only safe connection metadata and status information.
- RLS and tenant scoping remain enforced at the database layer.
- Every function and job records actor attribution via the server-side session or service path.

## Required environment variables

The application and deployment require the following values, configured by Danielle and not committed to the repo:

- `META_APP_ID`
- `META_APP_SECRET`
- `META_VERIFY_TOKEN`
- `META_ACCESS_TOKEN`
- `META_WEBHOOK_SECRET`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

No real values should be committed to this repository.

## Connection steps Danielle must perform

1. Provision the Meta app and confirm the approved business assets.
2. Confirm the Facebook Page and Instagram professional account are approved for the D9Network tenant.
3. Configure Meta permissions for the approved account or page.
4. Add the server-side credentials and webhook secret in the deployment environment.
5. Run the Phase 4A migration and verifier in the target Supabase project.
6. Validate the connection records and health state in the admin console.
7. Confirm a test post or supported engagement action against the approved D9Network destination.

## Human approval workflow

Publication remains gated by the approved content workflow:

- draft
- submitted for review
- approved
- scheduled
- ready
- publishing
- published
- partially published
- failed
- cancelled

Content must be approved before publish. Edited content requires reapproval. Approval is never inherited automatically from stale content versions.

## Consent and frequency controls

Publication is denied when any of the following conditions apply:

- opt-out or suppression is active
- consent is missing, expired, or withdrawn
- cooldown is still active
- frequency limit is reached
- the destination is disconnected or permissions are limited
- the provider rejects the action
- the content is not approved or has changed since approval

The system continues to use the existing D9 consent and follow-up rules rather than replacing them with a parallel social-only model.

## Provider error and retry behavior

Provider failures are normalized and classified as retryable or non-retryable. The application must not report a successful published status unless the provider returns a verified final state.

If a provider response is unavailable or denied, the content remains in a safe manual-review or retry state rather than a false successful state.

## Manual fallback behavior

If Meta does not permit a delivery through the authorized API:

- the assisted content/send workflow remains available;
- manual delivery is only recorded after staff confirms completion;
- the action is not represented as provider delivery or provider confirmation.

## Remaining Phase 4B–4E scope

Phase 4A is intentionally limited to social connection and provider-safe publishing scaffolding.

Phase 4B will cover the Brilliant Directories membership system of record and conversion closure.

Phase 4C: analytics foundation and performance intelligence
Phase 4D: predictive and prescriptive intelligence
Phase 4E: normative governance, administration, and launch

## Test checklist

- Disconnected provider behavior
- Permission-limited provider behavior
- Approved publishing lifecycle
- Unapproved publishing denial
- Changed-content reapproval
- Opt-out denial
- Missing-consent denial
- Frequency-limit denial
- Cooldown denial
- Provider error and retry handling
- Duplicate webhook handling
- Uncertain inbound matching
- Manual-delivery distinction
- No false success reporting
- Migration and verifier parsing
- Security regression checks for the completed 3F release

## Migration and verifier instructions

Run the additive migration in the target Supabase project:

- `supabase/migrations/20260917_000001_phase_4a_live_social_engagement.sql`

Run the verification script:

- `supabase/verification/verify_phase_4a_live_social_engagement.sql`

This repository does not run live Supabase SQL automatically; Danielle will execute the migration and verifier manually in the configured environment.
