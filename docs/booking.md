# Booking model

Partially specified. What is settled is recorded here; the rest is in
[open questions](open-questions.md).

## Service direction

Every listing carries a **service direction** property, set by the provider:

- **Provider travels to client** — plumber, electrician, mobile hairdresser,
  water delivery
- **Client comes to provider** — salon premises, workshop
- **Both** — provider offers either

The customer selects the applicable direction at the point of booking.

This matters beyond UI: it determines whether a location is required from the
customer, how distance affects matching and search ranking, and whether travel
time is part of the provider's availability.

## Discovery

Providers are found by **browsing category and location**, not by automatic
dispatch — except for rides, which follow the standard ride-hailing request
pattern.

*Status: the split between browse-and-book and auto-match has been discussed but
not formally decided for every category. Treat this as the working assumption.*

## Commission timing

Commission is deducted from the provider's wallet on **completed** bookings
only.

**Undefined:** what marks a booking complete, who marks it, and what happens
when the parties disagree. This is the single largest gap in the specification —
it determines the wallet ledger design, the dispute process, and whether a
provider can game completion. It must be settled before build.

## Not yet specified

- Cancellation, no-show and refund handling
- What happens when a provider's wallet balance is insufficient at completion
- Whether bookings are scheduled in advance, on demand, or both, per category
- Ratings and reviews
