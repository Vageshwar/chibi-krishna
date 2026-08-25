# Product Requirement Document (PRD) v3.0

## Product Name: Chibi Krishna AI

**Status:** Locked. Supersedes `Chibi_Krishna_AI_PRD_v2.md` on two axes: **visual stage** (2D pose-swap → **Rive-rigged 2D character**) and **growth mechanics** (adds referral, streak notification, latency targets, analytics). Everything else in v2 (monetization, AI pipeline, safety, language rules, audience/store positioning) is unchanged and restated here so this file is self-contained. `Chibi_Krishna_AI_PRD.md` (v1.0, 3D/Deepgram/Cartesia) remains historical.

**Play Store title:** Chibi Krishna AI

**Platform (V1):** Android 8.0+ (API 26+). iOS not a V1 ship target.

---

## Changes from v2 (why this revision exists)

1. **Solo-dev reality check on "lively 2D."** v2's plan (4 flat PNG poses + mouth/eye overlay swap) works but reads as a stiff cutout doll — poses jump-cut instead of blending. The dev cannot sculpt/rig 3D and does not want to pay for AI 3D generation. Fix: a **Rive** skeletal 2D rig — free editor, free MIT-licensed Flutter runtime, no revenue-tiered license (unlike Live2D Cubism, which was considered and rejected for that reason). Same StageCubit contract as v2, so the app-logic side barely changes; only the rendering widget and the art pipeline change.
2. **V1 as documented had no growth loop beyond "share a screenshot."** A post-launch review flagged: no re-engagement (no notifications), no referral/invite mechanic, no pinned voice-latency target (first-impression risk), and no analytics to tell you *why* virality did or didn't happen. This revision adds all four, scoped to fit the existing no-backend, solo-budget constraint.

---

## 1. Executive summary

Chibi Krishna AI is an interactive **voice-and-text** Android companion. A full-screen **rigged 2D chibi Krishna** stands on a soothing nature stage (parallax stills + a lightly animated character — breathing, blinking, gesture poses, live mouth movement), driven by Rive, not 3D. The user asks questions; Krishna answers in a playful child register with **Bhagavad Gita–themed wisdom**.

**Talking Tom is a UI/UX reference only:** full-screen character, calm nature backdrop, uncluttered chrome. It is **not** a tap-to-giggle toy, voice-echo gimmick, or 3D mascot.

**Key differentiator (V1):** Scripturally flavored, bilingual (Hindi/English) conversation with an on-device speech loop, a **single** cloud LLM (Gemini Flash), and a 2D character that feels alive at rest (idle breathing/blink) without any 3D pipeline. No 3D model, no Deepgram, no Cartesia/ElevenLabs, no app backend.

---

## 2. Audience and store positioning

| Layer | Decision |
| :--- | :--- |
| Who may *use* it | Children with a parent, and older/middle-age devotees |
| Who the **listing** is for | **13+**, devotees, parents. Copy and screenshots must not pitch a kids' game |
| Youths as a segment | Not targeted |
| Google Play Families / Designed for Families | **Out of V1** |
| Ads | Standard **AdMob** (not child-directed Families ads) |

Store listing, feature graphic, and in-app "for kids" language must stay consistent with 13+. Cute Bal Leela art is allowed; "made for children" is not.

---

## 3. Character and theology

- On-screen / About: **AI avatar of Krishna**, created to share joy and Gita-inspired wisdom.
- In voice and chat he **always speaks as Krishna** (playful Bal Leela, roughly 6–8 in tone, fond of makhan and flute).
- He **never** solicits offerings, dakshina, or ads in-character.
- Monetization copy is always the **publisher**: "Support Chibi Krishna AI."

**Once per session** (and permanently in About): a short caption that this is an AI avatar — not a living guru, not a replacement for temple, family, or clinicians.

If asked whether he is God / the real Krishna, he stays in play in voice, and the caption/About states the AI-avatar fact plainly.

---

## 4. Core use cases (V1)

1. Ask a spoken or typed question; receive a short, warm, Gita-themed answer in the **same language family** as the user (Hindi or English; Hinglish as specified below).
2. Open the app for a **daily blessing card** (local curated paraphrase + chapter.verse cite) and a simple streak — reinforced by an **optional daily reminder notification**.
3. Optional "ask more" on the daily card → Gemini.
4. After voice quota, watch a **Support** rewarded ad for more voice turns, **or invite a friend** for a smaller no-ad bonus; optional blessing **animation** (not a religious transaction).
5. Even with zero questions asked, the character is visibly alive on open (breathing, blink, ambient flute) — the "wow, it's not a static image" moment happens before the user speaks at all.

