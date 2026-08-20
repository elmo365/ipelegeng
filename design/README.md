# design/

Archived source of the Ipelege UI design, imported from Claude Design.

| File | What it is |
|---|---|
| `ipelege-ds-1-foundations.dc.html` | Five decisions, journey map, brand / colour / type / components, visual direction |
| `ipelege-ds-2-customer.dc.html` | Entry & account, onboarding, home, browse, listing detail, booking, tracking, rate & review |
| `ipelege-ds-3-provider.dc.html` | Mode switcher, provider home, my categories, inbox, wallet, top up, become a provider, KYC |
| `ipelege-ds-4-specs.dc.html` | Account / preferences / security / notifications / data, cancellation & attestation, light & dark, the nine-category matrix, navigation, motion, feedback, **and the `PAL` token object** |
| `ipelege-admin-back-office.dc.html` | The desktop back office — its own token set |
| `android-frame.jsx` | Device-frame component the mockups sit in. Presentation scaffold; no bearing on the build. |
| `DESIGN-BRIEF.md` | The brief the work started from. Historical — the design has moved past it. |

## Where to read this

Don't read the `.dc.html` files for implementation. They are Claude Design
pages: markup plus `{{ }}` template bindings resolved at render time by a
runtime shim (`support.js`) that is not in this repo, and they reference brand
PNGs that are not here either. They will not render locally.

Read instead:

- [`docs/design-system.md`](../docs/design-system.md) — mobile tokens, type
  scale, surface treatment, motion, navigation, components.
- [`docs/admin-design.md`](../docs/admin-design.md) — the desktop back office,
  which has **its own token set** and deliberately shares almost none of the
  app's.
- [`docs/design-deltas.md`](../docs/design-deltas.md) — where the design decided
  things the specification documents left open or had wrong.

The live, complete, rendering version is the Claude Design project
`012e55a7-8d3d-4aed-abf7-f1ab95fadf63` — *Ipelege app design system*.

## Split, so nothing is truncated

The design tool caps a single file read at **256 KiB** and the mobile page had
grown past 512 KB, so a single-file pull cut mid-`KYC Movers & hauling` and lost
a third of the content. On 2026-08-20 the page was split in Claude Design into
the four parts above — each under the cap, all four returning
`truncated: false`.

**485 KB total, against the 262 KB the single-file read returned.** That
recovered the `PAL` token object (both modes), the navigation / motion /
feedback specifications, six settings screens, arrival attestation, and the
nine-category customer-and-provider matrix.

Every `.dc.html` here is what the project returned on 2026-08-20. The earlier
snapshot was deliberately deleted rather than kept alongside, so nothing here is
a blend of two vintages.

Each screen label renders in **both light and dark**, so the labels are roughly
twice that many mockups.

If the page grows again and a part starts returning `truncated: true`, split
that part further — the cap is server-side, so it cannot be worked around from
the repo.

## What is missing from the archive

- **All brand assets.** Eighteen PNGs (marks, wordmarks, lockups, app icons,
  adaptive and notification icons) live only in the design project. The import
  path returns binary files base64-encoded through the model's context, which is
  prohibitively expensive for images. Download them directly when wiring the
  launcher icon and splash.
- **`support.js`.** Generated Claude Design runtime, no bearing on the build.

Treat the archived `.dc.html` files as a **text source of truth**, not runnable
pages.

Re-pulled and split, 2026-08-20.
