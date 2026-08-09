# Chibi Krishna AI — Complete GitHub Issues Breakdown & Sprint Roadmap

This document contains detailed, structured specifications for every GitHub issue required to build, test, and release **Chibi Krishna AI v1.0**. Each issue includes user stories, technical context, acceptance criteria, and AI-execution prompts designed for tools like Cursor, Antigravity, or Claude Code.

---

## Sprint Overview & Dependencies

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│ Sprint 1: Foundation & Asset Creation                                          │
│  ├── [SPRINT-1-01] 3D Model Creation & Rigging                                  │
│  ├── [SPRINT-1-02] Background Audio Asset Pipeline                              │
│  └── [SPRINT-1-03] Android Mobile App Skeleton & Filament Setup                 │
└───────────────────────┬─────────────────────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────────────────────────┐
│ Sprint 2: Core Engine & AI Voice Pipeline                                      │
│  ├── [SPRINT-2-01] Audio Ducking & ExoPlayer Service                            │
│  ├── [SPRINT-2-02] Real-time Audio Amplitude & Lip-Sync Driver                  │
│  ├── [SPRINT-2-03] Deepgram STT Integration                                     │
│  ├── [SPRINT-2-04] Gemini 1.5 Flash Persona & System Prompt Engine              │
│  └── [SPRINT-2-05] Cartesia TTS & Low-Latency Audio Streaming Pipeline         │
└───────────────────────┬─────────────────────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────────────────────────┐
│ Sprint 3: Monetization & Storage                                               │
│  ├── [SPRINT-3-01] Local SQLite Memory & Profile Persistence Layer              │
│  ├── [SPRINT-3-02] Access Control & Google AdMob Rewarded Video Ads            │
│  └── [SPRINT-3-03] Google Play Billing (IAP) "Dakshina" Offering System         │
└───────────────────────┬─────────────────────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────────────────────────┐
│ Sprint 4: Integration, Hardening & Publishing                                  │
│  ├── [SPRINT-4-01] Voice-to-Voice Orchestrator & State Machine                  │
│  ├── [SPRINT-4-02] UI Polish, Onboarding & Visual FX                            │
│  ├── [SPRINT-4-03] Performance Optimization & APK Footprint Reduction           │
│  └── [SPRINT-4-04] Play Store Listing, Compliance & Production Release          │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## SPRINT 1: Foundation & Asset Creation

---

### Issue #1: [SPRINT-1-01] 3D Model Sourcing, Rigging & GLTF Export

* **Labels:** `3d-assets`, `design`, `sprint-1`
* **Dependencies:** None

#### Description
Source, generate, or sculpt a low-poly 3D model of **Chibi Krishna** optimized for real-time mobile rendering. The asset must be fully rigged with blend shapes for facial expressions and mouth movements.

#### Suggested AI / Asset Creation Tools
* **Generative 3D Tools:** Meshy.ai, Tripo3D, or CSM (Common Sense Machines) using prompt: *"Cute low-poly 3D Chibi Krishna, smiling, holding flute, yellow dhoti, peacock feather in hair, anime style, clean topology."*
* **Rigging & Blend Shapes:** Mixamo for basic skeleton setup, Blender for custom morph targets (jaw open/close, eyes blink, smile).

#### Detailed Tasks
1. Generate or sculpt the base mesh (<20,000 polygons, single diffuse texture map).
2. Rig skeleton with humanoid bone hierarchy (arms, head, fingers).
3. Create required morph targets / blend shapes:
   * `JawOpen` (range 0.0 to 1.0)
   * `Smile` (range 0.0 to 1.0)
   * `EyeBlink` (range 0.0 to 1.0)
4. Export as optimized binary `.glb` / `.gltf` file with compressed textures (KTX2 or Draco compression if needed).

