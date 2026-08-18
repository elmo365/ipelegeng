# Work Handoff - Ipelege

**Saved:** Tuesday, 18 August 2026, 03:21 (SAST+0200)
**Branch:** main
**Last commit:** dcc4735 Rename app to Ipelege throughout docs; save session handoff

## What I was working on

Two things. First, importing the Claude Design project *"Ipelege app design
system"* (`012e55a7-8d3d-4aed-abf7-f1ab95fadf63`) into the repository. Second —
and this became most of the session — closing the specification gaps the import
exposed, because the design had run well ahead of the documents and several
areas had no plan at all.

The user's direction throughout: **plan everything before coding, leave nothing
to chance.** Coding was explicitly deferred to the next session.

Repository is still **pre-build**. It now holds 29 specification documents plus
a parked Flutter scaffold.

## Files changed this session

**New documents (8):**

- **A** `docs/design-system.md` — tokens, type scale, motion, navigation,
  components, extracted from the design into implementable form
- **A** `docs/design-deltas.md` — where the design superseded the specs, and the
  import's fidelity gaps
- **A** `docs/database.md` — physical schema: four PostgreSQL schemas, privilege
  model, indexes, event outbox, retention, erasure
- **A** `docs/admin.md` — the back office as a first-class subsystem, and the
  admin↔app loop
- **A** `docs/cancellation.md` — evidence-based adjudication, benchmarked
- **A** `docs/safety.md` — strangers meeting in person; what the badge stands
  behind
- **A** `docs/components.md` — adopt vs build: maps, routing, ledger, auth
- **A** `docs/test-strategy.md` — the document `sdlc-overview.md` had named as
  next

**Modified (11):** `README.md`, `docs/architecture.md`, `docs/categories.md`,
`docs/compliance.md`, `docs/data-model.md`, `docs/dfd.md`,
`docs/monetization.md`, `docs/open-questions.md`, `docs/project-plan.md`,
`docs/sdlc-overview.md`, `docs/system-flowcharts.md`.

**New directories:**

- **A** `design/` — archived design source (`ipelege-design-system.dc.html`,
  `android-frame.jsx`, `DESIGN-BRIEF.md`, `README.md`)
- **A** `app/` — **parked Flutter scaffold.** `flutter create` output plus
  `lib/theme/tokens.dart`. Not wired up; `main.dart` is still the generated
  stub.

## What is working

- **Design imported.** Text content, tokens, screen inventory and rationale are
  in the repo and cross-referenced.
- **OKLCH → sRGB conversion is done and accurate.** The design authors colour in
  OKLCH, which Flutter cannot parse. A conversion script produced the full
  light/dark palette, neutral ramp, status hues and nine category tile colours;
  the output is `app/lib/theme/tokens.dart` as an `AppPalette` ThemeExtension.
- **Flutter toolchain verified** — Flutter 3.41.6 stable, Dart 3.11.4, Java 18.
  Project created as `bw.co.ipelege`, deps added (`go_router`,
  `flutter_riverpod`, `intl`, `decimal`).
- **Documentation set is internally consistent.** New docs are linked from
  `README.md` and `sdlc-overview.md`; deltas are recorded rather than silently
  applied.

## What is NOT working yet

- **No application code.** `app/lib/main.dart` is the generated stub. The theme,
  router, navigation shells and screens are not built.
- **The design HTML archive is truncated.** The import tool caps reads at
  256 KiB and the source is larger. Cut mid-`stateMotion`, taking **eight
  specification tables** with it — `backRules` (11 rows, written as a spec),
  `navState`, `haptics`, `loadingStates`, `savedStates`, `motionSpecs`, and the
  remainder of `stateMotion`. `motionTokens` and `palRows` are recoverable from
  surviving parts of the file. Full list in `docs/design-deltas.md`.
- **No brand assets in the repo.** 18 PNGs live only in the design project.
- **Hosting is not provisioned.** User is creating the Oracle account and will
  supply SSH access.
- CodeGraph, Serena and claude-context remain as recorded in the previous
  handoff — CodeGraph now indexes the Dart and JSX files that exist.

## Decisions made (and why)

- **Backend: Django 5 + DRF + GeoDjango** on PostgreSQL 16 + PostGIS. Decisive
  factor was the admin: five mobile journeys cannot complete without a human
  (KYC approval, EFT matching, reversal adjudication, dispute resolution,
  revocation), and Django admin supplies most of that as configuration. Also
  Python `Decimal` for ledger money, and first-class PostGIS.
- **Admin is Django admin in the same project** — not a separate app, not
  Flutter Web. Shares the domain layer, so "approve a category" has one
  implementation. Built alongside each feature it unblocks.
- **Routing: Valhalla, not OSRM.** *Reversed mid-session on evidence.*
  `ghcr.io/gis-ops/docker-valhalla/valhalla` publishes linux/arm64;
  `osrm/osrm-backend` on Docker Hub is amd64-only and **last published July
  2021** while the project is on v26.8.0. Valhalla also has map matching
  (Meili), which was my stated reason for preferring OSRM and was simply wrong.
  Botswana extract is 83 MB, so OSRM's throughput edge is irrelevant.
