---
name: expo-release
description: Cut a release for the Expo / React Native mobile app — pre-flight the store review rules for the target platform, pick the platform and version, generate the store "what's new" notes, update CHANGELOG.md, and create the release branch + git tag + GitHub release. Use when the user wants to release, ship, or cut a new mobile / Expo version, bump the app version, prepare release notes, or runs expo-release. Replaces the manual build.sh release flow.
---

# expo-release

Orchestrates a mobile release end-to-end: **detect → platform → store-review gate →
version → notes → branch → commit → EAS build → auto-merged PR → tag**. The helper
scripts handle the deterministic parts (version discovery, file patching); you curate
the human-readable notes.

This skill runs the whole flow without stopping for approval at the build or merge
steps: it **always triggers** the EAS build **before** the PR — so a release that
can't build never reaches `main` — then **auto-merges** the release PR, printing the
build link(s).

> **This skill is repo-agnostic. Do not assume a release contract — detect it.**
> Expo repos differ on four axes that change what the later steps must do, and every
> wrong assumption here fails *silently* (a step waits for a file that never changes,
> or writes copy into a path nothing reads) rather than erroring. **Step 0 is not
> optional**, and nothing below it may be run from memory of a previous repo.
>
> This is not hypothetical — it is the bug this skill was rewritten to prevent. A copy
> of it hardcoded one repo's contract, was reused in a second repo with the opposite
> contract, and the mismatch survived a real end-to-end run unnoticed.

The **one** place it stops for a human is the store-review gate in step 2: anything
that could get the build rejected halts the release before a single file is touched,
and the user decides what happens next.

## Inputs (args, else ask)

- **platform** — `ios` | `android` | `all`. If not given, ask with `AskUserQuestion`.
  Resolve this **first** — it selects which review check gates the release (step 2).
- **version** — SemVer like `2.1.0`. If not given, recommend one (see step 3) and ask.

## Workflow

Run everything from the **repo root**. Let `SK=~/.claude/skills/expo-release`.

### 0. Detect the release contract (do this first, every time)

Resolve the app directory, then read four facts off the repo. Report them back to the
user in a short table before continuing — if any surprises you, stop and ask.

```sh
APP="${RELEASE_APP_DIR:-apps/mobile}"; [ -d "$APP" ] || APP=.
echo "appDir: $APP"

# A. version source + auto-increment
node -p "const e=require('./$APP/eas.json'); \
  'appVersionSource: '+(e.cli?.appVersionSource ?? '(unset → EAS defaults to remote)')+ \
  '\nautoIncrement:    '+(e.build?.production?.autoIncrement ?? false)"

# B. Expo config: static (writable) or dynamic (not writable)
ls "$APP"/app.json "$APP"/app.config.ts "$APP"/app.config.js "$APP"/app.config.mjs 2>/dev/null

# C. fastlane present?
test -d "$APP/fastlane" && echo "fastlane: yes" || echo "fastlane: no"

# D. release-notes naming convention
ls "$APP/release-notes/" 2>/dev/null
```

Read the results as:

| Fact | Values | What it controls |
|---|---|---|
| **A. `appVersionSource`** | `local` / `remote` | Whether EAS writes the native build number **into the repo** (step 7) |
| **B. Expo config** | `app.json` (static) / `app.config.*` (dynamic) | Whether EAS *can* write it back at all |
| **C. fastlane** | present / absent | Whether store copy is pushed by tooling or pasted by hand (steps 2, 4, 9) |
| **D. notes naming** | `<v>-ios.md`/`<v>-android.md` / bare `<v>.md` | Which files step 4 writes and step 9 reads |

