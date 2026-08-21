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

**The motion pass ran on 2026-08-21, and found the other half of the same
failure.** The corrected durations were consumed by the router, the button
ripple, the two sheets and one category tile — and by nothing else. No screen
held a single `AnimatedContainer`, `AnimatedSwitcher` or
`TweenAnimationBuilder`, so the transition table's two most-specified rows —
the 300 ms booking state change with its eleven-row per-state table, and the
400 ms wallet count — were simply absent. Correcting a token is not
implementing it.

Both are built now, and `app/test/ui/motion_test.dart` pins the rules rather
than the numbers: chip and step bar on **one** duration, forward progress
animates and every ending is instant, a screen opened *at* a state does not
replay reaching it or buzz for it, the balance counts only when it changes, and
reduce-motion collapses to zero rather than shortening. Three findings came out
of it and are written up in [`design-deltas.md`](design-deltas.md) §17: the
design's "medium haptic" names a strength `core/haptics.dart` deliberately does
not have, an ending greys its steps out by removing them, and two Flutter traps
that produce motion which looks implemented and is not.

**The gate is now a script rather than a ritual**, which is the lesson both of
its failures were really about — a gate nobody can re-run is a gate that gets
skipped, and this one has now been skipped once and run too narrowly once.
`app/integration_test/gate_test.dart` walks every screen built since
2026-08-20, in light and in dark, on a real device, and writes one PNG per
artboard into `app/build/gate/`:

```
cd app
flutter drive --driver=test_driver/integration_test.dart   --target=integration_test/gate_test.dart -d <device-id>
```

It reaches each screen by overriding `routerProvider` — the seam the widget
tests already use — rather than by tapping through the app, because a gate that
has to complete a nine-step journey to photograph the ninth screen fails at
step two and shows nothing. It asserts almost nothing on purpose: what it
produces is **evidence for a comparison against the artboards**, and every rule
that can be asserted instead lives in `app/test/`, where it runs in a second.

**The colour half then ran, on 2026-08-21 — 28 screens, both modes.** The
palette holds: every surface, plate and chip reads as the canvas specifies, and
the dark mode most of these screens had never been rendered in is correct.

What it found is a class of bug neither a widget test nor an artboard
comparison can catch, because artboards draw controls in their *chosen* state:
**three interactive controls were invisible at rest.** An empty rating star at
1.4:1 against the card in dark, the **required** consent tick at 1.8:1, and the
notification switches with it — all drawn in hairline tokens against WCAG
1.4.11's 3:1 floor. The rating screen is the sharpest case, since its five
stars are its only input and its own copy calls the rating "the only signal a
new provider has".

Fixed with a token rather than three patches — `AppPalette.controlOutline`,
carrying `textMuted`'s existing value so no colour the design never specified
entered the app — and pinned in both directions by
`app/test/theme/contrast_test.dart`: a control must clear 3:1, and `divider`
must stay *under* it, because "fixing" contrast by darkening the hairline would
give every card a visible border and undo the design's shadow-not-borders
treatment. Written up in [`design-deltas.md`](design-deltas.md) §18, along with
why the loop prompt's completed-booking placement cannot be photographed and
should not be made to be.

**The gate was then found to be photographing fakes, and fixed.** The first two
runs pumped `IpelegeApp` with only the router overridden, so the unlock screen
answered `AlwaysAllowBiometrics` — a gate that runs on a device to see what the
device does, and asks a stub instead. It now applies the same
`biometricsProvider` override `main()` does.

That verified a branch that had never run against the real platform. The
emulator has a fingerprint sensor with **no enrolled print and no device
credential**, which is exactly the design's *"biometry unavailable → passcode"*
case, and the screen came back correct: no fingerprint button, no copy naming
one, **Enter device passcode** promoted to the primary. It also caught the one
element that was not conditional — a hardcoded 50 dp fingerprint glyph sitting
directly over the words "Use your device passcode to continue". A picture is
copy. Fixed, and pinned by a test verified to fail without the fix.

**Then a real handset was paired, and the last branch closed.** A Galaxy S24
(Android 16, three enrolled prints) joined over wireless adb, and the gate run
against it produced the opposite answer to the emulator from the same code:
fingerprint glyph, fingerprint copy, **Use fingerprint** as the primary. The
conditional is verified from both sides, not just the broken one.

