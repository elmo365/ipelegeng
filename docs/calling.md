# Calling between customer and provider

**Raised 2026-08-21: once a service is chosen and both sides have accepted,
they need to be able to talk. What are the options — is Matrix overkill?**

Short answers, then the reasoning:

- **Matrix is overkill.** You would run a homeserver, a federation surface and
  a second identity model to get one feature this app needs.
- **Build both a phone call and an in-app call.** Decided on competitive
  parity — inDrive and the other ride apps in this market offer both, and a
  provider comparing them will notice. See the recommendation below.
- **The dialer ships first and stays as the fallback.** It costs nothing and
  works with no data at all.
- **WebRTC is the parity feature**, and the two hard parts are already in
  place — a VPS for signalling and TURN, and FCM to wake a handset whose app is
  closed.

> The sections below argue in-app calling on **privacy** grounds and find that
> case weak, because the design gives numbers away in `ACCEPTED`. That analysis
> stands and is kept as written. The decision was made on a different and
> stronger basis, and the recommendation section is where it lands.

---

## The design has already answered half of this

Two things are already decided in the canvas, and they narrow the field before
any technology is considered:

1. **The booking status screen already draws a call button.** It is in the
   provider row, it is `Icons.call`, and it is inert — one of the ten actions
   with nowhere to go.
2. **Numbers are already shared on acceptance.** The `ACCEPTED` state's body is
   verbatim: *"Today at 14:00, at Plot 4521, Block 8. **Kabelo has your
   number.**"*

That second one matters more than it looks. The usual reason a marketplace
builds in-app calling is **number privacy** — so a provider does not keep a
customer's personal number forever. This design does not claim that privacy, it
explicitly gives it away. So in-app calling here cannot be justified on privacy
grounds without first changing the design's own promise.

---

## The options, honestly ranked

### 1. The system dialer — `tel:` · **recommended for launch**

The call button opens the phone app with the number filled in.

- **Zero infrastructure, zero running cost, zero new permissions.**
- Works on every handset, on any network, with no data connection.
- Consistent with what the design already tells the user.
- The caller pays airtime, which in this market is a real cost to them and the
  main argument against.
- No call metadata for a dispute, and no way to un-share a number later.

**This is the honest first step**, and it is a two-line change once the booking
flow is real.

### 2. WebRTC, self-hosted · the upgrade path

`flutter_webrtc` in the app, a signalling channel over the VPS, STUN for
address discovery and **coturn** as the relay for the roughly one call in five
where NAT traversal fails.

- **Media is always encrypted.** DTLS-SRTP is mandatory in WebRTC, and a 1:1
  peer-to-peer call is end-to-end encrypted by construction — there is no
  server in the media path to trust.
- **Uses data, not airtime.** For a market where data bundles are often the
  cheaper commodity, that is a genuine user benefit rather than a technical
  preference.
- Numbers never need to be exchanged, which would let the design take back the
  promise in `ACCEPTED` if it ever wants to.
- **You already have both hard parts.** The VPS runs signalling and coturn.
  FCM high-priority plus a full-screen intent is exactly the mechanism
  `device-permissions.md` §2 already specifies for waking a driver on a ride
  request — an incoming call is the same problem with a different payload.
- Costs: `RECORD_AUDIO`, a relay that carries bandwidth for the calls that need
  it, and real work on the states that make calling hard — ringing, busy, the
  other party's app killed, reconnection.

### 3. LiveKit, self-hosted · WebRTC with the sharp edges filed off

Open source, self-hostable, a good Flutter SDK, and it handles signalling,
TURN and reconnection rather than leaving them to us.

A 1:1 audio call does not need an SFU, so this is more machinery than the job
strictly requires — but it is machinery that is already written and tested,
against a pile of edge cases that are genuinely tedious to get right. Worth it
if calling turns out to matter; unnecessary if it does not.

Note that routing through an SFU makes the media **hop-by-hop** encrypted
rather than end-to-end, unless E2EE is switched on explicitly.

### 4. Number masking · if privacy becomes the driver

Twilio Proxy, an Africa's Talking voice number, or an MNO arrangement: both
parties call a platform number and the platform bridges them.

This is what the large ride platforms do, and it is the *only* option that
solves number privacy while keeping the familiarity of a normal phone call. It
is also the only one with a **per-minute** cost, and it needs Botswana voice
numbers, which is a commercial arrangement rather than a code change.

