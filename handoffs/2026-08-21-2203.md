# Work Handoff - Ipelege

**Saved:** Friday 21 August 2026, 19:40 (+02:00)
**Branch:** main
**Last commit:** d76096c Adopt element-by-element UI ticks; fix the three things a glance missed

## What I was working on

Resumed from the 13:28 handoff and did its first named next step: **run Phase
0's gate on everything built since 2026-08-20**. Both halves — motion, then
colour — and the gate is a runnable script now rather than an act of will.

Both halves found real defects, and in both cases the defect was the same
shape: something the design specified, that the repo had *recorded* correctly
and *implemented* nowhere, and that no widget test could ever have seen.

**The motion pass** found the transition table consumed by four places and no
screen. `theme/motion.dart` held the right durations — they were corrected on
2026-08-20 after the previous pass — but there was not one `AnimatedContainer`,
`AnimatedSwitcher` or `TweenAnimationBuilder` anywhere in the app. The table's
two most-specified rows, the 300 ms booking state change with its eleven-row
per-state table and the 400 ms wallet count, were simply absent. Correcting a
token is not implementing it.

**The colour pass** ran 28 screens in both modes on a Pixel emulator. The
palette holds exactly. What it found instead was three interactive controls
that are **invisible at rest** — a class of bug an artboard comparison cannot
catch either, because artboards draw controls in their chosen state.

## Files changed this session

Seven commits: 599d16e, 89aa2f6, 8f894c4, 5c5a7c0, 014b3f2, 4c7cf7b, d76096c.

**The motion pass**

- **A** `app/lib/ui/components/enter_in_place.dart` — "anything entering in
  place", the design's own rule, as one widget instead of three copies.
- **M** `app/lib/ui/screens/consumer/booking_status_screen.dart` — now
  stateful, so it can tell arriving at a state from being opened at one; the
  whole per-state motion table.
- **M** `app/lib/ui/components/money_text.dart` — `MoneyCounter`, which counts
  on change and never on load.
- **M** `app/lib/ui/screens/provider/wallet_screen.dart` — the balance uses it.
- **M** `app/lib/ui/components/category_tile.dart` — `CategoryTileEntrance`
  delegates to `EnterInPlace`.
- **A** `app/test/ui/motion_test.dart` — 21 tests, pinning the rules rather
  than the numbers.

**The colour pass**

- **A** `app/integration_test/gate_test.dart` — the gate itself: 28 screens,
  both modes, one PNG per artboard.
- **A** `app/test_driver/integration_test.dart` — writes the frames to
  `app/build/gate/`.
- **M** `app/lib/theme/tokens.dart` — `AppPalette.controlOutline`.
- **M** `app/lib/ui/screens/consumer/rate_review_screen.dart`,
  `app/lib/ui/components/choice_cards.dart`, `app/lib/theme/app_theme.dart` —
  the three controls that were invisible.
- **A** `app/test/theme/contrast_test.dart` — 15 tests holding the floors in
  both directions.
- **M** `app/pubspec.yaml` / `.lock` — `integration_test` from the SDK.
- **M** `docs/design-deltas.md` §17 and §18; `docs/build-order.md` Phase 0.

**Pointing the gate at the real platform**

- **M** `app/integration_test/gate_test.dart` — applies `main()`'s
  `biometricsProvider` override, so the unlock screen is photographed answering
  the handset rather than a stub.
- **M** `app/lib/ui/screens/entry/unlock_screen.dart` — the hero glyph obeys the
  same rule the copy and buttons already did.
- **M** `app/test/ui/unlock_test.dart` — pins it; verified to fail without the
  fix.

**Closing Phase 1 on real hardware**

- **A** `app/integration_test/biometric_test.dart` — raises a real system
  prompt and waits for a real finger. A separate target from the gate, because
  a gate is unattended and this is not.
- **M** `app/integration_test/gate_test.dart` — applies `main()`'s
  `biometricsProvider` override, says `--debug` out loud, and documents the
  sleeping-screen failure.
- **M** `app/lib/ui/screens/entry/unlock_screen.dart` — the hero glyph obeys
  the same rule the copy and buttons already did.

**The permission surface, and Phase 3.5**

- **A** `docs/device-permissions.md` — the whole surface: what is asked, when,
  and what happens when the answer is no. §2b is why the overlay permission
  cannot be front-loaded.
