---
name: app-store-review-check
description: Acts as an Apple App Store reviewer — audits an iOS/iPadOS/macOS/tvOS/watchOS app against the App Store Review Guidelines and returns a pass/fail report with the specific guideline numbers at risk and concrete fixes. Use this whenever the user wants to pre-check, pre-flight, audit, or "review like Apple would" an app before submitting to App Store Connect, whenever they mention App Store rejection, App Review, guideline compliance, TestFlight review, metadata/privacy-label review, or worry about why an app might get rejected — even if they just paste an app description, screenshots, privacy labels, or an App Store Connect API key and ask "will this get approved?"
---

# App Store Review Check

Play the role of an Apple App Review reviewer. Take whatever the user can provide
about their app, walk it against the App Store Review Guidelines, and produce a
verdict for each relevant guideline plus a concrete fix — the same shape of feedback
Apple sends in a rejection, but *before* they submit so they can fix it first.

You are not Apple and can't guarantee an outcome. Be clear that this is a best-effort
pre-flight audit that reduces rejection risk; the real reviewer makes the final call.

## What you can review (any subset)

The more inputs, the more thorough the audit. Ask for what's missing but never block —
review what you have and mark unknown areas explicitly.

- **App metadata / listing**: name, subtitle, keywords, description, promotional text, category, age rating, "What's New", screenshots, preview videos, support URL, marketing URL.
- **Privacy**: privacy policy URL/text, App Privacy "nutrition label" answers, purpose strings (Info.plist usage descriptions — *or* the framework config that generates them, e.g. an Expo plugin's `userTrackingPermission`), ATT usage, data collection/sharing, third-party SDKs.
- **Functional description**: what the app does, business model, monetization, login flow, backend/demo-account availability.
- **Source code / project**: scan for private-API usage, background modes, entitlements, IAP/StoreKit usage, tracking SDKs, hardcoded external-payment links, missing account deletion, and **permission-request flows** (custom pre-permission dialogs that can be cancelled before the system prompt — see the Permission-flow audit step below).
- **Screenshots / built UI**: check against design + content rules (screenshots show real use, 4+ appropriate, no other-platform imagery, dismissible ads, etc.).
- **App Store Connect data (optional, automated)**: if the user has an App Store Connect API key, `scripts/fetch_asc_metadata.py` can pull live app metadata and TestFlight builds directly. See "Pulling data from App Store Connect" below.

## Process

1. **Intake.** Establish app type and platform(s), what it does, its business model, and which inputs the user provided. If they only pasted a description, that's fine — review it and flag that a code/metadata/screenshot pass would catch more.

2. **Scope the guidelines.** Read `references/guidelines.md` — the condensed, review-oriented map of all five sections with rejection criteria. Determine which subsections apply. An app with no IAP skips most of §3.1; a kids app pulls in 1.3 and 5.1.4; a VPN pulls in 5.4; a UGC/social app pulls in 1.2. When the app touches a high-risk or nuanced area (payments, privacy/ATT, crypto, gambling, health, kids, VPN/MDM), re-fetch the live guidelines page to confirm current wording before ruling, because these change and carry the heaviest enforcement.

3. **Audit each applicable guideline.** For every relevant subsection produce: guideline number + title, a verdict (**Pass** / **At risk** / **Likely rejection** / **Needs info**), the evidence that drove it, and a concrete fix. Prioritize the high-frequency rejection reasons listed at the end of `references/guidelines.md` — they catch most real rejections. Don't invent violations; if you can't determine something from the inputs, mark it **Needs info** and say what to provide.

4. **Run the mechanical-pattern sweep (when source is available).** Beyond reasoning about guidelines, there is a set of **objective, code-detectable patterns Apple's own review tooling flags automatically** — these produce the most predictable rejections, so check them explicitly and default them to **Likely rejection** (not "At risk") when the pattern is present, because a real reviewer's automation will catch them. Grep the project and trace each hit:

   - **Permission priming (5.1.1(iv)) — the highest-signal one.** Find **every** native permission request: `request*PermissionsAsync` (Expo), `requestCameraPermissionsAsync`/`requestMediaLibraryPermissionsAsync`/`requestForegroundPermissionsAsync`, `AVCaptureDevice.requestAccess`, `PHPhotoLibrary.requestAuthorization`, `CLLocationManager.request*`, `UNUserNotificationCenter.requestAuthorization`, `CNContactStore.requestAccess`, `react-native-permissions` `request()`. For each, trace **backwards** to what triggers it. If the request is reached only *after* a custom `Alert`/`Modal`/action-sheet, check whether that gate exposes any **non-proceeding path** — a `Cancel`, `Not now`, `Maybe later`, `Deny`, `Skip`, backdrop/scrim tap, swipe-dismiss, or hardware-back that returns to the app instead of the OS prompt. **Any such path → Likely rejection under 5.1.1(iv).** The custom screen may only lead to the system prompt. (This is the exact pattern that got real Milemark builds rejected: an `Alert.alert(title, guidelineText, [Take photo, Choose from library, Cancel])` in front of `requestCameraPermissionsAsync`.) **Do not score a priming/rationale modal as a compliance strength** — it is a risk to interrogate, never a plus.
   - **Account deletion (5.1.1(v)).** If the app creates accounts (any OAuth/email sign-in), grep for an in-app deletion path (`delete account`, `DELETE /me`, a delete-account link). Email-only or web-only-with-no-in-app-entry → Likely rejection.
   - **Purpose strings (5.1.1(ii)) — auto-scanned, so treat like the priming check.** Apple runs an **automated** analysis for "placeholder or otherwise insufficient purpose strings" and rejects on it before a human ever opens the app. Audit in three passes:

     **(a) Find them in the right place — absence of a grep hit is NOT a Pass.** `NS*UsageDescription` keys often live nowhere in the committed tree, because the `Info.plist` is *generated* at build time and gitignored. Look up the project's build system before concluding anything:

     | Project type | Where the string actually lives |
     |---|---|
     | Native Xcode | `*/Info.plist`, or `INFOPLIST_KEY_NS*UsageDescription` in `project.pbxproj` / `.xcconfig` |
     | Expo | `app.json` / `app.config.{js,ts}` — `ios.infoPlist`, **plus per-plugin shorthand keys** that expand into plist entries at prebuild: `expo-tracking-transparency` → `userTrackingPermission`; `expo-camera` → `cameraPermission`, `microphonePermission`; `expo-image-picker` → `photosPermission`, `cameraPermission`, `microphonePermission`; `expo-media-library` → `photosPermission`, `savePhotosPermission`; `expo-location` → `locationWhenInUsePermission`, `locationAlwaysAndWhenInUsePermission`, `locationAlwaysPermission`. **Grepping only for `NS*UsageDescription` misses every one of these.** The list isn't exhaustive — confirm a given package's option names from its Expo docs page or its `app.plugin.js` / `plugin/build/`, since they vary per package and across SDK versions. |
     | Bare React Native | `ios/<App>/Info.plist` (committed) |
     | Flutter | `ios/Runner/Info.plist` |
     | Capacitor / Cordova | `ios/App/App/Info.plist`, or `config.xml` `<edit-config>` blocks |

     Also check the *generated* plist when one exists locally (`plutil -convert xml1 -o - ios/<App>/Info.plist | grep -A1 UsageDescription`) — it's the ground truth for what ships, and it catches strings injected by a Pod or config plugin that appear in no source file. Only report "no purpose strings" after confirming the app requests no protected resource at all.

     **A permission plugin that's installed but whose string option is unset is a finding, not a blank.** These plugins inject a **default** when you don't override them — Expo's are stock Xcode-style strings like `"Allow $(PRODUCT_NAME) to access your photos"`, `"Allow $(PRODUCT_NAME) to use your location"`, `"Allow $(PRODUCT_NAME) to save photos"`. So an app that never configured the option still ships boilerplate straight into the plist. Cross-check the installed permission-related packages against the options actually set in config: every installed one with no string set → **Likely rejection**, same as an explicit placeholder.

     **(b) Test each string for placeholder-ness → Likely rejection.** A compliant string answers **how the data is used** *and* gives **a specific example**. Flag as **Likely rejection** when a string:
     - is the **framework's own doc/template default**, verbatim. These are the highest-signal hits, since they ship in thousands of apps and the scanner knows them. Known examples: `"This identifier will be used to deliver personalized ads to you."` (expo-tracking-transparency docs — a real 2026 rejection), `"Allow this app to collect app-related data that can be used for tracking you or your device."`, `"Allow $(PRODUCT_NAME) to access your camera"`, `"$(PRODUCT_NAME) needs access to your photo library"`, or anything still carrying a `$(PRODUCT_NAME)` token or Xcode's stock wording;
     - merely **restates the permission** without a use — "App needs microphone access", "App would like to access your Contacts" (Apple's own examples of strings that fail);
     - names the data but not the **purpose** — "This identifier will be used for ads" says *that*, not *how*;
     - carries **no concrete example** of the resulting user-visible behavior;
     - is a single short clause (< ~60 chars is a strong tell), obvious lorem/TODO text, or empty.

     A good replacement names the use, any third party receiving the data, and an example: *"Fexi shares your device's advertising identifier with our ad provider, Google AdMob, to personalize the ads in the free version — for example, showing a travel or banking ad instead of an unrelated one."*

     **(c) Check for orphaned strings.** Apple's rejection offers two remedies, and the second is often the right one: *remove* the string and the code reaching the resource. For each declared string, grep for a matching API call. A string with no corresponding request — left over from a removed feature, a copy-pasted template, or a dependency's boilerplate — is itself a rejection trigger and should be deleted rather than reworded.

     Two follow-ons once the strings pass (a)–(c): confirm each names **all** uses of that data, not just one (a camera string saying "profile photo" while the app also shoots campground photos → At risk), and confirm the ATT string is consistent with the App Privacy label and `NSPrivacyTrackingDomains`. When flagging, say explicitly that this is a **binary** fix — the string compiles into `Info.plist`, so it needs a new build and build number, and cannot be resolved by replying in Resolution Center or editing the App Store Connect listing.
   - **ATT / tracking (5.1.2).** Grep for tracking/ads/analytics SDKs (Facebook, AppsFlyer, Adjust, Branch, Firebase Analytics, AdMob, Segment, Amplitude) and IDFA use. If any track users across apps/sites and there's no `AppTrackingTransparency` prompt → Likely rejection; also flag a privacy-label mismatch.
   - **Private APIs (2.5.1), background modes (2.5.4), external-payment links (3.1.1(a)), StoreKit vs. non-IAP unlocks (3.1.1).** Grep entitlements, `UIBackgroundModes`, hardcoded payment URLs, and unlock logic.

   Ground every finding in a real `file:line`. Presence of a pattern is a finding — don't hand-wave it away.

   **Absence is only a Pass once you've confirmed you searched where this project actually keeps that thing.** A clean grep proves nothing if the file you grepped isn't where the value lives. Cross-platform toolchains (Expo, Flutter, Capacitor, Cordova, Unity) *generate* the iOS project at build time and usually gitignore `ios/`, so plist keys, entitlements, background modes, and URL schemes exist only as declarative config under a framework-specific key — or only in a build artifact. Before recording any Pass-by-absence, identify the build system (look for `app.json`/`app.config.*`, `pubspec.yaml`, `capacitor.config.*`, `Podfile`, a committed `*.xcodeproj`, `.gitignore` entries for `ios/`), then state in the finding *where you looked*. If a resource is plainly used (an ads SDK, a camera screen) but its declaration is nowhere in source, the declaration is generated — go find the generator, don't score it absent.

5. **Verify before finalizing.** Re-read the findings against the actual inputs to avoid false positives (don't flag "no privacy policy" if one was provided) and false negatives (a description mentioning "unlock premium" implies IAP → check §3.1). Confirm each cited guideline number matches its real title. For code audits, ground every finding in a real file/line, not a guess.

6. **Write the report** using `assets/report_template.md`. Deliver it as a Markdown file in the outputs folder and present it to the user.

## Verdict scale

- **Pass** — nothing in the inputs suggests a problem here.
- **At risk** — plausibly non-compliant or a common reviewer flag; explain the risk and the safer path.
- **Likely rejection** — clearly conflicts with a guideline as written; treat as a blocker. **Objective, code-detectable patterns from the mechanical sweep (step 4) belong here, not in "At risk," whenever the pattern is present** — Apple's automation catches them reliably, so a hedge undersells the risk.
- **Needs info** — can't judge from what was provided; state exactly what to supply.

**Calibrate toward the reviewer, not the developer.** This audit's value is catching a rejection *before* a week-long review round-trip, so when a pattern matches a known-enforced rule, rule it a blocker and let the developer decide it's a false alarm — an over-flag costs minutes, an under-flag costs a rejection cycle. Reserve "At risk" for genuinely judgment-dependent calls (a reviewer *might* object); use "Likely rejection" for anything that matches an enforced rule as written. Never label a permission-priming gate, a placeholder/boilerplate purpose string, missing in-app account deletion, or an ATT-less tracking SDK as merely "At risk" — each of these is caught by Apple's own automation, so the outcome isn't a reviewer's judgment call.

Lead the report with a short overall verdict (Ready / Fix-before-submit / Not ready)
and a count of blockers vs. risks, then the per-guideline findings grouped by section,
then a prioritized fix checklist.

## Pulling data from App Store Connect (optional)

There is no App Store Connect connector, so live data requires the user's own API key.
Only do this if the user wants it and provides credentials — otherwise review pasted inputs.

To generate a key: App Store Connect → Users and Access → Integrations → App Store Connect API →
generate a key (Admin or App Manager role), then download the `.p8` file (one-time) and note
the **Key ID** and **Issuer ID**.

`scripts/fetch_asc_metadata.py` uses those to fetch app metadata and TestFlight builds via
the App Store Connect API. It signs a short-lived JWT locally; the key never leaves the sandbox.
Run it in the workspace, e.g.:

```
pip install pyjwt cryptography requests --break-system-packages
python scripts/fetch_asc_metadata.py \
  --key-id ABC123DEF4 --issuer-id 11111111-2222-3333-4444-555555555555 \
  --key-file AuthKey_ABC123DEF4.p8 --app-id 1234567890 --out asc_metadata.json
```

Then review `asc_metadata.json` (app info, versions, localizations, current build state)
the same way you'd review pasted metadata. If the key is missing/invalid, fall back to
asking the user to paste the metadata.

## Notes on judgment

- Guidelines are principles, not a checklist Apple applies mechanically — a human reviewer weighs intent and user experience. Reason about *why* a rule exists (usually user safety, trust, or a fair marketplace) and whether the app honors that spirit, not just the letter.
- Rejections are common and usually fixable in one resubmit; frame findings as "fix this and you're clear," not doom.
- Cite guideline numbers so the user can look them up and, if they disagree with a reviewer later, reply in Resolution Center with specifics.
