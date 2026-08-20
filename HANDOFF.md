# Work Handoff - Ipelege

**Saved:** Thursday, 2026-08-20, 20:15 (+02:00)
**Branch:** main
**Last commit:** e3dfd83 Provision arm64 VPS stack; resolve ledger grain; add wallet.md

## What I was working on

A **full design resync followed by real UI implementation**. The session had
three phases, and the second two only happened because the user pushed back
twice on how thin my first resync was.

1. **Resync attempt 1** — pulled the design canvas, updated tokens and docs.
2. **The pushback.** User: *"there was an overhaul on the design side, how come
   you say no change?"* then *"not just the component section, the whole
   mockups and the document have moved"* then *"discard old things, refetch
   design afresh"*. All three were correct. I had conflated *retrieved* with
   *applied*, and had been merging a stale local snapshot with a fresh one.
3. **The split.** The mobile canvas had grown past 512 KB against a 256 KiB
   server-side read cap, so a third of it was unreachable. I could not split it
   myself — reading the tail is the very thing being blocked — so I wrote a
   `split-plan.md` into the design project; the user did the split in Claude
   Design; I re-pulled four parts, all complete.

## Files changed this session

**Design archive (`design/`)** — old monolith deleted, not merged:

- **D `ipelege-design-system.dc.html`** — the truncated single-file pull.
- **A `ipelege-ds-1-foundations.dc.html`** (144 KB) — decisions, journey map,
  brand/colour/type/components, visual direction.
- **A `ipelege-ds-2-customer.dc.html`** (93 KB) — entry, onboarding, home,
  browse, listing detail, booking, tracking, rate & review.
- **A `ipelege-ds-3-provider.dc.html`** (136 KB) — mode switcher, provider home,
  my categories, inbox, wallet, top up, become a provider, KYC.
- **A `ipelege-ds-4-specs.dc.html`** (101 KB) — settings screens, attestation,
  light & dark, category matrix, navigation/motion/feedback, **and `PAL`**.
- **A `ipelege-admin-back-office.dc.html`** (167 KB) — desktop, complete.
- **M `README.md`** — rewritten for the split.

**Docs** — **A `docs/admin-design.md`** (the 8 desktop screens + admin token
set); **M `design-system.md`** (surface treatment, category hues, components,
navigation/motion/feedback, screen inventory with build status); **M
`design-deltas.md`** (§§8–12 added); **M `README.md`** (doc index).

**Flutter** — **M** `theme/tokens.dart`, `dimens.dart`, `app_theme.dart`,
`ui/shell/app_shell.dart`, `ui/components/{category_tile,status_chip,info_note}`,
`routing/app_router.dart`. **A** `core/demo_data.dart`;
`ui/components/{surface,ledger_entry,week_chart,money_row,stepper_bar,decision_pair}.dart`;
`ui/screens/consumer/{home,category_browse,listing_detail}_screen.dart`;
`ui/screens/provider/{dashboard,wallet}_screen.dart`. **A** three test files.

## What is working

- **The design source is complete and single-vintage.** 485 KB across four
  parts vs 262 KB truncated; every part `truncated: false`. No local file is a
  blend of two pulls.
- **Every colour is read, not inferred.** `PAL` gave both modes. Dark mode was
  previously derived and is now real.
- **Five screens built and wired**: consumer home, category browse, listing
  detail, provider dashboard, wallet. Six new components.
- **97 tests pass, `flutter analyze` clean.** Up from 47 — and the 47 baseline,
  carried unverified through two prior handoffs, was re-run and confirmed.
- The tests found **four real bugs**, not just layout noise: the non-redeemable
  disclaimer overflowed at 360 dp, the fees row overflowed, `StatusChip` blew
  out its pill on "Verified · Hairdressing & beauty", and rentals was offering
  a booking it has no flow for.

## What is NOT working yet

- **No backend.** Django not started. Screens read `core/demo_data.dart`, which
  is scaffolding to delete when the API lands.
- **Most screens are still placeholders** — booking request, booking status (11
  states), ride tracking, rate & review, mode switcher, my categories, booking
  inbox, top up, become a provider, per-category KYC, and the six settings
  screens. All are now *available* in the design; none are built.
- **Never run on a device.** Carried over from two prior handoffs. Widget tests
  only — no emulator or handset run, so the surface treatment has never been
  seen rendered.
- `navPillBg` is the one remaining derived colour (inline literal in the canvas,
  not a token, so no published dark form).
- The VM stack from last session is untouched and still has no schema.

## Decisions made (and why)

- **Discard rather than merge design snapshots.** User's call and the right
  one: a half-stale archive is exactly the trap that produced the bad first
  resync. Cost was the old `PAL`; the split recovered it anyway.
- **Split into four parts, in Claude Design.** The 256 KiB cap is server-side on
  `get_file` with no range or pagination, so the repo cannot initiate it. Sent
  `split-plan.md` into the project rather than making the user retype it.
