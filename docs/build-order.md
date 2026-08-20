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
that resolves it get built and tested together.

**Enforcement.** `app/test/routing/build_order_test.dart` asserts that the
routes claimed built below actually render real screens, and that everything not
yet claimed still renders `PlaceholderScreen`. Marking something done here
without building it fails the suite, and so does building something without
recording it. Update the doc and the test together.

---

## Phase 0 · Look at what exists — **current gate**

Nothing else starts until this is done.

- Run the app on a handset or emulator.
- Check the surface treatment renders as designed in **both modes**: tinted
  page, shadows in place of borders, 13/18/22/26 radii, category icon plates,
  the raised nav sheet.

**Why it gates everything:** five screens and six components were built against
tokens that have only ever been seen by the widget tester. Dark mode in
particular was rewritten wholesale when `PAL` was recovered and has never been
displayed. Building ten more screens before looking is how a token error gets
copied ten times.

**Done when:** a screenshot of home and wallet in both modes has been compared
against the canvas, and any drift is either fixed or recorded in
[`design-deltas.md`](design-deltas.md).

---

## Phase 1 · The account gap — stage 0–1

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

**Done when:** a cold install can register, verify, consent, and reach Home; a
returning user can sign in; a visitor can still browse without an account and is
stopped at the booking action.

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

Built: consumer home · category browse · listing detail · provider dashboard ·
wallet. Six shared components. 97 tests.

Everything else renders `PlaceholderScreen`, which is deliberate — the
navigation graph stays complete and testable while screens land one at a time.

**Next action: Phase 0.**