- **Nine categories, not six.** "Small trades" split into Plumbing, Electrical
  and Tiling — each has different KYC requirements, so one grouping could not
  share a verification flow. Catering separated from Hire.
- **Hosting: self-managed VPS, not managed Postgres.** Root access is required —
  the append-only ledger needs `REVOKE`, custom roles and triggers, which some
  managed plans forbid. Oracle Always Free (2 OCPU ARM, 12 GB, Johannesburg) for
  phase 0; Botswana-resident for production.
- **Auth phased.** Phase 0 is email + password + phone + names via
  `django-allauth`; SMS OTP deferred until an aggregator is affordable. Phone is
  unique from day one even while unverified, so the phase 1 migration does not
  inherit duplicates.
- **Safety model is traceability, not prevention.** The user's framing, and it
  is right: *an app cannot prevent harm; it can record who, where and when, and
  make reporting fast.* A safety feature that cannot be operated is worse than
  its absence. So the panic button ships only when its destination is real, and
  anything producing a record beats anything promising a response.
- **Design deltas recorded, not applied wholesale.** Several touch compliance
  and the ledger and need sign-off — particularly the "wallet" naming.

## Things I tried that did NOT work - do not repeat these

- **Fetching the full design HTML via `DesignSync get_file`.** Hard 256 KiB cap.
  There is no offset or range parameter. Retrying returns the same truncation.
  Recover the missing tables from Claude Design directly.
- **Pulling binary assets through `get_file`.** Returns base64 into context;
  ~35k tokens per PNG, 18 PNGs. Not viable. Download them from the design
  project in a browser.
- **Reading OSRM ARM support from blog posts and GitHub issue pages.** Gave
  contradictory, undated answers. **Query the registry directly** —
  `https://hub.docker.com/v2/repositories/<repo>/tags/` for Docker Hub, and
  `ghcr.io/token?scope=repository:<repo>:pull` then the manifest endpoint with
  an OCI index Accept header for GHCR. That settled it in one call.
- **`git add --dry-run` for previewing scope.** The rtk hook filters its output
  to nothing. Use `git ls-files --others --exclude-standard`, or stage and
  inspect `git diff --staged --stat`.
- **`bc` for arithmetic in Bash.** Not installed in this Git Bash environment.
  Use shell arithmetic or node.
- **Asking two structured questions where one sentence would do.** The user
  called this out directly — it reads as forced. Recommend and proceed.

## Exact next steps to continue

1. **Build the Flutter shell.** `app/lib/theme/tokens.dart` is done. Still
   needed: `motion.dart` (the seven-token `Motion` class from
   `docs/design-system.md`, including the `MediaQuery.disableAnimations`
   helper), `typography.dart` (IBM Plex Sans onto the M3 `TextTheme`),
   `app_theme.dart`, and a `Money` formatter — Pula, explicit, never from device
   locale.
2. **Navigation.** `go_router` with two bottom-nav shells (Consumer: Home,
   Bookings, Messages, Account · Provider: Dashboard, Requests, Listings,
   Account), each tab keeping its own stack, and the push / lateral / replace
   rules from `docs/design-system.md#sideways-is-not-forward`.
3. **Wire `main.dart`** to the theme with Light/Dark/System, replacing the stub.
4. **Take SSH from the user and provision the Oracle box** — Docker Compose with
   Postgres 16 + PostGIS, Redis, MinIO, Caddy. All arm64-native.
5. **Recover the eight truncated design tables** from Claude Design before
   building navigation and feedback — `backRules` especially.
6. **Get a hosting quote from Digital Delta DC1** (BoFiNet, Block 8). It
   converts the residency blocker into arithmetic.
7. Remaining unwritten specs, in rough priority: offline & connectivity, API
   contract shape, environments & CI, observability, and a refresh of
   `CONTRIBUTING.md` — it still says the backend stack is undecided.

## Open questions / blockers

**External, unchanged:** EPS licensing position; data residency (now narrower —
local Tier III capacity is confirmed to exist, only the price is missing).

**Newly opened this session** — all in `docs/open-questions.md`:

- **What does the verified badge stand behind?** Today it means an admin saw a
  trade certificate; customers read it as *safe to let into my home*. Either
  raise the check or lower the claim. Doing neither is a misrepresentation.
  Biggest single open item.
- **`LEDGER_ACCOUNT`: one per provider, or one per provider per category?**
  Blocks the ledger schema.
- **The dispute window and full-trail retention are one decision, not two.** The
  window must be shorter, or evidence is deleted before it is needed.
- **The "wallet" naming** contradicts a binding constraint in `compliance.md`.
  Goes to counsel *with* the EPS question, not separately.
- **What happens to already-accepted bookings when a category is revoked.**
  Undefined, and it blocks both the revocation screen and safety suspension.
- Rentals viewings are invisible to the platform — in scope or explicitly out?
- Cancellation policy: who may raise a reversal, within what window, which
  causes qualify.

**Coordination:** the user is setting up the Oracle account and will provide SSH
during the next session. Do not block on it — the Flutter work does not need it.
