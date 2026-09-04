#!/usr/bin/env bash
# expo-release — cut a release for an Expo / React Native app.
#
#   detect contract → preflight → store-review reminder → version → notes →
#   bump → branch + commit → EAS build → push + PR + squash-merge → tag + GitHub release
#
# Usage:
#   expo-release.sh [-p ios|android|all] [-v X.Y.Z] [options]
#
# Options:
#   -p, --platform     ios | android | all           (asked if omitted)
#   -v, --version      SemVer to release              (suggested if omitted)
#       --skip-review  don't pause for the store-review pre-flight
#       --no-build     skip the EAS build
#       --no-merge     push + open PR but don't merge / tag
#       --cached       drop --clear-cache from the EAS build
#   -n, --dry-run      print what would happen; no writes, no git, no EAS
#   -h, --help
#
# Env:
#   RELEASE_APP_DIR      app folder (default: apps/mobile if it exists, else .)
#   RELEASE_TAG_PREFIX   tag prefix (default: mobile-v)
#   RELEASE_EAS_PROFILE  EAS build profile (default: production)
#   EDITOR               used to curate CHANGELOG + store notes
#
# Requires: git, gh, jq, node/npx (for eas), perl.

set -euo pipefail

# ---------- args ----------
PLATFORM="" VERSION="" SKIP_REVIEW=0 NO_BUILD=0 NO_MERGE=0 CLEAR_CACHE=1 DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    -p|--platform) PLATFORM="$2"; shift 2 ;;
    -v|--version)  VERSION="$2"; shift 2 ;;
    --skip-review) SKIP_REVIEW=1; shift ;;
    --no-build)    NO_BUILD=1; shift ;;
    --no-merge)    NO_MERGE=1; shift ;;
    --cached)      CLEAR_CACHE=0; shift ;;
    -n|--dry-run)  DRY=1; shift ;;
    -h|--help)     sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

