# Architecture

## Frontend

- React 19 + TypeScript + Vite
- Client-side routing through React Router
- Local mock data store to model campaigns, prospects, and metrics
- Plain CSS tokens to match the D9Network design direction without introducing an external UI library

## Application design

- Compact left navigation shell
- Operational header with workspace actions
- Page-level cards, filters, metric summaries, and tables
- Responsive behavior for narrower screens

## Data and roles

This release is intentionally framework-first. It includes a mock domain model that aligns with the production schema described in the project brief and includes a SQL migration sketch for later Supabase implementation.

## Future integration path

The planned production architecture is:

- Supabase PostgreSQL for operational storage and row-level security
- Supabase Auth for staff authentication
- Supabase Storage for media assets
- Netlify for frontend hosting
- Edge functions for import validation, workflow events, and adapters
