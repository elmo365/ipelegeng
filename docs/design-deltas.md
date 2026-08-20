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

**Fully re-pulled 2026-08-20** from Claude Design project
`012e55a7-8d3d-4aed-abf7-f1ab95fadf63`. The previous local snapshot was
**discarded rather than merged**, so `design/` contains only what the project
returns today and nothing in it is a blend of two vintages. The project had
moved three times since the first import (2026-08-18 ×2, 2026-08-19).

§§1–7 are from the original import and still hold. §§8–12 are what the re-pull
found — and it was more than a retint: the surface, the component set, the
category hues and three journey rules all moved.

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

## 8. Surface treatment — the design restyled itself

Added in the 2026-08-20 resync. Between 2026-08-18 and 2026-08-19 the design
audited its own screens against current app work, concluded they read "correct
and joyless — a form, not a product", and committed to a new surface. Twenty
existing screens were migrated to it; both modes moved together.

This is **not** a flow, copy or rule change. Identical content, identical wallet
rules — only the surface moved. But it invalidated most of the geometry and
several colour tokens the Flutter shell was built on, so it is recorded here.

| | Before | After |
|---|---|---|
| Page | `#ffffff` | `#EDF3F8`, tinted, so white cards float |
| Card separation | 1 px grey border | blue-tinted shadow, **no border** |
| Radii | flat 10–14 | 26 hero / 22 card / 18 row / 13 icon plate / 15 button |
| Blue | link text and one navy card | full gradient hero carrying its own actions |
| Category identity | 3 px bar + grey monogram | Material Symbol on a tinted plate of the category hue |
| Numbers | `"4 jobs"`, `"P48.94"` | seven-bar week chart with a delta pill |
| Nav | hairline strip | raised sheet, 26 px top radius, tinted active pill |
| Ledger | flat rows | one card per entry, VAT on a dashed tie-line to its parent fee |
| Text ink | `#111111` | `#0D2436` |

