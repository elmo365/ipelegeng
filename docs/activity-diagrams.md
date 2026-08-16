# Activity diagrams

Swimlaned activity flows for the main journeys. State machines and error paths
are in [system flowcharts](system-flowcharts.md).

---

## A-1 · Provider onboarding

```mermaid
flowchart TD
    Start([User decides to offer a service]) --> A1[Select category]
    A1 --> A2[System shows document requirements for that category]
    A2 --> A3[Upload documents]
    A3 --> A4[Grant processing consent]
    A4 --> A5[(Store encrypted, create pending verification)]
    A5 --> A6[Notify admin queue]
    A6 --> B1{Admin review}
    B1 -->|Approve| B2[Activate category for user]
    B1 -->|Reject| B3[Record reason]
    B1 -->|More info needed| B4[Return to applicant]
    B4 --> A3
    B3 --> B5[Notify user with reason]
    B5 --> End1([Can resubmit])
    B2 --> C1[Notify user]
    C1 --> C2{Balance sufficient?}
    C2 -->|No| C3[Prompt top-up]
    C3 --> C4[Top-up flow A-4]
    C2 -->|Yes| C5[Create first listing]
    C4 --> C5
    C5 --> End2([Live and discoverable])
```

---

## A-2 · Booking lifecycle, non-ride

```mermaid
flowchart TD
    S([Customer browsing]) --> A1[Open listing]
    A1 --> A2[Choose service direction]
    A2 --> A3[Set time and location]
    A3 --> A4{Provider balance covers commission?}
    A4 -->|No| A5[Listing shown unavailable to customer]
    A5 --> A6[Notify provider to top up]
    A6 --> E1([End - no booking])
    A4 -->|Yes| B1[Create booking REQUESTED]
    B1 --> B2[Notify provider]
    B2 --> B3{Provider responds within window?}
    B3 -->|Declines| B4[DECLINED - suggest alternatives]
    B3 -->|No response| B5[EXPIRED]
    B3 -->|Accepts| C1[ACCEPTED - notify customer]
    B4 --> E1
    B5 --> E1
    C1 --> C2{Cancelled before start?}
    C2 -->|Yes| C3[CANCELLED - apply cancellation rules]
    C3 --> E1
    C2 -->|No| D1[Service delivered]
    D1 --> D2[Customer pays provider directly - off platform]
    D2 --> D3[Provider marks complete]
    D3 --> D4{Customer confirms?}
    D4 -->|Confirms| F1[Post commission to ledger]
    D4 -->|No response in window| F2[Auto-confirm, flag for admin]
    D4 -->|Disputes| G1[DISPUTED - hold commission]
    F2 --> F1
    F1 --> F3[COMPLETED]
    F3 --> F4[Prompt customer to rate]
    F4 --> E2([End])
    G1 --> G2[Admin resolution]
    G2 --> E2
```

**Note the ordering at D2.** Money changes hands between the two people before
the platform records anything. The platform's ledger entry at F1 concerns only
the commission the provider owes.

---

## A-3 · Ride request and trip

```mermaid
flowchart TD
    S([Customer needs a ride]) --> A1[Set pickup and destination]
    A1 --> A2[System estimates distance, time, fare]
    A2 --> A3[Customer confirms]
    A3 --> B1[Find nearby available drivers with sufficient balance]
    B1 --> B2{Any candidates?}
    B2 -->|No| B3[Widen search radius]
    B3 --> B4{Retry limit reached?}
    B4 -->|No| B1
    B4 -->|Yes| B5[Fail with clear message]
    B5 --> E1([End])
    B2 -->|Yes| C1[Offer to drivers]
    C1 --> C2{Driver accepts in time?}
    C2 -->|No| B3
    C2 -->|Yes| D1[Assign trip]
    D1 --> D2[Show driver, vehicle, live location to customer]
    D2 --> D3{Driver cancels?}
    D3 -->|Yes| D4[Record against driver standing]
    D4 --> B1
    D3 -->|No| E2[Driver arrives]
    E2 --> E3{Customer present?}
    E3 -->|No, after wait| E4[Driver cancels as no-show]
    E4 --> E1
    E3 -->|Yes| F1[Start trip - begin route recording]
    F1 --> F2[Stream location updates to customer]
    F2 --> F3[Arrive at destination]
    F3 --> F4[End trip]
    F4 --> F5[Customer pays driver directly]
    F5 --> F6[Post commission from driver balance]
    F6 --> F7[Prompt rating]
    F7 --> E1
```

