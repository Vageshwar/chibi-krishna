# MVP-02 — Rive stage + mic → quote → TTS loop

**GitHub issues:** [#5](https://github.com/Vageshwar/chibi-krishna/issues/5) (Rive stage), [#8](https://github.com/Vageshwar/chibi-krishna/issues/8) (mic capture), [#9](https://github.com/Vageshwar/chibi-krishna/issues/9) (quote engine), [#10](https://github.com/Vageshwar/chibi-krishna/issues/10) (TTS + mouth-flap), [#11](https://github.com/Vageshwar/chibi-krishna/issues/11) (orchestrator) — all in the **MVP — Alive Krishna, No AI Yet** milestone.
**Branch:** `mvp-02-rive-mic-loop`
**Status:** Implemented and verified running on Edge (web), awaiting review

## What changed

- **Rive integration** (`lib/features/stage/presentation/widgets/chibi_stage_view.dart`): loads the user-provided `assets/rive/chibi_krishna.riv` and renders it adaptively — wires `pose`/`jawOpen`/`blessBurst` state-machine inputs if present, falls back to looping the first plain animation if there's no state machine yet, falls back to static art if there's neither. Logs what it actually found via `debugPrint` on load. This was intentionally defensive because the file is "basic" and its real contents couldn't be confirmed by tooling (see Known gaps below).
- **Mic capture** (`lib/features/oracle/data/speech_service.dart`): wraps `speech_to_text`, defaults to `hi_IN`, falls back to `en_IN`/`en_US`/system locale. Exposes `isHindiLocale` so the response language follows what was actually recognized.
- **Quote engine** (`lib/features/oracle/data/quote_repository.dart` + `assets/gita/mvp_quotes.json`): 20 original Gita-flavored quotes (hi/en), random pick that never immediately repeats. No network, no cost.
- **TTS + mouth-flap** (`lib/features/oracle/data/tts_service.dart`): wraps `flutter_tts`, drives a timed random envelope into `jawOpen` while speaking (device TTS doesn't expose real amplitude/viseme data).
- **Orchestrator** (`lib/features/oracle/presentation/cubit/conversation_cubit.dart`): `idle → listening → thinking → speaking → idle`. Two consecutive empty transcripts, or mic permission denied, flips to a text-input fallback. No Gemini, no quota — matches MVP milestone scope.
- **`lib/main.dart`**: real mic button with a glow overlay while listening, a response-text card, the text fallback field. Removed the old debug pose-testing button bar.
- Added `listening` to `ChibiAnimationState` (`stage_state.dart`) — the enum only had idle/thinking/speaking/blessing before.
- Added `RECORD_AUDIO`/`INTERNET` to the Android manifest for future device testing.

## Required Rive states (for the user to build out in the Rive editor)

State machine name **`ChibiSM`** (any name works — the code binds to the artboard's first state machine, `ChibiSM` just matches `docs/requirements/assets_v3.md`). Inputs:

| Input | Type | Values | Needed for MVP? |
| :--- | :--- | :--- | :--- |
| `pose` | Number | 0 idle, 1 listening, 2 thinking, 3 speaking, 4 blessing | Only 0 and 3 are exercised today |
| `jawOpen` | Number | 0.0–1.0, updated ~every 90ms while speaking | Yes |
| `blessBurst` | Trigger | fires once entering pose 4 | Not yet (V1 milestone) |

Until a state machine with at least `pose` exists, the app loops whatever plain animation is first in the file (or shows it static) rather than reacting to app state.

## What the `.riv` file actually contains (confirmed by running the app)

A `flutter_test`-based introspection attempt (loading the file via `RiveFile.import` inside a test targeting Edge, since Chrome isn't installed on this machine) hung and timed out after 12 minutes launching the browser under the test runner — abandoned. Running the real app instead answered it directly:

- The file **does** have a state machine, named **`KrishnaJI_SM`** — but it currently has **zero inputs** (`Inputs present: ` came back empty). It's a bare shell, matching "basic" — see the Required Rive states table above for what to add.
- **The artwork itself throws a rendering exception**: `RangeError (index): Index out of range: index should be less than 2: 2` from deep inside `rive`'s `Fill.draw()` (`package:rive/src/rive_core/shapes/paint/fill.dart`). This is a paint-time error, not a load-time one, so it doesn't surface through a normal `try/catch` — and left unhandled it **repeated on every single frame** (1535 times in ~30 seconds in one test run), which would have hammered performance and flooded logs on a real device.
  - Most likely cause: the `.riv` was exported by a newer Rive editor version than the `rive: ^0.13.20` Flutter package supports (some fill/shape type the file references isn't recognized by this runtime). Tried upgrading to `rive: ^0.14.11` to check — that turned out to be a full runtime rewrite (entirely different API: `RiveFile`/`StateMachineController`/`SMINumber`/`Rive` widget don't exist in that line at all, replaced by a new `rive_native`-backed API), too large a migration to take on inside this PR. Reverted to `^0.13.20`.
  - **Fix applied**: `chibi_stage_view.dart` now installs a `FlutterError.onError` guard that detects a Rive-originated paint exception once, logs a clear diagnostic, and falls back to the plain gradient background instead of repainting a broken artboard forever. Verified live: the crash now fires **exactly once**, then the app stabilizes with no further errors.
  - **Not fixed**: the underlying rendering incompatibility itself. The character currently won't visually render via this package version with this file. Options going forward (for whoever picks this up next): (a) re-export the `.riv` from the Rive editor targeting an older runtime version if the editor offers that setting, (b) simplify whatever shape/fill is triggering it, or (c) do the real `rive` 0.14.x migration as its own follow-up issue.
- **Not yet verified on Android** — this dev machine's Android toolchain has unresolved `cmdline-tools`/license gaps (see `CLAUDE.md`); testing happens via USB debugging separately.
- Language selection for responses currently follows whichever STT locale actually got used (`SpeechService.isHindiLocale`) rather than a manual UI toggle — full Hindi-first chrome/toggle is MVP-04 (`#7`), not yet built. In this dev environment Edge's speech recognition didn't offer Hindi, so it fell back to `en_US` — expected per the documented fallback behavior, not a bug.

## Verification performed

- [x] `flutter analyze` — clean.
- [x] `flutter build web` — builds clean with the new dependencies.
- [x] `flutter run -d edge` — app launches, mic/speech service initializes, Rive loads and its state machine is found and logged, the render-error guard was confirmed live (fires once, then stable — checked line count held steady after the fallback kicked in).
- [ ] Full manual click-through of the mic → quote → TTS loop (permission prompt → speak → hear response) — not done interactively in this sandboxed environment; recommend the reviewer click through this by hand.
