---
name: base-integration-testing
description: >-
  Platform-agnostic rules for writing integration tests — real collaborating
  units exercised across a real boundary, mocking only true external
  dependencies. The shared base for the api-integration-testing,
  webapp-integration-testing, and react-native-integration-testing skills. Use
  this whenever adding, reviewing, scaffolding, or improving ANY integration
  test, deciding what to mock vs. run for real, or fixing flaky/order-dependent
  tests — even if the user doesn't say "integration test" explicitly. Pair it
  with the matching platform skill (API, web app, React Native) for that layer's
  specifics.
---

# Base Integration Testing Rules

The shared, platform-agnostic rule set for **all** integration tests. The
specialized skills — `api-integration-testing`, `webapp-integration-testing`,
`react-native-integration-testing` — assume these rules and add only what is
specific to their layer. When working on a specific platform, apply this base
*and* the matching platform skill together.

> Scope note: an **integration test** exercises real collaborating units across a
> real boundary (a request path, a rendered screen, a navigation flow) with real
> internal dependencies, mocking **only** what you do not own or cannot make
> deterministic. These rules are not for pure unit tests (no I/O, fully isolated)
> nor for the contract/E2E suites that hit live third parties — those are
> separate, opt-in suites.

## 1. Scope & Philosophy

- Test **behavior through the public surface**, never through internal implementation details. The public surface is whatever a real consumer sees: an HTTP response, a rendered screen, a navigation outcome.
- Test the **full path** end to end within the layer under test — do not short-circuit past the wiring that integration tests exist to exercise.
- Assert on **observable outcomes**: the result a consumer can see *and* the resulting state (persisted data, dispatched events, stored values) — not on spies over internal functions.
- Mock **only** what you do not own or cannot make deterministic: third-party services, payments, email/SMS/push, LLMs, clocks, randomness, GPS/sensors. Never mock your own modules, store, or data layer.
- One test verifies **one behavior**. Do not bundle unrelated assertions into a single test.
- A test's name states the **behavior and condition**, e.g. `shows an error banner when the email already exists`.

## 2. Real Dependencies vs. Mocked Boundaries

- Use the **same engine and major version** as production for anything you own (database, cache, queue, store). Substituting a different implementation hides real differences in behavior, constraints, and features.
- Provision dependencies in **disposable, reproducible** environments (containers, a fresh app/store instance per run) so the suite is hermetic on any machine and in CI.
- Apply the project's **real setup path** (migrations, seed scripts, store initialization) so that path is tested too. Never hand-maintain a divergent test-only schema or config.
- Stub external dependencies at the **boundary** (network interceptor, injected fake client) rather than reaching deeper. Do not let the default suite make real outbound calls.
- Make each mock's behavior **explicit per test** (success / client error / server error / timeout) so you verify how the system reacts to each.
- Keep tests that hit real third parties in a **separate, opt-in suite** — never in the fast default run.

## 3. Isolation & Determinism

- Every test must be **independent and order-independent**. Never rely on state created by another test.
- **Reset state between tests** with one consistently applied strategy (transaction rollback, truncation, fresh store/instance). Pick the safest one for your concurrency model and apply it everywhere.
- Tests must be **deterministic**: no dependence on wall-clock time, timezone, locale, machine, or live network.
- **Inject or freeze time** and **seed randomness** so runs are repeatable.
- **Never `sleep`.** Wait on a condition with a bounded timeout (poll until true / await an event / await a visible result).
- Generate **unique data per test** (UUIDs, random suffixes) so parallel runs never collide.

## 4. Test Structure & Lifecycle

- Follow **Arrange–Act–Assert** (Given–When–Then). Keep the three phases visually distinct.
- Do **expensive setup once, globally** (start containers, run migrations, build the app/render harness). Do **cheap isolation per test**.
- **Tear everything down**: close connections/pools, stop containers, unmount components, clear interceptors, remove temp files — so the process exits cleanly and leaks no handles.
- Build test data with **factories/builders**, not large shared fixtures. Seed only what the test needs.
- A test must be **understandable on its own**. Avoid hidden magic in shared setup that a reader cannot see from the test body.

## 5. Authentication & Authorization

- Establish credentials/tokens/sessions **programmatically** in setup. Never drive a real login UI for unrelated tests, and never hardcode real or production secrets.
- Provide helpers to create users with **specific roles and permissions**.
- Always test the **unauthenticated** and the **unauthorized** paths explicitly, not just the happy authenticated case.

## 6. What to Assert

- Assert the **primary result** a consumer observes and the **side effects** (state created/updated/deleted, message enqueued, event dispatched, external call made with the expected payload).
- Assert **error and failure paths** with the same rigor as success.
- Do **not** assert volatile values (timestamps, generated IDs) by exact match — assert their **shape/presence**, use matchers, or control them via injected time.
- Treat assertions as **living documentation** of the contract — be precise.
- **Fail loudly and specifically**: assert concrete values so a failure message points straight at the cause.

## 7. Async & Background Work

- Test the **producer** (correct message/event/effect dispatched) and the **consumer** (correct processing) — separately if needed.
- Drive async work to completion via **inline processing or condition polling**, never by sleeping for it.
- Test **retry, failure, and dead-letter / error** paths, and verify consumers are **idempotent** under redelivery.
- For inbound events/webhooks/callbacks, test **validation and malformed/replayed payloads**.

## 8. Suite Health

- The integration suite must be **fast enough to run on every push**. Budget it and protect that budget.
- **Flaky is broken.** A nondeterministic test is a bug — fix it or quarantine it; never retry-until-green in CI as a habit.
- Tests must be **parallel-safe** (isolated data + isolated state) or explicitly marked serial.

## 9. Environment & CI

- Run the **identical suite** locally and in CI; containerized/reproducible dependencies make this consistent.
- Configure everything via **environment variables / config**. Never point tests at a shared, staging, or production datastore or backend.
- Use **dedicated, disposable test resources** that are always safe to wipe.

## 10. Anti-patterns (reject these everywhere)

- **Over-mocking** — mocking your own data layer/services turns an integration test into a unit test and hides the bugs this layer exists to catch.
- **Asserting on implementation** — checking an internal method was called instead of the resulting state or output.
- **Shared mutable state** — fixtures or seed data that tests depend on and mutate, creating order coupling.
- **Real third-party calls** in the default suite — slow, flaky, rate-limited, nondeterministic.
- **`sleep`-based waiting** — replace with condition polling.
- **Hidden magic in shared setup** — setup so implicit a test can't be understood on its own.
- **Snapshotting volatile output** — brittle snapshots full of timestamps/IDs that change every run.
