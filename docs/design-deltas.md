# Design deltas — where the design moved past the specs

The Claude Design work was built *from* `docs/`, but it ran ahead of the
documents in several places: it named things the specs left open, split
groupings the specs had lumped together, and invented screens and rules the
specs never listed. This file records those deltas so the build knows which
layer to trust.

**Rule of thumb: for anything in this list, the design is the newer decision.**
The underlying spec documents have not been rewritten — the deltas are recorded
here rather than silently applied, because several of them touch compliance and
the ledger and need a real sign-off, not an edit.

Imported 2026-08-17 from Claude Design project `012e55a7-8d3d-4aed-abf7-f1ab95fadf63`.

## 1. Nine categories, not six

[`categories.md`](categories.md) says "six categories at launch" and groups
plumbers, electricians and tilers under **Small trades**, plus **Event hire**.
The design carries nine named categories:

| Design | Was in `categories.md` |
|---|---|
| Rides | Rides |
| Movers & hauling | Movers & hauling |
| Property rentals | Property rentals |
| Hairdressing & beauty | Hairdressing & beauty |
| **Plumbing** | part of "Small trades" |
| **Electrical** | part of "Small trades" |
| **Tiling** | part of "Small trades" |
| **Catering** | "Home cooks / catering", not a launch category |
| **Hire** | "Event hire" |

Reasons recorded in the design project's sync log: no provider should be
labelled "small", and each trade carries its **own** KYC requirements, so they
cannot share one verification flow. Category count is explicitly no longer
fixed at six.

Per-category KYC requirements as the design has them:

| Category | Documents |
|---|---|
| Rides | Driving licence · Vehicle registration |
| Movers | Driving licence · Vehicle registration |
| Rentals | Proof of ownership · Property inspection |
| Beauty | Identity verification |
| Plumbing | Plumbing certification · Identity verification |
| Electrical | Electrical licence · Identity verification |
| Tiling | Proof of past work · Identity verification |
| Catering | Food handling permit · Identity verification |
| Hire | Proof of equipment ownership · Identity verification |

**Action:** `categories.md` needs rewriting, and the seeding order in
[`go-to-market.md`](go-to-market.md) recalculating against nine.

## 2. Money figures the specs left unset

[`monetization.md`](monetization.md) lists commission percentage, rental listing
price and minimum top-up as open. The design commits to two of them and adds VAT
handling the specs never described:

- **Ride commission — 8% of the fare.**
- **VAT — 14%, charged on the fee amount**, never on the customer's money.
  Every deduction posts as **two lines**, fee and VAT, never bundled into one
  opaque figure.
- Worked example the design uses throughout: a P120 ride → commission P9.60 →
  VAT P1.34 → P10.94 deducted. The driver keeps the full P120 in hand.
- Rental listing price and minimum top-up remain unset.

**Reversals** are specified in the design and absent from the specs:

- A cancellation **never** refunds itself. The balance does not move until a
  reversal is confirmed.
- The ledger carries a **reversal-pending row with no amount** — an amount would
  imply money already returned.
- A reversal **mirrors the deduction line for line** — fee back and VAT back,
  same figures, opposite sign, both referencing the original booking. Never one
  merged credit.
- The VAT reversal needs its **own credit-note entry**; it cannot vanish from
  the trail.
- Adjudication is an admin/desktop job. The phone shows status and reason —
  raised, under review, confirmed, declined — and **never a decision control**.

**Action:** this is ledger design. It should land in
[`payments.md`](payments.md) / [`monetization.md`](monetization.md) before the
ledger schema is written, and the 8% / 14% figures need confirming as decisions
rather than illustrations.

Still open, per the design:

- Who may raise a cancellation, and up to when after the fee posts.
- Whether some causes reverse automatically (verified no-show, ride cancelled
  inside the first minute).
- The review window a provider is told to expect — the copy has to name it.
- Partial reversals (a driver who travelled to a no-show has a real claim).
- Whether a provider can contest a declined reversal.

## 3. "Wallet balance", not "commission credit"

The original [design brief](../design/DESIGN-BRIEF.md) made this
non-negotiable: *call it "commission credit", never "wallet"* — on the grounds
that a wallet implies stored value and invites the wrong regulatory
characterisation.

The design reversed it, deliberately. It calls the balance **"wallet balance"**
because that is what a provider calls it, and defends the position differently:
no withdraw button, no "available balance" framing, no stored value to reclaim,
and the non-redeemable disclaimer sitting **on the balance card itself** rather
than in a footnote. The framing is "a meter, not an account".

Note this is consistent with [`monetization.md`](monetization.md), which already
says "wallet + commission" — it is the brief that was the outlier.

**Action:** this is the single delta most worth a compliance opinion.
[`compliance.md`](compliance.md) names the EPS Regulations 2019 question as
externally blocking; the naming choice is part of that same question. Do not
treat it as settled because the design settled it.

## 4. Screens the specs never named

