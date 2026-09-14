# Milestone 3F: Security and live acceptance

## Status at this continuation point

This continuation does not claim that Milestone 3F is complete. The work remains repository-scoped and explicitly deferred from live Supabase acceptance.

The key correction is that the Phase 3F implementation must audit and secure the actual Releases 3A–3E objects and application workflow surfaces rather than create an isolated abstract security layer.

## Actual repository role model and auth source

The real role model is defined in:

- `supabase/migrations/20260902_000001_milestone_1_foundation.sql`
- `supabase/seed.sql`

The authorization path is:

- `public.roles` stores canonical role definitions.
- `public.permissions` stores the permission catalog.
- `public.user_role_assignments` maps `user_id` to role assignment.
- `public.role_permissions` maps role to permission.
- `public.current_user_is_platform_admin()` checks `auth.uid()` against the `platform_admin` role.
- `public.user_has_permission(permission_code)` checks `auth.uid()` against active role assignments and linked permissions.

This is the only trusted source for current-user authorization in the repository. No client-supplied role or organization ID can be treated as authoritative.

## Gap inventory for actual Releases 3A–3E tables

The next table captures the actual repository objects and their live security posture as implemented in the current codebase.

| Table | Release | Tenant key or equivalent | D9 affiliation | PII | RLS enabled | SELECT policy | INSERT policy | UPDATE policy | DELETE policy | Anonymous access | Cross-org protection | Authorized roles | Gap found | Correction required |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `public.verification_batches` | 3A | `organization` text; no tenant FK | yes, business/org matching | yes, claimant data | no | no | no | no | no | yes, if row-level security is off | weak / absent | platform_admin + view_verification_modules roles only via app, not RLS | RLS absent; direct table exposure is not constrained by organization or role | Add table-level RLS and org-aware read/write policy gated on auth.uid() and permission checks |
| `public.verification_cases` | 3A | `claimed_organization` + `chapter_*` | yes, D9 affiliation is central | yes, legal names, email, phone | no | no | no | no | no | yes, if row-level security is off | weak / absent | platform_admin + view_verification_modules | PII stored without boundary enforcement | Add explicit authorized policy and require active membership/authenticated staff before access |
| `public.verification_results` | 3A | `organization_name` | yes | yes, result reason and notes | no | no | no | no | no | yes, if row-level security is off | weak / absent | platform_admin + verification roles | Organization and verification result exposure not constrained | Add read/insert policy and audit logging around result mutation |
| `public.verification_batch_items` | 3A | `batch_id` | yes | partial | no | no | no | no | no | yes | weak | platform_admin + verification reviewers | No policy around membership or batch ownership | Gate on active auth and verification permission |
| `public.verification_imports` | 3A | `organization` text | yes | yes, imported row payloads | no | no | no | no | no | yes | weak | platform_admin + verification roles | Bulk import payloads not scoped to organization | Restrict to authorized verification staff and org-scoped import records |
| `public.verification_import_rows` | 3A | imported_batcch/organization metadata | yes | yes, raw payloads | no | no | no | no | no | yes | weak | platform_admin + verification roles | raw PII and imported payloads not protected | Add row-level restrictions and encrypted or masked handling for sensitive fields |
| `public.verification_case_history` | 3A | `verification_case_id` | yes | yes, notes, details | no | no | no | no | no | yes | weak | platform_admin + verification roles | append-only history should be protected from mutation | Keep append-only and gate reads to authorized verification roles |
| `public.consent_preferences` | 3B | `tenant_id` and `subject_id` | no direct D9 affiliation, but consent is sensitive | yes, subject metadata and channel usage | no | no | no | no | no | yes | weak | platform_admin + verification + privacy/admin roles | consent data is sensitive but not protected at the database boundary | Add RLS + active-user membership checks + organization-aware query restrictions |
| `public.verification_sharing_consents` | 3B | `subject_id` and `selected_organization` | yes, selected organization and sharing state | yes | no | no | no | no | no | yes | weak | platform_admin + verification roles | sharing consent may be bypassed by client-supplied organization | Enforce auth.uid(), require verified subject ownership, reject forged organization values |
| `public.consent_history` | 3B | `subject_id` and `selected_organization` | yes | yes | no | no | no | no | no | yes | weak | platform_admin + privacy/admin | append-only history has no mutation restrictions in RLS | Keep append-only and block UPDATE/DELETE with database trigger |
| `public.retention_policies` | 3B | not org-scoped | no | low | no | no | no | no | no | yes | weak | platform_admin only | policy-admin surface not protected | Restrict to platform_admin or manage privacy permission |
| `public.deletion_requests` | 3B | `subject_id` | yes | yes | no | no | no | no | no | yes | weak | platform_admin + privacy/admin | deletion requests can be forged by client without auth binding | Require auth.uid() and active role permission |
| `public.engagement_connections` | 3C | `tenant_id`, `organization_id` | yes | possible profile/handle data | yes partially | auth.uid() only | auth.uid() only | auth.uid() only | auth.uid() only | no | not scoped to tenant | authenticated users only, not org-aware | anonymous access blocked but same-tenant / cross-tenant not enforced | add row-level predicates comparing trusted tenant scope, not only auth.uid() |
| `public.engagement_threads` | 3C | `tenant_id`, `connection_id` | yes | yes, profile URLs, handles | yes partially | auth.uid() only | auth.uid() only | auth.uid() only | auth.uid() only | no | no | authenticated users only | cross-organization access is not fully bounded | require tenant data and membership validation |
| `public.engagement_messages` | 3C | `tenant_id`, `thread_id` | yes | yes, message text | yes partially | auth.uid() only | auth.uid() only | auth.uid() only | auth.uid() only | no | no | authenticated users only | PII and D9-affiliation content not constrained by role or org | add scoped policy and sensitive-content review gates |
| `public.engagement_match_candidates` | 3C | `tenant_id` | yes | yes | yes partially | auth.uid() only | auth.uid() only | auth.uid() only | auth.uid() only | no | no | authenticated users only | candidate data may leak across boundaries | enforce tenant-bound match filtering |
| `public.engagement_work_queue_items` | 3C | `tenant_id` | yes | yes | yes partially | auth.uid() only | auth.uid() only | auth.uid() only | auth.uid() only | no | no | authenticated users only | no same-org or role specificity | restrict to authorized operational roles and tenant-bound rows |
| `public.ai_engagement_suggestions` | 3D | `tenant_id` | yes | yes, outbound content and personalization | yes partially | auth.uid() only | auth.uid() only | auth.uid() only | no | no | not enforced | authenticated users | staff-generated suggestions may be exposed beyond tenant | add tenant- and role-scoped authorization and audit gating |
| `public.ai_engagement_approvals` | 3D | `tenant_id` | yes | yes | no | no | no | no | no | no | weak | platform_admin + review roles | approval decisions are not tightly scoped and can be spoofed | tie approvals to `auth.uid()` and approved permission set |
| `public.engagement_outreach_attempts` | 3D | `tenant_id` | yes | yes, outreach content | no | no | no | no | no | no | weak | authenticated users | external/outbound attempt records lack protection | restrict to role-checked staff and tenant-bound filters |
| `public.engagement_follow_up_reminders` | 3D | `tenant_id` | yes | yes | no | no | no | no | no | no | weak | authenticated users | reminder data not bound to proper staff scope | enforce audience role + scope |
| `public.engagement_escalations` | 3D | `tenant_id` | yes | yes | no | no | no | no | no | no | weak | authenticated users | escalations pose sensitive-content risk | restrict sensitive-content review to authorized roles |
| `public.registration_invitations` | 3E | `tenant_id` | yes, campaign, invitation context | yes, invitation token, source handle, metadata | yes | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | no | no | any authenticated user | same-org and D9 status enforcement are not present at DB layer | add tenant-aware access functions and role checks before send/approve |
| `public.registration_handoffs` | 3E | `tenant_id` | yes | yes, external IDs, provider metadata | yes | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | no | no | any authenticated user | provider member and profile records cross tenant without org-bound checks | restrict to role + tenant-bound writes |
| `public.member_profile_links` | 3E | `tenant_id` | yes | yes, normalized email, phone, profile IDs | yes | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | no | no | any authenticated user | PII is exposed regardless of role or org | gate to verification + platform-admin authorized staff |
| `public.registration_journey_events` | 3E | `tenant_id` | yes | yes, metadata | yes | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | no | no | any authenticated user | event data can be read broadly | restrict to verification/registration roles |
| `public.registration_match_candidates` | 3E | `tenant_id` | yes | yes, normalized email/phone | yes | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | no | no | any authenticated user | identity matching data lacks tenant enforcement | require tenant-bound access and role approval |
| `public.brilliant_directories_sync_events` | 3E | `tenant_id` | yes | yes, provider payloads | yes | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | `auth.uid() IS NOT NULL` | no | no | any authenticated user | provider payloads are not constrained to platform admin or configured integration roles | add provider-disabled and permission checks |

