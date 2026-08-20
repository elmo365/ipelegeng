# Build order

**This file decides what gets built next.** It is not a wish list and not a
backlog — it is an ordered sequence with dependencies, and each phase names what
must be true before the next one starts.

The spine is the design's own proposed order, stated at the end of the journey
map in [`design/ipelege-ds-1-foundations.dc.html`](../design/ipelege-ds-1-foundations.dc.html):

> close the account gap first → then the booking-status state set with the
> payment moment moved → then the loop prompt in stage 7 → then the provider
> management surface → then account & privacy

Two things are layered on top of that: a verification gate before any more
screens are built, and the admin pairings, so a flow and the back-office surface
that resolves it get built and tested together. A third was added once the
verification gate ran and found the app had no identity at all — see Phase 0.5.

**Enforcement.** `app/test/routing/build_order_test.dart` asserts that the
routes claimed built below actually render real screens, and that everything not
yet claimed still renders `PlaceholderScreen`. Marking something done here
without building it fails the suite, and so does building something without
recording it. Update the doc and the test together.

---

## Where each screen lives

**Do not build a screen without opening its artboard first.** Every phase below
names its screens by the label the canvas gives them, so the UI and the design's
own notes are one lookup away. Extracted from the `data-screen-label` attributes
on 2026-08-20 — 60 artboards, each rendered in both light and dark.

| Canvas | Artboards |
|---|---|
| [`ds-2-customer`](../design/ipelege-ds-2-customer.dc.html) | `SPLASH / FIRST OPEN` · `REGISTER · UC-1` · `SIGN IN` · `BIOMETRIC UNLOCK + PASSCODE FALLBACK` · `CONSENT CAPTURE · FR-1.10` · `AUTH GATE · UC-4` · `LOCATION PERMISSION` · `1 · ONBOARDING & OTP` · `2 · HOME` · `3 · CATEGORY BROWSE` · `4 · LISTING DETAIL` · `5–6 · BOOKING REQUEST / STATUS` · `BOOKING STATUS · 11 STATES` · `7 · RIDE REQUEST & TRACKING` · `8 · RATE & REVIEW` |
| [`ds-3-provider`](../design/ipelege-ds-3-provider.dc.html) | `MODE SWITCHER` · `MODE SWITCHER · CUSTOMER ONLY` · `9 · PROVIDER HOME` · `10 · MY CATEGORIES` · `11 · BOOKING INBOX` · `12 · WALLET` · `13 · TOP UP` · `14 · BECOME A PROVIDER` · nine `KYC ·` screens, one per category · `15 · CREATE LISTING` · `16 · RENTAL LISTING` |
| [`ds-4-specs`](../design/ipelege-ds-4-specs.dc.html) | `17 · ACCOUNT` · `18 · PREFERENCES` · `19 · SECURITY` · `20 · BIOMETRIC ENROLMENT` · `21 · NOTIFICATIONS` · `22 · DATA & STORAGE` · `21 · ARRIVAL ATTESTATION` |
| [`ds-1-foundations`](../design/ipelege-ds-1-foundations.dc.html) | No artboards — the journey map, the token definitions and the restyle rationale. It also carries each screen's own ✓ built / gap marker, which tracks **design** completeness, not this repo's. |
| [`admin-back-office`](../design/ipelege-admin-back-office.dc.html) | `A0` staff sign-in · `A0b` add staff user · `A1` queue board · `A2` verification queue · `A3` document review · `A4` reversal evidence · `A5` VAT and reporting · `A6` key statistics · `A7` responsive |

Two things in that index are the design's own inconsistencies, recorded rather
than silently corrected:

- **Two screens are numbered 21** — Notifications and Arrival attestation.
- **The booking-state count differs between canvases.** The journey map in
  foundations enumerates ten; the artboard is titled `BOOKING STATUS · 11 STATES`
  and `design-system.md` lists `AWAITING_PAYMENT` as the eleventh. Eleven is
  right — the map's list omits the payment step, which is exactly the step the
  design moved. Phase 2 builds eleven.

---

## Phase 0 · Look at what exists — **done 2026-08-20**

All five built screens were run on a Pixel 9a emulator in both modes and
compared against the canvas: consumer home, category browse, listing detail,
provider dashboard, wallet.

**The colour tokens hold.** Sampled pixels match `AppPalette` exactly — dark page
`#050B0F`, card `#171F25`, nav `#11171C`; light card and nav pure white on the
`#EDF3F8` page. The `PAL` recovery was right, and the dark mode that had never
been displayed renders as specified. Surface treatment, radii, icon plates and
the raised nav sheet all read as designed.

