# Ipelege — design brief

The brief that was pasted into Claude Design to start the UI work. Archived here
from the design project's `uploads/`. **Historical** — the design that came out
of it has moved past this brief in several places; see
[docs/design-deltas.md](../docs/design-deltas.md).

---

## What it is

**Ipelege** — a multi-category services marketplace for Botswana, launching in
Gaborone and Francistown. Connects informal service providers who have no fixed
premises with customers.

**The name matters for the design.** *Ipelege* is the Setswana imperative for
self-reliance addressed to **one person** — carry yourself. The plural form,
*Ipelegeng*, addresses everyone and is used as the motto. So the product voice
is singular and personal: it speaks to the individual provider or customer, not
to a crowd. Copy should follow that — "your bookings", not "our community".

Mobile app in Flutter, Android-first.

## Six launch categories

Rides · Movers & hauling · Property rentals · Hairdressing & beauty · Small
trades · Event hire

## The model in one paragraph

Customers browse and book free — they are **never** charged a platform fee.
Providers load a **commission credit** balance and a commission is deducted per
completed booking. Property rentals differ: landlords pay per listing, tenants
browse free. Payment for the service itself happens **directly between customer
and provider, outside the app**.

---

## Non-negotiable constraints

| Constraint | Why |
|---|---|
| **English only** | Setswana localisation not planned — few libraries ship the language files, and half-translated reads as broken |
| **Pula (BWP) formatting**, Botswana date formats | Set explicitly, not inherited from device locale |
| **Low-end Android, 3G, target under 30 MB** | The provider base is not on flagship phones |
| **Call it "commission credit", never "wallet"** | Regulatory — a wallet implies stored value and invites the wrong characterisation |
| **No customer-side balance anywhere** | Customers never fund an account |
| **Verified badge must mean something** | Verification is per category, not per user |

---

## Screens to design

### Customer
1. Onboarding — phone + OTP, with consent capture
2. Home — six categories, location context
3. Category browse — filters for location and service direction
4. Listing detail — provider, verification status, price, direction options
5. Booking request — direction, time, location
6. Booking status — through the lifecycle to completion confirmation
7. Ride request — pickup/destination, driver assignment, live tracking map
8. Rate and review

### Provider
9. Become a provider — category picker showing per-category requirements
10. KYC upload and verification status
11. Create listing — including the service direction control
12. Booking inbox — accept/decline, mark complete
13. Commission credit — balance, top-up via Orange Money / EFT / card
14. Rental listing flow — per room, with listing fee confirmation

Admin panel is a separate exercise; stack not yet chosen. Skip for now.

---

## The five design problems that actually matter

These are the ones worth solving deliberately rather than defaulting.

**1. Six categories, thin supply.**
At launch some categories will have very few providers. A customer who opens the
app and finds three hairdressers and no trucks does not come back. First
impressions are spent once. How does the home screen stay credible when supply
is uneven — and how does a thin category communicate honestly rather than look
abandoned?

**2. The new provider with zero ratings.**
Lynk (Kenya, closest comparable, since wound down) found customers always chose
the highest-rated provider, so new providers never got a first job and churned.
Ratings worked *too* well. The design needs to give new providers a real chance
without faking credibility.

**3. Payment happens outside the app.**
This is unusual and genuinely confusing. The customer books in-app, then pays
the provider directly in cash or their own mobile money. The UI must make that
unambiguous at the right moment — never implying the app took payment, never
leaving the customer wondering whether they already paid.

**4. Commission credit must not look like a bank balance.**
It is non-redeemable, non-transferable, and can only be spent on platform fees.
The interface should make that obvious rather than surprising someone later when
they try to withdraw.

**5. Service direction is a first-class concept.**
Every listing is "I come to you", "you come to me", or both, and the customer
picks at booking. It changes what the app asks for (a location or not) and it
appears in browse, listing detail and booking. It needs a clear, compact visual
treatment that survives being shown everywhere.

---

## Naming in the UI

- App name everywhere: **Ipelege**
- Motto, where used: **Ipelegeng**
- Never mix them, and never pluralise the app name

## Tone

The users are working people running real businesses — truck owners,
hairdressers, landlords with rooms to let. Not a lifestyle app, not a startup
aesthetic. Legible, fast, trustworthy. Trust is the product being sold, so the
interface has to feel solid rather than clever.

---

## Full specification

21 markdown documents covering requirements (with stable IDs), use cases, ER
diagram, activity diagrams, DFDs, system flowcharts, architecture, compliance
and project plan — in the repo at
https://github.com/elmo365/ipelegeng once pushed.
