---
name: expo-release
description: Cut a release for the Expo / React Native mobile app — pick the platform and version, generate the store "what's new" notes, update CHANGELOG.md, and create the release branch + git tag + GitHub release. Use when the user wants to release, ship, or cut a new mobile / Expo version, bump the app version, prepare release notes, or runs expo-release. Replaces the manual build.sh release flow.
---

# expo-release

Orchestrates a mobile release end-to-end: **platform → version → notes → branch →
commit → EAS build (bumps `app.json`) → commit → auto-merged PR → tag**. The helper
scripts handle the deterministic parts (version discovery, file patching); you curate
the human-readable notes.

This skill runs the whole flow without stopping for approval at the build or merge
steps: it **always triggers** the EAS build **before** the PR — the production build's
`autoIncrement` mutates the native build version (`buildNumber`/`versionCode`) in
`app.json`, which is committed onto the release branch so the PR carries it — then
**auto-merges** the release PR, printing the build link(s).

## Inputs (args, else ask)

- **platform** — `ios` | `android` | `all`. If not given, ask with `AskUserQuestion`.
- **version** — SemVer like `2.1.0`. If not given, recommend one (see step 2) and ask.

## Workflow

Run everything from the **repo root**. Let `SK=~/.claude/skills/expo-release`.

1. **Preflight.** Confirm the working tree is clean and you're on `main` in sync with
   `origin/main` (`git fetch -q origin main` then compare). If on another branch, out
   of sync, or the tree is dirty, **warn and ask before continuing** — don't abort silently.

2. **Resolve version.** Run `node "$SK/scripts/release-info.mjs"` → JSON with `current`,
   `lastTag`, `suggested`, `suggestedBump`, and `commits[]` (subjects since the last tag).
   If the user passed a version, use it. Otherwise ask with `AskUserQuestion`, listing
   `suggested` **first** as "(Recommended)" with the bump reason, plus the other two
   bump levels. If `current`'s tag already exists, see [REFERENCE.md](REFERENCE.md) (amend vs. patch).

3. **Write the notes** from `commits[]`. Three outputs (curate — don't dump raw subjects):
   - **`<appDir>/CHANGELOG.md`** — prepend a `## [<version>] - <today>` section in
     Keep a Changelog style (Added / Changed / Fixed / Moderation & Security), each
     line ending with its `(#NN)` PR number.
   - **`<appDir>/release-notes/<version>.md`** — short, user-facing App Store / Play
     "What's New" copy (plain language, bullets, no PR numbers).
   - **`<appDir>/fastlane/metadata/android/en-US/changelogs/default.txt`** — **only when
     `platform` is `android` or `all`.** The Play "What's new" copy: curate it from the same
     release highlights as the release-notes file, but write it *for Play* — it is **not** a
     literal trim of the App Store notes. Play copy runs to **≤ 500 chars** (its hard
     per-language limit — measure with `wc -m`) and by convention here carries the `(Pro)`
     tags and extra bullets the App Store "What's New" omits, so the two read differently on
     purpose. Overwrite this file each release. Use `default.txt`, **not**
     `<versionCode>.txt`: `eas.json` here is `appVersionSource: "local"` + `autoIncrement`,
     so EAS owns the final `versionCode` at build time and the number isn't known when the
     release is cut; `supply` applies `default.txt` to whatever code is promoted. This is
     the Play analogue of pasting release-notes into App Store Connect — the iOS side has
     no such repo file because `deliver` reads `release-notes/<version>.md` at upload time.
     After the build is submitted (step 6), push it with
     `/usr/bin/ruby /usr/local/bin/fastlane android metadata` (see the fastlane note below).

4. **Bump the version.** `node "$SK/scripts/set-version.mjs" <version>` (patches
   `package.json` + `app.config.ts`).

5. **Branch + commit the bump & notes.** Branch `release/mobile-<version>` and commit the
   version bump (step 4) + notes (step 3). Commit message: summarize the release and end
   with the `Co-Authored-By` trailer (per repo conventions). **Do not push, create the PR,
   or merge yet** — the build in step 6 still has to add its commit to this branch first.

6. **Run the build (always), then commit the build-version bump.** Do **not** just hand
   off — kick off the EAS build for the chosen platform from `<appDir>`:
   `npx eas build --platform <platform> --profile production --clear-cache --non-interactive`.
   Run it in the background so the session isn't blocked, and once EAS has queued the
   build(s), **print the build link(s)** for every platform (the `https://expo.dev/…/builds/…`
   URL EAS prints per platform; for `all` that's one per platform). If EAS can't run
   non-interactively (missing credentials), report the failure and the command to finish it.

   Because `eas.json` is `appVersionSource: "local"` + `production.autoIncrement`, EAS
   **rewrites `app.json` on disk** early in the build — bumping `ios.buildNumber` and/or
   `android.versionCode` (the native build version, distinct from the SemVer `version`
   from step 4). This increment lands before the cloud build finishes, so **don't wait
   for the build to complete**: watch the working tree (`git status --porcelain app.json`)
   until `app.json` shows the change, then **commit it onto the same release branch** with
   a message like `build: increment native build version for <version>` + the
   `Co-Authored-By` trailer. If nothing changes `app.json` (e.g. EAS didn't run, or the
   platform's field was untouched), skip this commit and say so — don't fabricate a bump.

7. **Push, PR, auto-merge.** Now that the branch carries both the version/notes commit and
   the build-version commit, push and `gh pr create` (base `main`). PR body: summarize the
   release and end with the Claude Code footer (per repo conventions). Then **auto-merge
   without asking** — `gh pr merge <#> --squash --delete-branch` (add `--auto` if branch
   protection requires checks to pass first; fall back to `--admin` only if the user has
   said they want to bypass). Report the merge; don't pause for approval.

8. **Tag + GitHub release.** Because the PR is **squash-merged**, the branch commit isn't
   on `main` — first `git checkout main && git pull --ff-only origin main` so HEAD is the
   squash-merge commit, then tag `<tagPrefix><version>` (e.g. `mobile-v2.1.0`) on it, push
   the tag, and `gh release create <tag> --title ... --notes-file
   <appDir>/release-notes/<version>.md --target main` (or `--notes` from the CHANGELOG
   section). See [REFERENCE.md](REFERENCE.md) if `gh pr merge --auto` hasn't landed yet
   (wait for the merge before tagging).

## Notes

- Defaults target this monorepo: `appDir = apps/mobile`, tag prefix `mobile-v`. Override
  with `RELEASE_APP_DIR` / `RELEASE_TAG_PREFIX` env vars for another app.
- `eas.json` here uses `appVersionSource: "local"` + `production.autoIncrement`, so EAS
  bumps the native build version (`ios.buildNumber` / `android.versionCode`) **in
  `app.json` on disk** at build time — that's the change step 6 commits. The SemVer
  `version` is still owned by the repo (the step-4 bump); only the build number is EAS's.
- Re-running for an **already-shipped** version is unsafe — steer to a patch instead.
  See [REFERENCE.md](REFERENCE.md).
- **Play store listing** (Android) is pushed by fastlane `supply`, not EAS. EAS submit
  uploads the AAB to the `internal` track; the "What's new" text from `default.txt` lands
  once you run `fastlane android metadata` **after** the build is submitted (the version
  code must be in the track first). On this machine `bundle exec` is broken — invoke via
  system Ruby: `/usr/bin/ruby /usr/local/bin/fastlane android metadata`. Store images go
  through `fastlane android upload`. The iOS listing text uploads via `deliver` separately;
  neither store pulls `release-notes/<version>.md` automatically.
