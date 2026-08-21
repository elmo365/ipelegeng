# Work Handoff - Ipelege

**Saved:** Thursday, 2026-08-20, 21:43 (+02:00)
**Branch:** main
**Last commit:** 8877ff3 Build Phase 1: the account gap

## What I was working on

**Following [`docs/build-order.md`](docs/build-order.md) rather than re-deriving
it.** Phase 0 was the standing gate; it is now closed, and Phase 1 — the account
gap — is built.

1. **Phase 0.** Ran all five previously-built screens on a Pixel 9a emulator in
   both modes and compared them against the canvas. This is the first time any
   of this app has been seen rendered.
2. **The identity gap Phase 0 exposed**, raised by the user mid-session: stock
   Flutter launcher icon, a white flash on every cold start, no mark anywhere.
3. **Phase 1**, in full: seven entry routes plus the auth gate.

## Files changed this session

**Commit `b95cc96` — Phase 0 and identity**

- **M** `ui/components/category_tile.dart` — supply count wraps instead of
  ellipsising; grid extent 124 → 136.
- **M** `test/ui/components_test.dart` — a guard that measures in the real IBM
  Plex face, because the test font draws every glyph a full em wide.
- **A** `android/.../values/colors.xml`, `values-night/colors.xml`; **M** both
  `launch_background.xml` — the cold-start window paints `screenBg2` per mode.
- **A** `docs/identity.md`, **A** `test/identity/identity_test.dart`.
- **M** `docs/build-order.md`, `docs/design-deltas.md` (§13).

**Commit `8877ff3` — Phase 1**

- **A** `core/session.dart` (the entry rules as states), `core/phone.dart`.
- **A** components: `entry_header.dart`, `form_field_card.dart`, `actions.dart`,
  `choice_cards.dart`, `brand_lockup.dart`.
- **A** `ui/screens/entry/`: splash, register, sign in, verify, consent, unlock,
  location, auth gate.
- **M** `routes.dart`, `app_router.dart` (entry routes + `_replacingPage`),
  `tokens.dart` (`entryGradient`, `splashGradient`), `typography.dart`
  (`fieldLabel`, `sectionLabel`), `listing_detail_screen.dart` (the gate).
- **A** `test/core/session_test.dart`, `test/ui/entry_test.dart`.

## What is working

- **The palette is correct on a real device, in both modes.** Sampled pixels
  match `AppPalette` exactly — dark page `#050B0F`, card `#171F25`, nav
  `#11171C`. The `PAL` recovery holds, and the dark mode that had never been
  displayed renders as specified.
- **The app has a way in.** Cold start lands on the splash. Register → OTP →
  consent → location → Home works end to end on the emulator.
- **A visitor is a first-class state.** Home, browse and listing detail are
  reachable with no account; the wall is at the booking action and names the
  provider.
- **147 tests, `flutter analyze` clean.** Up from 109 at the start of the
  session. (The "97" carried in the last two handoffs was already stale — the
  build-order suite had taken it to 109.)
- **The cold-start flash is gone**, asserted against `AppPalette` by
  `identity_test.dart` so an Android XML resource cannot drift from a Dart
  token silently.

## What is NOT working yet

- **No brand artwork, anywhere.** Stock Flutter launcher icon, no adaptive
  icon, no splash image, no notification icon, no lockup in-app. Searched the
  entire user profile: the PNGs are not on this machine. Blocked on an export
  from the design project — see [`docs/identity.md`](docs/identity.md).
- **Biometry is not wired to the platform.** Both unlock buttons call
  `SessionController.unlock()`; no `local_auth` prompt is shown. The states and
  the fallback's visual weight are right; the sensor is not connected.
- **Nothing persists.** `SessionController` is in-memory, so a restart is a new
  device. Safe direction to be wrong in, but it means `/unlock` is only
  reachable by deep link today.
- **No backend.** Django not started; screens still read `core/demo_data.dart`.
- **Most screens are still placeholders** — booking request, booking status (11
  states), ride tracking, rate & review, mode switcher, my categories, inbox,
  top up, become a provider, KYC, the six settings screens.
- iOS is stock and unverified; there is no way to build it on this machine.

## Decisions made (and why)

- **The auth gate is a sheet, not a route.** Refusing it must not cost the
  visitor their place. It uses the **root** navigator — see below for why that
  is not optional.
- **Entry routes sit outside both shells.** A flow escapable by tapping a tab
  is not a gate.
