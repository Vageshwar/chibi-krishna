# Chibi Krishna AI

Solo-dev Android app: a full-screen 2D **Rive**-rigged chibi Krishna companion, voice-and-text, Gita-themed wisdom in Hindi/English. Flutter + Bloc, no backend, budget-conscious.

## Before writing or deciding anything

0. **If this is a fresh session (new machine, new environment, or picking up after a gap), read `docs/HANDOFF.md` first.** It's a point-in-time snapshot (open PRs, what's mid-flight, environment gotchas from whichever machine wrote it) — useful context, but treat it as a snapshot, not a standing rule like the items below.
1. **Read `docs/Chibi_Krishna_AI_PRD_v3.md`** — the current build spec. `Chibi_Krishna_AI_PRD.md` (v1, 3D/Deepgram/Cartesia) and `_PRD_v2.md` are historical; do not design or code from them.
2. **Check live GitHub state before assuming scope**: `gh issue list --state open --json number,title,milestone,labels` and `gh api repos/Vageshwar/chibi-krishna/milestones`. GitHub Issues/Milestones are the operational tracker. `docs/Chibi_Krishna_AI_GitHub_Issues_v3.md` is the rationale/detail bank behind them, not the live source of truth — and the v1/v2 issue docs are historical, same as the PRDs. If asked to add or change scope, reflect it in the live GitHub issues (via `gh`), not only in a doc.
3. **Diff docs against actual code before trusting a doc's claim about current state.** This repo's docs and code have drifted before: PRD v2 and v3 both said "remove the Filament/SceneView 3D stub," but `lib/features/stage/presentation/widgets/chibi_stage_view.dart` and `pubspec.yaml` still had it as of the last check. Read the relevant files yourself.

## Two milestones — do not blend them

- **MVP — Alive Krishna, No AI Yet** (issues #4–#12): Rive idle/speaking liveliness + working mic capture + a local random-quote responder. **No Gemini, no `.env` API key, no network call in the response path, no quota system.** Before adding a Gemini call, a quota check, or an ads/referral/notification feature, confirm the corresponding Fast-Follow issue is actually the one being worked — those inputs don't exist yet in MVP scope.
- **V1 — Real Oracle & Growth** (issues #13–#24): replaces canned quotes with Gemini, adds the crisis strip, quota, the full 5-state Rive rig, daily card, AdMob, referral, notifications, analytics, Play listing.

## Locked product decisions

Full rationale for all of these: `docs/Chibi_Krishna_AI_Design_Findings.md`. Treat them as fixed unless the user explicitly reopens one.

- **No 3D.** No Filament/SceneView/GLTF, no Deepgram/Cartesia/ElevenLabs. The character is a **Rive** 2D rig (`rive: ^0.14.x` — the `0.13.x` line is a dead legacy runtime, do not use it), not flat pose-swap PNGs. It's a marketplace asset (KrishnaJI, CC BY 4.0, attribution required) driven by **Data Binding** (ViewModel enums), not legacy state-machine inputs — full verified contract in `docs/requirements/assets_v3.md` §4a, don't assume the shape without reading it first.
- **No backend.** Quota, streak, and local counters live in on-device SQLite. `firebase_analytics` and `google_mobile_ads` are the only network-facing exceptions — passive SDKs, not servers we run.
- **AdMob, not AdSense.** AdSense is the web product; never add AdSense tags to the Android app.
- **13+ / devotees / parents store positioning, not Google Play Families**, even though children-with-a-parent are an allowed *usage*. No "for kids" language in-app or in store copy.
- **Krishna never asks for money in-character.** Support/dakshina/Invite copy is always publisher-voiced ("Support Chibi Krishna AI"), never "Krishna received your offering."
- **Hindi and English only**, no third language. Default STT locale `hi-IN`.
- **Crisis safety strip is non-negotiable** once real AI responses exist (V1 milestone) — persistent, never a dismissible snackbar, helpline numbers marked "confirm at ship" rather than hardcoded from memory.

## Flutter conventions in this repo

- State management is `flutter_bloc` **Cubit**, not Provider/Riverpod/GetX. State classes extend `Equatable` with `copyWith` — follow the shape already in `lib/features/stage/presentation/cubit/`.
- Structure: `lib/features/<feature>/presentation/{cubit,widgets}/`; cross-cutting services (audio, etc.) go in `lib/core/services/`. New features get their own `lib/features/<name>/` folder, matching `stage/`.
- Secrets go in `.env` via `flutter_dotenv`, never hardcoded, and `.env` must stay in `.gitignore`.
- Ambient failures degrade silently: a missing optional asset or `.env` should `debugPrint` and continue, not crash — see `dotenv.load` in `main.dart` and `BackgroundAudioService.initialize()` for the existing pattern to match.
