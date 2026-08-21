# Work Handoff - Ipelege

**Saved:** Friday 21 August 2026, 22:03 (+02:00)
**Branch:** main
**Last commit:** 227b29c Log a successful OTP confirmation, not only a rejected one

## What I was working on

Resumed the 13:28 handoff and ran a very long session that went well past its
plan. In order: ran **Phase 0's gate** on everything built since 2026-08-20
(both halves), **closed Phase 1** by verifying biometrics on a real handset,
built **Phase 3.5** (the settings spine), **changed the auth model**, **wired
Firebase** and got **real SMS delivering to a Botswana number**, and extracted
a **code-discovery skill** after a search-driven conclusion turned out wrong.

The session ended on three bugs found by testing the entry flow on the handset.
**They are the next session's first job** — see *What is NOT working yet*.

## Files changed this session

Fourteen commits, `599d16e` … `227b29c`. The shape of it:

- **Motion & colour gate** — `motion.dart` consumers built
  (`enter_in_place.dart`, `MoneyCounter`, the booking state table),
  `integration_test/gate_test.dart` + `test_driver/`,
  `AppPalette.controlOutline`, `contrast_test.dart`.
- **Biometrics on hardware** — `integration_test/biometric_test.dart`,
  `unlock_screen.dart` glyph fix.
- **Phase 3.5** — `core/settings.dart`,
  `ui/screens/settings/preferences_screen.dart`, `theme/theme_mode.dart`
  **deleted**, `preferences_test.dart`.
- **Auth model** — `session_store.dart` (`reopened` always → `locked`),
  `unlock_screen.dart` (no-device-lock fallback).
- **Firebase** — `firebase_options.dart`, `google-services.json`,
  `core/otp_firebase.dart`, `OtpVerifier` made async with a `send` half,
  `main.dart` init, `Session.codeLength` 4 → **6**.
- **Docs** — `device-permissions.md`, `sms-otp.md`, `CODE-DISCOVERY-GUIDE.md`
  (retargeted), `design/CORRECTIONS.md` (new, 7 entries), `design-deltas.md`
  §17–§21, calling folded into `architecture.md`, `docs/calling.md` deleted.
- **Skill** — `.claude/skills/code-discovery/SKILL.md`, its global copy, and two
  `PostToolUse` hooks in `~/.claude/settings.json`.

## What is working

- **Phase 0 closed.** 28 screens shot in both modes on a Galaxy S24 **and** the
  emulator; the palette holds everywhere. The gate is a script now:
  `flutter drive --debug --driver=test_driver/integration_test.dart
  --target=integration_test/gate_test.dart -d <device>`.
- **Biometrics verified end to end on real hardware.** Both availability
  branches, a real system prompt, and a real fingerprint reopening a locked
  session with the same name on the far side.
- **Real SMS works.** `otp: codeSent` at 21:32, delivered to +267 77 744 018,
  on the **free Spark plan**. Play Integrity attestation confirmed in the log.
- **Dark mode is reachable** — Preferences ships Appearance and the
  keep-screen-on preference, and the choice survives a restart.
- **307 tests**, `flutter analyze` clean.
- **The VPS is up again** and all four containers returned healthy on their own.

## What is NOT working yet

**The three entry-flow bugs the next session starts on.** Found on the handset.
Symptoms are as observed; **causes have not been investigated** — the
hypotheses below are starting points, not findings.

1. **Cannot sign in a second time.** After a successful login, signing in again
   fails.
2. **Biometric unlock never engages.** The offer to allow it appears and is
   accepted, but no biometric prompt is ever raised afterwards.
3. **A reopen falls back to SMS and then hits `too-many-requests`.** Because 2
   never engages, every reopen goes back through a code and Firebase
   rate-limits the device.

*Unverified hypothesis, recorded only so there is somewhere to start:* all
three are consistent with **the session not being restored at all** — a reopen
landing on `SessionStage.none` rather than `locked` would produce exactly this
trio. `SessionCodec.reopened` was changed this session to always return
`locked`, and `PrefsSessionStore` is wired only in `main()`. **Prove whether
the session is written and read back before assuming the reopen logic is
wrong.** Give this the code-discovery treatment rather than a guess — this
session has already produced two confident wrong answers from not doing that.

Also outstanding:

- **The OTP confirm half is unconfirmed.** `codeSent` is proven; whether
  `signInWithCredential` accepts the typed code has never been seen in a log,
  because success only started logging in the final commit.
- **No backend.** A sent request never becomes a booking; a review is dropped.
- **The VPS is a Spot VM** — `Standard_D2pds_v6`, `priority: Spot`,
  `evictionPolicy: Deallocate`. Azure will keep deallocating it; it went down
  once during this session. **Agreed to deal with this next session.**
