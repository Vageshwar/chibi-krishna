# Handoff — read this first if you're picking up fresh

Written 2026-08-25 (Windows→MacBook Air transition), updated several times since — most recently 2026-08-26 after the user merged everything through PR #36 and asked for a fresh handoff to continue in a new session. If you're a new session, start here — then follow `CLAUDE.md`'s own "before writing or deciding anything" checklist for the live PRD/GitHub state, since this file is a snapshot and decays fast.

## Environment: confirmed working on the MacBook Air

- **Android**: real emulator (`Medium_Phone_API_36.1`, Android 16/API 36) via `flutter emulators --launch Medium_Phone_API_36.1`. `flutter build apk --debug` / `flutter build appbundle` and `flutter run -d emulator-5554` all work. `adb` lives at `/Users/vageshwaryadav/Library/Android/sdk/platform-tools/adb` (not on `PATH` by default in this shell).
- **iOS**: simulator (`iPhone 16e`, device id `5A608090-37CA-45C3-806D-46E0EAE03CE1`) works for local dev. **Not a shipping target** — `CLAUDE.md` pins Android-only for release; iOS is purely local-dev convenience. Several iOS-only build fixes exist solely to keep that convenience working (two separate `google_mobile_ads`-related iOS build breakages — see PR #30/#32 commit history before touching `ios/Podfile` again).
- **`flutter test`**: needed a one-time native-library setup — `dart run rive_native:setup --verbose --clean --platform macos`. Without it, any widget test touching `ChibiStageView` fails with a Rive FFI dylib-not-found error. `flutter test test/widget_test.dart` passes now.
- Chrome is real on this machine (`flutter run -d chrome` works).
- **No way to hear TTS/audio output through any available tooling** — timing and voice-quality judgments in this app need the user to actually listen and report back. Emulator/simulator also can't produce real speech input, so anything gated on STT (quota exhaustion → ads, etc.) needs a real device to exercise end-to-end.

## Where things stand

**Everything through PR #36 is merged into `feature/sprint-1-foundation`.** In order: #25 (removed the old 3D stub), #26 (Rive stage + mic-to-quote loop), #30 (audio fix for #6, speaking-pose-before-audio fix as #29, iOS local-dev enablement), #31 (welcome splash, quieter music), #32 (local voice quota #16, AdMob banner/rewarded #18, banner/mic layout fix, simplified home screen, app icon + branded native splash, voluntary "$" Dakshina button), #33 (Play Store launch planning + published privacy policy), #35 (kid-like TTS pitch), #36 (STT/response latency tuning).

- **Issues #8, #9, #10, #11 were closed today** — they were done (bundled in PR #26) but never auto-closed because that PR's `Closes #5, #8, #9, #10, #11` line only linked issue #5 (a GitHub multi-issue-closing quirk, noted earlier in the session, finally cleaned up).
- **MVP milestone remaining: #7 (Hindi-first chrome/English toggle/About — now launch-blocking, see below), #12 (internal smoke-test build on a real device), #27 (CC BY attribution), #34 (release signing keystore).**
- **Decision locked 2026-08-25**: launching on **this MVP build**, not waiting for V1/Gemini. Quota (10 voice turns/day) ships active as built, not softened. Targeting worldwide including EU/UK, so the UMP consent SDK is required code work, not done yet.
- **Voice tuning, done this session**: `TtsService._pitch = 1.2` (kid-like, PR #35) and `SpeechService`'s `pauseFor = 2s` (PR #36 — was cut to 1.2s first, user found that too aggressive/cutting them off mid-sentence, raised back to 2s). Both are one-line constants if they need retuning again; ask the user to judge by ear, Claude can't hear the result itself.
- **Privacy policy is live**: <https://vageshwar.github.io/chibi-krishna/legal/privacy-policy.html> (GitHub Pages, source: `feature/sprint-1-foundation` branch `/docs` folder). Contact email `vageshwar.dev@gmail.com`. `docs/legal/privacy_policy.md` is the source-of-truth draft — edit that first, then port changes into `docs/legal/privacy-policy.html`, they're not auto-synced.
- **Known gap, not yet exercised**: the full 10-turn quota exhaustion → Support sheet → watch-rewarded-ad → +5 turns flow has never been tested end-to-end — needs a real device.
- **Known cosmetic gap**: on Android 12+, the native splash's OS-enforced circular icon viewport clips the "KRISHNA A.I" text baked into `assets/logo.jpg`'s bottom edge. The home-screen *launcher* icon is fine. Not blocking.
- Gemini (#13/FF-01) is **still not integrated** — deliberately, even for this launch. Every response is still the same local Gita-quote picker.
- Full technical narrative of the Rive integration: `progress/mvp-02-rive-mic-loop.md`.

## The one thing most likely to trip up a fresh session

The character rig (`assets/rive/chibi_krishna.riv`) is **not** what the original spec docs (`docs/requirements/assets_v3.md` §4) describe — that was written speculatively before any real `.riv` existed. The real asset is the **KrishnaJI marketplace asset** (CC BY 4.0, creator `ar.akash`) using Rive **Data Binding** — a ViewModel with three enum properties: `poses`, `emotion`, `eye`. See `docs/requirements/assets_v3.md` §4a for the verified real contract (§4 above it is historical) and `lib/features/stage/presentation/widgets/chibi_stage_view.dart` for the reference implementation.

Also: `rive: 0.13.x` is that package's abandoned legacy runtime and cannot render this asset. The project is on `rive: ^0.14.11`. Don't downgrade it.

## Play Store launch checklist — pick up here

Three scope decisions locked in 2026-08-25 (don't re-litigate without a reason): quota active as built, Claude drafts legal docs, targeting worldwide including EU/UK.

**Play Developer account: registered, was in Google's identity verification as of 2026-08-25** — check current status, this may have cleared by now.

### Code work — no external blockers, can start any time

- [ ] **UMP consent flow** — required since targeting EU/UK/EEA; personalized ads legally can't serve there until this is wired. `google_mobile_ads` is already in the app. Comparable in scope to the original AdMob integration — budget a real session.
- [ ] **About screen** (issue #7 territory, now launch-blocking). Needs three things reachable *in the app*:
  - AI-avatar disclaimer, verbatim from PRD v3 §3: *"AI avatar of Krishna, created to share joy and Gita-inspired wisdom... not a living guru, not a replacement for temple, family, or clinicians."*
  - **CC BY 4.0 attribution for the Rive character** (issue #27) — [KrishnaJI](https://rive.app/marketplace/27686-52286-krishnaji/) by creator `ar.akash`. Everything needed is already documented, nothing to ask the user.
  - Link to the published privacy policy (URL above).
- [ ] **Release signing keystore + Gradle config — tracked as issue #34.** Recommended approach (Play App Signing, not the legacy self-managed flow) and exact `keytool`/Gradle steps are in the issue. Open decisions for the user: cert DN details, backup/custody location for the resulting `.jks` + passwords.

### Needs the user's input or a decision

- [ ] **Store listing content** — short + long description, category, feature graphic (1024×500), screenshots. Claude can draft description copy and generate screenshots from the emulator/simulator once the app is otherwise ready (the `adb exec-out screencap` / `xcrun simctl io screenshot` tooling from this session works fine).
- [ ] **Content rating questionnaire (IARC)** — answered at submission time. Facts to have ready: no user-generated content, no violence, contains ads, no IAP (locked, never adding it — PRD §7), religious/spiritual character content, target age 13+.
- [ ] **Target audience & content section in Play Console** — 13+/devotees/parents, explicitly not "Designed for Families" (`CLAUDE.md`'s locked decision).
- [ ] **Terms of Service** (soft requirement) — not drafted yet. Ask if the user wants Claude to draft this too, same as the privacy policy.

### Straightforward, just don't forget

- [ ] Advertising ID (AD_ID) declaration in Play Console's App Content section.
- [ ] "Contains ads: yes" / "In-app purchases: no" declarations.
- [ ] Play Console "Data Safety" form — must match the privacy policy exactly, item by item.

None of this blocks other feature work (Gemini, crisis strip, etc. can proceed in parallel).

## Quick orientation for new work

1. `CLAUDE.md` — always read first, points at the rest.
2. `docs/Chibi_Krishna_AI_PRD_v3.md` — the build spec.
3. `gh issue list --state open --json number,title,milestone,labels` and `gh api repos/Vageshwar/chibi-krishna/milestones` — live scope, not the markdown issue docs.
4. `docs/requirements/assets_v3.md` §4a — the real Rive contract, if touching the character.
5. `docs/legal/privacy_policy.md` — privacy policy source draft (published version: `docs/legal/privacy-policy.html`, live on GitHub Pages).
6. `progress/*.md` — narrative history of what was tried, what broke, and how it got fixed, per piece of work.
7. `gh pr list --state open` — check nothing's stuck in review before assuming a clean base to branch from.

This file itself will go stale — it's a snapshot, not a living doc. Trust the live GitHub state and the code over anything time-bound written here.
