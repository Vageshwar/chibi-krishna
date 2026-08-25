# Product Requirement Document (PRD) v2.0

## Product Name: Chibi Krishna AI

**Status:** Locked V1 (grilling session). Historical 3D/voice-vendor plan remains in `docs/Chibi_Krishna_AI_PRD.md` (v1.0) and is **not** the build target.

**Play Store title:** Chibi Krishna AI

**Platform (V1):** Android 8.0+ (API 26+). iOS folder in the Flutter repo is not a V1 ship target.

---

## 1. Executive summary

Chibi Krishna AI is an interactive **voice-and-text** Android companion. A full-screen chibi depiction of Krishna stands on a soothing nature stage (stills + light parallax). The user asks questions; Krishna answers in a playful child register with **Bhagavad Gita–themed wisdom**.

**Talking Tom is a UI/UX reference only:** full-screen character, calm nature backdrop, uncluttered chrome. It is **not** a tap-to-giggle toy, voice-echo gimmick, or 3D mascot.

**Key differentiator (V1):** Scripturally flavored, bilingual (Hindi / English) conversation with an on-device speech loop and a **single** cloud LLM (Gemini Flash). No 3D model, no Deepgram, no Cartesia/ElevenLabs, no app backend.

---

## 2. Audience and store positioning

| Layer | Decision |
| :--- | :--- |
| Who may *use* it | Children with a parent, and older / middle-age devotees |
| Who the **listing** is for | **13+**, devotees, parents. Copy and screenshots must not pitch a kids’ game |
| Youths as a segment | Not targeted |
| Google Play Families / Designed for Families | **Out of V1** |
| Ads | Standard **AdMob** (not child-directed Families ads) |

Store listing, feature graphic, and in-app “for kids” language must stay consistent with 13+. Cute Bal Leela art is allowed; “made for children” is not.

---

## 3. Character and theology

- On-screen / About: **AI avatar of Krishna**, created to share joy and Gita-inspired wisdom.
- In voice and chat he **always speaks as Krishna** (playful Bal Leela, roughly 6–8 in tone, fond of makhan and flute).
- He **never** solicits offerings, dakshina, or ads in-character.
- Monetization copy is always the **publisher**: “Support Chibi Krishna AI.”

**Once per session** (and permanently in About): a short caption that this is an AI avatar — not a living guru, not a replacement for temple, family, or clinicians.

If asked whether he is God / the real Krishna, he stays in play in voice, and the caption/About states the AI-avatar fact plainly.

---

## 4. Core use cases (V1)

1. Ask a spoken or typed question; receive a short, warm, Gita-themed answer in the **same language family** as the user (Hindi or English; Hinglish as specified below).
2. Open the app for a **daily blessing card** (local curated paraphrase + chapter.verse cite) and a simple streak.
3. Optional “ask more” on the daily card → Gemini.
4. After voice quota, watch a **Support** rewarded ad for more voice turns; optional blessing **animation** (not a religious transaction).

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
IDLE (idle flute pose, ambient bansuri)
  → user holds/taps mic
LISTENING (listen pose, SpeechRecognizer)
  → final transcript
THINKING (think pose, Gemini)
  → first TTS / text
SPEAKING (bless or speak + mouth layers, flute ducked)
  → IDLE
```

**Voice-first.** Show a text field when:

- microphone permission denied, no recognizer, or hardware/audio error; **or**
- **two** empty / failed transcripts in a row; **or**
- user chooses **Type instead**.

Text on that fallback path is **generous** (uncapped or a very high cap). Voice is metered (below).

---

## 7. Monetization (V1)

**AdSense web tags are not used in the Android app.** Ads are **Google AdMob / Google Mobile Ads SDK**.

| Surface | Behavior |
| :--- | :--- |
| Banner | Thin **adaptive banner in bottom chrome** (with mic / Support). **Never** over the character’s face or the murti-like stage |
| Rewarded | Only from a **Support** bottom sheet the user opened. Publisher copy. Unlocks **+3–5** extra voice turns after the daily free voice budget |
| Interstitial | **None on launch.** None as a wall in front of Krishna |
| IAP / Play Billing | **None in V1** |
| “Dakshina” icon | Same Support sheet: **watch an ad** to support the app / extra questions / play blessing **animation**. Never “Krishna received your offering.” |

**Voice quota:** **10** voice turns per local calendar day, then Support rewarded for **+3–5** per completed view. Reset at local midnight.

---

## 8. AI, Gita grounding, and data

### 8.1 Pipeline

```
Mic → Android SpeechRecognizer (on-device / OS)
  → Gemini Flash (Google AI Studio API key in .env)
  → Android TextToSpeech
