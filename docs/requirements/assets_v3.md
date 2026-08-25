# Chibi Krishna AI — art/rig spec v3 (Rive character + flat backgrounds)

Supersedes the character portion of `docs/requirements/assets.md` (v2), which specified 4 flat full-body PNG poses. **Backgrounds are unchanged** — still flat PNGs, see §3 below, sourced straight from the v2 file. Only the **character** moves from "4 painted poses" to "one rigged Rive artboard."

Confirm current Rive editor pricing/feature gating at [rive.app/pricing](https://rive.app/pricing) before committing — the runtime (`rive` Flutter package) is MIT-licensed and free regardless of editor plan; this note is only about the desktop/web editor tier, which may change.

---

## 0. Current asset in use (supersedes §1–2's commissioning spec for now)

`assets/rive/chibi_krishna.riv` is **not** a custom commission — it's the [KrishnaJI asset](https://rive.app/marketplace/27686-52286-krishnaji/) from the Rive marketplace, by creator `ar.akash`, **license CC BY 4.0** (commercial use OK, **attribution required** — add a credit line in the app's About screen before shipping; not yet done).

It uses Rive **Data Binding** (a ViewModel), not the legacy state-machine number/trigger inputs §4 originally speculated before this asset was found and inspected. See §4a for the real, verified contract. §1–2's rigging/commissioning guidance stays as reference for if custom art ever replaces this asset, but it doesn't describe what's actually in the repo right now.

---

## 1. Why a rig instead of 4 poses

A rig lets one artboard **blend** between states (idle → listening is a smooth head-tilt, not a jump-cut) and gives a genuinely alive idle state (breathing, randomized blink, flute sway) with zero ongoing Dart code to drive it. It also decouples art iteration from app builds: once the state-machine input names below are fixed, an artist/rigger can improve the rig in the free Rive editor and re-export the `.riv` file with no Flutter code changes.

## 2. Master file and layers

