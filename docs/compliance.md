# Regulatory & compliance constraints

> **This is not legal advice.** Both items below need a Botswana-qualified
> lawyer before build decisions are locked. They are here because they are
> *architectural* constraints, not paperwork — getting them wrong means
> rebuilding, or not launching.
>
> **Item 1 is largely designed out already** — the platform never sits between
> customer and provider. What remains is a narrow, answerable question about the
> provider balance, plus a set of design rules that must hold to keep it
> answerable.

---

## 1. Payments regulation — largely designed out, one residual question

### What the design already avoids

Two structural choices remove most of the regulatory surface, and they were
deliberate:

1. **The platform charges providers only** (CON-1)
2. **All customer↔provider payment happens outside the app** — cash or the
   parties' own mobile money

Together these mean the platform **never holds, transmits, or settles money
between two users.** No escrow, no float, no payouts, no settlement engine. The
activities that most clearly constitute payment services — money transmission,
holding customer funds, executing transfers on behalf of others — are simply not
present.

That is the right architecture and it should not be traded away for
convenience later. It is also why there is no settlement component in
[architecture](architecture.md).

### The one residual question

The Electronic Payment Services Regulations 2019 (Statutory Instrument No. 2)
cover issuance of e-money and **its deposit on payment accounts**, not only
transfers between parties. Operating an electronic payment service without a
Bank of Botswana licence is a criminal offence under Regulation 4(1).

So the remaining question is narrow but real: **when a provider deposits money
with the platform and holds a balance, is that balance a payment account?**

The answer turns on redeemability. Most regimes distinguish stored value —
which is e-money — from prepaid credit for the issuer's *own* services, which
generally is not. Ipelege's balance is intended to be the latter.

### Design rules that keep it that way

These are **binding constraints, not preferences.** Each one, if broken, moves
the balance toward looking like stored value:

| Rule | Why |
|---|---|
| **No cash-out, ever** — including on account closure | Redeemability is the defining feature of e-money |
| **No transfer between users** | Transferable value is a payment instrument |
| **Balance pays Ipelege fees only** — never a third party | Paying third parties is money transmission |
| **No customer-side balances at all** | Customers never fund an account |
| **Top-up amounts kept modest; no incentive to hold large balances** | Large float attracts prudential interest |
| **Don't call it a "wallet" in the product** | "Commission credit" or "advertising credit" describes what it is; "wallet" invites the wrong characterisation |

> **The rule most likely to be broken under pressure is the first one.** A
> provider who tops up P500, does two jobs, and quits will ask for their money
> back. Refusing is uncomfortable; refunding to cash is exactly the feature that
> could reclassify the product. Decide the policy now, in writing, and put it in
> the provider terms — not in the moment when someone is upset.

### What still needs counsel

The reasoning above is sound but it is not a legal opinion, and the penalty for
being wrong is criminal rather than civil. Get a Botswana-qualified lawyer to
confirm, specifically:

- [ ] Does non-redeemable, non-transferable prepaid credit for the platform's
      own services fall outside the EPS Regulations 2019?
- [ ] Does Botswana recognise a "limited network" or "own services" exclusion,
      and does this fit it?
- [ ] Any obligations under the Financial Intelligence Act 2022 arising from
      taking provider deposits, even outside EPS licensing?
- [ ] Does receiving EFT deposits into a company bank account for prepaid
      credit change the analysis?

This is a scoped question a lawyer can answer relatively quickly — not an open
research project. **Ask it before backend design freeze**, but it should no
longer be treated as a project-threatening unknown.

## 2. Data Protection Act 2024 — including a data residency requirement

The Data Protection Act 2024 (Act No. 18 of 2024) was assented to on 24 October
2024, published 29 October 2024, and came into force on **14 January 2025**,
repealing and re-enacting the 2018 Act. It broadly follows the GDPR approach.

Penalties are severe: fines up to **BWP 50 million or 4% of global annual
turnover**, whichever is higher, with imprisonment for certain offences —
reported prison terms range from three to twelve years for some violations.

### Requirements with architectural consequences

