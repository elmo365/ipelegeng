# Design system

Imported from the Claude Design project **"Ipelege app design system"**
(`012e55a7-8d3d-4aed-abf7-f1ab95fadf63`) on 2026-08-17. The source page is
archived at [`design/ipelege-design-system.dc.html`](../design/ipelege-design-system.dc.html);
this document is the implementable extract of it.

Where the design and the older specification documents disagree, see
[design-deltas](design-deltas.md). The design is the newer layer.

Target: Flutter, Android-first, Android 8+, binary under 30 MB, 3G, 1–2 GB RAM
handsets. Material 3 bones, Ipelege skin.

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

| Token | Light | Dark |
|---|---|---|
| `screenBg` | `#ffffff` | `oklch(0.17 0.012 250)` |
| `screenBg2` | `oklch(0.985 0.004 250)` | `oklch(0.14 0.01 250)` |
| `cardBg` | `#ffffff` | `oklch(0.23 0.014 250)` |
| `cardBorder` | `oklch(0.91 0.008 250)` | `oklch(0.33 0.014 250)` |
| `textPrimary` | `#111111` | `oklch(0.96 0.004 250)` |
| `textSecondary` | `oklch(0.32 0.012 250)` | `oklch(0.82 0.01 250)` |
| `textMuted` | `oklch(0.5 0.014 250)` | `oklch(0.68 0.012 250)` |
| `textFaint` | `oklch(0.55 0.014 250)` | `oklch(0.6 0.012 250)` |
| `inputBorder` | `oklch(0.82 0.01 250)` | `oklch(0.4 0.014 250)` |
| `inputBg` | `#ffffff` | `oklch(0.23 0.014 250)` |
| `divider` | `oklch(0.91 0.008 250)` | `oklch(0.33 0.014 250)` |
| `navBg` | `#ffffff` | `oklch(0.2 0.014 250)` |
| `navMuted` | `oklch(0.75 0.012 250)` | `oklch(0.5 0.012 250)` |
| `stripe1` | `oklch(0.93 0.008 250)` | `oklch(0.28 0.012 250)` |
| `stripe2` | `oklch(0.97 0.004 250)` | `oklch(0.24 0.01 250)` |
| `chipNeutralBg` | `oklch(0.91 0.008 250)` | `oklch(0.3 0.014 250)` |
| `chipNeutralText` | `oklch(0.4 0.014 250)` | `oklch(0.8 0.01 250)` |
| `verifiedBg` | `oklch(0.95 0.03 152)` | `oklch(0.3 0.06 152)` |
| `verifiedText` | `oklch(0.35 0.1 152)` | `oklch(0.85 0.09 152)` |
| `pendingBg` | `oklch(0.96 0.045 80)` | `oklch(0.32 0.07 80)` |
| `pendingText` | `oklch(0.45 0.13 80)` | `oklch(0.88 0.1 80)` |
| `notUploadedBg` | `oklch(0.91 0.008 250)` | `oklch(0.3 0.014 250)` |
| `notUploadedText` | `oklch(0.5 0.014 250)` | `oklch(0.75 0.012 250)` |
| `selectedBg` | `oklch(0.96 0.02 235)` | `oklch(0.28 0.05 235)` |
| `sectionAlt` | `oklch(0.97 0.004 250)` | `oklch(0.2 0.012 250)` |
| `infoBg` | `oklch(0.96 0.02 235)` | `oklch(0.26 0.05 235)` |
| `infoBorder` | `oklch(0.88 0.03 235)` | `oklch(0.36 0.06 235)` |
| `infoTitle` | `#061326` | `#bcdcf5` |
| `infoText` | `#145A8D` | `#9dcdf0` |
| `accentText` | `#145A8D` | `#75BDEB` |
| `creditColor` | `oklch(0.5 0.13 152)` | `oklch(0.68 0.13 152)` |
| `subtleBg` | `oklch(0.965 0.006 250)` | `oklch(0.21 0.012 250)` |
| `dangerBg` | `oklch(0.95 0.045 25)` | `oklch(0.32 0.07 25)` |
| `dangerText` | `oklch(0.42 0.16 25)` | `oklch(0.88 0.1 25)` |

Balance card gradient:

- light — `radial-gradient(135% 120% at 85% -15%, #16406B 0%, #0A2242 45%, #061326 100%)`
- dark — `radial-gradient(135% 120% at 85% -15%, #1B4B7A 0%, #0C2A4E 45%, #08192E 100%)`

Appearance is user-selectable in Settings → Appearance: Light, Dark, System.

### Category hues