- Three brand cuts and one logo still exceed the 256 KiB fetch cap.
- Nothing reads `keepScreenOnDuringRides` yet — Phase 5 owns that.

## Decisions made (and why)

- **Dropped "an OTP every time the app is opened".** Not on cost — the check
  does not work. An SMS code proves possession of the SIM, and on a reopen the
  SIM is inside the handset the person is holding, so against a stolen phone it
  proves nothing while costing a message per launch. Every reopen asks for the
  device credential instead. §20.
- **The OTP is six digits.** Firebase sends six and it is not configurable, so
  the artboard's four boxes cannot accept the code that arrives. Forced, not
  chosen. §21.
- **Firebase for messaging and SMS, never for identity.** `FirebaseOtpVerifier`
  throws the Firebase user away and reports only whether the code was right.
  The account of record stays the app's own session, and later the Postgres row
  beside the wallet and the KYC documents — the same lock-in argument
  `architecture.md` already made against Firebase as a backend.
- **Phase 3.5 was pulled forward** because dark mode was finished and
  unreachable: both themes and the provider existed with no control anywhere.
- **Both call routes will be built**, on competitive parity rather than privacy —
  inDrive and the others offer an in-app call *and* a phone call in this market.
  Matrix rejected: a homeserver and a second identity system for two features.
- **A UI tick is earned per element, not per screen.** Adopted after a
  whole-screen review passed a flat-white wordmark plainly visible in the image.
- **Device tests are debug builds, always** — the driver attaches to the Dart VM
  service, which a release build does not have.

## Things I tried that did NOT work - do not repeat these

- **A seam that discards the cause is not observable.** `_readFailure` mapped a
  `FirebaseAuthException` onto four enum values and dropped `e.code`, so a real
  failure surfaced as "could not send a code" with nothing saying why. No amount
  of watching logcat recovers information that was never emitted. **Logging only
  the failure branch is the same bug half-fixed** — success and never-attempted
  looked identical until the last commit.
- **A sleeping screen kills an on-device gate and names nothing useful.**
  `PixelCopy` throws `Window doesn't have a backing surface!`, the app takes
  SIGKILL, the driver reports `Service has disappeared`, and **no screenshots
  survive** — the driver flushes at the end.
- **An `AnimatedSwitcher`'s outgoing child animates on the controller it was
  built with.** Flipping `duration` from zero at the moment of the change leaves
  the outgoing half at zero. Instantness must come from unmounting the switcher.
- **"Has it changed" is not "is it different from where it started."**
- **A widget test pumping a screen needs `AppTheme`**, not a bare `MaterialApp` —
  the palette is a `ThemeExtension`.
- **Do not conclude from a search.** I read a gate, concluded a button was
  disabled, and said so; the user had already passed that screen. The real bug
  was one level in — `_send()` navigated without ever asking for a code.
- **Do not claim a file is absent after grepping two directories.** I said no
  VPS host was recorded anywhere; `.env` had it, with the Azure IDs.
- Carried: heredocs for large Dart files; bulk string-replacing call shapes;
  a policy written only into the shipping store; `local_auth` 3.x ≠ 2.x;
  stripping `<script>` when flattening a canvas; transcribing a binary.

## Exact next steps to continue

1. **Fix the three entry-flow bugs.** Reproduce on the handset first —
   `adb -s adb-RZCXA17Z2JK-ig29zg._adb-tls-connect._tcp logcat -s flutter:V`
   now reports both OTP outcomes. Begin by proving whether the session is
   persisted and restored at all.
2. **Deal with the VPS deallocation.** Spot eviction is the cause and it will
   recur. Convert to Regular, automate a restart, or accept it knowingly — but a
   ledger cannot live on a VM Azure can deallocate mid-transaction, and Phase 4
   puts one there.
3. **Confirm the OTP round trip** — watch for `otp: confirm accepted`.
4. **Phase 4:** becoming a provider, paired with the admin queue.
5. **Tick the remaining 27 screens** element by element. Only the splash has had
   a real one and it produced three findings.
6. **Send `design/CORRECTIONS.md` to the design side** — seven entries now.

## Open questions / blockers

- **Why the VPS keeps stopping is answered — Spot eviction.** What to do about
  it is next session's call.
- **BLOCKED, user-only:** four brand files exceed the 256 KiB `get_file` cap.
- **Undesigned:** the dispute *flow*, messaging, the calling screens, empty and
  offline states, profile photos.
- **Unsettled:** late-cancellation fee, no-show consequence, commission per
  category, dispute turnaround, and whether the design wants number privacy back.
- Carried: reversal policy, negative balance, minimum top-up, hosting
  durability, EPS licensing, data residency, KYC retention, GPS DPIA.
