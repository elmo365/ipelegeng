# Ipelege

**A multi-category services marketplace for Botswana.**

*Ipelege* is Setswana for "self-reliance."

Most service work in Botswana is informal. Hairdressers, drivers, tent-and-chair
hire operators, home cooks, plumbers, electricians and truck owners run real
businesses without fixed premises or any reliable way to reach customers beyond
word of mouth and WhatsApp status posts. Ipelege gives them a channel — and
gives customers one place to find, book and pay verified providers.

---

## The short version

| | |
|---|---|
| **Who pays** | Service providers only. Never the customer, in any category. |
| **How** | Wallet top-up; commission deducted per completed booking. No bookings, no cost. |
| **Launch cities** | Gaborone, Francistown |
| **Launch categories** | Rides · Movers & hauling · Property rentals · Hairdressing & beauty · Small trades · Event hire |
| **Seeding priority** | Movers → rentals → beauty → trades, hire |
| **Phase two** | Bus ticket booking |
| **Payments at launch** | EFT + Orange Money; gateway TJ or PayGate |
| **Mobile** | Flutter |
| **Admin panel** | Undecided — see [open questions](docs/open-questions.md) |

---

## Documentation

Start with the [SDLC overview](docs/sdlc-overview.md) for reading order.

### Requirements & analysis

| Document | What's in it |
|---|---|
| [Problem statement](docs/problem-statement.md) | Who is underserved and why existing options fail |
| [Solution](docs/solution.md) | The four pillars the platform rests on |
| [Categories](docs/categories.md) | Full category list and the ecosystem principle |
| [Monetization](docs/monetization.md) | Wallet model, pay-per-post, per-category variation |
| [Payments](docs/payments.md) | Mobile money, card gateways, integration sequencing |
| [User model](docs/user-model.md) | Account structure, roles, per-category verification |
| [Booking model](docs/booking.md) | Service direction, discovery, commission timing |
| [Go-to-market](docs/go-to-market.md) | City sequencing, cold-start strategy |
| [Distribution](docs/distribution.md) | Facebook as a channel — what can and can't be automated |
| [Requirements](docs/requirements.md) | Functional, non-functional, constraints — with IDs |
| [Compliance](docs/compliance.md) | **Botswana EPS licensing & Data Protection Act constraints** |
| [Comparable platforms](docs/comparable-platforms.md) | **What Lynk, SweepSouth and the super-apps got right and wrong** |

### Design

| Document | What's in it |
|---|---|
| [Use cases](docs/use-cases.md) | Actors, use case diagram, detailed specifications |
| [Data model](docs/data-model.md) | ER diagram, entity dictionary, ledger design |
| [Activity diagrams](docs/activity-diagrams.md) | Onboarding, booking, rides, top-up, rentals |
| [Data flow diagrams](docs/dfd.md) | Context, level 1, level 2 |
| [System flowcharts](docs/system-flowcharts.md) | State machines, idempotent posting, callbacks |
| [Architecture](docs/architecture.md) | Components, stack decisions, deployment, security |
| [Booking model](docs/booking.md) | Service direction, discovery, commission timing |

### Planning

| Document | What's in it |
|---|---|
| [Project plan](docs/project-plan.md) | Phases, Gantt, milestones, critical path |
| [Open questions](docs/open-questions.md) | Decisions still outstanding |

---

## Design principles

1. **Breadth at launch, not later.** The differentiator against single-purpose
   incumbents is that one app covers a household's real needs. Launching as a
   single-category app forfeits the whole thesis.

2. **Categories that feed each other.** Renting a room generates a moving job.
   A funeral generates catering and chair hire. Growth compounds within the
   platform instead of being bought from outside it.

3. **Providers pay for outcomes, never for access.** A provider with no bookings
   pays nothing. This is deliberate — the target user cannot afford to advertise
   before they have earned anything.

4. **Trust is the product.** Facebook groups and word of mouth already have
   reach. What they lack is verification, accountability and recourse.

5. **Ship what's available; negotiate later.** Launch on the integrations that
   are self-serve today. Leverage for the harder deals comes from traction, not
   from a pitch deck.

---

## Blockers before implementation

Two external questions have real lead times and should be started immediately.
Both are detailed in [compliance](docs/compliance.md).

1. **Confirm the provider balance sits outside EPS licensing.** By design the
   platform never sits between customer and provider — they settle directly, so
   there is no money transmission. The narrow remaining question is whether
   non-redeemable commission credit counts as a payment account under the
   Electronic Payment Services Regulations 2019. Scoped question for counsel.

2. **Where can data be hosted?** The Data Protection Act 2024 requires a copy of
   personal data to remain in Botswana for the duration of processing. This
   constrains infrastructure before anything else is chosen.

## Status

Pre-build. This repository currently holds specification documents only.
