# Back office — interface design

The desktop half of the product, extracted from the Claude Design canvas
[`design/ipelege-admin-back-office.dc.html`](../design/ipelege-admin-back-office.dc.html)
on 2026-08-20. That canvas came through the import **complete** (171 KB, under
the read cap), so unlike the mobile one this document has no gaps.

This is the *interface* spec. The behaviour it renders lives in
[`admin.md`](admin.md) (queues, permissions, the honest rule),
[`cancellation.md#admin-surface`](cancellation.md) (evidence classes and
decision rules) and [`database.md`](database.md) (the append-only journal).
Where this file and those disagree, they are recorded in
[`design-deltas.md`](design-deltas.md).

## What this surface is

Decided 2026-08-17: **Django admin inside the same modular monolith, on
`/staff/*`.** Not a bespoke web app, and explicitly not Flutter Web. The
framework supplies the furniture, so the design work is density, queue framing,
and the shape of a decision.

Three standing principles:

- **Dense reading, not a canvas.** Back-office work is tabular reading,
  keyboard-driven queues, document inspection and audited writes.
  Server-rendered HTML gives text selection, find-in-page and printing for
  free; a canvas renderer does none of them well.
- **One domain layer, two entry points.** Every admin write calls the same
  service function the API calls. An admin approving a category and an
  automatic approval must produce byte-identical state transitions and audit
  rows.
- **The rule that keeps it honest.** *No admin surface may write to a field
  where a state transition exists for it.* Status is read-only text; the
  transitions are named actions with a reason. A dropdown is an unaudited
  second implementation of the state machine.

## Tokens — deliberately not the app's

The phone optimises for one thumb on a 360 dp screen. This surface optimises for
a reviewer with a keyboard, a 1440 px window and forty documents to get through
before lunch. **Almost every mobile token is wrong here**, so do not import
`app/lib/theme` values into the admin stylesheet.

| Token | Value | Why it differs from the app |
|---|---|---|
| Body text | 13 px / 1.45 | Read at 60 cm on a monitor, not at arm's length in sunlight |
| Table row height | 36 px | ~20 rows visible without scrolling. Mobile's 48 dp target does not apply to a mouse |
| Identifiers, money, time | IBM Plex Mono | Tabular figures align down a column, so a wrong digit is visible. Pula and 24-hour times set explicitly, **never** from device locale |
| Surfaces | 1 px borders | No shadows, no lifted cards. Elevation is a touch affordance; here it only adds noise between columns |
| Radius | 4 / 8 px | The app's 13–26 px radii waste horizontal space and soften data that should read as data |
| Colour | status only | Brand blue in the header and on links. Inside the table, colour means state or age and nothing else |
| Motion | none | Pages are server-rendered and full-page. Nothing animates except a spinner on a submit genuinely in flight |

## Rules every queue screen follows

- **Age is a column, not a sort option.** Every queue row carries how long the
  person on the other end has been waiting, coloured against the SLA.
- **One decision per screen.** The reviewer reads evidence and answers one
  question. Anything unrelated is not on the page.
- **A refusal states its basis.** Reject, more-info and decline all require
  typed reason text, because that text is shown to the person verbatim.
- **Every screen names the consequence on the phone.** If a reviewer cannot see
  what the provider will see, they cannot judge whether the copy is honest.
- **No bulk approve. Ever.** Bulk-approving identity verification is the single
  action most likely to destroy the thing the product sells.
- **Evidence is read-only, including for superusers.** An editable record is not
  evidence.

### Keyboard map

A reviewer working a queue of forty should never need the mouse to move between
items.

| Key | Action |
|---|---|
| `j` / `k` | Next, previous row |
| `Enter` | Open |
| `/` | Search |
| `g` then `d` | Document viewer |
| `Esc` | Close — **never** submit |

## Screens

### A0 · Staff sign-in — `/staff/login/`

Named individuals only, mandatory 2FA enforced by the framework rather than by
policy, and the whole path IP-restricted at the load balancer before this page
is reached. No self-service registration, no shared accounts.

- **Two steps, not one form with an extra box.** Password and code are separate
  posts, so a leaked password alone reveals nothing about whether the account
  exists.
