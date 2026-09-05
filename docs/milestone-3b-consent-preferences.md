# Milestone 3B: Consent and Communication Preferences

## Scope

Release 3B adds an explicit consent framework for outreach and verification sharing. It is designed to be additive and compatible with the existing Milestone 2 and Release 3A tables, with focused reuse of public.opt_outs, public.audit_events, public.workflow_events, and the platform-admin permissions already established in the foundation migrations.

## Reused foundation

The Release 3B model reuses:

- public.opt_outs for suppression and opt-out evidence
- public.audit_events for append-only system audit trail
- public.workflow_events for status transitions and operational activity
- public.current_user_is_platform_admin() and public.user_has_permission() for permission checks
- set_updated_at trigger conventions already used by earlier releases

Additions are intentionally limited to the consent and retention model required for release 3B.

## Consent channels and purpose model

Supported communication channels:

- email
- phone
- text
- social_media

Purpose model:

- general_communication
- verification_share
- service_updates
- marketing
- security_notice

Each effective preference keeps a single active record per subject, channel, and purpose. The model is deny-by-default: missing consent, expired consent, withdrawn consent, and active suppression all block outreach.

## Verification-sharing separation

General communication consent is separate from organization-specific verification-sharing consent. A user may have email consent for outreach without any active approval to share membership verification details with a selected Divine Nine organization. Verification sharing is affirmative, explicit, organization-scoped, and historically traceable.

## Opt-out precedence

The precedence order for outreach eligibility is:

1. global opt-out
2. channel opt-out
3. consent status and validity
4. permission-specific enforcement

Global opt-outs override every channel-level grant. A channel-specific opt-out only blocks that channel.

## Consent-history behavior

public.consent_history is append-only. It records consent granted, denied, updated, withdrawn, expired, organization-sharing grant, suppression changes, retention actions, and opt-out state transitions. Normal authenticated roles cannot mutate consent history directly; only controlled database functions may write history records.

## Retention and deletion policy model

Retention categories include:

- active consent records
- withdrawn/expired consent evidence
- opt-out and suppression evidence
- verification-sharing consent
- consent history
- deletion requests

Each policy is configurable with:

- retention_days
- effective_from
- enabled
- disposition (retain, delete, anonymize)
- policy_version
- notes

The deletion lifecycle supports requested, under_review, approved, rejected, completed, and cancelled. A hold can prevent disposition until legal or audit requirements are cleared.

## Initial product-policy defaults

The default Release 3B configuration uses a conservative retention posture and favors retaining evidence needed for compliance and suppression. Final legal retention periods require business and legal approval before they are treated as binding policy.

## RLS and security model

All new tables are RLS-enabled. Authenticated users may manage their own consent data subject to standard role checks, while platform admins govern retention/deletion policies and operational privacy actions. Consent history remains append-only and is not directly mutable by normal roles. The functions use safe search_path configuration and validate the caller before privileged actions.

## RPC signatures

Release 3B introduces authoritative ledger-style operations for consent decisions and activity logging:

- evaluate_outreach_eligibility(p_subject_type, p_subject_id, p_channel, p_purpose, p_tenant_id)
- evaluate_verification_sharing_eligibility(p_subject_type, p_subject_id, p_selected_organization, p_verification_case_id)
- upsert_communication_consent(...)
- withdraw_communication_consent(...)
- grant_verification_sharing_consent(...)
- withdraw_verification_sharing_consent(...)
- record_opt_out(...)
- reverse_opt_out(...)
- request_data_deletion(...)
- process_deletion_request(...)
- get_effective_consent_preferences(...)
- get_consent_history(...)
- load_suppression_status(...)

## Repository integration

The repository module in src/lib/consentRepository.ts calls the database RPC layer rather than simulating state. It provides durable methods for loading effective consent, granting or withdrawing preferences, managing verification-sharing consent, recording opt-out or suppression reversals, checking eligibility, and loading retention-history state.

## UI contract and enforcement

The consent UI should:

- identify the selected subject
- show the current status for email, phone, text, and social media
- allow grant, deny, or withdrawal actions
- require a source and privacy-notice version
- show the effective outreach decision
- present organization-specific sharing consent separately
- display suppression and permission status
- display immutable history in chronological order

The application must prevent outreach actions when the eligibility decision is denied. The UI is a guardrail and the database function remains the authoritative enforcement layer.

## Manual acceptance steps

1. Create or update the subject record.
2. Capture communication consent for the desired channel and purpose.
3. Record organization-specific sharing consent only when the user explicitly approves the selected organization.
4. Confirm no active global or channel opt-out exists.
5. Evaluate outreach or verification-sharing eligibility using the canonical RPCs.
6. Use the consent history record to support audit and compliance review.
7. For deletion or anonymization requests, route through the retention policy and deletion-request lifecycle.

## Future outreach systems

Any future sending integration must call the centralized eligibility guard before it initiates outreach. The decision must be authoritative and deny-by-default; integrations may not rely on UI display state alone.

## Rollback considerations

Before executing the migration in a live Supabase environment, review the scope of the new tables and functions, confirm role permissions, and validate retention-policy defaults with the appropriate legal and business stakeholders. Because this is an additive release, rollback should preserve the existing opt-out and audit history tables while removing the new consent objects only after carefully reviewing downstream integrations.
