# MVP-01 — Remove SceneView / Filament / GLB 3D stub

**GitHub issue:** [#4](https://github.com/Vageshwar/chibi-krishna/issues/4) (milestone: MVP — Alive Krishna, No AI Yet)
**Branch:** `mvp-01-remove-3d-stub`
**Status:** Done, awaiting review

## What changed

- Removed `sceneview_flutter` from `pubspec.yaml` and its only usage (`SceneViewController`/`SceneView` in `ChibiStageView`).
- Removed `assets/models/chibi_krishna.glb` from `pubspec.yaml`'s asset list and deleted the file itself (1.5KB stub, not real art) — the app no longer requires or references any GLB model.
- Rewrote `lib/features/stage/presentation/widgets/chibi_stage_view.dart`: dropped the debug "Mouth Morph Shape (JawOpen)" HUD card and the gold `AnimatedBuilder` aura gradient. It's now a minimal placeholder — a calm gradient background with a state label — that still reads `StageCubit`/`StageState` reactively. This is intentionally throwaway: MVP-02 (Rive rig, blocked on the `.riv` file) replaces it, and nothing else should need to change when that happens since the `StageCubit` contract (`animationState`, `jawOpen`) is untouched.

## Side fixes needed to verify this actually works

- `pubspec.yaml`'s `environment.sdk` was `^3.10.4`, newer than the installed Flutter's Dart (3.9.2 on Flutter 3.35.3) — `flutter pub get` failed outright before any of the above. Lowered to `^3.9.2` to match the installed toolchain (per user decision — the alternative was upgrading Flutter, deferred).
- Project had no web platform scaffolding (`flutter build web` failed with "not configured for the web"). Ran `flutter create . --platforms web` to add it, since Chrome is the agreed day-to-day dev target for this machine (memory: `dev_workflow_chrome_first`) — physical Android device via USB debugging is used for Android-specific checks (mic/TTS/permissions) later in the MVP sequence.

## Verification

- [x] `flutter analyze` — no issues.
- [x] `flutter build web` — builds clean.
- [ ] Not yet run on an Android device/emulator (Android toolchain on this machine still has unresolved `cmdline-tools`/license issues per `flutter doctor` — not addressed in this issue, will matter once Android-specific MVP work starts).

## Next up

MVP-04 (`#7`, Hindi-first chrome/English toggle/About) is next in the agreed sequence, unless review here changes something. MVP-02 (`#5`, Rive rig) stays blocked until the placeholder `.riv` exists.
