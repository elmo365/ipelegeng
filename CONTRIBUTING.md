# Working on this repository

## Current state

**Specification, plus the beginning of the app.** 29 documents in `docs/`, and a
Flutter shell in `app/` — theme, navigation and shared components, with
placeholder screens where the product screens will go. No backend code yet.

The stack is decided ([architecture.md](docs/architecture.md),
[components.md](docs/components.md)):

| | |
|---|---|
| Mobile | Flutter 3.41 / Dart 3.11, `go_router` + `flutter_riverpod` |
| Backend | Django 5 + DRF + GeoDjango |
| Database | PostgreSQL 16 + PostGIS |
| Admin | Django admin, in the same project, built alongside each feature it unblocks |
| Routing engine | Valhalla (self-hosted, OSM extract) |
| Hosting | Self-managed VPS — root access is required for the append-only ledger |

## Before writing any code

Read, in this order:

1. [docs/sdlc-overview.md](docs/sdlc-overview.md) — what exists and reading order
2. [docs/open-questions.md](docs/open-questions.md) — what is not decided
3. [docs/compliance.md](docs/compliance.md) — the constraints that shape architecture

Two decisions are still outstanding and block parts of the build: the **EPS
licensing position** and the **data residency choice** (local Tier III capacity
is confirmed; only the price is missing). Neither blocks the mobile shell.

Also open, and blocking specific screens rather than the whole build: what the
**verified badge stands behind**, the `LEDGER_ACCOUNT` grain, the dispute
window, and what happens to accepted bookings when a category is revoked. All
are in `open-questions.md`.

## Working on the app

```bash
cd app
flutter pub get
flutter analyze     # must be clean
flutter test        # must be green
```

**The rule that governs everything under `lib/`: the UI is central and
theme-driven. A screen never hardcodes a colour, radius, spacing value or type
style.** It uses plain Material widgets and lets `theme/app_theme.dart` decide
how they look. Where a screen genuinely needs a value, it comes from
`context.palette`, `Space` / `Radii` / `Touch`, or `AppTypography` — never a
literal. The point is that a design change lands in one file and every screen
follows.

```
app/lib/
  main.dart          ProviderScope + MaterialApp.router. Wiring only.
  core/              Pure Dart with logic. Money formatting lives here.
  theme/             tokens · dimens · typography · motion · app_theme · theme_mode
  routing/           routes · nav_tabs · navigation · app_router
  ui/shell/          one shell widget, rendered with whichever tab set
  ui/screens/        placeholders today, replaced one screen at a time
  ui/components/     the pieces screens compose from
```

A few rules that are easy to break by accident:

- **Money is `Decimal`, never `double`, and is formatted only through `Money` /
  `MoneyText`.** Pula formatting is explicit, never inherited from the device
  locale — thousands are separated by a space, negatives lead with a true minus,
  and there are always two decimal places.
- **Push, lateral and replace are three different movements.** Use
  `context.pushScreen` / `goLateral` / `goReplacing` from `routing/navigation.dart`
  rather than calling `go` or `push` directly, and read
  [design-system.md](docs/design-system.md#sideways-is-not-forward) before
  adding a route. Getting this wrong is how a user backs into a discarded flow
  and posts a second deduction.
- **Every path is a constant in `routing/routes.dart`.** No path literals in
  screens.
- **Every duration goes through `Motion.of(context, …)`**, which honours
  reduce-motion. Nothing loops — no shimmer, no pulse, no spinner. On these
  handsets that is a battery decision, not a polish one.
- **Fonts are bundled** in `app/assets/fonts`, not fetched at runtime. The app
  has to start on a bad connection.
- **Colour tokens are generated, not hand-written.** The design authors in
  OKLCH; `theme/tokens.dart` holds the converted sRGB values. If a token
  changes, re-run the conversion rather than eyeballing a hex code.

Tests, per [test-strategy.md](docs/test-strategy.md): pure Dart for anything
with logic, widget tests for components with states, and both themes covered —
a light token reused inside a dark widget is this design's most likely defect.

## Editing the specification

**Diagrams are Mermaid**, rendered natively by GitHub. Edit the text in the
code fence — never replace a diagram with an exported image. Text diagrams stay
diffable and cannot drift out of sync with the repo.

**Requirement IDs are stable.** `FR-3.7`, `NFR-6`, `CON-1` and so on are
referenced across documents, and should be referenced from commits, issues and
tests. Don't renumber; add new IDs and mark old ones superseded.

**Record decisions where they belong.** A decision made in conversation that
isn't written down here doesn't exist. When something moves from open to
decided, remove it from `open-questions.md` and write it into the relevant
document — don't leave it in both.

**Keep contradictions visible.** Several documents flag evidence that argues
against current decisions (see `comparable-platforms.md`). Those flags are
deliberate. Resolve them by deciding, not by deleting.

## Commit messages

Reference requirement IDs where applicable:

```
Add per-category verification model (FR-1.5)
Fix idempotency race in ledger posting (FR-5.8, NFR-4)
```
