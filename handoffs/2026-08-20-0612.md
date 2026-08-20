# Work Handoff - Ipelege

**Saved:** Tuesday, 18 August 2026, 06:15 (SAST+0200)
**Branch:** main
**Last commit:** e06616c Import design system; close specification gaps; decide stack

## What I was working on

Building, at last. The previous session ended with the specification closed and
coding deliberately deferred; this session executed steps 1–3 of its next-steps
list — the Flutter shell, navigation, and wiring `main.dart` — then swept the
documentation so nothing still describes the repo as pre-build.

The user's direction, given mid-session and worth carrying forward: **theme-based
central UI, not elements hardcoded per screen.** That shaped every file below.

The repository is no longer specification-only. It has an app that runs.

## Files changed this session

**Theme — the central UI layer (new):**

- **A** `app/lib/theme/dimens.dart` — `Space` (4 px grid), `Radii`, `Touch`
  (48 dp floor), `Breakpoints` + `WindowClass`
- **A** `app/lib/theme/typography.dart` — IBM Plex Sans onto the M3 `TextTheme`,
  Plex Mono figure styles, `AppFonts`
- **A** `app/lib/theme/motion.dart` — the seven `Motion` tokens, the
  `disableAnimations` helper every duration routes through, and `PageMotion`
  (push / lateral / replace)
- **A** `app/lib/theme/app_theme.dart` — `AppTheme.light` / `AppTheme.dark`.
  Buttons, inputs, chips, cards, nav bar, sheets, dialogs, list tiles, switches
  all themed from the palette
- **A** `app/lib/theme/theme_mode.dart` — `themeModeProvider`, session-only
- **M** `app/lib/theme/tokens.dart` — added `CategoryToken` and the nine
  `Categories`, which were converted last session but never landed in code.
  Also moved `library;` above the imports, where Dart requires it

**Money (new):** `app/lib/core/money.dart` — `Money` + `PulaFormat` extension.

**Navigation (new):** `app/lib/routing/routes.dart` (every path as a constant),
`nav_tabs.dart` (both tab sets as data, `AppMode`), `navigation.dart` (the three
movements as named methods), `app_router.dart` (two sibling
`StatefulShellRoute`s, one branch per tab).

**UI (new):** `app/lib/ui/shell/app_shell.dart`,
`app/lib/ui/screens/placeholder_screen.dart`, and
`app/lib/ui/components/` — `status_chip.dart`, `category_tile.dart`
(+ `CategoryGrid`, `CategoryTileEntrance`), `money_text.dart`, `info_note.dart`.

**Wiring:** **M** `app/lib/main.dart` — `ProviderScope` + `MaterialApp.router`,
Light/Dark/System. The generated stub is gone.

**Assets:** **A** `app/assets/fonts/` — IBM Plex Sans 400/500/600/700 and Plex
Mono 400/600 as TTF, plus `LICENSE.txt` (OFL). **M** `app/pubspec.yaml` declares
them.

**Tests (new, 47 passing):** `app/test/core/money_test.dart`,
`app/test/theme/theme_test.dart`, `app/test/routing/navigation_test.dart`,
`app/test/ui/components_test.dart`.

**Documentation swept for staleness:** **M** `CONTRIBUTING.md` (rewritten — the
stack is decided, and it now carries the app conventions), **M** `README.md`
(status), **M** `docs/sdlc-overview.md` (phases 4 and 5), **M**
`docs/design-system.md` (new "Where this lives in code" map).

## What is working

- **`flutter analyze` is clean and `flutter test` is green — 47 tests.** Money
  formatting (the suite `test-strategy.md` asks for), both themes, navigation,
  components in light and dark.
- **The app boots into the consumer shell** and the tests drive it: tabs keep
  their own stacks across switches, tapping the current tab returns it to its
  root, a mode switch replaces the bar and leaves no consumer tab behind, and
  the wallet is reachable only by pushing from the dashboard.
- **The theme is genuinely central.** Components read `context.palette`, `Space`,
  `Radii` and `AppTypography`; no screen carries a colour or a size. A design
  change lands in `app_theme.dart` and every screen follows.
- **Fonts are bundled**, so type is correct offline and on first run.
- **CodeGraph is current** — its watcher indexed every file as it was written and
  it reports call paths and test coverage for the new symbols.

## What is NOT working yet

- **No product screens.** Every route renders `PlaceholderScreen`. The screen
  inventory in `design-system.md` is untouched work.
- **Never run on a device or emulator.** Everything above is `flutter test`,
  which uses Ahem-substituted fonts and no real GPU. The design's own rule is to
  test motion on an entry-level handset; that has not happened.
- **`ThemeMode` does not persist.** It resets to system on every launch; it needs
  the settings store, which needs the backend.
- **Serena cannot read Dart in this project until VS Code is relaunched.**
  `.serena/project.yml` had `languages: []`; it is now `["dart"]`, but the MCP
  server caches project config at startup and re-activating does not reload it.
  Note `.serena/` and `.codegraph/` are both gitignored, so that fix is local
  only and must be repeated on any other machine.