- Canvas/artboard: **1080 × 1920** (9:16), same baseline as v2.
- Krishna roughly **~900px tall**, centered, feet on a stable baseline (matches where the background foreground-grass layer expects the character to stand).
- Deliver as a layered source file the rigger can bone/mesh (Figma, Illustrator, or Rive's own vector tools — **not** a flattened PSD with 4 painted faces; those cannot be rigged).
- Minimum separate layers/parts needed for rigging:
  - Head (with separate **eyelid** shapes for blink — top lid at minimum)
  - **Lower jaw / mouth** as its own part (a bone-driven jaw, or a small mesh that can be deformed/blended between closed/open) — this is what `jawOpen` drives
  - Torso
  - Upper arm + forearm, **both sides** (needed for: flute-holding idle pose, ear-cupped listening gesture, raised-hand blessing gesture)
  - Flute prop (attached to hand bone so it moves naturally with the arm)
  - Optional: simple particle/aura shape for the blessing burst (can be authored directly in Rive rather than delivered as art)
- Character parts: **transparent background** (PNG/SVG import into Rive). No painted-on shadows that assume a fixed pose — the rig will move the parts.

## 3. Background (unchanged from v2 — flat PNGs, no rig)

| File | Purpose | Transparent? |
| :--- | :--- | :--- |
| `bg_sky_day.png` | 9:16 far sky/hills, no character | No |
| `bg_mid_trees_day.png` | Mid trees/river bank, parallax | Yes |
| `bg_fore_grass_day.png` | Foreground grass/flowers | Yes |

Composited in Flutter as a `Stack` beneath the Rive artboard, same ken-burns/parallax treatment as v2. Nice-to-have: dusk parallax trio, unchanged from v2, still backlog.

## 4. Rive state machine contract (speculative — superseded by §4a for the asset actually in the repo)

The plan below was written before any real `.riv` existed, assuming legacy state-machine number/trigger inputs. Kept for historical reference and as the target shape if a custom rig is ever commissioned to replace the marketplace asset. **Do not implement against this — implement against §4a.**

| Input | Type | Driven by | Purpose |
| :--- | :--- | :--- | :--- |
| `pose` | Number | `StageCubit.animationState` (0=idle, 1=listening, 2=thinking, 3=speaking, 4=blessing) | Selects/blends the state layer |
| `jawOpen` | Number, 0.0–1.0 | TTS/STT amplitude envelope, pushed every frame during listening/speaking | Drives the jaw bone rotation or mouth mesh blend |
| `blessBurst` | Trigger | Fired once on entering pose 4 | Plays the aura/particle animation |

States envisioned: Idle (breathing/blink loop), Listening (head tilt), Thinking (chin/far-look), Speaking (`jawOpen`-driven mouth), Blessing (raised-hand gesture + `blessBurst` aura).

## 4a. Real contract — `assets/rive/chibi_krishna.riv` (KrishnaJI), verified live

This asset uses **Rive Data Binding**, not the number/trigger inputs above. Artboard `krishna_ai_teacher_master`, state machine `KrishnaJI_SM`, a **ViewModel** with three enum properties — all verified by actually loading the file and mutating each value at runtime (not just read from docs):

| Property | Enum type | Values | Notes |
| :--- | :--- | :--- | :--- |
| `poses` | `posesEnum` | `Yesss`, `idle_lookaround`, `is_waving`, `talk_visemes`, `is_Denial`, `is_Acceptance`, `Idle` | `talk_visemes` is a **self-contained talking animation** — set once, not driven per-frame like the old `jawOpen` plan |
| `emotion` | `emotion_state` | `Exhalation`, `Thniking` *(sic — typo baked into the .riv itself, must be matched exactly)*, `Happy01`, `Happy02`, `Happy03`, `Sad`, `Opps01`, `Opps02`, `Neutral01`, `Neutral02`, `Aaaaah`, `Odd`, `Crying`, `Oh No` | |
| `eye` | `eye_type` | `close`, `open_big`, `open_small` | |

Bind with `controller.dataBind(rive.DataBind.auto())` (returns a `ViewModelInstance`), then `vmi.enumerator('poses')` etc. — each returns a `ViewModelInstanceEnum` whose `.value` is a **String** matching one of the values above (not a numeric index). Full working reference: `lib/features/stage/presentation/widgets/chibi_stage_view.dart`.

**Current `ChibiAnimationState` → property mapping** (in code, `_applyState` in that file):

| App state | `poses` | `emotion` | `eye` |
| :--- | :--- | :--- | :--- |
| idle | `Idle` | `Happy01` | `open_big` |
| listening | `idle_lookaround` | `Happy01` | `open_big` |
| thinking | `Idle` | `Thniking` | `open_small` |
| speaking | `talk_visemes` | `Happy01` | `open_big` |
| blessing | `Yesss` | `Happy03` | `open_big` |

There's also a second, separate `Confetti` artboard (one animation, `celebrating 2`) in the same file — not yet wired to anything; a natural fit for the blessing state's aura burst, as its own `RiveWidgetController` shown briefly on top rather than nested in the character's state machine. Not implemented yet (V1/FF-02 scope, blessing isn't exercised in the MVP).

A `FlutterError.onError` guard in `chibi_stage_view.dart` catches any Rive-originated paint exception once and falls back to a plain gradient background rather than repainting a broken frame forever — currently inert (this asset renders cleanly under `rive: ^0.14.11`), kept in case a future file revision trips something.

## 5. Placeholder-first delivery (Sprint 1) — superseded, real asset now in use

This section described the plan before the KrishnaJI marketplace asset (§0) was found — kept for reference only, since it's no longer the active path.

Before final art exists, ship a **trivial placeholder `.riv`**: any simple shape (a circle/blob is fine) with the same `ChibiSM` state machine and the three inputs above wired up, even if the "animation" is just a color or scale change per state. This lets Sprint 1 build and test the full `StageCubit` → `RiveAnimation`/`StateMachineController` plumbing without blocking on final character art, exactly mirroring how v2 used colored-rectangle PNG placeholders. Swapping the final rig in later is an asset replacement (same file name, same state machine contract), not a code change.

## 6. Reducing rigging effort (optional accelerants)

- Rive's own tutorials include a full "rig a character" walkthrough (bones, meshes, blend states) aimed at exactly this kind of 2D companion character — worth doing once before starting the real rig.
- The Rive community/marketplace has free example character rigs; adapting an existing bone structure (reskinning with Krishna art, rather than rigging from scratch) can cut rigging time significantly if the proportions are close enough. Re-skinning is still real work, not zero-effort, but it avoids solving bone hierarchy and blend states from a blank canvas.

## 7. Other assets (unchanged from v2)

| File | Purpose |
| :--- | :--- |
| `app_icon_1024.png` | Play/launcher 1024², optional alpha |
| Play feature graphic 1024×500 + 2–4 screenshots | Nice-to-have, needed before store submission (Sprint 4) |

No "makhan offering" art — Support/Invite are UI chrome, never in-character transactions.
