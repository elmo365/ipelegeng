# Open questions

Decisions not yet made. Tracked here so they are not silently assumed during
build.

## Resolved since last revision

- **Launch categories.** **Nine**, not six — "small trades" split into plumbing,
  electrical and tiling, each with its own KYC requirements; catering separated
  from hire. See [categories](categories.md).
- **Mobile framework.** Flutter, Android-first.
- **Backend stack.** Django 5 + DRF + GeoDjango on PostgreSQL 16 + PostGIS.
  Decided 2026-08-17. See [architecture](architecture.md#backend--decided).
- **Admin panel.** Django admin inside the same project — not a separate
  application, not Flutter Web. Built alongside each feature it unblocks, not
  as a phase two. See [admin](admin.md).
- **Ride commission and VAT.** 8% of the fare; 14% VAT on the fee. Fee and VAT
  post as separate journal entries, never bundled. See
  [monetization](monetization.md#rates-and-vat).
- **Service direction.** Set per listing by the provider, chosen by the customer
  at booking. See [booking](booking.md).
- **Launch payment rails.** EFT + Orange Money. See [payments](payments.md).
- **Ledger account granularity.** **One wallet per provider**, spanning every
  category — not one per category. Decided 2026-08-19; corroborated by the data
  model (`USER ||--|| LEDGER_ACCOUNT`, 1:1) and the design canvas, which calls
  "one wallet" its load-bearing decision. Consolidated flow in [wallet](wallet.md).

## ⚠️ Newly opened — 2026-08-17

Raised by the design import and the cancellation benchmarking. Each is
recorded where it belongs; collected here so none is lost.

**Blocking a schema decision** — see [database](database.md#open):

- [x] **`LEDGER_ACCOUNT`: one per provider, or one per provider per category?**
      **Resolved 2026-08-19 — one per provider** (single wallet, all categories).
      See [wallet](wallet.md) and the Resolved list at the top of this file.
- [ ] Are negative balances permitted, and in which states?
- [ ] Retention period for `TRIP_LOCATION`, which sets the partition drop window
- [ ] Statutory retention for journal entries — confirm the assumed 7 years

**Blocking cancellation** — see [cancellation](cancellation.md#open):

- [ ] **The cancellation policy itself.** Who may raise a reversal, within what
      window, and which causes qualify. Everything specified so far is
      mechanism; none of it is policy.
- [ ] **The dispute window and full-trail retention are one decision, not two.**
      The window must be shorter than retention, or evidence is deleted before
      it is needed.
- [ ] Whether a declined reversal can be contested, and by what route
- [ ] Whether arrival attestation is mandatory per category, and what happens
      when a provider simply never taps it
- [ ] Thresholds: the 5-minute wait, the GPS accuracy cutoff, the proximity
      radius that counts as "arrived". Benchmarked, not decided — and Gaborone
      yard addresses are not Manhattan street addresses.
- [ ] Partial reversals, and whether a no-show fee can exist at all when the
      platform never touches the customer's money

**Contradicts an existing binding constraint:**

- [ ] **The balance is called a "wallet" in the product.**
      [compliance](compliance.md) lists *don't call it a wallet* as a binding
      constraint; the design deliberately reversed it and defends the position
      structurally instead. **Not settled** — put it in the same question to
      counsel as EPS licensing. See
      [design-deltas](design-deltas.md#3-wallet-balance-not-commission-credit).

**Safety** — see [safety](safety.md#open). Nothing in the spec covered this:

- [ ] **What does the verified badge actually stand behind?** Today it means an
      admin saw a trade certificate. Customers read it as *safe to let into my
      home*. Either raise the check (police clearance for home-entry and
      passenger categories) or lower the claim (say what was checked) —
      **doing neither is a misrepresentation.** Biggest open item on this list.
- [ ] For a multi-worker business, does the badge cover the **account** or the
      **person who turns up**? Small businesses are the normal case here.
- [ ] Re-verification cadence — a certificate seen in January says nothing about
      a conviction in June
- [ ] **Rentals viewings are invisible to us** — the enquiry leaves the app, so a
      stranger meeting at an empty property has no record. In scope or explicitly
      out?
- [ ] Panic button destination: emergency services, nominated contact, or a
      monitored line? Each is an operating commitment, and South Africa now
      **mandates** one for e-hailing.
- [ ] Who owns the incident queue out of hours, and the response target for a
      critical report
- [ ] Whether audio trip recording is proportionate under the DPA

**Blocking a screen from shipping:**

- [ ] **What happens to already-accepted bookings when a category is revoked.**
      Undefined in the spec, and the design says the state therefore "has no
      honest copy yet". The admin revoke action cannot ship without it.

**Auth phasing** — see [components](components.md#auth--adopt-and-phase-it):

- [ ] **Phase 0 registration is email + password + phone + names**, deferring
      SMS OTP until an aggregator is affordable. This departs from FR-1.1/FR-1.2,
      where the phone number *is* the identity.
- [ ] **"One phone, one account" cannot be verified in phase 0.** Enforce
      uniqueness on the unverified column anyway, or the phase 1 migration
      inherits every duplicate created in the meantime.
- [ ] Whether phase 1 phone verification uses Firebase Auth's free quota or a
      local SMS aggregator — **the routes, and what each costs, are written up
      in [`sms-otp.md`](sms-otp.md)**, along with the finding that matters more
      than the per-message price: the design asks for an OTP on *every fresh
      login*, which makes SMS a recurring per-user cost rather than a one-time
      one
- [ ] Whether **flash-call** verification replaces or supplements SMS. Much
      cheaper in this kind of market, and it changes a screen — so it is a
      design decision as well as a cost one
- [ ] **Sender ID registration** with the networks or BOCRA, if bulk SMS in
      Botswana requires it. A lead-time item rather than a code one, so it has
      to be checked before a launch date is set
- [ ] The design's OTP screens and "SMS code on every new device" rule do not
      apply in phase 0 — the register screen needs a variant, and the design
      project should be told

**Operational:**

- [ ] Who staffs the [admin queues](admin.md#queues--the-actual-daily-work), and
      what verification SLA they can sustain — the app copy has to name a
      review window, so this is a product decision, not an ops one
- [ ] Whether reversal confirmation needs two-person approval above some amount

## ⚠️ Blockers — external, start now

- [ ] **Confirm the provider balance sits outside EPS licensing.** Most of the
      exposure is already designed out — the platform never sits between
      customer and provider, so there is no money transmission. The narrow
      remaining question is whether a non-redeemable, non-transferable prepaid
      credit balance counts as a payment account under the Electronic Payment
      Services Regulations 2019. Scoped question for counsel, not an open
      research project. See [compliance](compliance.md).
- [ ] **Written policy on unused balance at account closure.** Refunding to cash
      is the one change most likely to reclassify the product. Decide in advance
      and put it in the provider terms.
- [ ] **Where is data hosted?** The Data Protection Act 2024 requires a copy of
      personal data to remain in Botswana. Constrains infrastructure choice.
      **Now much narrower than it was** — local Tier III capacity is confirmed
      to exist (Digital Delta DC1, BoFiNet-operated, Block 8; also Atal and
      C-Nest), and a self-managed VPS is the recommended shape because it gives
      the superuser the ledger's privilege model needs. What remains is a
      **price**. Get a quote; if it lands near P60/month, start local, stay
      local, and this blocker closes with no migration ever needed. See
      [architecture](architecture.md#two-viable-routes-both-giving-root).
      Note that several providers branded "Botswana VPS" are physically in
      Johannesburg — good latency, wrong jurisdiction.
- [ ] **Is a DPIA required for GPS tracking, and who conducts it?**
- [ ] **KYC document retention schedule** per document type.

## Answered by research

Evidence and reasoning in [comparable-platforms](comparable-platforms.md).
These are *recommendations from precedent*, not decisions — each still needs
your call.

| Question | Evidence-based answer |
|---|---|
| Commission rate | 10% is a tested ceiling in a comparable African market (customer-side). Start at or below the equivalent. |
| Quote vs fixed pricing | Fixed / from-pricing with instant booking. Quote-based flows were a major failure point at Lynk. |
| Listing structure | Structured service catalogue per category, not free-text. |
| Ratings and reviews | Build them — but with an explicit new-provider boost, or you manufacture provider churn. |
| Which category to seed first | Movers. Urgent demand, small provider pool, in-person signup. |

## ⚠️ Reopened by research

- [ ] **Six categories at launch.** Evidence runs strongly against: Gojek, Grab
      and WeChat each went single-service first; SweepSouth stayed
      single-category roughly a decade; Lynk's service variety contributed to
      its failure. Suggested compromise — build the six-category *model*
      (categories are data), seed one or two deeply for beta.
- [ ] **Lead-gen or full-service?** The compliance-driven design pushes toward
      lead-gen (platform touches no money). Lynk tested lead-gen in an African
      market and moved away from it. Regulation and market evidence point
      opposite ways. **Decide deliberately.**
- [ ] **Is "trust is the product" enough?** Lynk found customers would not pay
      for vetting and convenience alone. Needs an answer.
- [ ] **Is rentals actually a gap?** Boroko (Botswana rental app, Google Play)
      already offers verified, filterable listings, alongside Property24
      Botswana and 4321property. The room-in-a-yard segment may still be
      underserved — verify before relying on it.
- [ ] **Rides competition.** Gaborone has inDrive, Yango *and* Bolt. The spec
      assumes inDrive alone. Also check whether ride-hailing regulation in
      Botswana creates obligations for a local entrant.

## Product

- [ ] **Booking completion** — what marks a booking complete, who marks it, and
      what happens on dispute. Determines wallet ledger design. See
      [booking](booking.md).
- [ ] **Cancellations, no-shows, refunds.**
- [ ] **Insufficient wallet balance at completion** — what happens.
- [ ] **Discovery model per category** — browse-and-book vs auto-match is the
      working assumption, not a formal decision.
- [ ] **Target customer definition** — urban, smartphone-owning, Gaborone-first
      is the working assumption; never stated explicitly.
- [ ] **Verification: mandatory or badge?** Must a provider verify before
      listing, or can unverified providers appear, with "verified" as a
      differentiator?
- [ ] **Dispute and recourse** — trust is the stated product; the mechanism is
      undefined.
- [ ] **Ratings and reviews** — implied by "record of past work to build trust,"
      not specified.
- [ ] **No-show fees.** A driver who waits twenty minutes for an absent customer
      currently absorbs the loss entirely. Since the platform never touches the
      customer's money, there is no obvious mechanism to charge them. Real
      fairness problem, no clean answer yet.
- [ ] **Revoked verification with live bookings** — what happens to bookings
      already accepted when a category is revoked.

## Monetization

- [ ] Commission percentage.
- [ ] Whether commission varies by category.
- [ ] Per-listing price for rentals.
- [ ] Minimum wallet top-up.
- [x] Wallet balance — one per provider, or per category? **Resolved: one per
      provider.** See [wallet](wallet.md).

## Technical

- [ ] **Backend language and framework** — nothing chosen. Blocks most
      implementation work. See [architecture](architecture.md).
- [ ] **Admin panel stack** — React and Flutter web both under consideration,
      possibly a Windows desktop build. Explicitly a proposal, not final.
      *(Mobile is settled: Flutter.)*
- [ ] **Backend stack** — not chosen.
- [ ] **GPS tracking components** — intent is open-source rather than built from
      scratch; specific libraries not selected.
- [ ] **Who performs KYC** — manual admin review or a third-party service.
      Botswana's national ID system already supports basic KYC verification;
      worth investigating before contracting a vendor.
- [x] **Ledger account granularity** — **Resolved: one per provider** (single
      wallet across all categories). See [wallet](wallet.md).
- [ ] **Test strategy** — not yet written. Ledger and booking state transitions
      need concurrency and property-based tests, not just unit tests.

## Payments

*Launch rails are decided: EFT + Orange Money, gateway is TJ or PayGate.*

- [ ] **Which gateway — Transaction Junction or PayGate.** Likely settled by
      whichever supports instant EFT and Botswana settlement on terms available
      to a pre-launch company.
- [ ] Whether EFT top-ups are automated via instant EFT, or require manual
      reconciliation. Has real operational cost either way.
- [ ] Orange Money Botswana API — sandbox access, settlement terms, fees.
- [ ] PawaPay Botswana coverage (phase two only).

## Go-to-market

- [ ] Which single category and city to seed first.
- [ ] Provider acquisition channel. Partly answered — Facebook as top-of-funnel,
      see [distribution](distribution.md). Note the Groups API is gone, so group
      posting is manual and needs an owner.
- [ ] Facebook App Review lead time, if Page auto-posting is wanted at launch.
- [ ] **Minimum supply threshold per category before public launch.** Now the
      sharpest go-to-market question: six categories means six chances to look
      empty on first open.
- [ ] Launch-readiness supply threshold.

## Evidence gaps

- [ ] **Incumbent adoption.** The claim that existing bus-ticketing apps have
      negligible adoption rests on absent public download figures and founder
      observation. Not measured. This is the claim most likely to be challenged
      by a funder.
