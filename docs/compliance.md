# Regulatory & compliance constraints

> **This is not legal advice.** Both items below need a Botswana-qualified
> lawyer before build decisions are locked. They are here because they are
> *architectural* constraints, not paperwork — getting them wrong means
> rebuilding, or not launching.
>
> **Item 1 is largely designed out already** — the platform never sits between
> customer and provider. What remains is a narrow, answerable question about the
> provider balance, plus a set of design rules that must hold to keep it
> answerable.

---

## 1. Payments regulation — largely designed out, one residual question

### What the design already avoids

Two structural choices remove most of the regulatory surface, and they were
deliberate:

1. **The platform charges providers only** (CON-1)
2. **All customer↔provider payment happens outside the app** — cash or the
   parties' own mobile money

Together these mean the platform **never holds, transmits, or settles money
between two users.** No escrow, no float, no payouts, no settlement engine. The
activities that most clearly constitute payment services — money transmission,
holding customer funds, executing transfers on behalf of others — are simply not
present.

That is the right architecture and it should not be traded away for
convenience later. It is also why there is no settlement component in
[architecture](architecture.md).

### The one residual question

The Electronic Payment Services Regulations 2019 (Statutory Instrument No. 2)
cover issuance of e-money and **its deposit on payment accounts**, not only
transfers between parties. Operating an electronic payment service without a
Bank of Botswana licence is a criminal offence under Regulation 4(1).

So the remaining question is narrow but real: **when a provider deposits money
with the platform and holds a balance, is that balance a payment account?**

The answer turns on redeemability. Most regimes distinguish stored value —
which is e-money — from prepaid credit for the issuer's *own* services, which
generally is not. Ipelegeng's balance is intended to be the latter.

### Design rules that keep it that way

These are **binding constraints, not preferences.** Each one, if broken, moves
the balance toward looking like stored value:

| Rule | Why |
|---|---|
| **No cash-out, ever** — including on account closure | Redeemability is the defining feature of e-money |
| **No transfer between users** | Transferable value is a payment instrument |
| **Balance pays Ipelegeng fees only** — never a third party | Paying third parties is money transmission |
| **No customer-side balances at all** | Customers never fund an account |
| **Top-up amounts kept modest; no incentive to hold large balances** | Large float attracts prudential interest |
| **Don't call it a "wallet" in the product** | "Commission credit" or "advertising credit" describes what it is; "wallet" invites the wrong characterisation |

> **The rule most likely to be broken under pressure is the first one.** A
> provider who tops up P500, does two jobs, and quits will ask for their money
> back. Refusing is uncomfortable; refunding to cash is exactly the feature that
> could reclassify the product. Decide the policy now, in writing, and put it in
> the provider terms — not in the moment when someone is upset.

### What still needs counsel

The reasoning above is sound but it is not a legal opinion, and the penalty for
being wrong is criminal rather than civil. Get a Botswana-qualified lawyer to
confirm, specifically:

- [ ] Does non-redeemable, non-transferable prepaid credit for the platform's
      own services fall outside the EPS Regulations 2019?
- [ ] Does Botswana recognise a "limited network" or "own services" exclusion,
      and does this fit it?
- [ ] Any obligations under the Financial Intelligence Act 2022 arising from
      taking provider deposits, even outside EPS licensing?
- [ ] Does receiving EFT deposits into a company bank account for prepaid
      credit change the analysis?

This is a scoped question a lawyer can answer relatively quickly — not an open
research project. **Ask it before backend design freeze**, but it should no
longer be treated as a project-threatening unknown.

## 2. Data Protection Act 2024 — including a data residency requirement

The Data Protection Act 2024 (Act No. 18 of 2024) was assented to on 24 October
2024, published 29 October 2024, and came into force on **14 January 2025**,
repealing and re-enacting the 2018 Act. It broadly follows the GDPR approach.

Penalties are severe: fines up to **BWP 50 million or 4% of global annual
turnover**, whichever is higher, with imprisonment for certain offences —
reported prison terms range from three to twelve years for some violations.

### Requirements with architectural consequences

| Requirement | Consequence for Ipelegeng |
|---|---|
| **Data residency** — a copy of personal data must remain in Botswana for the duration of processing | **Hosting decision is constrained.** A single foreign cloud region is not sufficient on its own. Needs either local hosting or a replicated copy held in Botswana. Settle before choosing infrastructure. |
| **Consent as a central principle**; conditions for valid consent | Explicit, granular, withdrawable consent at signup and at each KYC step. Consent state must be stored and versioned, not assumed. |
| **Data minimisation, storage limitation, accuracy** | KYC documents cannot be kept indefinitely "just in case". Define a retention schedule per document type. |
| **DPIA for high-risk processing** | Live GPS tracking of riders and drivers is high-risk processing. A DPIA is likely required before launch. |
| **Data subject rights** — access, rectification, erasure, portability, objection | Build export and deletion as features, not manual admin tasks. Erasure conflicts with ledger immutability — see below. |
| **Breach notification** | Notification path to the Commission and affected users, with detection and logging to support it. |
| **DPO appointment** for large-scale or sensitive processing | Organisational, but plan for it. |

### The erasure vs. immutable-ledger conflict

Data subject erasure rights collide directly with the immutable financial ledger
in [data-model](data-model.md). Standard resolution: **separate identity from
transactions.** The ledger references a pseudonymous account ID; personal data
lives in a separate store that can be erased without destroying financial
history. Design this in from the start — retrofitting it is very expensive.

### KYC has a local advantage

Botswana's national ID system already allows agents to verify customers and
conduct basic KYC — a foundation to build on rather than around. Worth
investigating before contracting a third-party verification vendor.

---

## Open compliance questions

- [ ] Does non-redeemable commission credit fall outside EPS licensing? **Counsel required — narrow question.**
- [ ] Financial Intelligence Act 2022 obligations from taking provider deposits?
- [ ] Written refund/closure policy for unused balance — decide before launch, not in the moment.
- [ ] Where will data be hosted to satisfy the Botswana residency requirement?
- [ ] Is a DPIA required for GPS tracking, and who conducts it?
- [ ] Retention schedule per KYC document type
- [ ] Can national ID verification be used directly, and under what terms?
