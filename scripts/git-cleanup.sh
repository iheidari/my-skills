#!/usr/bin/env bash
#
# git-cleanup.sh — delete local branches whose GitHub PR is merged.
#
# Run from anywhere inside a git repository. Lists local branches with a MERGED
# pull request (plus their remote branch if it still exists), asks for
# confirmation, then deletes them. The current and default branches are never
# touched. Exits with an error if not inside a git repository.
#
# Usage: git-cleanup.sh [--dry-run] [--yes]
#   --dry-run   list merged branches and exit; delete nothing
#   --yes, -y   skip the confirmation prompt (for non-interactive use)
#
set -euo pipefail

dry_run=false
assume_yes=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    --yes|-y)  assume_yes=true ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "ERROR: unknown option: $arg" >&2; exit 2 ;;
  esac
done

# --- Preflight ---------------------------------------------------------------
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: not inside a git repository" >&2
  exit 1
fi
if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: GitHub CLI (gh) is not installed — see https://cli.github.com" >&2
  exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh is not authenticated — run: gh auth login" >&2
  exit 1
fi

cd "$(git rev-parse --show-toplevel)"

# --- Refresh remote state ----------------------------------------------------
git fetch --prune --quiet 2>/dev/null || true

# --- Resolve protected branches and default remote ---------------------------
current="$(git rev-parse --abbrev-ref HEAD)"
default="$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null || true)"
[ -z "$default" ] && default="main"

default_remote="origin"
if ! git remote | grep -qx "origin"; then
  default_remote="$(git remote | head -n1 || true)"
fi

# --- Detect merged branches --------------------------------------------------
branches=()   # branch name
prs=()        # PR number
titles=()     # PR title
remotes=()    # remote name if remote branch still exists, else ""

while IFS= read -r branch; do
  [ -z "$branch" ] && continue
  [ "$branch" = "$current" ] && continue
  [ "$branch" = "$default" ] && continue

  info="$(gh pr list --head "$branch" --state merged --limit 1 \
            --json number,title \
            --jq '.[0] | select(.) | "\(.number)\t\(.title)"' 2>/dev/null || true)"
  [ -z "$info" ] && continue

  remote="$(git config "branch.$branch.remote" 2>/dev/null || true)"
  [ -z "$remote" ] && remote="$default_remote"
  remote_col=""
  if [ -n "$remote" ] && git show-ref --verify --quiet "refs/remotes/$remote/$branch"; then
    remote_col="$remote"
  fi

  branches+=("$branch")
  prs+=("${info%%$'\t'*}")
  titles+=("${info#*$'\t'}")
  remotes+=("$remote_col")
done < <(git for-each-ref --format='%(refname:short)' refs/heads/)

if [ "${#branches[@]}" -eq 0 ]; then
  echo "No merged branches to clean up."
  exit 0
fi

# --- Present -----------------------------------------------------------------
echo "Branches with a merged PR (current: $current, default: $default — both protected):"
echo
for i in "${!branches[@]}"; do
  where="local"
  [ -n "${remotes[$i]}" ] && where="local + ${remotes[$i]}"
  printf '  %2d) %s — PR #%s — %s  [%s]\n' "$((i + 1))" "${branches[$i]}" "${prs[$i]}" "${titles[$i]}" "$where"
done
echo

if $dry_run; then
  echo "Dry run — nothing deleted."
  exit 0
fi

# --- Confirm -----------------------------------------------------------------
selected=("${!branches[@]}")
if ! $assume_yes; then
  if [ ! -t 0 ] && [ ! -r /dev/tty ]; then
    echo "ERROR: no terminal for confirmation — re-run with --yes to delete, or --dry-run to list" >&2
    exit 1
  fi
  input=/dev/stdin
  [ -t 0 ] || input=/dev/tty
  printf 'Delete these branches? [y/N, or numbers e.g. "1 3"] ' 
  IFS= read -r answer < "$input" || answer=""
  case "$answer" in
    y|Y|yes|YES) ;;
    *[0-9]*)
      selected=()
      for n in $answer; do
        if ! [[ "$n" =~ ^[0-9]+$ ]] || [ "$n" -lt 1 ] || [ "$n" -gt "${#branches[@]}" ]; then
          echo "ERROR: invalid selection: $n" >&2
          exit 2
        fi
        selected+=("$((n - 1))")
      done
      ;;
    *) echo "Cancelled — nothing deleted."; exit 0 ;;
  esac
fi

# --- Delete ------------------------------------------------------------------
echo
for i in "${selected[@]}"; do
  b="${branches[$i]}"
  # -D is required: squash/rebase merges look unmerged to git; PR merge is verified above.
  if git branch -D "$b" >/dev/null 2>&1; then
    echo "deleted local  $b"
  else
    echo "FAILED local   $b" >&2
    continue
  fi
  if [ -n "${remotes[$i]}" ]; then
    if git push "${remotes[$i]}" --delete "$b" >/dev/null 2>&1; then
      echo "deleted remote ${remotes[$i]}/$b"
    else
      echo "FAILED remote  ${remotes[$i]}/$b" >&2
    fi
  fi
done
echo
echo "Done."