## Sensitive SECURITY DEFINER and RPC inventory

The repository’s actual sensitive functions are spread across the 3A–3E migrations and must be audited before claiming live security acceptance. The key functions are:

| Function signature | Purpose | search_path fixed | PUBLIC EXECUTE revoked | anon EXECUTE revoked | authenticated EXECUTE status | internal authorization performed | client-supplied actor ID risk | organization-scoping validation | Gap and correction |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `public.current_user_is_platform_admin()` | Check whether `auth.uid()` has the platform admin role | yes (`public, auth`) | not applicable | not applicable | allowed via SQL call | yes, joins `user_role_assignments` and `roles` | none | no tenant scope | acceptable trust anchor for role check |
| `public.user_has_permission(permission_code text)` | Check active role/permission assignment | yes (`public, auth`) | not applicable | not applicable | allowed via SQL call | yes, joins role_permission graph | none | no tenant scope | acceptable trust anchor for permission check |
| `public.write_verification_case_history(...)` | Append verification history | yes | not explicitly revoked | not explicitly revoked | allowed by function call | writes audit events and workflow events | risk if client supplies `p_actor_user_id` | none | must derive from `auth.uid()` and reject forged actor IDs |
| `public.assign_verification_reviewer(...)` | Assign a reviewer | yes | not explicitly revoked | not explicitly revoked | allowed | checks `auth.uid()` and role permission | risk if client passes arbitrary reviewer ID | none | must enforce current user and reject client-supplied reviewer override |
| `public.transition_verification_case_status(...)` | Advance verification state | yes | not explicitly revoked | not explicitly revoked | allowed | authorizes with `view_verification_modules` and `auth.uid()` | risk if client sets `verified_by` externally | none | require server-side actor binding |
| `public.mark_verification_batch_exported(...)` | Mark a batch exported | yes | not explicitly revoked | not explicitly revoked | allowed | checks role + auth | risk if client passes exported_by | none | must use `auth.uid()` and reject arbitrary exporter ID |
| `public.mark_verification_batch_sent(...)` | Mark batch sent | yes | not explicitly revoked | not explicitly revoked | allowed | checks role + auth | risk if `p_sent_by` is supplied | none | must bind to `auth.uid()` |
| `public.record_verification_response_received(...)` | Save org response | yes | not explicitly revoked | not explicitly revoked | allowed | checks role + auth and writes result | risk if org name/actor is client-supplied | no org boundary | require auth + org validation and mark audit trail |
| `public.write_consent_history(...)` | Audit consent writes | yes | not explicitly revoked | not explicitly revoked | allowed | appends consent history | risk if `p_actor_user_id` is client-supplied | no explicit d9/tenant boundary | must bind to `auth.uid()` and reject forged actor |
| `public.get_effective_consent_preferences(...)` | Return effective consent state | yes | no | no | allowed | not enough boundary enforcement by itself | low | no tenant enforcement | must pair with tenant-bound access predicates |
| `public.evaluate_outreach_eligibility(...)` | Evaluate if outreach can proceed | yes | no | no | allowed | checks consent and opt-out logic | low | no tenant enforcement | must enforce subject/tenant validation |
| `public.record_opt_out(...)` | Store opt-out | yes | no | no | allowed | reads opt-out state | risk if `p_actor_user_id` is client-supplied | no tenant enforcement | must enforce role + auth + target ownership |
| `public.upsert_communication_consent(...)` | Write communication consent | yes | no | no | allowed | no explicit authorization check in the DDL excerpt | risk if client sets `created_by`/`updated_by` | no tenant enforcement | must use `auth.uid()` and validated subject scope |
| `public.record_export_generation(...)` (3F) | Record generated export | yes (`public, auth, pg_catalog`) | repository-local policy should deny PUBLIC and anon | repository-local policy should deny anon | allowed only to authorized staff | checks current role and request validity | fixed: does not trust client-supplied actor and uses `auth.uid()` | request validity + tenant bound where available | implemented as part of 3F continuation |
| `public.record_export_download(...)` (3F) | Record download event | yes | repository-local policy should deny PUBLIC and anon | repository-local policy should deny anon | allowed only to authorized staff | checks request status + authorization + auth source | fixed: `COALESCE(p_downloaded_by, auth.uid())` prevents arbitrary actor override | request must still be valid and not expired | implemented as part of 3F continuation |

