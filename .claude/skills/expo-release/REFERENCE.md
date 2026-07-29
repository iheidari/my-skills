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
gh release edit mobile-v<version> --notes-file apps/mobile/release-notes/<version>.md
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

- `eas.json` uses `appVersionSource: "local"` + `production.autoIncrement`, so the SemVer
  `version` comes from `app.json` (the local `set-version.mjs` bump) and EAS bumps only the
  native build version (`ios.buildNumber` / `android.versionCode`) **in `app.json` on disk**
  at build time. That on-disk build-number change is what SKILL step 7 commits onto the
  release branch before the PR — so the PR carries both the SemVer bump and the build-number
  bump. Because the source is local, there's no `build:version:set` remote push to make.
- The `release-notes/<version>.md` file is the copy you paste into **App Store Connect**
  ("What's New in This Version"). EAS submit does not upload it for you.
- **Android release notes are automated.** The skill also writes the same copy (≤ 500 chars)
  to `fastlane/metadata/android/en-US/changelogs/default.txt`; push it to the **Play Console**
  after the AAB is submitted with `/usr/bin/ruby /usr/local/bin/fastlane android metadata`.
  It's keyed as `default.txt` rather than `<versionCode>.txt` because EAS autoincrements the
  version code at build time, and `supply` applies `default.txt` to whatever code is promoted.
- The default build profile is `production`; `--clear-cache` forces a clean native build
  (avoids stale prebuilt frameworks baking a mismatched native module — e.g. an Expo
  dyld launch crash). Drop it for a faster, cached build.

## Scripts

- `scripts/release-info.mjs` — read-only; prints `{ current, lastTag, suggested,
  suggestedBump, today, commits[] }` as JSON. No writes.
- `scripts/set-version.mjs <version>` — patches `package.json` + `app.config.ts`. No git.

Both honor `RELEASE_APP_DIR` (default `apps/mobile`) and, for discovery,
`RELEASE_TAG_PREFIX` (default `mobile-v`).
