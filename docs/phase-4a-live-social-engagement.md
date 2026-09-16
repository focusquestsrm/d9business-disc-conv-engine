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

## Server-side pattern selected for Phase 4A.1

This repository uses the Netlify Functions boundary for the secure provider facade. The browser calls Netlify endpoints such as `/.netlify/functions/social-provider` and receives only normalized, safe status objects. The browser does not access environment variables or provider secrets directly. The server-side function owns all secret reads, signature verification, and provider normalization.

### Function inventory

- `netlify/functions/social-provider.mjs` — connection status, account discovery, capability discovery, publish gating, status retrieval, and webhook validation
- `netlify/functions/social-webhook.mjs` — Meta verification challenge handling and signed webhook processing

### Secret-handling rules

- Secrets are read only from server-side environment variables.
- No `VITE_` variables contain Meta credentials.
- No credentials are persisted in `localStorage` or `sessionStorage`.
- No credentials are embedded in URLs or logs.
- Full provider payloads are never returned to the browser.
- The browser never asserts provider success; live publish results remain server-controlled and blocked until the server verifies a safe connection.

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

## Disconnected behavior and safe fallback

Without server-side credentials, the provider boundary returns safe normalized results such as:

- configuration_required
- disconnected
- permission_limited
- reconnect_required
- provider_error

The browser sees only the safe normalized result, never provider secrets or raw provider payloads. Live Meta connectivity is not claimed by the repository, and a publish attempt remains blocked until a verified server-side connection is configured.

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

## Webhook verification design

The webhook boundary validates the Meta `x-hub-signature-256` HMAC when configured, rejects invalid signatures, extracts a provider event ID, stores a deduplication boundary, and ignores unsupported or incomplete payloads without inferring D9 affiliation or membership. A challenge request is accepted only when the verification token matches the secure server-side configuration.

## Phase 4A.3 application and operator workflow

Phase 4A.3 completes the repository-side application flow for authorized social engagement handling without claiming live Meta connectivity.

### Route and page inventory

The application exposes the secure social work flow through protected routes that remain gated by the repository authentication and role model:

- Social Connections — provider state, safe destination summary, configuration-required handling
- Publishing Queue — queue readiness, blocked reason display, safe publish-state summary
- Scheduled Posts — schedule visibility only when a verified connection exists
- Published/Failed Activity — activity feed with blocked or failed states only, never a false published state
- Inbound Activity — normalized webhook event display and safe event summary
- Connection Health — provider state and destination health summary without raw secrets or tokens
- Content Preparation — operator workflow for prospect or business selection, content draft, destination, action, scheduling, notes, and eligibility review
- Content Approval — review screen showing prospect, requestor, destination, content version, warnings, requested schedule, and review note actions

### Operator workflow

The operator workflow is intentionally fail-closed:

1. select a prospect or business
2. prepare a supported social engagement item
3. choose an authorized destination
4. select a supported action
5. enter proposed content
6. choose requested schedule
7. add internal note
8. evaluate eligibility
9. submit for approval
10. review and approve, return, or reject the item
11. schedule or reschedule approved content
12. cancel eligible work
13. request an authorized retry when the safe connection permits it
14. view status and history in the secure work queues

### Eligibility presentation and fail-closed policy

Before submission or scheduling, each action must show the safe operator-visible eligibility summary:

- consent state
- opt-out state
- suppression state
- frequency/cooldown status
- connection state
- destination status
- capability support
- review warnings and content-version changes
- final blocked reason if the action cannot proceed

The application blocks actions when consent is missing, the prospect is opted out or suppressed, the cooldown rule is active, the destination is disconnected or disabled, the capability is unsupported, the provider is not connected, or the content is not approved or has changed since approval.

### Approval experience and server boundary

Authorized reviewers can approve, return, or reject content only through the protected workflow. The UI waits for a confirmed server result before it updates state. Approved content changes visibly require reapproval before the system will permit a new schedule or send. The repository never accepts direct browser-supplied provider results or actor identifiers in the publish path.

### Status and activity behavior

Activity displays remain safe and normalized:

- configuration_required, disconnected, and provider_error states are visible as blocked or failed states only
- a work item is never shown as published without verified server confirmation
- raw Meta payloads, provider secrets, stack traces, token values, and service-role material are not rendered in browser UI

### Responsive and accessible behavior

The social engagement screens follow the repository’s existing responsive conventions and accessible patterns:

- forms use visible labels and keyboard access
- controls remain usable at mobile, tablet, and desktop widths
- wide tables scroll within their container rather than causing page-level overflow
- focus and status messaging remain available to assistive technology
- meaningful text explains loading, empty, blocked, and configuration-required states

## Final Phase 4A.3 repository state

Phase 4A.3 remains repository-scoped and intentionally honest: the product does not claim live Meta connectivity or a production provider connection until the secure environment and provider credentials are configured in Phase 4A.4. The code remains fail-closed and safe for non-live repository validation.

### Final schema objects

The additive Phase 4A migration defines:

