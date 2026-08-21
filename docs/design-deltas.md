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

## 13. What the handset showed that the widget tester could not

Phase 0 of [`build-order.md`](build-order.md) put the five built screens on a
Pixel 9a in both modes, next to the canvas. The palette itself came back clean —
sampled pixels match `AppPalette` exactly, `#050B0F` page, `#171F25` card,
`#11171C` nav in dark — so the `PAL` recovery holds. Three things did not.

**Fixed — the supply count was being ellipsised.** Every thin category rendered
as *"New in Gaborone · 6 plum…"*. The count is the one thing the supply copy
exists to state, and an ellipsis put it back to being vague — the exact failure
§1 and the `SupplyStanding` copy were written against. The canvas sets no clamp
on that text at all; ours had `maxLines: 1`. Now two lines, with the grid's
`mainAxisExtent` raised 124 → 136 to hold them, and a test that measures in the
real IBM Plex face rather than the test font, which draws every glyph a full em
wide and would have passed a string twice its true width.

**Not a drift, and worth writing down because it read like one.** The canvas
gives the category tile `box-shadow: pal.shCard`, and we render `shadowRow`.
That looks wrong and is right: the two vocabularies invert. `pal.shCard` is the
*common surface* shadow at `0 4px 14px` and maps to our `shadowRow`;
`pal.shRaise` is the deeper one at `0 6px 20px` and maps to our `shadowCard`.
The mapping table lives at the top of the shadow block in `tokens.dart`. Reading
a canvas shadow name as if it were ours puts every surface one step too deep —
which is what happened here for one commit before the table was re-read.

**Recorded, not fixed — the tile's off-grid literals.** The canvas draws it at
`border-radius:20px`, `padding:14px`, a `38×38` icon plate with a `10px` gap,
in a grid of `gap:11px` inside `padding:0 18px`. Ours is radius 18 (`Radii.row`),
padding 13, a 36×36 plate with a 9 px gap, `Space.x3` gaps and a 16 px gutter.
None of the design's numbers are tokens — they are inline literals in one
artboard, and 20 sits between `Radii.row` (18) and `Radii.card` (22). Adding a
token per literal is the thing this repo already declined to do for `navPillBg`.
The deviation is ≤ 2 dp everywhere and invisible at a glance; it becomes worth
revisiting only if a later pull promotes those numbers into `PAL`.

**Also noted:** browse derives its header count from the listings it holds, so
plumbing reads *"Gaborone · 3 providers"* under a home tile saying *"6
plumbers"*. That is `demo_data.dart` disagreeing with itself, not a layout
fault, and it dies with the scaffolding when the API lands.


---

## 14. Reading the whole design, and what that corrected

All five canvases were read end to end on 2026-08-20 — foundations, customer,
provider, specs and the back office, 2,384 lines of flattened text. Everything
before this had been done against **extracted slices**: a regex for a token
name, a `find()` around one artboard. That works for looking something up and
fails completely at noticing that a document disagrees with itself.

**The root cause is in this repo, not in the canvas.** The 2026-08-20 resync
*appended* the recovered sections to `design-system.md` instead of replacing the
stale ones. The file ended up with two `## Motion` headings and two navigation
sections, and the stale motion section carried a `Motion` class **code listing**
— so it read as the authority, and `theme/motion.dart` was written from it.

Five contradictions, all inside one document:

| Where | Stale text said | The canvas says |
|---|---|---|
| `## Motion` (first) | `sheet: 280`, `page: 250`, `count: 600`; no tab-change, no parallax | 120 tab change · 220 push **+ 16 px parallax** · 260/180 sheet · 300 state change · **400** count |
| `## Feedback` → Haptics | "**Four** moments … the four where money moves" | "**Three** uses only" — and two of them are not money moving |
| State restoration | KYC draft "lives **on the server** from the moment of upload" | "stored **locally** until submitted" · "drafts persist to **local storage** on every field change" |
| Navigation | Split across two sections with a cross-reference | One set of rules |
| Anchors | `#motion` ambiguous between two headings | — |