- **No "remember this device."** Convenience here is a permanent bypass of the
  second factor. Sessions are short (20 min idle) and re-authentication is
  cheap.
- **Recovery goes through a person.** An email reset on an account that can
  approve identity documents is a weaker path than the front door, so it does
  not exist.
- Rejecting, declining or deleting anything asks for the password again
  regardless of session age.

### A0b · Staff accounts and roles — `/staff/auth/user/add/`

Every action writes an `ADMIN_ACTION` row naming an actor, so the actor has to
be a real person. The account is created **inactive**; it becomes usable once
the person opens a single-use 24-hour invite link, sets their own password and
enrols an authenticator in the same sitting. You never see or set their
password.

Work email must be an individual mailbox — role addresses (`admin@`, `ops@`) are
rejected. Phone is for reaching a locked-out reviewer, **never** as a second
factor. Leavers are deactivated, never deleted: their audit rows have to keep
pointing at a real person.

**The role table is the screen.** Roles are groups of permissions, not
free-form checkboxes.

| Capability | Reviewer | Finance | Growth | Superuser |
|---|:--:|:--:|:--:|:--:|
| Approve / reject / request info on verification | ✓ | — | — | ✓ |
| View identity documents · each view logged | ✓ | — | — | ✓ |
| Match or refund an unmatched deposit | — | ✓ | — | ✓ |
| Confirm or decline a reversal | — | ✓ | — | ✓ |
| Resolve a dispute | ✓ | ✓ | — | ✓ |
| Read the journal and account history | ✓ | ✓ | — | ✓ |
| Generate the VAT return figures for BURS | — | ✓ | — | ✓ |
| Post to groups and log what was posted | — | — | ✓ | ✓ |
| Create or deactivate staff accounts | — | — | — | ✓ |
| **Edit anything the ledger owns** | — | — | — | **—** |

The last row is not an omission. **No role, superuser included, may update or
delete a ledger row** — corrections are reversing entries, and the *database
privilege* enforces that rather than the interface. Showing the impossible row
teaches the model in one line.

Separation of duties is the default: a reviewer who approves a provider cannot
then match that provider's deposit. One person holding both is a superuser
decision with a reason attached.

### A1 · Queue board — `/staff/`

Django's app index lists models, and a model list does not tell anyone what to
do today. The landing page is replaced by **six queues**, each with its count,
its oldest item, and whether it is inside its SLA. The model tree stays one
click away for the rare direct lookup.

| Queue | Source | Note |
|---|---|---|
| Verification pending | `PROVIDER_CATEGORY` · pending, more_info | Oldest measured against the 48-hour window the app promises |
| Unmatched deposits | `TOPUP` · unmatched | A provider paid and the balance has not moved — the failure most likely to lose them permanently |
| Reversals under review | `REVERSAL` · under_review | Most cases must never reach a human; this is the flagged remainder |
| Disputes open | — | Quality disputes after completion. The platform never handled the payment, so its position is limited and the copy says so |
| Reconciliation mismatches | 06:00 scheduled run | Journal totals against the payment provider, to the thebe |
| Posts ready for groups | — | Growth surface. Posting happens outside the system boundary; what was posted where is logged |

Above the queues, and **not counted alongside them**, sits a blocked-posts
alert: a post blocked by the composer indicates a bug in the composer, not a
moderation decision, so it alarms rather than waits.

Design notes worth keeping:

- **Counts sit next to ages.** A count alone invites working the easy items
  first. The oldest-item figure, coloured against the promised window, is what
  makes an aged verification impossible to ignore.
- **Session state is in the header** (2FA active, session ends HH:MM). Idle
  timeout is short and destructive actions re-authenticate, so the reviewer
  needs to see the clock before starting a long document review.

### A2 · Verification queue — `/staff/core/providercategory/`

A Django changelist with the framework's furniture kept — search, right-hand
filters, result count, action bar over a checkbox column. What is *designed* is
the column set, the age treatment, and the deliberate absence of an approve
action in the bulk menu.

Columns: **Applicant** (name, phone, application id) · **Category** ·
**Documents** · **Status** · **Waiting** (default sort, descending) · **City**.

Filters: by status (pending or more info / pending / more info / all), by
category (all nine, with trades and the small three grouped), by age (any / over
48 hours / over 7 days), by city.

