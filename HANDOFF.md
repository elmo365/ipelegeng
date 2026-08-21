# Work Handoff - Ipelege

**Saved:** Friday, 2026-08-21, 05:13 (+02:00)
**Branch:** main
**Last commit:** a01ed33 Build the booking status screen: all eleven states

## What I was working on

**Reading the design properly, and repairing everything that had been built on
a partial reading of it.** The session began as "resume and follow
build-order.md" and became something else once the user pushed back, repeatedly
and correctly, on the same point: I was working from extracted slices of the
canvases rather than reading them.

Five rounds of that pushback, each one right:

1. *"why are you dealing with design as if you don't know the design"* — the
   project id was in `design/README.md` the whole time.
2. *"read top to bottom the whole design not foundation"* — I had read one
   canvas of five.
3. *"docs come before dart"* — I was correcting code before the document it
   was built from.
4. *"if documentation is wrong its a definite emergency"* — three documents
   were actively wrong and I was building on them.
5. *"the design mentions the assets and done the flutter conversion for you"* —
   my flattener was stripping `<script>`, which is where the design keeps its
   token data.

## Files changed this session

Five commits: `3a29e95` (read the whole design, correct the docs), `f4a3c8a`
(import brand, ship the icon), `3b72016` (implement Foundations), `38f3b4a`
(splash + notification icons), `a01ed33` (booking status).

**Docs corrected** — `design-system.md` (motion, haptics, navigation, state
restoration merged and re-sourced), `identity.md` (rewritten twice as the truth
changed), `design/README.md`, `design-deltas.md` (§13, §14), `build-order.md`
(brand promoted to Phase 1; screen index added; DISPUTED/NO_SHOW unblocked).

**New Dart** — `core/booking.dart`, `core/haptics.dart`,
`ui/screens/consumer/booking_status_screen.dart`,
`ui/screens/entry/biometric_enrolment_screen.dart`; `BrandMark` /
`BrandLockupHorizontal` / `BrandCut` in `brand_lockup.dart`; `QuietAction`.

**New tests** — `booking_test.dart`, `motion_test.dart`, `encoding_test.dart`,
plus rewritten `identity_test.dart`.

**Assets** — seven brand PNGs in `design/assets/`, three shipped in
`app/assets/brand/`, launcher + adaptive + splash + notification icons
generated into `android/.../res`.

## What is working

- **The brand is real.** Launcher icon at five densities, adaptive icon with a
  `<monochrome>` layer, splash icon in both modes, notification icon wired into
  the manifest. All verified on a Pixel 9a.
- **Colour and type are verified against the canvas**, not assumed: every value
  in `tokens.dart` matches `PAL` exactly in both modes including all six shadow
  alphas, and all eight type roles match.
- **Booking status: all eleven states**, copy verbatim from `BSTATES`, payment
  at step 4, endings hiding the step bar.
- **177 tests, `flutter analyze` clean.**

## What is NOT working yet

- **Four brand cuts exceed the 256 KiB fetch cap** — `mark-dark`,
  `wordmark-dark-new`, `lockup-dark`, `logo-light-transparent`. The in-app
  splash therefore still sets the wordmark in type on its navy gradient.
- **Phase 2 is half done**: booking *status* is built; **booking request** and
  **rate & review** are not.
- **The OTP screen has wrong-code and locked states but no backend** — any
  four digits are accepted by `DemoOtpVerifier`.
- Consent supersede is modelled and still not enforced by a router redirect.
- `local_auth` is not wired; both unlock buttons call `unlock()`.
- Nothing persists. No Django backend.
- iOS is stock and cannot be built on this machine.

## Decisions made (and why)

- **Brand is Phase 1**, because the design's Foundations runs Brand → Colour →
  Type → Components before any screen. It had been "Phase 0.5", bolted on.
