# Milestone 2 SQL execution order

## Required execution order

1. Milestone 1 foundation migration
   - supabase/migrations/20260902_000001_milestone_1_foundation.sql
2. Milestone 2 discovery migration package
   - supabase/migrations/20260902_000002_milestone_2_discovery.sql

## Migration package review

The Milestone 2 migration package includes:

- discovery_sources
- businesses
- business_contacts
- prospects
- campaigns
- nominations
- import_jobs
- import_rows
- workflow_assignments
- workflow_events
- possible_duplicates
- opt_outs
- prospect_source_events
- integration_statuses

It also creates database functions and triggers for:

- set_updated_at
- enforce_workflow_transition
- record_workflow_transition
- build_d9_match_candidate
- tenant_allowed_read

The execution order is intentionally kept as a single package following the foundation migration. It must not include the already-applied Milestone 1 migration file in a re-run or consolidation effort.

## Rerun and rollback notes

- The migration uses IF NOT EXISTS on tables and triggers to avoid duplicate object creation.
- The migration is designed for incremental execution only after the foundation package is already applied.
- Rollback should be planned as a controlled database-recovery step, not as a local script execution in this repository.
