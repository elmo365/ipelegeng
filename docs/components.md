# Components — what to adopt, what to build

Survey of freely usable components for the parts that are expensive or
error-prone to write from scratch. [architecture](architecture.md) already
commits to an open-source mapping stack (CON-6); this names the actual packages
and states where adopting is wrong.

## The rule

**Adopt where the problem is universal and hard. Build where the problem is
ours and small.**

Map rendering, routing and geocoding are universal, hard, and solved. The ledger
is small, specific, and the one thing we can never reshape after the first
production write — so it is built, not adopted, and the reasoning is below.

---

## Maps

### Rendering — MapLibre GL

**Adopt.** [`maplibre_gl`](https://pub.dev/packages/maplibre_gl) (the
established fork of flutter-mapbox-gl) or
[`maplibre`](https://pub.dev/packages/maplibre) (a newer rewrite using
FFI/JNI bindings).

Vector, fully styleable, **vendor-neutral — no proprietary token required.**
That last point is why it beats Google Maps here: Google Maps has no offline
support and its style cannot be customised beyond basic colour tweaks, and it
bills per request at volumes we cannot predict.

Offline matters more for this market than for most. The package supports
`downloadOfflineRegion`, and MBTiles (SQLite-packed tiles) render directly —
which is the right answer for Gaborone and Francistown, both small enough to
package entirely.

**Pick `maplibre_gl` for now.** The rewrite is promising but the mature package
has the offline API and the larger body of worked examples, and this is not
where the project should be discovering issues.

**Watch the binary budget.** The 30 MB cap is a hard requirement. A map SDK plus
bundled tiles will be the single largest contributor — measure early, and treat
bundled offline tiles as a download-on-demand feature rather than a shipped
asset.

### Tiles

Self-host from OpenStreetMap extracts, or start on a free/cheap tile provider
while volumes are trivial. Botswana is a small extract; self-hosting is a
container and a few GB, not a project.

### Routing — Valhalla

**Adopt Valhalla.** *Revised 2026-08-18 — this document previously recommended
OSRM. Registry checks changed the answer.*

Both accept OSM `.osm.pbf` extracts from Geofabrik and give a complete routing
API with no external dependencies. The **Botswana extract is 83 MB** — very
small, which makes throughput differences irrelevant and preprocessing cheap
either way.

| | Valhalla | OSRM |
|---|---|---|
| **arm64 container** | ✅ `ghcr.io/gis-ops/docker-valhalla/valhalla` publishes **linux/amd64 + linux/arm64** | ❌ `osrm/osrm-backend` on Docker Hub is **amd64 only** |
| Image maintenance | Actively published | **Docker Hub images last updated July 2021 (v5.25.0)** — five years stale, while the project itself is on v26.8.0 |
| arm64 otherwise | — | Works: official GitHub releases ship `linux-arm64` prebuilt assets (v26.8.0, Aug 2026). Needs building or unpacking rather than `docker pull`. |
| Throughput | ~2,000–4,000 q/s | ~5,000–10,000 q/s |
| Data | Runs on raw OSM, no preprocessing step | Requires preprocessing into a compressed graph |
| Map matching | ✅ Meili | ✅ `match` service |
| Extras | Isochrones, time-aware routing, elevation, multimodal | Routing, nearest, matrix, match |

**Why the reversal.** The earlier recommendation rested on OSRM being faster and
having map matching. Neither survives contact with the facts: **Valhalla has map
matching too** (Meili), and throughput is meaningless at our volume — nothing
here is throughput-bound, and the road network is one small country.

