# Chibi Krishna AI — GitHub issues v2 (solo, budget)

**Build target:** `docs/Chibi_Krishna_AI_PRD_v2.md`  
**Why the old issues are wrong:** `docs/Chibi_Krishna_AI_GitHub_Issues.md` (v1) assumes Filament, GLB, Deepgram, Cartesia, Play Billing. **Do not execute v1 issues.**  
**Art:** `docs/requirements/assets.md`  
**Findings:** `docs/Chibi_Krishna_AI_Design_Findings.md`

Do not open these on GitHub with `gh` unless asked; this file **is** the issue spec.

---

## Sprint overview

```
Sprint 1  Foundation: drop 3D, image stage, placeholders, flute, hi/en chrome
Sprint 2  Oracle: STT → Gemini → TTS, language, quota SQLite
Sprint 3  Daily JSON card + crisis/safety UI + AdMob Support
Sprint 4  Polish, privacy, Play 13+ listing, internal testing
```

**V1.1 (not these sprints):** on-device share video.

**Dependency sketch:** Sprint 1 stage → Sprint 2 state machine uses poses. Sprint 3 ads/quota need Sprint 2 quota API. Sprint 4 needs a store-ready AAB.

---

## SPRINT 1 — Image stage and chrome

### Issue #1: `[SPRINT-1-01]` Remove SceneView / Filament and stop loading GLB

* **Labels:** `sprint-1`, `mobile`, `debt`
* **Dependencies:** none

**User story:** As a solo maintainer, I do not ship a broken 3D view or a missing `chibi_krishna.glb` crash.

**Tasks:**

1. Remove `sceneview_flutter` from `pubspec.yaml` and all Dart imports.
2. Stop listing `assets/models/chibi_krishna.glb` if the file is absent or unused; do not require it to launch.
3. Replace `ChibiStageView` SceneView with a placeholder `Stack` that still reacts to `StageCubit` states (`idle`, `thinking`, `speaking`, `blessing`).
4. Keep lip-sync **value** on the cubit; drive opacity/swap of placeholder mouth widgets instead of a 3D morph HUD labeled “JawOpen” (or hide that debug HUD behind `kDebugMode`).

**Acceptance:**

- [ ] `flutter run` on Android does not depend on a GLB or SceneView.
- [ ] Debug APK builds without Filament native failures tied to our stage.
- [ ] Animation state buttons (or equivalent) still switch visual state.

**Cursor prompt:**

```text
In this Flutter project, remove sceneview_flutter and any GLB/Filament stage. Replace ChibiStageView with a Flutter Stack image stage that reads StageCubit. Do not add 3D packages. App must launch without assets/models/chibi_krishna.glb.
```

---

### Issue #2: `[SPRINT-1-02]` Image stage layout (parallax + character + mouth)

* **Labels:** `sprint-1`, `ui`
* **Dependencies:** #1

**User story:** As a devotee, I see full-screen Krishna on nature, not a game HUD.

**Tasks:**

1. Layer: `bg_sky_day` → `bg_mid_trees_day` (slight horizontal/vertical parallax or ken-burns) → `bg_fore_grass_day` → character pose → mouth → eyes.
2. Use `assets/stage/` (or `assets/images/stage/`) paths matching `docs/requirements/assets.md` filenames.
3. Until final art arrives, use **clearly labeled placeholders** (solid colors + text “sky / trees / Krishna idle”) at 1080×1920 aspect, then drop in PNGs without layout rewrite.
4. Map cubit states: idle → `krishna_idle_flute`; listening (when added) → `krishna_listen`; thinking → `krishna_think`; speaking → idle or listen + mouth cycle; blessing → `krishna_bless` + optional aura placeholder.
5. Mouth: swap `mouth_closed|half|open` from `jawOpen` thresholds (e.g. <0.25 / <0.6 / else). Blink: occasional `eyes_blink`.
6. Character must not sit under a future banner: reserve **bottom safe inset** (~50–80 dp plus banner height constant).

**Acceptance:**

- [ ] 9:16 stage fills the screen; character feet on a stable baseline.
- [ ] Pose + mouth change without rebuilding navigation.
- [ ] Placeholders documented in README or `assets/stage/README.txt`.

