# Work Handoff - Ipelege

**Saved:** Friday 21 August 2026, 13:28 (+02:00)
**Branch:** main
**Last commit:** 4a5a72f handoff: save session 2026-08-21 0513

## What I was working on

Resumed from the 05:13 handoff and built straight down `docs/build-order.md`:
finished **Phase 2**, built **Phase 3** whole, then closed **all three of Phase
1's open remainder items**. The repo went from 177 tests to **254**, with
`flutter analyze` clean and `flutter build apk --debug` green throughout.

Three screens, one rules engine, two platform integrations, and the docs that
had to stop being wrong once each landed.

## Files changed this session

**New — Phase 2 (booking):**
- `app/lib/ui/screens/consumer/booking_request_screen.dart` — screen 5, the
  direction radio set and the conditional location card
- `app/lib/ui/screens/consumer/rate_review_screen.dart` — screen 8
- `app/lib/ui/components/screen_header.dart` — extracted from the status screen
  so both booking steps share one header

**New — Phase 3 (the loop):**
- `app/lib/core/loop_prompt.dart` — the pairs and the four suppression rules
- `app/lib/ui/components/loop_prompt_card.dart` — the card on a closed booking
- `app/lib/ui/screens/consumer/loop_handoff.dart` — the rental→movers sheet

**New — Phase 1 remainder:**
- `app/lib/core/session_store.dart` — session persistence and the reopen policy
- `app/lib/core/biometrics.dart` — the `local_auth` seam

**New tests:** `booking_request_test`, `rate_review_test`, `loop_test`,
`core/loop_prompt_test`, `core/session_store_test`, `routing/consent_redirect_test`,
`ui/unlock_test`.

**Modified:** `routes.dart`, `app_router.dart` (two new routes, the consent
redirect, loop decisions), `session.dart` (`needsReconsent`, `restore`, a single
`_set` write point), `main.dart` (prefs + platform biometrics), `demo_data.dart`
(rentals listings, `listingOf`, `loopAfter`), `listing_detail_screen.dart`,
`booking_status_screen.dart`, `category_browse_screen.dart`,
`unlock_screen.dart`, `MainActivity.kt`, `AndroidManifest.xml`, `pubspec`.

**Docs:** `build-order.md`, `design-deltas.md` (§15, §16), `booking.md`,
`categories.md`, `compliance.md`, `design-system.md`.

## What is working

- **Phase 2 complete.** Booking request → status → rate & review, with the
  auth gate joining listing detail to the request form. Sending is a *replace*
  so back cannot fire a second request; rate & review submits nothing until a
  star is tapped.
- **Phase 3 complete.** Four adjacency pairs, four suppression rules, two
  placements. Against the real launch supply figures **only the rentals→movers
  prompt fires** — the other three point at thin categories and are correctly
  withheld. There is a test pinning that so nobody "fixes" it later.
- **Consent supersede is enforced**, not just modelled: a router redirect sends
  any `needsReconsent` session to `/consent`. Visitors and locked sessions are
  deliberately exempt.
- **The session persists** and never comes back `active` — biometry on restores
  to `locked`, biometry off goes back through the code.
- **Biometric unlock is wired to the platform.** Two distinct prompts, the
  no-sensor state handled in both directions, refusals silent.
- 254 tests, `flutter analyze` clean, debug APK builds.

## What is NOT working yet

- **Nothing built since 2026-08-20 has been seen on a handset.** Booking
  request, rate & review, the rentals listing, both loop placements and the new
  unlock screen are all unverified visually. Phase 0's gate (colour *and*
  motion, both modes) is owed on all of them.
- No backend. A sent request does not become a booking; a submitted review is
  returned to the caller and dropped; `DemoOtpVerifier` still accepts any four
  digits.
- The four brand cuts still exceed the 256 KiB fetch cap.
- Ten of the eleven booking actions are inert. Only `COMPLETED` → rate & review
  goes anywhere, and each of the others is blocked for a reason already in the
  build order.