The journey map derived screens from UC-1–UC-18, and found gaps. These exist in
the design and in no spec document:

**Entry** — Splash / first open · Auth gate sheet · Location permission ·
Biometric unlock · Consent capture

The reasoning: UC-4 gives Visitor browse rights, so the account wall belongs at
the **booking action**, not at launch. A stranger can see supply before being
asked for a number.

**Account & mode** — Mode switcher (two variants: already a provider, and not
yet a provider) · My categories (the per-category verification matrix) ·
Provider home

The mode switch has to exist **before** the first category is approved, or a
pending applicant has nowhere to check on it.

**Settings** — Settings · Biometric enrolment · Notifications · Data & storage ·
Appearance (Light / Dark / System)

## 5. Corrections the specs force, which the built screens got wrong first

Recorded in the design project's own sync log as fixes applied to earlier
mockups:

- **Payment precedes "mark complete"** (per activity diagram A-2 D2) — there is
  an `AWAITING_PAYMENT` state before `PENDING_CONFIRMATION`. Earlier screens had
  the provider marking complete first.
- **Structured service catalogue over free-text listing titles.**
- **New-provider boost belongs in ranking, not only in labelling** — the
  "New on Ipelege" chip is not on its own an answer to the Lynk problem.

## 6. The journey has three shapes, not one

Not stated this way anywhere in `docs/`:

| Shape | Categories | Difference |
|---|---|---|
| Browse & book · commission | Movers · Beauty · Plumbing · Electrical · Tiling · Catering · Hire | Stages 0–3 customer, 4–5 provider. Commission on completion. |
| Dispatch · commission | Rides | **Skips browse and listing detail entirely.** Request goes to nearby drivers with sufficient credit (FR-3.10). Live tracking is a launch requirement. |
| Pay-per-listing · no booking | Property rentals | **No booking, no commission, no completion.** Tenant enquires and leaves the app; landlord pays per room, per vacancy. |

Plus: the journey **does not end at a completed booking** — it re-enters
discovery in an adjacent category (stage 7). That is the ecosystem thesis and
the design gives it its own moment in the UI.

## 7. Per-category verification is a matrix, not a status

One account can hold, simultaneously: approved (listings live), pending review,
more info requested, rejected (can resubmit), and not applied — across five
different categories. The design treats this as **the normal case after a few
months, not an edge case**, so "provider" is never a single status anywhere in
the UI.

Sharpest unhandled case: revocation deactivates every listing under that
category immediately, and **what happens to bookings already accepted is
undefined in the spec** — so that state has no honest copy yet.
[`open-questions.md`](open-questions.md) should carry this.

---

## Import fidelity

### Truncated in import

The design MCP caps file reads at 256 KiB and the source page is larger, so
[`design/ipelege-design-system.dc.html`](../design/ipelege-design-system.dc.html)
is cut mid-way through the `stateMotion` data array. Everything up to that point
is intact — all markup, all screens, the palette, the categories and the
requirements map.

Lost from the tail, all of them specification tables rendered from data arrays
declared after `stateMotion`:

| Table | Rows | Where it renders |
|---|---|---|
| `stateMotion` (remainder) | 2 of 11 | Motion → booking states |
| `motionTokens` | 7 | Motion → token table (**recoverable** — the same seven are in the `class Motion` code block, which survived) |
| `motionSpecs` | 12 | Motion → every motion in the build |
| `backRules` | 11 | Navigation → what the system back button does, everywhere |
| `navState` | 6 | Navigation → what survives going back |
| `haptics` | 6 | Feedback → haptics |
| `loadingStates` | 6 | Feedback → loading bands |
| `savedStates` | 6 | Feedback → what gets kept |
| `palRows` | 12 | Light & dark → token comparison (**recoverable** — the full `PAL` object survived) |

To recover them, open the page in Claude Design and copy the tables, or export
the file from the project directly. They are worth recovering before the
navigation and feedback layers are built — `backRules` in particular is written
as a specification, not guidance.

### Not imported

The fourteen brand PNGs under the design project's `assets/` are not mirrored
into this repo. The import tool returns binary files base64-encoded through the
model's context, which is prohibitively expensive for images. Download them from
the design project directly when the app icon, splash and adaptive icon are
wired up:

```
adaptive-foreground.png    app-icon-dark-512.png    app-icon-light-512.png
appicon-dark.png           appicon-light.png        lockup-dark.png
lockup-h-dark.png          lockup-h-light.png       lockup-horizontal.png
logo-light-transparent.png mark-dark.png            mark-icon.png
mark-light.png             notification-icon.png    wordmark-dark-new.png
wordmark-dark.png          wordmark-light-new.png   wordmark-light.png
```

`support.js` (the Claude Design runtime shim) was also not imported — it is
generated tooling with no bearing on the Flutter build, and without the assets
the archived page would not render locally anyway. Treat the archived `.dc.html`
as a **text source of truth**, not a runnable page.