Out of V1: on-device share **video**, full Gita library retrieval, IAP, iOS production, tap-reaction toy loop.

---

## 5. Languages

| Topic | Rule |
| :--- | :--- |
| Supported | **Hindi and English only** (no third language in V1) |
| Default STT locale | `hi-IN` |
| English STT | User toggle in settings |
| Gemini | Reply in the language of the **transcript** (Hindi ↔ English) |
| Hinglish (Latin mixed) | Gemini may reply in **Hinglish Latin**; TTS uses **`en-IN`** |
| UI chrome | **Hindi-first**, English toggle (buttons, Support, errors, daily card chrome) |

Hinglish has no dedicated TTS voice; do not promise one.

---

## 6. Interaction loop

```
IDLE (idle pose: breathing, blink, flute sway, ambient bansuri)
  → user holds/taps mic
LISTENING (listen pose, SpeechRecognizer)
  → final transcript
THINKING (think pose, Gemini call)
  → [if > ~2s with no first audio: play a short local filler line — not a Gemini call]
  → first TTS / text
SPEAKING (speak pose + live mouth-flap from TTS amplitude, flute ducked)
  → IDLE
```

**Voice-first.** Show a text field when:

- microphone permission denied, no recognizer, or hardware/audio error; **or**
- **two** empty/failed transcripts in a row; **or**
- user chooses **Type instead**.

Text on that fallback path is **generous** (uncapped or a very high cap). Voice is metered (below).

**Latency masking:** because the round trip is STT → network Gemini → TTS, silence past ~2s reads as "broken," not "thinking." A small bundled set of local filler lines (Hindi + English, e.g. "Hmm… ek pal…" / "Let me think…") plays once if Gemini hasn't returned by then, then the real answer follows. This is a UX patch, not a substitute for the latency target in §13.

---

## 7. Monetization (V1)

**AdSense web tags are not used in the Android app.** Ads are **Google AdMob / Google Mobile Ads SDK**.

| Surface | Behavior |
| :--- | :--- |
| Banner | Thin **adaptive banner in bottom chrome** (with mic/Support). **Never** over the character's face or the murti-like stage |
| Rewarded | Only from a **Support** bottom sheet the user opened. Publisher copy. Unlocks **+3–5** extra voice turns after the daily free voice budget |
| Interstitial | **None on launch.** None as a wall in front of Krishna |
| IAP / Play Billing | **None in V1** |
| "Dakshina" icon | Same Support sheet: **watch an ad** to support the app / extra questions / play blessing **animation**. Never "Krishna received your offering." |
| **Invite a friend** *(new)* | Same Support sheet, a second tab. Share sheet with app text/link. On a completed share intent, grant **+2** voice turns, capped at **2 grants/day** (max +4/day this way). **No install verification** — there is no backend, so this is a soft nudge, not measured attribution. Copy must not imply the friend must download for the reward to count. |

**Voice quota:** **10** voice turns per local calendar day, then Support rewarded for **+3–5** per completed view, or referral for **+2** (capped as above). Reset at local midnight.

---

## 8. AI, Gita grounding, and data

### 8.1 Pipeline

```
Mic → Android SpeechRecognizer (on-device/OS)
  → Gemini Flash (Google AI Studio API key in .env), hard timeout 8s
  → Android TextToSpeech
```

- **No** Deepgram, **no** Cartesia, **no** ElevenLabs in V1.
- **No** application backend. Quota, profile, and event counters in **local SQLite**.
- Gemini model: cheap **Flash** class (pin model id at implementation; confirm current name in AI Studio).

### 8.2 System prompt (oracle)

Each Gemini call uses a **short** system prompt:

1. Persona (Chibi Krishna, speaks as Krishna, AI-avatar if identity is pressed).
2. Safety (crisis, politics, no invented verse numbers, short answers).
3. Language-matching instructions (including Hinglish Latin → Hinglish Latin).
4. A **short thematic summary of the Gita in our own words** (dharma, devotion, action without clinging to fruit, evenness, etc.). **Not** 700 verses. **Not** a copyrighted translation pasted in.

