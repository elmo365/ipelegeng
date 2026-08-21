# Corrections for the design side

**Things the canvas needs that it does not currently have.** This file goes
*back* to Claude Design; it is a work list for the design project, not for this
repository.

Keep it distinct from [`../docs/design-deltas.md`](../docs/design-deltas.md),
which records the opposite direction: where **this repo** departs from the
design and why. A delta is a decision already made here. A correction is
something only the design can supply.

Each entry says what is missing, why it is needed, and what the build is doing
in the meantime so the two do not silently diverge.

---

## 1. Profile photos do not exist anywhere in the design

**Raised 2026-08-21.** The Account artboard (`ds-4-specs`) renders the user as
the initials **"KM"** on a tinted plate. That is the *fallback*, and it is the
only state drawn — there is no avatar, no upload control, no change or remove
action, and no photo on any other screen. Searching all five canvases for
"photo" returns listing photos, KYC documents and the data-and-storage
settings; nothing about a person's own picture.

**Why it matters more here than on most products.** Ipelege's central argument
is that a provider is a verified real person you are about to let into your
yard. A provider row that can only ever show two letters is a weaker version of
that claim than it needs to be, and the customer side has the same gap in
reverse — a driver picking up a passenger sees initials.

**What the design needs to add:**

- The **Account** screen's avatar in all three states: photo set, initials
  fallback, and mid-upload.
- The **change flow** — take a photo, choose from library, and **remove**.
  Remove must be a first-class action, not buried: a face is personal data and
  UC-16 gives the user the right to take it back.
- Where a photo **surfaces**: provider row on booking status, listing detail,
  the provider's own dashboard header, the mode switcher, and the ride screens
  where driver and passenger identify each other.
- The **moderation state.** A photo is user-supplied content on a platform that
  verifies people. If a photo can be rejected, there is a state for that and it
  needs copy.

**What the build does meanwhile:** initials only, everywhere, which is what the
canvas draws. No placeholder avatar is invented — the same rule the brand mark
follows, and for the same reason: a made-up stand-in is harder to remove later
than an empty slot.

**Related:** this is also a compliance surface. Deletion under UC-16 must
remove the image from object storage as well as the row, and the retention
question belongs with the KYC retention one already open.

---

## 2. "Keep the screen on during a ride" is not a preference on any screen

**Raised 2026-08-21: "for rides it's a critical part."**

A passenger watching a driver approach and a driver following a route are both
looking at a screen they are not touching, which is exactly the condition a
handset's display timeout ends. A default Samsung timeout is 30 seconds. This
is not a nicety; without it the ride screens are unusable.

Android needs **no permission** for this — it is a window flag — which means
the *user's* control over it only exists if it is deliberately designed. It is
not currently on the Preferences artboard, whose rows are Appearance,
Notifications (SMS / WhatsApp / Push) and Data (Location, downloads).

**What the design needs to add:** a row under a new or existing group —
*"Keep the screen on during a ride"*, default on, with a sub-line that admits
the cost in words a user on a failing battery would want. And a decision on
whether the default is right, which is recorded as an open question in
[`../docs/device-permissions.md`](../docs/device-permissions.md).

---

## 3. How an incoming ride reaches a driver who is not in the app

The incoming-ride moment is **well** specified — a sheet rising in 180 ms, a
ringtone, the one heavy haptic in the app, and the only looping animation
allowed anywhere. What is not specified is how that moment arrives when the
driver's phone is showing WhatsApp, or is locked.

That is three different designs on Android, and they are not interchangeable:

- a **full-screen intent** notification that takes over the screen,
- a **draw-over-other-apps** overlay, which the user must grant by hand in
  Settings and which Play Store scrutinises,
- a **foreground-service** notification that persists for the whole on-duty
  shift and is the only honest way to say "your location is in use".

**What the design needs to add:** the on-duty toggle and what it promises; the
permission-priming screen or sheet that explains *before* sending someone into
Android Settings; the locked-screen appearance of an incoming request; and the
degraded path when the permission is refused. The trade-offs and the platform
constraints are written up in
[`../docs/device-permissions.md`](../docs/device-permissions.md) so the design
does not have to rediscover them.

---

## 4. The Security screen promises an OTP that no longer happens

**Decided 2026-08-21.** Screen 19 (Security) tells the user that turning
biometric unlock off means *"an OTP every time the app is opened"*, and the
build did that until now.

The rule was dropped because the check is ineffective, not because it is
expensive: an SMS code proves possession of the SIM, and on a reopen the SIM is
inside the handset the person is holding — so against the stolen-phone threat
it exists for, the code reaches the thief too. The device credential is the
only proof a thief lacks. Full reasoning in
[`../docs/design-deltas.md`](../docs/design-deltas.md) §20.

**What the design needs to change:**

- The Security screen's biometric-unlock sub-line. Off no longer means an OTP;
  it means the device passcode instead of a fingerprint. Both still land on the
  same locked screen.
- A state for **a handset with no screen lock at all**, which now goes through
  a fresh sign-in because there is no credential to check. Currently undrawn.
- Wherever onboarding explains what biometric unlock is *for*, since it is now
  a choice between two device credentials rather than a choice between a
  credential and a code.

**Nothing shipped is wrong today** — Security is Phase 7 and unbuilt. The
artboard is what needs correcting, before it is built from.

---

## 5. Carried — already known, still outstanding

| | |
|---|---|
| **Four brand cuts exceed the 256 KiB fetch cap** | `mark-dark`, `wordmark-dark-new`, `lockup-dark`, `logo-light-transparent` truncate silently. Export them from the design project or re-save smaller. Detail in [`../docs/identity.md`](../docs/identity.md). **This is the oldest item here.** |
| **Two screens are numbered 21** | Notifications and Arrival attestation. |
| **The dispute flow is undrawn** | The `DISPUTED` *state* is built and shipping the design's own provisional note. The flow that reaches it does not exist. |
| **Customer ↔ provider messaging** | Referenced from several screens; no thread UI anywhere. |
| **Empty and offline states** | Not drawn for any screen in the journey. |
| **The loop prompt has no artboard** | Specified as behaviour, marked `gap`. Three of its four copy pairs are ours, flagged as derived in `core/loop_prompt.dart` so a later canvas can replace them cleanly. |

---

## How to use this file

When the design supplies one of these, move it out of here and into
[`../docs/design-deltas.md`](../docs/design-deltas.md) if the build had to
depart from it in the meantime, or simply delete the entry if the build can
adopt it directly. An entry that stays here indefinitely is a decision nobody
has made, and it should end up in
[`../docs/open-questions.md`](../docs/open-questions.md) instead.