> **Phase 0's verdict was too narrow, and is corrected here.** It checked
> *colour* against the canvas and nothing else, because it was run against
> extracted slices of the design rather than a full reading of it. Motion was
> never compared at all — and when the whole design was finally read end to end,
> every duration in `theme/motion.dart` turned out to be wrong. A gate that only
> samples pixels is not a gate on "renders as designed".
>
> The root cause was in this repo, not in the reading: `design-system.md`
> carried **two `## Motion` sections** that disagreed, because the resync
> appended the recovered canvas table instead of replacing the stale block. The
> stale one held a `Motion` class code listing, so it read as the authority, and
> that is what got implemented. Four further contradictions surfaced with it —
> see [`design-deltas.md`](design-deltas.md) §14.
>
> **Phase 0 now also requires a motion pass**, not just a colour pass: every row
> of the transition table checked against what the app actually does.

Three drifts, all written up in [`design-deltas.md`](design-deltas.md) §13:

- **Fixed:** the supply count was ellipsised on every thin category
  (*"New in Gaborone · 6 plum…"*), hiding the number the tile exists to state.
- **Recorded:** the tile's off-grid literals (20 px radius, 14 px padding,
  38 px plate) against our token scale. ≤ 2 dp, deliberately not tokenised.
- **Recorded:** the canvas and this repo use inverted shadow vocabularies —
  `pal.shCard` is our `shadowRow`, `pal.shRaise` is our `shadowCard`. Read the
  mapping table in `tokens.dart` before "correcting" a surface depth.

**And one thing the screenshots made obvious that no screen review would have:**
the app has no identity at all. Stock Flutter launcher icon, a white window
flash on every cold start, no mark anywhere. See Phase 0.5.

---

## Phase 1 · Brand — **the design's own first foundation**

The canvas orders Foundations as **Brand → Colour → Type → Components**, and
only then screens. This phase is numbered accordingly rather than bolted on:
brand is the first thing the design defines, and the app shipped five screens
with a stock Flutter icon because the build order here did not mirror that.

**Done:** launcher icon at five densities, adaptive icon with a `<monochrome>`
layer for Android 13 themed icons, the mark in-app, the notification artwork,
and the cold-start window painting the palette's `screenBg2` instead of the
stock white/black flash.

**Blocked, and not by cost:** the wordmark and both lockups exceed the 256 KiB
`get_file` cap and come back truncated. Full detail, including the two distinct
ways an asset gets corrupted and the guard against each, in
[`identity.md`](identity.md).

Nothing here fabricates a substitute mark — the canvas is explicit that a
previous set assembled from mixed exports lost the ripple rings and the blue
*i*, and inventing one would repeat exactly that.

---

## Phase 1b · Identity leftovers — **does not gate the flows**

The brand artwork is fully designed and has never been in this repository. The
canvases render twelve PNGs from an `assets/` folder that only exists in the
design project, so every `<img>` in `design/*.dc.html` points at nothing.

Done already, because it needed no artwork: the cold-start flash is gone — the
launch window now paints the palette's `screenBg2` per mode instead of
`?android:colorBackground`, which resolved to plain white and plain black.

Still waiting on the export: launcher icon, adaptive icon, splash artwork, the
notification icon, and the lockup that Phase 1's splash / register / sign-in
screens render.

**Full detail, and the test that keeps it honest, in
[`identity.md`](identity.md).** Nothing here fabricates a substitute mark — the
canvas is explicit that a previous set assembled from mixed exports lost the
ripple rings and the blue *i*, and inventing one would repeat that.

**Why it does not gate Phase 1:** the account flows are structure, validation
and state, none of which need the logo. Build them with the mark's slot left
empty and drop the artwork in when it arrives. What it *does* gate is any claim
that Phase 1 is finished.

---

## Phase 1 · The account gap — **built 2026-08-20**, artwork outstanding

Splash · Register · Sign in · OTP · Biometric unlock with passcode fallback ·
Consent capture · Auth gate · Location permission

Design: `ipelege-ds-2-customer.dc.html`.

**Why first, beyond the design saying so:**

- **The auth gate is a dependency of Phase 2.** It sits at the booking action,
  not at launch, so booking request cannot be finished without it. Building
  booking first means building it twice.
- **Consent is a Must** under FR-1.10 and the DPA, and it is versioned — a
  superseded version forces re-consent before anything else proceeds. That
  cannot be retrofitted around an existing session model.