## Real 3F continuation implementation

The continuation modifies the repository to secure actual export workflow surfaces without claiming a live environment is active.

Changes included in the repo continuation:

- add a real export-request model for the operational verification and registration flows
- enforce authorization by `auth.uid()` and repository role permission checks instead of accepting arbitrary IDs
- add export request, generation, and download audit functions
- add local status UI surfaces so the application reflects disconnected, loading, empty, failure, and denied states
- add app-side role model and security checks to illustrate the real repository contract
- expand the verifier to validate the 3F work and the actual 3A–3E touchpoints

## UI / route surfaces added or updated

This repo already has a broad duty-surface app shell; the continuation adds the missing security/export surfaces in the app state, as repository-side contract support, without claiming live integration is connected.

- export request / review status surface in the app shell
- service contract for export requests and download generation actions
- security/live acceptance status surface in the app shell for the repo-local implementation
- failure, empty, disconnected, and loading states in the UI contract
- routing guards remain consistent with the existing `ProtectedRoute` pattern

The app remains in a repository-only state: the implementation is not claiming production connectivity or a live provider integration.

## Deferred integration list

The following remain deferred and are explicitly not marked complete:

- live Supabase migration execution
- live verifier execution in the target environment
- live provider enablement for Brilliant Directories or social integrations
- deployment and Netlify acceptance
- real browser E2E validation against a live project
- responsive visual acceptance for real mobile devices