# ---------- helpers ----------
c_bold=$'\e[1m' c_dim=$'\e[2m' c_red=$'\e[31m' c_yel=$'\e[33m' c_grn=$'\e[32m' c_off=$'\e[0m'
step() { printf '\n%s== %s ==%s\n' "$c_bold" "$*" "$c_off"; }
info() { printf '%s\n' "$*"; }
warn() { printf '%s%s%s\n' "$c_yel" "$*" "$c_off" >&2; }
die()  { printf '%s%s%s\n' "$c_red" "$*" "$c_off" >&2; exit 1; }
run()  { if [ "$DRY" = 1 ]; then printf '%s$ %s%s\n' "$c_dim" "$*" "$c_off"; else "$@"; fi; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing required tool: $1"; }

ask_yn() { # ask_yn "question" [default y|n]
  local q="$1" def="${2:-n}" ans
  [ "$def" = y ] && q="$q [Y/n] " || q="$q [y/N] "
  read -r -p "$q" ans
  ans="${ans:-$def}"
  [[ "$ans" =~ ^[Yy] ]]
}

edit_file() { # open in $EDITOR unless dry-run
  [ "$DRY" = 1 ] && { info "${c_dim}(dry-run) would edit $1${c_off}"; return; }
  "${EDITOR:-vi}" "$1"
}

for t in git gh jq perl npx; do need "$t"; done

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

# ---------- 0. detect release contract ----------
step "0. Detect release contract"

APP="${RELEASE_APP_DIR:-}"
if [ -z "$APP" ]; then [ -d apps/mobile ] && APP=apps/mobile || APP=.; fi
[ -f "$APP/package.json" ] || die "no package.json in $APP (set RELEASE_APP_DIR)"
TAG_PREFIX="${RELEASE_TAG_PREFIX:-mobile-v}"
EAS_PROFILE="${RELEASE_EAS_PROFILE:-production}"

# A. version source + auto-increment
if [ -f "$APP/eas.json" ]; then
  VERSION_SOURCE="$(jq -r '.cli.appVersionSource // "remote"' "$APP/eas.json")"
  AUTO_INC="$(jq -r --arg p "$EAS_PROFILE" '.build[$p].autoIncrement // false' "$APP/eas.json")"
else
  warn "no $APP/eas.json — assuming appVersionSource=remote"
  VERSION_SOURCE=remote AUTO_INC=false
fi

# B. Expo config: static app.json vs dynamic app.config.*
DYN_CONFIG="$(ls "$APP"/app.config.ts "$APP"/app.config.js "$APP"/app.config.mjs 2>/dev/null | head -1 || true)"
if [ -n "$DYN_CONFIG" ]; then CONFIG_KIND=dynamic; CONFIG_FILE="$DYN_CONFIG"
elif [ -f "$APP/app.json" ]; then CONFIG_KIND=static; CONFIG_FILE="$APP/app.json"
else die "no Expo config (app.json / app.config.*) in $APP"; fi

# C. fastlane
[ -d "$APP/fastlane" ] && FASTLANE=yes || FASTLANE=no

# D. release-notes naming convention
NOTES_DIR="$APP/release-notes"
# shellcheck disable=SC2010
n_suffixed=$(ls "$NOTES_DIR" 2>/dev/null | grep -Ec -- '-(ios|android)\.md$' || true)
# shellcheck disable=SC2010
n_bare=$(ls "$NOTES_DIR" 2>/dev/null | grep -Ec '^[0-9]+\.[0-9]+\.[0-9]+\.md$' || true)
if   [ "$n_suffixed" -gt "$n_bare" ]; then NOTES_CONV=suffixed
elif [ "$n_bare" -gt "$n_suffixed" ]; then NOTES_CONV=bare
else
  warn "release-notes/ has no clear precedent (suffixed=$n_suffixed bare=$n_bare)"
  if ask_yn "Use suffixed <v>-ios.md / <v>-android.md? (n = bare <v>.md)" y; then NOTES_CONV=suffixed; else NOTES_CONV=bare; fi
fi

printf '%-18s %s\n' "appDir:" "$APP" \
  "appVersionSource:" "$VERSION_SOURCE" \
  "autoIncrement:" "$AUTO_INC ($EAS_PROFILE)" \
  "expo config:" "$CONFIG_KIND ($CONFIG_FILE)" \
  "fastlane:" "$FASTLANE" \
  "notes naming:" "$NOTES_CONV" \
  "tag prefix:" "$TAG_PREFIX"

if [ "$VERSION_SOURCE" = local ] && [ "$CONFIG_KIND" = dynamic ]; then
  die "misconfigured: appVersionSource=local needs a static app.json (EAS can't write a dynamic $CONFIG_FILE). Fix eas.json or the config first."
fi
ask_yn "Contract look right?" y || exit 1

# ---------- 1. preflight ----------
step "1. Preflight"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
git fetch -q origin main
DIRTY="$(git status --porcelain)"
BEHIND="$(git rev-list --count HEAD..origin/main)"
AHEAD="$(git rev-list --count origin/main..HEAD)"
ok=1
[ "$BRANCH" = main ] || { warn "on branch '$BRANCH', not main"; ok=0; }
[ -z "$DIRTY" ] || { warn "working tree is dirty:"; printf '%s\n' "$DIRTY" >&2; ok=0; }
[ "$BEHIND" = 0 ] && [ "$AHEAD" = 0 ] || { warn "main is $AHEAD ahead / $BEHIND behind origin/main"; ok=0; }
if [ "$ok" = 1 ]; then info "${c_grn}clean, on main, in sync with origin/main${c_off}"
else ask_yn "Continue anyway?" n || exit 1; fi

# ---------- platform ----------
if [ -z "$PLATFORM" ]; then
  read -r -p "Platform [ios/android/all]: " PLATFORM
fi
case "$PLATFORM" in ios|android|all) ;; *) die "platform must be ios | android | all" ;; esac
WANT_IOS=0 WANT_ANDROID=0
[ "$PLATFORM" != android ] && WANT_IOS=1
[ "$PLATFORM" != ios ] && WANT_ANDROID=1

# ---------- 2. store-review gate ----------
step "2. Store-review pre-flight"
if [ "$SKIP_REVIEW" = 1 ]; then
  info "skipped (--skip-review)"
