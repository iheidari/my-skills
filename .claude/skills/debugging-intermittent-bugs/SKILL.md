---
name: debugging-intermittent-bugs
description: Parallel-hypothesis workflow for intermittent or flaky bugs — reproduce with a failing test, race 3-4 agents on distinct root-cause theories, and apply only the fix that provably makes the test pass. Use when a bug is described as intermittent, flaky, random, non-deterministic, "sometimes happens", "can't reproduce", or when a previous fix for the same bug didn't hold.
---

# Debugging Intermittent Bugs

Intermittent bugs invite wrong theories: a fix "works" because the bug didn't
happen to fire, not because the cause was found. This workflow prevents that by
requiring every theory to prove itself against a reliable failing test, with
competing hypotheses investigated in parallel instead of anchoring on the first
plausible one.

**Do not change any production code until step 3 selects a proven fix.**

## 1. Reproduce with a failing test

Follow the `diagnosing-bugs` skill (Phases 1–2) to build a tight feedback loop
and turn it into a failing test. For intermittent bugs the key move is raising
the reproduction rate until it is debuggable: loop the trigger 100×,
parallelise, stress, pin time/RNG/network, narrow timing windows.

Gate: a test you have run that fails reliably (or at a pinned, high rate) on
this bug. No test, no hypotheses.

## 2. Race 3–4 parallel agents on distinct hypotheses

Generate 3–4 **distinct** root-cause hypotheses (different mechanisms — e.g.
race condition, stale cache, ordering assumption, environment/timing — not
variations of one idea). Then spawn one agent per hypothesis, all in a single
message so they run concurrently. Each agent's brief:

- The failing test command and its observed output.
- Its one hypothesis, stated falsifiably ("if X is the cause, then Y").
- Its job: prove or disprove the hypothesis **against the failing test** —
  instrument, or apply a candidate fix in isolation and run the test enough
  times to distinguish "fixed" from "didn't fire this run".
- Report back: verdict (proven / disproven / inconclusive), evidence, and the
  candidate fix diff if proven.

## 3. Apply only the proven fix

Adopt the fix from the agent whose hypothesis actually made the test pass —
verified by re-running the test repeatedly at the original reproduction
conditions, not just once. If no agent proves its theory, generate new
hypotheses and race again; do not "try the most likely one anyway".

## 4. Verify and ship

- Keep the reproduction test as a permanent regression test.
- Run the full typecheck, lint, and test suite.
- Open a PR whose description includes: the proven root cause, the rejected
  hypotheses and the evidence that disproved each, and how the regression test
  pins the bug. The rejected-theories writeup is required — it saves the next
  debugger from re-walking dead ends.
