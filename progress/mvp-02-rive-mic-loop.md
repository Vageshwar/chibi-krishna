# MVP-02 — Rive stage + mic → quote → TTS loop

**GitHub issues:** [#5](https://github.com/Vageshwar/chibi-krishna/issues/5) (Rive stage), [#8](https://github.com/Vageshwar/chibi-krishna/issues/8) (mic capture), [#9](https://github.com/Vageshwar/chibi-krishna/issues/9) (quote engine), [#10](https://github.com/Vageshwar/chibi-krishna/issues/10) (TTS + mouth-flap), [#11](https://github.com/Vageshwar/chibi-krishna/issues/11) (orchestrator) — all in the **MVP — Alive Krishna, No AI Yet** milestone.
**Branch:** `mvp-02-rive-mic-loop`
**Status:** Implemented and verified running on Edge (web), **character now actually renders**, awaiting review

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

## What the `.riv` file actually contains, and the rendering fix (both confirmed by running the app)

A `flutter_test`-based introspection attempt (loading the file via `RiveFile.import` inside a test targeting Edge, since Chrome isn't installed on this machine) hung and timed out after 12 minutes launching the browser under the test runner — abandoned in favor of just running the real app, which answered everything directly.

**Initial finding:** the file has a state machine named **`KrishnaJI_SM`** (zero inputs — a bare shell) and **26 animation clips already built** (idle variants, blink, talking mouth, wave, thinking, accept/deny/yes, sad/crying/oh-no/odd/ouch, happy/neutral variants, oops, exhale) plus a bonus `Confetti` particle artboard — much richer than "basic" implied. The user separately uploaded 16 more `.riv` files expecting per-mood exports; all 16 turned out to be **byte-for-byte identical** to `chibi_krishna.riv` (same MD5) since Rive always exports the whole project, not a single clip — deleted as pure duplicates, no content lost.

**The rendering blocker (now fixed):** the artwork threw `RangeError (index): Index out of range: index should be less than 2: 2` from deep inside `rive: ^0.13.20`'s `Fill.draw()` — a paint-time error, so it didn't surface through `try/catch`, and unhandled it repeated on **every single frame** (1535 times in ~30s in one run). Root cause: `rive: 0.13.20` is that package's now-abandoned **legacy runtime** (confirmed via its own README) — the file was built with a current Rive editor and needs the actively-maintained runtime.

**Fix:** migrated to `rive: ^0.14.11` (the current `rive_native`-backed runtime, entirely different API — `File`/`RiveWidgetController`/`NumberInput`/`TriggerInput`/`RiveWidget` replace the old `RiveFile`/`StateMachineController`/`SMINumber`/`SMITrigger`/`Rive` classes). Verified live end-to-end:
- A standalone smoke test against `Factory.flutter` rendering loaded and painted the artboard with **zero errors**.
- The full migrated `chibi_stage_view.dart`, run in the real app, found the artboard and state machine, and **the render-error guard never fired** — checked output stayed stable over repeated polls, no crash, no fallback needed.
- The `pose`/`jawOpen`/`blessBurst` input-lookup logic carried over almost 1:1 to the new API (`stateMachine.inputs`, `NumberInput.value`, `TriggerInput.fire()`), so the contract in the table above is unchanged.

The `FlutterError.onError` guard is kept in the code as a safety net for whatever the *next* file revision might trip, but it's not currently doing anything — rendering is clean.

**Still true:** the state machine has zero inputs, so the character won't visibly react to app state yet — see the Required Rive states table above. That's now the only remaining blocker to a fully "alive" character, and it's pure Rive-editor work (add 3 inputs), not a code problem.

- **Not yet verified on Android** — this dev machine's Android toolchain has unresolved `cmdline-tools`/license gaps (see `CLAUDE.md`); testing happens via USB debugging separately.
- Language selection for responses currently follows whichever STT locale actually got used (`SpeechService.isHindiLocale`) rather than a manual UI toggle — full Hindi-first chrome/toggle is MVP-04 (`#7`), not yet built. In this dev environment Edge's speech recognition didn't offer Hindi, so it fell back to `en_US` — expected per the documented fallback behavior, not a bug.

## Verification performed

- [x] `flutter analyze` — clean.
- [x] `flutter build web` — builds clean with `rive: ^0.14.11`.
- [x] `flutter run -d edge` — app launches, mic/speech service initializes, Rive artboard and state machine found, **no render errors**, verified stable over multiple polls.
- [ ] Full manual click-through of the mic → quote → TTS loop (permission prompt → speak → hear response) — not done interactively in this sandboxed environment; recommend the reviewer click through this by hand.
- [ ] Visual confirmation that the character actually *looks* right (correct proportions/colors/no missing shapes) — I can confirm it paints without crashing, not what it looks like; reviewer should eyeball it.
