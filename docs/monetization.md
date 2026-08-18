# Monetization

## The firm constraint

**The platform charges service providers only. Never the consumer.**

This holds in every category and on every transaction. For bus tickets, the
operator pays, not the passenger. For rentals, the landlord pays, not the
tenant.

## The model is flexible by category

There is deliberately no single revenue mechanism forced across all categories.
The model fits the category, subject to the constraint above.

### Wallet + commission (booking categories)

Used for rides, movers, hairdressers, trades, catering, hire, laundry, water
delivery.

Providers load a wallet balance. A commission percentage is deducted per
**completed** booking.

Why this rather than a flat monthly subscription: a provider with no bookings
pays nothing, and can see that their money is only ever spent on real customers.
For a target user who cannot afford to advertise before earning, that difference
determines whether they sign up at all. The model is familiar locally from
inDrive.

### Pay-per-post (property rentals)

Landlords pay per listing. Tenants browse free.

Fits because there is no booking to take a commission on, and because listing
volume is high and recurring — see [categories](categories.md#property-rentals--why-this-works-in-botswana).

### Operator-pays (bus tickets, phase two)

Bus operators pay. Passengers pay face value.

---

## Rates and VAT

Set 2026-08-17 by the design work — see
[design-deltas](design-deltas.md#2-money-figures-the-specs-left-unset).

| | |
|---|---|
| Ride commission | **8% of the fare** |
| VAT | **14%, charged on the fee** — never on the customer's money, which never passes through the platform |
| Posting | **Two lines, always.** Fee and VAT post as separate journal entries in one transaction, never bundled into one opaque figure. |

The rate is read from the category at booking time and copied onto the booking,
so a later rate change cannot retroactively alter what was owed. The VAT rate is
effective-dated in its own table, not a constant — a historical transaction has
to stay reconstructable at the rate that applied on its date
([database](database.md#fee-and-vat-are-two-entries-in-one-transaction)).

### A P120 ride, in full

| | |
|---|---|
| Customer pays the driver, cash or Orange Money | P120.00 |
| Ipelege commission · 8% of the fare | −P9.60 |
| VAT · 14% of the commission | −P1.34 |
| **Deducted from wallet balance** | **P10.94** |
| **Driver keeps** | **P120.00** |

Stating it this way round is the point. The driver keeps the whole fare in hand
and pays P10.94 of pre-loaded credit for having been sent the job — which is why
the balance reads as a meter and not as an account someone is owed money from.

## Reversals

**A cancellation does not refund itself.** Reversal only matters once a fee has
already been deducted — a ride called off after dispatch, a completion the
customer disputes, a rental listing withdrawn after publishing. In none of those
cases does the credit come back on its own.

A reversal is a separate, reviewed, adjudicated event. Until it is confirmed the
balance does not move by a thebe, and the ledger carries a pending marker with
**no amount** — an amount would imply money already returned. A confirmed
reversal mirrors the original line for line, VAT included as its own credit
note.

Full state machine and rules:
[system-flowcharts](system-flowcharts.md#reversal-state-machine).

---

## Open

- **Per-listing price for rentals — not set.**
- **Minimum wallet top-up — not decided.**
- Whether commission varies by category — not decided. Non-ride categories have
  no rate at all yet; only rides is set.
- Whether a no-show fee applies, and who bears it given the platform never
  touches the customer's money.
- The reversal rules listed in
  [system-flowcharts](system-flowcharts.md#open) — who may raise one, within
  what window, whether any reverse automatically, and whether partial reversals
  exist.

> **Naming.** [compliance](compliance.md) lists *don't call it a "wallet" in the
> product* as a **binding constraint**, on the grounds that the word invites the
> wrong regulatory characterisation. The design deliberately reversed this and
> calls it the wallet balance, defending the position structurally instead — no
> withdraw button, no "available balance" framing, disclaimer on the card
> itself. **This is not settled**, and it belongs in the same question to
> counsel as the EPS licensing position. See
> [design-deltas](design-deltas.md#3-wallet-balance-not-commission-credit).