- **Match the design's token names exactly**, even where mine read better —
  `screenBg2` is the page, `screenBg` stayed white. Future syncs now diff
  directly instead of needing translation.
- **Supply is two states in the app, three in the back office.** `ok`/`thin` for
  customers; `HEALTHY/THIN/CRITICAL` is the operator's recruiting view. And the
  copy is the real decision: *"New in Gaborone · 2 providers"*, never "2
  nearby" — young rather than failing.
- **`JourneyShape` on `CategoryToken`** so rentals structurally cannot offer a
  booking, rather than relying on a call site remembering.
- **`DecisionPair` ships as one component** so "never two blue buttons side by
  side" cannot be half-applied.
- **New-provider boost is one slot, non-compounding** — second position, not
  first. The boost earns a look; it does not claim to be the best match.

## Things I tried that did NOT work - do not repeat these

- **Claiming "components came through complete" when I meant "retrieved".** The
  component set had gone 4 groups → 7. Say *applied* or *retrieved*, never
  blur them.
- **Merging the 2026-08-17 snapshot with a fresh pull** to cover the truncated
  tail. Produces a file where some values are current and some are 3 days stale,
  with nothing marking which.
- **Grepping for `backRules`, `motionSpecs`, `haptics`** to find the spec
  tables. The design rebuilt them as prose sections; the array names return zero
  hits in all four parts even though the content is there.
- **Splitting the canvas from the repo side.** Impossible by construction —
  reading the tail is what is blocked.
- **A bare `grep -o` with a complex alternation over a 256 KB HTML file** —
  catastrophic backtracking, hit the 120 s timeout. Use Python for structured
  extraction from these files.
- **`sed -i "1i import ..."`** on a Dart file with a `library;` directive —
  puts the import above the doc comment and fails to parse.

## Exact next steps to continue

**First, a correction on build order.** The five screens built this session were
chosen to *validate the resynced tokens* — dashboard and wallet are the design's
own restyle exemplars, and home/browse/listing is a coherent vertical slice.
That was right for the resync, but it is **not** the design's stated build
order, and it has left a real hole: the app has **no way in**. No splash, no
register, no sign in, no OTP, no auth gate. It boots straight to Home as an
anonymous browser.

The design's own proposed order, from the journey map, is: *close the account
gap first → then booking status with the payment moment moved → then the stage-7
loop prompt → then the provider management surface → then account & privacy.*
Follow that from here.

1. **Close the account gap** (stage 0–1). Splash, register, sign in, OTP as
   second factor, biometric unlock with equal-weight passcode fallback, granular
   consent including the WhatsApp/SMS channels, auth gate, location permission.
   In `ipelege-ds-2-customer.dc.html`. Two reasons this is genuinely first, not
   just the design's preference: **the auth gate sits at the booking action**,
   so booking request depends on it existing; and every screen already built is
   currently reachable without an account, which is correct for browse and
   wrong for everything past it.
2. **Booking request + booking status.** The densest piece: 11 states, carrying
   the **payment-before-mark-complete** correction (service delivered → customer
   pays directly → provider marks complete → customer confirms → commission
   posts).
3. **Pair the admin side in** where a mobile flow needs it — user's steer, for
   more thorough testing. First natural pair: KYC submission → admin
   verification queue → document review.
4. **Run it on a handset or emulator.** Three handoffs old now, and the whole
   surface rework has never been seen rendered. Worth doing *before* building
   ten more screens on tokens nobody has looked at.
5. Provider management surface: mode switcher, my categories, booking inbox, top
   up, become a provider, the nine KYC screens.
6. The six settings screens from part 4, then the stage-7 loop prompt.
7. Retire `stripe1`/`stripe2`/`info*` from `AppPalette` if a later pull confirms
   they are gone rather than merely unused.

## Open questions / blockers

**Unchanged and still code-blocking:** already-accepted bookings when a category
is revoked — blocks the admin Revoke action shipping.

**New, from the design's own "needs a business decision" list:**

- Late-cancellation fee amount — percentage, flat figure, or first-occurrence
  waiver. Screens are written so the number drops in without changing the flow.
- No-show consequence for providers — currently only says verification is
  reviewed; what actually happens, and after how many.
- Commission rate per category — rides shows 8%; whether trades and rentals
  differ is unresolved.
- Dispute turnaround — screens promise contact but name no timeframe.

**Not yet designed at all:** messaging between customer and provider (referenced
from several screens, no thread UI), provider listing management at scale,
empty/offline states across the journey.

**Carried:** wallet naming vs `compliance.md` (the design says "wallet balance";
the project's own `CLAUDE.md` still says "commission credit" and no screen
follows it) · reversal policy · negative balance · min top-up · hosting
durability · EPS licensing, data residency, KYC retention, GPS DPIA.