---

## A-4 · Commission credit top-up

```mermaid
flowchart TD
    S([Provider needs balance]) --> A1[Enter amount]
    A1 --> A2{Choose method}

    A2 -->|Orange Money| B1[Create pending top-up with unique reference]
    B1 --> B2[Call Orange Money API]
    B2 --> B3[Provider authorises on handset]
    B3 --> B4{Callback received?}
    B4 -->|Yes| B5[Validate callback signature]
    B4 -->|No, timeout| B6[Scheduled job queries provider status]
    B6 --> B5
    B5 --> Z1

    A2 -->|EFT| C1[Create pending top-up with unique reference]
    C1 --> C2[Display bank details and reference]
    C2 --> C3[Provider transfers at their bank]
    C3 --> C4[Bank statement imported]
    C4 --> C5{Reference matches?}
    C5 -->|Yes, amount matches| Z1
    C5 -->|Amount mismatch| C6[Hold for admin decision]
    C5 -->|No reference| C7[Unmatched queue]
    C6 --> C8[Admin resolves]
    C7 --> C8
    C8 --> Z1

    A2 -->|Card| D1[Redirect to external gateway]
    D1 --> D2[Gateway captures card - never touches platform]
    D2 --> D3[Gateway callback]
    D3 --> Z1

    Z1[Resolve idempotency key] --> Z2{Already processed?}
    Z2 -->|Yes| Z3[Return existing result - no double post]
    Z2 -->|No| Z4[Build balanced journal entry]
    Z4 --> Z5{Sum = zero?}
    Z5 -->|No| Z6[Reject and alert]
    Z5 -->|Yes| Z7[Append to journal]
    Z7 --> Z8[Refresh balance view]
    Z8 --> Z9[Notify provider]
    Z3 --> E([End])
    Z9 --> E
    Z6 --> E
```

**The EFT branch is the expensive one.** Steps C3–C8 involve a human unless the
gateway provides instant EFT. Worth quantifying before launch — it scales with
provider count.

---

## A-5 · Rental listing publication

```mermaid
flowchart TD
    S([Landlord has a vacant room]) --> A1{Verified as landlord?}
    A1 -->|No| A2[Verification flow A-1]
    A2 --> A3
    A1 -->|Yes| A3[Create listing for one room or unit]
    A3 --> A4[Add location, price, photos, available date]
    A4 --> A5[System shows listing fee]
    A5 --> A6{Balance sufficient?}
    A6 -->|No| A7[Save as draft, prompt top-up]
    A7 --> A8[Top-up flow A-4]
    A8 --> A9
    A6 -->|Yes| A9[Confirm]
    A9 --> B1[Post listing fee to ledger]
    B1 --> B2[Publish listing with expiry date]
    B2 --> B3[Tenants browse free]
    B3 --> C1{Expiry reached?}
    C1 -->|Renew| B1
    C1 -->|Let lapse| C2[Listing archived]
    C2 --> E([End])
```

**The cross-sell moment is at B3.** A tenant who books a room is a mover
customer that same week — this is the ecosystem principle made concrete. Prompt
it there.


---

## A-6 · External channel syndication