else
  cat <<MSG
Before any file is touched, audit HEAD against the store rules for the platform(s) shipping:
  ios     → app-store-review-check
  android → google-play-review-check
Point the check at: repo root, $CONFIG_FILE, privacy/permission config, this version's release-notes/,
$( [ "$FASTLANE" = yes ] && echo "and the listing copy under $APP/fastlane/metadata/." \
  || echo "and note the store LISTING (descriptions, screenshots, categories) is NOT in this repo — report those guidelines as 'not assessed', not Pass." )
Continue only if every finding is Pass. Anything else → stop and fix (or re-run with an explicit override).
MSG
  ask_yn "Review done and clean for $PLATFORM?" n || exit 1
fi

# ---------- 3. resolve version ----------
step "3. Version"
CURRENT="$(jq -r .version "$APP/package.json")"
LAST_TAG="$(git tag --list "${TAG_PREFIX}*" --sort=-v:refname | head -1 || true)"
RANGE=""; [ -n "$LAST_TAG" ] && RANGE="$LAST_TAG..HEAD"
LOG_PATHS=("$APP"); [ -d packages/shared ] && LOG_PATHS+=(packages/shared)
mapfile -t COMMITS < <(git log --no-merges --pretty=%s $RANGE -- "${LOG_PATHS[@]}")

re_break='^[a-z]+(\([^)]*\))?!:'
re_feat='^feat(\([^)]*\))?:'
re_fix='^fix(\([^)]*\))?!?:'
BUMP='patch'
for s in "${COMMITS[@]}"; do
  if [[ "$s" =~ $re_break ]] || [[ "$s" == *BREAKING* ]]; then BUMP=major; break; fi
  [[ "$s" =~ $re_feat ]] && BUMP=minor
done
IFS=. read -r MAJ MIN PAT <<<"$CURRENT"
V_MAJOR="$((MAJ+1)).0.0" V_MINOR="$MAJ.$((MIN+1)).0" V_PATCH="$MAJ.$MIN.$((PAT+1))"
case "$BUMP" in major) SUGGESTED=$V_MAJOR ;; minor) SUGGESTED=$V_MINOR ;; *) SUGGESTED=$V_PATCH ;; esac

info "current:  $CURRENT"
info "last tag: ${LAST_TAG:-(none — first release)}"
info "commits since: ${#COMMITS[@]}"
printf '  %s\n' "${COMMITS[@]}"
if [ -z "$VERSION" ]; then
  info ""
  info "  1) $SUGGESTED  ($BUMP, recommended)"
  info "  2) $V_MAJOR  (major)"
  info "  3) $V_MINOR  (minor)"
  info "  4) $V_PATCH  (patch)"
  read -r -p "Version [1-4 or X.Y.Z] (1): " pick
  case "${pick:-1}" in 1) VERSION=$SUGGESTED ;; 2) VERSION=$V_MAJOR ;; 3) VERSION=$V_MINOR ;; 4) VERSION=$V_PATCH ;; *) VERSION=$pick ;; esac
fi
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "bad version: $VERSION"
TAG="${TAG_PREFIX}${VERSION}"
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  die "tag $TAG already exists. If it never shipped: git tag -f + gh release edit. If it shipped: cut a patch instead."
fi
TODAY="$(date +%F)"
info "→ releasing ${c_bold}$VERSION${c_off} ($TAG) for $PLATFORM"

# ---------- 4. notes ----------
step "4. Notes"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# strip "type(scope): " prefix; keep "(#NN)"
clean_subject() { perl -pe 's/^[a-z]+(\([^)]*\))?!?:\s*//; s/^(.)/\u$1/'; }

added=() fixed=() changed=()
for s in "${COMMITS[@]}"; do
  line="- $(printf '%s' "$s" | clean_subject)"
  if   [[ "$s" =~ $re_feat ]];           then added+=("$line")
  elif [[ "$s" =~ $re_fix ]]; then fixed+=("$line")
  else changed+=("$line"); fi
done

