# Chibi Krishna AI — GitHub issues v3 (solo, budget)

**Build target:** `docs/Chibi_Krishna_AI_PRD_v3.md`
**Why v2's issues are superseded:** `Chibi_Krishna_AI_GitHub_Issues_v2.md`'s stage issues (#1–#2) assumed a flat 4-PNG pose-swap stage; v3 uses a **Rive-rigged 2D character** instead (same `StageCubit` contract, different renderer/art pipeline — see PRD v3 §10). v2's oracle/quota/safety/ads issues (#5–#11) are carried forward almost unchanged. New: analytics scaffold, latency masking, referral bonus, streak notification.
**Art/rig spec:** `docs/requirements/assets_v3.md`
**PRD:** `docs/Chibi_Krishna_AI_PRD_v3.md`

**Current repo state (checked before writing this):** the codebase still has the old Filament/`sceneview_flutter` stub (`lib/features/stage/presentation/widgets/chibi_stage_view.dart` renders `SceneView` + a debug "Mouth Morph Shape (JawOpen)" HUD card, `pubspec.yaml` still lists `sceneview_flutter` and `assets/models/chibi_krishna.glb`).

---

## MVP-first restructure (supersedes the sprint ordering below — GitHub Issues/Milestones are now the live tracker)

The sprint plan below front-loads a rigged 5-state character, Gemini, ads, referral, notifications, and a daily card before anyone knows whether "ask Krishna and get a good answer" even feels good. Actual execution instead runs two GitHub milestones, in this order:

1. **MVP — Alive Krishna, No AI Yet.** Prove the two things that don't need an LLM: (a) the Rive character feels alive at rest — breathing, blink, a *cheerful* idle micro-action, not just a static loop — and (b) the mic pipeline actually works (permission, capture, transcript, fallback-to-typing). The "answer" to any input, voice or typed, is a random line from a small local, curated Gita-flavored quote list (hi/en) spoken via TTS with live mouth-flap. **No Gemini, no `.env` API key, no network call, no cost, no quota system** — none of that is needed when responses are canned. The Rive rig is deliberately minimal: **idle + speaking only**; listening is a UI overlay (mic glow), not a third character pose; a dedicated listening pose plus the blessing pose and particle aura move to Fast-Follow.
2. **V1 — Real Oracle & Growth.** Everything that only matters once free-form AI output exists: Gemini persona + timeout fallback (replacing the random-quote picker as the primary response path — the MVP quote list stays as an offline/error fallback rather than being deleted), the crisis strip (pointless against fixed pre-vetted quotes, essential against arbitrary model output), the daily voice quota (irrelevant when responses are free; necessary once they cost tokens), the full 5-state Rive rig + particle aura, daily card/streak, AdMob, referral, local notifications, analytics, polish, and Play listing prep.

The individual issues below (Sprint 1–4) are the detailed spec/rationale bank; the live GitHub issues under each milestone are the trimmed, execution-ready versions of the same work, split along the AI/no-AI line above rather than the sprint-number line.

---

## Sprint overview

```
Sprint 1  Foundation: drop 3D, Rive character stage + placeholder rig, flute, hi/en chrome, analytics scaffold
Sprint 2  Oracle: STT → Gemini → TTS, language, quota SQLite, latency masking, funnel events
Sprint 3  Daily JSON card + crisis/safety UI + AdMob Support + referral bonus + streak notification
Sprint 4  Polish, latency/perf verification, privacy/Play 13+ listing, internal testing
```

**V1.1 (not these sprints):** on-device share video.

**Dependency sketch:** Sprint 1 stage + analytics scaffold → Sprint 2 state machine uses poses and logs events. Sprint 3 ads/quota need Sprint 2 quota API; referral and notification need Sprint 3's streak/share work. Sprint 4 needs a store-ready AAB and a latency measurement pass.

---

## SPRINT 1 — Rive stage, chrome, analytics scaffold

### Issue #1: `[SPRINT-1-01]` Remove SceneView / Filament and stop loading GLB

* **Labels:** `sprint-1`, `mobile`, `debt`
* **Dependencies:** none

**User story:** As a solo maintainer, I do not ship a broken 3D view or a missing `chibi_krishna.glb` crash.

**Tasks:**

1. Remove `sceneview_flutter` from `pubspec.yaml` and all Dart imports (currently only `chibi_stage_view.dart`).
2. Stop listing `assets/models/chibi_krishna.glb` in `pubspec.yaml` assets; the file does not need to exist to launch.
3. Delete the debug "Mouth Morph Shape (JawOpen)" HUD card and the golden aura `AnimatedBuilder` gradient from `ChibiStageView` — both get replaced by the Rive artboard in #2.
4. Keep `StageCubit`/`StageState` as-is for now (`animationState`, `jawOpen`) — #2 binds Rive to these unchanged.

**Acceptance:**

- [ ] `flutter run` on Android does not depend on a GLB or SceneView.
- [ ] Debug APK builds without Filament native failures.
- [ ] No `sceneview_flutter` reference remains in `pubspec.yaml` or `lib/`.

---

### Issue #2: `[SPRINT-1-02]` Rive character stage + placeholder rig

* **Labels:** `sprint-1`, `ui`
* **Dependencies:** #1

**User story:** As a devotee, I see a full-screen Krishna that breathes and blinks even before I say anything — not a static cutout, not a game HUD.

**Tasks:**

1. Add the `rive` package (official Flutter runtime).
2. Build/obtain a **placeholder `.riv`** per `docs/requirements/assets_v3.md` §5: any simple shape with a `ChibiSM` state machine exposing `pose` (number, 0–4), `jawOpen` (number, 0–1), `blessBurst` (trigger). Place at `assets/rive/chibi_krishna.riv`.
3. Rebuild `ChibiStageView` as: background `Stack` (`bg_sky_day` → `bg_mid_trees_day` → `bg_fore_grass_day`, parallax/ken-burns, placeholders OK until art lands per assets_v3.md §3) with a `RiveAnimation.asset` + `StateMachineController` on top.
4. Wire `StateMachineController` inputs to `StageCubit`: `pose` from `state.animationState.index` (or an explicit mapping — do not rely on enum order alone), `jawOpen` from `state.jawOpen` on every cubit emission, `blessBurst.fire()` once when `animationState` transitions **into** `blessing` (not on every rebuild).
5. Reserve **bottom safe inset** (~50–80dp plus banner height constant) so the character never sits under the future AdMob banner.

**Acceptance:**

- [ ] 9:16 stage fills the screen; character (placeholder or final) visible full-screen.
- [ ] Idle state animates on its own (breathing/blink) with **no** Dart-side timer driving it — confirms blink/breathing is authored inside the `.riv`, not faked in Flutter.
- [ ] Changing `StageCubit` state (via the existing debug buttons) visibly changes the Rive state machine's `pose` input.
- [ ] `blessBurst` fires exactly once per entry into blessing, not repeatedly.

**Cursor prompt:**

```text
In this Flutter project, add the `rive` package and replace ChibiStageView's SceneView with a RiveAnimation driven by a StateMachineController bound to StageCubit. Inputs: pose (number 0-4), jawOpen (number 0-1), blessBurst (trigger, fire once on entering blessing). Keep a background Stack of flat PNG parallax layers behind the Rive artboard. Use a placeholder .riv at assets/rive/chibi_krishna.riv until final art lands. Do not add 3D packages.
```

---

### Issue #3: `[SPRINT-1-03]` Flute loop + ducking (keep/fix)

* **Labels:** `sprint-1`, `audio`
* **Dependencies:** none (#1/#2 parallel)

**User story:** As a user, I hear soft bansuri that ducks when Krishna speaks.

**Tasks:**

1. Keep `just_audio` loop of `assets/audio/bg_flute_loop.ogg` (the `.wav` in the repo is redundant — either drop it or document why both are kept).
2. Duck ~0.60 → ~0.12 over ~300ms when speaking (already implemented in `BackgroundAudioService.setAudioDucked` — verify it's still wired to `StageCubit`'s speaking state, not only debug buttons, once #2 lands).
3. If the ogg is missing, app still launches (log + silent fail — already the current behavior, keep it).

**Acceptance:**

- [ ] Loop does not click at seam if a proper loop file is present.
- [ ] Duck/unduck tied to the real speaking state (post-#2), not only debug buttons.

---

### Issue #4: `[SPRINT-1-04]` Hindi-first chrome, English toggle, About caption

* **Labels:** `sprint-1`, `i18n`, `ui`
* **Dependencies:** #1, #2

**User story:** As a Hindi-speaking devotee, chrome is Hindi until I pick English.

**Tasks:**

1. ARB or simple `AppLocalizations`: `hi` default, `en` toggle persisted (`shared_preferences`).
2. Strings: app title **Chibi Krishna AI**, Support, Invite, Type instead, remaining questions, About.
3. About/first-session caption: AI avatar, not a replacement for teachers/temple/clinicians (Hindi + English).
4. Remove the debug pose-testing button bar from the **release** layout (keep behind `kDebugMode`) — it currently sits in `main.dart`'s `HomeScreen`, unguarded.

**Acceptance:**

- [ ] Cold start UI is Hindi if locale/toggle says so.
- [ ] Toggle switches chrome without restarting the process (or with a single rebuild).
- [ ] About states AI-avatar clearly.
- [ ] Release build shows no debug pose buttons.

---

### Issue #5: `[SPRINT-1-05]` Local analytics event scaffold *(new)*

* **Labels:** `sprint-1`, `analytics`
* **Dependencies:** none

**User story:** As the solo maintainer, once the app ships I want to know *why* it did or didn't spread — not guess.

**Tasks:**

1. Add `firebase_analytics` (events only — no Firestore, no Auth, no Cloud Functions; this does not reopen the "no backend" decision, it's a passive SDK in the same category as AdMob).
2. Define one `analytics_events.dart` with typed constants for every event named in `PRD_v3.md` §13 (`app_open`, `voice_turn_started`, `voice_turn_first_audio`, `voice_turn_completed`, `voice_turn_failed`, `card_viewed`, `card_shared`, `streak_incremented`, `referral_share_tapped`, `referral_bonus_granted`, `reward_ad_completed`, `notification_tapped`, `crisis_strip_shown`) — later sprints call into this file rather than inventing ad-hoc event names.
3. Log `app_open` on launch as the first real usage of the scaffold.
4. Enforce (by convention/comment, and in code review of later issues): no event payload may contain transcript text, raw audio, or PII.

**Acceptance:**

- [ ] `app_open` visible in Firebase console (DebugView) on a debug run.
- [ ] `analytics_events.dart` exists with the full event list as named constants, even for events not yet fired (later sprints fill them in).

---

## SPRINT 2 — Voice oracle

### Issue #6: `[SPRINT-2-01]` On-device STT (default hi-IN)

* **Labels:** `sprint-2`, `ai-stt`
* **Dependencies:** #2 (listen pose), #5 (analytics)

**Required:** Android mic permission in manifest + runtime prompt.

**Tasks:**

1. Integrate Android speech recognition (`speech_to_text`).
2. Default locale **`hi-IN`**; settings switch to **`en-IN`** (or `en-US` if `en-IN` unavailable — document fallback).
3. Listening UI: listen pose (`pose=1`); cancel; **Type instead**.
4. Count empty/error finals; after **two** consecutive empties, show text field.
5. Permission denied → text field immediately.
6. Log `voice_turn_started` when a transcript is actually sent (not on every mic tap).

**Acceptance:**

- [ ] Hindi default; English after toggle.
- [ ] Two empty results reveal text input.
- [ ] No Deepgram, no custom STT server.

---

### Issue #7: `[SPRINT-2-02]` Gemini Flash persona + thematic Gita summary

* **Labels:** `sprint-2`, `ai-llm`
* **Dependencies:** #5 (can stub UI)

**Required config:** `GEMINI_API_KEY` in `.env` (never commit real keys).

**Tasks:**

1. Call Gemini **Flash** (pin model id in one constant; comment where to update).
2. **Short** system prompt: persona (speaks as Krishna; AI avatar if asked), language match (Hindi/English/Hinglish Latin), no invented verse numbers, 3–4 sentence cap, politics refusal, crisis: comfort + tell them to use on-screen help/humans, plus original-words thematic Gita summary (dharma, devotion, niṣkāma karma, evenness — not verses).
3. User message = transcript or typed text only. **Do not** attach a Gita file or full JSON pack.
4. **Hard 8s timeout** (PRD v3 §13). Timeout, empty key, and HTTP errors → apologetic in-character line, log `voice_turn_failed` with a reason code, return to IDLE. Never a raw error dialog.

**Acceptance:**

- [ ] No Gita corpus in the request body.
- [ ] Replies stay short; English question → English; Hindi → Hindi.
- [ ] Hinglish Latin in → Hinglish Latin out.
- [ ] `.env` listed in `.gitignore`.
- [ ] A forced timeout (e.g. airplane mode) produces the apologetic fallback, not a crash or raw exception text.

---

### Issue #8: `[SPRINT-2-03]` On-device TTS + live mouth-flap + latency-masking filler

* **Labels:** `sprint-2`, `ai-tts`
* **Dependencies:** #7, #2

**Tasks:**

1. `flutter_tts` (or equivalent): `hi-IN` when reply is Devanagari-majority; `en-IN` for English and Hinglish Latin.
2. Speak full text; set `pose=3` (speaking); duck flute; drive `jawOpen` from TTS activity or a simple envelope (device TTS may not give visemes — envelope is fine) into the Rive `jawOpen` input from #2.
3. **Latency mask (PRD v3 §6):** if no first audio by ~2s after `voice_turn_started`, play one short **local, pre-bundled** filler line (Hindi + English variants; not a Gemini call) while still waiting — then continue into the real answer once ready.
4. Log `voice_turn_first_audio` when TTS actually starts speaking the real answer, and `voice_turn_completed` when it finishes. Compute/attach latency (ms between `voice_turn_started` and `voice_turn_first_audio`) as an event property.
5. Stop TTS on new listen.

**Acceptance:**

- [ ] No Cartesia/ElevenLabs.
- [ ] Mouth moves during speech at least as an envelope, visible on the Rive rig.
- [ ] Flute ducks for the utterance.
- [ ] Artificially delayed response (mock a slow Gemini call) triggers exactly one filler line, not a loop of them.
- [ ] `voice_turn_first_audio`/`voice_turn_completed` events fire with a latency value.

---

### Issue #9: `[SPRINT-2-04]` Orchestrator state machine + local quota

* **Labels:** `sprint-2`, `architecture`
* **Dependencies:** #6, #7, #8

**Tasks:**

1. States: `idle → listening → thinking → speaking → idle`. Ignore overlapping taps.
2. SQLite: profile name optional; `daily_usage` date, `voice_turns_used`, `reward_turns_remaining`, `referral_turns_remaining` (used by #14).
3. **10** voice turns/day (STT that produces a sent query counts). Rewarded grants **+3 to +5** (document the constant `kRewardTurns = 5`).
4. Text fallback path **does not** consume voice quota (uncapped text for V1, documented).
5. Midnight local reset.

**Acceptance:**

- [ ] 11th voice turn blocked until reward, referral bonus, or next day.
- [ ] Typed questions still work when voice is exhausted if text UI is showing.
- [ ] No cloud DB.

---

## SPRINT 3 — Daily card, safety, ads, growth

### Issue #10: `[SPRINT-3-01]` Daily blessing JSON + streak + screenshot share

* **Labels:** `sprint-3`, `content`
* **Dependencies:** #4

**Tasks:**

1. `assets/gita/daily_blessings.json`: 30–90 objects `{ "id", "cite": "2.47", "hi", "en" }` — **original paraphrases**, not scraped scripture.
2. Pick by day-of-year or sequential streak index; persist last seen date + streak count.
3. Card UI over or below stage (must not cover face permanently — sheet or bottom card). Log `card_viewed` on open.
4. **Ask more** sends the day's paraphrase + user follow-up to Gemini (same system prompt as oracle).
5. Share: render card to image or share plain text via share sheet (not video). Log `card_shared` on share-sheet invocation.
6. Log `streak_incremented` once per local day on open/claim.

**Acceptance:**

- [ ] Works offline (no Gemini) for the card itself.
- [ ] Streak increments once per local day on open/claim.
- [ ] Share sheet opens with text or PNG; `card_shared` fires.

**Content note:** Authors must not paste a copyrighted translation. Cites are pointers; body is original child-simple wording.

---

### Issue #11: `[SPRINT-3-02]` Crisis strip + politics + identity caption

* **Labels:** `sprint-3`, `safety`
* **Dependencies:** #7, #4

**Tasks:**

1. Classifier: keyword/model-instruction hybrid to flag self-harm/acute despair (on-device keywords + system-prompt instruction; if the model is unsure, still show the strip when keywords hit).
2. **Persistent bottom/top strip** (not only a snackbar): talk to family; call **112**; iCALL/counseling — strings with "numbers confirmed at ship" comment and constants in one `helplines.dart` file.
3. Krishna lines: gentle, no suicide jokes, no methods, no "just think of makhan" as the only reply.
4. Once per session: AI-avatar caption.
5. Politics: prompt already refuses sides; add 2–3 QA fixture tests.
6. Log `crisis_strip_shown` (no transcript content in the payload — just the fact it fired).

**Acceptance:**

- [ ] Crisis UI does not require dismissing to see a helpline.
- [ ] Helpline constants live in one file for ship-day edit.
- [ ] About duplicates identity disclaimer.

---

### Issue #12: `[SPRINT-3-03]` AdMob banner + Support rewarded (no IAP)

* **Labels:** `sprint-3`, `admob`
* **Dependencies:** #9

**Required:** `ADMOB_APP_ID`, `ADMOB_BANNER_ID`, `ADMOB_REWARDED_ID` (test IDs until store).

**Tasks:**

1. `google_mobile_ads` init; test unit IDs in debug.
2. **Adaptive banner** in bottom chrome only; padding already reserved in stage (#2).
3. Support icon/button → sheet: publisher copy ("Support Chibi Krishna AI — watch a short video for more questions"). Krishna does not speak this.
4. On reward: add `kRewardTurns` voice turns; optional blessing pose (`pose=4`) + aura — copy must not say the offering reached Krishna. Log `reward_ad_completed`.
5. No interstitial. No banner on the character overlay.
6. Load fail: sheet explains try later; never grant reward without `onUserEarnedReward`.

**Acceptance:**

- [ ] Face never covered by the banner.
- [ ] Reward only after completed rewarded callback.
- [ ] No `in_app_purchase`/Play Billing.

---

### Issue #13: `[SPRINT-3-04]` Invite-a-friend soft bonus *(new)*

* **Labels:** `sprint-3`, `growth`
* **Dependencies:** #9, #10 (reuses share plumbing), #12 (same Support sheet)

**User story:** As a user who's hit the daily voice limit, I can invite a friend for a small bonus without watching another ad.

**Tasks:**

1. Add an "Invite" tab/section to the same Support bottom sheet from #12. Publisher copy, generic share text/link (Android share sheet — reuse the mechanism from #10, not a new plugin).
2. On a **completed** share intent (the share sheet's own completion callback, not just the button tap), grant **+2** voice turns via the `referral_turns_remaining` column from #9.
3. **Cap at 2 grants/day** (max +4/day from this path). Reset at local midnight alongside the rest of quota.
4. Copy must **not** imply the friend has to install for the reward to register — there is no backend, so this cannot be verified. Document that limitation directly in the UI copy's code comment and in the About/FAQ if one exists.
5. Log `referral_share_tapped` on open of the invite share sheet, `referral_bonus_granted` when the +2 actually lands.

**Acceptance:**

- [ ] Sharing twice in a day grants +4 total and stops granting on a 3rd share.
- [ ] No claim in the UI that the referral is verified or that the friend must install.
- [ ] Works with the same 10-turn quota display from #9 (shows combined remaining turns, not a separate confusing counter).

**Cursor prompt:**

```text
Add an "Invite" section to the existing Support bottom sheet. Use the platform share sheet to send app text/link. On the share sheet's completion callback, grant +2 voice turns to a referral_turns_remaining counter in the existing quota SQLite table, capped at 2 grants per local day. Do not claim install verification anywhere in copy — there is no backend.
```

---

### Issue #14: `[SPRINT-3-05]` Daily streak local notification *(new)*

* **Labels:** `sprint-3`, `growth`
* **Dependencies:** #10 (streak must exist)

**User story:** As a user who opened the app yesterday, a single gentle reminder brings me back today.

**Tasks:**

1. Add `flutter_local_notifications`. **Local scheduling only** — no server push, consistent with the no-backend constraint.
2. Request the notification permission **contextually** — e.g. right after the user claims their first streak day, not at cold start. Handle Android 13+ `POST_NOTIFICATIONS` runtime permission explicitly.
3. Schedule **one** daily notification (not a barrage) around the user's typical open time (simplest V1 approach: a fixed local time, e.g. 8pm, configurable later) reminding them their streak/blessing is waiting. Hindi + English copy per §5 language rules.
4. Tapping the notification deep-links straight to the daily card, not just the app's home screen.
5. If the user opens the app on their own before the scheduled time, do not also fire the notification that day (cancel/reschedule for the next day instead of double-pinging).
6. Log `notification_tapped` on deep-link entry from a notification.

**Acceptance:**

- [ ] Permission prompt appears after the first streak claim, not on first launch.
- [ ] Denying the permission does not block any other feature.
- [ ] At most one notification per local day.
- [ ] Tapping it opens directly to the daily card.

---

## SPRINT 4 — Ship

### Issue #15: `[SPRINT-4-01]` Visual polish, onboarding name, remove debug stage bar

* **Labels:** `sprint-4`, `ui`
* **Dependencies:** #2, #4

**Tasks:**

1. Optional first-run: "What should Krishna call you?" stored locally.
2. Mic as primary control; Support/Invite and language in chrome; daily card entry obvious.
3. Warm, calm colors (not cyber-gold HUD — current `main.dart` theme leans cyber-gold/cyan; revisit against the "calm nature stage" brief).
4. Confirm the debug pose-testing bar from #4 is fully gone in release, not just visually hidden.

**Acceptance:**

- [ ] First session under 30s to first listen or card.
- [ ] Release UI has no debug controls of any kind.

---

### Issue #16: `[SPRINT-4-02]` Performance, R8, latency verification, no 3D leftovers

* **Labels:** `sprint-4`, `performance`
* **Dependencies:** all feature issues

**Tasks:**

1. Confirm no SceneView/GLB/`sceneview_flutter` in release (pubspec and native build outputs).
2. Compress PNGs and the `.riv` file; don't ship unused dusk assets if not commissioned.
3. ProGuard/R8 for play release; minify ads + analytics SDKs per Google/Firebase sample.
4. **Latency verification against PRD v3 §13:** on a mid-range API 26+ device, measure P50/P90 tap-to-first-audio across a batch of real voice turns using the `voice_turn_started`→`voice_turn_first_audio` analytics events. Report the numbers in the PR description against the **P50 < 2.5s / P90 < 4.5s** target; if missed, note whether it's STT, Gemini, or TTS init that's the bottleneck.
5. Smoke: 5-minute listen/think/speak on a mid-range device/emulator, confirm the Rive idle animation doesn't drop frames.

**Acceptance:**

- [ ] Release AAB installs; Rive stage renders at a smooth frame rate on a mid device (no 3D GPU tax).
- [ ] APK/AAB size called out in the PR description (target: well under old 30MB 3D budget).
- [ ] Latency numbers reported against the pinned NFR target.

---

### Issue #17: `[SPRINT-4-03]` Privacy policy, Data safety, 13+ Play listing

* **Labels:** `sprint-4`, `publishing`
* **Dependencies:** #12, #6, #5, #14

**Tasks:**

1. Host a privacy policy URL: mic, transcripts to Google Gemini, AdMob, **Firebase Analytics (anonymous events)**, **local notifications**, local storage, no voice files on our servers.
2. Play Console: target audience **13+/not primarily children**; do not enroll Families.
3. IARC questionnaire honest (users can talk about feelings; no child-directed).
4. Listing: title **Chibi Krishna AI**; short/full description for devotees and parents; no "for kids."
5. Data safety: microphone, ads, analytics, notifications, optional name.
6. Internal testing track AAB.

**Acceptance:**

- [ ] Policy URL live before production review.
- [ ] Listing copy matches 13+ lock in PRD v3.
- [ ] Helpline numbers re-checked the week of submit.
- [ ] Data safety form lists analytics and notifications, not just mic/ads.

---

## Backlog (do not pull into V1 sprints)

| ID | Item |
| :--- | :--- |
| V1.1 | On-device 10–15s video + share sheet |
| Later | Full Gita snippet retrieval (option C) after user testing |
| Later | Play Billing dakshina (only if ever ethically reframed as app tip) |
| Later | Server-verified referral attribution / deep-link install tracking (needs a backend — revisit only if the soft nudge in #13 proves worth it) |
| Later | Dusk parallax, richer Rive rig fidelity (a second animation pass once the base rig ships), iOS |
| Rejected | Live2D Cubism — revenue-tiered commercial license, conflicts with AdMob revenue from day one |

---

## Solo sequencing hint

Week-shaped, not calendar-committed: **#1+#2+#3+#4+#5** → **#6+#7+#8+#9** → **#10+#11+#12+#13+#14** → **#15+#16+#17**. Art can land anytime after #2's placeholder rig; the `.riv` file swap is asset-only once the state machine contract is stable.
