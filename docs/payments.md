# Payments

## Launch decision

**Launch payment methods: EFT and Orange Money.**

**Card gateway: Transaction Junction or PayGate** — one of the two. The choice
between them is not yet made.

Everything else — MyZaka, Smega, aggregators — is phase two, behind the
abstraction described below.

## Principle

Build against what is **self-serve or negotiable today**, behind an abstraction
that lets harder integrations slot in later. Leverage for the harder deals comes
from transaction volume, not from a pitch.

## Rails

### EFT (launch)

Bank transfer. Widely understood in Botswana and requires no merchant
negotiation to begin with.

**Design flag:** plain EFT is not an API. Unless it is instant EFT provided
through the gateway, a top-up arrives as a bank deposit that must be matched to
a provider wallet — which means either manual admin reconciliation or a bank
feed. This is real operational work and should be scoped, not assumed away.
Confirm whether the chosen gateway offers instant EFT before treating this as
automated.

### Orange Money (launch)

Public developer portal, Botswana explicitly supported, documented web payment
API, self-serve signup. The most straightforward integration available.

Primary rail for provider wallet top-ups.

### MyZaka (Mascom) and Smega (BTC) — phase two

No public developer documentation. Both are full wallet products; integration
requires a commercial merchant agreement.

**Feasibility is proven.** Betway operates in Botswana with both integrated, so
the rails exist and work.

**Caveat:** that proves it is *possible*, not that it is *available on the same
terms*. Betway is a large international operator with compliance resources and
high deposit volumes; it likely negotiated direct merchant agreements from a
position a pre-launch startup does not have. Expect those conversations to take
months — which is why they are phase two, once there is volume to negotiate
with.

### Aggregators

Aggregators such as PawaPay offer one API across multiple African mobile money
networks, which would avoid negotiating separate deals. **Botswana coverage is
unconfirmed** — the country list did not surface in research, and Botswana is a
small market. Verify directly before relying on it.

## Cards

Card handling sits **entirely outside the platform**. The user is redirected to
the gateway, the gateway captures the card details, and the platform receives a
callback via API.

This keeps the platform out of PCI-DSS compliance scope — a significant saving
for a small team, and the main reason for the design.

| Gateway | Notes |
|---|---|
| **PayGate** | South African, well established, processes for Botswana merchants. Reported to have offices in Botswana. Acquired by DPO Group — may now be branded DPO PayGate. |
| **Transaction Junction** | South African, works with Botswana companies. Holds a relationship with FNB Botswana, which could act as intermediary. |

The FNB angle is worth weighting: a local bank relationship gives settlement in
pula and a local entity to negotiate with face to face, which in practice
matters more than the technical integration.

**Deciding factor to establish:** which of the two supports instant EFT and
Botswana settlement on terms available to a pre-launch company. That question
likely settles the choice on its own.

## Architecture requirement

Define a **payment provider interface** at the outset. Orange Money and the
chosen gateway are the first implementations; MyZaka, Smega and any aggregator
are later implementations behind the same interface. No provider-specific logic
should leak into booking or wallet code.

---

## To verify

- [ ] Whether TJ and PayGate each support instant EFT for Botswana
- [ ] Botswana settlement terms and fees for both gateways
- [ ] Whether PayGate Botswana now operates under DPO branding
- [ ] Transaction Junction / FNB Botswana onboarding requirements
- [ ] Orange Money Botswana API — sandbox access, settlement terms, fees
- [ ] PawaPay (or equivalent aggregator) Botswana coverage — phase two only
