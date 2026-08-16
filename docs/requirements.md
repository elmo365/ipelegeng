# Requirements specification

Requirement IDs are stable — reference them in commits, tests and issues.
`FR` = functional, `NFR` = non-functional, `CON` = constraint.

## Scope

Phase one: a six-category services marketplace for Gaborone and Francistown.
Phase two: bus ticket booking. Out of scope for this document.

---

## 1. Account & identity

| ID | Requirement | Priority |
|---|---|---|
| FR-1.1 | A visitor can register an account with a phone number as primary identifier | Must |
| FR-1.2 | Phone number is verified by OTP before the account is usable | Must |
| FR-1.3 | Every account can act as a customer with no further steps | Must |
| FR-1.4 | An account can apply to become a provider in one or more categories | Must |
| FR-1.5 | Provider verification is applied **per category**, with category-specific document requirements | Must |
| FR-1.6 | A user can hold customer and provider roles simultaneously | Must |
| FR-1.7 | An admin can approve, reject or revoke a provider category verification | Must |
| FR-1.8 | A user can export their personal data | Must (DPA) |
| FR-1.9 | A user can request account and personal-data deletion without destroying financial ledger history | Must (DPA) |
| FR-1.10 | Consent is captured explicitly, granularly, and versioned at signup and each KYC step | Must (DPA) |

## 2. Listings

| ID | Requirement | Priority |
|---|---|---|
| FR-2.1 | A verified provider can create a listing within a verified category | Must |
| FR-2.2 | A listing carries a service direction: provider-travels, client-travels, or both | Must |
| FR-2.3 | A listing carries a service area or a fixed location, depending on direction | Must |
| FR-2.4 | A listing carries pricing information (fixed, from-price, or quote-on-request) | Must |
| FR-2.5 | A provider can set a listing active or inactive | Must |
| FR-2.6 | Property rental listings are per room or unit, not per landlord | Must |
| FR-2.7 | A rental listing requires a paid listing fee before going live | Must |
| FR-2.8 | A rental listing expires after a defined period and can be renewed | Should |
| FR-2.9 | A listing can carry photos | Should |
| FR-2.10 | Listing free-text is validated on creation; phone numbers, emails and social handles are rejected with an explanatory message | Must |

## 2a. External channel posting

| ID | Requirement | Priority |
|---|---|---|
| FR-2a.1 | A listing can be published to the Ipelege Facebook Page, subject to explicit opt-in consent defaulted off | Should |
| FR-2a.2 | Outbound posts are rendered from structured fields only — never from provider free text | Must |
| FR-2a.3 | Outbound posts contain no phone number, email, handle, exact address or provider full name | Must |
| FR-2a.4 | Photos used in outbound posts are screened for visible contact details and excluded if flagged | Should |
| FR-2a.5 | Outbound posts include a deep link back to the listing in the app, with a source parameter for attribution | Must |
| FR-2a.6 | Withdrawing consent removes existing external posts | Must (DPA) |
| FR-2a.7 | Page comments are moderated against contact-detail patterns | Should |

## 3. Discovery & booking

| ID | Requirement | Priority |
|---|---|---|
| FR-3.1 | A customer can browse listings by category | Must |
| FR-3.2 | A customer can filter by location and service direction | Must |
| FR-3.3 | A customer can request a booking, selecting direction, time and location | Must |
| FR-3.4 | A provider can accept or decline a booking request | Must |
| FR-3.5 | Either party can cancel before the service starts, subject to cancellation rules | Must |
| FR-3.6 | A booking moves through a defined lifecycle — see [system flowcharts](system-flowcharts.md) | Must |
| FR-3.7 | Both parties can mark a booking complete; completion requires provider confirmation | Must |
| FR-3.8 | A customer can rate and review a completed booking | Should |
| FR-3.9 | A customer can raise a dispute on a completed or cancelled booking | Should |
| FR-3.10 | Rides use a request/dispatch flow rather than browse-and-book | Must |

## 4. Rides

| ID | Requirement | Priority |
|---|---|---|
| FR-4.1 | A customer can request a ride from a pickup to a destination | Must |
| FR-4.2 | Available nearby drivers are offered the request | Must |
| FR-4.3 | Live GPS location of the assigned driver is visible to the customer during the trip | Must |
| FR-4.4 | Trip route is recorded for safety and dispute purposes | Must |
| FR-4.5 | A customer can share trip status externally | Should |
| FR-4.6 | Driver verification requires driving licence and vehicle registration | Must |

## 5. Wallet & commission

