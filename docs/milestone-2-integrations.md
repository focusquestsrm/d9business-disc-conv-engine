# Milestone 2 integration boundaries

## Principle

The system must not duplicate the membership service already provided by Brilliant Directories or the D9Network Intelligence Dashboard. The app should consume those systems through typed interfaces and preserve a clear provider boundary.

## Provider contract

- provider name
- integration status
- request model
- response model
- external record id
- match status
- limited snapshot
- last checked timestamp
- error status
- retry eligibility
- audit event reference

## Supported statuses

- not_configured
- configured
- healthy
- degraded
- failed

## Local interface model

The repository includes a typed integration contract in src/lib/integrations.ts. It models the boundary without creating a real external service endpoint or credentials.

## Deferred live requirements

- actual Brilliant Directories API contract details
- actual D9 Intelligence credentials and endpoint configuration
- real external health checks
- production runtime secret storage and rotation
- live provider tests routed through the repository/data-service layer

## Social media readiness

The project preserves future social source fields and service boundaries for Instagram and Facebook, but does not implement unofficial scraping, automated DMs, or live publishing in Milestone 2.