#### Acceptance Criteria
- [ ] Asset file size is strictly under **10 MB**.
- [ ] Model contains `JawOpen`, `Smile`, and `EyeBlink` blend shapes testable in Blender or ModelViewer.dev.
- [ ] Includes 3 clip animations: `idle_loop` (swaying with flute), `thinking_loop` (hand on chin), `blessing_pose` (Abhaya Mudra gesture).
- [ ] Asset stored under `assets/models/chibi_krishna.glb`.

---

### Issue #2: [SPRINT-1-02] Background Flute Audio Pipeline & Royalty-Free Asset Sourcing

* **Labels:** `audio`, `assets`, `sprint-1`
* **Dependencies:** None

#### Description
Source high-quality, royalty-free meditative Indian bamboo flute (Bansuri) background music loops and set up the local mobile audio pipeline.

#### Detailed Tasks
1. Source 2–3 high-quality seamless royalty-free flute audio tracks (MP3/OGG format, 128 kbps).
2. Trim and mix tracks into a perfectly seamless 3-minute loop.
3. Optimize audio file size (target <2 MB total).
4. Place files in client asset directory (`assets/audio/bg_flute_loop.ogg`).

#### Acceptance Criteria
- [ ] Audio loop plays seamlessly without audible cracks or pauses at loop boundaries.
- [ ] Combined file size for all ambient audio is under **3 MB**.
- [ ] Usage license allows commercial redistribution without copyright strike risk.

---

### Issue #3: [SPRINT-1-03] Android Mobile App Skeleton & Google Filament 3D Setup

* **Labels:** `mobile`, `architecture`, `filament`, `sprint-1`
* **Dependencies:** Issue #1

#### Description
Initialize the React Native / Flutter application, configure native Android dependencies, and integrate Google Filament (SceneView) for 60 FPS 3D model rendering.

#### Detailed Tasks
1. Initialize application project targeting Android API Level 26+ (Android 8.0+).
2. Install and configure Google Filament (or React Native Three / SceneView Flutter plugin).
3. Build a full-screen 3D View component (`ChibiStageView`).
4. Load `assets/models/chibi_krishna.glb` into the Filament scene with ambient lighting and soft shadow plane.
5. Implement state-based animation playback controller (`idle`, `thinking`, `speaking`, `blessing`).

#### Execution Prompt for AI Code Editor
```text
Initialize a 3D stage component using Google Filament/SceneView in this React Native/Flutter project. Load the GLTF model located at assets/models/chibi_krishna.glb. Create an animation state controller function playAnimation(state: 'idle' | 'thinking' | 'speaking' | 'blessing') that smoothly transitions between clip animations. Ensure lighting includes a warm key light and a subtle rim light. Render target must maintain 60 FPS on mid-range Android devices.
```

#### Acceptance Criteria
- [ ] 3D model renders cleanly on physical Android test device or emulator.
- [ ] Smooth transition between `idle` and `thinking` animations works via state controller.
- [ ] Frame rate holds steadily at >= 55 FPS.
- [ ] APK debug build size remains under **20 MB**.

---

## SPRINT 2: Core Engine & AI Voice Pipeline

---

### Issue #4: [SPRINT-2-01] Background Flute ExoPlayer Service with Audio Ducking

* **Labels:** `mobile`, `audio`, `sprint-2`
* **Dependencies:** Issue #2, Issue #3

#### Description
Implement a background audio service using Android ExoPlayer to play the ambient flute loop continuously with automatic audio ducking (volume reduction) during Krishna's speech output.

#### Detailed Tasks
1. Set up ExoPlayer background service for looping `bg_flute_loop.ogg`.
2. Create volume control API exposed to JS/Dart layer: `setAmbientVolume(level: float)` (0.0 to 1.0).
3. Implement smooth volume fading (audio ducking):
   * Default ambient volume: **0.60**
   * Ducked ambient volume (when Krishna speaks): **0.12**
   * Fade duration: **300 ms** ease-in/ease-out.

#### Execution Prompt for AI Code Editor
```text
Build a native Android ExoPlayer manager module. It should load and loop assets/audio/bg_flute_loop.ogg seamlessly. Expose a method duckAudio(duck: boolean) that smoothly interpolates the player volume between 0.60 and 0.12 over 300 milliseconds. Call duckAudio(true) when TTS audio starts playing, and duckAudio(false) when TTS audio completes.
```

