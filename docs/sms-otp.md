# SMS and OTP — testing it, and paying for it

**Asked on 2026-08-21: "the test on account creation is seeded data, but SMS —
can it be done, or do we need a paid service?"**

Two separate answers, and conflating them is what makes this look blocked when
it is not:

- **Testing needs no paid service.** Not for unit tests, not for widget tests,
  and not for a real end-to-end account creation on a handset.
- **Production delivery is paid**, at any volume worth having. There is no free
  route that survives real users.

---

## 1. Testing — four levels, none of them costing anything

### Level 1 · The state machine (today)

`DemoOtpVerifier.isCorrect` is `code.length == 4`. Every four-digit string
passes. This is deliberate and it is *enough* for what the current tests claim:
that OTP is unskippable, that attempts are limited, that resend cools down,
that back is blocked mid-round-trip.

It proves nothing about delivery. See
[`test-strategy.md`](test-strategy.md#what-a-green-suite-does-not-mean) for the
full table of what each stub hides.

### Level 2 · A fixed code outside production

The level account-creation E2E should run at. A known code — say `000000` —
accepted for seeded accounts in dev and staging only, so a test can register,
verify and reach Home without a network.

**Two things this must have, or it becomes a back door:**

- Gated on a **build-time** flag, not a runtime one, so the branch is not
  compiled into a release at all.
- A test that **fails if a release build would accept it**. The rule is
  worthless as a comment; it has to be enforced the way
  `build_order_test.dart` enforces the phase list.

### Level 3 · A provider sandbox

Tests the *integration* — credentials, request shape, error handling, delivery
receipts — without sending a real message or paying.

- **Africa's Talking** has a sandbox with a simulator, and is one of the
  candidates for production here anyway.
- **Twilio** has test credentials and magic numbers that produce each failure
  mode on demand.
- **Firebase Auth** has allow-listed test phone numbers with fixed codes, free
  and unlimited.

This is where the real client gets written and where its failure paths get
exercised, and it is still free.

### Level 4 · A real SIM, for a handful of true end-to-end runs

If a genuinely real SMS must arrive on a real handset before launch: a prepaid
SIM in a USB GSM modem, or an Android phone acting as a gateway, driven by AT
commands or a tool like Gammu. **Cost is airtime**, nothing else.

**Only for a few smoke tests.** Consumer SIMs sending application traffic are
throttled or cut off by the networks, deliverability is poor, and using one in
production would be both unreliable and a breach of the SIM's terms.

**So: nothing about testing account creation requires a paid service.** Levels
2 and 3 cover it, and level 4 covers the "did a message really arrive" question
for the price of airtime.

---

## 2. Production — the part that costs money

No free option survives contact with real users. The realistic routes, roughly
in order of how quickly they can be stood up:

| Route | Shape | Watch |
|---|---|---|
| **Firebase Auth phone** | Free daily quota, then billed. Handles the whole verify flow | Ties identity to Google, adds Play Integrity / reCAPTCHA, and the quota does not scale |
| **Pan-African aggregator** (Africa's Talking, Clickatell, Infobip) | Per-message, regional pricing, one integration for several countries | Confirm Botswana route quality specifically — coverage varies by network |
| **Global aggregator** (Twilio, Vonage) | Most reliable, best tooling | Usually the most expensive per message into this region |
| **Direct with the MNOs** (Mascom, Orange Botswana, BTC) | Cheapest per message at volume | Needs a business account and a negotiation per network; slowest to arrange |

**Prices move and vary by route — get current quotes rather than trusting any
figure written here.** What matters for the decision is the shape, not a number
this document would be wrong about within a quarter.

### The cost finding that matters more than the per-message price

The design does not ask for OTP once at registration. It asks for **"an OTP on
every fresh login"**, and the Security screen promises it in those words. That
makes SMS a **recurring per-user cost**, not a one-time acquisition cost, and
in a small market that is the number that decides whether this is affordable.

Three things already reduce it, and one would reduce it further:

- **The session persists.** `session_store.dart` means a reopen is not a fresh
  login, so the common case sends nothing.
- **Biometry unlocks** rather than re-authenticating, which is exactly why it
  was built that way.
- **A "fresh login" is genuinely rare** — a new device, a reinstall, or an
  explicit sign-out.
- **Flash-call verification** would cut it further: the system places a call
  the user never answers and the last digits of the number *are* the code. It
  is much cheaper than SMS and widely used in exactly this kind of market. It
  needs a different screen, so it is a design question as well as a cost one.

**WhatsApp** is the other lever, and this app already plans WhatsApp booking
updates and collects consent for them on the consent screen. Meta bills per
conversation, which in some markets undercuts SMS.

---

## 3. The recommendation, for Botswana

Asked directly: *"I see options — so what can work for us? I am in Botswana."*
A staged answer, because the right choice at launch is not the right choice at
volume.

### Launch on Firebase Auth phone verification

Not because it is the cheapest per message — it is not — but because of what it
lets you skip:

- The **free quota covers early volume**, and it bills only past that.
- It handles the **whole flow**: send, verify, rate-limit, anti-abuse. No
  client to write against three different network APIs.
- **No commercial negotiation, and no sender-ID registration, to launch.** That
  matters more than it looks: an aggregator contract or an MNO agreement is a
  *lead-time* item. It can hold a launch date hostage in a way that writing
  code cannot.
- Google buys global routes, so Botswana delivery works without anyone here
  arranging it.

**What it costs you, stated plainly:** identity is tied to Google; Play
Integrity and reCAPTCHA come with it; deliverability is not yours to control or
debug; and the price curve past the quota is steep enough that it is a bridge,
not a destination.

### Move to a SADC aggregator when volume justifies it

Botswana's routes are best served from South Africa rather than from East
Africa. The realistic shortlist to **get live quotes from** — not a ranking,
because pricing and route quality both move:

- **Clickatell**, **BulkSMS.com**, **SMSPortal** — South African, established
  Botswana routes, SADC-friendly billing.
- **Africa's Talking** — excellent, but strongest in East and West Africa.
  Confirm the Botswana route specifically before assuming parity.
- **Infobip / Twilio / Vonage** — most reliable and best tooled, usually the
  most expensive into this region.
- **Direct with Mascom, Orange Botswana and BTC** — cheapest at real volume,
  slowest to arrange, and it is three negotiations rather than one.

### The lever worth pushing hardest: WhatsApp

**WhatsApp penetration in Botswana is very high**, and this app is already
built around that fact — the consent screen collects *"Booking updates on
WhatsApp"* as its own opt-in, and the design treats WhatsApp as a first-class
channel rather than a fallback.

Using it for **verification** as well as updates would reuse a channel the user
has already consented to, on a network they already trust, and in this market
it is likely to be both cheaper and more reliable than SMS. It is billed per
conversation by Meta rather than per message.

It needs a Meta Business account and template approval, so it is not zero
lead-time either — but unlike an MNO agreement it is a form rather than a
negotiation.

### What has to be verified rather than assumed

Two things this document deliberately does not state as fact, because anything
written here would be stale within a quarter:

1. **Current pricing and Botswana route quality.** Get live quotes.
2. **Whether a sender ID must be registered** with the networks or BOCRA for
   bulk SMS. Check it early — it is lead time, not code.

---

## Open questions

- **Which provider**, and whether the phase-0 plan (email + password, deferring
  SMS — see [`open-questions.md`](open-questions.md)) still holds now that the
  entry flow is built against phone-as-identity.
- **Flash-call instead of, or alongside, SMS.** A cost decision that changes a
  screen, so it belongs to the design as much as to the backend.
- **Sender ID registration.** Bulk SMS in Botswana may require registering an
  alphanumeric sender ID with the networks or BOCRA. Needs checking before a
  launch date is set, because it is a lead-time item rather than a code one.
- **What a failed delivery does.** Every route above fails sometimes, and the
  design has no screen for "the code never arrived" beyond resend. The resend
  cooldown is built; the dead end after three resends is not.