Full token table in
[`design-system.md#surface-treatment`](design-system.md#surface-treatment).

**Action: done.** `app/lib/theme/tokens.dart`, `dimens.dart`, `app_theme.dart`
and `ui/components/category_tile.dart` were resynced on 2026-08-20.

## 9. Category hues respread across the wheel

The nine hue angles changed, and this one is easy to miss because the category
*list* did not. The old set was clustered in the blue-teal band (155–265), so
nine categories rendered as nine near-identical blues. The design respread them
across the full wheel:

| Key | Old hue | New hue | Icon |
|---|---|---|---|
| `rides` | 230 | 230 | `directions_car` |
| `movers` | 205 | 205 | `local_shipping` |
| `rentals` | 255 | 255 | `meeting_room` |
| `beauty` | 215 | **330** | `content_cut` |
| `plumbing` | 245 | **180** | `plumbing` |
| `electrical` | 265 | **85** | `electrical_services` |
| `tiling` | 185 | **40** | `grid_view` |
| `catering` | 195 | **25** | `restaurant` |
| `hire` | 155 | **300** | `chair` |

Construction also changed: the tile plate is `oklch(0.95 0.035 <hue>)` with the
icon in `oklch(0.5 0.13 <hue>)`, rather than one solid `oklch(0.55 0.12 <hue>)`
square. **Action: done** in the same resync.

## 10. The wallet-naming reversal has reversed again — on paper only

[§3](#3-wallet-balance-not-commission-credit) records the design overriding the
brief's "commission credit, never wallet".

The design project's own standing instructions (`CLAUDE.md` in the project, not
in this repo) now say the opposite again: *"Commission credit", never "wallet"
(regulatory)*. But **no screen follows it.** The current canvas says "wallet
balance" throughout — in the five-decisions preamble ("The wallet balance is a
meter, not an account. It is called the wallet balance, plainly, because that is
what a provider calls it"), on the balance card, and in the header strip. The
back-office canvas uses neither term.

So the rendered design and this repo agree, and the standing instruction is the
outlier. Treat "wallet balance" as current, keep
[`wallet.md`](wallet.md) as written, and note that the contradiction is a
restatement of the same unresolved compliance question — not a new decision.
**Action: unchanged — still the delta most worth a compliance opinion.**

## 11. The component set was rebuilt, not just retinted

Easy to miss behind the surface change, and worth its own entry: the components
sheet went from **four groups to seven**, and three of the seven did not exist
before.

| Group | Then | Now |
|---|---|---|
| Buttons | 4 — primary, secondary, text, disabled | 6 — **Accept and Decline added** as a pair |
| Input | phone field only | phone field **plus a priced field with an error state** |
| Status signals | 2 chips, tone only | 4 chips, **each pairing a hue with a glyph** |
| Money row | — | **new** |
| Category tile | one tile, grey monogram | all nine, Material Symbols on tinted plates |
| Nav active pill | — | **new** |
| Toggle & stepper | — | **new** |

The rules that came with them:

- **Never two blue buttons side by side.** Accept is success green, decline is a
  danger-toned outline; the pair has to be readable at a glance. Shipped as one
  component (`DecisionPair`) so the rule cannot be half-applied.
- **Status never depends on colour alone** — `verified_user`, `hourglass_top`,
  `error`. The "New" chip is the one tone with no glyph, and it moved off the
  grey neutral onto the tinted blue plate so it reads as information rather than
  as a disabled state.
- **VAT nests under its parent fee** on a dashed rule with a stub, in the
  compact money row as well as in the full ledger card.

**Action: done.** `status_chip.dart`, `money_row.dart`, `stepper_bar.dart`,
`decision_pair.dart` and the raised nav sheet in `app_shell.dart`.

## 12. Three journey rules the screens have to enforce

Stated in the journey map rather than in a component, and each one changes
behaviour rather than appearance:

1. **Property rentals never offers a booking.** Pay-per-listing: no booking, no
   commission, no completion — the tenant enquires and leaves the app. A
   "Request booking" button on a rental promises a flow that does not exist.
   Modelled as `JourneyShape` on `CategoryToken`.
2. **New providers need a real boost, not just honest copy.** The repo's own
   recommendation is to build ratings *with* an explicit new-provider boost,
   or you manufacture provider churn. Labelling someone "New on Ipelege" is
   half the fix; placement in browse is the other half.
3. **Payment precedes "mark complete."** Activity diagram A-2 orders it:
   service delivered → customer pays the provider directly → provider marks
   complete → customer confirms → commission posts. The design has moved the
   pay-directly moment to step 4 of the booking status set. Not yet built —
   the booking status screen is outstanding.

**Action: 1 and 2 done. 3 lands with the booking status screen.**


---

## Import fidelity

### The canvas was split — nothing is truncated any more

**Resolved 2026-08-20.** The mobile page was split in Claude Design into four
files, each comfortably under the 256 KiB read cap:

| File in `design/` | Size | Contents |
|---|---:|---|
| `ipelege-ds-1-foundations.dc.html` | 144 KB | Five decisions, journey map, brand / colour / type / components, visual direction |
| `ipelege-ds-2-customer.dc.html` | 93 KB | Entry & account, onboarding, home, browse, listing detail, booking, tracking, rate & review |
| `ipelege-ds-3-provider.dc.html` | 136 KB | Mode switcher, provider home, my categories, inbox, wallet, top up, become a provider, KYC |
| `ipelege-ds-4-specs.dc.html` | 101 KB | Account / preferences / security / notifications / data, cancellation & attestation, light & dark, the nine-category matrix, navigation, motion, feedback, **and `PAL`** |

485 KB total, against the 262 KB the single-file read returned — **85% more
content**, and every part came back `truncated: false`.

What that recovered, all of which the previous entry listed as lost:

- **`PAL`, post-restyle, both modes.** See below — it corrected real errors.
- **The navigation / back-button rules**, the state-restoration list, the motion
  table, haptics and the loading/saving rules. They no longer exist as the named
  data arrays (`backRules`, `motionSpecs`, `haptics`…) the earlier import
  recorded — the design rebuilt them as prose sections, which is why searching
  for the array names finds nothing. Recorded in
  [`design-system.md`](design-system.md).
- **Six more screens** — Account, Preferences, Security, Biometric enrolment,
  Notifications, Data & storage — plus arrival attestation and the
  nine-category customer/provider matrix.
- **The `CATS` array**, which corrected the supply model (below).

### `PAL` corrected four things that had been inferred

The palette had been reconstructed from the mockups. Reading the real object
showed where that went wrong:

| | Inferred | Actual |
|---|---|---|
| The page | `screenBg` = `#EDF3F8` | **`screenBg2`** = `#EDF3F8`; `screenBg` stayed white |
| `divider` | `#DDE2E6` | `#E9F0F5` |
| `inputBorder` | `#BFC5CA` | `#DCE7EF` |
| `chipNeutralBg` | `#DDE2E6` grey | `#E1EDF5` tinted blue |
| Dark surfaces | hue 250, carried from pre-restyle | **hue 235**, cooler and bluer |
| Dark shadows | blue-tinted, low alpha | **black**, higher alpha |

The token names now match the design's own, so a future sync diffs directly.
`navPillBg` is the only remaining derived value — it is an inline literal in the
canvas rather than a token, so it has no published dark form.

### Supply is two states, not three

The `CATS` array carries `supply: 'ok' | 'thin'`. The three-level
`HEALTHY / THIN / CRITICAL` scale belongs to the **back office**, where an
operator needs to know where to go recruiting. The app collapses it, because the
customer-facing job is different: a category with two providers and one with
four are the same thing to someone deciding whether to tap.

And the copy is the decision, not the number. Thin categories read
**"New in Gaborone · 2 providers"**, never "2 nearby" — young rather than
failing. Six of the nine are thin at launch, which the design calls the design
condition rather than an edge case: seeding goes deep rather than wide, so most
categories look new for months.

### Superseded: the single-file pull

The notes below described the state before the split, when the monolithic
canvas cut mid-`KYC Movers & hauling`. Kept only so the constraint is on record:
**the 256 KiB cap is server-side on `get_file`, with no range or pagination**, so
splitting had to happen in Claude Design — the repo could not initiate it,
because reading the tail was the very thing being blocked.

Each screen label still renders in **both light and dark**, so ~25 labels is
roughly fifty mockups.

### The token contract, as the fresh canvas binds it

Thirty tokens, extracted from the fresh pull rather than assumed:

```
accentText cardBg cardBorder chipNeutralBg chipNeutralText creditColor
dangerBg dangerText divider inputBg inputBorder navBg navMuted
notUploadedBg notUploadedText pendingBg pendingText screenBg screenBg2
sectionAlt selectedBg shCard shNav shRaise subtleBg textFaint textMuted
textPrimary textSecondary verifiedBg verifiedText
```

Two things this settles:

- The design names **three** shadow tokens — `shCard`, `shRaise`, `shNav` —
  matching the three depths its own prose describes (20 on cards, 28 on the
  hero, and the upward nav cast). The 14 px row shadow and the coloured button
  shadows are inline literals, not tokens.
- `stripe1`, `stripe2` and the `info*` set are **no longer bound anywhere**.
  They remain in `AppPalette` unused; retire them when something confirms they
  are gone for good rather than merely unused on the 25 screens we can see.

### The back office came through complete

[`design/ipelege-admin-back-office.dc.html`](../design/ipelege-admin-back-office.dc.html)
is 171 KB — under the cap, so it is **whole**. See
[`admin-design.md`](admin-design.md).

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
