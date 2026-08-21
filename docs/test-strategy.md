# Test strategy

[sdlc-overview](sdlc-overview.md) named this the next document to write, and
named the reason: *ledger correctness and booking state transitions need
property-based and concurrency tests, not just unit tests.* That is the whole
thesis of this document. Everything else here is ordinary.

## What actually threatens this product

Testing effort should be spent where a defect is unrecoverable, not spread
evenly. Four failures are unrecoverable:

| Failure | Why it cannot be walked back |
|---|---|
| **A wrong ledger balance** | The journal is append-only. A bad entry is corrected by another entry, which means the error is permanent, visible, and has to be explained to a provider who has already lost trust. |
| **A double-charged commission** | The provider paid twice for one job. They will not report it — they will leave, and tell other providers why. |
| **A booking in an impossible state** | The state history is what a dispute is adjudicated from. If it is incoherent, the dispute cannot be settled at all. |
| **Personal data leaking or surviving erasure** | BWP 50 million or 4% of turnover, and imprisonment for some offences ([compliance](compliance.md)). |

Everything else — a mis-rendered card, a slow list, a wrong label — is a bug you
fix on Tuesday. The four above are the ones that need tests that go looking for
trouble rather than confirming the happy path.

## Shape of the suite

```
        /\        Manual exploratory · real handset, real 3G
       /  \       Integration tests (Flutter integration_test, few, slow)
      /----\      API / contract tests (moderate)
     /      \     Property + concurrency tests (small in count, high in value)
    /--------\    Unit tests (many, fast)
```

Inverted in one respect from the usual advice: the property and concurrency
layer is small in test *count* but is where the difficult thinking goes. Six
property tests over the ledger are worth more than six hundred unit tests over
serializers.

## Backend — Django

### Unit

`pytest` + `pytest-django`. Standard, fast, no network.

Rules:

- **Tests run against real PostGIS**, never SQLite. Half the invariants in
  [database](database.md) — partial unique indexes, deferred constraint
  triggers, revoked privileges, `geography` types — do not exist in SQLite. A
  suite that passes there proves nothing about the things most likely to break.
- No mocking of the database or the ORM. Mock the *network* — payment
  providers, Meta, SMS, maps — and nothing else.
- Factories (`factory_boy`) over fixtures for object graphs; the shared seed
  fixture is only for reference data (the nine categories, chart of accounts,
  VAT rate).

### Property-based — the ledger

`hypothesis`. These are the tests the SDLC document was asking for.

Invariants that must hold for **any** sequence of valid operations:

1. **Every transaction sums to zero.** Generate arbitrary transaction types in
   arbitrary order; assert `SUM(credits) - SUM(debits) = 0` per transaction,
   always.
2. **Derived balance equals cached balance.** After any operation sequence,
   `ledger.account_balance` and `account_balance_cache` agree. This is the test
   that catches a trigger that fires in the wrong order.
3. **Replaying a sequence produces an identical journal.** Same inputs, same
   keys, same result — the definition of idempotency.
4. **Reversal restores the prior balance exactly.** For any deduction,
   deduct-then-reverse returns the account to the balance it had, to the thebe,
   including VAT. This is where rounding bugs surface: reversing a rounded fee
   with a recalculated figure leaves a residue, and only a property test over
   many amounts finds it.
5. **No sequence produces a negative platform-side imbalance.** The sum of all
   entries across all accounts is zero at every point.
6. **Rounding is applied once.** For any fare, `round(fare × rate)` computed
   directly equals the stored `commission_amount`. Half-up, never half-even —
   P0.125 must become P0.13.

Amount generators must include the values that break naive money code: 0.01,
0.005, amounts where 8% lands exactly on a half-thebe, and the largest amount
`numeric(12,2)` holds.

### Property-based — the booking machine

7. **No sequence of events reaches an undrawn state or transition.** Generate
   random event sequences against the eleven states in
   [system-flowcharts](system-flowcharts.md); assert every resulting transition
   appears in the diagram. This is what stops `AWAITING_PAYMENT` being skipped
   by a code path nobody remembered.
8. **`booking_event` always reconstructs the current state.** Replay the event
   log from the start; the final state matches the booking row. If it does not,
   dispute adjudication is unsound.
9. **Commission posts exactly once across any path to COMPLETED** — including
   via `DISPUTED` resolution, including with retries interleaved.

### Concurrency

Real threads and real connections. Not `TestCase`, which wraps each test in a
transaction and hides exactly the races being hunted — these use
`TransactionTestCase` or a direct pool.

