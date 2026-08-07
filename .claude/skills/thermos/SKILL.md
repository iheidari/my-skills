---
name: thermos
description: "Launch both thermo-nuclear review subagents in parallel, then synthesize their findings. Use when the user asks for thermos, a double thermo review, or a combined bug/security and code-quality branch audit — and when another skill (create-pr, do-task, ship) calls for a thermos pass."
---

# Thermos

Run the two thermo review passes as async background subagents in parallel, then synthesize their results.

## Invocation

Callable directly by the user (`/thermos`) or by another skill via the Skill tool — `create-pr`
and `do-task` both call for a thermos pass.

When another skill invokes it, that skill supplies the scope (a base ref, a PR, or an explicit
file list). Use the scope given instead of re-deriving it, and return the synthesized findings to
the caller so it can gate on them — a blocker means the caller stops.

**Must run on the main thread.** Thermos works by spawning two independent subagents; a subagent
cannot spawn subagents, so invoking this skill from inside one collapses both passes into a single
reviewer. A skill that is already running in a subagent should inline the two review rubrics itself
rather than calling thermos.

## Workflow

1. Determine the review scope from the caller's scope if one was given, otherwise from the user request, PR, current branch, or relevant changed files.
2. Gather the diff and any file/context excerpts needed for reviewers to evaluate the change without guessing.
3. Launch both subagents in the same message with `run_in_background: true`:
   - `subagent_type: "thermo-nuclear-review-subagent"` for bugs, breakages, security, devex regressions, feature-flag leaks, and other branch-audit risks.
   - `subagent_type: "thermo-nuclear-code-quality-review-subagent"` for maintainability, structure, file-size growth, spaghetti, abstractions, and codebase-health risks.
4. Pass each subagent the same scoped diff/file context and ask it to return prioritized findings with file references and evidence.
5. After both finish, synthesize the results with findings first, deduplicated across reviewers. Weight overlapping findings more heavily, resolve disagreements with your own judgment, and keep summaries brief.

If individual background summaries are already visible to the user, do not restate them wholesale. Surface the unified verdict, the highest-signal findings, and any remaining uncertainty.

## Output

End with a verdict line the caller can gate on: `BLOCKER`, `FINDINGS`, or `CLEAN`. Follow it with
the deduplicated findings, each as `severity — file:line — what's wrong — fix`.
