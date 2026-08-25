# Privacy Policy — Chibi Krishna AI

**Published version: `privacy-policy.html` in this same folder**, live at
<https://vageshwar.github.io/chibi-krishna/legal/privacy-policy.html> once this is merged into
`feature/sprint-1-foundation` (GitHub Pages is configured to serve `/docs` from that branch). This
`.md` file is the source-of-truth draft — **edit this file first, then port changes into the `.html`
version**, they're not auto-synced. Contact email is currently the placeholder
`privacy@vageshwar.dev` — swap for a real inbox (or a subdomain off `vageshwar.dev`, per the user's
stated future plan) whenever that's ready; not launch-blocking, just needs to actually receive mail
by the time this ships. Re-check this document against the code any time a new data-touching
feature ships (Gemini/FF-01, Firebase Analytics/FF-09, notifications/FF-08, referral/FF-07 are all
V1 additions not in the app yet, and each will need a line added here when they land) — don't let
this drift the way `PRD_v2.md` did.

---

**Effective date:** 25 August 2026

Chibi Krishna AI ("the app," "we," "us") is developed by Vageshwar. This policy explains what the
app does and does not do with your data.

## Quick summary

- No account, no sign-up, no name, no email, no phone number — the app doesn't ask for any of these.
- Your voice is processed by your device's own speech recognition to turn it into text; the app
  does not record, store, or transmit audio itself.
- The app shows ads (Google AdMob) and uses your device's advertising identifier for that.
- A small amount of usage data (how many questions you've asked today) is stored **only on your
  device** — never sent anywhere, gone if you uninstall the app.
- We do not sell your data. We do not have a server to store it on even if we wanted to.

## What the app does with your data, in detail

### Microphone / voice input

When you tap the microphone, the app uses your device's built-in speech recognition service
(Android's `SpeechRecognizer` or, on iOS during development, Apple's Speech framework) to convert
what you say into text. Depending on your device and its settings, that recognition may happen
entirely on-device or may involve your device manufacturer's own cloud speech service (this is
standard OS behavior, controlled by your device, not by this app). The app itself:

- does not record or store audio,
- does not transmit audio to any server we operate (we don't operate one),
- only receives the **text transcript** the OS hands back, which is used to pick a response and is
  not saved after your session ends.

You can always deny microphone access; the app falls back to a text input box instead.

### Advertising (Google AdMob)

The app shows a banner ad and, optionally, a rewarded video ad (to unlock a few extra questions
for the day, or to voluntarily support the app). These are served by Google AdMob, which uses your
device's advertising identifier (Android Advertising ID / iOS IDFA) to serve and measure ads,
including personalized ads where you've consented. See Google's own privacy policy for how AdMob
handles this data: <https://policies.google.com/privacy>. We do not receive or store your
advertising identifier ourselves — it's handled directly between your device and Google.

If you are in the EU, UK, or Switzerland, the app asks for your consent before showing personalized
ads, via Google's User Messaging Platform. You can decline; you'll still see ads, just not
personalized ones.

### Local usage data

The app keeps a small local record (on your device only, via SQLite) of how many voice questions
you've asked today and how many bonus questions you've earned from watching ads. This:

- never leaves your device,
- resets automatically at midnight,
- is deleted entirely if you uninstall the app.

### What we don't collect

No account or login. No name, email, or phone number. No location. No contacts. No photos or
files. No persistent profile of you as a user. No transcript of what you've said is stored beyond
your current session. We don't have a backend server, so there's nowhere for this data to be sent
even if the app wanted to send it.

## Children

Chibi Krishna AI is not designed for or directed at children, and is not part of Google Play's
Families program. It's positioned for a general audience 13 and older (devotees, parents, and
families), though a parent or guardian may of course choose to use it together with a child.

## Your choices

- **Microphone**: grant or deny at any time via your device's app permission settings; the app
  works without it (text input fallback).
- **Ad personalization**: controlled by your device's ad settings (Android: Settings → Privacy →
  Ads; iOS: Settings → Privacy → Tracking) and, for EEA/UK/Switzerland users, the in-app consent
  prompt.
- **Local data**: uninstalling the app removes everything stored locally.

Because we don't collect personal data or run a backend, there isn't a personal-data-deletion
request process beyond the above — there's nothing on a server to delete.

## Changes to this policy

If what the app collects or does changes (for example, when Gemini-powered responses or analytics
are added in a future update), this policy will be updated and the effective date above will
change.

## Contact

Questions about this policy: privacy@vageshwar.dev