- **`DISPUTED` and `NO_SHOW` ship with their provisional notes** rather than
  being withheld. The design wrote the copy and flagged it itself; a state with
  no screen is worse than one that admits what is unsettled.
- **Never recolour the brand artwork.** Light and dark are separate drawings —
  the dark cut has a white `i` body. A `ColorFilter` flattens the ripple rings
  and both blues, which is the exact damage the canvas records from a previous
  mixed-export set.
- **The dark splash uses the design's dark app icon** on a background matching
  its baked navy plate, which is why it works without `mark-dark.png`.
- **`PromiseCard.iconColor` is required**, because two artboards use different
  greens on the same glyph and a default would silently make one wrong.

## Things I tried that did NOT work - do not repeat these

- **Stripping `<script>` when flattening a canvas.** That is 16,673 characters
  per file containing `PAL`, `CATS`, `REQUIREMENTS`, the pricing copy and all
  eleven `BSTATES`. Everything I called "missing from the design" was in there.
- **Transcribing a binary out of a tool result.** `mark-icon.png` came back
  complete and inline and was still corrupt, because I hand-copied ~20 KB of
  base64. `Image.open()` read its header happily; only a full `load()` failed.
  Decode from the file the tool wrote, and verify the `IEND` chunk before the
  file lands.
- **`Get-Content` / `Set-Content` on a source file.** They default to the
  system codepage: a rename of one symbol double-encoded nine em dashes and a
  middot in `booking_status_screen.dart`. It compiled, all tests passed, and it
  was only visible as "Verified Â· Plumbing" in a screenshot.
- **Writing a mojibake-detector with the mangled characters written out
  literally.** It matches itself. Build the pattern from `\u` escapes.
- **Reading a canvas name as one of ours.** `pal.shCard` is our `shadowRow`;
  `pal.shRaise` is our `shadowCard`. The vocabularies invert.
- **`CrossAxisAlignment.stretch` on a Row inside a ListView** — unbounded
  constraint, will not lay out. Use `IntrinsicHeight`.
- **A modal on a tab's Navigator.** go_router re-syncs on pop and removes the
  page underneath.
- **A PowerShell here-string or heredoc for `git commit -m`.** Write the
  message to a file and use `git commit -F`.

## Exact next steps to continue

1. **Finish Phase 2** — booking request (`5–6 · BOOKING REQUEST / STATUS`) and
   rate & review (`8 · RATE & REVIEW`), both in `ds-2-customer`. The direction
   radio set and the pricing copy are already in the canvas script block.
2. **Phase 3** — the loop prompt, stage 7. Suppression rules are in
   foundations: adjacent category thin, already booked, or the same person.
3. **When the four cuts arrive**: drop them into `design/assets/`, point
   `BrandLockup(onDark:)` at the real artwork, and delete the type fallback.
4. Close Phase 1's remainder: `local_auth`, the consent-supersede redirect, and
   persistence for `SessionController`.

Read `docs/build-order.md` first — it now carries a 60-artboard index so each
phase points at the screen it implements.

## Open questions / blockers

**Blocking, and only you can clear it:** `mark-dark.png`,
`wordmark-dark-new.png`, `lockup-dark.png`, `logo-light-transparent.png` — all
over the 256 KiB `get_file` cap. Re-save them smaller in the design project or
export them directly.

**Undesigned, so not startable:** the dispute *flow* (UC-13), customer↔provider
messaging, provider listing management at scale, empty/offline states.

**Business decisions the screens are written around:** late-cancellation fee
amount · no-show consequence · commission rate per category (rides shows 8%) ·
dispute turnaround.

**Carried:** wallet naming vs `compliance.md` · reversal policy · negative
balance · min top-up · hosting durability · EPS licensing · data residency ·
KYC retention · GPS DPIA.

**Noted, not fixed:** the design numbers two screens `21`, and `Session.
maxCodeAttempts` (5) is the repo's number — the design says "locked after N
attempts" without setting N.
