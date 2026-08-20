# Database layer specification

The physical design. [data-model](data-model.md) says *what* the entities are
and why; this says how they exist in PostgreSQL — types, constraints, indexes,
privileges, migrations — and which of those rules the application is **not**
permitted to enforce on its own.

Read [data-model](data-model.md) first. Where the two disagree, that is a bug in
this document.

## Engine

| | |
|---|---|
| Engine | PostgreSQL 16 |
| Extensions | `postgis` (3.4+), `pgcrypto`, `pg_stat_statements`, `btree_gist` |
| Encoding / collation | `UTF8`, `en_US.UTF-8`, `ICU` provider |
| Timezone | Cluster runs `UTC`. Africa/Gaborone is a presentation concern only. |
| ORM | Django 5.x + `django.contrib.gis` (GeoDjango) on `psycopg` 3 |

`postgis` is required by `SERVICE_AREA`, `TRIP_LOCATION` and driver proximity
matching. `pgcrypto` is for `gen_random_uuid()`. `btree_gist` is needed for the
exclusion constraint on `PROVIDER_CATEGORY` described below.

**One database, four schemas.** Not four databases — the ledger must commit in
the same transaction as the booking state change that caused it, and a second
database would turn that into a distributed-transaction problem the project does
not need ([architecture](architecture.md)).

| Schema | Contents | Erasable | Django app |
|---|---|---|---|
| `identity` | `user_profile`, `consent_record`, `verification_document` | **Yes** — this is what an erasure request empties | `identity` |
| `core` | users, categories, listings, bookings, trips, reviews, disputes | No | `accounts`, `catalogue`, `listings`, `booking` |
| `ledger` | chart of accounts, journal, top-ups | **Never** | `ledger` |
| `ops` | admin actions, outbound messages, external posts, job state | No | `ops` |

The split is not cosmetic. It is what makes the privilege model below expressible
and what makes "erase this person without destroying financial history"
a `DELETE` against one schema rather than a hunt.

## Rules the database enforces, not the application

Four invariants are load-bearing enough that application-level enforcement is
insufficient. A bug, a migration, a shell session or a future developer must not
be able to violate them.

### 1. The journal is append-only, enforced by privilege

`architecture.md` states it directly: *no application code path issues UPDATE or
DELETE on journal tables; enforce at the database privilege level, not by
convention.*

```sql
-- Application role: can read and insert. Cannot mutate history.
GRANT USAGE ON SCHEMA ledger TO ipelege_app;
GRANT SELECT, INSERT ON ledger.journal_transaction TO ipelege_app;
GRANT SELECT, INSERT ON ledger.journal_entry       TO ipelege_app;
REVOKE UPDATE, DELETE, TRUNCATE
    ON ledger.journal_transaction, ledger.journal_entry
  FROM ipelege_app;

-- Belt and braces: a trigger, so even a role misconfiguration fails loudly.
CREATE OR REPLACE FUNCTION ledger.reject_mutation() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'ledger.% is append-only (attempted %)',
    TG_TABLE_NAME, TG_OP USING ERRCODE = 'raise_exception';
END $$ LANGUAGE plpgsql;

CREATE TRIGGER journal_entry_immutable
  BEFORE UPDATE OR DELETE ON ledger.journal_entry
  FOR EACH ROW EXECUTE FUNCTION ledger.reject_mutation();

CREATE TRIGGER journal_transaction_immutable
  BEFORE UPDATE OR DELETE ON ledger.journal_transaction
  FOR EACH ROW EXECUTE FUNCTION ledger.reject_mutation();
```

Consequence for Django: `JournalEntry` and `JournalTransaction` models must
override `save()` to refuse updates and `delete()` to raise, so the failure
surfaces in Python rather than as a database exception mid-request. The
migrations that create these grants and triggers are `RunSQL` with an explicit
`reverse_sql`.

Corrections are **reversing entries**, never edits. There is no exception to
this, including for admin.

### 2. Every transaction balances to zero

Double-entry is meaningless if a transaction can be left lopsided. Enforced as a
deferred constraint trigger so entries can be inserted one at a time within a
transaction and checked at `COMMIT`:

```sql
CREATE OR REPLACE FUNCTION ledger.assert_balanced() RETURNS trigger AS $$
DECLARE net numeric(14,2);
BEGIN
  SELECT COALESCE(SUM(CASE WHEN direction = 'credit' THEN amount ELSE -amount END), 0)
    INTO net
    FROM ledger.journal_entry
   WHERE transaction_id = NEW.transaction_id;

  IF net <> 0 THEN
    RAISE EXCEPTION 'transaction % does not balance (net %)', NEW.transaction_id, net;
  END IF;
  RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER journal_entry_balances
  AFTER INSERT ON ledger.journal_entry
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION ledger.assert_balanced();
```

A transaction must also have at least two entries — a single-entry transaction
that happens to sum to zero is a zero-amount entry, which is a bug.

### 3. Idempotency on every money operation

`architecture.md` calls this *cheap now, near-impossible to backfill safely*.

```sql
ALTER TABLE ledger.journal_transaction
  ADD CONSTRAINT journal_transaction_idempotency_key_uniq UNIQUE (idempotency_key);
```

`idempotency_key` is `NOT NULL` and deterministic per real-world event, so a
retried Orange Money callback, a double-tapped top-up and a redelivered webhook
all collapse onto the same row:

| Event | Key |
|---|---|
| Top-up settlement | `topup:{topup_id}:settled` |
| Booking commission | `booking:{booking_id}:commission` |
| VAT on that commission | same transaction — VAT is an entry, not a transaction |
| Rental listing fee | `listing:{listing_id}:fee:{vacancy_seq}` |
| Reversal | `reversal:{dispute_id}:{original_transaction_id}` |

The caller catches the unique violation and treats it as success. It **must
not** check-then-insert; that races.

### 4. One approved provider row per user per category

`PROVIDER_CATEGORY` accumulates history — a rejected application can be
resubmitted, a revoked one can be re-applied for — so a plain unique constraint
on `(user_id, category_id)` is wrong. What must be unique is the *live* row:

```sql
CREATE UNIQUE INDEX provider_category_one_live
    ON core.provider_category (user_id, category_id)
 WHERE status IN ('pending', 'more_info', 'approved');
```

This is the constraint that makes the verification matrix in
[design-system](design-system.md) coherent: one account can be approved for
movers, pending for rentals, rejected for plumbing and not-applied for beauty
simultaneously, but it cannot be pending for movers twice.

## Money

| Rule | |
|---|---|
| Type | `numeric(12,2)` — never `float`, never `double precision` |
| Currency | BWP only at launch. Column exists (`char(3) NOT NULL DEFAULT 'BWP'`) with a check constraint, so multi-currency is a data change not a migration. |
| Sign | Amounts are **always positive**. Direction lives in `journal_entry.direction`. A negative amount is a constraint violation, not a credit. |
| Rounding | Half-up to 2 decimal places, applied **once**, at the point the fee is computed. Never re-round a stored figure. |
| Display | Pula formatting is set explicitly in the client, not inherited from device locale. |

Django: `DecimalField(max_digits=12, decimal_places=2)`. Never `FloatField`.
Python's `Decimal` with `ROUND_HALF_UP` — set the context explicitly rather than
relying on the default `ROUND_HALF_EVEN`, which would round P0.125 to P0.12.

### Fee and VAT are two entries in one transaction