- `public.social_provider_connections` — provider lineage, connection state, page/account identifiers, trusted server metadata
- `public.social_provider_destinations` — Meta destinations, enabled/disabled channels, approval state
- `public.social_provider_capabilities` — supported content capability matrix and max lengths
- `public.social_publishing_jobs` — job lifecycle, approval metadata, content hash/version, scheduling, provider identifiers
- `public.social_publishing_attempts` — append-only attempt history and server-side result recording
- `public.social_provider_events` — normalized inbound webhook evidence and deduplication boundary
- `public.social_provider_health_events` — provider state transitions and operational audit trail

### Publishing state machine

The repository enforces a conservative publishing state model:

- `draft` — created but not yet submitted
- `submitted_for_review` — human review requested
- `approved` — content approved for the current hash/version
- `scheduled` — queued for a future send time
- `ready` — task is eligible and reserved for trusted processing
- `publishing` — a trusted server worker has claimed the job
- `published` — provider success was verified by the trusted server path
- `partially_published` — provider confirmed partial success
- `failed` — provider-normalized failure or a safe, explicit failure state
- `cancelled` — manually cancelled before final delivery

A job cannot enter a publish-ready state unless it carries an approved approval record, a content hash, a positive content version, a valid destination, and a connected provider connection.

### Protected database operations

The repository includes protected server-side SQL functions covering the trusted operations required by Phase 4A.2:

- `public.enforce_social_connection_state()` — blocks forged or invalid provider connection states
- `public.enforce_social_publishing_job_transition()` — prevents invalid job-state transitions and unapproved publish states
- `public.record_social_publishing_attempt()` — enforces sequential attempts and updates the job result in the trusted server path
- `public.current_user_can_manage_social_connections()` — centralizes permission gating for admin staff

The final repository model also keeps the trusted publishing path separate from browser-driven input and restricts provider-result mutation to server-side policy by design.

### Actor, tenant, role, and consent controls

Phase 4A.2 keeps the repository aligned with the established D9 role model:

- trusted actors are derived from `auth.uid()`
- anonymous callers are rejected for protected operations
- client-supplied actor IDs are not accepted
- tenant and organization boundaries are enforced before approving or claiming a job
- role and permission checks are applied through the repository’s existing `current_user_is_platform_admin()` and `user_has_permission()` model
- consent, opt-out, suppression, frequency, and cooldown conditions must all succeed before a job is eligible
- if the authoritative consent or suppression record is unavailable, the system fails closed and records the reason rather than assuming eligibility

### Idempotency and concurrency protections

Phase 4A.2 includes database-level protections for the trust boundaries underlying scheduled publishing:

- duplicate job requests should use the same idempotency key and must not create duplicate live publish actions
- a worker can claim only one eligible job at a time via trusted server locking logic and sequential workflow checks
- repeated provider success callbacks are rejected or normalized to duplicate/ignored states instead of creating repeated publish transitions
- webhook events are deduplicated via a provider-event uniqueness boundary before they can affect state
- retry attempts receive sequential attempt numbers
- failed attempts never create a false published state

### Webhook verification and deduplication

The repository’s webhook boundary remains intentionally conservative:

- the secure Meta webhook signature is validated before any processing occurs
- challenge verification requires the server-side verification token
- unsupported or incomplete payloads are safely ignored
- event IDs are deduplicated before state changes are applied
- raw secrets are never stored in tables or returned to client code

### Trusted server publishing sequence

The final trusted publishing flow is:

1. authenticated request or scheduled invocation enters the secure server boundary
2. eligible job is claimed by the trusted server path only
3. approved stored content, destination, and capability checks are validated
4. consent, suppression, cooldown, and frequency gates are re-evaluated
5. a provider operation is executed only if the capability is supported and the connection is connected
6. the server records the attempt, then records verified success or normalized failure
7. the browser never sees provider secrets, raw payloads, or live success claims without server verification

### Remaining Phase 4A.3 and 4A.4 work

Phase 4A.3 remains the application/operator integration layer: live UI workflows, operational review screens, and admin-facing approval orchestration.

Phase 4A.4 remains the live Meta configuration and deployment environment work: setting the real provider credentials, verifying the production-secure secret boundary, and validating the live Meta connection in the authorized deployment environment.

This repository remains intentionally honest: it does not claim live Meta connectivity until that later environment and provider configuration are completed.

## Migration and verifier instructions

Before any apply step, run the read-only preflight package to confirm the target database is ready for the 3E/3F/4A live schema set:

- `supabase/verification/preflight_phase_4a_live_database.sql`

Interpret the preflight results:

- if the overall status is `PASS`, continue to the additive migration
- if the overall status is `BLOCK`, stop and resolve the missing or unsafe dependency before proceeding

Run the additive migration in the target Supabase project:

- `supabase/migrations/20260917_000001_phase_4a_live_social_engagement.sql`

Run the verification script:

- `supabase/verification/verify_phase_4a_live_social_engagement.sql`

This repository does not run live Supabase SQL automatically; Danielle will execute the preflight, migration, and verifier manually in the configured environment.