- **A** `design/CORRECTIONS.md` — a work list pointing *back* at the design
  project, the opposite direction to `design-deltas.md`. First entry is profile
  photos, which do not exist anywhere in the canvas.
- **A** `app/lib/core/settings.dart` — the store, shaped like `session_store`.
- **A** `app/lib/ui/screens/settings/preferences_screen.dart` — Appearance, and
  the keep-screen-on preference.
- **D** `app/lib/theme/theme_mode.dart` — replaced by the settings store.
- **A** `app/test/ui/preferences_test.dart`.

**UI ticks, and what the first one found**

- **M** `docs/test-strategy.md` — the tick procedure, and a table naming every
  stub and exactly what it hides.
- **M** `app/lib/ui/components/brand_lockup.dart` — the wordmark's blue `i`,
  and the inverted `ExcludeSemantics`/`Semantics` nesting.
- **M** `app/lib/theme/tokens.dart`, `.../entry/splash_screen.dart` —
  `Brand.skyPale`, the splash glyph tint the canvas actually specifies.
- **M** `app/test/identity/identity_test.dart` — both pinned.
- **A** `docs/sms-otp.md` — testing OTP without a paid service, and the
  Botswana recommendation.

## What is working

- **Phase 0 is closed on everything built up to 2026-08-21.** The palette was
  compared against the canvas on 28 screens in both modes and holds — every
  surface, plate, chip and gradient. The dark mode most of these screens had
  never been rendered in is correct.
- **The booking state change moves as one event.** The chip's plate, dot and
  label ink, the accent rule and all six step bars run on **one** duration,
  passed down rather than repeated. Forward progress animates; every ending is
  instant. The pay panel and provider row rise 12 dp on the states the design
  names, the rating action arrives 120 ms behind the bar completing, and a
  screen opened at a state does not replay reaching it or buzz for it.
- **The wallet balance counts to a new figure and does nothing on load**,
  enforced structurally: the tween begins at the amount the widget was born
  holding, so the rule cannot be forgotten rather than merely remembered.
- **The three invisible controls are visible**, confirmed on device in both
  modes after the fix, not just in arithmetic.
- **The rentals → movers handoff sheet has been seen rendered**, for the first
  time. It is the only one of stage 7's two placements that can be.
- **The no-biometry branch is verified against the real platform.** The
  emulator has a fingerprint sensor with nothing enrolled and no device
  credential — precisely the design's *"biometry unavailable → passcode"* case
  — and the screen came back correct: no fingerprint button, no copy naming
  one, **Enter device passcode** promoted to the primary.
- **The biometric path is verified end to end on a Galaxy S24** (Android 16,
  three enrolled prints), paired over wireless adb. The same build gives the
  opposite answer to the emulator — fingerprint glyph, fingerprint copy, **Use
  fingerprint** as the primary — so the conditional is confirmed from both
  sides, not just the broken one. A **real system prompt** was raised and a
  **real fingerprint** carried a locked session back to `active`, with the same
  name on the far side. Every branch of `core/biometrics.dart` has now run
  against a real platform.
- **Dark mode is reachable.** Phase 3.5 shipped the settings spine, so the
  theme can be changed from inside the app and survives a restart. It had been
  finished and unreachable — both themes and the provider existed with no
  control anywhere.
- 254 tests → **305**. `flutter analyze` clean. The gate runs green end to end,
  **58 shots on the handset** as well as on the emulator, and both brand fixes
  were confirmed *there* rather than only in the analyzer.

## What is NOT working yet

- **Profile photos do not exist anywhere in the design.** The Account artboard
  renders initials on a plate and that fallback is the only state drawn — no
  avatar, no upload, no remove. Raised as a gap; written up as the first entry
  in `design/CORRECTIONS.md` for the design side to supply.
- **Nothing reads `keepScreenOnDuringRides` yet.** It is stored and defaults
  on; the ride screens are Phase 5. That is deliberate, not an oversight.
- **The splash has no logo**, and this is the sharpest cost of the fetch-cap
  blocker. The artboard stacks `mark-dark.png` at 88 px above the wordmark; the
  build renders the type stand-in and no pin at all.
- **The OTP tests do not test OTP.** `DemoOtpVerifier` accepts any four digits,
  so the rules around the code are tested and the code is not. Every stub and
  what it hides is now tabled in `test-strategy.md`.
