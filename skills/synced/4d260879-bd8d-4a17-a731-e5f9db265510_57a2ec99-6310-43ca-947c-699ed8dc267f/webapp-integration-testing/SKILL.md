---
name: webapp-integration-testing
description: >-
  Standards for browser-based integration / UI tests of a web app — a real
  browser rendering the real frontend against a real or controlled backend,
  asserting on what the user sees and does. Use whenever adding, reviewing,
  scaffolding, or improving end-to-end / UI / browser tests for a web app, wiring
  up server lifecycle for browser tests, choosing locators, handling waits, or
  intercepting network for deterministic UI states — even if the user just says
  "test this page/flow." This is the policy layer; it relies on Anthropic's
  webapp-testing skill as the Playwright execution harness, and builds on the
  base-integration-testing skill.
---

# Web App Integration Testing Rules

Web-app-specific layer. **Also apply the `base-integration-testing` skill** for
the shared rules (isolation, determinism, structure, auth, assertions, suite
health, CI). This skill adds only what is specific to driving a real browser
against a running web application.

> Scope note: **web-app integration / UI tests** — a real browser rendering the
> real frontend, talking to a real or controlled backend, asserting on what the
> user can see and do. Not for pure component unit tests (no browser) and not for
> API-only tests (use api-integration-testing).

## Execution tool: use Anthropic's webapp-testing skill

This skill is the **standards** layer (what to test, what to assert, what to
mock). For **execution**, use Anthropic's `webapp-testing` skill — the Playwright
toolkit at `https://github.com/anthropics/skills/blob/main/skills/webapp-testing/SKILL.md`.
It provides native Python Playwright scripting plus `scripts/with_server.py` for
server lifecycle (run it with `--help` first; treat bundled scripts as black
boxes). Don't rebuild a Playwright wrapper — that skill is the maintained harness;
the rules below wrap it.

## 1. Drive the App Like a User

- Interact through the **rendered UI** — visible text, roles, labels, placeholders — not through internal component state, store internals, or test-only hooks where a semantic locator exists.
- Prefer **role/text/label locators** (`get_by_role`, `text=`, accessible names) over brittle CSS/XPath tied to structure or styling.
- Assert on **what the user observes**: rendered content, navigation/URL, visible feedback (banners, toasts, validation messages) — plus the resulting backend state where it matters.
- A test should read as a **user story**: arrange the page state, perform the user actions, assert the visible outcome.

## 2. Waiting & Determinism (web specifics)

The base forbids `sleep`. Concretely, for a browser:

- After navigation or an action that triggers fetches, **wait for `networkidle`** (or a specific element/response) before inspecting or asserting.
- Wait on **conditions**: `wait_for_selector`, `wait_for_url`, `expect(...).to_be_visible()` — never a fixed timeout.
- Use Playwright's **auto-waiting** assertions/locators instead of manual polling where possible.
- Follow **reconnaissance-then-action**: render, wait for idle, inspect the DOM (screenshot / `page.content()` / locator listing), discover real selectors, then act on them.

## 3. Backend & Network Control

- Decide per suite whether the test runs against a **real backend** (true end-to-end) or a **controlled one**. State it explicitly; don't mix silently.
- When isolating the frontend, **intercept at the network boundary** (Playwright route interception) to serve deterministic responses — the web equivalent of stubbing third-party HTTP. Do not reach into app internals to fake data.
- For full-stack tests, manage frontend **and** backend with `with_server.py` (it supports multiple servers) and reset backend state between tests.
- Make each intercepted response **explicit per test** (success / slow / error) so you exercise loading, empty, and error UI states.

## 4. Scenario Coverage (per flow / screen)

- **Happy path** — the primary user flow completes and shows the expected result and persisted state.
- **Form validation** — required fields, bad input, inline error messages, disabled/enabled submit.
- **Loading & empty states** — pending requests show a loading affordance; no-data shows the empty state.
- **Error states** — backend 4xx/5xx and network failure surface the right user-facing message, not a blank/broken screen.
- **AuthN/AuthZ** — unauthenticated users are redirected/blocked; role-gated UI is hidden/denied (seed sessions programmatically rather than clicking through login each time).
- **Navigation & deep-linking** — routes load directly, back/forward behave, guarded routes redirect.
- **Critical responsive/viewport** behavior, where the layout meaningfully changes.

## 5. Browser Hygiene

- Always launch **chromium headless** for CI runs; **close the browser** when done.
- Isolate **browser state** (cookies, storage) per test — use a fresh context/page so sessions don't leak between tests.
- Capture **screenshots and console/network logs** on failure to make diagnosis fast; the webapp-testing skill's examples show console logging.

## 6. Anti-patterns (web specifics, on top of the base)

- **Selector coupling to structure/styling** — locators tied to nth-child, class names, or DOM shape break on every refactor; prefer roles/text.
- **Fixed `wait_for_timeout` as a fix for flakiness** — wait for the actual condition instead.
- **Inspecting the DOM before `networkidle`** on dynamic apps — you assert against a half-rendered page.
- **Testing through component internals** — reaching into React/Vue state instead of the rendered UI turns this back into a unit test.
- **One giant end-to-end test** that walks the whole app — keep one behavior per test.