**Cursor prompt:**

```text
Implement ChibiStageView as a Stack: three background layers, one character pose Image, mouth overlay, optional eyes. Bind pose to StageCubit.animationState and mouth to jawOpen. Leave bottom padding for an AdMob banner. Use asset paths from docs/requirements/assets.md. Placeholders OK.
```

---

### Issue #3: `[SPRINT-1-03]` Flute loop + ducking (keep / fix)

* **Labels:** `sprint-1`, `audio`
* **Dependencies:** none (#1 parallel)

**User story:** As a user, I hear soft bansuri that ducks when Krishna speaks.

**Tasks:**

1. Keep `just_audio` loop of `assets/audio/bg_flute_loop.ogg` (or a short royalty-free placeholder if missing — **license in comments**).
2. Duck ~0.60 → ~0.12 over ~300 ms when speaking.
3. If the ogg is missing, app still launches (log + silent fail), matching current service try/catch.

**Acceptance:**

- [ ] Loop does not click at seam if a proper loop file is present.
- [ ] Duck/unduck tied to speaking state, not only debug buttons.

---

### Issue #4: `[SPRINT-1-04]` Hindi-first chrome, English toggle, About caption

* **Labels:** `sprint-1`, `i18n`, `ui`
* **Dependencies:** #1

**User story:** As a Hindi-speaking devotee, chrome is Hindi until I pick English.

**Tasks:**

1. ARB or simple `AppLocalizations`: `hi` default, `en` toggle persisted (`shared_preferences`).
2. Strings: app title **Chibi Krishna AI**, Support, Type instead, remaining questions, About.
3. About / first-session caption: AI avatar, not a replacement for teachers/temple/clinicians (Hindi + English).
4. Remove debug-only gold bars from the **release** layout (keep behind a debug flag).

**Acceptance:**

- [ ] Cold start UI is Hindi if locale/toggle says so.
- [ ] Toggle switches chrome without restarting the process (or with a single rebuild).
- [ ] About states AI-avatar clearly.

---

## SPRINT 2 — Voice oracle

### Issue #5: `[SPRINT-2-01]` On-device STT (default hi-IN)

* **Labels:** `sprint-2`, `ai-stt`
* **Dependencies:** #2 (listen pose)

**Required:** Android mic permission in manifest + runtime prompt.

**Tasks:**

1. Integrate Android speech recognition (e.g. `speech_to_text`).
2. Default locale **`hi-IN`**; settings switch to **`en-IN`** (or `en-US` if `en-IN` unavailable — document fallback).
3. Listening UI: listen pose; cancel; **Type instead**.
4. Count **empty/error finals**; after **two** consecutive empties, show text field (PRD).
5. Permission denied → text field immediately.

**Acceptance:**

- [ ] Hindi default; English after toggle.
- [ ] Two empty results reveal text input.
- [ ] No Deepgram, no custom STT server.

**Cursor prompt:**

```text
Add Android speech_to_text with default locale hi-IN and a settings toggle for English. On permission failure or two empty transcripts, show a text field. No cloud STT APIs.
```

---

### Issue #6: `[SPRINT-2-02]` Gemini Flash persona + thematic Gita summary

* **Labels:** `sprint-2`, `ai-llm`
* **Dependencies:** none (can stub UI)

**Required config:** `GEMINI_API_KEY` in `.env` (never commit real keys).

**Tasks:**

1. Call Gemini **Flash** (pin model id in one constant; comment where to update).
2. **Short** system prompt: persona (speaks as Krishna; AI avatar if asked), language match (Hindi/English/Hinglish Latin), no invented verse numbers, 3–4 sentence cap, politics refusal, crisis: comfort + tell them to use on-screen help / humans, **plus original-words thematic Gita summary** (dharma, devotion, niṣkāma karma, evenness — not verses).
3. User message = transcript or typed text only. **Do not** attach a Gita file or full JSON pack.
4. Timeouts, empty key, and HTTP errors → user-visible Hindi/English error, return to IDLE.

**Acceptance:**

- [ ] No Gita corpus in the request body.
- [ ] Replies stay short; English question → English; Hindi → Hindi.
- [ ] Hinglish Latin in → Hinglish Latin out (prompt instruction).
- [ ] `.env` listed in `.gitignore`.

---

### Issue #7: `[SPRINT-2-03]` On-device TTS + speaking mouth

* **Labels:** `sprint-2`, `ai-tts`
* **Dependencies:** #6, #2

**Tasks:**

1. `flutter_tts` (or equivalent): `hi-IN` when reply is Devanagari-majority; `en-IN` for English and **Hinglish Latin**.
2. Stream or speak full text; set speaking state; duck flute; drive `jawOpen` from TTS activity or a simple envelope (device TTS may not give visemes — envelope is OK).
3. Stop TTS on new listen.

**Acceptance:**

- [ ] No Cartesia/ElevenLabs.
- [ ] Mouth moves during speech at least as an envelope.
- [ ] Flute ducks for the utterance.

---

### Issue #8: `[SPRINT-2-04]` Orchestrator state machine + local quota

* **Labels:** `sprint-2`, `architecture`
* **Dependencies:** #5, #6, #7

**Tasks:**

1. States: `idle → listening → thinking → speaking → idle` (PRD). Ignore overlapping taps.
2. SQLite: profile name optional; `daily_usage` date, `voice_turns_used`, `reward_turns_remaining`.
3. **10** voice turns/day (STT that produces a sent query counts). Rewarded grants **+3 to +5** (pick **+5** unless AdMob reward item says otherwise — document the constant `kRewardTurns = 5`).
4. Text fallback path **does not** consume voice quota (or uses a separate high cap ≥ 100 — pick **uncapped text** for V1 and document it).
5. Midnight local reset.

**Acceptance:**

- [ ] 11th voice turn blocked until reward or next day.
- [ ] Typed questions still work when voice is exhausted if text UI is showing.
- [ ] No cloud DB.

**Cursor prompt:**

```text
Build a conversation cubit: IDLE/LISTENING/THINKING/SPEAKING. Persist 10 voice turns per local day in SQLite. Text input does not consume voice quota. Do not add Firebase.
```

---

## SPRINT 3 — Daily card, safety, ads

### Issue #9: `[SPRINT-3-01]` Daily blessing JSON + streak + screenshot share

* **Labels:** `sprint-3`, `content`
* **Dependencies:** #4

**Tasks:**

1. `assets/gita/daily_blessings.json`: 30–90 objects `{ "id", "cite": "2.47", "hi", "en" }` — **original paraphrases**, not scraped scripture.
2. Pick by day-of-year or sequential streak index; persist last seen date + streak count.
3. Card UI over or below stage (must not cover face permanently — sheet or bottom card).
4. **Ask more** sends the day’s paraphrase + user follow-up to Gemini (same system prompt as oracle).
5. Share: render card to image or share plain text via share sheet (**not** video).

**Acceptance:**

- [ ] Works offline (no Gemini) for the card itself.
- [ ] Streak increments once per local day on open/claim.
- [ ] Share sheet opens with text or PNG.

**Content note:** Authors must not paste a copyrighted translation. Cites are pointers; body is original child-simple wording.

---

### Issue #10: `[SPRINT-3-02]` Crisis strip + politics + identity caption

* **Labels:** `sprint-3`, `safety`
* **Dependencies:** #6, #4

**Tasks:**

1. Classifier: keyword / Gemini safety flag / extra system instruction to prefix `CRISIS:` when user indicates self-harm or acute despair (prefer **on-device keywords + model instruction**; if the model is unsure, still show strip when keywords hit).
2. **Persistent bottom/top strip** (not only a snackbar): talk to family; call **112**; iCALL / counseling — UI strings with **“numbers confirmed at ship”** comment and constants in one `helplines.dart` file.
3. Krishna lines: gentle, **no suicide jokes**, **no methods**, **no “just think of makhan” as the only reply**.
4. Once per session: AI-avatar caption.
5. Politics: prompt already refuses sides; add 2–3 QA tests in comments or a dart test with fixture prompts.

**Acceptance:**

- [ ] Crisis UI does not require dismissing to see a helpline.
- [ ] Helpline constants live in one file for ship-day edit.
- [ ] About duplicates identity disclaimer.

---

### Issue #11: `[SPRINT-3-03]` AdMob banner + Support rewarded (no IAP)

* **Labels:** `sprint-3`, `admob`
* **Dependencies:** #8

**Required:** `ADMOB_APP_ID`, `ADMOB_BANNER_ID`, `ADMOB_REWARDED_ID` (test IDs until store).

**Tasks:**

1. `google_mobile_ads` init; **test** unit IDs in debug.
2. **Adaptive banner** in **bottom chrome** only; `padding` already reserved in stage (#2).
3. Support icon/button → sheet: **publisher** copy (“Support Chibi Krishna AI — watch a short video for more questions”). **Krishna does not speak this.**
4. On reward: add `kRewardTurns` voice turns; optional **blessing pose + aura** animation — copy must **not** say the offering reached Krishna.
5. No interstitial. No banner on the character `Stack` overlay.
6. Load fail: sheet explains try later; never grant reward without `onUserEarnedReward`.

**Acceptance:**

- [ ] Face never covered by the banner.
- [ ] Reward only after completed rewarded callback.
- [ ] No `in_app_purchase` / Play Billing.

**Cursor prompt:**

```text
Add google_mobile_ads: adaptive banner in a bottom bar, not over the character. Support bottom sheet shows a rewarded ad; onUserEarnedReward adds voice turns. Publisher copy only. No interstitials, no IAP.
```

---

## SPRINT 4 — Ship

### Issue #12: `[SPRINT-4-01]` Visual polish, onboarding name, remove debug stage bar

* **Labels:** `sprint-4`, `ui`
* **Dependencies:** #2, #4

**Tasks:**

1. Optional first-run: “What should Krishna call you?” stored locally.
2. Mic as primary control; Support and language in chrome; daily card entry obvious.
3. Warm, calm colors (not cyber-gold HUD). Nature stills when art lands.
4. Disable debug pose buttons in profile ≠ debug.

**Acceptance:**

- [ ] First session under 30 s to first listen or card.
- [ ] Release UI has no “Mouth Morph Shape” debug card.

---

### Issue #13: `[SPRINT-4-02]` Performance, R8, no 3D leftovers

* **Labels:** `sprint-4`, `performance`
* **Dependencies:** all feature issues

**Tasks:**

1. Confirm no SceneView / GLB in release.
2. Compress PNGs; don’t ship unused dusk assets if not commissioned.
3. ProGuard/R8 for play release; minify ads SDK per Google sample.
4. Smoke: 5-minute listen/think/speak on a mid-range API 26+ device/emulator.

**Acceptance:**

- [ ] Release AAB installs; stage 60fps-enough on a mid device (no 3D GPU tax).
- [ ] APK/AAB size called out in the PR description (target: well under old 30 MB 3D budget).

---

### Issue #14: `[SPRINT-4-03]` Privacy policy, Data safety, 13+ Play listing

* **Labels:** `sprint-4`, `publishing`
* **Dependencies:** #11, #5

**Tasks:**

1. Host a privacy policy URL: mic, transcripts to Google Gemini, AdMob, local storage, no voice files on our servers.
2. Play Console: target audience **13+ / not primarily children**; **do not** enroll Families.
3. IARC questionnaire honest (users can talk about feelings; no child-directed).
4. Listing: title **Chibi Krishna AI**; short/full description for devotees and parents; **no “for kids”**.
5. Data safety: microphone, ads, optional name.
6. Internal testing track AAB.

**Acceptance:**

- [ ] Policy URL live before production review.
- [ ] Listing copy matches 13+ lock in PRD v2.
- [ ] Helpline numbers re-checked the week of submit.

---

## Backlog (do not pull into V1 sprints)

| ID | Item |
| :--- | :--- |
| V1.1 | On-device 10–15s video + share sheet |
| Later | Full Gita snippet retrieval (option C) after user testing |
| Later | Play Billing dakshina (only if ever ethically reframed as app tip) |
| Later | Dusk parallax, Rive, iOS |

---

## Solo sequencing hint

Week-shaped, not calendar-committed: **#1+#2+#3+#4** → **#5+#6+#7+#8** → **#9+#10+#11** → **#12+#13+#14**. Art can land anytime after #2 placeholders.