- **Only the splash has had a real UI tick.** The other 28 screens have been
  looked at, which is now explicitly not the same thing.
- **No backend.** A sent request never becomes a booking, a submitted review is
  returned to the caller and dropped, and `DemoOtpVerifier` accepts any four
  digits. Ten of eleven booking actions are inert.
- **Three brand cuts and one logo still exceed the 256 KiB fetch cap** —
  `mark-dark`, `wordmark-dark-new`, `lockup-dark`, `logo-light-transparent`.
  The light cuts all landed; the dark ones compress larger. Only the design
  side can clear this.
- **No picker behind the booking request's WHEN card** — scheduling granularity
  per category is still open.
- The loop prompt's **completed-booking** placement renders nowhere in the demo,
  and that is correct — see the decision below.

## Decisions made (and why)

- **"Medium haptic" is a strength the app deliberately does not have.** The
  design marks `ACCEPTED` and `COMPLETED` with one, and `core/haptics.dart`
  exposes three haptics named after *meanings*, not strengths, because "a phone
  that buzzes at everything gets muted". Resolved to `Haptics.decision()` —
  whose own definition is "accepting a request; confirming a booking is done",
  i.e. these two moments under their other name. **A fourth haptic was not
  added**, because the two sections are not in conflict about behaviour.
- **The empty-room rule wins over demo completeness.** All three
  `bookingCompleted` loop pairs point at categories the demo marks thin, so the
  prompt is withheld and the placement cannot be photographed. Making it
  reachable would mean fabricating supply, which is the one thing stage 7's
  rules exist to prevent. Recorded so the absence is not read as a regression.
- **No new colour was invented to fix contrast.** `controlOutline` carries
  `textMuted`'s existing value in both palettes. A hex the design never
  specified would have traded one silent drift for another.
- **`divider` is pinned to stay *under* 3:1.** Fixing contrast by darkening the
  hairline would give every card a visible border and undo the design's
  shadow-not-borders treatment. Both directions are tested.
- **The gate reaches screens by overriding `routerProvider`, not by tapping
  through the app.** A gate that must complete a nine-step journey to
  photograph the ninth screen fails at step two and shows nothing.
- **Every animation is gated on having arrived.** Motion explains a change; one
  that fires when nothing happened is decoration.
- **A picture is copy.** The unlock screen's hero glyph was the only element on
  it that did not obey the no-sensor rule — 50 dp of fingerprint over the words
  "Use your device passcode to continue". It is `Icons.dialpad` there now.
- **The gate must override what `main()` overrides**, or it photographs stubs.
  The session store is the deliberate exception: a prefs-backed one would carry
  a shot's session into the next shot.
- **The biometric test is a separate target from the gate.** A gate is
  unattended; a test that waits thirty seconds for a person to touch a sensor
  is not, and folding it in would make every future gate run need a human.
- **Device runs are debug, always** — written out in the commands even though
  it is the default. The driver attaches to the Dart VM service, which a
  release build does not have.
- **A special permission cannot be "set early and defaulted on".**
  `SYSTEM_ALERT_WINDOW` has no API to grant it — the user must toggle it in
  Settings by hand — and declaring it before the feature exists is a Play Store
  liability. The manifest entry lands in the phase that uses it. Keep-screen-on
  is the opposite case: no permission at all, just a window flag, so the
  *preference* could be front-loaded and was.
- **Notifications stay off the Preferences screen** even though the canvas puts
  them there. They are consent records under FR-1.10, and splitting one DPA
  trail across two stores to save a phase would be the wrong shortcut.
- **A UI tick is earned per element, not per screen.** Enumerate the artboard's
  elements *before* opening the screenshot, or the screenshot decides what gets
  checked. Adopted after a whole-screen review passed a defect that was plainly
  visible in the image.
- **A seam's fake must be more permissive than the real thing**, never less, so
  no test can pass *because* the fake rejected what production would allow.
- **Launch OTP on Firebase Auth phone**, not an aggregator — the free quota
  covers early volume and it skips a commercial negotiation that is a
  lead-time item. Move to a SADC aggregator at volume. WhatsApp is the lever
  worth pushing hardest here, and the app already collects consent for it.

## Things I tried that did NOT work - do not repeat these