> Subject to the licensing question in [compliance](compliance.md). Written
> here for the **non-redeemable commission credit** model.

| ID | Requirement | Priority |
|---|---|---|
| FR-5.1 | A provider can top up their commission credit balance | Must |
| FR-5.2 | Top-up is supported via Orange Money and EFT | Must |
| FR-5.3 | Card top-up is supported via an external gateway | Should |
| FR-5.4 | Commission is deducted on booking completion only | Must |
| FR-5.5 | Balance is non-redeemable, non-transferable and not withdrawable | Must (regulatory) |
| FR-5.6 | Every balance movement is recorded as an immutable double-entry journal entry | Must |
| FR-5.7 | Balance is a derived view over the journal, never the source of truth | Must |
| FR-5.8 | All balance-affecting operations are idempotent, keyed by a client-supplied reference | Must |
| FR-5.9 | Corrections are made by reversing entries, never by editing history | Must |
| FR-5.10 | A provider with insufficient balance cannot accept new bookings | Must |
| FR-5.11 | A provider can view their transaction history | Must |
| FR-5.12 | Rental listing fees are charged from the same balance | Must |
| FR-5.13 | Payment for the service itself is settled directly between customer and provider, outside the platform | Must (regulatory) |

## 6. Administration

| ID | Requirement | Priority |
|---|---|---|
| FR-6.1 | Admin can review and action pending verifications with document viewing | Must |
| FR-6.2 | Admin can view and reconcile EFT top-ups against bank records | Must |
| FR-6.3 | Admin can suspend a user, provider category, or listing | Must |
| FR-6.4 | Admin can view and resolve disputes | Should |
| FR-6.5 | Admin can adjust commission rates per category | Should |
| FR-6.6 | All admin actions are written to an audit log | Must |
| FR-6.7 | Admin can view supply density per category per city | Should |

---

## Non-functional requirements

| ID | Requirement | Target |
|---|---|---|
| NFR-1 | Mobile app usable on low-end Android devices | Android 8+ |
| NFR-2 | Core browse and booking works on 3G | Degrades gracefully |
| NFR-3 | Ledger consistency | Sum of debits = sum of credits, always |
| NFR-4 | Duplicate payment callbacks never double-post | Idempotency keys |
| NFR-5 | Live tracking location update latency | ≤ 5 s |
| NFR-6 | Personal data copy resident in Botswana | Mandatory — see [compliance](compliance.md) |
| NFR-7 | No card data ever stored or transits platform servers | Mandatory — PCI scope avoidance |
| NFR-8 | KYC documents encrypted at rest, access logged | Mandatory |
| NFR-9 | Interface language | **English only** — see note below |
| NFR-12 | Currency and locale formatting | BWP / pula, Botswana date and number formats, set explicitly rather than inherited from device locale |
| NFR-10 | App size kept small for low-bandwidth download | Target < 30 MB |
| NFR-11 | Availability | 99% at launch |

### Note on NFR-9 — why English only

Setswana localisation is **not planned**, and the reason is practical rather
than preferential: few libraries ship Setswana language files. Flutter's
framework-level localisations cover a fixed set of locales, and Setswana is not
among the well-supported ones.

The consequence matters. Even with hand-written Setswana translations for your
own strings, built-in widget text — date pickers, system dialogs, default
buttons — would fall back to English. The result is a **mixed-language
interface**, which reads as broken rather than localised. Consistent English is
the better product than half-translated Setswana.

Two things this does *not* restrict:

- **User-generated content.** Listing text, messages and reviews are
  unrestricted — people write in whatever language they choose. No validation,
  no transliteration, and the database must handle it cleanly.
- **Human communication.** Support conversations, Facebook copy and provider
  recruitment can be in Setswana whenever it lands better. That is a per-message
  human choice, not a product feature.

**NFR-12 still applies regardless of language.** Currency must display as pula
and date formats must be Botswana-correct. These come from locale settings, not
translation files, and a device set to en-US will otherwise format things
wrongly. Set them explicitly.

*If this is ever revisited, verify current Flutter locale support first — the
supported set does change between releases.*

## Constraints

| ID | Constraint |
|---|---|
| CON-1 | Platform charges providers only, never customers, in any category |
| CON-2 | Mobile client is Flutter |
| CON-3 | EPS licensing position must be resolved before backend design freeze |
| CON-4 | Launch cities: Gaborone and Francistown |
| CON-5 | Six launch categories |
| CON-6 | GPS tracking assembled from open-source components, not built from scratch |