Each category owns a hue at chroma 0.12, lightness 0.55 for the tile
(`oklch(0.55 0.12 <hue>)`), plus a two-letter monogram. Monograms are
placeholders — swap for real iconography before ship.

| Key | Monogram | Hue | Label |
|---|---|---|---|
| `rides` | RI | 230 | Rides |
| `movers` | MV | 205 | Movers & hauling |
| `rentals` | PR | 255 | Property rentals |
| `beauty` | HB | 215 | Hairdressing & beauty |
| `plumbing` | PL | 245 | Plumbing |
| `electrical` | EL | 265 | Electrical |
| `tiling` | TL | 185 | Tiling |
| `catering` | CA | 195 | Catering |
| `hire` | HR | 155 | Hire |

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

| Component | Spec |
|---|---|
| Primary button | `#145A8D` fill, white text, radius 12, padding 14×24, label 15/600 |
| Secondary button | white fill, `#145A8D` text, 1.5 px `#145A8D` border, radius 12, padding 12.5×24 |
| Text action | transparent, `#145A8D` text, padding 8×4 |
| Disabled button | `chipNeutralBg` fill, `oklch(0.65 0.012 250)` text, no border |
| Input | 1.5 px border (`inputBorder`, `#145A8D` on focus), radius 10, padding 12×14, text 15; label 13/500 above, helper 12 muted below |
| Verified chip | `verifiedBg` / `verifiedText`, 14 px success dot, radius 100, 12.5/600, text `Verified · <Category>` |
| New-provider chip | `chipNeutralBg` / `chipNeutralText`, radius 100, 12.5/600, text `New on Ipelege` |
| Category tile | 96 px wide, white card, 1 px `cardBorder`, radius 14, padding 14×8; 40 px monogram square radius 11 in the category hue; label 12/600 centered |

## Motion

Seven tokens. Motion explains a change; it never decorates one. Anything
entering in place travels **12 dp at most** — only sheets go further. **Nothing
loops.**

```dart
class Motion {
  static const tap   = Duration(milliseconds: 120);
  static const enter = Duration(milliseconds: 220);
  static const exit  = Duration(milliseconds: 160);
  static const sheet = Duration(milliseconds: 280);
  static const page  = Duration(milliseconds: 250);
  static const count = Duration(milliseconds: 600);
  static const none  = Duration.zero;

  static const curve    = Curves.easeOutCubic;
  static const curveOut = Curves.easeInCubic;

  // Every duration goes through here. No exceptions.
  static Duration of(BuildContext c, Duration d) =>
      MediaQuery.of(c).disableAnimations ? none : d;
}
```

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

> The design page lists eleven booking states; the archived copy was truncated
> after `CANCELLED`. See [design-deltas](design-deltas.md#truncated-in-import).

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

### State restoration

Restoration is a requirement, not a polish item — the OS reclaims memory
constantly on these handsets. Notably: a provider who backgrounds the app
mid-KYC and comes back an hour later, after Android has killed the process, must
land on the same step with the same documents attached. **That is why the KYC
draft lives on the server from the moment of upload rather than in the widget
tree.**

> The design page carries two full specification tables here — *what the system
> back button does, everywhere* (11 rows) and *what survives going back*
> (6 rows). Both were lost to the import truncation; see
> [design-deltas](design-deltas.md#truncated-in-import).

## Feedback

### Haptics

Four moments earn a real buzz, and they are the four where money moves.
Everything else is either the lightest possible click or silence — a phone that
vibrates constantly gets its haptics switched off in system settings, and then
the four that mattered are gone too.

### Loading

One loading treatment for every wait is the mistake. A 200 ms cached read and a
6 s upload on 3G need opposite things, and on these phones the second case is
not rare. Treatment is banded by expected duration.

### What gets kept

Autosave is right for effort and wrong for money. A listing draft should survive
anything; a top-up amount should survive nothing.

> The detailed haptics, loading-band and saved-state tables were lost to the
> import truncation; see [design-deltas](design-deltas.md#truncated-in-import).

## Screen inventory

Mocked up in the design page, in light and dark:

**Entry & account** — Splash · Register · Sign in · Biometric unlock · Consent ·
Auth gate · Location permission

**Customer** — Onboarding · Home · Category browse · Listing detail · Booking
request · Booking status (full state set) · Ride request & tracking · Rate and
review

**Mode & provider** — Mode switcher (both variants) · Provider home · My
categories · Become a provider · Create listing · Booking inbox · Wallet ·
Rental listing flow

**Settings** — Settings · Biometric enrolment · Notifications · Data & storage ·
Appearance

The admin panel is out of scope for the mobile design.
