# Work Handoff - Ipelege

**Saved:** Saturday 22 August 2026, 20:08 (+02:00)
**Branch:** main
**Last commit:** 3382f7c handoff: save session 2026-08-21 2203

## What I was working on

The three entry-flow bugs the handset found on 2026-08-21, and the reason all
three existed.

They were **not three bugs**. They were one absence: the entry flow — account
creation, sign in, OTP, reopen, unlock — had never been specified *as a
process*. Every screen in it had been built correctly against its artboard and
had passing tests. The failures were all at the **joins between** screens, which
is exactly what no artboard draws and what no screen test can see.

So the session went architecture first, at the user's direction: write the fixed
process and the standards, then fix the code against them. `docs/entry-flow.md`
is that specification and is normative. The bugs are fixed and pinned; the fixes
have **not** yet been re-run on the Galaxy S24.

## Files changed this session

**New**

- `docs/entry-flow.md` — the normative specification. Actors, four use cases
  (register, sign in on a known device, reopen, sign out), the DFD Level 2 of
  process 1.0, the full state machine, the launch decision, the OTP protocol
  including a callback contract table, 13 invariants each naming its test, the
  three defects, four canvas departures, and what is still open.
- `app/lib/routing/entry_flow.dart` — `launchRoute` and `nextEntryRoute`. Two
  pure functions, the only place either question is answered.
- `app/test/routing/launch_test.dart` — 10 tests. Every one starts at a real
  launch with a session read from the **store**, never constructed.
- `app/test/ui/entry_flow_test.dart` — 12 tests. Drives real screens against a
  fake sender and asks where the app ended up.
- `app/test/core/otp_firebase_test.dart` — 10 tests. A fake `FirebaseAuth`
  driven through every callback branch in the contract table.

**Changed**

- `app/lib/core/otp_firebase.dart` — `verificationCompleted` now resolves the
  round; a broadcast `autoVerifications` stream; a 60s backstop so no future
  unhandled callback can hang `send()` again.
- `app/lib/core/session.dart` — `OtpSendOutcome.autoVerified`;
  `OtpVerifier.autoVerifications`; `send()` lost its `onAutoVerified` parameter;
  `Session.locationAsked`; `verifiedWithoutCode()`; `lock()` documented as
  deliberately uncalled from `lib/`.
- `app/lib/core/session_store.dart` — `locationAsked` persisted, defaulting
  false so an older record is read as never-asked.
- `app/lib/routing/app_router.dart` — the launch decision, in the redirect.
- `app/lib/ui/screens/entry/verify_screen.dart` — the big one. Resend actually
  sends; consent block drawn only when the round owes consent; subscribes to
  auto-retrieval; routes through `nextEntryRoute`.
- `app/lib/ui/screens/entry/sign_in_screen.dart`, `register_screen.dart` —
  handle `autoVerified`.
- `app/lib/ui/screens/entry/biometric_enrolment_screen.dart` — uses the shared
  ladder instead of its own.
- `docs/use-cases.md`, `docs/dfd.md`, `docs/system-flowcharts.md`,
  `docs/activity-diagrams.md`, `docs/sms-otp.md`, `README.md` — cross-linked to
  the new spec. `system-flowcharts.md`'s account gate was wrong about both
  halves of the launch branch and is corrected. `activity-diagrams.md` gained
  A-0, the whole entry arc as one process flow.
- `docs/design-deltas.md` §22 — the four departures.
- `design/CORRECTIONS.md` §7 and §8 — two new items for the design side.

## What is working

- **307 tests → 339. `flutter analyze` clean.**
- All three handset bugs have a cause confirmed in code, a fix, and a test:
  - *Cannot sign in a second time*: `verificationCompleted` completed nothing.
    On a repeat sign-in Firebase instant-verifies the SIM and fires that
    **instead of** `codeSent`, so `send()` never returned and the button sat on
    "Sending…". `_verificationId` was null on that path too, so even a typed
    code could not have worked.
  - *Biometric unlock never engages*: nothing in `lib/` navigated to
    `Routes.unlock`. Reachable only from tests passing `initialLocation`.
  - *Reopen → SMS → too-many-requests*: same root. The welcome screen made no
    launch decision, so a restored session landed on "Get started / Sign in" and
    the only way forward sent a message.
- Three more found while specifying, all fixed: **resend did not resend** (wired
  to the countdown alone); **signing in overwrote consent** (`agree()` ran
  unconditionally, so an unticked optional box withdrew a granted channel); **a
  refused location was re-asked forever** (no `locationAsked`, only
  `locationGranted`).
- `.claude/skills/code-discovery/SKILL.md` is committed and pushed here
  (`d783e12`). The running copy at `~/.claude/skills/code-discovery/` is
  byte-identical except that it omits the five-line "this file is canonical"
  banner, which is the only intended difference.

## What is NOT working yet

- **None of it has been on the handset.** This matters more here than usual:
  the whole argument of `entry-flow.md` §8.2 is that a green suite proved
  nothing about reachability. `launch_test.dart` now starts from the store
  rather than constructing state, which is a real improvement, but the S24 run
  is still owed. **That is the next session's first job.**
