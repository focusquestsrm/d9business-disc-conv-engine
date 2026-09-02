# Data model overview

The production model is planned around a normalized operational schema with canonical people and businesses, prospect acquisition records, workflow tasks, and consent history.

## Core entities

- staff_profiles
- roles
- user_role_assignments
- campaigns
- campaign_assignments
- prospects
- people
- businesses
- business_people
- d9_connections
- consent_records
- communication_templates
- engagements
- questionnaire_submissions
- verification_reviews
- profile_claims
- marketplace_listings
- membership_records
- membership_conversions
- growth_interests
- growth_handoffs
- spotlight_records
- media_assets
- outcomes
- suppressions
- import_jobs
- import_rows
- match_candidates
- workflow_tasks
- workflow_events
- audit_events
- application_settings

## Release 1 state

This release implements a front-end domain model and UI workflow using mock data and local component state. The production database design remains scaffolded for the planned Supabase migration.
