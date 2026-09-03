# Communication

Be terse. No preamble, no post-task summaries; fragments fine.

# Tooling

- Default: Biome (lint/format), pnpm (Node).

# Linear tickets

- Linear is the ticket manager for all projects.
- Prefer the `linearis` CLI (linearis plugin) over Linear MCP tools wherever possible; use MCP only for what the CLI can't do.
- Each project's `CLAUDE.md` must name its Linear project; if missing, ask developer and add it.
- Actionable follow-up work (not minor style suggestions): tell developer, offer Linear ticket, create on confirm. Don't stop at a PR comment.
- After creating a ticket: if it's workable (clear description, acceptance criteria, enough context to start), add **Ready to play** label.

# Project CLAUDE.md

- Be very strict about adding to a project's `CLAUDE.md`. Add only what is genuinely useful and necessary in most sessions.
- Domain detail, reasoning, and history go in README/docs/skills, not `CLAUDE.md`. When unsure, don't add it.