The third one is the serious one. Server-held versus locally-held drafts decides
whether an unsubmitted Omang ever leaves the handset. That is a privacy
position, and it had been written from inference into a document that the code
is supposed to follow.

**All five are now merged into one section each, sourced from the canvas text
rather than from the doc's own copy of it** — every row re-checked against part
4 lines 0248–0316 before it was written down.

### What it changed in the app

- `theme/motion.dart` rewritten to the canvas table: `tabChange` 120 added,
  `page` 250 → 220 with `pushParallax` 16, `sheet` 280 → 260 with a separate
  `sheetOut` 180, `count` 600 → **400**, `stateChange` 300 added.
- Tab changes were animating for 220 ms as a fade. They are siblings, not a
  journey — 120 ms.
- `PageMotion.push` now drifts the outgoing screen 16 dp. It previously had no
  parallax at all, so a push read as a swap rather than as depth.
- The auth-gate sheet takes 260 in / 180 out instead of the theme default.
- Back is blocked during the OTP round trip, per the navigation rules.

### What it changed in the plan

Phase 0's gate checked colour and nothing else, and passed. It now requires a
motion pass as well. Phase 1 was recorded as built and is not — the biometric
enrolment screen does not exist, the OTP screen carries one of about ten named
states, and consent supersede is modelled without being enforced. Both are
corrected in [`build-order.md`](build-order.md).

**The lesson, for the next session:** a slice tells you what a section says. It
cannot tell you that another section says the opposite. Read the design whole
before implementing from it, and when a resync brings new material in, *replace*
what it supersedes rather than appending beside it.


---

## 15. Building Phase 2's remainder — four departures, each recorded

Booking request and rate & review were built on 2026-08-21 from the
`5–6 · BOOKING REQUEST / STATUS` and `8 · RATE & REVIEW` artboards in
`ipelege-ds-2-customer.dc.html`, plus the `dirDefs` and `ratingStars` bindings in
that file's `<script>` block. Four things in the built screens differ from what
the canvas draws. None is an improvement made for its own sake; each is written
here so it can be argued with.

### 15.1 The service direction options are confirmed, and `either` survives

`ServiceDirection` carried a doc comment saying its three values were "inferred
from the model rather than read", because the option list "sits past the read
cap on the source canvas", and asking for confirmation once the tail was
recoverable. The tail has been readable since the canvas was split. It now is
confirmed, and the answer is split:

| | The canvas | Kept |
|---|---|---|
| Booking radio set | `Comes to you` / `You go to them`, each with a sub-line | Both, verbatim, as `ServiceDirection.choices` |
| Browse filter | `Any direction` / `Comes to you` / `You go to them` | Yes — the "All" chip is now "Any direction" |
| `either` | Absent | **Kept**, as a listing property |

`either` is not an invention and is not deleted. [`booking.md`](booking.md) is
explicit that a listing may offer "**Both** — provider offers either", with the
customer selecting the applicable direction at the point of booking. So a
listing may be `either`; a booking request never is. `choices` is what says so
in code, and both the filter and the radio set read it rather than filtering
`values` by hand.

**The design's own inconsistency, recorded not corrected:** the canvas draws
both radio cards unconditionally, on a listing its own browse card labels
"Comes to you · Block 8". Both cards render, as the design has them. Narrowing
them to what a provider actually offers is a decision for when listings carry
real direction data.

### 15.2 The `Request / Status` tab strip is not built

The artboard puts a two-tab segmented control at the top of the phone — Request
and Status — because it is showing screens **5 and 6** in one frame. They are
separate routes in the app, on different tabs, reached at different times: a
status you can flip back to a request form for is a status of nothing. The
status screen made this call when it was built; the request screen follows it.

What the tab strip was also doing was carrying the top of the screen, so
removing it leaves a screen with no way back. Both booking screens now use one
extracted `ScreenHeader` — a raised back plate, a title, the category as a
filled pill — rather than one custom header and one stock `AppBar`.