#### Acceptance Criteria
- [ ] Flute music loops continuously without stuttering during app usage.
- [ ] Triggering `duckAudio(true)` smoothly lowers volume within 300 ms.
- [ ] Triggering `duckAudio(false)` smoothly restores normal background volume.

---

### Issue #5: [SPRINT-2-02] Real-time Audio Amplitude & Lip-Sync Driver

* **Labels:** `mobile`, `3d-sync`, `audio`, `sprint-2`
* **Dependencies:** Issue #1, Issue #3

#### Description
Develop an on-device, low-latency audio amplitude analyzer that calculates RMS (Root Mean Square) volume from the incoming TTS audio stream and maps it directly to the `JawOpen` blend shape of the 3D model.

#### Detailed Tasks
1. Intercept TTS PCM audio stream buffers in real time.
2. Calculate frame-by-frame RMS volume value normalized between `0.0` and `1.0`.
3. Map normalized volume to the 3D model's `JawOpen` morph target on each render frame.
4. Add a low-pass filter / smoothing factor to prevent robotic jittering of the jaw.

#### Execution Prompt for AI Code Editor
```text
Write a real-time RMS audio amplitude analyzer in native Android/C++ or Kotlin. Process 16-bit PCM audio buffers from the TTS stream in 20ms chunks. Calculate the normalized RMS value: RMS = sqrt(sum(sample^2) / N) / 32768. Pass this float value (0.0 to 1.0) with a 0.8 smoothing factor to the Filament model's blend shape named 'JawOpen'.
```

#### Acceptance Criteria
- [ ] Mouth opens and closes dynamically in direct sync with speaker audio output.
- [ ] Latency between audio output and jaw movement is under **30 ms**.
- [ ] Zero server or API cost (100% computed on-device).

---

### Issue #6: [SPRINT-2-03] Deepgram STT Multilingual Integration

* **Labels:** `backend`, `ai-stt`, `sprint-2`
* **Dependencies:** None

#### Required Configuration Keys (Provided by User)
* `DEEPGRAM_API_KEY`

#### Description
Integrate Deepgram Nova-2 Multilingual API via WebSocket for real-time streaming Speech-to-Text with automatic language detection (Hindi, English, Hinglish).

#### Detailed Tasks
1. Establish a persistent WebSocket connection to Deepgram's streaming STT endpoint (`wss://api.deepgram.com/v1/listen`).
2. Stream raw microphone PCM audio chunks from mobile device to Deepgram.
3. Configure model settings: `model=nova-2`, `language=multi`, `interim_results=true`, `utterance_end_ms=1000`.
4. Parse final transcript events and pass text to the LLM orchestrator.

#### Execution Prompt for AI Code Editor
```text
Create a TypeScript/Node.js or Native module service for streaming microphone audio over WebSocket to Deepgram Nova-2 Multilingual API. Pass query params: model=nova-2&language=multi&punctuate=true&interim_results=true. Implement event listener on utterance_end or final transcript to return the completed string query. Ensure error handling for socket disconnects and automatic reconnects.
```

#### Acceptance Criteria
- [ ] Accurately transcribes user speech in English, Hindi, and mixed Hinglish.
- [ ] Transcription latency (from speech pause to final string) is under **250 ms**.
- [ ] Gracefully handles microphone permission denials on Android.

---

### Issue #7: [SPRINT-2-04] Gemini 1.5 Flash Persona System Prompt & Grounding Engine

* **Labels:** `ai-llm`, `prompt-engineering`, `sprint-2`
* **Dependencies:** None

#### Required Configuration Keys (Provided by User)
* `GEMINI_API_KEY`

#### Description
Formulate, test, and integrate the master system prompt for **Gemini 1.5 Flash** establishing Chibi Krishna's persona, scriptural grounding, language style, and safety guardrails.