```

- **No** Deepgram, **no** Cartesia, **no** ElevenLabs in V1.
- **No** application backend. Quota and profile in **local SQLite**.
- Gemini model: cheap **Flash** class (e.g. whatever AI Studio currently documents as Flash). Confirm model id at implementation.

### 8.2 System prompt (oracle) — Q29 A

Each Gemini call uses a **short** system prompt:

1. Persona (Chibi Krishna, speaks as Krishna, AI-avatar if identity is pressed).
2. Safety (crisis, politics, no invented verse numbers, short answers).
3. Language-matching instructions (including Hinglish Latin → Hinglish Latin).
4. A **short thematic summary of the Gita in our own words** (dharma, devotion, action without clinging to fruit, evenness, etc.). **Not** 700 verses. **Not** a copyrighted translation pasted in. **Not** the full book on every request.

**Do not** inject a full Gita corpus into the prompt or into every user message.

Post-testing (later): optional on-device library (old option C) may be trialed. Out of V1.

### 8.3 Daily blessing pack

Local JSON: **30–90 original paraphrases** written for this app, each with a `gita` cite (`chapter.verse`) the author has checked. Used for the **daily card** and streak. **Ask more** on the card may call Gemini with the same short system prompt.

Do not scrape a modern copyrighted Hindi/English Gita into the repo.

### 8.4 Privacy

- No server-side persistence of recordings (there is no server).
- Microphone used only for STT.
- Gemini receives **transcript text**, not raw audio.
- Privacy policy + Play Data safety must list mic, ads (AdMob), and network to Google.

---

## 9. Safety

| Situation | Product behavior |
| :--- | :--- |
| Distress / self-harm / crisis | Gentle in-character comfort. **No jokes about suicide.** **No medical or “how to” steps.** **On-screen strip stays visible:** talk to family; India emergency **112**; counseling helplines (**confirm numbers and hours at ship** — see Design Findings). He is not a doctor. He may say he is an AI avatar and they should talk to a person. |
| Politics / polarizing news | No party, no sides. Short dharma about duty, kindness, even-mindedness. |
| Other faiths / miracle betting | No attacks, no lottery predictions, no miracle claims. |
| “Are you God?” | In-play voice + session caption + About (AI avatar). |

**Do not** change the subject to flute/makhan as the *only* crisis response.

---

## 10. Visual / audio stage

- **Renderer:** Flutter `Stack` of PNGs (parallax + character + mouth/eyes). **Drop** `sceneview_flutter` / Filament / GLB.
- **Poses:** idle flute, listen, think, bless.
- **Lip feel:** RMS or TTS-activity driving `mouth_closed | half | open` (and blink).
- **Background:** day sky + mid trees + foreground grass (ken-burns / slow parallax). No looping background **video** in V1.
- **Audio:** local looping bansuri; duck while Krishna speaks (`just_audio` or equivalent).

Commission spec: `docs/requirements/assets.md`.

---

## 11. Tech stack (V1)

| Component | Choice |
| :--- | :--- |
| Client | **Existing Flutter repo** |
| Stage | Image stack (no 3D) |
| State | Keep `flutter_bloc` where it already exists |
| STT / TTS | Android `speech_to_text` / `SpeechRecognizer` + `flutter_tts` (or equivalent) |
| LLM | Gemini Flash, key in `.env` via `flutter_dotenv` |
| Ads | `google_mobile_ads` (AdMob) |
| Local DB | SQLite (`sqflite` or Drift) |
| Ambient audio | `just_audio` (already in project) |
| Billing | Not in V1 |

---

## 12. Growth (V1 vs V1.1)

| Mechanic | Version |
| :--- | :--- |
| Daily card + streak | V1 |
| Share screenshot / card via Android share sheet | V1 |
| 10–15s on-device video of Krishna speaking + share sheet | **V1.1** (no cloud video storage) |

---

## 13. Non-functional requirements

| NFR | V1 target |
| :--- | :--- |
| Voice round-trip | **Realistic:** STT + network Gemini + TTS. **Not** the v1.0 “< 900 ms / three vendors” number |
| APK | Modest; **no** 3D runtime. Still strip unused assets; avoid huge dusk/video packs |
| Offline | Daily card + UI work; oracle and ads need network |
| Cost | Solo budget: device speech + Gemini Flash + AdMob. Watch token use after launch; 10 voice/day is the fuse |

---

## 14. Explicitly out of V1

- 3D / GLTF / mixamo / Filament lip-sync blendshapes  
- Deepgram, Cartesia, ElevenLabs  
- Play Billing “dakshina” SKUs  
- AdSense in the APK  
- Designed for Families  
- Full Gita dump per request  
- Cloud video render/storage  
- Production iOS  

---

## 15. Success (60 days, directional)

Devotees and parents keep a **daily streak**, ask Gita-flavored questions, and share a **card**. Video share is a follow-on if the oracle feels good.