```mermaid
flowchart TD
    S([Listing published in app]) --> A1{Consented to external posting?}
    A1 -->|No| A2[In-app only - no further action]
    A2 --> E1([End])
    A1 -->|Not asked yet| A3[Show opt-in, defaulted OFF]
    A3 --> A4{Provider opts in?}
    A4 -->|No| A2
    A4 -->|Yes| A5[Record versioned consent]
    A5 --> B1
    A1 -->|Yes| B1[Compose teaser from structured fields only]
    B1 --> B2[Category, area, price band, photo, deep link]
    B2 --> B3[Screen photo for visible contact details]
    B3 --> B4{Contact details found in photo?}
    B4 -->|Yes| B5[Exclude photo]
    B5 --> B6
    B4 -->|No| B6[Final validation - no number, email, handle, address, full name]
    B6 --> B7{Clean?}
    B7 -->|No| B8[Block post and alert - do not strip silently]
    B8 --> E1
    B7 -->|Yes| C1[Publish to Facebook Page via Graph API]
    C1 --> C2{Published?}
    C2 -->|API error| C3[Retry with backoff]
    C3 --> C4{Retries exhausted?}
    C4 -->|No| C1
    C4 -->|Yes| C5[Log failure, alert admin]
    C5 --> E1
    C2 -->|Token expired| C6[Queue post, alert admin to refresh token]
    C6 --> E1
    C2 -->|Yes| D1[Store external post reference against listing and consent]
    D1 --> D2[Add to manual group-posting queue]
    D2 --> D3[Growth operator posts to groups by hand]
    D3 --> D4[Log group, operator, timestamp]
    D4 --> E1

    NOTE[Listing publication never blocks on any of this]
```

**The critical property: this whole flow is downstream and optional.** A Meta
outage, an expired token, or a failed validation must never prevent the listing
going live in the app.

---

## A-7 · Consent withdrawal and takedown

```mermaid
flowchart TD
    S([Provider withdraws channel consent]) --> A1[Mark consent withdrawn with timestamp]
    A1 --> A2[Find all external posts linked to that consent record]
    A2 --> A3{Any posts found?}
    A3 -->|No| A4[Confirm to provider]
    A3 -->|Yes| B1[Delete each via Graph API]
    B1 --> B2{All deleted?}
    B2 -->|Yes| B3[Mark posts removed]
    B3 --> A4
    B2 -->|Partial or failed| C1[Retry]
    C1 --> C2{Still failing?}
    C2 -->|No| B3
    C2 -->|Yes| C3[Escalate to admin for manual removal]
    C3 --> C4[Tell provider removal is in progress - do NOT report success]
    C4 --> C5[Admin removes manually, marks resolved]
    C5 --> A4
    A4 --> D1[Stop all future syndication for this provider]
    D1 --> E([End])
```

**Honesty is a requirement here.** Reporting a takedown that has not happened is
both a data-protection failure and a trust failure, in a product whose central
claim is trust.

---

## A-8 · Transactional messaging

```mermaid
flowchart TD
    S([Event: OTP / booking requested / accepted / completion due]) --> A1{User consented to WhatsApp messaging?}
    A1 -->|No| B1[Send via SMS]
    A1 -->|Yes| A2[Select approved template for the event]
    A2 --> A3{Template approved by Meta?}
    A3 -->|No| A4[Alert admin]
    A4 --> B1
    A3 -->|Yes| A5{Inside 24h service window?}
    A5 -->|Yes| A6[Send as free-form or utility - free window]
    A5 -->|No| A7[Send as utility or authentication template - billed]
    A6 --> C1
    A7 --> C1
    C1[Send via WhatsApp Business Platform] --> C2{Delivered?}
    C2 -->|Yes| C3[Record delivery and category for cost attribution]
    C2 -->|Not on WhatsApp| B1
    C2 -->|Failed| C4[Retry per policy]
    C4 --> C5{Retries exhausted?}
    C5 -->|No| C1
    C5 -->|Yes| B1
    B1 --> C3
    C3 --> E([End])
```

**Never use marketing templates for transactional events.** They carry no volume
discount and are billed on every delivery. Category selection is a cost
decision, not a labelling formality.
