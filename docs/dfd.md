# Data flow diagrams

## Context diagram (Level 0)

The system as a single process, with its external entities.

```mermaid
flowchart TB
    C([Customer])
    P([Provider])
    A([Admin])
    OM[/Orange Money API/]
    GW[/Card Gateway/]
    BANK[/Bank - EFT/]
    MAP[/Map & Routing Service/]
    SMS[/SMS Gateway/]
    META[/Meta - Facebook Page & WhatsApp/]
    G([Growth Operator])

    SYS{{Ipelegeng Platform}}

    C -->|registration, search, booking request, rating| SYS
    SYS -->|listings, booking status, driver location| C

    P -->|KYC documents, listings, accept/complete, top-up request| SYS
    SYS -->|booking notifications, balance, verification status| P

    A -->|verification decisions, reconciliation, dispute resolution| SYS
    SYS -->|pending queues, audit log, supply metrics| A

    SYS -->|payment request| OM
    OM -->|payment callback| SYS
    SYS -->|redirect for card capture| GW
    GW -->|payment callback| SYS
    BANK -->|deposit statement| SYS
    SYS <-->|geocode, route, distance| MAP
    SYS -->|OTP, notifications| SMS
    SYS -->|teaser posts, template messages| META
    META -->|post ids, delivery status, engagement| SYS
    SYS -->|post-ready queue, group limits| G
    G -->|manual group posts, results| SYS
```

**Note the Growth Operator.** They appear on the context diagram as an external
actor because manual group posting is outside the system boundary — the system
prepares and records the work, but a person performs it. That is a consequence
of the Groups API withdrawal, not a design preference.

---

## Level 1 — major processes

```mermaid
flowchart TB
    C([Customer])
    P([Provider])
    A([Admin])
    PAY[/Payment Providers/]
    MAP[/Map Service/]
    META[/Meta APIs/]
    G([Growth Operator])

    P1[1.0 Account & Identity]
    P2[2.0 Verification]
    P3[3.0 Listing Management]
    P4[4.0 Discovery & Booking]
    P5[5.0 Ride Dispatch & Tracking]
    P6[6.0 Ledger & Commission]
    P7[7.0 Payment Integration]
    P8[8.0 Administration]
    P9[9.0 Channel Syndication & Messaging]

    D1[(D1 Users & Profiles)]
    D2[(D2 Verifications & Documents)]
    D3[(D3 Listings)]
    D4[(D4 Bookings & Events)]
    D5[(D5 Journal - immutable)]
    D6[(D6 Trip Locations)]
    D7[(D7 Audit Log)]
    D9[(D9 External Posts & Messages)]
    D10[(D10 Consent Records)]

    C --> P1
    P --> P1
    P1 <--> D1

    P --> P2
    P2 <--> D2
    P2 --> D1

    P --> P3
    P3 <--> D3
    P3 --> P6

    C --> P4
    P --> P4
    P4 <--> D4
    P4 --> D3
    P4 --> P6
    P4 <--> MAP

    C --> P5
    P5 <--> D6
    P5 --> D4
    P5 <--> MAP

    P --> P7
    P7 <--> PAY
    P7 --> P6

    P6 --> D5
    P6 -.->|derived balance| P4

    P3 --> P9
    P4 --> P9
    P1 --> P9
    P9 <--> D9
    P9 --> D10
    P1 --> D10
    P9 <--> META
    P9 --> G
    G --> P9
    P8 --> D9

    A --> P8
    P8 --> D2
    P8 --> D5
    P8 --> D7
    P8 --> D4
```

### Process descriptions