`app/integration_test/biometric_test.dart` then raised a **real system prompt**
and a **real fingerprint** carried a locked session back to `active`. It is a
separate target from the gate because a gate is unattended and this waits for a
person to touch a sensor. Every branch of `core/biometrics.dart` has now run
against a real platform. Written up in
[`design-deltas.md`](design-deltas.md) §18.5.

**Phase 0 is closed, and so is Phase 1** — apart from the four brand cuts that
exceed the fetch cap, which only the design side can clear.

**Two things that cost a run, before anyone repeats them** (§18.6): a sleeping
screen kills an on-device gate with three symptoms that name nothing —
`Window doesn't have a backing surface!`, SIGKILL, `Service has disappeared` —
and **no screenshots survive**, because the driver flushes at the end. And
device runs are **debug** builds, always: the driver attaches to the Dart VM
service, which a release build does not have.

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
  proceeds". *(Fixed 2026-08-21 — a `redirect` on the router sends any
  `needsReconsent` session to `/consent`. `canBook` returning false only ever
  stopped a booking, which is "before booking", not "before anything else".
  Three things are deliberately exempt: a visitor, because browsing is free
  under UC-4; a locked session, because unlock plus an undismissable consent
  form is two gates at once and a dead end; and `/consent` itself. There is no
  `refreshListenable`, because `Consent.current` is a compile-time constant and
  cannot be superseded mid-session — the case it catches is a **restored**
  session, which is why `SessionController.restore` landed with it.)*
- **Back is not blocked during the OTP round trip**, which the navigation rules
  state outright. *(Fixed 2026-08-20.)*

**~~Still open, and known since it was built:~~ Closed 2026-08-21.** Biometry
and the passcode were wired to the session but not to the platform — both
buttons called `unlock()` and no prompt was ever shown. They now go through
`core/biometrics.dart`:

- **The two buttons ask for different things.** `biometricOnly: true` on the
  fingerprint, the device credential on the passcode. Letting the OS substitute
  a PIN for a fingerprint would have made them the same button, which the
  design draws as two distinct choices.
- **The "biometry unavailable → passcode" state is implemented**, and in both
  directions: a handset with no usable sensor never gets the fingerprint button
  *or* copy telling it to use one, and a prompt that reports unavailable
  mid-flight collapses the screen to passcode-only rather than leaving a button
  that can only fail. On a phone with no reader the passcode is promoted to the
  primary, because there it is not a fallback — it is the only way in.
- **A refusal is silent.** A cancelled prompt is a change of mind, not an
  error, and the other way in is already on screen.
- **Android:** `MainActivity` now extends `FlutterFragmentActivity` (AndroidX
  `BiometricPrompt` is a Fragment and throws `no_fragment_activity` otherwise —
  at the moment the user taps unlock, which is the worst place to find out),
  and the manifest declares `USE_BIOMETRIC`. Verified by `flutter build apk
  --debug`; **not yet seen on a handset**, which is Phase 0's gate, not this
  one's.

**Session persistence landed 2026-08-21.** "OTP on every fresh login; the
session then persists until explicit logout" — the first half was always true
and the second was not, because every restart was a fresh install.
`core/session_store.dart` now holds it, and the decisions worth knowing are:

- **A reopen never lands on `active`.** With biometry on it restores to
  `locked`; with biometry off it goes back through the code, because the
  Security screen promises "an OTP every time the app is opened" in those
  words. Restoring straight to signed-in would make a stolen handset a
  signed-in handset, and that is the one way this could be wrong that matters.
- **Not kept:** a session mid-verification, and the attempt count with it. The
  design's restoration list puts "any OTP already sent" under *Not kept*, and
  resuming into a form whose code has expired is worse than starting again.
- `SessionController` writes through a single `_set`, so persistence cannot be
  forgotten when the next mutator is added.

*A bug this caught, worth repeating: the keep-or-drop rule was first written
only into the prefs-backed store, while every test ran against the in-memory
one. Tests were passing against behaviour the app did not have. Both now share
one `write`.*

---

## Phase 2 · Booking, with the payment moment moved — **built 2026-08-21**

Booking request · Booking status (11 states) · Rate & review

Design: `ipelege-ds-2-customer.dc.html`. Depends on Phase 1 (auth gate).

**The correction this phase exists to carry:** payment precedes "mark
complete". Activity diagram A-2 orders it *service delivered → customer pays the
provider directly → provider marks complete → customer confirms → commission
posts*. Earlier mockups had the provider marking complete first. The pay-directly
moment gets the hero treatment because it is the one thing that must not be
misread.