- No picker behind the booking request's `WHEN` card — scheduling granularity
  per category is still an open question.

## Decisions made (and why)

- **Phase 3 was buildable despite being marked `gap`.** The journey map gives
  the trigger points, the pairs, the four states and one finished line of copy.
  What it lacks is an artboard. `LoopPair.verbatim` marks the design's one
  string so a later canvas can replace ours without a diff archaeology session.
- **Rides is a target, never a source** for the loop prompt: it is dispatch so
  it has no browse to land on, and it is the highest-frequency category, so
  prompting after every ride is the banner stage 7 exists not to be.
- **An unknown supply figure counts as thin.** Not knowing whether a room is
  empty is not grounds for sending someone into it.
- **A restored session never comes back `active`.** That is the one way
  persistence could be wrong that matters — it would make a stolen handset a
  signed-in handset.
- **`ServiceDirection.either` was kept**, against the canvas, because
  `booking.md` makes "Both" a *listing* property. The customer still picks one
  of two; `ServiceDirection.choices` says so in code.
- **The rating star reads `palette.accentText`, not the canvas's `#145A8D`
  literal** — identical in light, legible in dark.
- **"you pay them directly"**, where the canvas writes "him" of a provider named
  Kabelo. It is a template rendered for every provider on the platform.
- **No `refreshListenable` on the consent redirect.** `Consent.current` is a
  compile-time constant, so a version cannot be superseded mid-session; the case
  it catches is a *restored* session.

## Things I tried that did NOT work - do not repeat these

- **A `cat <<'EOF'` heredoc through the Bash tool for a ~430-line Dart file**
  died with "unexpected EOF". Use the Write tool for whole files; heredocs are
  fine for short ones and the encoding is correct UTF-8 either way.
- **Bulk `str.replace` on `state = state.copyWith(` → `_set(state.copyWith(`**
  left every call one closing paren short. If you rewrite call shapes
  mechanically, the arity changes too — check `flutter analyze` before moving on.
- **Putting the keep-or-drop rule only in `PrefsSessionStore.write`** while every
  test ran against `InMemorySessionStore` meant tests passed against behaviour
  the app did not have. Two tests caught it. Both stores now share one `write`.
- `local_auth` **3.x is not 2.x**: no `error_codes.dart`, no
  `AuthenticationOptions`, `stickyAuth` is now `persistAcrossBackgrounding`, and
  errors are typed `LocalAuthException` / `LocalAuthExceptionCode`.

## Exact next steps to continue

1. **Run Phase 0's gate** on everything built since 2026-08-20 — a Pixel in both
   modes, colour *and* motion. This is owed before Phase 4 and is the one thing
   blocking a clean "Phase 1–3 done".
2. **Verify biometric unlock on real hardware.** It builds and is unit-tested
   behind a fake; the sensor path itself has never run.
3. **Phase 4 — becoming a provider, paired with the admin queue.** This is where
   the backend starts: Django on `/staff/*`, plus `PROVIDER_CATEGORY`,
   `ADMIN_ACTION` and `DOCUMENT_ACCESS`. Both halves ship together because
   neither is testable alone. Postgres is already running.

## Open questions / blockers

- **BLOCKING, only the user can clear it:** `mark-dark`, `wordmark-dark-new`,
  `lockup-dark` and `logo-light-transparent` exceed the 256 KiB `get_file` cap.
- Undesigned so not startable: the dispute **flow** (UC-13), customer↔provider
  messaging, provider listing management at scale, empty and offline states.
- Late-cancellation fee amount; no-show consequence for providers; per-category
  commission rate; dispute turnaround time.
- Carried: reversal policy, negative balance, min top-up, hosting durability,
  EPS licensing, data residency, KYC retention, GPS DPIA.
- Noted not fixed: the design numbers two screens 21; `Session.maxCodeAttempts`
  (5) is the repo's number, not the design's.
