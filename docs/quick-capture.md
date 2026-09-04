# D9Network Quick Capture

## Purpose

Quick Capture is a fast internal intake workflow for D9Network staff who identify a potential member, business owner, partner, organization, or professional lead from social media, referrals, websites, events, or alliance channels. It is intentionally lighter than the full prospect record editor and is designed for quick mobile-friendly entry while still writing into the core D9 discovery pipeline.

## Eligible users

This intake form is intended for authorized internal D9Network users only. It remains protected behind the app's existing Supabase authentication and role checks. It is not a public-facing form and it should not accept anonymous submissions.

## Required identifier rule

Each submission must include at least one meaningful identifier from the following list:

- Social handle
- Social or profile URL
- Email address
- Phone number
- First and last name
- Business or organization name

If no identifier is present, the form rejects the record before it can be saved.

## Core fields

The form includes the requested quick-capture fields for prospect type, platform, handle, URL, names, business record, email, phone, website, city, state, association, source type, source name, notes, follow-up priority, and assignment ownership.

The form intentionally keeps the initial screen short and moves lower-frequency details into the collapsed "Add more details" section.

## Duplicate behavior

Before creating a new record, the form checks for existing matches using normalized social, URL, email, phone, website, first name + last name, and business name signals. Existing behavior is intentionally conservative:

- Exact strong match: existing record surfaced for manual review before creating another prospect
- Possible match: review path before creating a new record
- No match: proceed with a new prospect record
- Existing populated data is never overwritten with blank values
- Source and submission history is preserved when information is added to an existing record

## Workflow routing

The quick-capture record is routed into the operational workflow using the same discovery and prospect model already in use by the app.

Recommended operating behavior:

- Handle or URL only: Needs enrichment
- Contact method present and no duplicate: Ready for outreach
- Possible duplicate: Possible duplicate review
- Opted-out or suppressed match: Do Not Contact and block outreach

This route does not mark a person as a registered member or verified Greek member.

## Database objects used

The form reuses the existing application objects and workflow model.

- public.prospects
- public.workflow_events
- public.prospect_source_events
- public.workflow_assignments
- public.opt_outs
- public.audit_events
- public.user_role_assignments
- public.roles

## Schema changes

No new migration was required for this task because the project already contains the needed Milestone 2 discovery, workflow, duplicate, and audit objects. The app reuses the existing database structure rather than creating a parallel model.

## Security and RLS assumptions

- Supabase auth remains the entry point
- Internal-only access is enforced through existing role assignment and RLS patterns
- Anonymous inserts are blocked by the existing table policies
- Sensitive contact and notes data remain protected by the existing RLS model
- Created and modified actor metadata remains associated with the saved record
- No service-role key is exposed in the browser
- browser logs do not include PII

## Manual verification steps

1. Sign in as an internal user with access.
2. Open the dashboard and confirm the New Prospect CTA opens the Quick Capture route.
3. Submit a record with only an Instagram handle and confirm the record saves.
4. Submit a record with only a profile URL and confirm the record saves.
5. Submit a record with a name only and confirm the record saves.
6. Attempt an empty submission and confirm validation prevents save.
7. Confirm invalid email, phone, and profile URL values are blocked.
8. Confirm duplicate detection blocks an accidental second record.
9. Confirm the route returns the user to the dashboard from the standalone layout.
10. Check the saved prospect in the operational workflow and work-queue views.

## Notes

This route remains part of the existing D9 app and does not create a separate repository, database, or disconnected application.
