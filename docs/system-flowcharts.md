# System flowcharts & state machines

Where [activity diagrams](activity-diagrams.md) show what people do, this
document defines what the *system* must enforce.

---

## Booking state machine

Every booking is in exactly one state. Transitions not drawn here are invalid
and must be rejected by the API, not merely hidden in the UI.

```mermaid
stateDiagram-v2
    [*] --> REQUESTED : customer requests

    REQUESTED --> ACCEPTED : provider accepts
    REQUESTED --> DECLINED : provider declines
    REQUESTED --> EXPIRED : response window elapses
    REQUESTED --> CANCELLED : customer cancels

    ACCEPTED --> IN_PROGRESS : service starts
    ACCEPTED --> CANCELLED : either party cancels
    ACCEPTED --> NO_SHOW : counterparty absent

    IN_PROGRESS --> PENDING_CONFIRMATION : provider marks complete
    IN_PROGRESS --> DISPUTED : problem raised mid-service

    PENDING_CONFIRMATION --> COMPLETED : customer confirms
    PENDING_CONFIRMATION --> COMPLETED : auto-confirm timeout
    PENDING_CONFIRMATION --> DISPUTED : customer disputes

    DISPUTED --> COMPLETED : resolved in provider favour
    DISPUTED --> CANCELLED : resolved in customer favour

    COMPLETED --> [*]
    DECLINED --> [*]
    EXPIRED --> [*]
    CANCELLED --> [*]
    NO_SHOW --> [*]
```

### Commission posting rule

| State | Commission |
|---|---|
| COMPLETED | **Posted** |
| DISPUTED | **Held** — not posted until resolved |
| CANCELLED, DECLINED, EXPIRED, NO_SHOW | Not posted |

Commission posts **once**, on entry to COMPLETED, keyed idempotently on booking
ID. A booking that reaches COMPLETED via dispute resolution posts at that point,
not before.

> **Unresolved.** NO_SHOW currently posts nothing, which means a driver who
> waited twenty minutes absorbs the loss. Whether a no-show fee applies — and
> who bears it, given the platform never touches the customer's money — is
> [open](open-questions.md). It is a real fairness problem, not an edge case.

---

## Top-up state machine

```mermaid
stateDiagram-v2
    [*] --> PENDING : provider initiates

    PENDING --> SETTLED : callback validated / EFT matched
    PENDING --> FAILED : provider declines or gateway error
    PENDING --> UNMATCHED : EFT deposit, reference missing or wrong
    PENDING --> EXPIRED : no payment within window

    UNMATCHED --> SETTLED : admin matches manually
    UNMATCHED --> REFUNDED : admin returns funds

    SETTLED --> [*]
    FAILED --> [*]
    EXPIRED --> [*]
    REFUNDED --> [*]
```

Only the transition into SETTLED writes to the journal.

---

## Provider category verification states

```mermaid
stateDiagram-v2
    [*] --> PENDING : application submitted
    PENDING --> INFO_REQUESTED : admin needs more
    INFO_REQUESTED --> PENDING : applicant resubmits
    PENDING --> APPROVED : admin approves
    PENDING --> REJECTED : admin rejects
    APPROVED --> REVOKED : misconduct or expired document
    REJECTED --> PENDING : applicant reapplies
    REVOKED --> PENDING : applicant reapplies
    APPROVED --> [*]
```

**On REVOKED:** all listings under that category are deactivated immediately,
and bookings already ACCEPTED must be handled explicitly — currently undefined.

---

## Idempotent ledger posting

The single most important flowchart in the system. Any path that writes to the
journal goes through this.

```mermaid
flowchart TD
    A[/Posting request with idempotency key/] --> B{Key already in journal?}
    B -->|Yes| C[Return the original result]
    C --> Z([Done - nothing written])
    B -->|No| D[Begin transaction]
    D --> E[Build entry set]
    E --> F{Sum of debits = sum of credits?}
    F -->|No| G[Rollback]
    G --> H[Alert operations]
    H --> Z2([Failed - nothing written])
    F -->|Yes| I{Unique constraint on key still free?}
    I -->|No, race lost| J[Rollback, return original]
    J --> Z
    I -->|Yes| K[Append entries - no updates, no deletes]
    K --> L[Commit]
    L --> M[Refresh derived balance view]
    M --> Z3([Posted once])
```

**Why the check appears twice (B and I).** B is the fast path. I is the
correctness guarantee — two concurrent requests can both pass B, and only the
database unique constraint reliably stops the second from writing. Application
logic alone is not sufficient here.

---

## Payment callback handling