- Everything built so far is reachable with no account. That is *correct* for
  browse (UC-4 grants visitors browse and search) and wrong for everything past
  it. It has not bitten yet only because nothing past it exists.

**Watch:** OTP on every fresh login; the session then persists until explicit
logout. Biometry *unlocks*, it never authenticates — a new device or reinstall
goes back through phone + OTP. Passcode is a full card of equal weight, not fine
print, because broken or absent sensors are common on the target hardware.

**Blocked within this phase:** splash, register and sign in all render the
lockup, and the artwork does not exist here yet (Phase 0.5). The flows are
built with the mark's slot held by `BrandLockup`, which sets the name as type
and says in its own doc comment that it is not the logo.

**Done when:** a cold install can register, verify, consent, and reach Home; a
returning user can sign in; a visitor can still browse without an account and is
stopped at the booking action.

### What landed

Seven routes, all outside both shells so a tab cannot escape the flow:
`/welcome`, `/register`, `/sign-in`, `/verify`, `/consent`, `/unlock`,
`/location`. The auth gate is deliberately **not** a route — it is a sheet over
the listing, because refusing it must not cost the visitor their place.

`core/session.dart` holds the rules as states rather than as habits: OTP is
unskippable because nothing reaches `active` without passing through
`confirmingNumber`; `canBook` is false on a superseded consent version, so
re-consent is a state and not a prompt someone remembers to show; `lock()` does
nothing to a session that was never active, so biometry can only ever *unlock*.

Verified on a Pixel 9a in both modes. Two bugs the widget tests caught that a
reading would not have:

- The gate was pushed onto the tab's Navigator, whose pages go_router manages
  declaratively. Dismissing it re-synced the router and **took the listing down
  with it** — a visitor who declined lost the page they were looking at. It now
  uses the root navigator.
- `EntryHeader` sat in a `Column`, which centres on the cross axis, so the
  gradient band was only as wide as its own text. Invisible on register with its
  two-line subtitle; obvious on verify with its four words.

### What is still missing — corrected 2026-08-20

Phase 1 was recorded as built. Reading the whole design showed it is not, and
the gaps are in the design's own text, not in interpretation:

- **Biometric enrolment is a screen and it does not exist.** Part 4, screen 20:
  *"Offered once after first OTP, declinable without penalty"* — a fingerprint
  glyph, "Skip the code next time?", two reassurance cards (*"Stays on this
  device only"*, *"Ipelege never sees your fingerprint"*), and
  **Turn on biometric unlock** / **Not now**. Without it there is no path by
  which `/unlock` is ever reachable, which is why the screen could be built and
  the omission not noticed.
- **The OTP screen has one state; the design names about ten.** Part 1 lists
  them: code sent · wrong code · resend cooling down · locked after N attempts ·
  number already registered → sign in · consent declined → cannot proceed ·
  returning to a live session → biometric prompt · biometry unavailable or
  refused → passcode · new device or reinstall → full phone + OTP · signed out
  explicitly → back to sign in. Built: the happy path and resend cooling down.
- **Consent supersede is modelled but not enforced.** `Session.canBook` returns
  false on a stale version, and nothing routes that session to `/consent`. The
  design requires the gate to *force* re-consent "before anything else
  proceeds".
- **Back is not blocked during the OTP round trip**, which the navigation rules
  state outright. *(Fixed 2026-08-20.)*

**Still open, and known since it was built:** biometry and the passcode are
wired to the session but not to the platform — both buttons call `unlock()` and
no `local_auth` prompt is shown yet. The screen, the states and the fallback's
visual weight are right; the sensor is not connected.

---

## Phase 2 · Booking, with the payment moment moved — stage 3

Booking request · Booking status (11 states) · Rate & review

Design: `ipelege-ds-2-customer.dc.html`. Depends on Phase 1 (auth gate).

**The correction this phase exists to carry:** payment precedes "mark
complete". Activity diagram A-2 orders it *service delivered → customer pays the
provider directly → provider marks complete → customer confirms → commission
posts*. Earlier mockups had the provider marking complete first. The pay-directly
moment gets the hero treatment because it is the one thing that must not be
misread.

**Not in this phase, and deliberately:** `DISPUTED` and `NO_SHOW` have no honest
copy yet — see Blocked below.

**Done when:** all 11 states render with their own copy, tone and single primary
action, and the payment step sits at position 4.

---

## Phase 3 · The loop prompt — stage 7

Cross-category prompt · Rental enquiry → movers handoff

Design: `ipelege-ds-1-foundations.dc.html` (journey map, stage 7).

**Why this early.** It looks like a cross-sell banner and is not: it is the
ecosystem thesis. One acquired user is supposed to produce several transactions
across several categories, which is the entire argument for launching with nine.
The design puts it third for that reason, and it is cheap once booking exists.

**Watch:** suppress the prompt when the adjacent category is thin — do not
prompt someone into an empty room — when they have already booked it, or when
the provider in the adjacent category is the same person.

---

## Phase 4 · Becoming a provider, paired with the admin queue

**Mobile:** Become a provider · per-category KYC (nine) · Verification status
**Admin:** Queue board · Verification changelist · Document review

Design: `ipelege-ds-3-provider.dc.html` and
[`admin-design.md`](admin-design.md).

**This is where the backend starts.** It needs a Django project on `/staff/*`
and the `PROVIDER_CATEGORY`, `ADMIN_ACTION` and `DOCUMENT_ACCESS` models. The
Postgres instance is already running (see `HANDOFF.md`).

**Why these two halves ship together:** a KYC submission with nowhere to be
reviewed cannot be tested end to end, and a review queue with nothing in it
cannot either. This is also the pairing that exercises the rule that matters
most on the admin side — *no admin surface may write to a field where a state
transition exists for it* — and the one that proves an admin approval and an
automatic approval produce byte-identical state.

**Done when:** a provider can apply in a category from the phone, a reviewer can
approve / reject / request-more-info from `/staff/`, every document view writes a
`DOCUMENT_ACCESS` row, and the phone shows the reviewer's verbatim reason.

---

## Phase 5 · The provider management surface

Mode switcher (both variants) · My categories · Booking inbox · Top up ·
Create listing · My listings

Design: `ipelege-ds-3-provider.dc.html`. Depends on Phase 4 for an approved
category to manage.

**Watch:** top-up comes before create-listing in practice — with an empty wallet
accepting is blocked (FR-5.10), so a provider who lists first hits a wall on
their first job. Listings need a **structured catalogue**, not a free-text
title: default to fixed or from-pricing with instant booking and treat "quote on
request" as the exception, because quote-based flows were a major failure point
at Lynk.

---

## Phase 6 · Money operations, paired with admin finance

**Mobile:** EFT reference & pending states
**Admin:** Unmatched deposits · Reversal evidence view · VAT and the tax period

Depends on the ledger schema. One wallet per provider —
see [`wallet.md`](wallet.md).

**Why the pairing:** an unmatched EFT deposit is named in the design as *the
failure most likely to lose a provider permanently*, and a reversal under review
has no exit without someone deciding it. Neither half is testable alone.

---

## Phase 7 · Account and privacy — stage 6

Account · Preferences · Security · Biometric enrolment · Notifications ·
Data & storage

Design: `ipelege-ds-4-specs.dc.html`.

These are **Musts** under the DPA (FR-1.8, FR-1.9, UC-16), not settings polish.
Deletion has to keep the financial ledger intact while removing personal data,
which needs its own confirmation copy.

---

## Blocked — not scheduled, and not to be started

The design is explicit that these have **no honest copy** until a product
decision lands, and writing placeholder copy for them is worse than leaving them
out:

| Blocked | Waiting on |
|---|---|
| `DISPUTED` booking state, dispute flow (UC-13) | Dispute turnaround time — screens promise contact but name no timeframe |
| `NO_SHOW` booking state | No-show consequence for providers — what happens, and after how many |
| Cancellation fee copy | Late-cancellation fee amount — percentage, flat, or first-occurrence waiver |
| Admin **Revoke** action | What happens to already-accepted bookings when a category is revoked |
| Per-category commission display | Whether trades and rentals differ from the ride 8% |

Also unbuilt because undesigned, not blocked: customer↔provider messaging
(referenced from several screens, no thread UI exists), provider listing
management at scale, and empty/offline states across the journey.

---

## Where things stand

**Entry (Phase 1):** splash · register · sign in · OTP · consent · unlock ·
location, plus the auth gate as a sheet.

**Built earlier, to validate the resynced tokens:** consumer home · category
browse · listing detail · provider dashboard · wallet.

Twelve shared components. **147 tests**, `flutter analyze` clean, and every
built screen seen rendered on a device in both modes.

Everything else renders `PlaceholderScreen`, which is deliberate — the
navigation graph stays complete and testable while screens land one at a time.

**Next action: Phase 2**, booking with the payment moment moved. Phase 0 is
closed. Phase 0.5 is blocked on an artwork export and runs alongside rather
than in front; Phase 1 is built but is not *finished* until the lockup and the
biometric prompt land.