| Requirement | Consequence for Ipelege |
|---|---|
| **Data residency** — a copy of personal data must remain in Botswana for the duration of processing | **Hosting decision is constrained.** A single foreign cloud region is not sufficient on its own. Needs either local hosting or a replicated copy held in Botswana. Settle before choosing infrastructure. |
| **Consent as a central principle**; conditions for valid consent | Explicit, granular, withdrawable consent at signup and at each KYC step. Consent state must be stored and versioned, not assumed. |
| **Data minimisation, storage limitation, accuracy** | KYC documents cannot be kept indefinitely "just in case". Define a retention schedule per document type. |
| **DPIA for high-risk processing** | Live GPS tracking of riders and drivers is high-risk processing. A DPIA is likely required before launch. |
| **Data subject rights** — access, rectification, erasure, portability, objection | Build export and deletion as features, not manual admin tasks. Erasure conflicts with ledger immutability — see below. |
| **Breach notification** | Notification path to the Commission and affected users, with detection and logging to support it. |
| **DPO appointment** for large-scale or sensitive processing | Organisational, but plan for it. |

### The erasure vs. immutable-ledger conflict

Data subject erasure rights collide directly with the immutable financial ledger
in [data-model](data-model.md). Standard resolution: **separate identity from
transactions.** The ledger references a pseudonymous account ID; personal data
lives in a separate store that can be erased without destroying financial
history. Design this in from the start — retrofitting it is very expensive.

### What the handset itself holds

Recorded here because it is a processing decision, and because the next person
to add a field to it will not think of it as one.

As of 2026-08-21 the app stores a session on the device between launches —
`app/lib/core/session_store.dart`, in app-private storage under one key:

| Kept | Not kept |
|---|---|
| Name, phone number | Any OTP, sent or pending |
| Consent version agreed to | The code-attempt count |
| Which optional channels were agreed (SMS, WhatsApp) | Anything about a booking |
| Whether location was granted | Any KYC document or ledger figure |
| Whether biometric unlock was offered and enabled | Any token or credential |

Three things follow, and they are the rules for changing it:

1. **This is the same data the account screen shows on demand.** It is not
   special-category data, and it is what the session already needed to render.
   That is the justification, and it stops holding the moment something else is
   added.
2. **A KYC document must never be written here.** Half-finished uploads persist
   locally too, but under their own draft store with its own retention — see
   [design-system](design-system.md)'s state-restoration rules. Mixing them
   would put an unsubmitted Omang into a record that survives logout.
3. **A token does not belong here either.** When the Django session lands, where
   its credential is stored is a separate decision and needs this section
   revisited, not extended by default.

**Erasure:** signing out clears the record rather than blanking it, so the
device-side copy has no independent lifetime to account for.

**Biometrics are not in that table, and never will be.** Biometric unlock was
wired 2026-08-21 (`app/lib/core/biometrics.dart`). The prompt is the operating
system's own: the app asks the OS a yes/no question and receives a boolean.
**No fingerprint, face template or any derivative of one is read, transmitted
or stored by Ipelege**, which is what keeps this out of special-category
processing entirely. `USE_BIOMETRIC` is an install-time declaration, not a
runtime permission, and it grants access to the prompt rather than to the
sensor.

The rule that keeps it that way: **biometry unlocks, it never authenticates.**
A successful prompt reopens a session the device already held. It cannot create
one, so nothing in this app treats a biometric result as proof of identity —
which would be the point where it started to matter under the DPA.

### KYC has a local advantage

Botswana's national ID system already allows agents to verify customers and
conduct basic KYC — a foundation to build on rather than around. Worth
investigating before contracting a third-party verification vendor.

---

# What to look out for while building

The sections above are the law. This section is the working checklist — the
points where ordinary development decisions quietly become compliance
decisions. Most breaches here would not be malice; they would be a sensible
engineering choice made without noticing which rule it touched.

## The one-line test

> **Would this action still be defensible if the Data Protection Commission
> asked us to explain it, in writing, a year later?**

If the answer depends on nobody looking, stop. Two habits make this answerable
rather than aspirational: **write the reason down at the time** (which is why
`ADMIN_ACTION` and `BOOKING_EVENT` carry `reason` fields), and **make deletion a
job rather than a manual act.**

## Triggers — if you are doing this, check that