**All eleven states are in this phase, including `DISPUTED` and `NO_SHOW`.**

That is a correction. This file previously deferred those two on the grounds
that they "have no honest copy yet". They do: the canvas carries a `BSTATES`
array in its `<script>` block with all eleven states written out — chip, tone,
step, heading, body, action, action kind — and it marks the unsettled ones
itself rather than omitting them:

| State | The design's own note |
|---|---|
| `CANCELLED` | *Cancellation rules are not settled — this copy is provisional* |
| `NO_SHOW` | *No fee rule exists yet — provisional copy* |
| `DISPUTED` | *Dispute handling is undesigned in the spec — provisional* |

So the design's position is not "do not build these", it is **"build them and
show the note"**. A booking that reaches `NO_SHOW` with no screen behind it is
worse than one that says what is known and admits what is not. The note ships
as part of the state, and it comes out when the product decision lands.

The reason this was got wrong is worth recording: the `<script>` block was
being stripped before the canvas was read, so the eleven states looked absent
when they were merely somewhere I was deleting.

**Done when:** all 11 states render with their own copy, tone and single primary
action, and the payment step sits at position 4.

### What landed

Three screens, and the joins between them:

- **Booking request** at `/home/listing/:id/request` — on the **Home** tab, not
  Bookings, because until it is sent there is no booking, only a listing being
  looked at. Backing out returns to the listing. The direction radio set is the
  canvas's `dirDefs`, both label and sub-line, and the location card is
  conditional on it exactly as `needsLocation` is: a customer who is travelling
  to the provider is never asked for their address, because an address collected
  with no purpose is a DPA problem rather than a stray field.
- **Booking status**, already built, now reachable *from* the request — sending
  is a **replace**, so back cannot re-enter the form and send a second request
  for the same job.
- **Rate & review** at `/bookings/:id/rate`, reached from `COMPLETED`'s action.
  It is the one of the eleven actions that has somewhere to go; the rest stay
  inert rather than pretending, and each is inert for a reason already in the
  blocked list below.

**Nothing is pre-selected on the rating.** The canvas artboard sits at four
stars the way its booking artboard sits at `REQUESTED` — that is the demo's
state, not a default — so **Submit review** is dead until a star is tapped.
Submitting a rating the customer never chose would be worse than collecting
none, on a product whose central trust argument is that it does not fabricate
provider history.

