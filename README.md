# my-skills

**The single source of truth for my Claude Code and Codex skills and global
instructions.** Both agents use symlinks into this repo, so edits are live
everywhere immediately.

```
~/.claude/skills     ->  ~/Projects/my-skills/skills
~/.agents/skills     ->  ~/Projects/my-skills/skills
~/.claude/CLAUDE.md  ->  ~/Projects/my-skills/GLOBAL-AGENTS.md
~/.codex/AGENTS.md   ->  ~/Projects/my-skills/GLOBAL-AGENTS.md
```

## Structure

The repo keeps the shared files in agent-neutral root locations:

```
GLOBAL-AGENTS.md          # shared global instructions
skills/
  <skill-name>/
    SKILL.md              # required — frontmatter + instructions
    scripts/              # optional bundled resources
    references/
```

`GLOBAL-AGENTS.md` deliberately does not use the reserved root name
`AGENTS.md`, preventing Codex from loading the same instructions once globally
and again as repository guidance while working in this repo.

## Adding or editing a skill

Edit files in `skills/` directly, then commit. There is no sync step —
the symlinks mean `~/.claude/skills` and `~/.agents/skills` already point at
these files.

`copy-user-skills` still has a role, but a different one: it copies these skills
*into another project's* `.claude/skills` so they work in Claude cloud/web code,
which can't see local user skills.

## Restoring

The pre-symlink directories are preserved as:

```
~/.claude/skills.bak-2026-07-20
~/.agents/skills.bak-2026-07-20
~/.codex/AGENTS.md.pre-shared-20260910
```

Delete them once you're satisfied the symlink setup is behaving. Not carried
over from those backups, deliberately:

- `Archive/` + `Archive.zip` — stale duplicates of skills already here.
- `my-skill/` — an empty directory, never a real skill.
