# Communication

Be terse. No preamble, no summaries of what you just did, fragments fine

# Tooling

- Default to Biome for linting/formatting and pnpm as the Node package manager.
- If an existing repo is clearly set up with different tools (ESLint/Prettier config, npm/yarn lockfile), follow the repo's tooling instead and tell me.

# Ticket management (Linear)

- Use Linear as the ticket manager for all projects.
- Each project's `CLAUDE.md` must state the name of the Linear project it maps to. If it isn't documented there, ask the developer for the Linear project name and add it to that project's `CLAUDE.md`.
- When you have actionable follow-up work (not minor style suggestions), tell the developer and offer to create a Linear ticket; create it once they confirm. Do not stop at merely noting it in a PR comment.
- When you create a follow-up ticket, check whether it has all the requirements needed to be worked on (clear description, acceptance criteria, and enough context to start). If it does, add the **Ready to play** label to the ticket.