CL_SECTION="$TMP/changelog.md"
{
  echo "## [$VERSION] - $TODAY"; echo
  [ ${#added[@]}   -gt 0 ] && { echo "### Added";   printf '%s\n' "${added[@]}";   echo; }
  [ ${#changed[@]} -gt 0 ] && { echo "### Changed"; printf '%s\n' "${changed[@]}"; echo; }
  [ ${#fixed[@]}   -gt 0 ] && { echo "### Fixed";   printf '%s\n' "${fixed[@]}";   echo; }
} > "$CL_SECTION"
info "Edit the CHANGELOG section (Keep a Changelog style, keep (#NN) refs)"
edit_file "$CL_SECTION"

# store copy draft: same bullets, no PR numbers, no headings
STORE_DRAFT="$TMP/store.md"
grep '^- ' "$CL_SECTION" | perl -pe 's/\s*\(#\d+\)//g' > "$STORE_DRAFT" || true

IOS_NOTES="" ANDROID_NOTES="" RELEASE_NOTES_FILE=""
if [ "$NOTES_CONV" = suffixed ]; then
  [ "$WANT_IOS" = 1 ]     && IOS_NOTES="$NOTES_DIR/$VERSION-ios.md"
  [ "$WANT_ANDROID" = 1 ] && ANDROID_NOTES="$NOTES_DIR/$VERSION-android.md"
  RELEASE_NOTES_FILE="${IOS_NOTES:-$ANDROID_NOTES}"
else
  IOS_NOTES="$NOTES_DIR/$VERSION.md"; RELEASE_NOTES_FILE="$IOS_NOTES"
  [ "$WANT_ANDROID" = 1 ] && [ "$WANT_IOS" = 0 ] && { ANDROID_NOTES="$IOS_NOTES"; IOS_NOTES=""; }
fi

write_draft() { # write_draft <dest> <src>
  if [ "$DRY" = 1 ]; then info "${c_dim}(dry-run) would write $1${c_off}"; return; fi
  mkdir -p "$(dirname "$1")"; cp "$2" "$1"
}

if [ -n "$IOS_NOTES" ]; then
  info "Edit iOS / App Store 'What's New' → $IOS_NOTES (plain language, no PR numbers)"
  write_draft "$IOS_NOTES" "$STORE_DRAFT"; edit_file "$IOS_NOTES"
fi
if [ -n "$ANDROID_NOTES" ]; then
  info "Edit Android / Play 'What's new' → $ANDROID_NOTES (≤ 500 chars, written for Play)"
  write_draft "$ANDROID_NOTES" "$STORE_DRAFT"
  while :; do
    edit_file "$ANDROID_NOTES"
    [ "$DRY" = 1 ] && break
    chars=$(wc -m < "$ANDROID_NOTES" | tr -d ' ')
    [ "$chars" -le 500 ] && { info "Play notes: $chars chars"; break; }
    warn "Play notes are $chars chars (limit 500) — cut and save again"
  done
  if [ "$FASTLANE" = yes ]; then
    FL_CHANGELOG="$APP/fastlane/metadata/android/en-US/changelogs/default.txt"
    info "fastlane: writing Play copy to $FL_CHANGELOG"
    write_draft "$FL_CHANGELOG" "$ANDROID_NOTES"
  fi
fi

# prepend CHANGELOG section (after a leading "# " header if present)
CHANGELOG="$APP/CHANGELOG.md"
if [ "$DRY" = 1 ]; then info "${c_dim}(dry-run) would prepend section to $CHANGELOG${c_off}"
else
  if [ -f "$CHANGELOG" ] && head -1 "$CHANGELOG" | grep -q '^# '; then
    { head -1 "$CHANGELOG"; echo; cat "$CL_SECTION"; tail -n +2 "$CHANGELOG" | sed '1{/^$/d;}'; } > "$TMP/cl.new"
  else
    { cat "$CL_SECTION"; [ -f "$CHANGELOG" ] && cat "$CHANGELOG"; } > "$TMP/cl.new"
  fi
  mv "$TMP/cl.new" "$CHANGELOG"
fi

# ---------- 5. bump version ----------
step "5. Bump version $CURRENT → $VERSION"
touched=()
if [ "$DRY" = 0 ]; then
  jq --indent 2 --arg v "$VERSION" '.version = $v' "$APP/package.json" > "$TMP/pkg" && mv "$TMP/pkg" "$APP/package.json"
  touched+=("$APP/package.json")
  if [ "$CONFIG_KIND" = dynamic ]; then
    if grep -Eq "^\s*version:\s*[\"']\d*[0-9]+\.[0-9]+\.[0-9]+[\"']" "$CONFIG_FILE"; then
      perl -pi -e "s/^(\s*version:\s*)([\"'])\d+\.\d+\.\d+\2/\${1}\"$VERSION\"/" "$CONFIG_FILE"
      touched+=("$CONFIG_FILE")
    else
      warn "no 'version: \"x.y.z\"' line in $CONFIG_FILE — check it reads version from package.json"
    fi
  else
    if jq -e '.expo' "$CONFIG_FILE" >/dev/null; then q='.expo.version = $v'; else q='.version = $v'; fi
    jq --indent 2 --arg v "$VERSION" "$q" "$CONFIG_FILE" > "$TMP/app" && mv "$TMP/app" "$CONFIG_FILE"
    touched+=("$CONFIG_FILE")
  fi
  info "touched: ${touched[*]}"
else
  info "${c_dim}(dry-run) would patch $APP/package.json + $CONFIG_FILE${c_off}"
fi

# ---------- 6. branch + commit ----------
step "6. Branch + commit"
REL_BRANCH="release/mobile-$VERSION"
run git checkout -q -b "$REL_BRANCH"
run git add -A -- "$APP"
run git commit -q -m "release: mobile $VERSION ($PLATFORM)

- bump version $CURRENT → $VERSION
- CHANGELOG + store notes"
info "committed on $REL_BRANCH"

# ---------- 7. EAS build ----------
step "7. EAS build"
BUILD_URLS=()
if [ "$NO_BUILD" = 1 ]; then
  info "skipped (--no-build)"
else
  BUILD_LOG="$TMP/eas.log"
  cmd=(npx eas build --platform "$PLATFORM" --profile "$EAS_PROFILE" --non-interactive)
  [ "$CLEAR_CACHE" = 1 ] && cmd+=(--clear-cache)
  info "$ (cd $APP && ${cmd[*]}) &"
  if [ "$DRY" = 0 ]; then
    (cd "$APP" && "${cmd[@]}" 2>&1 | tee "$BUILD_LOG") &
    EAS_PID=$!
    expected=1; [ "$PLATFORM" = all ] && expected=2

    if [ "$VERSION_SOURCE" = local ]; then
      # EAS rewrites app.json (buildNumber / versionCode) early in the build → commit it
      info "appVersionSource=local: waiting for EAS to bump $CONFIG_FILE ..."
      for _ in $(seq 1 120); do
        [ -n "$(git status --porcelain -- "$CONFIG_FILE")" ] && break
        kill -0 "$EAS_PID" 2>/dev/null || break
        sleep 5
      done
      if [ -n "$(git status --porcelain -- "$CONFIG_FILE")" ]; then
        git add -- "$CONFIG_FILE"
        git commit -q -m "build: increment native build version for $VERSION"
        info "committed native build-number bump"
      else
        warn "$CONFIG_FILE unchanged — no build-number commit made"
      fi
    fi

    # wait for the build URLs (don't wait for the build itself)
    for _ in $(seq 1 120); do
      mapfile -t BUILD_URLS < <(grep -Eo 'https://expo\.dev/[^ ]*/builds/[0-9a-f-]+' "$BUILD_LOG" 2>/dev/null | sort -u)
      [ "${#BUILD_URLS[@]}" -ge "$expected" ] && break
      kill -0 "$EAS_PID" 2>/dev/null || break
      sleep 5
    done
    if [ "${#BUILD_URLS[@]}" -gt 0 ]; then
      info "${c_grn}build(s) queued:${c_off}"; printf '  %s\n' "${BUILD_URLS[@]}"
    else
      warn "no build URL seen yet — check: $BUILD_LOG"
      if ! kill -0 "$EAS_PID" 2>/dev/null; then
        warn "eas exited early; tail of log:"; tail -20 "$BUILD_LOG" >&2
        ask_yn "Continue to PR anyway?" n || exit 1
      fi
    fi
    disown "$EAS_PID" 2>/dev/null || true
  else
    [ "$VERSION_SOURCE" = local ] && info "${c_dim}(dry-run) would wait for + commit $CONFIG_FILE build-number bump${c_off}"
  fi
fi

# ---------- 8. push, PR, merge ----------
step "8. Push + PR"
run git push -q -u origin "$REL_BRANCH"
PR_BODY="$TMP/pr.md"
{
  echo "## Release mobile $VERSION ($PLATFORM)"; echo
  cat "$CL_SECTION"
  [ ${#BUILD_URLS[@]} -gt 0 ] && { echo "### Builds"; printf -- '- %s\n' "${BUILD_URLS[@]}"; echo; }
  [ "$SKIP_REVIEW" = 1 ] && echo "> Store-review pre-flight skipped (--skip-review)."
} > "$PR_BODY"
if [ "$DRY" = 1 ]; then
  info "${c_dim}(dry-run) gh pr create --base main --head $REL_BRANCH${c_off}"; PR_URL=""
else
  PR_URL="$(gh pr create --base main --head "$REL_BRANCH" --title "release: mobile $VERSION" --body-file "$PR_BODY")"
  info "PR: $PR_URL"
fi

if [ "$NO_MERGE" = 1 ]; then
  info "stopping before merge (--no-merge). Tag after merging:"
  info "  git checkout main && git pull --ff-only && git tag $TAG && git push origin $TAG"
  info "  gh release create $TAG --title 'mobile $VERSION' --notes-file $RELEASE_NOTES_FILE --target main"
  exit 0
fi

step "8b. Merge"
if [ "$DRY" = 1 ]; then info "${c_dim}(dry-run) gh pr merge --squash --delete-branch${c_off}"
else
  if ! gh pr merge "$PR_URL" --squash --delete-branch 2>/dev/null; then
    warn "direct merge refused (checks / protection) — enabling auto-merge"
    gh pr merge "$PR_URL" --squash --delete-branch --auto
  fi
  info "waiting for merge ..."
  for _ in $(seq 1 360); do
    state="$(gh pr view "$PR_URL" --json state -q .state 2>/dev/null || echo "")"
    [ "$state" = MERGED ] && break
    [ "$state" = CLOSED ] && die "PR was closed without merging"
    sleep 10
  done
  [ "$state" = MERGED ] || die "PR not merged after 60 min — merge it, then tag by hand (see --no-merge output)"
  info "${c_grn}merged${c_off}"
fi

# ---------- 9. tag + GitHub release ----------
step "9. Tag + GitHub release"
run git checkout -q main
run git pull -q --ff-only origin main
run git tag "$TAG"
run git push -q origin "$TAG"
run gh release create "$TAG" --title "mobile $VERSION" --notes-file "$RELEASE_NOTES_FILE" --target main
run git branch -D "$REL_BRANCH"

# ---------- done ----------
step "Done: $TAG"
[ ${#BUILD_URLS[@]} -gt 0 ] && { info "builds:"; printf '  %s\n' "${BUILD_URLS[@]}"; }
if [ "$FASTLANE" = yes ]; then
  [ "$WANT_ANDROID" = 1 ] && info "after the AAB is submitted, push Play notes: (cd $APP && /usr/bin/ruby /usr/local/bin/fastlane android metadata)"
  [ "$WANT_IOS" = 1 ]     && info "iOS listing text uploads via fastlane deliver"
else
  [ -n "$IOS_NOTES" ]     && info "paste $IOS_NOTES into App Store Connect → What's New in This Version"
  [ -n "$ANDROID_NOTES" ] && info "paste $ANDROID_NOTES into Play Console → release notes"
fi
