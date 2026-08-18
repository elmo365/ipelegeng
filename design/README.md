# design/

Archived source of the Ipelege UI design, imported from Claude Design.

| File | What it is |
|---|---|
| `ipelege-design-system.dc.html` | The design system and full screen set, as authored. **Truncated at 256 KiB** by the import tool — see below. |
| `android-frame.jsx` | Device-frame component the page wraps every mockup in. Presentation scaffold; no bearing on the Flutter build. |
| `DESIGN-BRIEF.md` | The brief the design work started from. Historical — the design has moved past it. |

## Where to read this

Don't read the `.dc.html` for implementation. It is a Claude Design page: markup
plus `{{ }}` template bindings resolved at render time by a runtime shim
(`support.js`) that is not in this repo, and it references brand PNGs that are
not in this repo either. It will not render locally.

Read [`docs/design-system.md`](../docs/design-system.md) instead — tokens, type
scale, motion, navigation and components, extracted and made implementable. Then
[`docs/design-deltas.md`](../docs/design-deltas.md) for the places where the
design decided things the specification documents left open or had wrong.

The live, complete, rendering version is the Claude Design project:
`012e55a7-8d3d-4aed-abf7-f1ab95fadf63` — *Ipelege app design system*.

## What is missing from the archive

- **The tail of the page.** The import cut mid-`stateMotion`, taking eight
  specification tables with it — the back-button rules, state restoration,
  haptics, loading bands and saved-state tables among them. Full list and
  recovery notes in
  [`docs/design-deltas.md`](../docs/design-deltas.md#truncated-in-import).
- **All brand assets.** Eighteen PNGs (marks, wordmarks, lockups, app icons,
  adaptive and notification icons) live only in the design project. Pull them
  when wiring the launcher icon and splash.
- **`support.js`.** Generated Claude Design runtime.

Imported 2026-08-17.
