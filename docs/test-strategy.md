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