**Do not** inject a full Gita corpus into the prompt or into every user message.

### 8.3 Daily blessing pack

Local JSON: **30–90 original paraphrases** written for this app, each with a `gita` cite (`chapter.verse`) the author has checked. Used for the **daily card** and streak. "Ask more" on the card may call Gemini with the same short system prompt.

Do not scrape a modern copyrighted Hindi/English Gita into the repo.

### 8.4 Privacy

- No server-side persistence of recordings (there is no server).
- Microphone used only for STT.
- Gemini receives **transcript text**, not raw audio.
- **Analytics** (§13): anonymous event counters only (e.g. "voice turn completed"), no transcript content, no raw audio, ever sent to analytics.
- **Notifications** are **local-only** (device-scheduled), not sent from any server we run.
- Privacy policy + Play Data safety must list: mic, ads (AdMob), network to Google (Gemini + AdMob + analytics), local notifications.

---

## 9. Safety

| Situation | Product behavior |
| :--- | :--- |
| Distress/self-harm/crisis | Gentle in-character comfort. **No jokes about suicide.** **No medical or "how to" steps.** **On-screen strip stays visible:** talk to family; India emergency **112**; counseling helplines (**confirm numbers and hours at ship** — see Design Findings). He is not a doctor. He may say he is an AI avatar and they should talk to a person. |
| Politics/polarizing news | No party, no sides. Short dharma about duty, kindness, even-mindedness. |
| Other faiths/miracle betting | No attacks, no lottery predictions, no miracle claims. |
| "Are you God?" | In-play voice + session caption + About (AI avatar). |

**Do not** change the subject to flute/makhan as the *only* crisis response.

---

## 10. Visual / audio stage (Rive, replaces v2 §10)

