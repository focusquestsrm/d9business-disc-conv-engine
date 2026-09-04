# Milestone 3A: Membership Verification

## Scope

This release adds the membership verification flow used to collect, validate, batch, export, review, and reconcile claims for D9 organizations. The implementation remains additive and local to the repository; it does not alter earlier milestone data or run live SQL against Supabase.

## Included components

- Business logic and validation rules in `src/lib/membershipVerification.ts`
- Automated validation in `src/lib/membershipVerification.test.ts`
- Verification queue, export/import screen, and member claim form in `src/App.tsx`
- Additive migration in `supabase/migrations/20260905_000001_milestone_3a_membership_verification.sql`
- Canonical verifier in `supabase/verification/verify_milestone_3a_membership_verification.sql`
- Navigation and dashboard metrics updates in the app shell

## Database model

The additive migration introduces the following objects:

- `public.verification_batches`
- `public.verification_cases`
- `public.verification_results`
- RLS policies for authorized verification access
- `updated_at` triggers for each new table

These tables allow the platform to queue claims, export them to organization review workbooks, accept returned responses, and reconcile final outcomes without affecting the earlier Discovery, Prospect, and Campaign schemas.

## Workbook flow

The Release 3A app supports:

1. Exporting a verification workbook in the required column order.
2. Importing a returned workbook for preview validation.
3. Checking batch consistency and duplicate case IDs.
4. Committing only accepted, valid rows.

The export logic uses the workbook column ordering defined by `buildVerificationExportColumns()` and the result validation defined by `validateVerificationResult()`.

## Security model

The migration preserves the approved D9 security model:

- tables are guarded behind Supabase RLS
- access is scoped to `current_user_is_platform_admin()` or the verification module permission
- no PostgreSQL roles are created outside the existing app-role pattern
- the migration is additive only and excludes destructive or live-environment changes

## Manual verification checklist

1. Open the Verification Queue page from the sidebar.
2. Confirm the dashboard shows the verification metrics.
3. Open the Member Claims page and submit a valid claim with consent.
4. Confirm the queue shows the new case in `ready_for_batch` or a similar active status.
5. Click Export workbook and confirm a `.xlsx` file downloads.
6. Import the workbook back into the queue and confirm the preview summary appears.
7. Confirm invalid result rows are blocked from commit.
8. Confirm the verification queue and dashboard remain aligned after import.
9. Run the SQL verifier against a local database instance only.

## Local validation

Run the project checks locally with the repo’s Windows-safe commands:

- `npm.cmd test -- --run`
- `npm.cmd run build`

Do not deploy to Netlify or run any migration against a live Supabase project.