| Race | Test |
|---|---|
| Two callbacks for one top-up land simultaneously | One journal transaction exists afterwards; the loser sees the winner's result, not an error |
| Provider taps "complete" twice, fast | One commission transaction |
| Two drivers accept the same dispatch simultaneously | Exactly one `ACCEPTED`; the other gets a clean "already taken", not a 500 |
| Deduction and reversal commit at the same moment | Balance is correct under either ordering, and the ordering is recorded |
| Balance check and deduction race | A provider at the credit floor cannot be driven below it by two concurrent bookings — the `SELECT … FOR UPDATE` in [database](database.md#balances-are-derived) is what this test exists to verify |

The last one is the important one. It is the test that fails if someone
"optimises" the authorisation read to use the balance cache.

### Database invariants

Tested directly, because they are enforced in the database and the application
must not be trusted to describe them accurately:

- `UPDATE` on `ledger.journal_entry` **raises**, as the app role.
- `DELETE` on `ledger.journal_entry` **raises**, as the app role.
- An unbalanced transaction **fails at COMMIT**, not silently.
- A duplicate `idempotency_key` **raises a unique violation**.
- A second live `provider_category` row for the same user and category
  **raises**; a second *historical* row does not.
- A `service_area` with both a polygon and a radius **raises**.
- A negative `amount` **raises**.

These tests exist because privileges and triggers are the kind of thing a
migration silently drops. If the grants are ever lost, this is what says so.

### Compliance

These are the tests that hold the
[designed-in mitigations](compliance.md#designed-in-mitigations--what-to-build-now)
honest. Each one guards a rule that is otherwise enforced only by someone
remembering it.

**Erasure**

- **Leaves no personal data** — after an erasure request, assert every column in
  the `identity` schema is null or the row is gone, `core.user.phone` is null,
  and KYC objects are actually **deleted from object storage**, not merely
  dereferenced.
- **`core.user.email` is overwritten with the placeholder, not nulled**, and the
  account can no longer authenticate. Nulling it would break Django's
  `USERNAME_FIELD` contract, so this is a real regression risk.
- **Leaves the ledger intact** — balances and history unchanged.
- **Is blocked, with a reason, when a dispute or live booking exists** — and the
  reason is retrievable by the app. A silent no-op is the failure mode.
- **No ledger table ever contains a name.** Assert by schema inspection, not by
  reading code — this is the assumption the whole erasure design rests on, and
  it fails by someone adding a convenience column.

**Retention and holds**

- **The settings assertion fires.** Set `DISPUTE_WINDOW_DAYS` above
  `TRIP_TRAIL_RETENTION_DAYS` and assert the application refuses to start.
- **Sweepers respect the legal hold** — place a hold, advance the clock past
  retention, run the sweeper, assert nothing was deleted. Release the hold, run
  again, assert it was.
- **Sweepers actually delete** when unheld — the partition is dropped and the
  objects are gone from storage, not just the rows.
- **A raised dispute places its hold in the same transaction.** Roll the
  transaction back and assert no orphan hold and no unprotected evidence.

**Consent and outbound**

- **No outbound message or external post** is produced without a current,
  granted, correctly-typed consent record; consent is read at action time and a
  superseded version does not authorise.
- **No cross-channel fallback** — absence of WhatsApp consent must not produce
  an SMS.
- **The safety gate blocks, never strips** — Botswana number formats
  specifically: local, `+267`-prefixed, spaced and dashed variants. A generic
  international regex passes this test while failing in production.

**Data leakage**

- **No personal data in domain event payloads.** Assert payloads carry IDs, not
  names, phones or emails — the outbox is retained, so a payload leak is a
  second copy nobody scheduled for deletion.
- **No phone numbers or tokens in application logs.** Logs are rarely covered by
  the retention schedule and are frequently shipped off-box.

**Auth**

- **`phone` is unique even while unverified** — a second registration with the
  same number fails at registration, not at some future migration.
- **`phone_hash` still answers "has this number registered"** where retained,
  and is a keyed HMAC rather than a plain digest.
- **Consent gates hold** — no outbound message or external post is produced
  without a current, granted, correctly-typed consent record; consent is read at
  action time and a superseded version does not authorise.
- **The safety gate blocks, never strips** — Botswana number formats
  specifically: local, `+267`-prefixed, spaced and dashed variants. A generic
  international regex passes this test while failing in production.
- **Retention sweepers actually delete** — advance the clock, run the job,
  assert the partition is dropped and the objects are gone.

### API contract

OpenAPI is generated from the implementation, per
[sdlc-overview](sdlc-overview.md), so the schema is an output not an input. What
is tested: that the generated schema does not change without a version bump, and
that the Flutter client's expectations match it. Schema diffs are reviewed in
pull requests like code.

## Flutter

### Unit and widget

- Pure Dart for anything with logic — Pula formatting, the booking state
  mapping, the fee breakdown display, direction handling.
- Widget tests for components with states: the verification chip, the direction
  control, the balance card, the five-step progress bar.
- **Golden tests in both light and dark** for every component in
  [design-system](design-system.md#components). This is the cheapest possible
  guard on a two-theme design, and the design's own rule — status pairings are
  re-toned, never re-hued — is exactly what a golden test catches when someone
  reuses a light token in a dark widget.

### Money formatting

Its own suite, because it is user-visible, easy to get wrong, and explicitly
must not inherit device locale:

`P0.00` · `P9.60` · `P1 250.00` · `−P1.34` · a thousands separator that is a
space, not a comma · two decimal places always, including on whole numbers.
Tested under a non-Botswana device locale, which is where the bug appears.

### Integration

`integration_test`, on a real device or emulator, kept few and covering only
journeys where the cost of breakage is high:

1. Visitor browses → hits the auth gate at booking → registers → the original
   action resumes.
2. Provider applies for a category → uploads documents → backgrounds the app →
   process is killed → returns to the same step with documents attached. This
   is the state-restoration requirement in
   [design-system](design-system.md#state-restoration) and it is the one that
   cannot be verified any other way.
3. Booking runs to `COMPLETED` through `AWAITING_PAYMENT`, and the ledger shows
   fee and VAT as two lines.
4. Mode switch: provider-side bookings never appear in the consumer list. The
   design calls this the load-bearing rule of the account model.

The `flutter-e2e-kickstart` skill in this environment scaffolds this setup.

### Back-button behaviour

The design writes the back rules as a **specification, not guidance**. Test
them as one — particularly the `replace` cases, where back must not re-enter a
flow and post a second deduction. That is a money bug reachable with a hardware
gesture.

## What a green suite does not mean

**Raised on 2026-08-21: "the SMS code you test is not accurate, because there
is no backend for it — the OTP is just a dummy."** Correct, and the point
generalises. Several seams in this app ship a real implementation and default
to a fake, so that a widget test never needs a platform channel or a network.
That is a good pattern and it has a specific cost: **a passing test proves the
rule, not the thing.**

This section names every stub and says exactly what it hides, so nobody reads
`All tests passed` as a claim the feature works.

| Seam | Fake | What the tests DO prove | What they do NOT |
|---|---|---|---|
| `OtpVerifier` | `DemoOtpVerifier` — `isCorrect` is `code.length == 4` | The state machine: OTP is unskippable, attempts are limited, resend cools down, back is blocked mid-round-trip, a wrong code is handled | **That any code is right or wrong.** No SMS is sent, none is received, and every four-digit string is accepted |
| `Biometrics` | `AlwaysAllowBiometrics` | The screen's branching, the refusal path, that biometry only ever *unlocks* | ~~Whether the platform agrees~~ — **closed 2026-08-21** on a Galaxy S24: both availability branches, a real prompt, a real fingerprint |
| `SessionStore` | `InMemorySessionStore` | What is kept and what is dropped, and that a reopen never lands on `active` | Nothing much — both implementations share one `write`, deliberately, after a bug where they did not |
| `SettingsStore` | `InMemorySettingsStore` | That a set preference is written, and survives a relaunch | Nothing much — same shared-write shape |
| Everything server-side | `Demo` | That screens render the data they are given | **That a booking exists.** A sent request becomes nothing, a submitted review is dropped, no money moves |

### The rule this produces

**A seam's fake must be more permissive than the real thing, never less.**
`DemoOtpVerifier` accepting everything is safe in that direction: no test can
pass *because* the fake rejected something the real one would allow. A fake
that was stricter than production would hide real failures behind green.

### The one that proved the cost

`AlwaysAllowBiometrics` said `ready` to everything, so every test passed and
**one entire branch of the shipped code had never run**. It took a real handset
to find that the emulator — a sensor with nothing enrolled — takes the
*other* path, and that the passcode-only layout still had a hardcoded
fingerprint glyph over copy telling the user to use a passcode.

Nothing in the suite could have caught it. That is the shape of every row above
that is still open, and the OTP row is the largest of them.

### What closes the OTP row

Real delivery, which is Phase 4 territory at the earliest — the backend does
not exist yet. Until then `DemoOtpVerifier` stays, and this table is the honest
statement of what the entry flow's green tests are worth: **the rules around
the code are tested; the code is not.**

---

## UI ticks — comparing a screenshot to its artboard, element by element

**A tick is earned per element, not per screen.** For every screen that is
built: take the gate's screenshot, open the artboard it came from, and compare
**each element in turn**, writing down the verdict for each. A screen is not
ticked because it "looks right".

**This rule exists because of a specific failure, on 2026-08-21.** The splash
screen was photographed on two devices and reviewed. The reviewer — me — read
the shot, noted that light and dark were byte-identical, correctly explained
*why* that was right, and called the screen correct.

The wordmark on it was flat white. The canvas requires a **light-blue `i`** and
white `pelege`, and says so in the one sentence in the whole design that names
what a wordmark must not lose: *"the wordmark keeps the blue i — the earlier
set had been assembled from different exports and dropped both."* The repo has
an entire document, [`identity.md`](identity.md), whose purpose is stopping
exactly that.

It was not missed for lack of evidence. The screenshot was on screen, at full
size, and the defect is plainly visible in it. **It was missed because the
screen was reviewed as a whole rather than element by element** — the eye
confirmed a gestalt it already expected. The user caught it by looking at the
same image.

That is the failure mode this section exists to prevent, and no amount of
"look more carefully" fixes it. Only enumeration does.

### The procedure

1. **List the elements from the artboard first**, before looking at the
   screenshot. Working the other way round means the screenshot decides what
   you check, and anything it is missing is invisible.
2. For each element, compare **shape, colour, type, spacing and copy**
   separately. Copy is compared **character by character** where the design
   wrote it — the booking states and the loop prompt are verbatim strings.
3. **Write the verdict per element**, not per screen. "Matches", "differs —
   recorded as delta §n", or "differs — bug, fixed in <commit>".
4. Do it **in both modes**. The dark cut of an asset is different artwork, not
   a tint, and the two most recent brand bugs were both dark-only.
5. Anything that differs goes to [`design-deltas.md`](design-deltas.md) if the
   departure is deliberate, or to a fix if it is not. Nothing is left as a
   remembered observation.

### What does not count as a tick

- "Looks right" / "renders correctly" / "matches the canvas" for a whole
  screen.
- A comparison made from memory of the artboard rather than with it open.
- A light-mode check standing in for both modes.
- A screenshot taken but not actually opened.

### Why the automated tests do not replace this

They pin what can be stated as a rule — contrast floors, motion durations,
verbatim copy, which routes render. They cannot tell you the wordmark lost a
colour, because nobody had written down that it must not. **The tick is where
new rules come from**: every one of `contrast_test.dart`,
`motion_test.dart` and the wordmark assertions in `identity_test.dart` exists
because a human comparison found something first, and each was then written
down so it never has to be found by eye again.

---

## Performance and device reality

The market is Android 8+, 1–2 GB RAM, 3G, binary under 30 MB. That is a
requirement, so it is tested:

- **Binary size is a CI gate.** The build fails over 30 MB rather than being
  noticed at release.
- **Frame timing on a real entry-level handset**, not the emulator. The design's
  motion rules exist because of this hardware; verifying them on a flagship
  proves nothing.
- **Throttled-network runs** — every loading band in the design assumes 3G, and
  the 6-second upload case is the common one, not the rare one.
- **Cold start on a killed process**, since Android reclaims memory constantly
  on these devices.

Backend load testing is deliberately **not** a launch activity.
[architecture](architecture.md) is explicit that nothing here is
throughput-bound at launch volumes, and time spent load testing is time not
spent on ledger correctness.

## CI

Every pull request:

1. Lint and format — `ruff` + `black`, `dart format` + `flutter analyze`
2. Backend unit + property tests against PostGIS in a service container
3. Database invariant tests
4. Flutter unit, widget and golden tests
5. Binary size gate
6. OpenAPI schema diff

Nightly: concurrency suite (slow, real threads), full property run with a raised
`hypothesis` example count, and the Flutter integration suite on a device.

**Coverage is measured but not gated on a percentage.** A number invites tests
written to raise the number. What *is* gated: the `ledger` app, the booking
state machine and the erasure path have no untested branches, checked by review
rather than by a threshold.

## What is deliberately not tested

- **The admin panel's Django-admin-provided CRUD.** Django's own test suite
  covers it. Custom admin actions — approving a category, confirming a reversal
  — are tested, because they are ours and they move money.
- **Third-party APIs.** Mocked at the boundary. Contract drift is caught by the
  reconciliation job in production, which is itself tested.
- **Mermaid diagrams and prose.** Reviewed, not tested.

## Open

- Whether to run a `hypothesis` stateful/`RuleBasedStateMachine` model of the
  full booking + ledger interaction, rather than separate property suites. More
  powerful, materially harder to debug when it fails.
- Load-test thresholds, once there are real volumes to base them on.
- Whether golden tests run on CI or only locally — they are render-environment
  sensitive and can be a maintenance tax.