Do not reach for this until the design decides it wants number privacy back.

### 5. Matrix · **overkill, and the wrong shape**

Matrix is a federated messaging protocol with VoIP layered on. Adopting it
means running Synapse or Dendrite, operating a federation surface, and carrying
a **second identity system** — Matrix users and rooms — alongside the Postgres
accounts that hold the wallet and the KYC documents.

It is genuinely tempting for one reason: customer↔provider **messaging** is
also undrawn and undelivered, and Matrix would give calling and messaging
together. That is not enough. The identity duplication is the same objection
[`architecture.md`](architecture.md) already raised against Firebase as a
backend, and it applies harder here — a homeserver is a service to run, patch
and back up, forever, for two features.

**If messaging and calling should share a transport, the answer is the app's
own WebSocket on the VPS plus WebRTC**, not somebody else's federation.

---

## Recommendation — **revised 2026-08-21: build both**

> *"Apps like inDrive allow phone call and in-app call, so we can't lose out to
> them."*

That settles it, and it changes the justification rather than just the answer.
The case for in-app calling above was argued on **privacy**, and privacy is
weak here because the design gives numbers away in `ACCEPTED`. **Competitive
parity is a different argument and a much stronger one** — inDrive, Bolt and
Uber all offer both, in this market, and a provider comparing the two apps
side by side will notice one of them cannot call without spending airtime.

So in-app calling moves from *"if it proves it matters"* to **planned**, and
the phone call stays alongside it rather than being replaced.

| When | Do |
|---|---|
| **Phase 5**, when the booking flow is real | Wire the existing call button to `tel:`. Two lines, no infrastructure, and it is the fallback forever — a call that works with no data is worth keeping. |
| **Phase 5–6, planned rather than conditional** | `flutter_webrtc` + coturn on the VPS, signalled over the socket the app already needs, woken by the FCM path built for ride dispatch. This is the parity feature. |
| **If the design takes back "Kabelo has your number"** | Number masking on the *phone* leg. Price it per minute first; the in-app leg needs no masking because no number is exchanged. |
| **Never, on current requirements** | Matrix. |

### Both, and what that means for the UI

Two call routes is not one button with a fallback — it is a **choice the user
makes**, and the design has to say which is which. The pattern the competition
uses is worth copying rather than reinventing:

- **In-app call is the default.** It costs the caller data rather than airtime,
  and it is the one that works without a number being dialled.
- **The phone call is the escape hatch**, one tap further in, for when data is
  bad or the other party's app is closed and unreachable.

That ordering also happens to be the cheap-to-the-user ordering, which is the
right default in this market.

### What "both" costs that "one" does not

- Two failure modes to design, not one: an in-app call that cannot connect has
  to offer the phone call, and it has to do that **without** looking like the
  app is broken.
- The in-app leg needs the callee's app reachable. That is the FCM
  full-screen-intent path from `device-permissions.md` §2 — already planned for
  ride dispatch, and now load-bearing for a second feature.
- `RECORD_AUDIO`, asked for at the first in-app call and never at install.

---

## What has to be designed before any of it

The UI does not exist. Listed in
[`../design/CORRECTIONS.md`](../design/CORRECTIONS.md):

- What the call button **does** — dial out, or open an in-app call screen.
- The **in-call screen**, if calling is in-app: who you are talking to, mute,
  speaker, end, and the booking it belongs to.
- The **incoming call screen**, including over the lock screen — the same
  full-screen-intent surface a ride request needs.
- **When the button is live.** Presumably from `ACCEPTED` to `COMPLETED`; the
  design has never said, and a call button on a `DECLINED` booking is wrong.
- The **microphone permission** priming, if in-app.
- What a **dispute** can see afterwards. A call nobody can evidence is worth
  less to `DISPUTED` than one with a timestamp and a duration.

## Open questions

- Does the design want number privacy back? **Narrower now that both routes
  are being built**: the in-app leg exchanges no number, so privacy only
  affects whether the *phone* leg dials a real number or a masked one. The
  `ACCEPTED` copy — "Kabelo has your number" — is still a privacy promise made
  in passing, and it should be a decision rather than a leftover.
- Whether messaging and calling ship together. If they do, the transport
  decision is one decision rather than two.
- Whether call metadata is needed for disputes, which is a compliance question
  as much as a product one — see [`compliance.md`](compliance.md) before
  recording anything about a call.
