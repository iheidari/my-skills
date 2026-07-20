#!/usr/bin/env bash
# Copy user-level skills (~/.claude/skills) into a project's .claude/skills.
#
# Usage:
#   sync-skills.sh check [target]
#   sync-skills.sh apply [target] [--on-existing=skip|overwrite]
#
# New skills are always copied. --on-existing governs only skills that already
# exist in the project: skip (keep the project copy) or overwrite (replace it).
# Source dir override: USER_SKILLS_DIR=/path sync-skills.sh ...
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODE="${1:-check}"
if [[ "$MODE" != "check" && "$MODE" != "apply" ]]; then
  echo "error: first argument must be 'check' or 'apply' (got '$MODE')" >&2
  exit 2
fi
shift || true

ON_EXISTING="skip"
TARGET=""
for arg in "$@"; do
  case "$arg" in
    # --on-conflict is accepted as a deprecated alias for --on-existing.
    --on-existing=*|--on-conflict=*) ON_EXISTING="${arg#*=}" ;;
    -*) echo "error: unknown flag '$arg'" >&2; exit 2 ;;
    *)  TARGET="$arg" ;;
  esac
done
if [[ "$ON_EXISTING" != "skip" && "$ON_EXISTING" != "overwrite" ]]; then
  echo "error: --on-existing must be 'skip' or 'overwrite' (got '$ON_EXISTING')" >&2
  exit 2
fi

SRC="${USER_SKILLS_DIR:-$HOME/.claude/skills}"
TARGET="${TARGET:-$PWD/.claude/skills}"
SELF="copy-user-skills"

if [[ ! -d "$SRC" ]]; then
  echo "error: no user skills directory at $SRC" >&2
  exit 1
fi

# Collect source skills: immediate subdirs that contain a SKILL.md, excluding self.
skills=()
for dir in "$SRC"/*/; do
  [[ -d "$dir" ]] || continue
  name="$(basename "$dir")"
  [[ "$name" == "$SELF" ]] && continue
  [[ -f "$dir/SKILL.md" ]] || continue
  skills+=("$name")
done

if [[ ${#skills[@]} -eq 0 ]]; then
  echo "No skills found in $SRC"
  exit 0
fi

echo "Source: $SRC"
echo "Target: $TARGET"
echo

new=()
existing=()
for name in "${skills[@]}"; do
  if [[ -e "$TARGET/$name" ]]; then
    existing+=("$name")
  else
    new+=("$name")
  fi
done

for name in "${new[@]}";      do echo "  NEW       $name"; done
for name in "${existing[@]}"; do echo "  EXISTING  $name (already in project)"; done
echo
echo "Summary: ${#new[@]} new, ${#existing[@]} already in project, ${#skills[@]} total."

if [[ "$MODE" == "check" ]]; then
  if [[ ${#existing[@]} -gt 0 ]]; then
    echo
    echo "New skills are always copied. For the ${#existing[@]} already in the project, choose:"
    echo "  apply --on-existing=skip       keep the project copies (default)"
    echo "  apply --on-existing=overwrite  replace them with your user-level copies"
  fi
  exit 0
fi

# apply
mkdir -p "$TARGET"
copied=0; skipped=0; overwrote=0

copy_one() {
  local name="$1"
  rm -rf "${TARGET:?}/$name"
  # -L dereferences: user skills are often symlinks into ~/.agents/skills, and a
  # copied symlink resolves to a path that does not exist in the target repo.
  cp -RL "$SRC/$name" "$TARGET/$name"
  find "$TARGET/$name" \( -name '__pycache__' -o -name '*.pyc' -o -name '.DS_Store' \) \
    -exec rm -rf {} + 2>/dev/null || true
}

for name in "${new[@]}"; do
  copy_one "$name"; copied=$((copied + 1)); echo "  copied     $name (new)"
done
for name in "${existing[@]}"; do
  if [[ "$ON_EXISTING" == "overwrite" ]]; then
    copy_one "$name"; overwrote=$((overwrote + 1)); echo "  overwrote  $name (existing)"
  else
    skipped=$((skipped + 1)); echo "  skipped    $name (existing, project copy kept)"
  fi
done

echo
echo "Done: $copied new copied; of ${#existing[@]} already in the project," \
     "$overwrote overwritten and $skipped skipped (per --on-existing=$ON_EXISTING)."
echo "Note: overwriting a skill whose contents already match produces no git change."

# Pre-approve the Linear MCP in the project settings so Claude cloud/web code
# doesn't prompt for permission on every Linear issue read/update. The settings
# file sits next to the skills dir (both under .claude/).
SETTINGS="$(dirname "$TARGET")/settings.json"
bash "$SCRIPT_DIR/ensure-settings.sh" "$SETTINGS"

echo "Commit $TARGET and $SETTINGS so the cloud environment can use them."
