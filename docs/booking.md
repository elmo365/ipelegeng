# Booking model

Partially specified. What is settled is recorded here; the rest is in
[open questions](open-questions.md).

## Service direction

Every listing carries a **service direction** property, set by the provider:

- **Provider travels to client** — plumber, electrician, mobile hairdresser,
  water delivery
- **Client comes to provider** — salon premises, workshop
- **Both** — provider offers either

The customer selects the applicable direction at the point of booking. The
design writes that choice as a two-option radio set, and the copy is settled —
confirmed against `ipelege-ds-2-customer.dc.html` on 2026-08-21:

| Option | The line under it |
|---|---|
| Comes to you | Provider travels to your location |
| You go to them | Service is at their premises |

**"Both" is never one of those two.** It is what a *listing* may offer; the
customer still picks one. The browse filter uses the same pair plus "Any
direction".

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

## Ratings and reviews

Partially settled by the design, and built 2026-08-21.

Settled: a **five-star** scale, an **optional** free-text comment, and a
skippable ask offered after `COMPLETED`. The screen states why it is asking —
*"Your rating is the only signal a new provider has"* — which is the same
argument the listing detail makes from the other side, and the reason the app
never synthesises a rating for a provider with no jobs.

One rule this repo adds and holds: **nothing is pre-selected.** The artboard
renders at four stars the way its booking artboard renders at `REQUESTED` —
that is the demo's state, not a default — so submit is disabled until a star is
chosen. See [design-deltas.md](design-deltas.md) §15.

Still undefined: how a rating aggregates onto a listing, whether a provider may
reply, whether a review can be edited or withdrawn, and what moderation applies
to the comment.

## Not yet specified

- Cancellation, no-show and refund handling
- What happens when a provider's wallet balance is insufficient at completion
- Whether bookings are scheduled in advance, on demand, or both, per category —
  the design's `WHEN` field states a time and offers no picker, which is this
  gap showing on screen
