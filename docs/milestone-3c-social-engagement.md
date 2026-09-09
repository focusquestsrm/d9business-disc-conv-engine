# Milestone 3C — Social Engagement Connections

Date reviewed: 2026-09-08

This document outlines the approved connection and ingestion framework for social engagement in the D9 Business Discovery Conversational Engine. It is intentionally conservative: any platform capability that is not explicitly validated with approved credentials, permissions, and production configuration remains marked as unavailable, restricted, or future-dependent.

## Scope and operating principle

This release establishes the production-ready connection, ingestion, matching, inbox, and routing framework. It does not claim that Instagram, Facebook, LinkedIn, or email are live unless valid credentials, permissions, and successful connection validation exist.

Where credentials or official platform approval are unavailable, the implementation:

- creates a connection lifecycle and adapter contract;
- supports safe manual or test ingestion;
- marks the connection as draft, pending, disconnected, restricted, or unavailable;
- exposes clear capability and limitation metadata;
- does not hard-code secrets or client-side access tokens;
- does not simulate production activity as if it were live.

## Platform capability matrix

### Instagram

- Supported account types: Business or creator accounts with Meta approval and app configuration.
- Authentication method: Meta Graph API or approved Instagram Graph API access via server-side configuration; no client-side tokens are allowed in the browser.
- Inbound-message availability: May be available only with Business/Creator account permissions and approved webhook or API access.
- Comment/reply availability: Controlled by platform rules, content type, and account configuration.
- Webhook availability: Subject to Meta app approval, webhook verification, and event subscriptions.
- Sending/reply limitations: Platform-specific rate limits, messaging permissions, and eligibility rules apply.
- Review or approval requirements: Platform approval, app status, and account eligibility checks are required before production-use activation.
- Rate limits or quota considerations: Subject to Meta API quotas and app-level limits.
- Retention limitations: Platform retention and API availability can vary and must be reaffirmed before activation.
- Prohibited automation: Automated outreach or reply behavior must comply with platform policy and the project’s consent rules.
- Required permissions: Meta app configuration, required app scopes, and approved page/account permissions.
- Release 3C implementation now: Connection record, adapter contract, safe manual/test ingestion support, and structured metadata placeholders for future validation.
- Configuration-dependent: Webhooks, app validation, live message ingestion, and production message sending.
- Unsupported: Claiming that Instagram is live without verified credentials and platform validation.
- Official source: https://developers.facebook.com/docs/instagram-platform/ and https://developers.facebook.com/docs/graph-api/ (reviewed 2026-09-08)

### Facebook

- Supported account types: Business pages and approved business assets with Meta app configuration.
- Authentication method: Server-side Meta Graph API configuration and approved access tokens.
- Inbound-message availability: Only available for eligible page or account configurations with permission and webhook or API access.
- Comment/reply availability: Subject to page type, moderation, and messaging permissions.
- Webhook availability: Available through approved Meta app subscription configuration, subject to validation.
- Sending/reply limitations: Rate limits, allowed message types, and platform policy govern any outbound action.
- Review or approval requirements: Meta app review and account permission checks are required before live production activation.
- Rate limits or quota considerations: Subject to Meta API quotas and usage tiers.
- Retention limitations: Provider-side retention varies and must be revalidated before activation.
- Prohibited automation: Messaging automation must align with platform policy and explicit user consent requirements.
- Required permissions: Approved page permissions, app configuration, and access scope management.
- Release 3C implementation now: Connection record, provider-neutral adapter contract, and controlled metadata for pending or restricted state.
- Configuration-dependent: Live page message ingestion, mirrors, reply workflows, and production webhook validation.
- Unsupported: Real Facebook production activity without a validated app/page configuration.
- Official source: https://developers.facebook.com/docs/pages and https://developers.facebook.com/docs/messenger-platform/ (reviewed 2026-09-08)

### LinkedIn

