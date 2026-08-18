# Project plan

## Health warning on this plan

This is a **structure**, not a commitment. Two things could invalidate it
entirely:

1. **The EPS licensing question.** If the Bank of Botswana requires a licence
   for the wallet ([compliance](compliance.md)), the timeline below does not
   survive — licensing involves incorporation, capital, security vetting of
   directors and a formal business plan. That is quarters, not weeks. **Resolve
   this before committing to any date.**
2. **Team size.** The durations assume a small team working steadily. One person
   part-time should roughly double them.

**Nine** launch categories is a lot of surface area — the design split the old
"Small trades" grouping into Plumbing, Electrical and Tiling, each with its own
KYC requirements, and separated Catering from Hire
([design-deltas](design-deltas.md#1-nine-categories-not-six)). The single
biggest schedule risk after licensing is trying to build all nine to the same
depth at once. Categories are data, not code — build the model once, seed two or
three deeply.

## Phases

```mermaid
gantt
    title Ipelege — phase one
    dateFormat YYYY-MM-DD
    axisFormat %b

    section 0 Blockers
    Legal opinion - EPS licensing      :crit, b1, 2026-09-01, 45d
    Hosting & residency decision       :crit, b2, 2026-09-01, 30d
    Payment gateway selection          :b3, 2026-09-15, 30d
    Cancellation policy decision       :crit, b4, 2026-09-01, 21d

    section 1 Foundation
    Backend stack decision - DONE      :done, f1, 2026-08-17, 1d
    Project setup, CI, environments    :f2, 2026-09-01, 14d
    Flutter shell, theme, navigation   :f2b, 2026-09-01, 21d
    Identity & accounts                :f3, after f2, 21d
    Ledger core + idempotency          :crit, f4, after f2, 28d
    Domain event outbox + relay        :f4b, after f3, 14d
    Staff auth, 2FA, audit plumbing    :f5, after f3, 10d

    section 2 Provider side
    Category & verification model      :p1, after f3, 21d
    KYC upload                         :p2, after p1, 21d
    Admin - verification queue         :p2b, after p2, 10d
    Listings & service direction       :p3, after p1, 28d
    Top-up - Orange Money              :crit, p4, after f4, 21d
    Top-up - EFT & reconciliation      :p5, after p4, 21d
    Admin - unmatched deposit queue    :p5b, after p5, 7d

    section 3 Customer side
    Search & browse                    :c1, after p3, 21d
    Booking lifecycle                  :c2, after c1, 28d
    Arrival attestation & evidence     :c2b, after c2, 14d
    Commission on completion           :c3, after c2, 14d
    Reversal rules & admin evidence    :crit, c3b, after c3, 21d
    Ratings & reviews                  :c4, after c2, 14d

    section 4 Rides
    Driver onboarding                  :r1, after p2, 14d
    Dispatch & matching                :r2, after c2, 28d
    Live tracking                      :crit, r3, after r2, 28d
    Trip lifecycle & safety            :r4, after r3, 21d
    Trip extension to movers           :r5, after r3, 14d

    section 5 Rentals
    Rental listing model               :n1, after p3, 14d
    Listing fee flow                   :n2, after n1, 14d

    section 5b Channels
    Facebook App Review submission     :crit, x1, 2026-09-15, 45d
    Consent model & granular capture   :x2, after f3, 21d
    Syndication worker & safety gate   :x3, after p3, 21d
    Takedown path & testing            :x4, after x3, 14d
    WhatsApp Business App - manual use :x5, 2026-09-01, 30d
    WhatsApp API & templates           :x6, after c2, 21d

    section 6 Hardening
    Dispute handling                   :h1, after c3b, 21d
    Legal hold & tiered retention      :crit, h1b, after c2b, 14d
    DPIA & data subject rights         :crit, h2, after c3, 21d
    Security review                    :h3, after r4, 14d
    Load & failure testing             :h4, after h3, 14d

    section 7 Launch
    Provider seeding - movers          :l1, after p5, 42d
    Provider seeding - rentals         :l2, after n2, 42d
    Provider seeding - beauty & trades :l3, after l2, 42d
    Closed beta - Gaborone             :l4, after h4, 28d
    Public launch                      :milestone, after l4, 0d
```

## Milestones

| # | Milestone | Definition of done |
|---|---|---|
| M0 | Licensing position known | Written legal opinion on the wallet model |
| M1 | Ledger provably correct | Concurrent double-post test passes; balances reconstruct from journal |
| M2 | First real top-up | Orange Money end-to-end in production, reconciled |
| M3 | First real booking | Non-ride booking completed, commission posted correctly |
| M4 | First real trip | Ride completed with tracking, route recorded |
| M5 | Supply threshold met | Minimum provider count reached per category per city |
| M5b | Channel loop working | Listing syndicates to Page, deep link converts to install, takedown verified |
| M6 | Compliance sign-off | DPIA complete, data subject rights functional, residency satisfied |
| M7 | Public launch | M1–M6 all met |

**M5 is the one that will slip.** It depends on people signing up, not on code
being finished, and it is the least controllable item in the plan.

## Critical path

```mermaid
flowchart LR
    A[EPS legal opinion] --> B[Backend + hosting decision]
    B --> C[Ledger core]
    C --> D[Orange Money top-up]
    D --> E[Booking lifecycle]
    E --> F[Commission posting]
    F --> G[Rides + tracking]
    G --> H[Compliance sign-off]
    H --> I[Launch]
    J[Provider seeding] --> I
```

Everything financial sits behind the ledger. Everything sits behind the legal
opinion. Provider seeding runs in parallel and joins at the end — start it as
early as there is something to show.

## Sequencing advice

**Build the ledger first, before any feature that touches it.** It is the piece
where mistakes are least recoverable — a booking bug loses a booking, a ledger
bug loses trust and cannot be cleanly undone.

**The admin side is not a phase-two panel.** Five mobile journeys cannot
complete without a human on the other side — KYC approval, EFT matching,
reversal adjudication, dispute resolution, revocation. Admin capability
therefore lands *with* the feature it unblocks rather than in a lump at the end,
which is why it now appears in three sections of the Gantt instead of as a
single "admin panel skeleton" bar. Because the back office is Django admin
inside the same project, each of those bars is short. See [admin](admin.md).

**Instrument evidence before you need to adjudicate on it.** Arrival
attestation is scheduled immediately after the booking lifecycle and before
reversal rules, deliberately: seven of the nine categories currently produce no
evidence that a service happened, and a reversal queue with nothing to weigh is
a queue that decides by coin toss. Retrofitting attestation after bookings are
live means every historical dispute is unadjudicable. See
[cancellation](cancellation.md).

**Consider narrowing the launch.** Six categories at launch is the stated
decision, and the ecosystem argument for it is sound. But a defensible middle
path is to build the full six-category *model* — categories are data, not code —
while seeding only two or three deeply for the closed beta, then opening the
rest as supply arrives. That keeps the ecosystem architecture without six
half-empty categories on day one.

## Note on Facebook App Review

`pages_manage_posts` requires Meta App Review, which has a lead time outside
your control. It is marked critical in the Gantt for that reason — not because
it is hard, but because it cannot be compressed once you are late. **Submit
early**, even before the syndication worker is finished.

Manual group posting and the WhatsApp Business App need no approval at all and
can start immediately — they are how seeding actually begins.

## Not estimated here

- Marketing and provider acquisition cost
- Legal and licensing fees
- App store review time
- Support staffing for EFT reconciliation, which scales with provider count
- **Growth operator time for manual group posting** — a recurring staffed role,
  roughly 3–5 groups per day, not an automated feature
- WhatsApp per-message costs once past the free service window