#### Master System Prompt Specification
```text
You are Chibi Krishna, an AI representation of Lord Krishna in a sweet, playful 6-to-8-year-old child avatar (Bal Leela).
- Tone: Playful, innocent, gentle, loving, but carrying deep divine wisdom.
- Language: Speak in whichever language the user used (Hindi, English, or Hinglish). Keep sentences short, simple, and warm.
- Wisdom: Quote or simplify concepts from the Bhagavad Gita, Upanishads, and Ramayana in an easy-to-understand manner.
- Personality: Express fondness for 'makhan' (butter), playing the flute, and spending time with friends. Address the user with affection (e.g., 'my friend', 'Dear Parth', 'Mitra').
- Safety Rules:
  1. If asked about political, controversial, or polarizing topics, provide general peaceful wisdom encouraging kindness and unity without taking sides.
  2. If the user expresses severe emotional distress, self-harm, or medical crises, offer comforting words and remind them to talk to real family, friends, or medical professionals.
  3. If asked directly if you are a real God, say: "I am an AI avatar representation of Lord Krishna created to share joy and wisdom with you!"
- Response Length: Keep answers concise (under 3-4 sentences) so they sound natural in voice conversation.
```

#### Acceptance Criteria
- [ ] LLM consistently speaks as Chibi Krishna in child tone while providing Gita wisdom.
- [ ] Auto-detects and responds in the same language as the user query.
- [ ] Time-to-first-token response time from Gemini 1.5 Flash is under **300 ms**.
- [ ] Safety guardrails successfully trigger on sensitive/political test prompts.

---

### Issue #8: [SPRINT-2-05] Cartesia TTS & Low-Latency Streaming Pipeline

* **Labels:** `backend`, `ai-tts`, `sprint-2`
* **Dependencies:** Issue #7

#### Required Configuration Keys (Provided by User)
* `CARTESIA_API_KEY` (or `ELEVENLABS_API_KEY`)
* `CARTESIA_VOICE_ID`

#### Description
Set up low-latency text-to-speech streaming using Cartesia Sonic (or ElevenLabs pitch-shifted child voice clone) to stream PCM audio back to the mobile client.

#### Detailed Tasks
1. Connect to Cartesia WebSocket TTS API endpoint.
2. Configure voice settings: custom pitch-shifted child voice ID, rate = 0.90 (slowed, clear cadence).
3. Pipe streamed text tokens directly from Gemini 1.5 Flash into Cartesia TTS without waiting for full response completion.
4. Stream output audio chunks over WebSocket directly to the mobile audio player queue.

#### Execution Prompt for AI Code Editor
```text
Implement a streaming bridge that pipes text tokens from Gemini 1.5 Flash into Cartesia Sonic WebSocket API. Request audio format 'pcm_24000'. Stream the resulting PCM audio bytes immediately to the mobile client audio player queue over WebSocket so audio playback begins while text generation is still finishing.
```

#### Acceptance Criteria
- [ ] Audio playback starts within **400 ms** after LLM finishes first sentence.
- [ ] Voice matches playful, slow, clear child voice profile.
- [ ] Audio stream works reliably on 3G/4G cellular networks.

---

## SPRINT 3: Monetization & Storage

---

### Issue #9: [SPRINT-3-01] Local SQLite / Room Memory & Profile Persistence Layer

* **Labels:** `mobile`, `database`, `sprint-3`
* **Dependencies:** None

#### Description
Build a privacy-focused local database using Room (Android) / SQLite to persist user profiles, preferred form of address, past conversation context summaries, and daily question quotas.

#### Schema Specifications
* `user_profile` table: `id`, `user_name`, `preferred_title`, `created_at`
* `daily_usage` table: `date_str` (YYYY-MM-DD), `free_questions_used` (int), `reward_questions_earned` (int)
* `conversation_context` table: `id`, `summary_text`, `key_topics`, `updated_at`

