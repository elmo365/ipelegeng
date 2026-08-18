# Safety & trust

Nothing in the specification set covers this. [project-plan](project-plan.md)
has a bar called "Trip lifecycle & safety" with nothing behind it, and that is
the entirety of the treatment so far.

It needs its own document because of what this product actually does:

> **Ipelege arranges for strangers to meet in person, usually alone, often in a
> home or a vehicle.** A driver and a passenger in a car. A plumber inside
> someone's house. A braider travelling to a client's address by herself. A
> prospective tenant viewing a room with a landlord neither has met.

That is not a feature of the product; it *is* the product. A marketplace selling
accountability has a duty here that a listings site does not.

---

## The scope, stated once

Everything in this document follows from a single position. It should not be
softened in marketing copy or widened in a planning meeting.

> **An app cannot prevent harm.** What it can do is record **who**, **where**
> and **when**, and make reporting fast. That is the whole of our safety
> capability, and we say so.

Three commitments, and no fourth:

| We do | We do not |
|---|---|
| **Who** — identity verified per category, so the person who turns up is documented, not anonymous | Guarantee anyone's conduct |
| **Where and when** — arrival attestation, position trails, immutable event history | Supervise, monitor in real time, or intervene |
| **Fast reporting and fast removal** — a report reaches a queue, a category can be suspended immediately | Provide emergency response, insurance, or damage cover |

**Deterrence through traceability, plus speed of removal.** That is deliverable
by a small team, it is honest, and it is materially more than a Facebook group
offers — which is the comparison a customer is actually making when they choose
us.

Two rules follow, and they govern every feature below:

1. **A feature is judged on whether we can operate it**, not on whether Bolt has
   it. *A safety feature that cannot be operated is more dangerous than its
   absence, because it implies a response that will not arrive.* A panic button
   routing to an inbox read on weekday mornings is a liability with a nice icon.
2. **Anything that produces a record beats anything that promises a response.**
   Records scale with a small team. Responses do not.

### What the app actually says

Writing the copy now, because "be honest in the copy" is easy to agree to and
easy to lose later. These strings live as constants, not literals — same
treatment as the money labels ([compliance](compliance.md)).

**On the badge**, never the bare word *Verified*:

> **Verified · Plumbing**
> Identity and trade certificate checked by Ipelege.

**On the safety screen**, reachable from every booking:

> **What Ipelege does**
> We check who providers are before they can list, and we keep a record of every
> booking — who, where and when. If something goes wrong, report it here and we
> will act.
>
> **What Ipelege cannot do**
> We are not there with you. We cannot supervise a job, and we are not an
> emergency service. If you are in danger, call the police first — then report
> it here so we can act on the account.
>
> **Before you meet**
> Share your booking with someone you trust. Keep contact in the app until you
> meet.

**Never** appears anywhere in the product: *safe*, *guaranteed*, *protected*,
*vetted* (unqualified), *screened* (unqualified), *insured*.

---

## The central risk: what "verified" means versus what it is read as

This is the most important thing on this page.

**What our badge actually means today:** an administrator looked at a plumbing
certificate, or a driving licence and vehicle registration, and approved the
category. It is a **competence and identity** check.

**What a customer reads it as:** *this person is safe to let into my home.*

Those are not the same claim, and the gap between them is created by our own
marketing. [design-system](design-system.md) states the thesis plainly —
"verification is what's being sold", "trust is the product". Having built the
badge into the centre of the value proposition, we cannot then treat its
meaning as a technicality.

Two ways to close the gap, and **one of them must be chosen before launch**:

1. **Raise the check to meet the reading** — add a police clearance certificate
   to the requirement set for categories involving home entry or carrying
   passengers.
2. **Lower the reading to meet the check** — state explicitly, at the point the
   badge appears, what was and was not verified.

Doing neither is the default, and the default is a misrepresentation that
becomes indefensible the first time something happens.

**Recommendation: do both.** The badge copy says what was checked
(`Verified · Plumbing — identity and trade certificate`), *and* the categories
that put a stranger in a home or a car carry a background check.

### The multi-worker hole

Thumbtack's own documentation concedes this and it applies to us exactly: a
background-check badge means **the account holder** met the criteria — for a
business with several workers, it does not guarantee the person who actually
turns up has been checked at all.