- **Character renderer:** a single **Rive** artboard (`rive: ^0.14.x` Flutter package, the current `rive_native`-backed runtime — `0.13.x` is that package's now-abandoned legacy line, do not use it) rendering `krishna_ai_teacher_master`, a marketplace character asset ([KrishnaJI](https://rive.app/marketplace/27686-52286-krishnaji/), CC BY 4.0 — **attribution required**, not yet added to the app). Composited over a Flutter `Stack` of the same flat background parallax PNGs as v2 (sky/mid-trees/foreground grass — those stay static images; only the character is rigged).
- **Driving mechanism — Rive Data Binding, not legacy state-machine inputs.** This asset's state machine (`KrishnaJI_SM`) exposes a **ViewModel** with three enum properties instead: `poses` (Idle/idle_lookaround/is_waving/talk_visemes/is_Denial/is_Acceptance/Yesss), `emotion` (14 values incl. a baked-in `Thniking` typo), `eye` (close/open_big/open_small). `StageCubit`'s `ChibiAnimationState` (idle/listening/thinking/speaking/blessing) maps to a combination of these three per app state. `talk_visemes` is a self-contained talking animation — set once per state change, not driven per-frame like a jawOpen number would be. Full verified contract and the mapping table: `docs/requirements/assets_v3.md` §4a.
  - Blink is **self-timed inside Rive**, not driven from Dart.
  - A `FlutterError.onError` guard catches any Rive paint-time exception once and falls back to a plain gradient rather than repainting a broken frame forever — inert with the current asset (renders cleanly), kept for whatever the next file revision might trip.
- **Background:** unchanged from v2 — day sky + mid trees + foreground grass (ken-burns/slow parallax). No looping background **video** in V1.
- **Audio:** local looping bansuri; duck while Krishna speaks (`just_audio`, unchanged from v2).
- **Explicitly rejected:** `sceneview_flutter`/Filament/GLB (solo 3D pipeline, already dead in v2); Live2D Cubism (free editor, but a revenue-tiered commercial license — this app carries AdMob revenue from day one, so that tier would eventually bite; Rive has no such cap).

Full rig contract: `docs/requirements/assets_v3.md`.

---

## 11. Tech stack (V1)

| Component | Choice |
| :--- | :--- |
| Client | **Existing Flutter repo** |
| Stage | Rive rig (character) + image `Stack` (background) |
| State | Keep `flutter_bloc` where it already exists |
| STT/TTS | Android `speech_to_text`/`SpeechRecognizer` + `flutter_tts` (or equivalent) |
| LLM | Gemini Flash, key in `.env` via `flutter_dotenv` |
| Ads | `google_mobile_ads` (AdMob) |
| Local DB | SQLite (`sqflite` or Drift) — quota, streak, and local event counters |
| Ambient audio | `just_audio` (already in project) |
| Notifications | `flutter_local_notifications` — **local scheduling only**, no push server |
| Analytics | `firebase_analytics` — **events only**, no Firestore/Auth/Functions, no server code we run. This does not reopen the "no backend" decision; it is a passive SDK for anonymous counters, same category as AdMob |
| Billing | Not in V1 |

---

## 12. Growth and retention (V1 vs V1.1)

| Mechanic | Version | Notes |
| :--- | :--- | :--- |
| Daily card + streak | V1 | Unchanged from v2 |
| Daily local streak reminder notification | **V1 (new)** | Opt-in, asked contextually (e.g. after first streak claim), not at cold start. One notification/day max. Deep-links to the daily card. Local scheduling only — no server push |
| Share screenshot/card via Android share sheet | V1 | Unchanged from v2 |
| Invite-a-friend soft bonus | **V1 (new)** | See §7. No install verification — a nudge, not measured K-factor |
| 10–15s on-device video of Krishna speaking + share sheet | **V1.1** | Still deferred — no cloud video storage, and it's the biggest single scope item. Acknowledged as the strongest viral lever, deliberately traded for solo-dev cost control in V1 |

**Honesty note carried from the review that produced this doc:** V1's growth bet is *habit* (streak + notification) plus *low-friction share* plus a *referral nudge* — not a video-driven viral loop. That is a reasonable solo-dev tradeoff, but it is a tradeoff, not a guarantee of virality.

---

## 13. Non-functional requirements

| NFR | V1 target |
| :--- | :--- |
| Voice round-trip | **Pinned target:** tap-to-first-audio **P50 < 2.5s, P90 < 4.5s** (STT + network Gemini + TTS start). Measured via the `voice_turn_started` → `voice_turn_first_audio` analytics event pair. Degrade path: local filler line past ~2s (§6); apologetic in-character line + return to IDLE if Gemini exceeds the 8s hard timeout — never a raw error dialog |
| APK | Modest; **no** 3D runtime. Rive's native runtime is small relative to the old 3D budget. Strip unused assets; avoid huge dusk/video packs |
| Offline | Daily card, UI, and the **idle character animation** (breathing/blink/flute-sway) all work with no network — the app "feels alive" before the user asks anything. Oracle and ads need network |
| Cost | Solo budget: device speech + Gemini Flash + AdMob + free-tier Firebase Analytics. Watch token use after launch; 10 voice/day is the fuse |
| Analytics coverage | At minimum: `app_open`, `voice_turn_started`, `voice_turn_first_audio`, `voice_turn_completed`, `voice_turn_failed` (with reason), `card_viewed`, `card_shared`, `streak_incremented`, `referral_share_tapped`, `referral_bonus_granted`, `reward_ad_completed`, `notification_tapped`, `crisis_strip_shown`. No PII, no transcript text, no raw audio in any event payload |

---

## 14. Explicitly out of V1

- 3D/GLTF/mixamo/Filament lip-sync blendshapes
- Deepgram, Cartesia, ElevenLabs
- Live2D Cubism (revenue-tiered license — rejected in favor of Rive)
- Play Billing "dakshina" SKUs
- AdSense in the APK
- Designed for Families
- Full Gita dump per request
- Cloud video render/storage
- Server-verified referral attribution / deep-link install tracking (would require a backend we've chosen not to run — revisit only if the soft referral nudge proves worth the added complexity)
- Push notifications requiring a server (local scheduling only)
- Production iOS

---

## 15. Success (60 days, directional)

Devotees and parents keep a **daily streak** (reinforced by the reminder notification), ask Gita-flavored questions inside the pinned latency target, share a **card**, and a meaningful minority use the invite nudge. With analytics in place these are now *measurable*, not just directional: streak Day-7 retention, share-sheet opens per WAU, referral-bonus grants per WAU (a lightweight virality proxy given no server attribution), and P50/P90 voice latency staying inside target. Video share remains a follow-on if the oracle and retention numbers justify the V1.1 investment.
