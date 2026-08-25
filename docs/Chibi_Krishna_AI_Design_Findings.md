# Chibi Krishna AI — Design findings (grilling lock)

This note records **why** V1 diverges from `docs/Chibi_Krishna_AI_PRD.md` (v1.0). It is not a second PRD; the build spec is `docs/Chibi_Krishna_AI_PRD_v2.md`.

A dedicated primary-source research file (`docs/research-image-companion-vs-3d-and-ads.md`) was **not** in the repo when this was written. Play/ads statements below follow the grilling session and [Google Play Families Policies](https://support.google.com/googleplay/android-developer/answer/9893335) at a **summary** level — re-read the live policy before store submission. Do not treat this file as legal advice.

---

## 1. Talking Tom is UI only

**Finding:** The original PRD mixed a **tap-toy** (Talking Tom DNA) with a **Gita voice oracle** and a **rigged 3D Krishna**. Those are three products.

**Lock:** V1 is the **oracle**. Talking Tom informs **layout and mood** only: full-screen character, nature backdrop, sparse chrome, soothing (not slapstick). No poke-belly, no voice-echo comedy loop, no requirement to orbit a 3D mesh.

---

## 2. Why not 3D in V1

**Finding:** Sprint 1 in v1.0 was blocked on a rigged GLB (blend shapes, clips, Filament). The Flutter repo already stubs `sceneview_flutter` and a fake jaw HUD; there is no shippable model. Solo 3D (sculpt, rig, animate, compress, light) is the slowest, least viral-critical path.

**Lock:** **Image stage** — four consistent poses + mouth/eye layers + parallax stills. Looks “alive” via pose changes and mouth swap, not camera orbit. Live2D/Rive can wait until stills exist. Extra mismatched AI full-bodies are worse than one aligned puppet.

Commission list: `docs/requirements/assets.md`.

---

## 3. AdSense vs AdMob

**Finding:** Conversation used “AdSense” loosely. **Google AdSense** is the **web** product. Android apps use **Google AdMob** (Google Mobile Ads SDK). The v1.0 PRD already named AdMob for rewarded video; V2 **drops AdSense-in-APK** entirely.

**Lock:** AdMob banner (bottom chrome) + rewarded from a **Support** sheet. No AdSense tags. No launch interstitial. No banner over the character.

---

## 4. Play 13+ vs “children and grandparents”

**Finding:** Desired *users* include children and older devotees. Play **Families** rules apply if children are a **declared or obvious** target: certified ad SDKs, no personalized ads to children, mixed audience needs a **neutral age screen**, and several formats are restricted (including aggressive rewarded/full-screen patterns and emotionally manipulative “watch this” pressure). Play may judge **imagery and wording**, not only the Console checkbox. A full-screen baby Krishna is child-*coded* even if grandma is the buyer.

Gemini / generative APIs often restrict **child-directed** use in their own terms — a kids-primary LLM oracle is a second trap.

**Lock:** **Usage** may include a child with a parent. **Listing and Console:** **13+ / devotees / parents**. **Not** marketed as a kids’ app. **No Designed for Families in V1.** Standard AdMob. Do not put “for kids” on the feature graphic.

---

## 5. Deity-speech vs ads (“dakshina”)

**Finding:** “Speaks as Krishna” + rewarded “offer makhan to God” screenshots as selling a deity. Families policy (and common sense) flags **emotionally manipulative** ad pressure. Paid IAP blessing was dropped for budget **and** ethics.

**Lock:** He **speaks as Krishna**. Ads and the dakshina **icon** are **publisher Support**: watch an ad for extra questions / a blessing **animation**. He never asks for an offering. No Play Billing in V1. Copy must never say “Krishna received your offering.”

---

## 6. Crisis: playful vs dodge

**Finding:** “Be playful and avoid the topic” **contradicts** duty of care. Avoiding self-harm is how products fail users and attract news/Play scrutiny.

**Lock:** Playful **tone** is allowed. **Avoiding** crisis is not. No suicide jokes. No medical instructions. **On-screen helpline strip** remains visible. In-character lines may comfort and point to humans; the strip is the requirement.

**Helplines (India) — confirm at ship** (hours and numbers change):

| Resource | Official-ish starting point | Confirm |
| :--- | :--- | :--- |
| Emergency | **112** (national emergency) | Always |
| iCALL (TISS) | Site [icallhelpline.org](https://icallhelpline.org/) lists **9152987821**; TISS contact page lists **022-25521111** (telephone counselling; hours historically Mon–Sat) | Hours, numbers, languages on ship day |
| AASRA | Widely cited suicide-prevention NGO; **do not hardcode a number from memory** | Verify AASRA’s own site at ship |

Also: family / trusted adult. Do not invent extra numbers in UI copy without a source.

---

## 7. Gita: prompt vs full library

**Finding:** A system prompt cannot hold the Gita. Sending a full translation **every** Gemini call is worse (tokens = money + copyright). A scraped modern Gita in the APK is a legal and quality risk.

**Lock (Q29 A):** Short system prompt = persona + safety + **short thematic Gita summary in our own words**. Oracle does **not** retrieve a snippet library in V1. Daily card is a **separate** local JSON of 30–90 **original** paraphrases + `chapter.verse` cites. “Ask more” on the card may call Gemini. **Full-library-in-every-call (C)** is a **post-testing** experiment only.

---

## 8. Cost stack (solo)

**Finding:** Deepgram + Gemini + Cartesia + 1-free-question/day is anti-viral and anti-budget. Sub-900 ms across three paid streams was a fantasy NFR.

**Lock:** On-device **SpeechRecognizer** + **TextToSpeech** + **Gemini Flash** (AI Studio `.env`). No backend. **10** voice turns/day, then rewarded **+3–5**. Text fallback after mic-fail path is generous. Tighten the cap if the Gemini bill spikes.

---

## 9. Share video vs cloud

**Finding:** Viral “clip of Krishna saying my line” does **not** require cloud transcode or object storage. Android can mux a short MP4 on device and use the **system share sheet**.

**Lock:** V1 = **screenshot / daily card share**. **V1.1** = on-device 10–15s video. No V1 cloud video bill.

---

## 10. Language tensions

**Finding:** Hindi-first devotees vs “answer in the user’s language” vs Hinglish (STT usually Latin/English, no Hinglish TTS).

**Lock:** **hi + en only.** Default STT `hi-IN`. Gemini matches transcript. Hinglish Latin → Gemini Hinglish Latin + TTS `en-IN`. UI Hindi-first, English toggle. No third language.

---

## 11. Voice-only vs elders

**Finding:** Mic-only until “hardware death” hides the product when Hindi STT returns empty.

**Lock:** Voice-first. Text after **two** empty tries, permission/hardware failure, or **Type instead**.

---

## 12. Flutter keep / 3D drop

**Finding:** The repo is already Flutter + Bloc + `just_audio` + SceneView stub.

**Lock:** Keep Flutter. **Delete SceneView / Filament path** from the V2 architecture. Image `Stack` is the stage.

---

## 13. Daily card vs LLM freshness

**Finding:** Streak/share should not depend on Gemini (cost, delay, bad verse).

**Lock:** Curated JSON for the card. LLM only if the user taps **ask more** (and for the main oracle).

---

## 14. Historical docs

| File | Role |
| :--- | :--- |
| `Chibi_Krishna_AI_PRD.md` | v1.0 — 3D, Deepgram, Cartesia, IAP dakshina — **historical** |
| `Chibi_Krishna_AI_GitHub_Issues.md` | v1 sprint (Filament, etc.) — **historical** |
| `Chibi_Krishna_AI_PRD_v2.md` | **Build this** |
| `Chibi_Krishna_AI_GitHub_Issues_v2.md` | **Work this** |