- **One row is one application, not one person.** Verification is per category,
  so the same person appears once per category and each decision is taken on its
  own requirement set. Grouping by person would invite approving a plumber for
  tiling.
- **The bulk menu holds one safe action** — request more information. Approve
  and reject are per-application only, and the action bar *says so* rather than
  leaving it as an absence.
- **Documents shows a fraction, not a tick.** "2 of 3" tells the reviewer the
  case is incomplete before they open it — the difference between a 10-second
  triage and a wasted page load.

### A3 · Document review — `/staff/core/providercategory/<id>/review/`

The highest-frequency admin task and the most sensitive one.

Layout: applicant panel (read-only) · the category's own requirement list paired
row-by-row with what arrived · the document viewer · the decision panel.

- **Status is not editable on this form.** It changes only through the actions,
  which call `verification.approve()`, `reject()` or `request_more_info()` and
  write `ADMIN_ACTION`.
- **Requirement beside upload, not above it.** Each row pairs what the category
  demands with what arrived, and labels the mismatch (`MATCHES REQUIREMENT`,
  `BACK NOT SUPPLIED`). The reviewer never has to remember that plumbing needs
  three documents and beauty needs two.
- **Every document is served through a short-lived presigned URL** (300 s), and
  every view writes a `DOCUMENT_ACCESS` record — actor, doc id, timestamp, ttl.
  NFR-8 requires this; the page *tells the reviewer they are being logged*
  rather than letting them discover it in an audit later. Never a raw storage
  link in a template.
- **Downloads are not offered.** There is no legitimate reason for an Omang to
  leave this screen.
- **The phone preview is part of the form.** The reason text is product copy at
  that moment; showing it in the frame it lands in is what stops "insufficient
  docs" being sent to a person. Reason is required, 400 characters, shown
  verbatim.
- **Rejection re-authenticates before it commits.** Approving and requesting
  information do not.
- **Previous / next live in the breadcrumb bar** ("1 of 14"), so queue position
  travels with the record and a reviewer works fourteen applications without
  returning to the list.

### A4 · Reversal evidence view — `/staff/ledger/reversal/<id>/evidence/`

An adjudication based on what the two parties assert is a coin toss with extra
steps, so this is an **evidence view with a decision at the end**, not a pair of
buttons. Most reversals are decided by rule and never appear here; what arrives
is the flagged remainder.

Sections, in this order:

1. **Amount at stake** — commission plus its VAT, stated as both reversing.
2. **What the rules concluded, before what the parties said.** A banner naming
   which rule routed this to a human and which rule *would* have decided it
   otherwise. That is the difference between adjudicating and guessing.
3. **Timeline** (`BOOKING_EVENT`, server timestamps, append-only) with an
   **evidence class on every row** — `HARD` / `SOFT` / `SUSPECT` / `ASSERTION`.
   A reviewer can then see at a glance that the two loudest items on the page
   are assertions carrying no weight on their own.
4. **Position, accuracy drawn to scale.** The GPS radius is drawn honestly — a
   fix with a 180 m radius in a yard-address neighbourhood cannot place a
   vehicle at a specific gate, and a circle drawn to scale is what stops a
   reviewer over-reading it. **Missing instrumentation is stated on the map**
   ("no trip trail — movers not yet instrumented") rather than shown as an empty
   map implying no movement.
5. **Computed server-side** — distance at attestation, accuracy radius, wait
   before the claim, mock-location flag, whether customer position exists.
6. **Flags** — including non-adverse ones. Poor coverage outside the two cities
   is the normal case and is labelled as not adverse; provider claim rate is
   shown against the category median.
7. **The decision.** Confirm posts the reversing entries **first, then** the
   balance moves — that is the order the events happened in. Decline moves
   nothing and leaves the row on the ledger with the reason attached. Basis is
   required, 600 characters, shown verbatim, and must be specific rather than
   "reversal declined".
8. **Escalation.** The app shows the evidence relied on and a route to a second
   look. An automated decline that cannot be contested is the pattern that
   generates complaints to a regulator. *Whether a declined reversal can be
   contested is still an open policy question* — the data model keeps the door
   open.

### A5 · VAT and the tax period — `/staff/ledger/taxperiod/<period>/`

