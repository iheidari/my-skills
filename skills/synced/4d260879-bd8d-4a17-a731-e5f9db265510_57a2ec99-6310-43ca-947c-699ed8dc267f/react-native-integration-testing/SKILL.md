---
name: react-native-integration-testing
description: >-
  Rules for React Native integration tests — real screens with real navigation,
  store/context, and data layer, driven through user interactions, mocking only
  native modules and true third-party boundaries. Covers fast in-JS render tests
  (React Native Testing Library + Jest) and opt-in device/E2E (Detox or Maestro).
  Use whenever adding, reviewing, scaffolding, or improving screen, navigation,
  flow, or component-integration tests for a React Native / Expo app, mocking
  AsyncStorage / permissions / native modules, or covering loading/error/offline
  and platform-specific behavior — even if the user just says "test this screen."
  Builds on the base-integration-testing skill; apply that base too.
---

# React Native Integration Testing Rules

React-Native-specific layer. **Also apply the `base-integration-testing` skill**
for the shared rules (isolation, determinism, structure, auth, assertions, async,
suite health, CI). This skill adds only what is specific to testing a React
Native app — screens, navigation, native modules, and async data — wired together.

> Scope note: **React Native integration tests** — rendering real screens with
> real navigation, context/store, and data layer, driven through user
> interactions, mocking only native boundaries and true third parties. Two
> complementary execution modes:
> - **In-JS render tests** (React Native Testing Library + Jest) — fast, run on
>   every push; the default integration layer.
> - **Device/E2E tests** (Detox or Maestro on a simulator/emulator) — full native
>   stack; a smaller, slower, opt-in suite for critical flows.
> Apply these rules to both; notes call out where a mode differs.

## 1. Render Real Trees, Drive Like a User

- Render the **real screen with its real providers** (navigation container, store/context, query client, theme) — not a component in isolation with everything stubbed. Wiring is the point.
- Query through **user-facing queries**: accessible role, label, text, `testID` only where no semantic query fits. Avoid asserting on internal component state or props.
- Drive interactions with **`fireEvent` / `userEvent`** (press, type, scroll) as a user would; assert on **what renders** and on resulting state/side effects.
- Each test reads as a **user story**: arrange screen + data, perform actions, assert visible outcome.

## 2. Mock the Native Boundary — Not Your App

The base says mock only what you don't own. For React Native the boundary is
**native modules and platform APIs**, which can't run in a JS test environment:

- Mock **native modules / platform APIs**: AsyncStorage, secure storage, push notifications, camera, geolocation, biometrics, permissions, `Linking`, haptics. Use the libraries' official mocks where provided.
- Mock **device/OS state** explicitly per test: platform (`Platform.OS`), dimensions, network reachability (NetInfo), app foreground/background.
- Do **not** mock your own navigation, store, reducers, hooks, or data-transformation code — exercise them for real.
- Keep your **API/data layer** real but **intercept at the network boundary** (e.g. MSW or a fetch/axios interceptor) to serve deterministic responses. Don't make real network calls in the default suite.

## 3. Navigation

- Test **navigation as behavior**: perform the action, assert the destination screen is rendered and received the correct params — not that a `navigate` spy was called.
- Render with a **real navigator** (a test wrapper around the real stack/tab navigator) so guards, params, and deep links are exercised.
- Cover **deep links / initial routes**, **back behavior**, and **auth-gated navigation** (signed-out users land on auth, signed-in on the app).

## 4. Async & Data (RN specifics)

- Use **`findBy*` queries and `waitFor`** to await rendered results; never a fixed delay.
- Wrap state-updating interactions so updates flush (`act` / async `waitFor`) to avoid "not wrapped in act" warnings — treat those warnings as failures.
- Cover **loading, success, empty, and error** UI for every data-driven screen by controlling the mocked response per test.
- For **offline / cached** behavior, drive the network-state mock and assert the app reads from cache and reconciles on reconnect.

## 5. Scenario Coverage (per screen / flow)

- **Happy path** — the flow completes, the right screen renders, state/storage updated.
- **Form validation** — required fields, bad input, inline errors, submit en/disabled.
- **Loading / empty / error states** — driven by the mocked data layer.
- **Navigation** — correct destination + params; back; deep link; guarded routes.
- **AuthN/AuthZ** — signed-out vs signed-in vs role-gated screens (seed auth state programmatically).
- **Platform differences** — iOS vs Android branches where behavior diverges (`Platform.select`, platform files).
- **Permissions** — granted vs denied paths for camera/location/notifications.
- **Persistence** — values written to and rehydrated from storage across a remount.

## 6. Device / E2E Mode (Detox / Maestro)

For the opt-in native suite:

- Run on a **pinned simulator/emulator image** (OS version, device) for reproducibility; the device is the disposable environment.
- Keep it **small and critical-path only** — it is slow; the JS render suite carries the bulk of coverage and runs on every push.
- **Reset app state between tests** (reinstall / clear data / relaunch clean) so tests stay independent.
- Use the framework's **synchronization** (Detox auto-sync, Maestro waits) instead of manual sleeps; disable or control animations that defeat synchronization.
- Point the app at a **controlled backend or mock server**, not production.

## 7. Anti-patterns (RN specifics, on top of the base)

- **Shallow rendering** for integration tests — it stubs children and defeats the purpose; render the full tree.
- **Asserting on navigation spies** instead of the rendered destination screen.
- **Over-mocking JS modules** (your own hooks/store) because something is awkward — fix the seam, don't mock your app.
- **`testID` everywhere** as the primary query — prefer accessible role/text; reserve `testID` for genuinely unqueryable elements.
- **Fixed timers / `setTimeout` waits** — use `findBy*` / `waitFor`.
- **Ignoring `act` warnings** — they signal unflushed async state and produce flaky tests.
