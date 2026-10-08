---
name: api-integration-testing
description: >-
  Rules and patterns for integration tests that drive an API through its real
  request path — real HTTP handlers against a real database/cache/queue, mocking
  only true third-party boundaries. Use whenever adding, reviewing, scaffolding,
  or improving integration tests for API endpoints/routes/controllers, setting up
  a test database or container, deciding what to mock, or covering status codes,
  auth, validation, pagination, idempotency, webhooks, and error responses — even
  if the user just says "write tests for this endpoint." Builds on the
  base-integration-testing skill; apply that base too.
---

# API Integration Testing Rules

API-specific layer. **Also apply the `base-integration-testing` skill** — it
covers scope, real-vs-mocked boundaries, isolation, determinism, structure,
auth, assertions, async, suite health, and CI. This skill adds only what is
specific to testing an API through its real request path. If the base skill is
available, consult it first.

> Scope note: **API integration tests** — driving real HTTP handlers against
> real dependencies while mocking only true third-party boundaries. Not for pure
> unit tests, and not for full browser/UI end-to-end tests (use
> webapp-integration-testing for those).

## 1. API Request Path

- Test the **full request path**: routing → middleware → auth → validation → handler → service → real datastore → serialized response.
- Test through the **public contract** (status code, headers, body shape), never through handler internals.
- Prefer driving the app **in-process** (pass the app/handler an in-memory request) over a real network socket, unless the test specifically needs the full network stack.
- Run the **same database engine and major version** as production. Never substitute an in-memory or different-dialect database.
- Apply the project's **real migrations** to the test database so migrations are tested too.

## 2. Resetting State Between Tests

- Reset with one consistently applied strategy: per-test transaction rollback, table truncation, or a fresh schema/template DB.
- **Truncation is the safest default** when background workers use their own connections (a per-test transaction won't be visible to them).

## 3. What to Assert (API specifics)

- Assert the **status code**, the **response body** (shape and relevant values), and any **meaningful headers** (content-type, location, pagination, cache).
- Assert the **side effects**: rows created/updated/deleted, message enqueued, event published, external call made with the expected payload.
- Assert **error responses** with the same rigor as success: correct status code *and* the documented error body.

## 4. Scenario Coverage (per endpoint)

For each endpoint, cover at minimum:

- **Happy path** — valid request returns the expected success response and state change.
- **Validation** — missing fields, wrong types, out-of-range/boundary values, unexpected extra fields.
- **AuthN/AuthZ** — unauthenticated (401), wrong user, insufficient role (403), expired/invalid token.
- **Not found** — referencing a non-existent resource returns 404.
- **Conflict / uniqueness** — duplicate creation returns 409 (or the documented behavior).
- **Idempotency** — repeating a request (where guaranteed) does not double-apply effects.
- **Pagination / filtering / sorting** — query params behave and bound results correctly.
- **Concurrency** — where the API guarantees an invariant under simultaneous requests.
- **Rate limiting** — if enforced, the limit and its response are exercised.

## 5. Async & Background Work (API specifics)

- Process background work **synchronously/inline** in tests, or **drain the queue and assert**, rather than sleeping for it.
- For inbound **webhooks**, test signature verification and malformed/replayed payloads.

## 6. Tooling Notes

- Mint valid credentials/tokens/sessions programmatically; never call the real login endpoint of an unrelated service to get a token.
- Stub third-party HTTP at the **network boundary** (request interceptor) or inject a **fake implementation** of the client interface.

## Add framework specifics here

Add language/framework-specific setup snippets (e.g. supertest, pytest +
Testcontainers, RestAssured) as separate `references/<framework>.md` files and
point to them from this body, rather than inlining them all.