- **An `AnimatedSwitcher`'s outgoing child animates on the controller it was
  built with.** Flipping its `duration` from zero to 300 ms at the moment of
  the change gives the *incoming* half the new duration and leaves the outgoing
  half at zero, so it vanishes instead of crossfading — and every assertion
  about the widget's properties still passes. Instantness must come from
  unmounting the switcher, not from zeroing it.
- **"Has it changed" is not "is it different from where it started."** Gating
  an arrival animation on `state.key != _openedAt` reads as *not arrived* for
  any booking that returns to a state it has been in. It is a latch.
- **A second `pumpWidget` in one test reuses the element tree**, so the screen
  is still the one opened a moment ago and reports having arrived. Split the
  test instead.
- **`find.byType(AnimatedDefaultTextStyle)` finds Material's own.** Anchor a
  finder to the widget you mean — `find.ancestor(of: find.text(…))`.
- **Do not "fix" the chip by crossfading its word.** "Chip crossfades pending →
  ok" names `BookingTone`s. The tone crossfades; the word changes with the
  frame.
- **A sleeping screen kills an on-device gate and names nothing useful.** A
  handset on a 30-second timeout locked mid-run: `PixelCopy` threw
  `IllegalArgumentException: Window doesn't have a backing surface!`, the app
  took SIGKILL, and the driver reported `Service has disappeared`. **No
  screenshots survive** — the driver flushes at the end, so dying at shot 55
  leaves as much evidence as dying at shot 1. `adb shell svc power stayon true`
  only holds while the handset is charging.
- **A widget test pumping a screen needs `AppTheme`, not a bare `MaterialApp`.**
  The palette is a `ThemeExtension`; without it `context.palette` throws a null
  check on the first component that reads it.
- Carried: a `cat <<'EOF'` heredoc for a ~430-line Dart file dies with
  "unexpected EOF" — use Write; bulk string-replacing call shapes changes arity
  and leaves every call a paren short; a policy written only into the shipping
  store while tests run against the in-memory one passes against behaviour the
  app does not have; `local_auth` 3.x is not 2.x; stripping `<script>` when
  flattening a canvas; transcribing a binary out of a tool result;
  `Get-Content`/`Set-Content` on a source file; `CrossAxisAlignment.stretch` on
  a Row inside a ListView; a modal on a tab's Navigator; a here-string for
  `git commit -m`.

## Exact next steps to continue

1. **Phase 4: becoming a provider, paired with the admin queue.** This is where
   the backend starts and it is a much larger step than anything before it: a
   Django project on `/staff/*`, the `PROVIDER_CATEGORY`, `ADMIN_ACTION` and
   `DOCUMENT_ACCESS` models. Postgres 16.4 + PostGIS, Redis, MinIO and Caddy
   are already running on the Azure arm64 box. The two halves ship together
   because neither is testable alone.
2. **Re-run the gate after Phase 4's screens land** —
   `cd app && flutter drive --debug --driver=test_driver/integration_test.dart
   --target=integration_test/gate_test.dart -d <device>` — and add the new
   screens to `_shots`. The list is the gate's coverage; a screen not in it is
   a screen nobody has looked at. On a handset, stop the screen sleeping first.
3. **Tick the other 28 screens**, element by element against their artboards,
   in both modes. The splash alone produced three findings; the rest have only
   been glanced at. `app/build/gate/` holds the shots.
4. **Send `design/CORRECTIONS.md` to the design side.** Profile photos, the
   keep-screen-on preference row, and how an incoming ride reaches a driver who
   is not in the app. The last one is three different designs on Android and
   picking wrong costs a Play Store review.

## Open questions / blockers

- **BLOCKED, and only the user can clear it:** four brand files exceed the
  256 KiB `DesignSync.get_file` cap and truncate silently. They must be
  exported or re-saved smaller from the design project.
- **Undesigned, so not startable:** the dispute *flow* (UC-13) — the `DISPUTED`
  state is built, the flow that reaches it is not; customer↔provider messaging;
  provider listing management at scale; empty and offline states.
- **Unsettled product decisions:** late-cancellation fee amount; no-show
  consequence for providers; commission rate per category; dispute turnaround.
  Three booking states ship the design's own "provisional" note in the
  meantime.
- Carried: reversal policy, negative balance, minimum top-up, hosting
  durability, EPS licensing, data residency, KYC retention, GPS DPIA.
- Noted, not fixed: the design numbers two screens 21, and
  `Session.maxCodeAttempts` (5) is the repo's number, not the canvas's.
