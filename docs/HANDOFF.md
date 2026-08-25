# Handoff — read this first if you're picking up fresh

Written 2026-08-25, at the point the user is moving development from a Windows machine to a MacBook Air. If you're a new session (new machine, new Claude Code session, or both), start here — then follow `CLAUDE.md`'s own "before writing or deciding anything" checklist for the live PRD/GitHub state.

## Environment: don't trust the old machine's findings

Everything discovered on the Windows dev machine this session is **specific to that machine**, not to the project:

- Chrome wasn't installed there (only Edge) — dev iteration used `flutter run -d edge`.
- The Android toolchain had unresolved `cmdline-tools`/license gaps — Android testing happened via a physical device over USB, not an emulator.
- A memory file (`dev_workflow_chrome_first`) captured this, but memory is local to that machine's Claude Code install — it will not carry over to a new machine and shouldn't be assumed to apply there.

**On a fresh machine (e.g. the MacBook Air): run `flutter doctor` and `flutter devices` yourself before assuming anything about what's available.** macOS typically has real Chrome and can run both an iOS simulator and an Android emulator properly, which may remove the workarounds used so far — don't carry them forward out of habit.

## Where things stand

- **PR #26** (`mvp-02-rive-mic-loop` → `feature/sprint-1-foundation`) is **open, not merged**. It bundles what was originally issues #5, #8, #9, #10, #11 (Rive stage, mic capture, quote engine, TTS, orchestrator) — all in the **MVP — Alive Krishna, No AI Yet** milestone. Those issues will auto-close when the PR merges; until then, GitHub will still show them as open even though the work is done and pushed.
- Also open in that same PR: live captions + a mic-level equalizer while listening, on-device TTS voice discovery (logs available voices, prefers higher-quality ones by name pattern), and a tap-to-react flourish (random warm animation when Krishna is tapped while idle).
- **Not yet done in MVP:** #6 (flute loop/ducking — likely already functional from Sprint 1's `BackgroundAudioService`, just not explicitly verified/closed as its own piece of work), #7 (Hindi-first chrome/English toggle/About), #12 (internal smoke-test build).
- **Two small tracked follow-ups, not blocking:** #27 (CC BY attribution credit for the Rive character asset — not yet added to the app) and #28 (V1-scoped: evaluate ElevenLabs vs on-device TTS, deferred out of MVP deliberately).
- Full technical narrative of how the Rive integration actually came together (including two real bugs found and fixed): `progress/mvp-02-rive-mic-loop.md`.

## The one thing most likely to trip up a fresh session

The character rig (`assets/rive/chibi_krishna.riv`) is **not** what the original spec docs (`docs/requirements/assets_v3.md` §4, `PRD_v3.md`'s first draft of §10) describe. Those were written speculatively, before any real `.riv` existed, assuming legacy Rive state-machine number/trigger inputs (`pose`, `jawOpen`, `blessBurst`). The asset actually in the repo is a **Rive marketplace character (KrishnaJI, CC BY 4.0)** that uses **Data Binding** — a ViewModel with three enum properties (`poses`, `emotion`, `eye`) — a different mechanism entirely. This was found the hard way (see `docs/krishna_rive_integration_summary.md` for the third-party doc that cracked it, and `docs/requirements/assets_v3.md` §4a for the verified real contract). **§4a is correct; §4 above it is historical.** `lib/features/stage/presentation/widgets/chibi_stage_view.dart` is the reference implementation.

Also worth knowing: `rive: 0.13.x` (the version this project started with) is that package's **abandoned legacy runtime** — it couldn't render this asset at all (crashed every frame). The project is on `rive: ^0.14.11` now, a completely different API. Don't downgrade it.

## Quick orientation for new work

1. `CLAUDE.md` — always read first, points at the rest.
2. `docs/Chibi_Krishna_AI_PRD_v3.md` — the build spec.
3. `gh issue list --state open --json number,title,milestone,labels` and `gh api repos/Vageshwar/chibi-krishna/milestones` — live scope, not the markdown issue docs.
4. `docs/requirements/assets_v3.md` §4a — the real Rive contract, if touching the character.
5. `progress/*.md` — narrative history of what was tried, what broke, and how it got fixed, per piece of work. Useful before re-deriving something that's already been figured out.

This file itself will go stale — it's a snapshot, not a living doc. If you're reading it long after 2026-08-25, trust the live GitHub state and the code over anything time-bound written here.
