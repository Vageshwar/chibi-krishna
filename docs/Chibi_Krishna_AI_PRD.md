# Product Requirement Document (PRD) v1.0
## Product Name: Chibi Krishna AI

---

## 1. Executive Summary & Core Vision
* **Core Concept:** An interactive, real-time voice-to-voice Android application featuring a 3D avatar of Lord Krishna in a playful child persona (*Bal Leela*) combined with timeless scriptural wisdom (*Bhagavad Gita*).
* **Key Differentiator:** Low-latency voice interaction paired with real-time 3D rendering, multilingual auto-detection (English, Hindi, Hinglish), and scripturally grounded guidance.

---

## 2. Target Audience & Core Use Cases
* **Primary Audience:** Devotees, youth, young adults, and spiritual seekers looking for peaceful guidance, comfort, or daily philosophical answers.
* **Core Use Cases:**
  * Seeking advice on everyday stress, decisions, and emotions.
  * Learning simplified principles of the Bhagavad Gita and Hindu Scriptures.
  * Conversational relaxation through playful dialogue and soothing background flute music.

---

## 3. Monetization & Access Model

### 3.1 Per-Question Access Logic
* **Free Quota:** Every user gets **1 Free Voice Question per Day** (resets daily at 00:00 local time).
* **Rewarded Video Ads (Google AdMob):**
  * When the free daily question is used, asking another question triggers a prompt: *"Watch a short video to ask Krishna another question!"*
  * **Reward Ratio:** 1 Completed Rewarded Video Ad = **1 Additional Voice Question**.
  * **Fallback:** Unlimited free text-only messaging once voice quota expires.

### 3.2 "Dakshina" Virtual Offerings (In-App Purchases)
* **Mechanism:** Integrated via **Google Play In-App Billing (IAP)** for seamless one-tap payment processing across regions.
* **Tiers & Virtual Offerings:**
  * 🌸 **Offer Flowers:** $0.99 / ₹29
  * 🧈 **Offer Makhan (Butter):** $1.99 / ₹49
  * 🪶 **Offer Peacock Feather:** $2.99 / ₹99
  * 🪔 **Perform Digital Diya / Aarti:** $4.99 / ₹199
* **In-App Reward Animation:**
  * Successfully offering Dakshina triggers a custom **3D Blessing Animation** (*Abhaya Mudra*) on the avatar along with a personalized audio thank-you message from Chibi Krishna.

---

## 4. Detailed Feature Specifications

### 4.1 3D Avatar & Stage Mechanics
* **3D Renderer:** Google Filament / SceneView for lightweight 60 FPS 3D rendering with a low APK footprint (~25 MB).
* **3D Model & States:** Single rigged low-poly `.gltf` Chibi Krishna model.
  1. *Idle Loop:* Gentle swaying, breathing, holding flute.
  2. *Thinking:* Head tilt, touch chin.
  3. *Speaking Loop:* Expressive hand gestures, smile.
  4. *Blessing State:* Hand raised in *Abhaya Mudra* with divine aura glow (triggered by Dakshina IAP).
* **Lip-Sync Method:** Device-side real-time audio amplitude mapping (RMS calculation) driving jaw/mouth blend shapes (<50ms processing latency, $0 server cost).

### 4.2 Real-time Voice-to-Voice Pipeline

$$\text{User Voice} \xrightarrow[\text{STT}]{\text{Deepgram Nova-2}} \text{User Text} \xrightarrow[\text{LLM}]{\text{Gemini 1.5 Flash}} \text{Krishna Text} \xrightarrow[\text{TTS}]{\text{Cartesia / Pitch-Shifted}} \text{Streaming Audio}$$

* **Speech-to-Text (STT):** Deepgram Nova-2 Multilingual (Auto-detects language switching between Hindi, English, and Hinglish).
* **LLM Engine:** Gemini 1.5 Flash. Sub-300ms time-to-first-token, system prompt grounded in Bhagavad Gita and major scriptural texts.
* **Text-to-Speech (TTS):** Cartesia Sonic / ElevenLabs (Childish voice, slowed cadence, clear articulation).
* **Background Audio:** Local ExoPlayer streaming royalty-free flute music in a continuous loop, with audio ducking dropping volume to ~15% when Krishna speaks.

### 4.3 Persona, Safety & Identity Guardrails
* **Persona Balance:** Playful 6–8 year old child who loves *makhan* (butter), yet speaks with timeless wisdom.
* **Identity Rules:** Explicitly answers "I am an AI avatar representation of Lord Krishna" if directly questioned about its nature.
* **Safety Rules:**
  * *Controversial/Political:* Provides general wisdom on unity, peace, and duty without taking explicit sides.
  * *Mental Health/Crisis:* Delivers comforting words alongside an on-screen prompt recommending connecting with friends, family, or healthcare professionals.

### 4.4 Local Memory Architecture
* **Storage Engine:** SQLite / Room Database stored locally on the Android device ($0 cloud database overhead).
* **Context Persisted:** User name, preferred form of address, emotional state history, key advice provided, and total Dakshina offered.

---

## 5. Technical Architecture & Tech Stack

| Component | Technology / Provider | Purpose |
| :--- | :--- | :--- |
| **Client App** | React Native / Flutter + Google Filament | UI & 3D Avatar rendering |
| **Speech-to-Text** | Deepgram Nova-2 Multilingual | Sub-200ms speech recognition |
| **Language Model** | Gemini 1.5 Flash | Character reasoning & scriptural grounding |
| **Text-to-Speech** | Cartesia Sonic | Real-time childlike voice synthesis |
| **Monetization** | Google Play Billing + AdMob | IAP Dakshina & Rewarded Video Ads |
| **Local Storage** | Room / SQLite | User context & daily limit tracking |

---

## 6. Non-Functional Requirements (NFRs)
* **Latency:** End-to-end voice round trip target **< 900 ms**.
* **APK Download Size:** **< 30 MB**.
* **Target OS:** Android 8.0+ (API Level 26+).
* **Data Privacy:** Zero server-side persistence of user voice recordings.
