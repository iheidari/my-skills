# expo-release — reference

## Version recommendation

`release-info.mjs` infers the bump from Conventional-Commit subjects since the last
`mobile-v*` tag (or the whole history for the first release):

| Subjects since last tag            | Bump  | Example         |
| ---------------------------------- | ----- | --------------- |
| any `feat!:` / `fix!:` / BREAKING  | major | 1.4.2 → 2.0.0   |
| any `feat:` (no breaking)          | minor | 1.4.2 → 1.5.0   |
| only `fix:` / `chore:` / `docs:` … | patch | 1.4.2 → 1.4.3   |

It's a recommendation — always let the user override. The first release with no prior
tag tends to suggest `patch`; a human usually wants `1.0.0` or a major there.

## Amending vs. patching a release

The right move depends on whether the version is **already in users' hands**.

**Not shipped yet** (tag not cut, or build never released to a store) → amend in place:

```sh
# after committing the extra changes onto the release branch
git tag -f mobile-v<version> && git push -f origin mobile-v<version>
# --notes-file path follows the repo's naming convention (SKILL step 0, fact D):
#   suffixed → apps/mobile/release-notes/<version>-ios.md
#   bare     → apps/mobile/release-notes/<version>.md
gh release edit mobile-v<version> --notes-file <path>
# rebuild — EAS autoIncrement bumps the *build number*, version stays the same
```

Regenerate the CHANGELOG/notes from the new commits before re-tagging.

**Already shipped to users** → do **not** reuse the version. A published tag is
effectively immutable, and the App Store / Play Store reject a version string that's
already live. Cut a **patch** (`<major>.<minor>.<patch+1>`) instead — that's exactly
what patch versions are for. Run the skill again with the patch version.

## Squash-merge re-tag

The main flow auto-merges the PR (squash) and only tags **after** the merge lands on
`main` (SKILL step 9), so this is normally a non-issue. Use this only as a recovery
path — if a tag ever ended up on the branch commit instead of the squash-merge commit,
retarget it after the merge lands:

```sh
git checkout main && git pull
git tag -f mobile-v<version>            # tags current main HEAD
git push -f origin mobile-v<version>
gh release edit mobile-v<version> --target main
```

(Or simply tag + create the release *after* the merge instead of on the branch.)

## EAS / store notes

**None of this is fixed across repos — SKILL step 0 detects it. What follows explains
each mode, not which one you're in.**

### Version source (step 0, facts A + B)

- **`appVersionSource: "local"` + a static `app.json`** — the SemVer `version` comes from
  `app.json` (the `set-version.mjs` bump) and EAS bumps only the native build version
  (`ios.buildNumber` / `android.versionCode`) **in `app.json` on disk** at build time.
  That on-disk change is what SKILL step 7 commits onto the release branch before the PR,
  so the PR carries both the SemVer bump and the build-number bump. Because the source is
  local, there's no `build:version:set` remote push to make.
- **`appVersionSource: "remote"`** — the native build version lives on **EAS's servers**
  and `production.autoIncrement` advances it there. Nothing lands in the working tree, so
  the release branch carries a single commit (bump + notes) and step 7 has no follow-up
  commit to make. Read the build number off the EAS build page if you need it. The SemVer
  `version` is still repo-owned via `set-version.mjs`.
- **`local` + a dynamic `app.config.*` is a misconfiguration**, not a mode. `local` needs
  EAS to write the incremented build number back into the Expo config, and a dynamic
  config can't be auto-written — that's typically *why* it's dynamic (a key like
  `GOOGLE_MAPS_API_KEY` comes from the environment rather than source). Surface it; don't
  release around it. A repo may pin its choice with a test — e.g. milemark's
  `apps/mobile/src/release-config.test.ts` — so flipping it fails CI until this flow is
  updated too.

### Store copy (step 0, facts C + D)

- The iOS notes file — `release-notes/<version>-ios.md` or bare `release-notes/<version>.md`
  depending on the repo's convention — is the copy you paste into **App Store Connect**
  ("What's New in This Version"). EAS submit does not upload it for you in either mode.
- **With fastlane present**, Android release notes are automated: the skill also writes the
  Play copy (≤ 500 chars) to `fastlane/metadata/android/en-US/changelogs/default.txt`, and
  you push it to the **Play Console** after the AAB is submitted with
  `/usr/bin/ruby /usr/local/bin/fastlane android metadata` (system Ruby — `bundle exec` is
  broken on this machine). It's keyed `default.txt` rather than `<versionCode>.txt` because
  EAS autoincrements the version code at build time, and `supply` applies `default.txt` to
  whatever code is promoted. Store images go through `fastlane android upload`; iOS listing
  text uploads via `deliver`.
- **Without fastlane**, there is no automation at all beyond the binary upload: both stores'
  "What's new" text is pasted by hand, and the wider listing (descriptions, screenshots,
  categories, content-rating answers) lives only in the consoles — **not version-controlled,
  and therefore invisible to the step-2 review gate**, which must report listing guidelines
  as *not assessed* rather than Pass. Don't write into a `fastlane/` path that doesn't exist;
  scaffolding one needs Play/ASC service-account credentials and is the user's call.

### Build

- The default build profile is `production`; `--clear-cache` forces a clean native build
  (avoids stale prebuilt frameworks baking a mismatched native module — e.g. an Expo
  dyld launch crash). Drop it for a faster, cached build.

## Scripts

- `scripts/release-info.mjs` — read-only; prints `{ current, lastTag, suggested,
  suggestedBump, today, commits[] }` as JSON. No writes.
- `scripts/set-version.mjs <version>` — patches `package.json`, plus `app.config.ts` **if
  that file exists** (it's skipped otherwise). No git. In a repo whose Expo config is a
  static `app.json`, check the version landed there too and patch it by hand if not —
  the script does not write `app.json`.

Both honor `RELEASE_APP_DIR` (default `apps/mobile`) and, for discovery,
`RELEASE_TAG_PREFIX` (default `mobile-v`).