### 15.3 A chosen star reads the palette, not the canvas's literal

The canvas fills a chosen star with the literal `#145A8D`, not with
`pal.accentText`. In light mode those are the same colour to the byte. In dark
mode the literal would put deep navy on a `oklch(0.235 …)` card, and the rating
— the one thing the screen exists to collect — would be close to invisible.

`_Stars` reads `palette.accentText`: identical to the canvas in light,
`#75BDEB` in dark. This is the same class of fix as the shadow-vocabulary
mapping in §13 — the canvas is authoritative about intent, and a literal that
only works in one mode is not the intent.

### 15.4 The pronoun in the payment sentence

The canvas writes, of a provider named Kabelo:

> Kabelo quotes you back. Nothing is charged now, and you pay **him** directly.

That sentence is a template rendered for every provider on the platform. The
built copy is identical but for the pronoun — **them** — because the alternative
is an app that misgenders providers on the screen where it asks a customer to
trust one. Everything else in the sentence is verbatim, and it is verbatim on
purpose: this is the screen that says nothing is charged now.

### One thing that is not a delta

The canvas's provider row reads "Verified · from P150". The built row reads
"Verified · from P150.00", because [`test-strategy.md`](test-strategy.md)'s
money rule is two decimal places always, including on whole numbers, and it is
enforced by tests. The canvas is drawing a figure; the app is formatting one.

---

## 16. Building a feature the design specified but never drew

Stage 7's loop prompt was built on 2026-08-21. The journey map in
`ipelege-ds-1-foundations.dc.html` marks both of its pieces — *Cross-category
prompt* and *Rental enquiry → movers handoff* — as `gap`, which tracks **design**
completeness. So unlike every screen before it, this one had no artboard.

What it did have is more than enough to build from, and the distinction matters
because [`build-order.md`](build-order.md) draws a line between "unsettled" and
"blocked": the journey map gives the two trigger points, the adjacency pairs,
the four suppression states, and one finished line of copy. What it does not
give is a layout or the other three headlines.

### 16.1 What is the design's, and what is ours

| | Source |
|---|---|
| The two placements | Journey map: *"the prompt belongs at the rental enquiry, and again at a completed movers job"* |
| The four suppression states | Journey map, verbatim |
| The pairs | Journey map's own table, plus [`categories.md`](categories.md) |
| `rentals → movers` headline | **The design's.** *"Moving in? Find a truck"* — marked `verbatim: true` in `LoopPair` |
| The other three headlines and all body copy | **Derived**, and flagged `verbatim: false` |
| The layout of card and sheet | **Ours**, assembled from existing components |

The `verbatim` flag is not decoration. It is how a later canvas replaces our
copy without anyone having to work out from a diff which strings were the
design's and which were guesses, and there is a test asserting the rentals pair
carries it and the others do not.

### 16.2 Four decisions turning the design's table into four pairs

The journey map's table reads *Room taken → truck that same week → plumber,
water delivery once moved in* · *Funeral or wedding → catering · chairs, tents
and sound hire · transport for guests* · *Rides → the connective tissue*.

1. **Water delivery is not a launch category.** It is in `categories.md`'s full
   list but not the nine, so `movers → plumbing` carries the "once moved in"
   half of that chain alone.
2. **The event cluster is three categories and a prompt offers one.** The design
   says "the adjacent category", singular, and a prompt offering three things is
   a menu — a menu at the end of a job is the banner this is not supposed to be.
   Catering offers hire, hire offers catering.
3. **Rides is a target, never a source.** *Transport for guests* is not offered,
   for two independent reasons: rides is `dispatch`, so it has no browse screen
   to send anyone to, and it is the highest-frequency category, so a prompt
   after every ride is exactly the noise stage 7 is meant to avoid. A test
   asserts no pair points at a dispatch category.
4. **An unknown supply figure counts as thin.** The design says don't prompt
   into an empty room; not *knowing* whether a room is empty is not grounds for
   sending someone into it, so the default fails closed.