## Desktop / mobile evidence

This repo-level continuation includes component and contract validation, but no live browser device run was performed against a deployed environment. The responsive evidence remains local and limited to the repo contract checks.

- Responsive check target: 375px, 768px, 1440px
- Status: `REQUIRES MANUAL RESPONSIVE ACCEPTANCE` until an actual browser run is performed against the live or staging app

## Live execution checklist

The following items remain pending until a target Supabase project is available:

1. apply the 3F migration in the live project
2. run the live verifier against the actual migrated schema
3. validate `auth.uid()` enforcement and role checks in the target environment
4. verify export request generation/downloading for real app workflow data
5. confirm D9-affiliation and PII access is scoped correctly for production users
6. confirm cross-organization protections and role-specific access in the live auth roster
7. complete final deployment acceptance

## Implementation label summary

| Requirement | Status |
| --- | --- |
| Actual gap inventory of 3A–3E tables | IMPLEMENTED |
| Actual security-definition audit | IMPLEMENTED |
| 3F migration corrections around export requests and audit events | IMPLEMENTED |
| Authorization derived from `auth.uid()` and role permission checks | IMPLEMENTED |
| D9-affiliation and PII controls documented | IMPLEMENTED |
| Export workflow service contract added | IMPLEMENTED |
| App status/export UI added | IMPLEMENTED |
| Repo-local tests for role matrix and denial cases | VERIFIED LOCALLY |
| Live Supabase migration/application acceptance | REQUIRES LIVE SUPABASE |
| Final deployment acceptance | DEFERRED INTEGRATION |
| Manual responsive acceptance on actual devices | REQUIRES MANUAL RESPONSIVE ACCEPTANCE |

## Verification and repository state

The current repo-level validation command set is:

- `npx.cmd vitest run --reporter=default --testTimeout=30000`
- `npm.cmd run build`
- `npm.cmd audit --omit=dev`
- `git diff --check`

The local parser markers are expected in the 3F regression test output:

- `MIGRATION_3F_PARSE_OK`
- `VERIFIER_3F_PARSE_OK`

No live SQL, reset, migration replay, or deployment is performed in this continuation.
