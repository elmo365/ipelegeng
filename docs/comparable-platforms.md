# Comparable platforms — what worked, what didn't

Research into platforms that attempted something close to Ipelegeng, used to
answer open questions with evidence rather than instinct.

**Read this before locking the launch scope.** Several findings contradict
decisions currently in the spec. They are presented as evidence, not verdicts —
but the contradictions are real and should be argued with, not skipped.

---

## Case 1 — Lynk (Kenya, 2015–2022) · *the closest analogue*

A Nairobi marketplace connecting informal, blue-collar service providers to
customers. Same target user, same continent, same thesis. It raised a Series A,
was backed by Safaricom and Lateral Capital, vetted over 1,000 workers — and
wound down, eventually being acquired by Eden Life. Eden Life then paused its
own consumer business in both markets.

**This is the single most relevant precedent to the project, and it failed.**

### What Lynk learned

**Vetting alone was not a product.** The founding thesis was that information
asymmetry was the problem — make vetted professionals visible and the market
works. It didn't hold: too many jobs still went wrong with well-vetted
individuals, and customers were not willing to pay for vetting and convenience
on their own.

> **Direct challenge to Ipelegeng.** "Trust is the product" is pillar three of
> the [solution](solution.md). Lynk tested that proposition in a comparable
> market and found customers wouldn't pay for it. Worth having an answer.

**Lead-gen vs full-service.** Lynk found that a lead-generation model — connect
the parties, step back — did not satisfy customer demand in the Kenyan context,
and moved to full-service, taking responsibility for delivery. Thumbtack reached
unicorn status on lead-gen in the US; the same model did not transfer.

> **Sharpest tension in the whole spec.** The compliance-driven design in
> [compliance](compliance.md) pushes Ipelegeng *toward* lead-gen: customer pays
> provider directly, platform touches no money, no escrow, no recourse over
> payment. That is the model Lynk abandoned. Regulation pushes one way, market
> evidence pushes the other. **This needs a deliberate decision, not a default.**

**Ratings created a rich-get-richer trap.** Displaying ratings and job counts
worked *too* well. Customers consistently chose the highest-rated provider, so
new providers couldn't get a first job — and many churned after failing to win
their first few. A cold-start problem *inside* the platform, not just at launch.

> **Design consequence:** if you build ratings (FR-3.8), you need a new-provider
> boost — guaranteed placement, a "new" badge treated positively, or rotating
> first-job allocation. Otherwise provider churn is built in.

**Quote-based flows were too slow.** When a customer requests a service, they
want it *now*. Providers were slow to quote — busy, unfamiliar with quoting, or
discouraged by past failures. For beauty services particularly, customers wanted
immediate booking, not a delayed quote.

> **Design consequence:** `pricing_type = quote-on-request` (FR-2.4) is a
> liability for exactly the categories in your launch set. Default to fixed or
> from-pricing with instant booking; treat quoting as the exception.

**Too much variety broke the model.** Customers requested wildly varied and
sometimes impossible services; providers accepted jobs they couldn't do. Lynk
moved to standardised service definitions.

> **Design consequence:** define services as a structured catalogue per
> category, not free-text listings.

**Commission ceiling.** Lynk charged 10% and found Kenyan buyers unwilling to
pay more than that for higher quality and reliability, against roughly 20% at
Uber and 30% at TaskRabbit. Note Lynk charged the *customer* and deliberately
chose not to charge providers, on the reasoning that providers had least ability
to pay — the opposite of Ipelegeng's CON-1.

> **Useful signal for the unset commission rate.** 10% is a market-tested
> ceiling in a comparable economy. But it is a *customer-side* figure; the
> provider-side ceiling is a different question and is not answered here.

**The competitor that actually mattered was Facebook.** Lynk's reach was
constrained by Facebook Marketplace and Instagram, which had wider and more
trusted reach. Word-of-mouth referral remained dominant, and rating- and
review-based services struggled to take hold.

> **Direct challenge to the rentals thesis.** [categories](categories.md) argues
> rentals win because Facebook groups are a bad experience. Lynk's experience
> suggests "bad experience but everyone is already there" beats "good experience
> nobody knows about." Being better is not automatically enough.

### The wider Kenyan graveyard

KibaruaNow (Mercy Corps-backed) shut down. Taskwetu closed within months of
launch. Kisafi made little headway. TaskGuru never got past launch.

This is not one company failing. It is a category struggling in an African
market with structural similarities to Botswana's.

---

## Case 2 — SweepSouth (South Africa, 2014–) · *the survivor*

Still operating, over 6,500 active professionals, 250,000+ clients and 2.5
million services facilitated as of May 2025.

**Its sequencing is the finding.**

Launched 2014 doing **one thing**: domestic cleaning. It stayed essentially
single-category for roughly a decade, only broadening into garden maintenance,
car washing, pool and window cleaning with a 2024 brand refresh, and childcare,
elder-care and office cleaning across 2024–2025. Ten years of depth before
breadth.