### 16.3 The suppression rules mostly fire, and that is correct

Against the demo's own supply figures — which are the canvas's `CATS` array
verbatim — exactly one of the four pairs shows. The other three point at
categories the design marks thin.

That is worth stating plainly because it is the kind of result that looks like a
bug: **six of nine categories are thin at launch by plan**, so a correctly built
loop prompt spends most of its life declining to appear. A version of this
feature that showed all four would be one that had quietly stopped checking
supply, and there is a test pinning the demo figures for that reason.

### 16.4 A copy bug the work exposed

Making rentals reachable — stage 7 needs a rental to enquire about — put the
listing detail screen in front of a `payPerListing` category for the first time,
and two things on it were wrong:

- **"Verification confirms identity and trade certification"** is wrong for at
  least two of the nine. Rentals is verified on proof of ownership and property
  inspection; tiling has no certificate at all and is verified on proof of past
  work — which `categories.md` says outright, and which is half the reason
  "small trades" was split into three categories in the first place. It now
  reads "the documents this category requires".
- **"0 completed jobs yet"** on a rental is a zero that can never become
  anything else. The design is explicit that pay-per-listing means "no booking,
  no commission, no completion", so a job count there is meaningless. Rentals
  now get their own note about what verification covers and how a viewing is
  arranged.

---

## 17. Running Phase 0's motion pass — the tokens were right, nothing used them

Phase 0's gate was widened on 2026-08-20 to require a motion pass, after the
colour-only version missed that every duration in `theme/motion.dart` had been
implemented from a stale `## Motion` block. Those numbers were then corrected.

**Running the pass on 2026-08-21 found the other half of the same failure.** The
corrected tokens were load-bearing in exactly four places — the router's page
transitions, the button tap ripple, the sheet controllers and one category
tile — and **nowhere else**. There was not one `AnimatedContainer`,
`AnimatedSwitcher` or `TweenAnimationBuilder` on any screen. The transition
table's two most-specified rows were unimplemented:

| Row | Design | What the app did |
|---|---|---|
| Booking state change · 300 ms | Chip colour and step bar animate **together**, so the change reads as one event. An eleven-row per-state table follows it. | Nothing moved. Every state cut. |
| Wallet balance · 400 ms | The figure counts to the new amount. "Money changing deserves to be noticed." | The figure was replaced. |

Both are now built, and `app/test/ui/motion_test.dart` pins them. The rows the
table names for screens that do not exist yet — the incoming-ride sheet and its
countdown, verification status — are untouched and stay that way until Phase 4
and Phase 5 reach them.

**The lesson is the same one Phase 0 already recorded once, one level down.**
Correcting a token is not implementing it. A gate that reads `motion.dart` and
finds the right numbers has checked the dictionary, not the sentence.

### 17.1 "Medium haptic" is a strength the app deliberately does not have

The per-state table marks two states with a haptic: `ACCEPTED` — *"provider row
rises 12 dp into place, medium haptic"* — and `COMPLETED` — *"one medium
haptic, no confetti"*. There is no medium.

`core/haptics.dart` exposes exactly three, and they are named after **what they
mean**, not how strong they are: `decision()`, `incomingRide()`, `error()`. The
class has no general-purpose `buzz()` on purpose, because the design's own
haptics rule is that "a phone that buzzes at everything gets muted — and then
the three that mattered are gone too."

Resolved in favour of the meanings, not the strengths: `decision()`'s own
definition is *"accepting or declining a request; confirming a booking is
done"*, which is these two moments under their other name. Both states fire
`Haptics.decision()`. **A fourth haptic was not added**, because the two
sections are not in conflict about behaviour — the motion table is describing
the same buzz in the vocabulary of intensity, which is the vocabulary the
haptics section explicitly refuses.

### 17.2 An ending greys the steps out by removing them

