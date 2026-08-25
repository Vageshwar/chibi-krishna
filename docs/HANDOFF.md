# Handoff — read this first if you're picking up fresh

Written 2026-08-25 (Windows→MacBook Air transition), **updated 2026-08-25 later the same day** after a full session of work on the Mac. If you're a new session, start here — then follow `CLAUDE.md`'s own "before writing or deciding anything" checklist for the live PRD/GitHub state, since this file is a snapshot and decays fast.

## Environment: now confirmed working on the MacBook Air

The original version of this file warned not to trust Windows-machine findings. Update: the Mac has now been used extensively this session and everything works cleanly —

- **Android**: real emulator (`Medium_Phone_API_36.1`, Android 16/API 36) via `flutter emulators --launch Medium_Phone_API_36.1`. `flutter build apk --debug` and `flutter run -d emulator-5554` both work. `adb` lives at `/Users/vageshwaryadav/Library/Android/sdk/platform-tools/adb` (not on `PATH` by default in this shell).
- **iOS**: simulator (`iPhone 16e`, device id `5A608090-37CA-45C3-806D-46E0EAE03CE1`) works for local dev. **Not a shipping target** — `CLAUDE.md` still pins Android-only for release; iOS is purely local-dev convenience, and several iOS-only build fixes this session exist solely to keep that convenience working (see PR #30 and #32's commit history for two separate `google_mobile_ads`-related iOS build breakages and their fixes — both real, both non-obvious, worth reading before touching `ios/Podfile` again).
- **`flutter test`**: needed a one-time native-library setup that had never been run — `dart run rive_native:setup --verbose --clean --platform macos`. Without it, any widget test touching `ChibiStageView` fails with a Rive FFI dylib-not-found error. Also found (and fixed, PR #32) a real bug this exposed: `ChibiStageView`'s entrance-animation controller was a lazy `late final` field, which crashed on `dispose()` if `_loadRive()` failed before the field was ever touched. Both are fixed now; `flutter test test/widget_test.dart` passes.
- Chrome is real on this machine (`flutter run -d chrome` works) — the old Edge-first workaround doesn't apply here.

## Where things stand

- **Merged into `feature/sprint-1-foundation`**: PR #26 (Rive stage + mic-to-quote loop, closed issues #5/#8/#9/#10/#11), PR #30 (fixed a corrupt `bg_flute_loop.ogg` → real `.mp3` audio for #6, fixed the speaking-pose-before-audio bug as #29, iOS local-dev enablement), PR #31 (welcome splash screen with bottom-to-top entrance + wave-hi greeting, quieter background music).
- **PR #32 — open, not merged.** This is the big one, still in flight: local voice quota (#16, SQLite via `sqflite`), AdMob banner + rewarded ads (#18, real ad unit IDs wired but gated to release-builds-only — debug always uses Google's test IDs), a banner/mic layout overlap fix, a simplified home screen (app bar removed, response bubble auto-fades), and — most recently — the real app icon + branded native splash generated from `assets/logo.jpg` (via `flutter_launcher_icons` / `flutter_native_splash`, both dev-only generators).
  - **Known gap, not yet exercised**: the full 10-turn quota exhaustion → Support sheet → watch-rewarded-ad → +5 turns flow has never been tested end-to-end. Neither the Android emulator nor iOS simulator produces usable real speech input, so this needs a manual pass on an actual device.
  - **Known cosmetic gap**: on Android 12+ specifically, the native splash screen's OS-enforced circular icon viewport clips the "KRISHNA A.I" text baked into the bottom of `assets/logo.jpg`. The home-screen *launcher* icon looks fine (verified on-device); only the cold-start splash icon clips. Fixable with a text-free, more-centered crop of just the character, if it's worth a follow-up.
- **Not yet done in MVP:** #7 (Hindi-first chrome/English toggle/About).
- **Two small tracked follow-ups, not blocking:** #27 (CC BY attribution credit for the Rive character asset — still not added to the app) and #28 (V1-scoped: evaluate ElevenLabs vs on-device TTS, deferred out of MVP deliberately).
- Gemini (#13/FF-01) is **still not integrated** — deliberately. The quota/ads plumbing in #32 was built ahead of it on purpose, to de-risk that integration in isolation. Right now every response (whether "normal" or "downgraded after declining an ad") is the same local Gita-quote picker.
- Full technical narrative of the Rive integration: `progress/mvp-02-rive-mic-loop.md`.

## The one thing most likely to trip up a fresh session

The character rig (`assets/rive/chibi_krishna.riv`) is **not** what the original spec docs (`docs/requirements/assets_v3.md` §4, `PRD_v3.md`'s first draft of §10) describe. Those were written speculatively, before any real `.riv` existed, assuming legacy Rive state-machine number/trigger inputs (`pose`, `jawOpen`, `blessBurst`). The asset actually in the repo is a **Rive marketplace character (KrishnaJI, CC BY 4.0)** that uses **Data Binding** — a ViewModel with three enum properties (`poses`, `emotion`, `eye`) — a different mechanism entirely. See `docs/krishna_rive_integration_summary.md` for the third-party doc that cracked it, and `docs/requirements/assets_v3.md` §4a for the verified real contract. **§4a is correct; §4 above it is historical.** `lib/features/stage/presentation/widgets/chibi_stage_view.dart` is the reference implementation — it now also owns a one-time bottom-to-top entrance animation and a `greeting` (wave) pose used by the splash sequence in `main.dart`.

Also worth knowing: `rive: 0.13.x` (the version this project started with) is that package's **abandoned legacy runtime** — it couldn't render this asset at all. The project is on `rive: ^0.14.11` now. Don't downgrade it.

## Legal / Play Store compliance — next session, start here

Not started yet. This is genuinely separate from feature work — it's account setup, policy documents, and Play Console form-filling, most of which needs the user's own decisions/accounts, not just code. Rough checklist, roughly in the order it'll actually block you:

1. **Google Play Developer account** — one-time $25 registration if not already done, plus Google's developer identity verification (has gotten stricter; may require ID/organization documents — check current requirements when you get there, this changes over time).
2. **Privacy policy** (hard requirement — Play won't let you publish without a public URL for it). Must disclose, honestly, everything this app actually does once V1 ships: microphone access (STT, on-device/OS-level per current MVP — revisit if that changes), AdMob (banner + rewarded, uses Advertising ID), Firebase Analytics (anonymous event counters only — `CLAUDE.md`/PRD are explicit that no PII, transcript text, or raw audio ever goes to analytics), Gemini (once #13 lands — transcript text leaves the device to Google's API), local SQLite (quota/streak — stays on-device, not shared). Issue #24 (FF-12) tracks "write the actual policy"; this handoff section is the checklist behind it.
3. **Play Console "Data Safety" form** — must match the privacy policy exactly, item by item (mic, ads, analytics, network destinations). Google audits for mismatches between what you declare and what the app's traffic actually does, so this needs to be accurate, not aspirational.
4. **Advertising ID (AD_ID) declaration** — required because `google_mobile_ads` is integrated (already in the app as of PR #32). Declared in Play Console's App Content section at submission time, not in code.
5. **Target audience & content section** — must reflect the locked positioning: **13+ / devotees / parents**, explicitly **not** "Designed for Families" (`CLAUDE.md`'s locked decision — Play Families has stricter ad/data rules this app doesn't meet, and the product isn't marketed as for-kids even though children-with-a-parent is an allowed usage).
6. **Content rating questionnaire (IARC)** — has to be answered honestly at submission time; nothing to pre-decide now, just budget time for it. Relevant facts for whoever fills it out: no user-generated content, no violence, contains ads, no in-app purchases (locked decision — no IAP, ever, per PRD §7), religious/spiritual character content.
7. **"Contains ads" / "No in-app purchases" declarations** — straightforward given the above, just don't forget them.
8. **CC BY 4.0 attribution for the Rive character asset** — issue #27, still open. Worth doing *before* store submission, since attribution should arguably be visible in-app (About screen, once #7 exists) and is a licensing obligation regardless of Play policy.
9. **GDPR/UK consent (Google's UMP SDK)** — only needed if targeting EU/UK/EEA users with personalized ads. Not decided yet — given the Hindi-first, India-leaning positioning, may not be urgent, but is a real open call the user should make, not something to assume either way.
10. **Terms of Service** — not a hard Play requirement, but worth having given the crisis-safety framing (PRD §9: this is an AI avatar, not a therapist/guru, with a mandatory on-screen safety strip once V1's crisis handling ships). A short ToS/disclaimer reduces liability exposure around that.
11. **Store listing assets** — app icon (done, see PR #32 — `assets/logo.jpg`/`.png` sourced), feature graphic 1024×500, screenshots, short/long description, category, contact email. None of this exists yet.

None of this blocks continued feature work — Gemini (#13), the crisis strip (#15), or anything else in the V1 milestone can proceed in parallel. It's listed here so it doesn't get forgotten until the week before someone tries to actually submit.

## Quick orientation for new work

1. `CLAUDE.md` — always read first, points at the rest.
2. `docs/Chibi_Krishna_AI_PRD_v3.md` — the build spec.
3. `gh issue list --state open --json number,title,milestone,labels` and `gh api repos/Vageshwar/chibi-krishna/milestones` — live scope, not the markdown issue docs.
4. `docs/requirements/assets_v3.md` §4a — the real Rive contract, if touching the character.
5. `progress/*.md` — narrative history of what was tried, what broke, and how it got fixed, per piece of work. Useful before re-deriving something that's already been figured out.
6. `gh pr list --state open` — check PR #32's actual status before assuming it's still open; this file will be stale the moment it merges.

This file itself will go stale — it's a snapshot, not a living doc. Trust the live GitHub state and the code over anything time-bound written here.