- Supported account types: Official page and professional account types where LinkedIn officially permits API or messaging integrations.
- Authentication method: LinkedIn developer app configuration and server-side OAuth, where officially supported.
- Inbound-message availability: Not universally available across all account types or developer app scopes.
- Comment/reply availability: Official restrictions may apply and are not assumed in this release.
- Webhook availability: Only where official developer capabilities are available and approved.
- Sending/reply limitations: Official quotas, API permits, and policy constraints govern what can be automated.
- Review or approval requirements: LinkedIn developer app review and platform approval remain required before becoming operational.
- Rate limits or quota considerations: Alice with LinkedIn’s official rate limits and partner conditions.
- Retention limitations: Provider retention is platform-controlled and should be verified before activation.
- Prohibited automation: Unapproved or unsupported messaging automation is not represented as live.
- Required permissions: LinkedIn app approval and account-level permissions where officially provided.
- Release 3C implementation now: Connection record and restricted state placeholders with clearly documented limitations; no live activation claim is made.
- Configuration-dependent: Official LinkedIn messaging or webhook capabilities, if and when supported for the organization.
- Unsupported: Assuming LinkedIn messaging is available without explicit platform authorization.
- Official source: https://learn.microsoft.com/en-us/linkedin/ and https://www.linkedin.com/developers/ (reviewed 2026-09-08)

### Email

- Supported account types: Approved organizational mail infrastructure or provider-specific mailbox accounts that are explicitly configured.
- Authentication method: Server-side provider adapter or trusted mailbox integration; no personal mailbox passwords are stored.
- Inbound-message availability: Configurable through approved webhook adapters, provider APIs, or safe manual/test ingestion.
- Comment/reply availability: Not applicable to email inbox threads unless explicitly supported by the selected provider.
- Webhook availability: Depends on the selected provider and approval model.
- Sending/reply limitations: Subject to provider policies, email deliverability restrictions, and consent rules.
- Review or approval requirements: Organization approval and security review are required before production use.
- Rate limits or quota considerations: Provider dependent; must be evaluated against the selected mail platform.
- Retention limitations: Mailbox and provider retention policies apply and can change.
- Prohibited automation: Unapproved bulk messaging or sending without valid consent is prohibited.
- Required permissions: Approved provider configuration, mailbox access model, and organization authorization.
- Release 3C implementation now: Generic email connection model with safe manual/test ingestion and consent gate enforcement before any outbound activity.
- Configuration-dependent: Approved provider selection, mailbox integration, and webhook availability.
- Unsupported: Assuming a specific provider such as Microsoft, Google, SMTP, or IMAP unless that provider is individually approved in the project.
- Official source: Provider-specific official documentation for the selected mailbox provider only (reviewed 2026-09-08)

## Consent and suppression precedence

Outbound activity must not be recorded or initiated unless Release 3B outreach eligibility is satisfied. In practice, this means:

- global opt-out overrides all channels;
- channel suppression blocks that channel;
- missing consent blocks outreach;
- withdrawn or expired consent blocks outreach;
- outbound activity is recorded only after eligibility is confirmed.

This is enforced inside the engagement library and by the canonical Release 3B consent logic.

## Matching rules

Automatic prospect linking is allowed only when there is a deterministic, strong, unambiguous key match such as:

- existing platform identity already linked to a single prospect;
- a verified email linked to one prospect;
- a confirmed external account/handle mapping;
- an existing provider thread already attached to one prospect.

Automatic linking is not allowed based on display name, similar names, photos, general organization names, ambiguous handles, or message text alone.

Ambiguous matches remain unmatched, generate match candidates, and route to the work queue for review.

## Required 3C implementation features

The repository includes the Release 3C migration, verifier, routing logic, and source-preservation library functions. The implementation deliberately keeps platform-specific parsing in focused library modules rather than spreading it through the app shell.

## Revalidation requirement

Platform capabilities can change. Before any production activation, the organization must revalidate the platform terms, app approval state, account permissions, rate limits, and webhook support against current official documentation.