`EXPIRED` says *"Steps grey out together, no travel"*, and the built screen
hides the step bar entirely on any ending rather than drawing it greyed —
"a bar with no progress on it reads as progress lost". Recorded rather than
changed: the hiding decision predates this pass and is defended in the screen's
own doc comment, and removal satisfies the part of the row that carries the
meaning, which is *no travel*. If a later canvas draws the greyed bar, this is
the line to change.

### 17.3 Two Flutter traps this pass walked into, both fixed

Kept because both produce motion that looks implemented and is not:

- **An `AnimatedSwitcher`'s outgoing child animates on the controller it was
  built with.** Flipping its `duration` from zero to 300 ms at the moment of
  the change gives the *incoming* half the new duration and leaves the outgoing
  half at zero — so it vanishes instead of crossfading, and the crossfade tests
  green on every assertion about the widget's properties. Instantness has to
  come from unmounting the switcher, not from zeroing it.
- **"Has it changed" is not "is it different from where it started".** Gating
  an arrival animation on `state.key != _openedAt` reads as *not arrived* for
  any booking that returns to a state it has already been in. It is a latch.

---

## 18. Running Phase 0's colour gate — three invisible controls

The colour half of the gate ran on 2026-08-21 against everything built since
2026-08-20: 28 screens, light and dark, on a Pixel emulator. The palette holds
— every surface, plate and chip reads as the canvas specifies, and the dark
mode that most of these screens had never been rendered in is correct.

**What it found is a class of bug no widget test can see, and no artboard
comparison would have caught either**, because the artboards show controls in
their *chosen* state. Three interactive controls were drawn with hairline
tokens, and at rest they were effectively invisible:

| Control | Was | Against | Contrast |
|---|---|---|---|
| An empty rating star | `divider` | the card | **1.4:1** dark |
| The **required** consent tick, unticked | `inputBorder` | the card | **1.8:1** dark |
| A notification switch, off | `inputBorder` | the row | **1.8:1** dark |

WCAG 1.4.11 puts the floor for a non-text UI component at **3:1**. Light mode
was no better: five pale grey stars on a white card.

The rating screen is the sharpest case. The five stars are the only input on
it, and the screen's own copy is *"Your rating is the only signal a new
provider has"* — a control that cannot be seen collects nothing, on the screen
that carries the product's entire trust argument. The consent tick is the most
serious: a control the DPA requires, on a screen that cannot be passed without
it.

### 18.1 The fix is a token, because the bug was one

`AppPalette.controlOutline` — *the resting outline of an interactive control* —
now sits beside `inputBorder` and `divider` and is the answer to a different
question. Those two draw hairlines, and a hairline is supposed to recede; this
draws the affordance, and an affordance nobody can see is not one.

**No new colour was invented.** `controlOutline` is `textMuted`'s value in both
palettes — the canvas's own — which clears the floor at 4.9:1 light and 5.8:1
dark. Inventing a hex the design never specified to fix a contrast bug would
have traded one silent drift for another.

`app/test/theme/contrast_test.dart` holds it, and holds the *other* half of the
rule too: `divider` must stay **under** 3:1 against a card. Fixing contrast by
darkening the hairline would have given every card on every screen a visible
border and undone the design's no-borders-only-tinted-shadow treatment. Both
directions are now pinned, along with the text floors and one test that fails
outright if `controlOutline` is ever set back to `divider` or `inputBorder`.

### 18.2 The loop prompt's second placement cannot be photographed, and should not be

The gate could not capture the cross-category prompt on a completed booking.
The reason is not a bug and was worth confirming rather than assuming: all
three `bookingCompleted` pairs — `movers → plumbing`, `catering → hire`,
`hire → catering` — point at categories the demo marks `thin`, so the
empty-room rule withholds every one of them. `Demo.bookingCategory` is
plumbing, which is not a *source* in any pair either.

So the placement is unreachable in the demo twice over, and **making it
reachable would mean fabricating supply that does not exist** — prompting
someone into an empty room, which is the one thing stage 7's rules exist to
prevent. The gate photographs the placement that *is* reachable instead: the
rental enquiry → movers handoff sheet, which fires against 21 real trucks.
Recorded here so the absence is not read later as a regression.