- **The entry rules live in `Session` as states, not as screen logic.** OTP is
  unskippable because nothing reaches `active` without passing through
  `confirmingNumber`; `canBook` is false on a superseded consent version, so
  re-consent is a state rather than a prompt someone remembers to show;
  `lock()` no-ops on a session that was never active, so biometry can only
  unlock.
- **Consent is captured on the OTP screen**, not after it. FR-1.10 wants it at
  account creation, and a screen afterwards is a screen people learn to
  dismiss. "Verify & continue" is dead until the code is complete *and* the
  required tick is set, with a line saying why.
- **`BrandLockup` holds the slot rather than faking a mark.** The canvas is
  explicit that a previous set assembled from mixed exports lost the ripple
  rings and the blue *i*; inventing a substitute would repeat that, on the
  Play Store listing.
- **The tile's off-grid literals are recorded, not tokenised** (20 px radius,
  14 px padding, 38 px plate). Adding a token per inline literal is what this
  repo already declined to do for `navPillBg`.

## Things I tried that did NOT work - do not repeat these

- **Reading a canvas shadow name as if it were ours.** `pal.shCard` is *our*
  `shadowRow`; `pal.shRaise` is our `shadowCard`. The vocabularies invert. I
  "fixed" the category tile to `shadowCard` on that misreading and shipped it
  in `b95cc96` before the mapping table in `tokens.dart` corrected me. The
  original code was right. Check that table before changing any surface depth.
- **Pushing a modal onto a tab's Navigator.** go_router manages a branch
  navigator's pages declaratively; an imperative route pushed onto it makes the
  router re-sync on pop and **removes the page underneath**. Dismissing the
  auth gate took the listing down with it. `useRootNavigator: true`.
- **`CrossAxisAlignment.stretch` on a Row inside a ListView.** Unbounded
  cross-axis constraint; it does not lay out at all. The consent card's accent
  rule needs `IntrinsicHeight`. A `BoxDecoration` border is not an alternative —
  Flutter rejects a non-uniform border on a rounded rect.
- **A widget in a `Column` assuming it is full width.** A Column centres on the
  cross axis, so `EntryHeader` was only as wide as its own text.
- **Asserting text layout under the default test font.** It draws every glyph a
  full em wide, roughly double the real width. Load the bundled face with
  `FontLoader` when the assertion is about fitting.
- **`find.text` on a `Text.rich` span.** Needs
  `find.textContaining(..., findRichText: true)`.
- **A PowerShell here-string for `git commit -m`.** It broke on the quotes in
  the message. Write the message to a file and use `git commit -F`.

## Exact next steps to continue

1. **Phase 2 — booking, with the payment moment moved.** Booking request,
   booking status (11 states), rate & review. The correction it exists to carry:
   payment precedes "mark complete", at position 4. `DISPUTED` and `NO_SHOW`
   stay out — they have no honest copy yet.
2. **Phase 0.5, the moment the artwork arrives.** Export the asset set into
   `design/assets/`, then: launcher icon at all densities, adaptive icon
   (`mipmap-anydpi-v26`), the Android 12 splash API, notification icon, and
   swap `BrandLockup` to the image. Update `docs/identity.md` and the hashes in
   `identity_test.dart` together — the suite fails until you do.
3. **Finish Phase 1's two loose ends**: `local_auth` behind the unlock buttons,
   and persistence for `SessionController` so `/unlock` is reachable the way a
   user would actually reach it.

Read `docs/build-order.md` and update it with its test — do not re-derive the
order here.

## Open questions / blockers

**New and hard-blocking:** the brand artwork. Nothing in Phase 0.5 can proceed
without it, and it cannot be reconstructed from this repo.

**Unchanged and still code-blocking:** already-accepted bookings when a category
is revoked — blocks the admin Revoke action shipping.

**From the design's own "needs a business decision" list:** late-cancellation
fee amount · no-show consequence for providers · commission rate per category
(rides shows 8%) · dispute turnaround.

**Not yet designed at all:** customer↔provider messaging, provider listing
management at scale, empty/offline states.

**Carried:** wallet naming vs `compliance.md` · reversal policy · negative
balance · min top-up · hosting durability · EPS licensing · data residency ·
KYC retention · GPS DPIA.

**Minor, noted in `design-deltas.md` §13:** browse derives its header count from
the listings it holds, so plumbing reads "3 providers" under a home tile saying
"6 plumbers". `demo_data.dart` disagreeing with itself; dies with the
scaffolding.