**Geographic expansion is where it got hurt.** It entered Kenya in 2019 and
Nigeria in June 2022, then closed Nigeria five months later and exited Kenya.
Former staff described the expansions as under-resourced, with constant budget
and headcount cuts and shoddy operational setup. Acquiring an existing local
platform (FilKhedma in Egypt) went better than building from scratch.

**Local adaptation was non-negotiable.** In Kenya, mobile money had to be built
in as the default payment method rather than treated as one gateway among
several — around 96% of Kenyan households have a mobile money account. Payment
assumptions do not travel.

> **Supports** the Orange Money-first decision in [payments](payments.md).
> **Also supports** launching in two cities at once only if genuinely resourced
> — SweepSouth's failures were about spreading thin, not about ambition.

---

## Case 3 — Gojek, Grab, WeChat · *the super-app pattern*

The model Ipelegeng is aiming at. The consistent pattern is that **none of them
launched as a super app.**

Gojek began in 2010 as a motorcycle-taxi call service and added GoFood, GoPay
and GoSend years later, once the driver-partner network was proven. Grab started
with ride-hailing and expanded into financial services, groceries and insurance
only after ride-hailing had won trust across markets. WeChat started as
messaging.

The reasoning generally given: dense supply in one category produces a good
experience and habit; thin supply across many produces bad first impressions. A
customer who books a ride and waits four minutes becomes loyal; the same
customer who books a plumber and waits three days leaves a one-star review — in
the same app.

> **Caveat on sources.** Much of the super-app "how to" material online is
> content marketing from clone-script vendors and should be discounted
> accordingly. The underlying factual claim — that Gojek, Grab and WeChat each
> began single-service — is well attested independently. The strategic advice
> built on it is weaker evidence, but it points the same direction as
> SweepSouth's actual history and Lynk's actual failure.

---

## Case 4 — the Botswana competitive picture is fuller than assumed

Two corrections to assumptions currently in the spec.

**Rides are not an inDrive-only market.** Gaborone has inDrive, Yango and Bolt
operating, with reporting on pressure this puts on traditional taxi operators
and on the absence of clear local regulation. The spec currently frames rides as
competing with inDrive. It is three international operators, and the local
regulatory position for ride-hailing is itself unsettled — worth checking
whether that creates obligations for a local entrant.

**Rentals are not Facebook-only.** A Botswana rental app, **Boroko**, is on
Google Play offering listings across the country with filtering by city, price
and property type, and describing its listings as verified. Property24 Botswana
and 4321property also operate rental portals.

> **This matters because rentals were justified as a category on the basis that
> the market runs through Facebook groups with no verification.** Verified
> digital listing already exists in Botswana. The room-in-a-yard segment may
> still be underserved — Boroko and Property24 skew toward formal properties —
> but that is now a hypothesis to check, not an established gap. Worth
> downloading Boroko and looking at what it actually lists.

---

## What this evidence says about open questions

| Open question | Evidence-based answer |
|---|---|
| **Six categories at launch?** | Evidence runs strongly against. Every successful super app went deep on one first; SweepSouth took a decade; Lynk's variety problem contributed to its failure. **Recommendation: build the six-category model, seed one or two deeply.** |
| **Commission rate** | 10% is a tested ceiling in a comparable market — but customer-side. Provider-side willingness is untested. Start at or below 10% equivalent. |
| **Ratings and reviews** | Build them, but with an explicit new-provider mechanism, or you manufacture provider churn. |
| **Quote vs fixed pricing** | Default to fixed/from-pricing with instant booking. Quoting was a major Lynk failure point. |
| **Listing structure** | Structured service catalogue per category, not free-text. |
| **Which category to seed first** | Movers still defensible — urgent demand, small provider pool, in-person signup. Consistent with Lynk's finding that customers want immediate booking. |
| **Lead-gen or full-service** | **Unresolved and important.** Regulation pushes to lead-gen; Lynk's evidence says lead-gen underperformed in an African market. Decide deliberately. |
| **Is rentals a real gap?** | Verify against Boroko before treating it as one. |

---

## The uncomfortable summary

The closest analogue to this project — same continent, same informal-sector
thesis, better funded — did not survive. The nearest survivor did it by going
narrow for a decade. The super-app model Ipelegeng aims at was reached by
companies that spent years single-service first.

None of that means don't build it. Botswana is not Kenya, the room-rental
dynamic is genuinely local, and Lynk's specific mistakes are documented well
enough to avoid. But it does mean **the launch-wide, six-category, trust-as-the-
product plan is the version of this idea that has already been tried and has
gone badly** — and the spec should either change or answer why Botswana is
different.

## Sources worth reading in full

- Lynk post-mortem, The Flip (Africa) — "Lessons Learned The Hard Way"
- Jobtech Alliance on Lynk's shift from auction to standardised services
- Adam Grunewald (Lynk founder), "Transforming the informal sector, and making mistakes"
- TechCabal on SweepSouth's Nigeria and Kenya closures
