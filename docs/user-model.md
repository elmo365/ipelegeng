# User model

## Structure

There is **one account type at the root: User.**

Customer and provider are **roles on that account**, not separate account types.
The same person can be both — which matters in this market: a driver still needs
a plumber, and a landlord still needs a moving truck.

```
User
├── role: Customer          (default, available to every account)
├── role: Provider          (opt-in)
│   └── ProviderCategory[]  (rides, movers, landlord, hairdresser, trades, …)
└── role: Admin             (internal)
```

`ProviderCategory` is an attribute underneath the provider role, not a distinct
account. Landlord is one of these categories, not a special user type — it
simply carries a different monetization model.

## Verification is per category

A user does **not** verify once and unlock all categories. Verification is
required **per category**, because requirements genuinely differ:

| Category | Verification requirements |
|---|---|
| Rides | Driving licence, vehicle registration |
| Movers & hauling | Driving licence, vehicle registration |
| Property rentals | Proof of ownership, property verification |
| Small trades | Trade certification where applicable |
| Other services | Identity verification |

Two consequences:

- A verified driver who later wants to hire out tents verifies again for that
  category.
- An already-verified user adding a second category is a much easier
  conversation than onboarding a stranger — this is a real growth path, not just
  a compliance step.

## KYC cost

KYC costs money per verification and adds friction before the provider has
earned anything. This is accepted as worth paying, particularly for landlords,
where one verification is amortised across many recurring listings.

---

## Open

- Whether verification is mandatory before listing, or an opt-in "verified"
  badge with unverified providers still visible.
- Who performs KYC — manual admin review, or a third-party provider.
- Whether a provider can hold a wallet balance across categories or per
  category.
