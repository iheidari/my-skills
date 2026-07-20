#!/usr/bin/env bash
# Ensure the project's .claude/settings.json pre-approves the Linear MCP so
# Claude cloud/web code doesn't prompt for permission every time it reads or
# updates Linear issues.
#
# Usage:
#   ensure-settings.sh [settings.json path]
#
# Merges (does not clobber): adds "mcp__Linear" and "mcp__claude_ai_Linear" to
# permissions.allow, creating the file and keys as needed, and leaving any
# existing settings intact. Safe to run repeatedly — it's a no-op once the
# permissions are present.
set -euo pipefail

PERMS="mcp__Linear
mcp__claude_ai_Linear"
SETTINGS="${1:-$PWD/.claude/settings.json}"

command -v node >/dev/null 2>&1 || {
  echo "error: node not found — needed to merge $SETTINGS" >&2; exit 1; }

mkdir -p "$(dirname "$SETTINGS")"

SETTINGS_PATH="$SETTINGS" PERMS="$PERMS" node <<'NODE'
const fs = require('fs');
const file = process.env.SETTINGS_PATH;
const perms = process.env.PERMS.split('\n').filter(Boolean);

let data = {};
if (fs.existsSync(file)) {
  const raw = fs.readFileSync(file, 'utf8').trim();
  if (raw) {
    try {
      data = JSON.parse(raw);
    } catch (e) {
      console.error(`error: ${file} is not valid JSON — leaving it untouched (${e.message})`);
      process.exit(1);
    }
  }
}
if (typeof data !== 'object' || data === null || Array.isArray(data)) {
  console.error(`error: ${file} does not contain a JSON object — leaving it untouched`);
  process.exit(1);
}

data.permissions = (typeof data.permissions === 'object' && data.permissions !== null && !Array.isArray(data.permissions))
  ? data.permissions
  : {};
const allow = Array.isArray(data.permissions.allow) ? data.permissions.allow : [];

const missing = perms.filter((p) => !allow.includes(p));
const present = perms.filter((p) => allow.includes(p));

for (const p of present) {
  console.log(`settings: '${p}' already allowed in ${file}`);
}
if (missing.length === 0) process.exit(0);

allow.push(...missing);
data.permissions.allow = allow;
fs.writeFileSync(file, JSON.stringify(data, null, 2) + '\n');
for (const p of missing) {
  console.log(`settings: added '${p}' to permissions.allow in ${file}`);
}
NODE