- Unchanged from last session: eight design tables still lost to the import
  truncation, 18 brand PNGs still only in the design project, hosting still
  unprovisioned.

## Decisions made (and why)

- **Central, theme-driven UI — the user's instruction, adopted as the governing
  rule of `lib/`.** Screens use plain Material widgets; `app_theme.dart` decides
  how they look. Written into `CONTRIBUTING.md` and `design-system.md` so it
  survives this session.
- **Bundle IBM Plex rather than use `google_fonts`.** `google_fonts` fetches at
  runtime by default, and this app has to start on a bad connection. ~1.1 MB of
  TTF against a 30 MB budget is the right trade. Pulled from the IBM/plex GitHub
  releases — Google Fonts' CSS API serves woff2, which Flutter cannot use.
- **Two *sibling* shell routes, not one nested set.** This is what makes a mode
  switch discard the other side's stack instead of suspending it, which is what
  the design means by "replaces the bar rather than adding to it".
- **The three movements got named methods** (`pushScreen` / `goLateral` /
  `goReplacing`) rather than leaving screens to call `go` and `push`. They look
  alike on screen and are easy to confuse; naming them puts the stack rule in one
  file. Getting it wrong is how a user backs into a discarded flow and posts a
  second deduction.
- **Money is never formatted at a call site.** `Money` and `MoneyText` are the
  only paths, so a figure cannot pick up the device locale. Separator is U+202F
  (narrow no-break space, so a line cannot break `P1 250.00` in half), minus is
  U+2212.
- **Category hues generated, not eyeballed.** Reconverted `oklch(0.55 0.12 h)` to
  sRGB with the same maths as the palette. Two clip a channel at the gamut edge;
  that is recorded in the token doc comment rather than hand-corrected.
- **Placeholder screens rather than stub widgets** — they take everything from
  the theme, so replacing one with a real screen changes behaviour without
  changing the look.

## Things I tried that did NOT work - do not repeat these

- **Bash heredocs for large Dart files.** A `cat > file <<'EOF'` of ~350 lines
  failed to open the heredoc at all and bash then choked on the first apostrophe.
  Smaller files were fine. Use the Write tool for anything substantial.
- **Google Fonts' CSS API for the font files.** Every `@font-face` it serves is
  woff2, which Flutter does not support, and there is no user-agent that changes
  that any more. The IBM/plex GitHub releases ship per-family zips with a
  `fonts/complete/ttf/` directory — take them from there.
- **Re-activating a Serena project to pick up a config change.** It returns
  success and keeps the cached config; `activate_project` on another project and
  back does not help either. It needs a full VS Code relaunch.
- **Asserting `findsOneWidget` on a pushed screen's title.** `PlaceholderScreen`
  renders its title twice — app bar and body — so the finder matches two. Use
  `findsWidgets`.
- `Decimal.signum` is deprecated in `decimal` 3.x. Use `.sign`; it is still an
  `int`, so comparisons carry over unchanged.

## Exact next steps to continue

1. **Relaunch VS Code** so Serena picks up `languages: ["dart"]`. Nothing else
   restores its symbol tools.
2. **Run the app on a real handset.** Everything so far is `flutter test`. Check
   the type scale, the nav bar, and that no motion loops.
3. **Build the first real screens, in this order:** consumer Home (category grid
   is already a component), category browse, listing detail. They are the
   shortest path to something demonstrable and they exercise the push/lateral
   rules on real content.
4. **Recover the eight truncated design tables** from Claude Design before back
   behaviour or feedback is built — `backRules` especially, since
   `app_router.dart` currently has only the general rule to follow.
5. **Take SSH from the user and provision the Oracle box** — Docker Compose with
   Postgres 16 + PostGIS, Redis, MinIO, Caddy, all arm64-native.
6. **Get a hosting quote from Digital Delta DC1** (BoFiNet, Block 8). It turns
   the residency blocker into arithmetic.
7. Remaining unwritten specs: offline & connectivity, API contract shape,
   environments & CI, observability.

## Open questions / blockers

**External, unchanged:** EPS licensing position; data residency (local Tier III
capacity confirmed, only the price is missing).

**Blocking specific screens** — all in `docs/open-questions.md`, none of them
blocked this session's work:

- **What the verified badge stands behind.** `StatusChip.verified` renders the
  claim today; what the claim means is still undecided. Biggest single item.
- **`LEDGER_ACCOUNT`: one per provider, or one per provider per category.**
  Blocks the ledger schema.
- **The dispute window and full-trail retention are one decision, not two.**
- **The "wallet" naming** contradicts a binding constraint in `compliance.md`.
  Goes to counsel with the EPS question.
- **What happens to already-accepted bookings when a category is revoked.**
- Rentals viewings invisible to the platform — in scope or explicitly out?
- Cancellation policy: who may raise a reversal, in what window, which causes
  qualify.

**Coordination:** the user is setting up the Oracle account and will provide SSH.
The app work does not block on it.