**A and B interact, and B wins.** `local` asks EAS to write the incremented
`buildNumber`/`versionCode` back into the Expo config — which only works if that config
is a **static `app.json`**. A *dynamic* `app.config.*` cannot be auto-written (that's
usually why it's dynamic: a key comes from the environment). So:

- **`local` + `app.json`** → EAS rewrites `app.json` on disk at build time. Step 7 has a
  commit to make.
- **`remote`** (any config) → the build number lives on EAS's servers. **Nothing lands in
  the working tree**; step 7 has nothing to commit.
- **`local` + dynamic `app.config.*`** → **misconfigured.** Stop and tell the user: this
  combination cannot work. Either the config must become a static `app.json`, or
  `appVersionSource` must become `remote`. Don't try to release around it.

For **D**, infer from what's already in `release-notes/`. Mixed or empty is ambiguous —
if the directory has no clear precedent, **ask** which convention to use rather than
picking one. A stray legacy file (an old unsuffixed `1.0.0.md` beside newer suffixed
ones) means *suffixed*; go with the majority of the recent files.

### 1. Preflight

Confirm the working tree is clean and you're on `main` in sync with `origin/main`
(`git fetch -q origin main` then compare). If on another branch, out of sync, or the
tree is dirty, **warn and ask before continuing** — don't abort silently.

### 2. Store-review pre-flight gate (blocking)

Before touching a single file, audit the release against the store review rules for the
platform(s) being shipped — in a **subagent** — and wait for the verdict:

| platform | check to run |
|---|---|
| `ios` | `app-store-review-check` |
| `android` | `google-play-review-check` |
| `all` | **both** |

Launch each with the `Agent` tool (`subagent_type: general-purpose`,
`run_in_background: false` so the release blocks on it). For `all`, put **both** Agent
calls in a **single message** so they run concurrently, and don't continue until both
have reported. Tell each agent to invoke its skill via the `Skill` tool against **this
repo at HEAD** — repo root, the Expo config detected in step 0 (name it explicitly:
`app.json` or `app.config.*`), the privacy/permission config, this version's
`release-notes/` copy if it exists, and — **only if step 0 found fastlane** — the store
metadata under `<appDir>/fastlane/metadata/`. Have it write its full report to the
scratchpad and **return**: the overall verdict (Ready / Fix-before-submit / Not ready),
the blocker and risk counts, the report path, and one line per non-Pass finding
(guideline/policy number, verdict, `file:line`, fix). Don't re-audit or downgrade what
comes back — the checks own their calibration.

**Tell the agent what it cannot see** — and this depends on step 0's fastlane result:

- **No fastlane** → the store *listing* (descriptions, screenshots, keywords, categories,
  content-rating answers) is **not in this repo at all**. The guidelines that judge
  listing text and imagery — Apple 2.3.x accurate metadata, Play's Store Listing
  policies — are **out of the gate's reach**, and the agent must report them as
  *not assessed* rather than as Pass. A clean verdict means the binary and its config
  look shippable, not that the listing does. **Never point the agent at a
  `fastlane/metadata/` path that doesn't exist** — it will silently assess nothing and
  return a clean verdict, which reads exactly like a real pass.
- **Fastlane present** → point the agent at `<appDir>/fastlane/metadata/` and let it
  assess the listing copy for real.

**Then gate on the result.** Continue automatically **only** when every finding is
**Pass**. On any **Likely rejection**, **At risk**, or **Needs info** finding, **stop the
release before any mutation** (no notes, no version bump, no branch, no build), show the
findings worst-first, and ask with `AskUserQuestion`:

- **Stop and fix the findings first (Recommended)** — end this release run; fixes land as
  their own PRs and the release is re-run afterwards.
- **Fix them now, then continue** — apply the fixes in this session, then **re-run this
  step from scratch** (a fresh audit, not a re-read of the old report).
- **Proceed anyway** — explicit override only. Record it in the release PR body (verdict,
  blocker count, report path, and that the user waived it) so the decision stays traceable.

For `all`, a split result (one platform clean, the other not) is its own question: offer
**releasing only the clean platform** alongside those options, and if the user takes it,
narrow `platform` for the rest of the flow — which also drops that platform's step-4
notes output.

A check that **couldn't run** (skill missing, subagent error, no findings returned) is
not a Pass — report that and ask before continuing.

### 3. Resolve version

Run `node "$SK/scripts/release-info.mjs"` → JSON with `current`, `lastTag`, `suggested`,
`suggestedBump`, and `commits[]` (subjects since the last tag). If the user passed a
version, use it. Otherwise ask with `AskUserQuestion`, listing `suggested` **first** as
"(Recommended)" with the bump reason, plus the other two bump levels. If `current`'s tag
already exists, see [REFERENCE.md](REFERENCE.md) (amend vs. patch).

### 4. Write the notes

From `commits[]`. Curate — don't dump raw subjects.

**Always:**

- **`<appDir>/CHANGELOG.md`** — prepend a `## [<version>] - <today>` section in Keep a
  Changelog style (Added / Changed / Fixed / Moderation & Security), each line ending
  with its `(#NN)` PR number. Written for every release, both platforms.

**Then the store copy, per step 0's convention D** — write only the file(s) for the
platform(s) being shipped:

- **Suffixed convention** → `<appDir>/release-notes/<version>-ios.md` (when platform is
  `ios`/`all`) and `<appDir>/release-notes/<version>-android.md` (when `android`/`all`).
- **Bare convention** → a single `<appDir>/release-notes/<version>.md` covering the
  release.

Whatever the file names, the **iOS** copy is the App Store "What's New in This Version"
text: plain language, bullets, no PR numbers, no hard length limit. The **Android** copy
is the Play "What's new" text — curate it from the same highlights but write it *for
Play*: it is **not** a literal trim of the iOS notes. Play enforces a hard
**≤ 500 characters** per language; **measure with `wc -m`** and cut until it fits rather
than letting the store truncate mid-bullet. By convention Play copy often carries tags
and extra bullets the App Store copy omits, so the two read differently on purpose.

**If step 0 found fastlane** and the platform includes `android`, also write
**`<appDir>/fastlane/metadata/android/en-US/changelogs/default.txt`** with that Play
copy, overwriting it each release. Use `default.txt`, **not** `<versionCode>.txt` — with
`autoIncrement` EAS owns the final `versionCode` at build time, so the number isn't known
when the release is cut, and `supply` applies `default.txt` to whatever code is promoted.

**If step 0 found no fastlane**, do **not** create a `fastlane/` path. Both files are copy
the user pastes into the store console by hand (see the store note at the bottom) —
nothing in the repo uploads them.

### 5. Bump the version

`node "$SK/scripts/set-version.mjs" <version>` — patches `package.json`, plus
`app.config.ts` if present. Confirm from its output which files it touched; if the repo's
Expo config is a static `app.json`, check the version landed there too and patch it by
hand if the script didn't.

### 6. Branch + commit the bump & notes

Branch `release/mobile-<version>` and commit the version bump (step 5) + notes (step 4).
Commit message: summarize the release and end with the `Co-Authored-By` trailer (per repo
conventions). **Do not push, create the PR, or merge yet** — the build runs first, so a
release that can't build never reaches `main`.

Whether this is the branch's *only* commit depends on step 0's fact A; step 7 says which.

### 7. Run the build (always)

Do **not** just hand off — kick off the EAS build for the chosen platform from `<appDir>`:
`npx eas build --platform <platform> --profile production --clear-cache --non-interactive`.
Run it in the background so the session isn't blocked, and once EAS has queued the
build(s), **print the build link(s)** for every platform (the `https://expo.dev/…/builds/…`
URL EAS prints per platform; for `all` that's one per platform). If EAS can't run
non-interactively (missing credentials), report the failure and the command to finish it.

**What happens next is decided by step 0's fact A:**

- **`appVersionSource: "local"` (+ static `app.json`)** — EAS **rewrites `app.json` on
  disk** early in the build, bumping `ios.buildNumber` and/or `android.versionCode` (the
  native build version, distinct from the SemVer `version` from step 5). This increment
  lands *before* the cloud build finishes, so **don't wait for the build to complete**:
  watch the working tree (`git status --porcelain app.json`) until `app.json` shows the
  change, then **commit it onto the same release branch** with a message like
  `build: increment native build version for <version>` + the `Co-Authored-By` trailer.
  If nothing changes `app.json` (EAS didn't run, or the platform's field was untouched),
  skip this commit and say so — **don't fabricate a bump**.
- **`appVersionSource: "remote"`** — `production.autoIncrement` advances the build number
  on **EAS's servers**; the working tree is untouched. The release branch therefore
  carries exactly **one** commit (step 6's). Do **not** watch `git status` for a change,
  and do **not** create a "build: increment native build version" commit — there is no
  such change to capture. Read the resulting build number off the EAS build page if you
  need it.

### 8. Push, PR, auto-merge

Push the release branch and `gh pr create` (base `main`). PR body: summarize the release
and end with the Claude Code footer (per repo conventions). Then **auto-merge without
asking** — `gh pr merge <#> --squash --delete-branch` (add `--auto` if branch protection
requires checks to pass first; fall back to `--admin` only if the user has said they want
to bypass). Report the merge; don't pause for approval.

### 9. Tag + GitHub release

Because the PR is **squash-merged**, the branch commit isn't on `main` — first
`git checkout main && git pull --ff-only origin main` so HEAD is the squash-merge commit,
then tag `<tagPrefix><version>` (e.g. `mobile-v2.1.0`) on it, push the tag, and
`gh release create <tag> --title ... --notes-file <path> --target main` (or `--notes` from
the CHANGELOG section).

Pick `<path>` from step 0's convention D:

- **Suffixed** → use the **`-ios`** file when both platforms shipped; it's the unabridged
  copy, whereas `-android` is the 500-char Play cut, not a summary of the release. For an
  Android-only release use `<version>-android.md`.
- **Bare** → `<appDir>/release-notes/<version>.md`.

See [REFERENCE.md](REFERENCE.md) if `gh pr merge --auto` hasn't landed yet (wait for the
merge before tagging).

**If step 0 found fastlane** and Android shipped, the Play "What's new" text still has to
be pushed *after* the build is submitted (the version code must be in the track first):
`fastlane android metadata` from `<appDir>`. On this machine `bundle exec` is broken —
invoke via system Ruby: `/usr/bin/ruby /usr/local/bin/fastlane android metadata`. Store
images go through `fastlane android upload`.

## Notes

- Defaults target a monorepo layout: `appDir = apps/mobile`, tag prefix `mobile-v`.
  Override with `RELEASE_APP_DIR` / `RELEASE_TAG_PREFIX` env vars for another app.
- **Never hardcode a release contract into this skill.** The four facts in step 0 differ
  between repos and each mismatch fails silently. Two live examples on this machine, with
  *opposite* contracts — which is exactly why step 0 exists:

  | | `appVersionSource` | Expo config | fastlane | notes naming |
  |---|---|---|---|---|
  | `milemark/apps/mobile` | `remote` | dynamic `app.config.ts` | none | `<v>-ios.md` / `<v>-android.md` |
  | `fexi/fexi-mobile` | `local` | static `app.json` | yes (`supply`/`deliver`) | bare `<v>.md` |

  Treat that table as an illustration that repos diverge, **not** as a lookup to skip
  step 0 with — either repo may change, and a third may appear.
- **`local` requires a writable static config.** It asks EAS to persist the incremented
  build number into the Expo config, which a dynamic `app.config.*` cannot accept. If a
  repo has both `local` and a dynamic config, that's a misconfiguration to surface, not to
  work around. A repo may also *pin* its contract: `milemark` has
  `apps/mobile/src/release-config.test.ts` asserting its config stays dynamic, its source
  stays `remote`, and its notes stay suffixed — so converting it fails CI until this flow
  is revisited too (0XC-285).
- Re-running for an **already-shipped** version is unsafe — steer to a patch instead.
  See [REFERENCE.md](REFERENCE.md).
- **Store listing copy: check for fastlane, don't assume either way.**
  - *With fastlane* — the Play listing is pushed by `supply` (not EAS); EAS submit only
    uploads the AAB to the `internal` track. iOS listing text uploads via `deliver`.
  - *Without fastlane* — EAS submit uploads the binary and that is the whole of the
    automation. The "What's new" text is **yours to paste**: the iOS notes into App Store
    Connect's "What's New in This Version", the Android notes into the Play Console
    release's release-notes box. Nothing pulls `release-notes/*.md` automatically, and the
    wider listing (descriptions, screenshots, categories) is console-managed and **not**
    version-controlled — worth knowing before a review gate asks to inspect it, since
    there's nothing in the repo for it to read. Don't write into a `fastlane/` path or
    call `fastlane` in this case; scaffolding it needs Play/ASC service-account
    credentials and is a decision for the user, not this flow.
- The default build profile is `production`; `--clear-cache` forces a clean native build
  (avoids stale prebuilt frameworks baking a mismatched native module — e.g. an Expo dyld
  launch crash). Drop it for a faster, cached build.
