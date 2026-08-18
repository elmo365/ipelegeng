# Cancellation, no-show and evidence

The specification set had no cancellation policy, and
[booking](booking.md) calls the completion gap its largest. The design added a
[reversal state machine](system-flowcharts.md#reversal-state-machine) but left
the decision itself as "an admin adjudicates" — with nothing said about *what
they adjudicate on*.

This document closes that. It is written around one observation:

> A driver can cancel a ride the telemetry shows they completed. A plumber can
> claim a no-show at an address their phone never approached. **An adjudication
> based on what the two parties assert is not an adjudication — it is a coin
> toss with extra steps.**

Because the platform never touches the customer's money, the only thing at stake
in a cancellation is the **provider's fee and the credit behind it**. That makes
this narrower than a rideshare refund system, and it makes the evidence question
sharper: we are deciding whether a provider keeps or reclaims credit, on our own
records.

## What the comparable platforms actually do

| Platform | Rule | What it tells us |
|---|---|---|
| Uber | No cancellation fee if the driver **made no progress toward the pickup**, or was **5+ minutes late**. Arrival time derived from GPS. | Progress-toward-pickup is a *computed* test over the position trail, not a self-report. |
| Uber | Explicitly states GPS "does not always perfectly correspond to real world coordinates" | Even the largest operator hedges GPS accuracy in policy text. So must we. |
| Bolt | Rider has **5 minutes** from the scheduled start; waiting before the scheduled time is not compensated | The waiting clock starts at a defined moment, not at whenever the driver says they arrived. |
| Lyft | Pre-accept drivers ineligible for the fee if **more than 5 minutes late** | Eligibility is gated before the dispute, not argued after it. |
| Uber (fraud policy) | Named fraud patterns: accepting with no intention to complete, **forcing the passenger to cancel**, manipulating GPS with fake-location apps | "Forcing the other party to cancel" is the specific abuse our reversal flow would otherwise reward. |
| Field-service tooling | Completion proof = live photo + **server-set timestamp the technician cannot change** + GPS at capture | The timestamp must come from us. A device clock is an input the subject controls. |

Two findings matter more than the thresholds:

**Deactivation-by-fraud-determination is legally contested.** Broad, conclusory
findings without factual specificity are the central weakness drivers'
representatives attack in arbitration; the demand is to disclose the data and
the methodology behind the determination. Our equivalent is smaller in stakes
but identical in shape — so a declined reversal must state the basis, not just
the outcome.

**Trip logs and GPS get overwritten, and that destroys adjudication.** In
disputes, preservation letters exist precisely because this data disappears.
Our retention schedule has to account for the dispute window, which pulls
directly against DPA storage limitation. See
[Retention](#retention-the-real-tension) below.

## The evidence available is wildly uneven across the nine categories

This is the finding that shapes everything else. The [three journey
shapes](system-flowcharts.md#not-every-category-traverses-these-machines) have
almost nothing in common evidentially.

| Shape | Categories | Evidence available today | Adjudicable? |
|---|---|---|---|
| **Dispatch** | Rides | Continuous position trail, pickup and destination points, trip start/end, route polyline, distance, timestamps | **Yes, richly.** Almost everything Uber uses, we already collect. |
| **Browse & book** | Movers · Beauty · Plumbing · Electrical · Tiling · Catering · Hire | Booking state transitions and their timestamps. **That is all.** No position data, no arrival signal, no proof anyone met. | **No — this is the gap.** |
| **Pay-per-listing** | Property rentals | Listing publication and withdrawal timestamps | N/A — no booking, no commission, so no reversal of this kind. The only reversal is a listing fee for a listing withdrawn after publishing, which is a records question, not an evidence one. |

**Seven of the nine categories currently produce no evidence that a service
happened.** A booking that reaches `COMPLETED` proves only that two people
tapped buttons. If a mover later claims the customer was a no-show and asks for
their commission back, there is nothing to adjudicate on.

Movers is the sharpest case: it is the seeding priority, the largest fees, and
it has a vehicle travelling to a location — so it has the same evidential shape
as rides and none of the instrumentation.

## What has to be logged

Three additions. None is optional if reversals are to be decided rather than
guessed.

### 1. Arrival attestation, for every travel-involving booking

When a listing's `service_direction` is `provider_travels`, the provider marks
arrival in the app. That action captures:

| Field | Source | Notes |
|---|---|---|
| `attested_at` | **Server clock** | Never the device clock. The device clock is an input the subject controls. |
| `point` | Device GPS | With accuracy radius, not a bare coordinate |
| `accuracy_m` | Device GPS | An 800 m fix is not evidence of arrival |
| `is_mock` | `Location.isMock` (API 31+) / `isFromMockProvider` | Recorded, not enforced — see below |
| `distance_to_target_m` | Computed server-side | PostGIS, against the booking location |

The same at completion. Two points, two server timestamps, and the distance to
the agreed location is enough to answer "was this person ever there" for all
seven browse categories — which today cannot be answered at all.

Applies to `client_travels` listings in mirror image, capturing the customer's
arrival at the provider's location.

### 2. A position trail for movers, as for rides

Movers already involves a vehicle travelling to and from a location. Extend
`TRIP` and `TRIP_LOCATION` to cover movers bookings, not only rides. The tables
already exist; the change is that a movers booking may have a trip.

This is a scope increase and worth stating as one. The alternative is that the
category with the largest per-booking fee is the one we cannot adjudicate.

### 3. Completion evidence, where the work leaves a visible result

Plumbing, electrical, tiling and movers produce a visible outcome. A completion
photo with a **server-set** timestamp and the GPS at capture is standard field
service practice and cheap to add. Optional per category, configured on
`CATEGORY`, not hard-coded.

Not for beauty or catering, where photographing the result is intrusive and the
outcome is not a fixed object.

## Decision rules

The point of the rules below is that **most cases never reach a human.** An
adjudication queue that receives every cancellation is a queue that decides
nothing carefully.

### Evidence classes

| Class | Meaning | Weight |
|---|---|---|
| **Hard** | Server-timestamped, server-computed: state transitions, server-side distance calculations, trip start/end | Decisive |
| **Soft** | Device-reported and plausible: GPS fixes with good accuracy, no mock flag, consistent trajectory | Supporting, never sole basis |
| **Suspect** | Mock-location flagged, impossible speed between fixes, accuracy worse than 200 m, trajectory inconsistent with cell/Wi-Fi positioning | **Not evidence.** Flags the case for review; never auto-decides in either direction. |
| **Assertion** | What either party says happened | Context only |

### Rides — automatic, no queue

| Situation | Outcome |
|---|---|
| Driver cancels, trail shows **no movement toward pickup** | No fee was owed. Nothing to reverse. |
| Driver cancels **after trip start and near the destination** | Fee stands. The trip substantively happened; the cancellation is the [abuse Uber names](https://www.uber.com/pt/en/drive/driver-app/fraud-activities/). **Auto-decline the reversal** and flag the pattern. |
| Customer no-show: driver **at pickup ≥5 min**, customer never within the radius | Reversal **auto-confirmed**. The driver bears no fee for a customer who did not arrive. |
| Driver **>5 min late** to pickup, customer cancels | No fee. Matches Uber and Lyft. |
| Any leg **suspect** | Human review, with the flag shown. |

The 5-minute figure is taken directly from the benchmark rather than invented.
It should be a configuration value, not a constant.

### Browse & book — evidence-gated

| Situation | Outcome |
|---|---|
| Provider attested arrival within the accuracy radius, customer disputes attendance | Human review. Attestation is soft evidence; it is not conclusive on its own. |
| Provider **never attested arrival**, claims customer no-show | Reversal **declined** by default. A no-show claim with no arrival record is unsupported. |
| Customer cancels before `ACCEPTED` | No fee was owed. |
| Customer cancels after `ACCEPTED`, before `IN_PROGRESS` | No fee owed — commission posts on completion only. |
| Booking reached `COMPLETED`, customer later disputes the work | Human review. This is a quality dispute, not a cancellation, and the platform's position is limited: **it never handled the payment.** |

### Rentals

No booking, no commission, no reversal of this kind. A listing fee for a listing
withdrawn shortly after publishing is a refund-policy question, and the policy
does not exist yet.

## GPS is evidence, not proof

Non-negotiable, and it is where systems like this go wrong:

- **Never auto-penalise on a single fix.** Decisions use trajectory over time.
- **Accuracy travels with the coordinate.** A fix with an 800 m radius in
  Gaborone's CBD says nothing about whether someone reached a specific yard. If
  accuracy exceeds the configured threshold, the fix is not usable evidence.
- **Mock-location flags mean "review", not "guilty".** `Location.isMock` is a
  reasonable minimum layer and it is defeatable; conversely a legitimate
  developer-mode user is not a fraudster. Corroborate server-side: impossible
  speed between fixes, trajectory anomalies, coordinates inconsistent with cell
  or Wi-Fi positioning.
- **Botswana-specific reality.** Coverage outside Gaborone and Francistown is
  patchy, and the target handsets are low-end with weak GNSS. Absent or poor
  location data is the **normal case in rural areas**, not a suspicious one, and
  a rule that treats missing data as adverse will systematically punish
  providers in exactly the places the platform claims to serve.
- Uber's own policy language hedges GPS accuracy. If they hedge it at their
  scale, our copy hedges it too.

## Due process

A declined reversal takes money from someone who believes they are owed it. It
has to survive being challenged.

- **The reason is stated specifically.** Not "reversal declined" — the actual
  basis: *"trip records show the vehicle reached the destination and the trip
  ran 22 minutes."* Broad, conclusory determinations are precisely what
  [collapses under challenge](https://www.daeryunlaw.com/us/practices/detail/uber-driver-rights-and-deactivation).
- **The provider sees the evidence relied on**, in the app, not on request.
- **Automatic decisions are labelled as automatic**, with a route to human
  review. An automated decline that cannot be escalated is the pattern that
  generates complaints to a regulator.
- **The adjudicator's identity is recorded** in `ADMIN_ACTION`, including for
  automated decisions, where the actor is the rule that fired.
- **Whether a declined reversal can be contested is [open](#open)** — but the
  data model must not foreclose it.

## Retention — the real tension

Adjudication needs the logs. The Data Protection Act 2024 requires storage
limitation, and `TRIP_LOCATION` is high-volume personal data
([database](database.md#trip_location-is-partitioned)). These pull in opposite
directions, and in disputes elsewhere the position data is routinely gone by the
time it is needed.

Resolution — **tiered, not uniform**:

| Tier | Data | Retention |
|---|---|---|
| Full trail | `TRIP_LOCATION` points | Short. Partition-dropped. Long enough to cover the dispute window and no longer. |
| Derived summary | Start/end points, distance, duration, max distance from target, arrival attestations | Retained with the booking. Small, and it is what adjudication actually uses. |
| Under dispute | Anything referenced by an open dispute or reversal | **Legal hold** — exempt from the sweeper until resolved, then released. |

The legal hold is the piece that has to be built, not bolted on. A retention job
that deletes evidence in an open case is a defect with legal consequences, and
it is the default behaviour of a naive sweeper.

**The dispute window must be shorter than the full-trail retention period.**
That is the constraint that makes the whole scheme coherent, and it means the
window cannot be set independently of the retention decision — both are
currently open.

## Admin surface

The [reversals queue](admin.md#queues--the-actual-daily-work) becomes an
evidence view rather than a decision button:

- **Timeline** — every `BOOKING_EVENT` with server timestamps, actor and reason.
- **Map** — position trail where one exists, the agreed location, the
  attestation points with their accuracy radii drawn to scale. The radius drawn
  honestly is what stops a reviewer over-reading a 500 m fix.
- **Computed facts** — distance to target at attestation, wait duration,
  progress-toward-pickup, trip distance versus route distance.
- **Flags** — mock location, impossible speed, accuracy exceeded, repeat-pattern
  indicators for this provider.
- **What the automatic rules concluded**, and why, where one fired.
- **Reason capture is mandatory** and the text is shown to the provider verbatim.
- **Pattern view** — cancellation rate per provider against the category median.
  Uber's named fraud patterns are patterns; a single cancellation is rarely the
  signal.

Evidence is **read-only in the admin**, including for superusers. It is the
record being adjudicated; an editable record is not evidence.

## Schema consequences

New, on top of [database](database.md):

```sql
-- Arrival / completion attestation
CREATE TABLE core.booking_attestation (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id   uuid NOT NULL REFERENCES core.booking(id),
  kind         text NOT NULL CHECK (kind IN ('arrival','completion','customer_arrival')),
  actor_id     uuid NOT NULL,
  attested_at  timestamptz NOT NULL DEFAULT now(),   -- server clock, always
  point        geography(Point,4326) NULL,
  accuracy_m   numeric(8,1) NULL,
  is_mock      boolean NOT NULL DEFAULT false,
  distance_to_target_m numeric(10,1) NULL,           -- computed server-side
  photo_ref    text NULL
);
CREATE UNIQUE INDEX booking_attestation_once ON core.booking_attestation (booking_id, kind, actor_id);
```

Also required:

- `core.booking` gains a derived evidence summary written at terminal state, so
  adjudication does not depend on the full trail surviving.
- `core.trip` becomes reachable from movers bookings, not only rides.
- A `legal_hold` marker — on the dispute, referencing what is held — that every
  retention sweeper checks before deleting.
- `core.category` gains `requires_arrival_attestation` and
  `requires_completion_photo`, because this varies across the nine and must not
  be a code branch.
- Attestation rows are **append-only**, same treatment as `booking_event`.

## Where this lands in the plan

The gap is real and it is upstream of things already scheduled:

| Work | Sits with | Note |
|---|---|---|
| Attestation capture + schema | Booking lifecycle | Blocks evidence-based reversal entirely |
| Trip extension to movers | Dispatch & matching | Scope increase on the largest-fee category |
| Automatic decision rules | Commission on completion | Most cases must never reach a human |
| Legal hold + tiered retention | DPIA & data subject rights | Currently a defect waiting to happen |
| Evidence view in admin | Dispute handling | Replaces a decision button that decides nothing |
| Cancellation policy document | **Before any of it** | The rules above are proposals until someone decides them |

## Open

- **The cancellation policy itself.** Everything above is mechanism. Who may
  raise a reversal, within what window, and what causes qualify is a product and
  legal decision that has not been made.
- **The dispute window**, which must be shorter than full-trail retention.
- **Full-trail retention period**, which must be longer than the dispute window.
  These two are one decision, not two.
- **Whether a declined reversal can be contested**, and by what route.
- **No-show fee.** [system-flowcharts](system-flowcharts.md) flags this as a
  genuine fairness problem — a driver who travelled to a no-show has a real
  claim, but the platform never touches the customer's money, so there is
  nobody to charge. Unresolved, and evidence does not resolve it.
- **Partial reversals** — the same case, needing a rule rather than a judgement.
- **Whether arrival attestation is mandatory or optional per category**, and
  what happens to a booking where the provider simply never taps it.
- **Thresholds**: the 5-minute wait, the accuracy cutoff, the proximity radius
  that counts as "arrived". Benchmarked above, but ours to set — and Gaborone
  yard addresses are not Manhattan street addresses.

---

Sources: [Uber — fraud activities](https://www.uber.com/pt/en/drive/driver-app/fraud-activities/) ·
[Uber — review cancellation fee](https://help.uber.com/h/6bec690f-ee35-40ba-96ee-c38a8ae796e0) ·
[Lyft — cancel and no-show fee policy for drivers](https://help.lyft.com/hc/en-us/all/articles/115012922847-Cancellation-and-no-show-fee-policy-for-drivers) ·
[Bolt — how to handle scheduled rides](https://bolt.eu/en/support/articles/7769413257746/) ·
[Uber driver rights and deactivation](https://www.daeryunlaw.com/us/practices/detail/uber-driver-rights-and-deactivation) ·
[The digital paper trail — evidence in a rideshare case](https://www.cowenlaw.com/the-unique-evidence-we-use-in-a-rideshare-lawsuit) ·
[Detecting fake GPS / mock location on Android](https://blog.anmolthedeveloper.com/how-to-detect-fake-gps-and-mock-location-in-android-apps-a-developers-security-guide) ·
[Location spoofing detection](https://www.incognia.com/solutions/detecting-location-spoofing) ·
[Proof of completion for field service](https://lockproof.com/learn/proof-of-completion-for-field-service)