### 18.3 The gate is a script now

`app/integration_test/gate_test.dart` walks every screen in both modes on a
real device and writes a PNG per artboard. It reaches each screen by overriding
`routerProvider` rather than by tapping through the app, because a gate that
has to complete a nine-step journey to photograph the ninth screen fails at
step two and shows nothing.

This matters more than the findings. Phase 0 has now failed twice in the same
shape — skipped entirely before the first five screens shipped, then run too
narrowly and missing every motion token — and both times the root cause was
that running it was a manual act of will. See [`build-order.md`](build-order.md)
Phase 0 for the command.

### 18.4 The gate was photographing fakes, and what fixing that found

The first two runs pumped `IpelegeApp` with only `routerProvider` overridden —
so they got `biometricsProvider`'s default, `AlwaysAllowBiometrics`, and the
unlock screen was photographed answering a fake. A gate that runs on a device
in order to see what the device does, and then asks a stub instead, is only
half a gate.

It now applies the same `biometricsProvider` override `main()` does. The
session store is deliberately **not** overridden: each shot must start from the
state its own callback sets, and a prefs-backed store would carry one shot's
session into the next.

**That immediately verified a branch that had never run against the real
platform.** The emulator reports `android.hardware.fingerprint` and a
`FingerprintProvider`, with `"count":0` — a sensor, no enrolled print, no
device credential — which is exactly the design's *"biometry unavailable or
refused → passcode"* case. `PlatformBiometrics.availability()` returned
unusable, and the screen came back correct: no fingerprint button, no copy
naming a fingerprint, **Enter device passcode** promoted to the primary and
drawn filled, "Sign in as someone else" beneath it.

**And it caught the one thing that was not conditional.** The copy and both
buttons obeyed the rule from the day they were written. The 104 dp hero plate
above them did not — it was a hardcoded `Icons.fingerprint`, 50 dp of it, sitting
directly over the words *"Use your device passcode to continue."*

That is the same bug as the copy would have been, drawn larger. The screen's
own comment already states the reason it must not happen: *"Telling someone to
use a fingerprint on a handset with no sensor is the kind of copy that makes
people think the app is broken rather than their phone."* A picture is copy.
The glyph is now `Icons.dialpad` on the passcode-only layout, matching the
button under it, and `test/ui/unlock_test.dart` pins it — verified to fail
without the fix, not merely to pass with it.

**What is still owed:** the *successful* biometric path. Raising a real prompt
needs a device credential and an enrolled print, and enrolling one means
setting a PIN and driving the emulator's Settings UI — a change to the
machine's state that is the user's to make, not this session's. What is
verified is the branch that matters most on the target hardware, where broken
and absent sensors are common.

### 18.5 The last unverified branch, closed on real hardware

A Galaxy S24 (Android 16, three enrolled prints) was paired over wireless adb
on 2026-08-21 and the gate run against it. That closes the one thing the
emulator could not answer, and it closed it in **both** directions:

| | Emulator · 0 prints | S24 · 3 prints |
|---|---|---|
| Hero glyph | `dialpad` | `fingerprint` |
| Copy | "…device passcode to continue" | "…fingerprint to continue" |
| Primary action | Enter device passcode | **Use fingerprint** |

Same build, same code path, opposite answers from `PlatformBiometrics
.availability()`. §18.4's glyph fix is verified from both sides rather than
only from the one that was broken.

Then `integration_test/biometric_test.dart` raised a **real system prompt** and
a **real fingerprint** carried a locked session back to `active`. It is a
separate target from the gate on purpose: a gate is unattended, and this one
waits thirty seconds for a person to touch a sensor. It signs in properly and
*then* locks, because `lock()` deliberately does nothing to a session that was
never active — starting from a fabricated locked state would test a state the
app cannot reach. It also asserts the name that comes back is the name that
went in, because biometry **unlocks**; it never authenticates, and the session
on the far side must be the one that was already there.

Every branch of `core/biometrics.dart` has now run against a real platform.

