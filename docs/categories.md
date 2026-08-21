# Categories

## The ecosystem principle

Categories are not chosen for coverage. They are chosen because they **feed each
other**.

Someone who finds a room on the platform needs a truck that same week. A funeral
generates catering, chair hire and transport. A new tenant needs a plumber and a
water delivery.

This is the platform's internal demand engine: one acquired user produces
several transactions across several categories, and each category makes the next
one cheaper to fill. It is also the strongest argument for breadth — the value
is in the adjacency, not the count.

**Implication for sequencing:** launch clusters that reinforce each other rather
than a scattered set of unrelated categories.

### The adjacency pairs, as built

The journey map's stage 7 turns this principle into a feature — the loop prompt,
built 2026-08-21 in `app/lib/core/loop_prompt.dart`. These are the pairs it
fires on. **This table and that file are one statement in two places**; change
them together.

| After | Offer | Where | Copy |
|---|---|---|---|
| Property rentals | Movers & hauling | The rental enquiry | *"Moving in? Find a truck"* — the design's own |
| Movers & hauling | Plumbing | A completed booking | Derived |
| Catering | Hire | A completed booking | Derived |
| Hire | Catering | A completed booking | Derived |

**Rides appears in no row as a source.** It is the connective tissue *into* the
other categories, it is dispatch so it has no browse screen to send anyone to,
and it is the highest-frequency category — a prompt after every ride is noise.

**A pair is an offer, not a guarantee.** Four rules suppress it, three of them
refusals the design states outright: the adjacent category is thin ("don't
prompt into an empty room"), the customer has already booked it, or the only
provider over there is the person they just used. Against the launch supply
figures only the rentals row survives — see
[design-deltas](design-deltas.md#163-the-suppression-rules-mostly-fire-and-that-is-correct).

## Launch categories

**Nine categories at launch.** Revised 2026-08-17 — see
[design-deltas](design-deltas.md#1-nine-categories-not-six). The count is no
longer fixed; categories are rows in a table, not code branches, so adding one
is a data change.

| Category | Slug | Model | Role |
|---|---|---|---|
| **Rides** | `rides` | dispatch | Connective tissue — literally moves customers to the other providers. Independent daily-frequency demand builds habit. |
| **Movers & hauling** | `movers` | browse | Trucks and bakkies moving goods and people. Most urgent demand; smallest provider pool needed to feel useful. |
| **Property rentals** | `rentals` | listing fee | Rooms and houses. Generates moving jobs; recurring listings revenue. |
| **Hairdressing & beauty** | `beauty` | browse | Braiders, barbers, nail technicians, lash and brow artists, makeup artists. Mostly mobile or home-based, matching the no-fixed-premises target exactly. |
| **Plumbing** | `plumbing` | browse | Real demand, verifiable providers. |
| **Electrical** | `electrical` | browse | Licensed trade; the verification badge carries the most weight here. |
| **Tiling** | `tiling` | browse | Portfolio-verified rather than certificate-verified. |
| **Catering** | `catering` | browse | Home cooks. Funerals and weddings — the adjacency engine at its clearest. |
| **Hire** | `hire` | browse | Tents, chairs, sound equipment. |

### Why "Small trades" was split

Plumbing, electrical and tiling were one grouping. They are now three
categories, for two reasons:

1. **No provider should be labelled "small."** The word describes the platform's
   view of them, not their business, and the product is being sold on
   professional credibility.
2. **They do not share a verification flow.** Plumbing needs plumbing
   certification, electrical needs an electrical licence, tiling has no
   certificate at all and is verified on proof of past work. One grouping meant
   one requirements list, which would have been wrong for at least two of the
   three.

"Event hire" became **Hire** and catering was separated out — a funeral needs
both, from different people.

### Per-category verification requirements

Verification attaches to the **category**, not the user
([data-model](data-model.md)), which is what makes the split above workable.

| Category | Documents required |
|---|---|
| Rides | Driving licence · Vehicle registration |
| Movers & hauling | Driving licence · Vehicle registration |
| Property rentals | Proof of ownership · Property inspection |
| Hairdressing & beauty | Identity verification |
| Plumbing | Plumbing certification · Identity verification |
| Electrical | Electrical licence · Identity verification |
| Tiling | Proof of past work · Identity verification |
| Catering | Food handling permit · Identity verification |
| Hire | Proof of equipment ownership · Identity verification |

Rides were debated and deliberately kept in. The argument against was cost: live
tracking, driver vetting and safety systems are heavy, and it means competing
with inDrive from day one. The argument for won — launching without rides makes
the ecosystem a phase-one promise rather than a product, and rides are what move
customers to the other categories.

### Seeding priority

Nine categories raises the cold-start bar further than six did: each one needs
enough supply to not look empty on first open. Fill them in order of provider
access:

1. **Movers & hauling** — easiest access, most urgent demand, and roughly twenty
   trucks across Gaborone and Francistown is enough to be useful
2. **Property rentals** — landlords are findable in the same Facebook groups as
   movers, so acquisition runs as one effort
3. **Hairdressing & beauty**
4. The trades — plumbing, electrical, tiling
5. Catering, hire

Rides are their own recruitment problem and run in parallel.

**Risk to hold in view:** twenty trucks feels like a working app; three
hairdressers feels like an empty one. Nine categories means nine chances to look
empty. Set a minimum supply threshold per category before public launch — see
[go-to-market](go-to-market.md).

**The design's answer to this is not to hide it.** Every category tile shows a
real, specific count — *"New in Gaborone · 4 electricians"* — because a home
screen that conceals low supply looks broken the moment a customer taps in. Two
or three categories looking healthy and the rest looking thin is the design
condition for months, not an edge case.

## Full category list

- Rides
- Movers & hauling (trucks, vehicle owners, goods and people)
- Property rentals
- Hairdressers & beauty — braiders, barbers, nail technicians, lash and brow
  artists, makeup artists
- Tent, chair and sound hire
- Home cooks / catering (funerals, weddings)
- Laundry and ironing
- Small trades (plumbers, electricians, tilers)
- Borehole / water tank delivery

## Phase two

- **Bus ticket booking.** A few months after marketplace launch. Operators pay,
  passengers do not.

## Property rentals — why this works in Botswana

Rentals were initially assessed as a poor fit: no provider completing a job, no
per-booking commission, and a landlord who lists once every year or two.

That assessment was wrong for this market. Botswana rentals are largely **single
rooms in a yard**. A landlord commonly holds around ten rooms, and turnover is
roughly monthly — so a single verified landlord posts continuously, not once
every two years.

That changes the economics entirely:

- KYC cost is incurred **once per landlord** and amortised across dozens of
  listings.
- Revenue is **recurring**, not one-off.
- Verification is the differentiator against Facebook groups, where scams are
  the defining problem.

Model: verify the landlord and the property once, then charge **per listing**,
per room, per vacancy.
