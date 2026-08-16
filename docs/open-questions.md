# Open questions

Decisions not yet made. Tracked here so they are not silently assumed during
build.

## Resolved since last revision

- **Launch categories.** Six: rides, movers & hauling, property rentals,
  hairdressing & beauty, small trades, event hire. See
  [categories](categories.md).
- **Mobile framework.** Flutter.
- **Service direction.** Set per listing by the provider, chosen by the customer
  at booking. See [booking](booking.md).
- **Launch payment rails.** EFT + Orange Money. See [payments](payments.md).

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
- [ ] Wallet balance — one per provider, or per category?

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
- [ ] **Ledger account granularity** — one per provider, or one per provider per
      category.
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