What decides it is that Valhalla **runs on ARM today with a `docker pull`**,
which removes the only real friction from the free Oracle box
([architecture](architecture.md#arm-and-the-osrm-question--checked)). OSRM's
abandoned Docker Hub images are a second, independent reason to prefer Valhalla
regardless of architecture.

Map matching matters directly for [cancellation](cancellation.md) — snapping a
driver's GPS trail to the road network is what turns a scatter of fixes into
"this vehicle drove to the destination". Both engines can do it; only one of
them pulls on ARM.

**GraphHopper** is the third option and the most ARM-proof of all — it is
**Java**, so architecture is a non-issue by construction and it ships as a JAR.
Worth keeping in mind as a fallback, but Valhalla's container is simpler to
operate and its feature set is closer to what rides needs.

### Geocoding — and a warning

[Nominatim](https://nominatim.org/) for search, [Photon](https://github.com/komoot/photon)
for autocomplete. Both self-hostable; Photon publishes weekly database dumps
including per-country extracts.

**But do not build the product on geocoding.** OSM's known weakness is exactly
our market: coverage is sparse in developing countries, house-number coverage is
incomplete in most countries, and rural addresses return **city-centre
centroids rather than real coordinates**. Botswana addressing — plot numbers,
wards, yards — is not what a street-address geocoder is built for.

Design around it instead, which the app should do regardless:

- **Map-pin selection is the primary input**, not a text field. The customer
  drops a pin; the geocoder only supplies a human-readable label, and a wrong
  label is cosmetic where a wrong coordinate is a failed job.
- **Saved places** — home, work, "Mma's yard". Most bookings repeat.
- **A free-text note alongside the pin** — "blue gate, past the tuckshop". This
  is how people actually give directions here, and no geocoder replaces it.
- Reverse geocoding is **display only**. Never let it decide dispatch.

This also feeds [cancellation](cancellation.md): a "distance to target" test is
only as good as the target, so the target must be a pin the customer placed, not
a string a geocoder guessed.

---

## Ledger — build it

**Do not adopt.** Two mature options exist and both were considered:

- [**django-hordak**](https://github.com/adamcharnock/django-hordak) — core
  double-entry models with relational integrity constraints, deliberately a
  foundation rather than a full app. The closest fit by far.
- [**django-ledger**](https://github.com/arrobalytics/django-ledger) — a full
  accounting engine: income statements, balance sheets, invoices, purchase
  orders. Far more than this product has any use for.

The recommendation is still to build, for three reasons:

1. **The journal is the one table that can never be reshaped.**
   [database](database.md#migrations) makes the ledger schema additive-only
   after the first production write. Adopting a package means adopting its
   migration story for precisely the table where a future upstream migration is
   unacceptable.
2. **Our requirements are specific and not the library's.** Idempotency keys on
   every transaction, VAT as a mandatory separate entry, reversals that mirror
   line-for-line rather than recalculate, and enforcement at the **database
   privilege level** rather than in Python. Bending a general ledger into that
   shape is comparable work to writing it, with less understanding of the
   result.
3. **It is small.** Four tables and one posting function. The
   [test strategy](test-strategy.md#property-based--the-ledger) already
   specifies six property-based invariants over it — and a suite that thorough
   over code we wrote is worth more than the same suite over code we adopted.

**Read hordak's models and its
[accounting-for-developers](https://django-hordak.readthedocs.io/en/latest/accounting-for-developers.html)
notes before writing ours.** Learning from it is free; depending on it is not.

---

## Live tracking — build, but thinly

No off-the-shelf component fits. What it decomposes into is all boring:

| Piece | Approach |
|---|---|
| Position ingest | Batched `POST` from the driver app, not per-fix. Battery is the constraint. |
| Live position store | Redis `GEO` + `GEOSEARCH` ([database](database.md#redis)) |
| Nearest-driver dispatch | Redis, not PostGIS. PostGIS answers the static question, Redis the moving one. |
| Delivery to the customer | Polling first. WebSockets only if polling proves inadequate — on 3G with 1 GB handsets, a held socket is a real battery and reliability cost. |
| Trail persistence | Batched write-through to partitioned `trip_location` |
| Map matching | OSRM `match` service |
| Spoof detection | `Location.isMock` client-side, plus server-side impossible-speed and trajectory checks ([cancellation](cancellation.md#gps-is-evidence-not-proof)) |

The tempting mistake is a realtime framework. Resist it: the requirement is a
marker that updates every few seconds, and polling meets it at a fraction of the
complexity and battery cost.

---

## Everything else

| Need | Adopt | Note |
|---|---|---|
| Django + PostGIS | `django.contrib.gis` | First-class, in core |
| REST API | Django REST Framework | Decided |
| OpenAPI schema | `drf-spectacular` | Generated, per [sdlc-overview](sdlc-overview.md) |
| Background jobs | Celery + Redis, or `django-q2` for something lighter | Syndication, retention sweeps, reconciliation, the event relay |
| Push notifications | Firebase Cloud Messaging | Free, and the only realistic Android option. Using FCM for *push* does not imply Firebase for *data* — see [architecture](architecture.md#why-not-firebase) |
| Admin 2FA | `django-otp` / `django-two-factor-auth` | Mandatory per [admin](admin.md#security) |
| Object storage | `django-storages` | S3-compatible; MinIO locally, Supabase Storage in phase 0 |
| Image handling | `pillow` + server-side resize | Listing photos on 3G — variants matter more than quality |
| Money in Dart | `decimal` / `intl` | **Never `double`.** Pula formatting is set explicitly, not from device locale. |
| Flutter state | `riverpod` or `bloc` | Either; pick one and do not mix |
| Flutter routing | `go_router` | The design's push / lateral / replace rules map onto it directly |
| Secure storage | `flutter_secure_storage` | Tokens |
| Biometrics | `local_auth` | Per-device enrolment ([database](database.md#opsdevice--where-a-push-can-land)) |
| SMS / OTP | Local aggregator, abstracted | Behind an interface from day one, as [payments](payments.md#architecture-requirement) requires of payment providers |

---

## Auth — adopt, and phase it

**Nothing here is written from scratch.** Django ships password hashing
(PBKDF2/Argon2), session handling, permissions and password reset in
`django.contrib.auth`, and
[`django-allauth`](https://docs.allauth.org/) + `dj-rest-auth` add
registration, email verification, token issuance and account management on top.
That is the adoption; writing our own password storage would be indefensible.

### Phase 0 — email, password, phone, names

SMS OTP needs an aggregator agreement and costs per message. Same argument as
[hosting](architecture.md#hosting-cost-before-there-is-an-audience): do not pay
for it before there is an audience.

So registration at build time captures **first name, surname, email, password
and phone number**, with email verification and phone stored **unverified**.

| Piece | Component |
|---|---|
| User model, hashing, reset | `django.contrib.auth` with a custom user model — **define this on day one**, it is near-impossible to change later |
| Registration, email verification | `django-allauth` |
| API token issuance | `dj-rest-auth`, or `djangorestframework-simplejwt` for short-lived access + refresh |
| Rate limiting | `django-ratelimit` / DRF throttling on login and reset |
| Per-device biometrics | `local_auth` in Flutter, unlocking a stored refresh token — unchanged by any of this |

### Phase 1 — phone verification, when SMS is affordable

The specification's identity model is **phone + OTP, one phone one account**
(FR-1.1, FR-1.2), and that is still the right end state: the target provider has
a phone number and may not use email. Phase 0 defers it; it does not replace it.

Two routes when the time comes, and the cheap one is worth knowing now:

- **Firebase Auth phone sign-in** carries a free monthly verification quota and
  needs no aggregator contract. Using Firebase for *identity verification* while
  keeping PostgreSQL for *data* is the same split already accepted for push
  notifications, and it does not reintroduce any of the
  [reasons Firebase was rejected as a database](architecture.md#why-not-firebase).
- **A local SMS aggregator** behind the same interface, which is the long-term
  answer and matches how [payments](payments.md#architecture-requirement)
  handles providers.

### What phasing this actually costs

Recorded because it is easy to wave through and it has teeth:

- **"One phone number, one account" is not enforceable in phase 0.** With phone
  unverified, two accounts can claim the same number. That rule is load-bearing
  in the [account model](design-system.md) — the number *is* the identity — so
  the phase 1 migration has a real conflict case to resolve, and the longer
  phase 0 runs the more conflicts accumulate. **Enforce uniqueness on the phone
  column from the start even while unverified**, which makes the problem a
  registration-time error instead of a migration-time mess.
- **More personal data, sooner.** Names and email land in the `identity` schema
  and are covered by erasure ([database](database.md#what-an-erasure-request-does)).
  The spec's phone-only model was deliberately minimal; this is a step away from
  data minimisation and should be a conscious one.
- **The design's onboarding screens assume OTP.** The four-box OTP entry and
  "SMS code on every new device" rule do not apply in phase 0. The register
  screen needs a variant, and the design project should be told
  ([design-deltas](design-deltas.md)).
- **`core.user` changes shape** — gains `email`, `password`, `first_name`,
  `last_name`, `phone_verified_at`. Better in the schema now than migrated in
  later.
- **Password reset needs email to work**, which means an email sender in phase 0
  — free tiers exist and this is minor, but it is not zero.

### Deliberately not adopted

- **A full auth-as-a-service platform** (Supabase Auth, Auth0) as the system of
  record. Django was chosen partly because the admin, the permission model and
  the domain layer share one user model; splitting identity into another service
  gives that up and complicates erasure, which has to be provable end to end.
  Firebase Auth as a *phone-verification service* in phase 1 is a narrower thing
  and is fine.
- **A booking/marketplace starter kit.** The booking machine has eleven states,
  three journey shapes and per-category verification. No kit models that, and
  bending one costs more than building.
- **Consent management as a service.** Granular versioned consent is a DPA
  artefact that must be queryable alongside every external post
  ([data-model](data-model.md)). It stays in our database.
- **A dispute/chargeback engine.** They assume the platform holds the money. It
  never does.

---

## To verify before committing

- [x] ~~PostGIS and privilege support on managed Postgres~~ — **moot on a
      self-managed VPS**, which is now the recommended route precisely because
      it gives superuser. The append-only journal needs `REVOKE`, custom roles
      and triggers; root removes the question. Only re-check this if a managed
      platform is chosen instead. See
      [architecture](architecture.md#hosting-cost-before-there-is-an-audience).
- [x] ~~Routing engine on ARM~~ — **resolved.** `ghcr.io/gis-ops/docker-valhalla/valhalla`
      publishes linux/arm64; verified against the registry manifest. Switched
      from OSRM, whose Docker Hub images are amd64-only and last published in
      July 2021.
- [x] ~~Botswana OSM extract size~~ — **83 MB** from Geofabrik. Small enough that
      routing throughput and preprocessing cost are both non-issues.
- [ ] `maplibre_gl` binary-size contribution against the 30 MB cap, measured on
      a real release build
- [ ] OSM road-network completeness for Gaborone and Francistown — good enough
      for routing is a lower bar than good enough for addressing, but it should
      be checked, not assumed
- [ ] OSRM `match` accuracy on low-end handset traces, which are noisier than
      the traces the service is usually demonstrated on
- [ ] Whether Botswana OSM extracts update often enough, or whether local
      contribution becomes part of the work
