# Design system

Extracted from the Claude Design project **"Ipelege app design system"**
(`012e55a7-8d3d-4aed-abf7-f1ab95fadf63`). Re-pulled 2026-08-20, after the mobile
canvas was split into four parts so the whole of it could be read; the source is
archived in [`design/`](../design/) as `ipelege-ds-1-foundations` through
`ipelege-ds-4-specs`, plus the back-office canvas. This document is the
implementable extract of them.

Where the design and the older specification documents disagree, see
[design-deltas](design-deltas.md). The design is the newer layer.

Target: Flutter, Android-first, Android 8+, binary under 30 MB, 3G, 1–2 GB RAM
handsets. Material 3 bones, Ipelege skin.

## Where this lives in code

The system below is implemented, not aspirational. It is **central and
theme-driven**: a screen uses plain Material widgets and the theme decides how
they look, so nothing here is re-specified per screen.

| This document | Code |
|---|---|
| [Colour](#color), [category hues](#category-hues) | `app/lib/theme/tokens.dart` — `Brand`, `Status`, `Neutral`, `AppPalette`, `Categories` |
| [Spacing, touch, responsive](#spacing-touch-responsive) | `app/lib/theme/dimens.dart` — `Space`, `Radii`, `Touch`, `Breakpoints` |
| [Type](#type) | `app/lib/theme/typography.dart`; faces bundled in `app/assets/fonts` |
| [Motion](#motion) | `app/lib/theme/motion.dart` — `Motion`, `PageMotion` |
| [Components](#components) | `app/lib/theme/app_theme.dart` for anything Material already themes; `app/lib/ui/components/` for the rest |
| [Navigation](#navigation) | `app/lib/routing/` — `routes`, `nav_tabs`, `navigation`, `app_router` |

Colour tokens are **generated**: the design authors in OKLCH, which Flutter
cannot parse, so `tokens.dart` holds converted sRGB values. Re-run the
conversion when a token changes rather than eyeballing a hex code.

## Five decisions the system is built around

1. **Material 3 bones, Ipelege skin.** Stock Material patterns — bottom nav,
   list items, filled/outlined buttons. Novelty is spent on the five product
   problems, not on reinventing navigation.
2. **Thin categories say so, honestly.** Every category tile shows a real,
   specific supply count rather than hiding low supply.
3. **Verification and rating are separate signals.** The verified badge is a
   compliance fact available from day one; the star rating only exists after
   jobs are done. Surfaced independently so a new provider is not invisible.
4. **The app never implies it took your money.** Payment is direct between
   customer and provider. Screens near a completed booking say so in plain
   words, at the moment it matters.
5. **The wallet balance is a meter, not an account.** No withdraw button, no
   "available balance" framing. The disclaimer sits on the balance card itself.

## Brand

| Asset | Use |
|---|---|
| Full lockup (mark + wordmark + tagline) | above 180 px |
| Horizontal lockup | 90–180 px |
| Mark alone | below 90 px, where the tagline stops being legible |

Light variants are the supplied artwork with its white plate knocked out; dark
variants are the supplied dark artwork untouched. Every asset is cut from the
one supplied lockup, so the mark keeps its ripple rings at every size and the
wordmark keeps the blue *i*.

Asset files live in the design project under `assets/` and are **not** mirrored
into this repo — see [design-deltas](design-deltas.md#not-imported).

## Color

### Brand

| Token | Value | Role |
|---|---|---|
| Sky | `#75BDEB` | Accent, accent text on dark |
| Deep | `#145A8D` | Primary |
| Ink | `#111111` | Primary text on light |
| White | `#FFFFFF` | Surface |
| Navy | `#061326` | Header, balance card base |

Status hues, expressed in OKLCH so light and dark are re-toned rather than
re-hued:

| Role | Hue | Meaning |
|---|---|---|
| Success | `oklch(0.60 0.13 152)` | verified / ok |
| Warning | `oklch(0.72 0.15 80)` | pending |
| Danger | `oklch(0.58 0.19 25)` | declined |

### Neutral scale

Cool, low-chroma, hue matched to the brand blue (hue 250):

```
oklch(0.985 0.004 250)  oklch(0.96 0.006 250)  oklch(0.91 0.008 250)
oklch(0.82 0.01  250)   oklch(0.65 0.012 250)  oklch(0.52 0.014 250)
oklch(0.40 0.014 250)   oklch(0.30 0.012 250)  oklch(0.20 0.01  250)
```

### Semantic palette, light and dark

Three things hold across both modes: the deep navy of the balance card (it only
lightens a step, so it stays the darkest surface on screen), the category hues
(a colour always means the same category), and every status pairing (approved
never stops being green).

**Read from the design's own `PAL` object**, both modes, verbatim — not
inferred from the mockups. Recovered 2026-08-20 when the canvas was split into
four readable parts.

Two things to know before using this table:

- **The page is `screenBg2`, not `screenBg`.** `screenBg` stayed white in the
  restyle; `screenBg2` is the #EDF3F8 tint every screen actually sits on. The
  Flutter `scaffoldBackgroundColor` points at `screenBg2`.
- **Dark surfaces sit on hue 235**, not the 250 of the neutral ramp — a shade
  cooler and bluer than the rest of the scale.

| Token | Light | Dark |
|---|---|---|
| `screenBg` | `#ffffff` | `oklch(0.18 0.015 235)` |
| `screenBg2` | `#EDF3F8` | `oklch(0.145 0.014 235)` |
| `cardBg` | `#ffffff` | `oklch(0.235 0.016 235)` |
| `cardBorder` | `oklch(0.91 0.008 250)` | `oklch(0.33 0.016 235)` |
| `textPrimary` | `#0D2436` | `oklch(0.96 0.004 250)` |
| `textSecondary` | `oklch(0.32 0.012 250)` | `oklch(0.82 0.01 250)` |
| `textMuted` | `#5F7387` | `oklch(0.68 0.012 250)` |
| `textFaint` | `#9CAFBF` | `oklch(0.6 0.012 250)` |
| `inputBorder` | `#DCE7EF` | `oklch(0.4 0.014 250)` |
| `inputBg` | `#ffffff` | `oklch(0.23 0.014 250)` |
| `divider` | `#E9F0F5` | `oklch(0.33 0.014 250)` |
| `navBg` | `#ffffff` | `oklch(0.2 0.014 250)` |
| `navMuted` | `#9CAFBF` | `oklch(0.55 0.012 250)` |
| `shCard` | `0 4px 14px rgba(20,90,141,0.06)` | `0 4px 14px rgba(0,0,0,0.30)` |
| `shRaise` | `0 6px 20px rgba(20,90,141,0.07)` | `0 6px 20px rgba(0,0,0,0.34)` |
| `shNav` | `0 -6px 24px rgba(20,90,141,0.08)` | `0 -6px 24px rgba(0,0,0,0.36)` |
| `stripe1` | `oklch(0.93 0.008 250)` | `oklch(0.28 0.012 250)` |
| `stripe2` | `oklch(0.97 0.004 250)` | `oklch(0.24 0.01 250)` |
| `chipNeutralBg` | `#E1EDF5` | `oklch(0.3 0.014 250)` |
| `chipNeutralText` | `#5F7387` | `oklch(0.8 0.01 250)` |
| `verifiedBg` | `oklch(0.95 0.03 152)` | `oklch(0.3 0.06 152)` |
| `verifiedText` | `oklch(0.38 0.11 152)` | `oklch(0.85 0.09 152)` |
| `pendingBg` | `oklch(0.96 0.045 80)` | `oklch(0.32 0.07 80)` |
| `pendingText` | `oklch(0.45 0.13 80)` | `oklch(0.88 0.1 80)` |
| `notUploadedBg` | `#E1EDF5` | `oklch(0.3 0.014 250)` |
| `notUploadedText` | `#5F7387` | `oklch(0.75 0.012 250)` |
| `selectedBg` | `oklch(0.96 0.02 235)` | `oklch(0.28 0.05 235)` |
| `sectionAlt` | `oklch(0.97 0.004 250)` | `oklch(0.2 0.012 250)` |
| `infoBg` | `oklch(0.96 0.02 235)` | `oklch(0.26 0.05 235)` |
| `infoBorder` | `oklch(0.88 0.03 235)` | `oklch(0.36 0.06 235)` |
| `infoTitle` | `#061326` | `#bcdcf5` |
| `infoText` | `#145A8D` | `#9dcdf0` |
| `accentText` | `#145A8D` | `#75BDEB` |
| `creditColor` | `oklch(0.5 0.13 152)` | `oklch(0.68 0.13 152)` |
| `subtleBg` | `oklch(0.965 0.006 250)` | `oklch(0.21 0.012 250)` |
| `dangerBg` | `oklch(0.96 0.04 25)` | `oklch(0.32 0.07 25)` |
| `dangerText` | `oklch(0.48 0.17 25)` | `oklch(0.88 0.1 25)` |

`navPillBg` (`#E1EDF5` light) is **not** in `PAL` — it is an inline literal in
the canvas, so its dark form is the one derived colour left in
`AppPalette`. Same for the two gradients below.

Balance card gradient:

- light — `radial-gradient(135% 120% at 85% -15%, #16406B 0%, #0A2242 45%, #061326 100%)`
- dark — `radial-gradient(135% 120% at 85% -15%, #1B4B7A 0%, #0C2A4E 45%, #08192E 100%)`

Appearance is user-selectable in Settings → Appearance: Light, Dark, System.

### Surface treatment

Resynced 2026-08-20. The design audited its own screens, found they read
"correct and joyless — a form, not a product", and named five causes. Four of
them are surface, and this is the fix it committed to. **Depth is carried by
tinted shadow; there are no grey borders on cards any more.**

| Layer | Radius | Shadow |
|---|---|---|
| Hero (dashboard header, balance card) | 26 | `0 12px 28px rgba(13,61,98,0.30)` |
| Card (ledger entry, listing, form section) | 22 | `0 6px 20px rgba(20,90,141,0.07)` |
| Row (category tile, money row, input group) | 18 | `0 4px 14px rgba(20,90,141,0.06)` |
| Icon plate | 13 | none |
| Nav sheet | 26 top | `0 -10px 30px rgba(13,36,54,0.20)` — casts **up** |
| Primary button | 15 | `0 8px 20px rgba(20,90,141,0.30)` — own hue |
| Accept (success) button | 15 | `0 8px 20px oklch(0.5 0.13 152 / 0.30)` |

The rest of the fix:

- **Blue as a field, not trim.** The hero is a real gradient —
  `linear-gradient(145deg, #1E7BB5 0%, #145A8D 52%, #0D3D62 100%)` — carrying
  its own actions, and the primary button is a solid blue with a coloured
  shadow. Blue is no longer just link text and one navy card.
- **Numbers become charts.** A provider's month is seven rounded bars with
  today emphasised plus a delta pill, not the string "4 jobs". Same numbers,
  read in one glance.
- **Nav is a raised sheet**, 26 px top radius, with a tinted 42 × 30 pill
  behind the active icon — replacing a hairline strip.
- **Ledger structure.** Each entry is a card, with VAT tied to its parent fee
  by a dashed tie-line and stub, so a fee and its tax read as one event rather
  than two lookalike rows.

None of it costs performance on the target handsets: one linear gradient, box
shadows and border radii. No images, no blur, no gradient meshes. The
data-saver and reduce-motion rules still hold.

### Category hues

Each category owns a **hue angle**. Both colours are constructed from it, so a
new category picks an angle rather than two hex codes:

- plate — `oklch(0.95 0.035 <hue>)`
- ink (the icon) — `oklch(0.5 0.13 <hue>)`

The tile is a Material Symbol on that tinted plate. **The two-letter monograms
are gone** — they were placeholders, and the design replaced them because
"category identity sitting in a 3 px bar and a grey monogram" was one of the
five reasons the screens read flat.

Note the hues are now spread across the whole wheel (25–330). The earlier set
was clustered in the blue-teal band, which made nine categories look like one.

| Key | Icon (Material Symbol) | Hue | Label |
|---|---|---|---|
| `rides` | `directions_car` | 230 | Rides |
| `movers` | `local_shipping` | 205 | Movers & hauling |
| `rentals` | `meeting_room` | 255 | Property rentals |
| `beauty` | `content_cut` | 330 | Hairdressing & beauty |
| `plumbing` | `plumbing` | 180 | Plumbing |
| `electrical` | `electrical_services` | 85 | Electrical |
| `tiling` | `grid_view` | 40 | Tiling |
| `catering` | `restaurant` | 25 | Catering |
| `hire` | `chair` | 300 | Hire |

Every tile also carries a real supply count — "62 nearby", "4 nearby",
"34 rooms". Thin supply is stated, never hidden: a home screen that flatters a
thin category looks broken the moment the customer taps into it.

## Type

**IBM Plex Sans**, mapped onto Material 3's five type roles so it drops into
Flutter's `TextTheme` without a custom scale to maintain. **IBM Plex Mono** is
reserved for money, timestamps and OTP only — tabular figures keep `P250.00` and
`P1 200.00` aligned in lists, and a monospace figure signals "check this number".

Body text never drops below 13 px. No condensed or decorative faces: they lose
legibility fastest exactly where this product needs it most — requirements text,
prices, consent copy.

| Role | Size / weight / line-height | Use |
|---|---|---|
| Display | 32 / 700 / 40 | Hero numbers, empty states |
| Headline | 24 / 700 / 30 | Screen titles |
| Title Large | 19 / 600 / 26 | Section & listing names |
| Title Medium | 16 / 600 / 22 | Card titles, list headlines |
| Body Large | 15 / 400 / 22 | Descriptions, requirements |
| Body Small | 13 / 400 / 18 | Helper & secondary text |
| Label | 13 / 600 / 16 | Buttons, tabs, badges |
| Caption | 11 / 500 / 14 | Timestamps, metadata |
| Mono Figure | IBM Plex Mono 600 | Money, balances, OTP |

## Spacing, touch, responsive

- **4 px base grid. 48 dp minimum touch target.**
- No layout depends on an image loading before it is usable — text and
  structure render first.
- Breakpoints follow Material 3 window size classes via `LayoutBuilder`:
  **compact** under 600 dp (phones, 2-column category grid), **medium**
  600–840 dp, **expanded** over 840 dp (3-column category grid).
- Every screen is built with flex and grid percentages, not fixed pixel widths,
  and reflows at those breakpoints rather than needing a separate tablet design.
- Single-column forms (become a provider, create listing, booking) gain a
  max-width and center themselves instead of stretching edge to edge.

## Components

Rebuilt on the surface treatment above: 13–18 px radii on containers, 15 px on
buttons, tinted shadows instead of grey borders, and **intent carried by
colour** — success for accept, danger for decline, warning for anything under
review.

| Component | Spec |
|---|---|
| Primary button | `#145A8D` fill, white text, radius 15, padding 14×24, label 15/600, shadow `0 8px 20px rgba(20,90,141,0.30)` |
| Accept button | success fill, white text, radius 15, shadow in the success hue. Paired with Decline — **never two blue buttons side by side**; the pair has to be readable at a glance |
| Decline button | danger-toned outline, radius 15 |
| Secondary button | white fill, `#145A8D` text, 1.5 px `#145A8D` border, radius 15, padding 12.5×24 |
| Text action | transparent, `#145A8D` text, padding 8×4 |
| Disabled button | `chipNeutralBg` fill, `oklch(0.65 0.012 250)` text, no border, no shadow |
| Input group | white, radius 18, padding 16, row shadow; label 12/600 above, helper 11.5 faint below |
| Input field | 1.5 px border (`inputBorder`, `#145A8D` on focus, `oklch(0.86 0.07 25)` on error), radius 13, padding 12×13, mono 14.5 for figures |
| Status signal | hue **plus a glyph** — `verified_user` / `hourglass_top` / `error`. Status never depends on colour alone |
| Verified chip | `verifiedBg` / `verifiedText`, radius 100, 12.5/600, text `Verified · <Category>` |
| New-provider chip | `chipNeutralBg` / `chipNeutralText`, radius 100, 12.5/600, text `New on Ipelege` |
| Money row | fee line with its VAT nested under it on a dashed tie-line — e.g. `Commission · 8% of P120 · −P9.60` over `VAT · 14% · −P1.34`. Never one bundled figure |
| Category tile | white card, radius 18, padding 13, row shadow; 36 px icon plate radius 13 in `oklch(0.95 0.035 <hue>)` with a 20 px Material Symbol in `oklch(0.5 0.13 <hue>)`; label 12.5/700; supply count 10 muted |
| Nav | raised sheet, radius 26 top, upward shadow; active icon filled `#145A8D` on a 42×30 `#E1EDF5` pill radius 11, label 9.5/700; inactive icon `#9CAFBF`, label `#5F7387` |

## Motion

**The canvas table is the authority.** Motion explains a change; it never
decorates one. Anything entering in place travels **12 dp at most** — only
sheets go further. **Nothing loops** except the incoming-ride countdown, which
the design names as the single exception.

Read from part 4 of the split canvas. Every duration below is stated there; none
of them is inferred.

| Transition | Duration | Curve & movement |
|---|---|---|
| Tab change | 120 ms | Cross-fade only, **no slide**. Tabs are siblings, not a journey. |
| Push to detail | 220 ms | Ease-out, slide in from the right, **16 px parallax on the outgoing screen**. |
| Bottom sheet | 260 in / 180 out | Ease-out on entry, ease-in on dismissal. Scrim fades over the same interval. |
| Booking state change | 300 ms | Chip colour and step bar animate **together**, so the change reads as one event. |
| Incoming ride request | 180 ms | Sheet rises fast, timer starts immediately. The countdown is **the only looping animation in the app**. |
| Wallet balance update | 400 ms | Figure counts to the new amount. Money changing deserves to be noticed. |
| Verification status change | none | Arrives by notification, so the screen is simply correct when opened. |

The tokens that carry it, in `theme/motion.dart`:

```dart
abstract final class Motion {
  static const tap         = Duration(milliseconds: 120);
  static const tabChange   = Duration(milliseconds: 120); // cross-fade only
  static const enter       = Duration(milliseconds: 220);
  static const exit        = Duration(milliseconds: 160);
  static const page        = Duration(milliseconds: 220); // + pushParallax
  static const sheet       = Duration(milliseconds: 260);
  static const sheetOut    = Duration(milliseconds: 180);
  static const stateChange = Duration(milliseconds: 300);
  static const count       = Duration(milliseconds: 400);
  static const none        = Duration.zero;

  static const curve    = Curves.easeOutCubic;
  static const curveOut = Curves.easeInCubic;

  static const travel       = 12.0; // anything entering in place
  static const pushParallax = 16.0; // the outgoing screen under a push

  // Every duration goes through here. No exceptions.
  static Duration of(BuildContext c, Duration d) =>
      MediaQuery.of(c).disableAnimations ? none : d;
}
```

> **Corrected 2026-08-20.** This section previously carried a seven-token block
> with `sheet: 280`, `page: 250` and `count: 600`, and no tab-change or parallax
> at all — values that predate the restyle and appear nowhere in the canvas. The
> resync **appended** the recovered table further down the document instead of
> replacing the stale block, so this file contained two `## Motion` sections
> disagreeing with each other, and `theme/motion.dart` was built from the wrong
> one. The duplicate is gone and the numbers above are the canvas's own.

### The three that carry the most meaning

| Moment | Behaviour | Implementation |
|---|---|---|
| A balance that changed | Fires when a top-up settles or a reversal is confirmed. **Never on load** — a figure that animates every time you look at it reads as a live feed. | `motion.count` · `TweenAnimationBuilder` |
| A request arriving | Rises 12 dp and fades in at the top of the inbox. The count above it steps at the same moment rather than animating on its own. | `motion.enter` · `AnimatedList.insertItem` |
| A stage advancing | The bar grows to the next stop and the label crossfades. No bounce, no pulse on the active dot. | `motion.enter` · `AnimatedContainer` + `AnimatedSwitcher` |

### Booking states

The pattern: **forward progress animates, every ending is instant.** A state
that reverses or fails should not travel across the screen as though something
were being achieved.

| State | What moves | Flutter |
|---|---|---|
| `REQUESTED` | Screen replaces the request flow, step 1 fills. Countdown ticks in text — no animated ring | `go()` + `AnimatedContainer` |
| `ACCEPTED` | Step 2 fills, chip crossfades pending → ok, provider row rises 12 dp into place | `AnimatedContainer` + `AnimatedSwitcher` + medium haptic |
| `IN_PROGRESS` | Step 3 fills. Nothing else moves — long-lived state, so nothing may pulse | `AnimatedContainer` only |
| `AWAITING_PAYMENT` | Step 4 fills and the pay panel slides up 12 dp. Highest-attention moment in the flow | `AnimatedSwitcher` + `SlideTransition` |
| `PENDING_CONFIRMATION` | Step 5 fills, action swaps to the confirm pair. No auto-scroll | `AnimatedSwitcher` |
| `COMPLETED` | Bar completes, then the rating row fades in 120 ms later. One medium haptic, no confetti | sequenced, `mediumImpact` |
| `DECLINED` | Chip and body change instantly at `motion.none`. Alternatives list fades in after | no transition on the chip |
| `EXPIRED` | Instant. Steps grey out together, no travel | `motion.none` |
| `CANCELLED` | Instant | `motion.none` |

> The design carries **eleven** booking states. The full set and its copy live
> in `design/ipelege-ds-2-customer.dc.html` and land with Phase 2 of
> [build-order.md](build-order.md) — two of them, `DISPUTED` and `NO_SHOW`, are
> blocked on product decisions and have no honest copy yet.

### Code rules

**Do**

- Reach for implicit animations first — `AnimatedContainer`, `AnimatedOpacity`,
  `AnimatedSwitcher`, `TweenAnimationBuilder`. A controller is warranted only to
  sequence, reverse or interrupt.
- Route every duration through one helper that checks
  `MediaQuery.disableAnimations`. Reduce-motion is a battery decision here, not
  an accessibility edge case.
- Animate transform and opacity — `SlideTransition`, `FadeTransition`. Width,
  padding and margin re-run layout on every frame.
- Keep the animated subtree small and hold `const` children outside the builder.
- Sequence where order carries meaning: reversal rows land, *then* the balance
  moves. That is the order the events actually happened in.
- Dispose every controller, and test on a real entry-level handset rather than
  the emulator.

**Don't**

- No loops. No shimmer sweeps, pulsing dots or spinning marks — they hold the
  GPU awake and drain a battery that is the user's lifeline.
- No celebration on money events. Payment happens person to person outside the
  app; confetti over a completion we never processed misstates what happened.
- Never animate the balance on first paint, and never animate a gate turning
  red. Errors appear instantly, at `motion.none`.
- No entrance animation on cold start. Content first; motion belongs to change,
  and nothing has changed yet.
- No `BackdropFilter`, no parallax, no shadow tweens.
- Never gate a tap on an animation finishing. Take the input immediately and let
  the motion catch up.

## Navigation

### Two tab sets, one login

Each mode has its own bottom bar, and each tab keeps its own stack. Switching
mode **replaces** the bar rather than adding to it, so a provider deep in a
listing does not carry that history into the consumer side.

| Mode | Tabs |
|---|---|
| Consumer | Home · Bookings · Messages · Account |
| Service provider | Dashboard · Requests · Listings · Account |

The wallet is deliberately **not** a tab — it hangs off the provider dashboard,
because a provider goes there to fix a problem, not to browse. Tabs carry
navigation only; every action stays in the context that produced it.

### Sideways is not forward

Three movements look similar on screen and must not be built the same way.

- **Push** — a listing, a booking, a form step. Adds to the stack; back pops it.
  The only movement that deepens history.
- **Lateral** — changing tab, changing category, changing the browse filter.
  Replaces content in place, adds nothing to the stack. Back returns to the home
  tab, not through every tab visited.
- **Replace** — booking created, listing published, mode switched, OTP verified.
  The flow behind it is discarded, so back cannot re-enter it and post a second
  deduction.

The app bar back arrow and the system gesture always do the same thing.

### What the system back gesture does

Written as a specification, not guidance — Android's back gesture is trusted
more than anything on screen, so these are rules rather than preferences.

| Rule | Behaviour |
|---|---|
| Tab roots | Back from Bookings, Wallet or Account lands on **Home**. Back from Home **exits** — it does not cycle through previously visited tabs. |
| Sheets and dialogs | One gesture dismisses **the top layer only**. A sheet over a screen takes two gestures to leave the screen. |
| Multi-step flows | Step back one field group, **holding entered values**. Nothing clears until the flow is abandoned deliberately. |
| Unsaved work | Asks first — but **only** where real typing or an upload would be lost: create listing, verification, a written review. Never on a screen the person only read. |
| Blocked entirely | During an **OTP round trip**, and while a **payment or top-up is in flight**. Both show progress instead, because the result is already server-side. |
| Mode switching | **Resets the stack.** Provider mode starts fresh at provider home; back returns to customer home, not into provider history. |

### State restoration

Restoration is a requirement, not a polish item — the OS reclaims memory
constantly on these handsets. Notably: a provider who backgrounds the app
mid-KYC and comes back an hour later, after Android has killed the process, must
land on the same step with the same documents attached. **That is why the draft
persists to local storage on every field change, not on a save action** — a
save button the process never reaches is not a save.

> **Corrected 2026-08-20.** This said the KYC draft "lives on the server from
> the moment of upload", which was inferred and contradicted the design twice in
> the very next subsection. The canvas is explicit in both places: *"half-finished
> verification uploads, stored **locally** until submitted"* and *"drafts persist
> to **local storage** on every field change"*. Local, not server — the
> difference decides whether an unsubmitted Omang ever leaves the handset, which
> is a privacy position, not an implementation detail.

### What survives being killed

Cheap phones kill backgrounded apps often, and reopening should not feel like
starting over.

**Kept:** half-finished verification uploads (stored locally until submitted) ·
a listing draft including photos already picked · the tab you were on and the
scroll position in a long list · provider online state and the ride you were on.

**Not kept:** search text · filter selections · any OTP already sent.

> **The session itself is kept — implemented 2026-08-21.** The entry rules say
> "the session then persists until explicit logout", so name, number, consent
> version, channels and the biometric answer survive a kill.
>
> **It never comes back signed in.** With biometric unlock on it restores to
> `locked` and the unlock screen reopens it; with it off the app goes back
> through the code, which is what Security promises in those words. And *"any
> OTP already sent"* is honoured literally: a session caught mid-verification
> is dropped rather than resumed, along with its attempt count.
>
> See `app/lib/core/session_store.dart`.

Implementation note from the design: tab roots use nested `Navigator`s with a
`PopScope` at each root, and drafts persist to local storage **on every field
change**, not on a save action.

## Feedback

### Haptics

**Three uses only** — a phone that buzzes at everything gets muted, and then the
three that mattered are gone too.

| Strength | When |
|---|---|
| Light | Accepting or declining a request; confirming a booking is done. |
| Heavy | An incoming ride request, alongside the ringtone. |
| Error | A wrong OTP or a failed top-up, paired with the message. |

> **Corrected 2026-08-20.** This said "four moments … the four where money
> moves", which is not what the canvas specifies — it names three, and two of
> them (a request accepted, a wrong OTP) are not money moving at all. The
> recovered table had been appended in a second `## Motion` section rather than
> replacing this prose.

### Loading and saving

One loading treatment for every wait is the mistake. A 200 ms cached read and a
6 s upload on 3G need opposite things, and on these phones the second case is
not rare.

- Lists load as **skeleton cards in the shape they will take**, never a centred
  spinner on an empty page.
- Buttons **spin in place and keep their label width**, so nothing reflows under
  the thumb.
- Settings **save on change**, no confirm button. A failure reverts the control
  and says why.
- Offline shows **the last known data under a banner**, not an empty screen.
  Actions queue and retry.

### What gets kept

Autosave is right for effort and wrong for money. A listing draft should survive
anything; a top-up amount should survive nothing. The full kept/not-kept list is
under [Navigation](#navigation).

## Light and dark

One control on Preferences — Light / Dark / System — drives every screen. Four
rules govern the swap:

1. **Surfaces lift, they do not just darken.** Dark cards sit *lighter* than the
   page behind them, keeping the same raised-card reading as light mode.
2. **Brand blue lightens.** `#145A8D` fails contrast on a dark surface, so text
   and icons switch to a lighter tint — while the gradient hero keeps the deep
   brand blue.
3. **Status colours desaturate the fill and brighten the text.** A verified chip
   on dark is a muted green ground with a bright green label, never the
   light-mode pair inverted.
4. **Shadows go black, not blue.** The blue tint disappears on dark surfaces and
   opacity carries the elevation instead.

System mode reads `MediaQuery.platformBrightness`.

## Screen inventory

Every screen is mocked up in **both light and dark**, so the 25 screen labels in
the current pull are roughly fifty rendered mockups. There is no target screen
count — the design says the number "falls out of the journey, and it is still
growing as states get named". Once every state needing its own layout is counted
(eleven booking states, five verification states per category, six mode-switch
conditions, five top-up states) the real inventory is nearer thirty and opening.

**Flutter status** below is this repo, not the design. The *order* those get
built in is not a matter of taste — see [build-order.md](build-order.md), which
is enforced by `app/test/routing/build_order_test.dart`.

| Stage | Screen | In the pull | Flutter |
|---|---|:--:|:--:|
| 0 Arrival | Splash / first open | ✓ | — |
| | Auth gate sheet | ✓ | — |
| | Location permission | ✓ | — |
| 1 Account | Register · Sign in · Consent capture | ✓ | — |
| | Onboarding / OTP | ✓ | — |
| | Biometric unlock + passcode | ✓ | — |
| 2 Discover | Home | ✓ | ✓ |
| | Category browse | ✓ | ✓ |
| | Listing detail | ✓ | ✓ |
| | Search + no-results | — | — |
| 3 Book & settle | Booking request | ✓ | — |
| | Booking status · 11 states | ✓ | — |
| | Rate & review | ✓ | — |
| | Raise dispute | — | — |
| 3B Rides | Ride request & tracking | ✓ | — |
| 4 Become a provider | Category picker | ✓ | — |
| | Per-category KYC (9) | partial | — |
| | Verification status · 5 states | — | — |
| 4B Both roles | Mode switcher (2 variants) | ✓ | — |
| | My categories (the matrix) | ✓ | partial |
| | Provider home | ✓ | ✓ |
| 5 Run the business | Wallet | ✓ | ✓ |
| | Top up | ✓ | — |
| | Booking inbox | ✓ | — |
| | Create listing · My listings | past the cut | — |
| | Rental listing flow | past the cut | — |
| 6 Account & rights | Settings · Privacy · Export / delete | past the cut | — |
| 7 The loop | Cross-category prompt | — | — |

"past the cut" means the screen exists in the design project but sits beyond the
256 KiB read cap — see
[design-deltas.md](design-deltas.md#one-snapshot-freshly-pulled).

The back office is a separate canvas with its own tokens —
[admin-design.md](admin-design.md).

## Three rules the screens enforce, not just render

From the journey map. Each changes behaviour, not appearance.

1. **Property rentals never offers a booking.** Pay-per-listing: no booking, no
   commission, no completion. The tenant enquires and leaves the app.
2. **New providers get a placement boost**, not only the "New on Ipelege" chip.
   Ratings must be built *with* the boost or you manufacture provider churn.
3. **Payment precedes "mark complete."** Service delivered → customer pays the
   provider directly → provider marks complete → customer confirms → commission
   posts.

And one the copy must respect: when a listing is unavailable because the
provider's credit is short, **the customer is never told that reason**
(UC-5 4a).
