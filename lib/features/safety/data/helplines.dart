/// FF-03 crisis strip constants — kept in one file so every number is a
/// single ship-day edit. Verified 2026-09-16 against each org's own site —
/// see PR description/commit for sources — but re-check before any future
/// ship if this file hasn't touched in a while; numbers and hours can
/// change without notice, per CLAUDE.md and PRD v3 §9.
class Helplines {
  const Helplines._();

  static const String indiaEmergencyLabel = 'India Emergency: 112';

  // KIRAN — Ministry of Social Justice & Empowerment's mental health
  // rehabilitation helpline. Toll-free, 24x7, 13 languages — the right
  // primary line for a crisis strip that can trigger at any hour.
  static const String kiranLabel = 'KIRAN Mental Health Helpline (24x7): 1800-599-0019';

  // iCALL (TISS) — free psychosocial counseling, but NOT 24x7: Mon-Sat,
  // 10am-8pm IST only. Hours are stated so the strip doesn't point someone
  // in crisis at 2am to a line that won't pick up.
  static const String counselingLabel = 'iCALL Counseling (Mon-Sat, 10am-8pm): 91529 87821';

  static const String familyPrompt = 'Please talk to family or someone you trust.';
}