Our nine categories are full of small businesses. A verified plumbing account
sending an apprentice is the normal case, not an edge case, and today the badge
would silently cover them.

**Decide before launch:** either the listing shows who will attend and that
person is verified, or the badge explicitly covers the business rather than the
individual and says so.

### Checks decay

TaskRabbit's background checks are run **at registration only**, not
continuously — a widely noted limitation. A certificate seen in January says
nothing about a conviction in June.

Our schema already has `verification_document.retention_until` and a `revoked`
state ([data-model](data-model.md)). What is missing is a **re-check cadence**.

---

## Provider safety is the larger statistical risk

Easy to get backwards. The reporting on comparable African markets is
consistent: while passenger incidents attract the coverage, **it is more
commonly the drivers who are victims** of violent robbery and hijacking.

Extend that to our other categories and the picture is worse, not better:

| Who is exposed | How |
|---|---|
| **Driver** | Alone in a vehicle with a stranger, carrying cash — because payment happens in person, outside the app |
| **Mover** | Travelling to an unknown address, handling goods, often with a crew |
| **Braider, nail technician** | `provider_travels` means a woman going alone to a stranger's home address |
| **Plumber, electrician, tiler** | Inside a stranger's property, sometimes alone with an occupant |
| **Landlord / prospective tenant** | Meeting an unvetted stranger at a property, often empty |
| **Customer** | Admitting an unknown person to their home, or entering a stranger's vehicle |

**Customers are verified by nothing at all.** A provider accepts a booking from
a phone number and an unverified name, and travels to whatever address was
entered. The asymmetry is deliberate — customers must never face a KYC wall —
but it means the safety design cannot be customer-protection-only.

The **cash** point deserves emphasis. Because
[payment happens outside the app](compliance.md), every completed job ends with
a provider holding cash at a known location at a predictable time. That is a
risk profile the platform *creates*, and it is a direct consequence of the
regulatory design. It should be named in the risk register, not discovered.

---

## Exposure differs by journey shape