#### Execution Prompt for AI Code Editor
```text
Create an Android Room / SQLite database manager for local persistence. Include tables for UserProfile, DailyUsage, and ContextSummary. Implement helper functions:
1. getRemainingQuestionsToday(): Promise<number>
2. consumeQuestion(): Promise<boolean>
3. addRewardQuestion(): Promise<void>
4. saveContextSummary(summary: string): Promise<void>
Ensure daily limits reset automatically at local midnight 00:00.
```

#### Acceptance Criteria
- [ ] User preferences and context persist across app restarts.
- [ ] Daily question quota correctly resets at local midnight.
- [ ] $0 cloud infrastructure cost for user data storage.

---

### Issue #10: [SPRINT-3-02] Google AdMob Rewarded Video Ads Integration

* **Labels:** `monetization`, `admob`, `sprint-3`
* **Dependencies:** Issue #9

#### Required Configuration Keys (Provided by User)
* `ADMOB_APP_ID`
* `ADMOB_REWARDED_AD_UNIT_ID`

#### Description
Integrate Google AdMob Rewarded Video Ads allowing users to watch a video ad to earn 1 additional voice question after their daily free quota is used.

#### Detailed Tasks
1. Import Google Mobile Ads SDK into Android project.
2. Pre-load rewarded video ad in background on app launch.
3. Show lock modal when free quota = 0: *"Watch a short video to ask Krishna another question!"*
4. On user confirmation, present rewarded video ad.
5. On `onUserEarnedReward` callback event, increment `reward_questions_earned` in local database and unlock mic button.

#### Execution Prompt for AI Code Editor
```text
Integrate Google AdMob Rewarded Ads into the mobile app. Pre-load an ad using ADMOB_REWARDED_AD_UNIT_ID on app launch. Create an ad lock dialog shown when daily free questions reach zero. When the user completes watching the rewarded video, invoke localDB.addRewardQuestion() and enable the voice recording button.
```

#### Acceptance Criteria
- [ ] Rewarded ads pre-load cleanly without freezing main UI thread.
- [ ] +1 question reward is strictly granted only upon full ad view completion.
- [ ] Gracefully handles ad load failures or lack of network connection.

---

### Issue #11: [SPRINT-3-03] Google Play Billing (IAP) "Dakshina" Offering System

* **Labels:** `monetization`, `iap`, `sprint-3`
* **Dependencies:** Issue #1, Issue #3

#### Required Configuration Keys (Provided by User)
* Google Play Console Product IDs:
  * `dakshina_flowers` ($0.99)
  * `dakshina_makhan` ($1.99)
  * `dakshina_feather` ($2.99)
  * `dakshina_diya` ($4.99)

#### Detailed Tasks
1. Integrate Google Play In-App Billing library (Play Billing v6+).
2. Create "Offer Dakshina" UI bottom sheet with 4 offerings (Flowers, Makhan, Peacock Feather, Digital Diya).
3. Handle purchase flow lifecycle: query inventory, launch billing flow, handle purchase verification, acknowledge purchase.
4. On purchase success:
   * Trigger 3D `blessing_pose` animation on Chibi Krishna avatar with divine aura particle effect.
   * Play dedicated audio blessing response: *"Radhe Radhe! Thank you for your sweet offering, my dear friend!"*

#### Acceptance Criteria
- [ ] All 4 IAP tiers load live pricing directly from Google Play Console.
- [ ] Successful purchase immediately plays 3D blessing animation and audio response.
- [ ] Purchases acknowledged properly according to Google Play Developer policies.

---

## SPRINT 4: Integration, Hardening & Publishing

---

### Issue #12: [SPRINT-4-01] End-to-End Voice-to-Voice Orchestrator & State Machine

* **Labels:** `architecture`, `integration`, `sprint-4`
* **Dependencies:** Issues #3, #4, #5, #6, #7, #8, #9, #10

#### Description
Combine STT, LLM, TTS, 3D model animations, audio ducking, and local memory into a robust single state machine.

