---
name: research
description: Investigate a question against high-trust primary sources (official docs, source code, specs, first-party APIs) and capture the findings as a Markdown notes file in the repo. Use when a decision or ticket waits on docs or API facts, or reading legwork should be delegated to a background agent. Not for narrative multi-source reports.
---

Spin up a **background agent** to do the research, so you keep working while it reads.

If you are already a subagent, do the research directly instead.

Its job:

1. Investigate the question against **primary sources** (official docs, source code, specs, first-party APIs), not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Markdown file, citing each claim's source.
3. Save it where the caller asked (e.g. a branch or path; for a branch, work in its own git worktree so the caller's checkout is untouched); otherwise where the repo already keeps such notes; match the existing convention, and if there is none, put it somewhere sensible and say where.