The [three shapes](system-flowcharts.md#not-every-category-traverses-these-machines)
need different treatments, and a single safety feature set would be wrong.

| Shape | Meeting | Highest-value controls |
|---|---|---|
| **Dispatch** (rides) | Enclosed vehicle, in motion, route known | Live tracking, trip sharing, emergency assist, number masking, driver identity re-check |
| **Browse & book** (7 categories) | A home or premises, static, often no location trail | Arrival attestation, share-my-booking, in-app contact, check-in / check-out |
| **Pay-per-listing** (rentals) | Property viewing, often empty, no booking record at all | **Currently invisible to us entirely** — the tenant enquires and leaves the app |

Rentals is the blind spot. The enquiry leaves the platform, so a viewing is
arranged over WhatsApp with no record that a meeting was ever scheduled. Nothing
in the safety model reaches it. That needs an explicit decision: either bring the
viewing arrangement into the app, or state that rentals viewings are outside our
duty of care and warn accordingly.

---

## Benchmark

What operators in comparable markets actually ship:

| Control | Where seen | Applies to us |
|---|---|---|
| In-app **emergency / panic button** | Bolt "Emergency Assist"; **legally mandated** in South Africa | Yes — rides first |
| **Trip sharing** with live location and vehicle registration | Uber, Bolt | Yes — and extend to non-ride bookings |
| **Phone-number masking** | Bolt, Uber | Yes, with a caveat below |
| **Audio trip recording** | Bolt (where available) | Consider — heavy consent implications under the DPA |
| **Random selfie identity checks** on drivers | Bolt, Uber | Yes — cheap, catches account sharing |
| **Criminal record / police clearance** | Standard for drivers in SA; TaskRabbit for in-home | **Gap — we do not do this** |
| Ongoing re-vetting | Named industry weakness | Gap |
| Property damage / satisfaction guarantee | Thumbtack, up to a limit | **No** — we hold no money; see below |

### The regulatory horizon

South Africa's **National Land Transport Amendment Act**, signed in late 2025,
now requires e-hailing platforms to provide a functional panic button connected
to emergency services, imposes stricter driver vetting, and carries fines around
R100,000.

Botswana has not legislated this. **Regional precedent of that weight is a
strong signal**, and building a panic button voluntarily is far cheaper than
retrofitting one to a deadline. Treat the SA Act as a preview of the compliance
floor rather than as somebody else's problem.

---

## The tracking trail *is* the safety model

Everything benchmarked above assumes an operator with a 24/7 safety desk, a
vetting budget and a legal team. **We are a small team, and pretending otherwise
produces a worse outcome than admitting it.**

The good news is that the safety model needs almost no new machinery. The
[evidence layer built for cancellation adjudication](cancellation.md) already
produces exactly the *who, where and when* the scope above commits to — it was
built to settle money disputes, and it settles safety questions with the same
records:

| Capability we already have | What it does for safety |
|---|---|
| Verified identity per category | The person who turns up is a known, documented individual, not a phone number |
| Arrival attestation with GPS and server timestamps | A record that this person was at this address at this time |
| Position trail (rides, movers) | Route reconstruction — where a vehicle actually went |
| `booking_event` history | An immutable account of what happened and when |
| Legal hold | Evidence survives long enough for a police enquiry |
| Per-category revocation | A provider can be removed from a category immediately |

**Deterrence through traceability, plus speed of removal.** That is deliverable
by a small team, it is honest, and it is genuinely more than a Facebook group
offers — which is the actual comparison a customer is making.

What it demands in return is **honesty in the copy.** If the trail is the
safety model, the app must not imply supervision it does not provide. The badge
says what was checked. The safety screen says: *we know who this is, we record
where and when, and we act on reports* — not *you are safe*.

Two things follow, and they matter more than any feature below:

1. **Every feature in the tiers below is judged on whether we can operate it**,
   not on whether comparable platforms have it.
2. **Anything that produces a record is favoured over anything that promises a
   response**, because records scale with a small team and responses do not.

## What to build

Tiered, so the argument for each is separable — and each tier is filtered
through the operability test above.

### Tier 1 — before any real user, all categories

- **Report a person.** From a booking, a listing and a profile. Free text plus a
  category (safety, fraud, no-show, abuse). Writes to a queue an admin actually
  works.
- **Block a person.** Mutual and permanent: a blocked pair are never matched
  again, in any category. This must reach the dispatch matcher, not just the UI.
- **In-app safety copy at the right moment** — not buried in terms. What was
  verified, what was not, and what to do if something goes wrong.
- **An incident escalation path with a named owner.** A report that lands in a
  queue nobody is accountable for is worse than no report button, because it
  implies a response that will not come.
- **Emergency numbers surfaced in-app.** Botswana's are widely published;
  **confirm the current numbers with the Botswana Police Service before
  shipping** rather than trusting a search result.

### Tier 2 — with the booking lifecycle

- **Share my booking** — a link giving a trusted contact the provider's name,
  the category, the scheduled time and the address. The non-ride equivalent of
  trip sharing, and the single highest-value control for the seven browse
  categories.
- **Arrival attestation** — already specified for
  [cancellation evidence](cancellation.md). It doubles as a safety signal: a job
  where the provider arrived and nothing further happened is detectable.
- **In-app contact with number masking** (see the tension below).
- **Cancel without penalty for a stated safety reason**, on either side, with no
  fee consequence and no rating impact. If cancelling for safety costs money,
  people will not cancel.

### Tier 3 — with rides

- **Live trip sharing** with vehicle registration. Cheap, no operating
  commitment, and it moves the response to someone who will actually act — the
  contact watching the trip.
- **Route deviation detection** — the position trail already exists for
  [evidence](cancellation.md); a significant unexplained deviation is a safety
  signal as well as a fraud one. It produces a record, so it fits the model.
- **Driver selfie re-verification**, randomly and after inactivity. Catches
  account sharing, which is the failure that makes every other control useless.
- **Emergency assist button** — **only when its destination is real.** Ship it
  the day it reaches emergency services or a nominated contact directly. Do not
  ship it pointed at our own support queue. South Africa now mandates a working
  one, so treat this as deferred rather than declined.

### Deliberately not doing

- **No safety guarantee, no insurance, no damage cover.** Thumbtack can offer
  this because it handles the money; we never do. Promising cover we cannot fund
  would be worse than silence.
- **No claim to vet customers.** We do not, we will not gate them, and we should
  not imply otherwise.
- **No SOS that only notifies us.** A panic button that alerts a support inbox
  during office hours is theatre. Either it reaches emergency services or a
  nominated contact, or it does not ship.

---

## The number-masking tension

Masking is standard practice and it **conflicts with our payment model.**

Payment happens person-to-person, outside the app, in cash or the parties' own
mobile money — which for Orange Money requires a phone number. And
[distribution](distribution.md) notes providers already live on WhatsApp.

So numbers will be exchanged. Masking cannot prevent it and pretending otherwise
is a false promise.

**The workable position:** mask by default up to the point of meeting, so a
browsing customer cannot harvest provider numbers and an enquiry cannot be
pulled off-platform before a booking exists. Accept that the parties will
exchange details when they transact, and be honest in the copy that the
platform's visibility ends there.

Worth recording as a real cost of the off-app payment design, alongside the
cash-handling exposure above.

---

## Incident handling

The queue matters more than the button.

| Stage | Requirement |
|---|---|
| **Report** | Reachable in under three taps from a booking. Never requires the reporter to name a category correctly to be heard. |
| **Acknowledge** | Automatic and immediate, stating what happens next and when. Silence after a safety report is its own harm. |
| **Triage** | Severity tiers. Alleged violence or a sexual offence is not the same queue as a rude message and must not sit behind one. |
| **Interim action** | Ability to **suspend a provider category immediately**, pending review, without a completed adjudication. The schema supports this — `revoked` exists — but the policy for using it does not. |
| **Preserve** | A safety report places a [legal hold](database.md#legal-hold) on the booking's evidence. Retention sweepers must not delete a trail that a police enquiry may need. |
| **Escalate** | A defined route to the Botswana Police Service, and a named person who owns it. |
| **Record** | Every step in `ADMIN_ACTION`, with reasons. If this is ever litigated, the record is the defence. |

**Suspension-pending-review conflicts with the revocation gap.**
[system-flowcharts](system-flowcharts.md) already flags that nobody has decided
what happens to already-accepted bookings when a category is revoked. A safety
suspension is exactly the case where that is urgent — you cannot leave a
suspended provider holding live bookings while someone thinks about it.

---

## Schema consequences

New, on top of [database](database.md):

```sql
CREATE TABLE ops.safety_report (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id   uuid NOT NULL REFERENCES core."user"(id),
  subject_id    uuid NOT NULL REFERENCES core."user"(id),
  booking_id    uuid NULL REFERENCES core.booking(id),
  category      text NOT NULL,        -- safety | fraud | abuse | no_show | other
  severity      text NOT NULL,        -- critical | high | normal
  body          text NOT NULL,
  status        text NOT NULL,        -- received | triaged | actioned | closed
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE ops.user_block (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id    uuid NOT NULL REFERENCES core."user"(id),
  blocked_id  uuid NOT NULL REFERENCES core."user"(id),
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (actor_id, blocked_id)
);

CREATE TABLE ops.booking_share (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id  uuid NOT NULL REFERENCES core.booking(id),
  token       text NOT NULL UNIQUE,   -- unguessable, single booking
  expires_at  timestamptz NOT NULL,
  revoked_at  timestamptz NULL
);
```

Plus:

- `core.provider_category` gains `suspended_at` and `suspension_reason` —
  distinct from `revoked`, because suspension is interim and reversible.
- The **dispatch matcher must consult `user_block`.** A block that only hides a
  listing but still allows a ride match is not a block.
- A safety report **places a legal hold in the same transaction**.
- `booking_share.token` is a bearer credential: unguessable, expiring, and
  revocable — it exposes a person's location and address to whoever holds it.

---

## Safety depends on hosting — directly

Worth stating explicitly because it is easy to file safety under "product
features" and hosting under "infrastructure" and never connect them. **Once the
evidence trail is the safety model, the box holding that trail becomes
safety-critical**, and every hosting property turns into a safety property.

| Hosting property | Safety consequence |
|---|---|
| **Availability** | A report button, a share link and a trip trail that are down during an incident do not exist. This is the strongest argument against depending on a free tier that can be paused, reclaimed or silently re-limited — Oracle halved its allowance with no notice and terminated over-limit instances. Fine for a dev box; **not** fine for the thing a police enquiry will ask for. |
| **Durability** | Evidence lost is a case that cannot be made. Off-box backups stop being an ops nicety and become part of the safety commitment. |
| **Residency** | A police enquiry, a subpoena or a court order lands in a Botswana jurisdiction. Evidence sitting in Lauterbourg is reachable in principle and slow and contested in practice — at exactly the moment speed matters most. |
| **Retention headroom** | Legal holds prevent deletion. A safety case can hold a full position trail open indefinitely, so held evidence grows without bound while the case does. Disk sizing must account for it; a sweeper that fails on a full disk fails silently. |
| **Latency** | Live tracking and share-my-booking are only useful in near real time. Johannesburg is under 10 ms; Europe is not comparable. |
| **Log integrity** | If evidence can be altered, it is not evidence. Append-only handling and controlled access are the same discipline the ledger already requires — and the same reason root access matters. |

The practical consequence: **the phase 0 / phase 1 hosting split is not just a
compliance line, it is a safety line.** A free foreign box is fine while the
data is synthetic. The moment real people are meeting real strangers through
this app, the evidence layer is load-bearing for someone's physical safety, and
it needs the availability, durability and jurisdiction that implies.

That is a further argument for [starting on Botswana-resident hosting and
staying there](architecture.md#two-viable-routes-for-production-both-giving-root)
if the price is close — it removes a migration from the middle of the period
when the safety model first goes live.

## Compliance overlap

Safety features are, almost without exception, personal-data processing:

- **Sharing a booking** discloses the provider's name and the customer's address
  to a third party who never consented. Time-bound, scoped, revocable — and
  described in the privacy notice.
- **Audio recording** is high-risk processing needing its own consent and almost
  certainly its own DPIA section. This is why it sits under "consider" and not
  "build".
- **Selfie re-verification** is biometric-adjacent. Check whether it is special
  category data under the Act before building it.
- **Reports and blocks contain allegations about identifiable people.** They are
  personal data about the *subject*, not only the reporter, and are subject to
  access requests. Write them expecting the subject may one day read them.
- **A safety hold overrides retention.** Correct, and it needs a stated maximum
  duration or it becomes indefinite retention by another name.

---

## Open

- [ ] **Does the verified badge get a police clearance behind it**, for
      home-entry and passenger-carrying categories? The single biggest decision
      on this page. Botswana Police Service issues clearance certificates —
      confirm cost, turnaround and whether a platform may require one.
- [ ] **What does the badge cover for a multi-worker business** — the account or
      the person who attends?
- [ ] Re-verification cadence, and what triggers an off-cycle re-check
- [ ] **Rentals viewings** — bring into the app, or state they are out of scope
      and warn?
- [ ] Panic button destination: emergency services directly, a nominated
      contact, or a monitored line? Each has a cost and an operating commitment.
- [ ] Confirm current Botswana emergency numbers with the Police Service
- [ ] Who owns the incident queue out of hours, and what is the response target
      for a critical report?
- [ ] Suspension policy — what happens to live bookings under a suspended
      category (blocked on the same decision as
      [revocation](system-flowcharts.md))
- [ ] Whether audio recording is proportionate here, given the DPA
- [ ] Maximum duration of a safety-driven retention hold

---

Sources: [Bolt SA safety measures](https://www.itweb.co.za/article/bolt-sa-bolsters-safety-measures-amid-rising-attacks/xA9PO7NEWe2vo4J8) ·
[Ride-hailing platforms and safety](https://fastcompany.co.za/tech/2025-10-07-the-ride-hailing-platforms-race-to-solve-safety-challenges/) ·
[New e-hailing laws, South Africa 2026](https://rydesafe.co.za/blog/e-hailing-laws-south-africa-2026) ·
[Laws to protect e-hailing drivers and passengers](https://mybroadband.co.za/news/motoring/653319-laws-to-protect-e-hailing-drivers-and-people-who-use-uber-and-bolt-in-south-africa/) ·
[E-hailing safety in the spotlight](https://www.timeslive.co.za/motoring/2026-07-03-e-hailing-safety-back-in-the-spotlight-after-latest-uber-robbery/) ·
[TaskRabbit background checks](https://checkr.com/organizations/taskrabbit) ·
[Thumbtack safety](https://www.thumbtack.com/safety/)