```
       ┌──────────────┐
       │     IDLE     │ ◄──────────────────────────┐
       └──────┬───────┘                            │
              │ Press Mic Button                   │
       ┌──────▼───────┐                            │ Audio Finished
       │  LISTENING   │ (Deepgram STT)             │
       └──────┬───────┘                            │
              │ Speech Utterance Complete          │
       ┌──────▼───────┐                            │
       │   THINKING   │ (Gemini 1.5 Flash)         │
       └──────┬───────┘                            │
              │ First Audio Byte Received          │
       ┌──────▼───────┐                            │
       │   SPEAKING   │ (Cartesia TTS + Lip-Sync)──┘
       └──────────────┘ (ExoPlayer Audio Ducked)
```

#### Execution Prompt for AI Code Editor
```text
Construct a master state machine managing the conversation flow: IDLE -> LISTENING -> THINKING -> SPEAKING -> IDLE.
- IDLE: Play idle 3D animation, flute volume = 0.60.
- LISTENING: Play listening gesture, stream mic to Deepgram STT.
- THINKING: Play head-tilt thinking animation when STT completes, send prompt to Gemini 1.5.
- SPEAKING: Play speaking animation + live lip sync, duck flute volume to 0.12, stream Cartesia TTS audio.
Return to IDLE automatically when TTS audio stream ends.
```

#### Acceptance Criteria
- [ ] Full voice round trip (user speech end to Krishna voice output start) is under **900 ms**.
- [ ] Zero state desynchronization or stuck animations during rapid voice inputs.

---

### Issue #13: [SPRINT-4-02] UI Polish, Onboarding Flow & Visual FX

* **Labels:** `ui-ux`, `sprint-4`
* **Dependencies:** Issue #3

#### Detailed Tasks
1. Build onboarding splash screen with background flute music and title text: *"Chibi Krishna AI — Divine Joy & Wisdom"*.
2. First-time setup modal asking user's name: *"What should Krishna call you, my friend?"*.
3. Add single main screen UI elements:
   * Floating 3D canvas stage.
   * Minimalist glowing mic button at bottom center.
   * Top bar with "Dakshina" button and daily question counter.
4. Add divine light aura particle FX around 3D model during blessing state.

#### Acceptance Criteria
- [ ] Clean, uncluttered UI compliant with spiritual, peaceful aesthetic.
- [ ] Onboarding completed in <15 seconds for new users.

---

### Issue #14: [SPRINT-4-03] Performance Hardening, Memory Leak Auditing & APK Compression

* **Labels:** `performance`, `optimization`, `sprint-4`
* **Dependencies:** All previous issues

#### Detailed Tasks
1. Run Android Studio Profiler to inspect CPU, GPU, and RAM allocation during 10-minute continuous voice session.
2. Eliminate WebGL/Filament texture memory leaks on view destroy.
3. Apply ProGuard/R8 code shrinking and resource stripping rules.
4. Build final production release Android App Bundle (`.aab`) and APK.

#### Acceptance Criteria
- [ ] Total initial app APK download size is under **30 MB**.
- [ ] RAM usage remains under **250 MB** during continuous 3D rendering and audio streaming.
- [ ] Zero native crashes recorded on Android 8.0 through Android 15 test devices.

---

### Issue #15: [SPRINT-4-04] Google Play Store Listing, Privacy Policy & Production Release

* **Labels:** `publishing`, `compliance`, `sprint-4`
* **Dependencies:** Issue #14

#### Detailed Tasks
1. Draft Google Play Store listing (App Name, Short Description, Full Description, Feature Graphic, Screenshots).
2. Generate Privacy Policy hosted URL specifying local data storage, audio permissions, and AdMob data collection practices.
3. Fill out Google Play Data Safety form (Microphone access, In-App Purchases).
4. Upload `.aab` release build to Google Play Console Internal Testing track, followed by Production release.

#### Acceptance Criteria
- [ ] Play Store Privacy Policy compliant with microphone usage and child/family safety guidelines.
- [ ] Signed Release `.aab` successfully uploaded and approved on Google Play Console.