| If you are… | Then you must… | Where |
|---|---|---|
| Adding **any** field that identifies a person | Put it in the `identity` schema, not `core`, and confirm the erasure job clears it | [database](database.md#what-an-erasure-request-does) |
| Adding a field that stores **location** | Treat it as personal data. Set a retention period *before* merging. | [cancellation](cancellation.md#retention--the-real-tension) |
| Adding a **new consent purpose** | New `consent_type`, versioned, defaulting to **off**. Never widen an existing consent's meaning — that invalidates every prior grant. | [data-model](data-model.md) |
| Sending **anything** outbound | Read consent at action time, for that specific channel. No cross-channel fallback. | [dfd](dfd.md) |
| Adding a field to a **domain event payload** | Events are an outbox and are retained. Personal data in a payload is personal data you now store twice. Reference by ID. | [database](database.md#opsdomain_event--transactional-outbox) |
| Letting an admin **view a document** | Presigned, short-lived, and the view itself logged. Never a raw storage link. | [admin](admin.md#document-review) |
| Adding a **retention sweeper** | Make it check the legal hold first | [cancellation](cancellation.md#retention--the-real-tension) |
| Choosing **where something is hosted** | Ask whether personal data touches it. Map tiles do not; the `identity` schema does. | [architecture](architecture.md#split-by-data-sensitivity-not-by-service) |
| Adding **analytics or crash reporting** | Most SDKs exfiltrate device and location data by default, to servers abroad. This is a cross-border transfer nobody consented to. | — |
| Logging a request | Phone numbers and tokens must not land in application logs. Logs are rarely covered by the retention schedule and are frequently shipped off-box. | — |

## Traps introduced by decisions already made

Each of these is a live risk created by a choice recorded elsewhere in this
repo. They are listed so they are not rediscovered late.

### 1. Development hosting is outside Botswana

Oracle Always Free is **Johannesburg**; Contabo is **Lauterbourg, France**.
Neither satisfies residency.

**The rule while building: synthetic data only.** No real names, no real phone
numbers, no real ID documents, not even "just one, to test the KYC flow." The
moment a real person's document is uploaded to a foreign box, a cross-border
transfer has occurred and no amount of later migration undoes it.

Seed fixtures should make this easy — obviously fake names, `+267 71 000 0xx`
numbers reserved for testing, placeholder images. If a developer has to invent
test data by hand, they will eventually use their own.

### 2. Phase 0 auth collects more personal data than the spec intended

The specification's identity model was deliberately minimal — a phone number and
nothing else. Phase 0 adds **first name, surname, email and a password**
([components](components.md#auth--adopt-and-phase-it)).

That is a defensible product decision and a step away from **data
minimisation**. Consequences to handle rather than absorb:

- All four fields belong in `identity` and must be cleared by erasure
- Email brings password-reset tokens, which are credentials with their own
  expiry and logging concerns
- The privacy notice must describe what is collected **at the time it is
  collected** — so it needs writing for phase 0, not for the phone-only model
  that was specified

### 3. GPS evidence is high-risk processing, and it is expanding

[compliance](compliance.md) already flags live tracking as likely requiring a
**DPIA**. The [cancellation](cancellation.md) work expands the footprint
considerably:

- Arrival and completion attestations now capture **location for seven more
  categories**, not just rides
- Movers gains a full position trail
- Completion photos may incidentally capture people and property

**The DPIA must cover the evidence model, not just ride tracking**, and it
should be done before that code ships rather than before launch. The purpose is
defensible — adjudicating money disputes fairly — but "we collected it in case
of a dispute" is only lawful if the retention is bounded and the purpose is
stated up front.

### 4. Retention and evidence pull against each other

Adjudication needs the logs; storage limitation says delete them. Resolved by
[tiered retention plus a legal hold](cancellation.md#retention--the-real-tension),
but the **numbers are still unset**, and two of them are one decision:

> The dispute window must be **shorter** than full-trail retention. Set them
> together or evidence will be deleted before it is needed — which is both an
> operational failure and, in the other direction, a compliance failure if the
> fix is simply to keep everything forever.

### 5. Erasure has three hard cases

The ledger separation handles the main conflict. Three others do not fall out of
it automatically:

| Case | Handling |
|---|---|
| **Tax records** | VAT entries have a statutory retention period that overrides erasure. Lawful — but the ledger must reference the pseudonymous account, never the person, or the exception swallows the rule. |
| **Open dispute** | A person with an unresolved dispute cannot be erased mid-adjudication. The request is **queued**, and the app must say so. |
| **Backups** | An erasure that leaves the person in last night's dump is not an erasure. Either backups age out inside a stated window, or the erasure job replays against restores. **Decide which — this is the most commonly missed one.** |

### 6. "Wallet" is a compliance decision being made by the UI

The design calls the balance a **wallet**, against the binding constraint in
this document not to. That is recorded in
[design-deltas](design-deltas.md#3-wallet-balance-not-commission-credit) and it
is not settled. It belongs in the **same instruction to counsel** as the EPS
question — asking one without the other wastes the engagement.

## Designed-in mitigations — what to build now

Each trap above has a fix that is cheap today and expensive later. These are
implementation decisions, not policies, and they belong in the first commits.

### For trap 2 — auth collects more than intended

**Split the user at the model layer on day one.** Django needs `email` and
`password` on the auth model for authentication to work at all; everything else
goes elsewhere.

| Table | Fields | On erasure |
|---|---|---|
| `core.user` (auth anchor) | `id`, `email` (USERNAME_FIELD), `password`, `phone`, `phone_hash`, `status` | `email` → `erased-{uuid}@invalid`, password set unusable, `phone` nulled |
| `identity.user_profile` | `first_name`, `surname`, `photo`, `id_number` | Emptied |

The placeholder email exists because Django requires a unique, non-null
`USERNAME_FIELD` — nulling it breaks the auth machinery, so it is replaced
rather than removed. `phone_hash` (keyed HMAC, not plain digest) survives so
"has this number registered before" stays answerable
([database](database.md#what-an-erasure-request-does)).

**Define the custom user model in the very first migration.** Changing it later
is close to impossible in Django, and this is the single most costly thing on
this page to defer.

**Collect nothing beyond those fields.** No date of birth, no gender, no
address at signup. Each is a separate lawful-basis argument nobody wants to
make.

### For trap 3 — the evidence footprint

- **Two points, not a trail.** For the seven browse categories, capture location
  only at arrival and completion. A continuous trail is proportionate for a
  moving vehicle and not for a plumber standing in a yard.
- **State the purpose at the moment of capture.** The attestation screen says
  why the location is being taken and what it will be used for. Purpose
  limitation is much easier to defend when the user was told at the time.
- **Request location permission contextually**, not at app launch. The design
  already has this as a dedicated screen.
- **Stop writing `trip_location` on terminal state.** A trip that ends must stop
  producing points; a leaked writer is both a battery bug and a compliance one.
- **Store accuracy alongside every coordinate.** It bounds what the data can
  honestly be used to claim ([cancellation](cancellation.md#gps-is-evidence-not-proof)).

### For trap 4 — retention vs dispute window

**Make the contradiction impossible to ship.** Both values live in one settings
block with a startup assertion:

```python
# settings/retention.py
DISPUTE_WINDOW_DAYS      = 14
TRIP_TRAIL_RETENTION_DAYS = 30
KYC_RETENTION_DAYS       = None   # unset — must be decided
...
assert DISPUTE_WINDOW_DAYS < TRIP_TRAIL_RETENTION_DAYS, (
    "Evidence would be deleted while a dispute could still be raised."
)
```

The app **fails to boot** if someone changes one without the other. The values
above are placeholders pending the decision; the assertion is not.

Alongside it: **write the derived evidence summary at terminal state**
(start/end points, distance, duration, max distance from target) so the full
trail can be dropped on schedule without destroying adjudicability.

### For trap 5 — erasure's three hard cases

**Erasure is a tracked request, not an immediate delete:**

```
identity.erasure_request
  id, user_id, requested_at, status, blocking_reason, completed_at
  status: queued | blocked | completed
```

- **Open dispute or live booking** → `blocked`, with the reason, and the app
  says so rather than silently doing nothing. The design already requires this
  copy.
- **Tax records** survive because the ledger references the pseudonymous
  account, never the person. Nothing special to build — but it only holds if
  nobody ever adds a name to a ledger table.
- **Backups.** Pick the simple, defensible option: **a stated backup retention
  window** (30 days), documented, with backups used only for disaster recovery
  and never for ordinary access. The erasure is complete in live data
  immediately; the request records when the last backup containing the person
  ages out. The alternative — replaying erasures against restores — is more
  correct and much harder to operate. **Decide and write it down; the failure
  here is having no answer, not picking the simpler one.**

### For trap 6 — the "wallet" naming

**One constant, referenced everywhere.** The label appears across roughly
fifteen screens. If it is typed into each of them, changing it after counsel
advises is a redesign; if it is a single localisation key, it is a one-line
change.

```dart
// Not a string literal in fifteen widgets.
const balanceLabel = 'Wallet balance';   // pending compliance sign-off
```

This costs nothing now and buys the ability to comply immediately if the answer
comes back badly. Apply the same treatment to the accompanying disclaimer copy.

## Build-time gates

Cheap to enforce, expensive to retrofit. Each belongs in the definition of done
for the feature that introduces it:

- [ ] Every personal-data field is in `identity` and cleared by the erasure job
- [ ] Every location field has a stated retention period at merge time
- [ ] Every consent purpose is granular, versioned, and defaults to off
- [ ] Every outbound action reads consent at action time
- [ ] Every document access is logged
- [ ] Every retention sweeper checks the legal hold
- [ ] No personal data in domain event payloads, logs, or error reports
- [ ] No real personal data on non-resident infrastructure, ever
- [ ] Erasure and export are **features with tests**, not admin procedures
      ([test-strategy](test-strategy.md#compliance))
- [ ] The custom user model is defined in the **first** migration, split as
      described above
- [ ] `DISPUTE_WINDOW_DAYS < TRIP_TRAIL_RETENTION_DAYS` asserted at startup
- [ ] User-facing money labels are constants, not literals

## People and paperwork, not code

Easy to defer indefinitely because nothing breaks without them:

| Item | Status |
|---|---|
| **DPO appointment** | Planned for, not done. Required for large-scale or sensitive processing. |
| **Privacy notice** | Not written. Must reflect phase 0 auth, not the specified model. |
| **Provider terms**, incl. balance at closure | Not written. Named as the single change most likely to reclassify the product. |
| **DPIA** | Not started. Must cover the evidence model. |
| **Breach notification path** | No runbook. Needs a named person and a route to the Commission. |
| **Records of processing** | Not maintained. |
| **Registration with the Commission**, if required | Unconfirmed. |

---

## Open compliance questions

**For counsel — send as one instruction, not several:**

- [ ] Does non-redeemable commission credit fall outside EPS licensing? **Narrow question.**
- [ ] **Does calling it a "wallet" in the product change that answer?** The design
      reversed the naming rule above. Ask this *with* the question before it —
      asking one alone wastes the engagement. See
      [design-deltas](design-deltas.md#3-wallet-balance-not-commission-credit).
- [ ] Financial Intelligence Act 2022 obligations from taking provider deposits?
- [ ] Written refund/closure policy for unused balance — decide before launch, not in the moment.
- [ ] Is registration with the Data Protection Commission required, and by when?

**Residency and transfer:**

- [ ] Where will data be hosted to satisfy the residency requirement? Local
      capacity is confirmed to exist; what is missing is a price. See
      [architecture](architecture.md#two-viable-routes-for-production-both-giving-root).
- [ ] Do **backups** inherit residency? An off-site backup abroad is a transfer.
- [ ] Does a **foreign-hosted OSRM/tile server** raise any issue? It holds no
      personal data, but the reasoning should be written down once rather than
      re-argued.

**Data protection, in build order:**

- [ ] **DPIA** — required for GPS tracking, and now must also cover the
      [evidence and attestation model](cancellation.md), which extends location
      capture to seven more categories. Who conducts it?
- [ ] **Full-trail retention and the dispute window** — one decision, not two.
      The window must be shorter than the retention.
- [ ] Retention schedule per KYC document type
- [ ] Retention for `TRIP_LOCATION`, `OUTBOUND_MESSAGE`, `ADMIN_ACTION`, and
      application logs
- [ ] **Do erasures replay against backups, or do backups age out inside a
      stated window?** Most commonly missed erasure gap.
- [ ] Privacy notice written for the **phase 0 auth model** (name, surname,
      email, password, phone), which collects more than the specification's
      phone-only design — see [components](components.md#auth--adopt-and-phase-it)
- [ ] Can national ID verification be used directly, and under what terms?
- [ ] DPO appointment — required for large-scale or sensitive processing
- [ ] Breach notification runbook: named person, route to the Commission