**One correction this phase forced**, in [`design-deltas.md`](design-deltas.md)
§15: `ServiceDirection` carried a note asking for its options to be confirmed
against the canvas once the tail was readable. They now are — two customer-facing
options, with the copy the canvas wrote — and `either` is kept, because it is a
property of a *listing* from [`booking.md`](booking.md) ("Both — provider offers
either") rather than a choice ever offered at booking.

**Still open in this phase, and not blockers on Phase 3:** nothing persists, so
a sent request does not become a real booking and a submitted review is returned
to the caller and dropped; there is no picker behind the `WHEN` card, because
scheduling granularity per category is still an open question.

---

## Phase 3 · The loop prompt — **built 2026-08-21**

Cross-category prompt · Rental enquiry → movers handoff

Design: `ipelege-ds-1-foundations.dc.html` (journey map, stage 7).

**Why this early.** It looks like a cross-sell banner and is not: it is the
ecosystem thesis. One acquired user is supposed to produce several transactions
across several categories, which is the entire argument for launching with nine.
The design puts it third for that reason, and it is cheap once booking exists.

**Watch:** suppress the prompt when the adjacent category is thin — do not
prompt someone into an empty room — when they have already booked it, or when
the provider in the adjacent category is the same person.

### What landed

**The rules are the feature.** `core/loop_prompt.dart` holds the four states the
journey map names, and three of them are refusals. `LoopPrompts.decide` returns
a `LoopDecision` carrying the *reason* it declined, not a bare null, because a
suppression that fires for the wrong reason looks identical on screen to one
that works.

Two placements, both named by the design:

- **The rental enquiry → movers handoff**, as a sheet on listing detail. Offered
  *after* the enquiry, never beside it — a truck alongside the enquiry button
  competes with the thing the customer came for. "Not now" dismisses to exactly
  where they were, the same rule the auth gate follows.
- **A completed booking**, as a card at the foot of the status screen. The
  screen gates it on `COMPLETED` itself as well as the caller deciding whether
  to offer one at all: a prompt that could surface while a plumber is still
  under the sink is precisely the cross-sell banner this is not.

**The demo shows one prompt out of four pairs, and that is the feature
working.** `movers → plumbing`, `catering → hire` and `hire → catering` all
point at categories the design marks thin, so the empty-room rule withholds
them. Only `rentals → movers` — 21 trucks — fires. Six of nine categories being
thin at launch is the design condition, not a gap in the demo data.

**Reachability cost.** Stage 7 needed a rental to enquire about, so `Demo` grew
rentals listings and a `listingOf(id)` that resolves them. That surfaced a copy
bug on listing detail, now fixed and recorded in
[`design-deltas.md`](design-deltas.md) §16: the new-provider note claimed
verification covers "trade certification", which is wrong for rentals (proof of
ownership) and tiling (proof of past work), and a rental was being given a
"0 completed jobs" count on a journey shape the design says has no completion
at all.

**What the design did not give, and what was derived instead.** The journey map
marks this feature `gap` — it is specified as behaviour and never drawn. One
line of finished copy exists (*"Moving in? Find a truck"*) and is marked
`verbatim` in code. The other three pairs' copy is derived from the design's own
adjacency sentences and flagged as derived, so a later canvas can replace it
without anyone having to guess which strings were ours.

---

## Phase 3.5 · The settings spine — **pulled forward from Phase 7**

Preferences (Appearance, and the preference store behind it)

Design: `ipelege-ds-4-specs.dc.html`, the artboard labelled `Settings` — whose
own title is *Preferences*. Its rows are **Appearance** (Light / Dark /
System), **Notifications** (SMS / WhatsApp / Push) and **Data** (Location,
downloads).

**Why this jumped the queue, and it is not the reason it was first raised.**
The ask was for somewhere to put "keep the screen on during a ride" without
being forced into Phase 7. Looking for that turned up something worse:

> **Dark mode is finished and no user can reach it.** Both themes, the whole
> palette, `themeModeProvider` — all built, all verified on two devices, and
> the only control that drives them is a row on a screen that renders
> `PlaceholderScreen`. The app ships a completed feature nobody can turn on.

That is the strongest argument in this file for pulling work forward, and it
was invisible until someone asked where a preference would live.

**What is in scope, deliberately narrow:**

- `core/settings.dart` — the store, persisted the way `session_store.dart` is,
  writing through a single mutator so a new preference cannot be added and
  silently not saved.
- **Appearance**, wired to the existing `themeModeProvider`. This is the row
  that unblocks dark mode.
- **Keep the screen on during a ride**, stored and defaulted **on**. Nothing
  reads it yet — the ride screens are Phase 5 — and that is fine: the point is
  that Phase 5 finds a preference already there rather than a Phase 7 detour.
  See [`device-permissions.md`](device-permissions.md) §1.

**What is *not* in scope, and stays in Phase 7:** Account, Security, Data &
storage, deletion. Those are the DPA-heavy screens — deletion has to keep the
financial ledger intact while removing personal data — and they need their own
confirmation copy and their own care. Pulling the spine forward is not an
excuse to pull the compliance surface forward with it.

**Not in scope either: any manifest permission.** `SYSTEM_ALERT_WINDOW` and
friends cannot be "set early and defaulted on" — they are special permissions
with no API to grant them, and declaring them before the feature exists is a
Play Store liability. The manifest entry lands in the phase that uses it. The
full reasoning is in [`device-permissions.md`](device-permissions.md) §2b.

**Done when:** a user can switch the app to dark from inside the app and it
survives a restart, and `keepScreenOnDuringRides` is readable by Phase 5
without touching Phase 7.

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

Account · Security · Notifications · Data & storage

**Shrunk on 2026-08-21.** Biometric enrolment landed in Phase 1, and
Preferences' spine was pulled forward to Phase 3.5 because dark mode was
finished and unreachable without it. What is left here is the part that was
always the reason this phase exists — the compliance surface.

Design: `ipelege-ds-4-specs.dc.html`.

These are **Musts** under the DPA (FR-1.8, FR-1.9, UC-16), not settings polish.
Deletion has to keep the financial ledger intact while removing personal data,
which needs its own confirmation copy.

---

## Blocked — not scheduled, and not to be started

Genuinely blocked — as opposed to merely unsettled. The distinction matters and
this list previously blurred it: a state whose copy the design has **written and
marked provisional** is buildable today, and only a screen the design has not
drawn at all is blocked.

| Blocked | Waiting on |
|---|---|
| The dispute **flow** (UC-13) — raising one, and what follows | Dispute turnaround time — screens promise contact but name no timeframe. The `DISPUTED` *state* is built; the flow that reaches it is undesigned. |
| Admin **Revoke** action | What happens to already-accepted bookings when a category is revoked |
| Per-category commission display | Whether trades and rentals differ from the ride 8% |

Also unbuilt because undesigned, not blocked: customer↔provider messaging
(referenced from several screens, no thread UI exists), provider listing
management at scale, and empty/offline states across the journey.

**Calling** joins that list. The booking status screen already draws the
button — `Icons.call` in the provider row, inert — and every screen and rule
behind it is missing: what it does, when it is live, the in-call and incoming
surfaces, and what a dispute can see afterwards. The technology options are
worked through in [`calling.md`](calling.md). **Both routes are planned** —
an in-app call and a phone call, because inDrive and the other ride apps in
this market offer both and a provider comparing them will notice. The dialer
ships first and stays as the fallback; WebRTC on the existing VPS is the parity
feature. Matrix is the wrong shape and the doc says why. The design work is in
[`../design/CORRECTIONS.md`](../design/CORRECTIONS.md) §5, and it should be
done **with** the incoming-ride surface, because a call and a ride request need
the same lock-screen treatment.

---

## Where things stand

**Brand (Phase 1):** launcher icon at five densities · adaptive icon with a
monochrome layer · splash icon in both modes · notification icon · the in-app
size ladder.

**Entry:** splash · register · sign in · OTP (with its wrong-code and
locked states) · consent · biometric enrolment · unlock · location, plus the
auth gate as a sheet.

**Booking (Phase 2):** booking request · booking status, **all eleven states**,
with the payment moment at step 4 · rate & review.

**The loop (Phase 3):** the cross-category prompt with all four suppression
rules · the rental enquiry → movers handoff sheet · the prompt card on a
completed booking.

**Built earlier, to validate the resynced tokens:** consumer home · category
browse · listing detail · provider dashboard · wallet.

The shared component set gained two: `ScreenHeader`, extracted from the status
screen so the two booking steps carry the same header rather than one custom and
one stock `AppBar`; and `LoopPromptCard`. **254 tests**, `flutter analyze`
clean, and `flutter build apk --debug` green. Every screen built before
2026-08-21 has been seen rendered on a device in both modes; the two that landed
that day have not, and Phase 0's gate applies to them before Phase 3 closes.

Everything else renders `PlaceholderScreen`, which is deliberate — the
navigation graph stays complete and testable while screens land one at a time.

**Next action: Phase 4** — becoming a provider, paired with the admin queue.
**This is where the backend starts**, and it is a much larger step than
anything before it: a Django project on `/staff/*`, the `PROVIDER_CATEGORY`,
`ADMIN_ACTION` and `DOCUMENT_ACCESS` models, and two halves that have to ship
together because neither is testable alone.

Phase 0 is closed. Phase 1 (brand) is done except the four cuts that exceed the
fetch cap. **Its remainder is closed**: the consent-supersede redirect, session
persistence and `local_auth` all landed 2026-08-21. What is left of Phase 1 is
the four brand cuts, and that is a fetch-cap problem only the user can clear.
Phase 2 is built: request, status with all eleven states, and rate & review.
Phase 3 is built: the prompt, its four suppression rules and both placements.
The dispute *flow* stays blocked because the design has not drawn it — the
`DISPUTED` state itself is built.

**Phase 0's gate ran on 2026-08-21, both halves, and is a script now** —
`app/integration_test/gate_test.dart`, 28 screens in both modes on a real
device. The motion pass found the transition table implemented nowhere and
built it; the colour pass found three interactive controls invisible at rest
and fixed them with a token. Both are written up in
[`design-deltas.md`](design-deltas.md) §17 and §18.

Phase 1 is closed too. The biometric path was verified end to end on a Galaxy
S24 on 2026-08-21 — both availability branches, a real system prompt, and a
real fingerprint reopening a genuinely locked session. What remains of Phase 1
is only the four brand cuts over the fetch cap, which this repo cannot clear.