Per [design-deltas](design-deltas.md#2-money-figures-the-specs-left-unset), a
deduction is never a single bundled figure. A P120 ride at 8% commission and 14%
VAT:

| Account | Direction | Amount |
|---|---|---|
| `provider:{id}` | debit | 10.94 |
| `platform_revenue` | credit | 9.60 |
| `vat_payable` | credit | 1.34 |

Three entries, one transaction, sums to zero. The commission rate is read from
`core.category.commission_rate` **at booking time** and copied onto
`core.booking.commission_rate` — a later rate change must not retroactively
alter what was owed.

The VAT rate lives in a `ledger.tax_rate` table with `effective_from` /
`effective_to`, not a constant. Tax rates change, and a historical transaction
must remain reconstructable at the rate that applied on its date.

### Balances are derived

`Balance` is not a column. It is:

```sql
CREATE VIEW ledger.account_balance AS
SELECT account_id,
       SUM(CASE WHEN direction = 'credit' THEN amount ELSE -amount END) AS balance
  FROM ledger.journal_entry
 GROUP BY account_id;
```

For read speed, maintain `ledger.account_balance_cache (account_id, balance,
last_entry_id, updated_at)` updated by an `AFTER INSERT` trigger on
`journal_entry`. It is a cache: a nightly job recomputes from the journal and
alerts on drift. **Never** read the cache for an authorisation decision that
gates a deduction — read the view, inside the transaction, `FOR UPDATE` on the
account row.

Negative balances are currently permitted on completion only
([data-model](data-model.md) open item). Until that is decided, the check is a
partial constraint on the *cache*, not the journal — the journal must be able to
record what actually happened.

## Geospatial

| Column | Type | Index |
|---|---|---|
| `core.service_area.centre_point` | `geography(Point, 4326)` | GiST |
| `core.service_area.boundary` | `geography(Polygon, 4326)`, nullable | GiST |
| `core.booking.location` | `geography(Point, 4326)`, nullable | GiST |
| `core.trip.pickup`, `.destination` | `geography(Point, 4326)` | GiST |
| `core.trip_location.point` | `geography(Point, 4326)` | GiST, per-partition |

`geography` not `geometry`: distances come out in metres without a projection
step, and Botswana spans two UTM zones, so there is no single convenient
projected SRID.

A service area is **either** a centre point plus `radius_m` **or** a polygon,
never both and never neither:

```sql
ALTER TABLE core.service_area ADD CONSTRAINT service_area_shape_xor CHECK (
  (centre_point IS NOT NULL AND radius_m IS NOT NULL AND boundary IS NULL)
  OR
  (boundary IS NOT NULL AND centre_point IS NULL AND radius_m IS NULL)
);
```

Driver proximity for dispatch (FR-3.10) does **not** query `trip_location` —
live positions live in Redis. PostGIS handles the static question ("which
listings cover this point"), Redis handles the moving one.

### `trip_location` is partitioned

Highest-volume table in the system by an order of magnitude, with the shortest
retention. Range-partition by `recorded_at`, monthly:

```sql
CREATE TABLE core.trip_location (
  id          bigserial,
  trip_id     uuid NOT NULL,
  point       geography(Point, 4326) NOT NULL,
  recorded_at timestamptz NOT NULL,
  PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);
```

Retention is enforced by `DROP PARTITION`, not `DELETE`. This matters: DPA
storage limitation has to be demonstrable, and dropping a partition is a fact
you can point at. Partition creation and drop run from a scheduled job with the
retention window in one named setting.

## Indexes

Beyond primary keys and the constraints above:

| Table | Index | For |
|---|---|---|
| `core.user` | `unique (phone)` | phone is the identity |
| `core.listing` | `(provider_category_id, status)` | provider's listing tab |
| `core.listing` | `(category_id, status, published_at desc)` where `status='published'` | category browse |
| `core.booking` | `(customer_id, state, created_at desc)` | consumer bookings tab |
| `core.booking` | `(provider_id, state, created_at desc)` | provider requests tab |
| `core.booking` | `(state, expires_at)` where state = `'REQUESTED'` | the expiry sweeper |
| `core.booking_event` | `(booking_id, occurred_at)` | dispute reconstruction |
| `ledger.journal_entry` | `(account_id, id)` | balance derivation |
| `ledger.journal_entry` | `(transaction_id)` | the balance trigger |
| `ledger.topup` | `(status, initiated_at)` where status in `('pending','unmatched')` | reconciliation queue |
| `identity.verification_document` | `(retention_until)` where `retention_until is not null` | retention sweeper |
| `ops.external_post` | `(consent_record_id)` | consent-withdrawal takedown |
| `ops.outbound_message` | `(user_id, sent_at desc)` | per-user message history |

The two partial booking indexes carry the separation the design insists on —
*what you book as a customer never appears in your provider inbox*. They are
different indexes because they are different queries, not one index with a
filter bolted on.

## The event outbox — how a state change reaches the phone

[admin](admin.md#the-adminapp-loop) establishes that almost every back-office
action exists to unblock someone waiting in the app. That relationship has to
exist in the schema, or it becomes a `send_push()` call inlined in an admin view
— which works exactly until the same transition happens through the API, a
management command or the expiry sweeper, and silently notifies nobody.

`data-model.md` had no table for this. It needs three.

### `ops.domain_event` — transactional outbox

```sql
CREATE TABLE ops.domain_event (
  id             bigserial PRIMARY KEY,
  event_type     text        NOT NULL,      -- 'provider_category.approved'
  aggregate_type text        NOT NULL,      -- 'provider_category'
  aggregate_id   uuid        NOT NULL,
  actor_id       uuid        NULL,          -- admin, user, or NULL for system
  admin_action_id uuid       NULL REFERENCES ops.admin_action(id),
  payload        jsonb       NOT NULL,
  occurred_at    timestamptz NOT NULL DEFAULT now(),
  processed_at   timestamptz NULL,
  attempts       smallint    NOT NULL DEFAULT 0,
  last_error     text        NULL
);

CREATE INDEX domain_event_unprocessed
    ON ops.domain_event (occurred_at)
 WHERE processed_at IS NULL;
```

**The event row is written in the same transaction as the state change it
describes.** That is the entire point, and it is why this is a table and not a
message queue: if the approval commits, the event commits; if the approval rolls
back, so does the event. There is no window in which a provider is approved and
nothing was emitted, and none in which a notification claims an approval that
was rolled back.

A relay worker polls the partial index, dispatches, and stamps `processed_at`.
Dispatch is **at-least-once** — the relay can crash after sending and before
stamping — so every consumer must be idempotent. For notifications that is
cheap: `ops.outbound_message` carries a unique constraint on
`(domain_event_id, channel_id, user_id)`.

`admin_action_id` is the join that makes the interconnection queryable in one
direction — *what did this admin decision cause* — and the reverse, *why did
this provider get this notification*, which is the question support actually
asks.

Events are **append-only**, same as the journal, though without the privilege
machinery: `processed_at`, `attempts` and `last_error` are relay bookkeeping and
are the only mutable columns.

### `ops.device` — where a push can land

```sql
CREATE TABLE ops.device (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES core."user"(id) ON DELETE CASCADE,
  push_token    text NOT NULL,
  platform      text NOT NULL CHECK (platform IN ('android','ios')),
  biometric_enrolled boolean NOT NULL DEFAULT false,
  app_version   text NOT NULL,
  last_seen_at  timestamptz NOT NULL,
  revoked_at    timestamptz NULL
);

CREATE UNIQUE INDEX device_push_token_live
    ON ops.device (push_token) WHERE revoked_at IS NULL;
```

`biometric_enrolled` is per device, not per account — the design requires that
biometrics be re-enabled after a device change and that a new device always gets
an SMS code. Storing it on the user would silently skip that.

This is also the table Settings → Security lists sessions from, and the one
"end this session" writes `revoked_at` to.

### `ops.outbound_message` gains a provenance column

Already specified in [data-model](data-model.md). One addition:

```sql
ALTER TABLE ops.outbound_message
  ADD COLUMN domain_event_id bigint NULL REFERENCES ops.domain_event(id),
  ADD CONSTRAINT outbound_message_once_per_event
      UNIQUE (domain_event_id, channel_id, user_id);
```

The unique constraint is what makes at-least-once relay delivery safe. It is the
same technique as `journal_transaction.idempotency_key`, for the same reason,
and it should be recognisable as such.

### What must emit an event

Non-negotiable, because each has a counterpart screen in the app:

| Event | Emitted by | App consequence |
|---|---|---|
| `provider_category.approved` / `.rejected` / `.more_info` / `.revoked` | verification service | Chip state, mode-switch availability, listing rights |
| `topup.settled` | ledger posting | Balance moves, `motion.count` |
| `reversal.confirmed` / `.declined` | ledger posting | Sequenced: rows land, then balance |
| `booking.state_changed` | booking service | Progress bar, chip, action row |
| `dispute.resolved` | dispute service | Both parties |
| `listing.deactivated` | revocation cascade | Listing tab |

Emission belongs to the **service function**, never to the admin view, the
serializer or a Django signal. Signals are tempting here and wrong: they fire on
`save()`, which means a data migration or a fixture load emits production
notifications.

## Retention and erasure

### The user split — auth versus identity

Phase 0 registration collects **first name, surname, email, password and
phone**, which is more personal data than the specification's phone-only model
([components](components.md#auth--adopt-and-phase-it)). Django needs `email`
and `password` on the auth model for authentication to function; everything
else is separable, and is separated.

| Table | Columns | Erasable |
|---|---|---|
| `core.user` — auth anchor | `id`, `email` (USERNAME_FIELD), `password`, `phone`, `phone_hash`, `phone_verified_at`, `status`, `is_staff` | Overwritten, not dropped |
| `identity.user_profile` | `first_name`, `surname`, `photo_ref`, `id_number` | Emptied |

**Define the custom user model in the first migration.** Changing Django's user
model after tables exist ranges from painful to impossible, and this is the
single most expensive thing in this document to defer.

`phone` carries a unique constraint **from the start, even while unverified**.
The "one phone, one account" rule cannot be *verified* until phase 1, but it can
be *enforced* — and enforcing it now turns a future migration conflict into a
registration-time error today.

```sql
ALTER TABLE core."user" ADD CONSTRAINT user_phone_uniq UNIQUE (phone);
```

### What an erasure request does

Erasure is a **tracked request**, not an immediate delete — three cases cannot
complete on demand.

```sql
CREATE TABLE identity.erasure_request (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES core."user"(id),
  requested_at    timestamptz NOT NULL DEFAULT now(),
  status          text NOT NULL CHECK (status IN ('queued','blocked','completed')),
  blocking_reason text NULL,
  completed_at    timestamptz NULL,
  backups_clear_at timestamptz NULL   -- when the last backup holding them ages out
);
```

When it runs, in one transaction:

```sql
UPDATE identity.user_profile SET first_name = NULL, surname = NULL,
       photo_ref = NULL, id_number = NULL, erased_at = now()
 WHERE user_id = $1;
DELETE FROM identity.verification_document WHERE ...;  -- objects purged too
UPDATE core."user"
   SET email = 'erased-' || $1 || '@invalid',
       phone = NULL, phone_hash = NULL, status = 'erased'
 WHERE id = $1;
UPDATE core."user" SET password = '!';                  -- unusable, per Django
```

The email is **replaced rather than nulled** because Django requires a unique,
non-null `USERNAME_FIELD`; nulling it breaks the auth machinery.

`phone_hash` is dropped on erasure. Where "has this number registered before"
must survive, it is a keyed HMAC held against a secret **outside** the database,
never a plain digest — a plain SHA-256 of a Botswana mobile number is trivially
reversible by enumeration.

The ledger is untouched. It references `ledger_account.owner_ref`, the
pseudonymous account ID, never personal data — the separation
[compliance](compliance.md) requires. That only holds as long as **no name ever
reaches a ledger table**; the statutory-retention exception must not be allowed
to swallow the rule.

### The three cases that block erasure

| Case | Handling |
|---|---|
| **Open dispute or live booking** | `status = 'blocked'` with the reason. The app **says so** rather than silently doing nothing. |
| **Tax records** | Not blocking — VAT entries reference the pseudonymous account and survive lawfully. |
| **Backups** | Live data is erased immediately. `backups_clear_at` records when the last backup containing the person ages out of the stated retention window. Backups are for disaster recovery only, never ordinary access. |

The alternative to a backup window — replaying erasures against restores — is
more correct and much harder to operate. **Either is defensible; having no
answer is not.**

### Retention schedule

| Data | Retention | Mechanism |
|---|---|---|
| `trip_location` | **Open** — must be set before launch | partition drop |
| `verification_document` | Per document type, **open** | sweeper on `retention_until` + object purge |
| `outbound_message` delivery records | **Open** | scheduled delete |
| `booking_event` | Life of the account | — |
| `journal_entry` | Statutory (7 years, to be confirmed) | never deleted |
| Backups | Stated window (30 days proposed) | rotation |

Several are open in [compliance](compliance.md). They are recorded here as
columns and jobs that exist and are configured, so that setting them is a config
change rather than a schema change.

### One settings block, with an assertion

Retention periods and the dispute window are **one decision, not several**, and
the relationship between two of them is a correctness constraint rather than a
preference. Put them together and let the application refuse to start if they
contradict:

```python
# settings/retention.py
DISPUTE_WINDOW_DAYS        = 14      # proposed — undecided
TRIP_TRAIL_RETENTION_DAYS  = 30      # proposed — undecided
BACKUP_RETENTION_DAYS      = 30      # proposed — undecided
KYC_RETENTION_DAYS         = None    # per document type — undecided
OUTBOUND_MESSAGE_RETENTION_DAYS = None   # undecided

assert DISPUTE_WINDOW_DAYS < TRIP_TRAIL_RETENTION_DAYS, (
    "Evidence would be deleted while a dispute could still be raised."
)
```

The numbers are placeholders. **The assertion is not** — it makes the one
contradiction that matters impossible to deploy, and it forces whoever changes
one value to think about the other.

### Legal hold

A retention sweeper that deletes evidence in an open case is a defect with legal
consequences, and it is the default behaviour of a naive sweeper. Every sweeper
checks the hold before deleting:

```sql
CREATE TABLE ops.legal_hold (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_type text NOT NULL,          -- 'booking' | 'trip' | 'user'
  subject_id   uuid NOT NULL,
  reason       text NOT NULL,          -- 'dispute' | 'reversal' | 'erasure_review'
  placed_at    timestamptz NOT NULL DEFAULT now(),
  released_at  timestamptz NULL
);

CREATE INDEX legal_hold_active
    ON ops.legal_hold (subject_type, subject_id) WHERE released_at IS NULL;
```

Holds are placed when a dispute or reversal is raised, and released when it
resolves. **Placing the hold is part of raising the dispute**, in the same
transaction — not a follow-up job that can fail.

## Redis

Not a cache in front of PostgreSQL. It holds exactly the state that is
high-write, short-lived and does not need durability:

| Key | Type | TTL | Purpose |
|---|---|---|---|
| `drv:pos` | `GEO` | — | live driver positions; `GEOSEARCH` for dispatch |
| `drv:last:{driver_id}` | string | 120s | staleness — a driver absent from this is not dispatchable |
| `sess:{token_hash}` | hash | access-token life | session lookup |
| `otp:{phone_hash}` | string | 5 min | OTP challenge + attempt counter |
| `rl:{scope}:{key}` | string | varies | rate limiting, OTP send in particular |
| `lock:{resource}` | string | 30s | short advisory locks for external-call fan-out |

**Nothing in Redis is a source of truth.** A full Redis flush must degrade the
product (no live tracking, everyone re-authenticates) and lose no money, no
booking and no document. Trip positions are written through to
`core.trip_location` on a batched interval; Redis is the read path, Postgres is
the record.

## Object storage

S3-compatible, encrypted at rest, **private** — no public bucket, no public
object, ever. Access is by short-lived presigned URL only, and every issuance is
written to `ops.admin_action` or an equivalent access log (NFR-8).

```
kyc/{user_id}/{provider_category_id}/{document_type}/{uuid}.{ext}   SSE, access-logged
listing/{listing_id}/{uuid}.{ext}                                   resized variants alongside
profile/{user_id}/{uuid}.{ext}
```

The database stores `storage_ref` only — never a URL, never a signed URL. A
stored signed URL is a stored credential with an expiry nobody is tracking.

KYC objects are deleted alongside the row on erasure and on retention expiry.
Both paths are the same code path, called from different triggers.

## Migrations

- **Django migrations are the only way schema changes reach any environment.**
  No manual DDL, including in development.
- Triggers, grants, views and partition management are `RunSQL` migrations with
  explicit `reverse_sql`. A migration that cannot be reversed is written as two
  migrations, one of which is documented as forward-only.
- Every migration must be safe to apply against a live database: no
  `ALTER TABLE ... ADD COLUMN NOT NULL` without a default, no index build
  without `CONCURRENTLY` (`AddIndexConcurrently`, and the migration marked
  `atomic = False`), no rewriting type change on a large table.
- Data migrations are separate from schema migrations, always.
- The ledger schema is **additive only** after first production write. Changing
  the shape of a journal table is not a migration, it is a new table plus a
  view.

## Connections, isolation, timeouts

| Setting | Value | Why |
|---|---|---|
| Isolation | `READ COMMITTED` (Postgres default) | Correct given the explicit `SELECT … FOR UPDATE` on ledger accounts |
| Pooler | PgBouncer, transaction pooling | Django's `CONN_MAX_AGE` alone will not survive worker counts |
| `statement_timeout` | 10s web, 0 for the migration and reporting roles | A slow query must fail, not queue |
| `idle_in_transaction_session_timeout` | 30s | An abandoned transaction holds ledger row locks |
| `lock_timeout` | 5s | Fail fast rather than pile up behind a migration |

Transaction-pooling mode means no session-level state: no `SET` outside a
transaction, no server-side cursors, no `LISTEN`/`NOTIFY` from the web role. The
async worker role connects directly, not through the pooler.

## Residency, backup, recovery

[compliance](compliance.md) requires a copy of personal data to remain in
Botswana for the duration of processing, and
[architecture](architecture.md) ranks the options. **That decision is still
open, and it constrains this layer more than any other.** What is fixed
regardless of the outcome:

- The `identity` schema is the residency-relevant one. If a topology ever splits
  storage across jurisdictions, that schema is the piece that must stay local —
  which is a second reason for the schema separation above.
- Backups inherit the residency requirement. An off-site backup in a foreign
  region is a transfer of personal data.
- Encrypted at rest and in transit, everywhere, including backups.
- PITR via WAL archiving. RPO and RTO targets are **not set** and should be,
  before launch.
- Restore is tested on a schedule. An untested backup is not a backup.

## Local development

`docker-compose` with `postgis/postgis:16-3.4`, `redis:7-alpine` and `minio`.
Seed fixtures load the nine categories and their requirements from
[design-deltas](design-deltas.md#1-nine-categories-not-six), a chart of accounts,
and the current VAT rate — the same fixtures CI uses, so "works on my machine"
and "works in CI" mean the same schema and the same reference data.

Tests run against real PostGIS. Not SQLite, not a mock: half of what this
document specifies — partial unique indexes, deferred constraint triggers,
privilege revocation, geography types — does not exist in SQLite, so a suite
that passes there proves nothing about the invariants that matter.

## Open

Carried from [data-model](data-model.md) and [compliance](compliance.md), listed
here because each one is a schema decision:

- ~~`LEDGER_ACCOUNT` — one per provider, or one per provider per category?~~
  **Resolved 2026-08-19: one per provider.** A provider holds a single wallet
  across every category — `owner_type = provider`, `owner_ref = provider_id`,
  no category component in the key. Corroborated by [data-model](data-model.md)
  (`USER ||--|| LEDGER_ACCOUNT`, a 1:1) and the design canvas ("one wallet",
  its stated load-bearing decision). Per-category *reporting*, if ever wanted,
  rides on `JOURNAL_TRANSACTION`, not on splitting the account. Full flow in
  [wallet](wallet.md).
- Are negative balances permitted, and in which states?
- Retention period for `TRIP_LOCATION` — sets the partition drop window.
- Retention schedule per KYC document type.
- Retention for `OUTBOUND_MESSAGE` delivery records.
- Statutory retention period for journal entries — confirm the 7 years.
- `EXTERNAL_POST` deletion on consent withdrawal: synchronous or queued?
- Hosting and residency topology.
- RPO / RTO targets.