- The 60s no-hang backstop in `otp_firebase.dart` has **no test**. Testing it
  needs `fake_async` or an injectable duration, and neither was added. Every
  other row of the callback table is covered.
- Unchanged from last session: no backend, so a sent request never becomes a
  booking and a review is dropped. The VPS is a Spot VM Azure keeps
  deallocating. Three brand cuts and one logo still exceed the 256 KiB cap.
  Nothing reads `keepScreenOnDuringRides`.

## Decisions made (and why)

- **Architecture before code, at the user's explicit direction.** Their words:
  "this is where the architecture must come into play to define the use cases,
  dfd, system flow chart and process flow for login and account creation so we
  have a fixed process and standards." Writing the spec first is what surfaced
  the three *additional* defects — none of them was on the bug list.
- **Instant verification is accepted; the code screen is skipped.** Firebase
  verifies a recently-seen number on the same handset with no SMS at all. "Every
  fresh login goes through OTP" is read as *there is no password*, not *a
  message must be billed on every entry* — the platform performs the same
  possession check against the same SIM. It cannot skip consent: a new account
  lands on `needsConsent` and is routed to `/consent`.
- **Cold start only for locking.** A warm resume does not lock. A fingerprint
  prompt every time someone checks a notification is the most common reason
  people switch biometrics off, and a backgrounded app is already behind the OS
  lock screen. This is why `SessionController.lock()` has no caller in `lib/`
  and is documented as such rather than deleted.
- **A returning member never sees `/welcome`.** It is a marketing screen. The
  Android system splash already covers the moment before the first frame.
- **No consent card on a returning sign-in.** An unticked optional box on a
  screen the member did not open to change anything is a withdrawal they never
  made. Raised to the design side as CORRECTIONS §7.
- **`locationAsked` mirrors `biometricOffered`.** False and never-asked are
  different states; only one should produce a screen.
- **The launch decision lives in the router, not in `SplashScreen.initState`.**
  A screen that decides where to go is only consulted when that screen is built
  — and that screen is precisely the one a member must not be shown.
- **Every invariant names its test.** §7 of the spec is a table of 13; a rule
  with nothing in the right-hand column is a comment, not a standard.

## Things I tried that did NOT work - do not repeat these

- **A quoted bash heredoc (`<<'EOF'`) fails in this environment** on content
  containing apostrophes — twice, with `unexpected EOF while looking for
  matching '`. Something between here and bash is re-parsing the command. Write
  the file with the Write tool, or write a Python script to a scratchpad file
  and run it. Do not keep retrying the heredoc.
- **`grep "\.lock()"` inside double quotes silently matched nothing**, and I
  briefly concluded `lock()` had zero callers. It has four, all in tests. The
  production-caller claim survived; the blanket one did not. Escaping inside
  double quotes is not the same as inside single quotes.
- **`dart format lib test` reformatted six files this session never touched.**
  Reverted them. The repo is not fully formatted, so a blanket format inflates
  the diff with unrelated churn.
- **`ref.read(provider.notifier).state` is not the way to read back a mutation.**
  Use `ref.read(provider)` after the call.
- Carried and still true: a seam that discards the cause is not observable; a
  test that constructs the state it tests cannot prove the state is reachable;
  do not conclude from a search; heredocs for large Dart files; `local_auth` 3.x
  is not 2.x; never transcribe a binary.

## Exact next steps to continue

1. **Run the entry flow on the Galaxy S24, debug build.** In order: cold start
   with no account → register → verify → enrol → location → home; kill and
   reopen → must land on `/unlock`, never on `/welcome`; unlock with a
   fingerprint; sign out; sign in again → this is the instant-verification path,
   watch for `otp: verificationCompleted, no code needed` and confirm no SMS is
   billed. `logcat -s flutter:V` reports every OTP outcome now.
2. **Watch for `otp: confirm accepted`** — the typed-code confirm half has still
   never been seen succeeding in a real log.
3. Decide whether the 60s backstop earns a test. If yes, `fake_async` in
   `dev_dependencies` is the smaller change.
4. Deal with the VPS deallocation. Spot eviction is the cause and it will recur;
   Phase 4 puts a ledger there and a ledger cannot live on a VM Azure can stop
   mid-transaction.
5. Phase 4: becoming a provider, paired with the admin queue.
6. Tick the remaining 27 screens element by element.
7. Send `design/CORRECTIONS.md` to the design side — nine entries now, two of
   them new this session.

## Open questions / blockers

- **From the spec's §10, all genuinely undecided:** account recovery when the
  number is gone (the number *is* the identity, so a lost SIM currently loses
  the account, and every option has a fraud shape); whether signing in on a
  second handset should end the first; what rate limit is ours to set once an
  aggregator replaces Firebase's unpublished per-number throttle; whether
  `/unlock` should add a lockout on top of the OS's own.
- BLOCKED, user-only: four brand files exceed the 256 KiB `get_file` cap.
- Undesigned: the dispute flow, messaging, the calling screens, empty and
  offline states, profile photos.
- Unsettled and carried: late-cancellation fee, no-show consequence, commission
  per category, dispute turnaround, whether the design wants number privacy
  back, reversal policy, negative balance, min top-up, hosting durability, EPS
  licensing, data residency, KYC retention, GPS DPIA.
