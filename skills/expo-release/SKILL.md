---
name: expo-release
description: Cut an Expo / React Native release end to end, writing the CHANGELOG and store copy so no editor ever opens.
disable-model-invocation: true
---

# Expo release

Drives `scripts/expo-release.sh` (repo root of this skills checkout) through a full release:
version bump, CHANGELOG, store notes, EAS build, PR, squash-merge, tag, GitHub release.

The script curates copy by opening `$EDITOR` three times and re-opens the Play notes until they
are under 500 characters. You have no terminal, so you write that copy **before** the run and
hand it over through `scripts/editor-shim.sh`. Steps 1-3 exist to make step 4 unattended.

Invoking the skill approves the whole pipeline including the squash-merge, the tag and the
GitHub release. Stop for the human only at the step 3 checkpoint.

Read the invocation for a version (`3.0.0`), a platform (`ios` / `android` / `all`), and
`skip review`. Ask only for what is missing and unguessable.

## 1. Establish the contract

From the app dir (`RELEASE_APP_DIR`, else `apps/mobile` if it exists, else the repo root):

- `jq -r .version package.json` — the current version.
- `git tag --list "${RELEASE_TAG_PREFIX:-mobile-v}*" --sort=-v:refname | head -1` — the last tag.
- `jq '.cli.appVersionSource, .build.production.autoIncrement' eas.json`.
- The Expo config: `app.config.*` (dynamic) or `app.json` (static).

Settle the version: the invocation's, else bump from the commit subjects since the last tag
(`!:` or `BREAKING` → major, `feat:` → minor, else patch). Refuse a version whose tag already
exists — that release shipped, so cut a patch instead.

Confirm the preflight the script itself enforces: on the default branch, clean tree, in sync
with origin. If any fails, fix or report it and stop — the script's own prompt defaults to *no*
and would exit anyway.

Done when you can name the version, the tag, the platform, and the commit range.

## 2. Write the copy

Read the commit subjects in range, scoped to the app dir plus `packages/shared`:

```
git log --no-merges --pretty=%s <last-tag>..HEAD -- <app-dir> packages/shared
```

Write two files in a temp dir. They are what ships; the script's own generated drafts are raw
commit subjects and get discarded.

**CHANGELOG section** — Keep a Changelog style, `## [<version>] - <YYYY-MM-DD>`, then
`### Added` / `### Changed` / `### Fixed`. Written for developers. Keep the `(#NN)` PR refs.

**Store copy** — one file used for both stores, so hold it to the stricter Play bar:

- **500 characters or fewer**, measured with `wc -m`. Verify before you run; past the bar the
  script loops on the editor forever.
- Written for a camper reading a store listing. No ticket IDs (`0XC-NNN`), no PR numbers, no
  commit-subject phrasing.
- Lead with the release's one headline change, then a short bullet list of what else is new.

A long range collapses hard: 61 commits of tickets and a11y fixes becomes a headline plus six
bullets. Group the internal churn into one plain line ("many accessibility improvements") or
drop it. Refactors, CI fixes and test work are invisible to campers — leave them out.

Done when both files exist and `wc -m` on the store copy reads 500 or less.

## 3. Checkpoint with the human

Show the store copy in full, with its character count, and the CHANGELOG section. Say that
approving runs the build, merges to the default branch, and publishes the tag and release.

Unless the invocation said `skip review`, also run the store-review check for each shipping
platform first — `app-store-review-check` for iOS, `google-play-review-check` for Android —
pointed at the repo root, the Expo config, the privacy and permission config, and the store copy
from step 2. Report anything that is not a Pass and stop; the human decides whether to continue.

Done when the human has approved the copy. This is the one blocking step.

## 4. Run it

Always pass `--skip-review`: you did that check in step 3, and the script's own prompt defaults
to *no* and would exit.

```
cd <repo-root>
EDITOR=<skill-dir>/scripts/editor-shim.sh \
EXPO_RELEASE_CHANGELOG=<tmp>/changelog.md \
EXPO_RELEASE_STORE=<tmp>/store.md \
  <skills-checkout>/scripts/expo-release.sh -p <platform> -v <version> --skip-review </dev/null
```

Run it in the background and poll its output file. It waits up to 60 minutes for the merge, so
it will outlive a foreground timeout.

Pass `--no-build` to skip EAS, `--cached` to drop `--clear-cache`, `--no-merge` to stop at the
PR — only when the invocation asks.

Every prompt left in the script defaults to yes on EOF, which `</dev/null` supplies. The one
exception is a failed preflight, which step 1 already cleared.

Done when the script prints `Done: <tag>`.

## 5. Report

Give the human the tag, the PR URL, the expo.dev build URLs, and where the copy goes next: App
Store Connect → What's New, Play Console → release notes, or the fastlane paths the script
names when the app has a `fastlane/` dir.

If the script died mid-run, say exactly where. Before step 6 nothing is committed and cleanup is
deleting the untracked `release-notes/<version>-*.md`; from step 6 on there is a
`release/mobile-<version>` branch and a version bump to unwind.
