# Handoff — read this first if you're picking up fresh

Written 2026-08-25 (Windows→MacBook Air transition), updated twice more the same day — most recently after the user decided to target a **Play Store launch on this MVP build**, not wait for V1/Gemini. If you're a new session, start here — then follow `CLAUDE.md`'s own "before writing or deciding anything" checklist for the live PRD/GitHub state, since this file is a snapshot and decays fast.

## Environment: confirmed working on the MacBook Air

- **Android**: real emulator (`Medium_Phone_API_36.1`, Android 16/API 36) via `flutter emulators --launch Medium_Phone_API_36.1`. `flutter build apk --debug` and `flutter run -d emulator-5554` both work. `adb` lives at `/Users/vageshwaryadav/Library/Android/sdk/platform-tools/adb` (not on `PATH` by default in this shell).
- **iOS**: simulator (`iPhone 16e`, device id `5A608090-37CA-45C3-806D-46E0EAE03CE1`) works for local dev. **Not a shipping target** — `CLAUDE.md` still pins Android-only for release; iOS is purely local-dev convenience. Several iOS-only build fixes exist solely to keep that convenience working (two separate `google_mobile_ads`-related iOS build breakages and fixes — see PR #30/#32 commit history before touching `ios/Podfile` again).
- **`flutter test`**: needed a one-time native-library setup — `dart run rive_native:setup --verbose --clean --platform macos`. Without it, any widget test touching `ChibiStageView` fails with a Rive FFI dylib-not-found error. `flutter test test/widget_test.dart` passes now.
- Chrome is real on this machine (`flutter run -d chrome` works).

## Where things stand

- **Merged into `feature/sprint-1-foundation`**: PR #26 (Rive stage + mic-to-quote loop), PR #30 (audio fix for #6, speaking-pose-before-audio fix as #29, iOS local-dev enablement), PR #31 (welcome splash, quieter music), **PR #32 (just merged)** — local voice quota (#16), AdMob banner + rewarded ads (#18), banner/mic layout fix, simplified home screen (no app bar, auto-fading response bubble), real app icon + branded native splash from `assets/logo.jpg`, and a voluntary "$" Dakshina support button (top-right, PRD §7) that opens the same Support sheet without requiring quota exhaustion.
- **Decision made 2026-08-25**: ship the **10-voice-turns/day quota active as built** (not raised/disabled) for this MVP launch — the user chose to launch with the full monetization mechanic live, not to soften it. Revenue paths on launch: passive banner ad, rewarded ad after quota exhaustion, and the voluntary Dakshina button.
- **Known gap, not yet exercised**: the full 10-turn quota exhaustion → Support sheet → watch-rewarded-ad → +5 turns flow has never been tested end-to-end (neither emulator/simulator gives usable real speech input). **Do this on a real device before submission** — it's the core monetization loop, worth confirming by hand.
- **Known cosmetic gap**: on Android 12+, the native splash's OS-enforced circular icon viewport clips the "KRISHNA A.I" text baked into `assets/logo.jpg`'s bottom edge. The home-screen *launcher* icon is fine (verified on-device). Not blocking; would need a text-free character-only crop to fix properly.
- **Not yet done in MVP:** #7 (Hindi-first chrome/English toggle/About) — **now load-bearing for launch**, see checklist below (About screen is where the AI-avatar disclaimer, CC BY attribution, and privacy-policy link all need to live).
- Gemini (#13/FF-01) is **still not integrated** — deliberately, and **still deliberately deferred even for this launch**. Every response right now is the same local Gita-quote picker, "normal" and "ad-declined-downgrade" paths included.
- Full technical narrative of the Rive integration: `progress/mvp-02-rive-mic-loop.md`.

## The one thing most likely to trip up a fresh session

The character rig (`assets/rive/chibi_krishna.riv`) is **not** what the original spec docs (`docs/requirements/assets_v3.md` §4) describe — that was written speculatively before any real `.riv` existed. The real asset is the **KrishnaJI marketplace asset** (Rive Data Binding — a ViewModel with three enum properties: `poses`, `emotion`, `eye`), verified live. See `docs/requirements/assets_v3.md` §4a for the real contract (§4 above it is historical) and `lib/features/stage/presentation/widgets/chibi_stage_view.dart` for the reference implementation.

Also: `rive: 0.13.x` is that package's abandoned legacy runtime and cannot render this asset. The project is on `rive: ^0.14.11`. Don't downgrade it.

## Play Store launch checklist — next session, start here

The user wants to launch **this MVP build** on Play Store. Three scope decisions are now locked in (made 2026-08-25, don't re-litigate without a reason):

1. **Quota stays active as built** (10/day, rewarded-ad unlock) — not softened for launch.
2. **Privacy policy: Claude drafts it.** First draft is done — see `docs/legal/privacy_policy.md`. It's accurate to the app's *current* actual behavior (mic via OS STT, AdMob/advertising ID, local-only SQLite quota, no Gemini, no analytics, no accounts). Has two placeholders (`[CONTACT EMAIL]`, `[EFFECTIVE DATE]`) that need the user's input before it can be hosted and linked from the Play listing. **Re-check this doc against the code before every future release** — it'll go stale the moment Gemini, Firebase Analytics, or notifications land, exactly like `PRD_v2.md` went stale.
3. **Targeting worldwide, including EU/UK/EEA** — this means Google's **User Messaging Platform (UMP) consent SDK is genuinely required code work before submission**, not just a policy checkbox. `google_mobile_ads` is already in the app; UMP typically ships as part of the same SDK or a small companion package. This is comparable in scope to the AdMob integration itself — budget a real work session for it, not a quick add-on. Until it's wired, personalized ads legally can't serve to EEA/UK/CH users.

### Code work — no external info needed, can start any time

- [ ] **UMP consent flow** (see decision #3 above) — gate personalized ad requests on consent for EEA/UK/CH; test using Google's documented "debug geography" override so it can be verified without a VPN.
- [ ] **About screen** (issue #7 territory, but now launch-blocking, not just nice-to-have) — needs to hold three things Play/licensing actually require to be reachable *in the app*, not only in store metadata:
  - The AI-avatar disclaimer PRD v3 §3 already specifies: *"AI avatar of Krishna, created to share joy and Gita-inspired wisdom... not a living guru, not a replacement for temple, family, or clinicians."* Locked copy, not this session's invention — pull it from the PRD verbatim.
  - **CC BY 4.0 attribution for the Rive character** (issue #27). Everything needed to write the credit line is already documented — no need to ask the user: [KrishnaJI](https://rive.app/marketplace/27686-52286-krishnaji/) by creator `ar.akash`, CC BY 4.0.
  - A link to the hosted privacy policy (once the user has a URL for it — see below).
- [ ] Regenerate/verify release build config is sane (see keystore item below before this matters).

### Needs the user's input or a decision — nothing to start on these without it

- [ ] **Google Play Developer account** — **registered, currently in Google's identity verification** (as of 2026-08-25). Nothing to do but wait; everything else in this checklist can proceed in parallel — Play Console account access isn't needed for local build/keystore/policy/code work, only for actually creating the store listing and submitting.
- [x] ~~Fill the two placeholders in the privacy policy~~ — **done, PR #33**. Hosted via GitHub Pages (repo is public, enabled via `gh api` pointing at `feature/sprint-1-foundation` /docs). Live at <https://vageshwar.github.io/chibi-krishna/legal/privacy-policy.html> **once #33 merges** (Pages serves from that branch, so the file isn't there until then). Contact email is `vageshwar.dev@gmail.com`. `docs/legal/privacy_policy.md` is the source-of-truth draft; `docs/legal/privacy-policy.html` is the published rendering — edit the `.md` first, they're not auto-synced.
- [ ] **Release signing keystore — tracked as issue #34**, not done yet. Recommended approach (Play App Signing, not the legacy self-managed flow) and exact `keytool`/Gradle steps are in the issue. Open decisions left to the user: certificate DN details, and where the resulting keystore + passwords get backed up outside this repo.
- [ ] **Store listing content** — short + long description, app category, feature graphic (1024×500), screenshots (can be generated from the emulator/simulator once the app is otherwise ready — the screenshot tooling from this session, `adb exec-out screencap` / `xcrun simctl io screenshot`, works fine for this).
- [ ] **Content rating questionnaire (IARC)** — answered honestly at submission time. Relevant facts to have ready: no user-generated content, no violence, contains ads, no in-app purchases (locked — never adding IAP per PRD §7), religious/spiritual character content, target age 13+.
- [ ] **Target audience & content section in Play Console** — must reflect the locked positioning: 13+/devotees/parents, explicitly **not** "Designed for Families" (`CLAUDE.md`'s locked decision).
- [ ] **Terms of Service** (soft requirement, not hard-blocking) — worth having given the AI-avatar/crisis-safety framing; reduces liability exposure. Not drafted yet; ask if the user wants Claude to draft this too, same way as the privacy policy.

### Straightforward, just don't forget

- [ ] Advertising ID (AD_ID) declaration in Play Console's App Content section (required — `google_mobile_ads` is integrated).
- [ ] "Contains ads: yes" / "In-app purchases: no" declarations.
- [ ] Play Console "Data Safety" form — must match the privacy policy exactly, item by item. Google checks for mismatches between declared and actual data flows.

None of this blocks other feature work (Gemini, crisis strip, etc. can proceed in parallel) — it's listed here so it doesn't get discovered the week someone tries to actually submit.

## Quick orientation for new work

1. `CLAUDE.md` — always read first, points at the rest.
2. `docs/Chibi_Krishna_AI_PRD_v3.md` — the build spec.
3. `gh issue list --state open --json number,title,milestone,labels` and `gh api repos/Vageshwar/chibi-krishna/milestones` — live scope, not the markdown issue docs.
4. `docs/requirements/assets_v3.md` §4a — the real Rive contract, if touching the character.
5. `docs/legal/privacy_policy.md` — draft privacy policy, needs the user's contact email + hosting URL before it's launch-ready.
6. `progress/*.md` — narrative history of what was tried, what broke, and how it got fixed, per piece of work.

This file itself will go stale — it's a snapshot, not a living doc. Trust the live GitHub state and the code over anything time-bound written here.