```mermaid
flowchart TD
    A[/Callback from payment provider/] --> B{Signature valid?}
    B -->|No| C[Reject, log, alert]
    C --> Z([End])
    B -->|Yes| D{Reference known?}
    D -->|No| E[Park in unmatched queue for admin]
    E --> Z
    D -->|Yes| F{Top-up already SETTLED?}
    F -->|Yes| G[Acknowledge, do nothing]
    G --> Z
    F -->|No| H{Amount matches expected?}
    H -->|No| I[Hold for admin decision]
    I --> Z
    H -->|Yes| J[Post to ledger via idempotent path]
    J --> K[Mark SETTLED]
    K --> L[Notify provider]
    L --> Z
```

Providers retry callbacks. Networks duplicate them. Attackers forge them. Every
branch above exists because one of those three happens in production.

---

## Scheduled reconciliation

```mermaid
flowchart TD
    A([Scheduled job]) --> B[Fetch external records for the period]
    B --> C[Fetch internal SETTLED top-ups for the period]
    C --> D{Compare}
    D -->|Match| E[Record clean reconciliation]
    D -->|External present, internal missing| F[Post via idempotent path]
    D -->|Internal present, external missing| G[Flag for investigation]
    D -->|Amount differs| G
    F --> H[Log recovery]
    G --> I[Alert operations]
    E --> Z([End])
    H --> Z
    I --> Z
```

This job is what catches the top-up whose callback never arrived. Without it,
a provider pays and their balance silently never moves — which is the failure
most likely to lose you a provider permanently.


---

## External post state machine

```mermaid
stateDiagram-v2
    [*] --> NOT_CONSENTED : listing created

    NOT_CONSENTED --> QUEUED : provider opts in
    QUEUED --> BLOCKED : validation found contact data
    QUEUED --> PUBLISHED : Graph API success
    QUEUED --> FAILED : retries exhausted

    BLOCKED --> QUEUED : composer fixed, requeued
    FAILED --> QUEUED : manual retry

    PUBLISHED --> STALE : listing edited after posting
    STALE --> PUBLISHED : external post refreshed

    PUBLISHED --> REMOVED : consent withdrawn
    PUBLISHED --> REMOVED : listing expired or deactivated
    STALE --> REMOVED : consent withdrawn

    REMOVED --> [*]
    NOT_CONSENTED --> [*]
```

`STALE` exists because a listing can change after it has been syndicated. The
`content_hash` on `EXTERNAL_POST` is what detects it.

`BLOCKED` is a **loud** state. It means the composer produced content containing
contact details, which should be impossible if posts are built from structured
fields — so it indicates a bug, and should alert rather than sit in a queue.

---

## Outbound content safety gate

Every piece of content leaving the platform for a public channel passes through
this. No exceptions, no bypass path.

```mermaid
flowchart TD
    A[/Composed post/] --> B{Built from structured fields only?}
    B -->|No, contains free text| C[Reject - composer defect]
    C --> Z2([Blocked and alerted])
    B -->|Yes| D{Phone number pattern present?}
    D -->|Yes| C
    D -->|No| E{Email or social handle present?}
    E -->|Yes| C
    E -->|No| F{Exact street address present?}
    F -->|Yes| C
    F -->|No| G{Provider full name present?}
    G -->|Yes| C
    G -->|No| H{Photo screened for visible contact details?}
    H -->|Flagged| I[Drop the photo, continue without it]
    H -->|Clean| J
    I --> J[Attach deep link with source parameter]
    J --> K[Release to channel]
    K --> Z([Published])
```

**Why block rather than strip.** Silently removing a detected phone number would
publish the post and hide the fact that the composer allowed free text through.
Blocking makes the defect visible. The cost of a blocked post is one missed
post; the cost of a silent strip is a class of bug that never gets found.

**Botswana number patterns** need explicit handling — local formats, +267
prefixed, and spaced or dashed variants. Generic international regexes will miss
them.

---

## Consent gate for outbound messaging

```mermaid
flowchart TD
    A[/Outbound action requested/] --> B[Read current consent record]
    B --> C{Consent granted for this specific type?}
    C -->|No| D[Do nothing - no fallback to another channel]
    D --> Z([Stopped])
    C -->|Withdrawn| E[Do nothing, and trigger takedown if posts exist]
    E --> Z
    C -->|Yes| F{Consent version still current?}
    F -->|Superseded| G[Re-consent required - prompt user in app]
    G --> Z
    F -->|Current| H[Proceed]
    H --> Z2([Allowed])
```

**Consent is read at action time, never cached at listing creation.** A provider
can withdraw between publishing a listing and an update being syndicated, and
the second action must respect the newer state.

**Note the absence of a fallback at D.** If a user has not consented to
WhatsApp, the answer is not "send it by SMS instead" unless they consented to
that separately. Channel consents are granular and independent.
