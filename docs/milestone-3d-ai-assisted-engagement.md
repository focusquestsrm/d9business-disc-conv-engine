# Milestone 3D: AI-Assisted Engagement

## Overview

Milestone 3D introduces a human-approval workflow for AI-assisted engagement suggestions. It is intentionally scoped to a provider-neutral, suggestion-only experience. No autonomous sending exists, no live provider integrations are connected, and no AI provider credentials are required for this phase.

The system supports:

- drafting AI suggestions for comment, direct-message, email, and follow-up actions
- human review and approval before outreach is considered eligible
- consent and suppression checks prior to any send pathway
- frequency and cooldown enforcement
- outcome classification and escalation review
- follow-up reminder tracking
- evidence-oriented audit history for all approval and delivery actions

## Architecture

The Release 3D flow is intentionally layered:

1. Database layer
   - additive migration tables for suggestions, approvals, outreach attempts, reminders, classifications, escalations, frequency rules, and prompt templates
   - RPCs that enforce the human-approval contract and protect sensitive operations
   - RLS plus trigger logic to keep approval and eligibility state durable

2. Repository layer
   - typed repository contract for all SQL-backed Release 3D operations
   - payload names match the exact stored procedure parameter names
   - repository methods remain neutral and deterministic for local/test usage

3. UI layer
   - review queue for suggestions requiring human attention
   - follow-up review with snooze, completion, and cancellation controls
   - escalation management with severity, assignment, and resolution tracking
   - timeline/audit views that preserve the chain of evidence

4. Domain logic layer
   - local generation templates for suggestion creation
   - eligibility evaluation logic
   - classification heuristics for safe, sensitive, and unclear replies
   - safety labels and escalation triggers

## Human-approval workflow

The Release 3D workflow is intentionally conservative:

- draft: the system may generate a candidate suggestion
- generated: a local or provider-generated draft is ready for review
- needs_review: staff review is required
- approved: a suggestion has passed human review and can be eligible for approved delivery
- pending_delivery: delivery is intentionally not live; this state represents approval evidence retained for later delivery
- delivered or delivery_failed: only after an approved record is sent through a durable and confirmed send path

The system enforces the following transitions:

- changes_requested returns the record to draft
- rejected content cannot progress
- cancelled content cannot progress
- blocked content cannot be approved
- editing approved content invalidates approval evidence
- newly recorded opt-out blocks approved but undelivered content
- sensitive or uncertain responses remain held
- delivery cannot occur without durable approval evidence

## State machine

```text
draft
  -> generated
  -> needs_review
  -> approved
  -> pending_delivery
  -> delivered
  -> delivery_failed

changes_requested -> draft
rejected -> terminal
cancelled -> terminal
blocked -> terminal

opt_out or suppression while approved but not delivered -> blocked
sensitive/uncertain response -> hold
```

## Consent and suppression precedence

Approval and delivery checks must evaluate in this order:

1. global or channel opt-out / suppression block
2. consent missing or withdrawn
3. sensitive-response hold
4. disconnected provider state
5. provider activity permission denied
6. frequency or cooldown failure
7. missing prospect match confirmation
8. missing human approval evidence
9. approval-gated delivery only after all checks pass

This precedence is enforced in the repository contract and reflected in the local UI logic.

## Frequency rules

The platform supports frequency rules by purpose, channel, and platform. These rules enforce:

- maximum attempts within a time window
- cooldown windows between messages
- blocking of sends that exceed the configured limits
- explicit denial reasons for frequency limit failures

Frequency enforcement is advisory in UI and required in the database/RPC contract.

## Personalization inputs

AI suggestions may draw from a limited set of personalization inputs:

- prospect name
- business name
- social handle
- platform and channel
- note or purpose context
- source context
- frequency and consent metadata

These values are used only to help generate a draft. They do not permit autonomous sending or high-risk personalization.

## Prohibited sensitive personalization

The platform must not personalize or target the following types of content:

- medical or personal crisis content
- explicit financial exploitation or scam targeting
- sensitive identity or discrimination-based framing
- personal health or crisis messaging
- manipulative or coercive persuasion around emotional vulnerabilities

Any such case is treated as escalation-sensitive and held for manual review.

## Classification and escalation

Outcome classification uses a deterministic process that can flag:

- positive interest
- information requested
- follow-up needed
- not interested
- opt-out request
- complaint
- sensitive or uncertain outcomes

Escalations are generated for sensitive content, low-confidence classification, missing consent clarity, uncertainty, compliance concerns, and manual-review conditions.

## AI provider status

AI provider connections are intentionally deferred. At this milestone:

- no external AI provider is connected
- no live provider credentials are activated
- AI is suggestion-only
- provider-neutral templates remain available for local test and review functions
- the UI displays “Approve suggestion” and retains the record as approved or pending delivery without claiming a real live send

## Delivery-provider status

Social and email delivery providers are also deferred. The UI must not show or imply a successful live send. Any delivery action remains a local, reviewed, approved state that is stored for future activation.

## Manual delivery recording

Manual delivery recording is supported as a durable audit step for future provider activation. It records:

- target prospect and channel
- provider/platform context
- content snapshot
- manual sender identity
- approval and eligibility evidence
- whether the record was manually sent or blocked

This is not treated as an autonomous send or live provider delivery.

## Known limitations

This milestone deliberately does not implement:

- external AI provider activation
- live social/email outbound delivery
- webhook or real-time event subscriptions
- autonomous approval or delivery
- broad provider state synchronization
- a duplicate queue or competing work system beyond the existing platform flow

## Future provider activation

When provider integration is later enabled, the Release 3D contract remains compatible with:

- provider capability checks
- durable approval evidence
- escalation holds
- manual review before actual send
- explicit state transitions from approved to pending_delivery to delivered

## Audit evidence

The audit trail preserves:

- suggestion generation metadata
- approval and rejection reasons
- eligibility checks and suppression decisions
- frequency checks and cooldown reasons
- classification confidence and required review flags
- escalation reasons and assignments
- follow-up lifecycle details
- manual delivery or provider result status

All records are intended to be reviewable by staff and auditable across manual and automated actions.

## AI is suggestion-only

AI is not permitted to autonomously send or publish outreach content in this milestone. Human review and approval are required for every progression beyond the draft stage.