**VAT is 14% on the Ipelege commission and on nothing else.** The platform never
touches the customer's payment, so the fare and the job price carry no VAT here.
That money is owed to **BURS**, so this screen produces a filing figure that can
be defended: derived from the append-only journal, reconciled against the
postings behind it, never typed in by hand.

Four headline figures: commission charged excl VAT · VAT at 14% · reversed in
period · **net VAT for the return**. Then a by-fee-type table with **VAT beside
its parent fee**, never as a lone number — the same nesting the provider sees in
the app, so the figure filed and the figure they were shown are visibly the same
arithmetic.

A reconciliation block (06:00 run) asserts: journal debits equal credits · VAT
rows without a parent fee = 0 · fees where VAT ≠ 14.00% = 0 · deposits matched
against the bank statement.

Three things the screen states rather than assumes:

- **Undecided reversals are shown as exposure**, with the amount that could
  still move, *before* the export button. A return filed over a moving figure
  produces a correction.
- **Period length and filing deadline are configuration.** Monthly is assumed
  and **not yet confirmed with BURS**.
- **Whether the rental listing fee is standard-rated** like commission needs
  confirming with the accountant rather than assuming.

Nothing on the page is editable. A wrong figure is corrected by a reversing
entry, which changes the number on the next load.

### A6 · Key statistics — `/staff/metrics/`

One screen for "how is Ipelege doing", including the M5 measure from
[`project-plan.md`](project-plan.md) that currently has nowhere to be read:
**supply per category per city**.

Headline pairs — bookings requested / completed (with %) · commission earned
excl VAT · VAT collected · credit topped up (with the unmatched figure beside
it) · providers earning of verified.

- **Every figure names its own denominator.** "1 402 completed" means nothing
  without "1 883 requested", so the pairs travel together and no card carries a
  bare count.
- **Thin categories are labelled, not averaged.** Standing (`HEALTHY` / `THIN` /
  `CRITICAL`) is set **per category per city**, because that is the unit a
  customer experiences. A healthy platform average is no comfort to someone in
  Francistown looking for hire.
- A request-to-completion funnel: requested → accepted → in progress →
  completed → rated. The share that *never get an answer* — declined, expired,
  or cancelled before acceptance — is the figure that says supply is too thin,
  not the completion count.
- Provider health: approvals this week, waiting over 48 hours, **new providers
  who got a first job** (the number that says the zero-ratings problem is not
  killing supply — watched weekly, not monthly), providers blocked by an empty
  balance, no-show claims raised.
- **VAT appears here too**, beside the revenue it came from, because the person
  reading weekly performance is often the person who has to file.

### A7 · Responsive behaviour

The back office is a web page. It gets opened on a laptop at 1280, on a borrowed
1024 screen, and on a phone by whoever is on call when a deposit has not landed.
**Nothing is fixed-width**; below 1024 the same markup reflows rather than
switching to a separate mobile view.

| Width | What changes | Detail |
|---|---|---|
| ≥1440 | Full layout | Table, filter rail and decision panel all on screen. The intended working width |
| 1024–1439 | Rail collapses | Filter rail becomes a row of dropdowns above the table. Decision panel keeps its place |
| 768–1023 | Single column | Panels stack in reading order: evidence first, decision last. Secondary columns (city, application id) drop out |
| <768 | Cards, not rows | Each queue row becomes a card carrying applicant, category, age and one action. Document review keeps the viewer full-width with the reason field above the buttons |

Three rules hold at **every** width:

1. The age column never drops.
2. The reason field is never below the fold while a refusal button is on screen.
3. A table never scrolls sideways to hide a decision.

Under 768 the checkbox column and the bulk action bar go with it. Batch work
needs a real screen, and a one-handed approval of an identity document is not a
feature worth having.

## Status

**Design only.** There is no Django project in this repository yet, so none of
the above is built. The data it renders — `PROVIDER_CATEGORY`, `TOPUP`,
`REVERSAL`, `BOOKING_EVENT`, `ADMIN_ACTION`, `DOCUMENT_ACCESS`, the journal —
is modelled in [`data-model.md`](data-model.md) and [`database.md`](database.md)
but not migrated. See [`open-questions.md`](open-questions.md) for what still
blocks the schema.