### 18.6 Two things that cost a run, both worth knowing

**A sleeping screen kills an on-device gate, and says nothing useful about it.**
The first S24 run died at shot 18 when the handset hit its thirty-second
timeout: `PixelCopy` throws `IllegalArgumentException: Window doesn't have a
backing surface!`, the app takes SIGKILL, and the driver reports `Service has
disappeared`. Three symptoms, none naming the cause, and **zero screenshots
survive** — the driver flushes at the end, so a run that dies at shot 55 leaves
exactly as much evidence as one that dies at shot 1. `adb shell svc power
stayon true` only holds while the handset is charging; otherwise raise the
timeout or keep touching the screen.

**Device runs are debug builds, always.** Already the default, and now written
out in the run commands so nobody adds `--release` to make it faster: the
driver attaches to the Dart VM service, which a release build does not have.
It would not fail informatively — it would fail to start.

---

## 19. The first real UI tick, and the three things a glance had passed

A **UI tick** — enumerate the artboard's elements first, then compare each one
against the screenshot, verdict per element — was adopted on 2026-08-21 after a
whole-screen review of the splash passed a defect that was plainly visible in
the image. The procedure is in
[`test-strategy.md`](test-strategy.md#ui-ticks--comparing-a-screenshot-to-its-artboard-element-by-element).

The first tick run under it was that same splash screen, dark, on a Galaxy S24.
It found **three** departures where the glance had found none.

| # | Element | Artboard | Was built | |
|---|---|---|---|---|
| 1 | Wordmark colour | light-blue `i`, white `pelege` | flat white | **fixed** |
| 2 | Card glyph tint | `#9FD4F5` | `Brand.sky` `#75BDEB` | **fixed** |
| 3 | The mark | `mark-dark.png`, 88 px, above the wordmark | absent entirely | **blocked** |

### 19.1 The wordmark had lost its blue *i*

The one relationship the canvas singles out as what an earlier brand set
destroyed — *"the wordmark keeps the blue i — the earlier set had been
assembled from different exports and dropped both"* — and the type fallback
shipped it flat white. Written up in [`identity.md`](identity.md); the fix is
two `TextSpan`s so the kerning stays the typeface's.

Fixing it surfaced a second bug in the same widget: `ExcludeSemantics` was
wrapping `Semantics`, so the exclusion swallowed the label along with the text
and **the lockup reached a screen reader with no name at all**. It shipped that
way, and was found only because a test asked for the name and did not get one.

### 19.2 The splash glyphs are a paler blue than the app's accent

The canvas paints the three card icons `#9FD4F5`, and **all four occurrences of
that value in all five canvases are on this one screen.** It is not a stray
literal: over a 10% white plate on the entry gradient, `Brand.sky` sits too
close to the ground behind it. Now `Brand.skyPale`, with the role in its doc
comment rather than the shade.

This is the kind of thing only enumeration finds. Both colours are light blue
on a dark blue ground; nothing about the screenshot looks wrong.

### 19.3 The splash is missing the mark, not just the wordmark

The artboard stacks **two** brand elements: `mark-dark.png` at 88 px, a 20 px
gap, then `wordmark-dark-new.png` at 176 px. The build renders the wordmark
stand-in and **no pin at all** — so the splash is short an element, not merely
showing type where artwork belongs.

Recorded rather than fixed, because `mark-dark.png` is one of the four cuts
that exceed the 256 KiB fetch cap and it cannot be drawn without inventing it.
It is the sharpest illustration of what that blocker actually costs: the first
screen of the app is missing the logo. Listed in
[`../design/CORRECTIONS.md`](../design/CORRECTIONS.md) with the other blocked
cuts.

---

## 20. Dropping "an OTP every time the app is opened"

**The design's rule, from the Security screen, in its own words:** biometric
unlock off means *"an OTP every time the app is opened"*. It was built exactly
that way — `SessionCodec.reopened` sent a biometry-off session back to
`confirmingNumber` — and it is now gone.

**Not for cost.** For the reason that makes the cost unjustifiable: **the check
does not do what it looks like it does.**

An SMS code proves possession of the **SIM**. The threat a reopen check exists
for is a stolen or borrowed handset — that is what `reopened`'s own comment
says, *"restoring straight to active would make a stolen handset a signed-in
handset"*. But on a reopen, the SIM is **inside the handset the person is
holding**. The code arrives in the thief's hand along with everything else.

So the old rule sent a paid message, on every single launch, to perform a check
that the attacker passes automatically. The device credential — a fingerprint
or the phone's own PIN — is the one proof a thief does not have, and asking for
it is what `SessionStage.locked` already does.

### What changed

| Moment | Before | Now |
|---|---|---|
| Reopen, biometry on | `locked` | `locked` |
| Reopen, biometry off | **`confirmingNumber`** — an OTP | **`locked`**, reached by the device passcode |
| Register / new device / reinstall | phone + OTP | unchanged |
| Explicit sign-out | phone + OTP | unchanged |

`biometricUnlock` still decides what `/unlock` **offers first**, which is what
the preference was always really about. It no longer decides whether a message
is sent.

**The OTP did not go away — it moved to what it actually proves.** A phone
number is verified at the moments where nothing on the device vouches for the
person yet: first registration, a new handset, a reinstall, and after a
deliberate sign-out.

### The edge case this created, and its answer

A handset with **no screen lock at all** has no device credential to check. It
used to fall through to the OTP; now there is nothing left to ask for, and
`/unlock` would have been a dead end with both buttons failing silently and a
live session behind them.

So a **passcode** prompt reporting `unavailable` is now treated differently
from a fingerprint doing so — it is the last way in, not a step down to the
next one. The session is signed out and the user goes through a fresh sign-in,
which is the honest outcome: nothing on this device can vouch for them.

### What the design side has to change

The Security screen's copy promises the old behaviour in those words. It is
listed in [`../design/CORRECTIONS.md`](../design/CORRECTIONS.md) — the screen
is Phase 7 and unbuilt, so no shipped string is wrong today, but the artboard
is.

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

**Superseded 2026-08-20 — this section was wrong, and it blocked work.**

Four brand PNGs are now in `design/assets/`: `appicon-light` (512²),
`appicon-dark` (512²), `adaptive-foreground` (432²) and `mark-icon` (130×165).
They came through `DesignSync.get_file`, and a large result lands in a file on
disk rather than in context — so "prohibitively expensive" was simply not true,
and the claim stopped anyone from testing it.

The real constraint is narrower and harder: `get_file` is **capped at 256 KiB**
and truncates silently. `mark-dark`, `lockup-dark` and `logo-light-transparent`
all return `truncated: true`; they were decoded, confirmed corrupt, and deleted.
Those three must be exported from the design side. Full detail in
[`identity.md`](identity.md).

The original list of everything the design project holds, kept for reference:

```
adaptive-foreground.png    app-icon-dark-512.png    app-icon-light-512.png
appicon-dark.png           appicon-light.png        lockup-dark.png
lockup-h-dark.png          lockup-h-light.png       lockup-horizontal.png
logo-light-transparent.png mark-dark.png            mark-icon.png
mark-light.png             notification-icon.png    wordmark-dark-new.png
wordmark-dark.png          wordmark-light-new.png   wordmark-light.png
```

**This note was not enough.** Recorded here as an import caveat, it sat
unactioned long enough that the app reached five built screens still shipping
Flutter's stock blue-flag launcher icon and flashing a white window on every
cold start. Phase 0 found it on the handset. The gap is now an artifact with a
test behind it — see [`identity.md`](identity.md) and
`app/test/identity/identity_test.dart` — rather than a line in a fidelity
appendix.

`support.js` (the Claude Design runtime shim) was also not imported — it is
generated tooling with no bearing on the Flutter build, and without the assets
the archived page would not render locally anyway. Treat the archived `.dc.html`
as a **text source of truth**, not a runnable page.