| # | Process | Inputs | Outputs | Key stores |
|---|---|---|---|---|
| 1.0 | Account & Identity | Phone, name, consent | Verified account, session | D1 |
| 2.0 | Verification | Documents, category | Approved/rejected category | D2, D1 |
| 3.0 | Listing Management | Listing details, direction, area | Published listing; fee request for rentals | D3 |
| 4.0 | Discovery & Booking | Search criteria, booking request | Listings, booking state changes | D3, D4 |
| 5.0 | Ride Dispatch & Tracking | Pickup, destination, driver positions | Assignment, live location, route | D4, D6 |
| 6.0 | Ledger & Commission | Completion events, top-up settlements, fees | Journal entries, derived balances | D5 |
| 7.0 | Payment Integration | Top-up request, provider callbacks | Settled/failed top-up | D5 |
| 8.0 | Administration | Admin decisions | Approvals, resolutions, audit entries | D2, D4, D5, D7 |
| 9.0 | Channel Syndication & Messaging | Listing published, booking events, consent state | Teaser posts, template messages, post-ready queue | D9, D10 |

**Note on 9.0.** It reads consent (D10) before every outbound action and writes
nothing to the listing or booking stores. It is deliberately a *leaf* process:
if the channel integration fails, nothing upstream is affected. A Facebook
outage must never prevent a listing going live.

**Note on 6.0.** Only process 6.0 writes to D5, and it only appends. No other
process may write journal entries directly. This single rule is what keeps the
ledger trustworthy.

---

## Level 2 — process 6.0, Ledger & Commission

```mermaid
flowchart TB
    IN1[/Booking completed event/]
    IN2[/Top-up settled event/]
    IN3[/Listing fee charge/]
    IN4[/Admin adjustment/]

    P61[6.1 Resolve idempotency key]
    P62[6.2 Build balanced entry set]
    P63[6.3 Validate sum = zero]
    P64[6.4 Append to journal]
    P65[6.5 Refresh balance view]
    P66[6.6 Reconcile against external]

    D5[(D5 Journal - append only)]
    D8[(D8 Balance cache - derived)]
    EXT[/Payment provider records/]

    IN1 --> P61
    IN2 --> P61
    IN3 --> P61
    IN4 --> P61

    P61 -->|new| P62
    P61 -.->|already seen: no-op| OUT2[/Return existing result/]
    P62 --> P63
    P63 -->|balanced| P64
    P63 -.->|unbalanced: reject + alert| ERR[/Error/]
    P64 --> D5
    P64 --> P65
    P65 --> D8
    D5 --> P66
    EXT --> P66
    P66 -.->|mismatch| ERR
```

**6.1 exists to make retries safe.** A payment gateway that sends the same
callback twice, a provider who taps "complete" twice, a network retry — all
resolve to the same key and post once.

**6.3 exists to make corruption loud rather than silent.** An unbalanced
transaction is rejected and alerted on, not quietly written.

**6.6 exists because internal records drift from external ones.** Scheduled
reconciliation against Orange Money and bank statements catches what callbacks
missed.

---

## Level 2 — process 9.0, Channel Syndication

```mermaid
flowchart TB
    IN1[/Listing published or updated/]
    IN2[/Consent withdrawn/]
    IN3[/Listing expired or deactivated/]

    P91[9.1 Check consent state]
    P92[9.2 Compose from structured fields]
    P93[9.3 Screen photo for contact details]
    P94[9.4 Validate - no contact data present]
    P95[9.5 Publish via Graph API]
    P96[9.6 Record external post reference]
    P97[9.7 Remove external posts]
    P98[9.8 Queue for manual group posting]

    D9[(D9 External Posts)]
    D10[(D10 Consent Records)]
    META[/Meta Graph API/]
    G([Growth Operator])

    IN1 --> P91
    D10 --> P91
    P91 -->|consented| P92
    P91 -.->|not consented: stop| STOP[/No action/]
    P92 --> P93
    P93 --> P94
    P94 -->|clean| P95
    P94 -.->|contact detected: block + alert| ERR[/Blocked/]
    P95 --> META
    P95 --> P96
    P96 --> D9
    P96 --> P98
    P98 --> G

    IN2 --> P97
    IN3 --> P97
    D9 --> P97
    P97 --> META
    P97 --> D9
```

**9.4 is a gate, not a filter.** If contact data is detected, the post is
blocked and flagged — it is not silently stripped and published. Silent
stripping hides a bug in the composer; blocking surfaces it.

**9.1 reads consent every time**, not once at listing creation. Consent can be
withdrawn between a listing going live and an update being syndicated.
