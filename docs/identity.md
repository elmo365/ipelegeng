# Brand identity in the app

**Status: partially imported.** Four brand assets are now in `design/assets/`
and are the source for the launcher icon, the adaptive icon and the in-app
mark. The larger cuts — the full lockups, the big mark and the wordmarks —
**cannot be fetched whole**, for a reason that is a hard constraint rather than
a cost.

Brand is the **first** thing the design's Foundations section defines, before
colour, type and components. It is sequenced accordingly in
[`build-order.md`](build-order.md), not treated as a finishing task.

[`app/test/identity/identity_test.dart`](../app/test/identity/identity_test.dart)
checks this file's claims against what is actually on disk, so the two cannot
drift apart.

---

## What is in the repo

| File | Size | Used for |
|---|---|---|
| `appicon-light.png` | 512 × 512 | Launcher icon at every density |
| `appicon-dark.png` | 512 × 512 | The dark cut, held for the themed icon |
| `adaptive-foreground.png` | 432 × 432 | Adaptive-icon foreground, **and** the in-app mark |
| `notification-icon.png` | 96 × 96 | Status-bar icon |

432 × 432 is exactly the Android adaptive-icon foreground size and 512 × 512 is
the Play Store icon size — the design exported for the platform deliberately.

`mark-icon.png` (130 × 165) is **not** here and is not needed:
`adaptive-foreground.png` is the same mark, transparent, at 432 px, so the app
takes its mark from that instead.

## What cannot be fetched, and why

`DesignSync.get_file` is **capped at 256 KiB**, and it truncates rather than
failing. These came back with `truncated: true` and decoded to a partial PNG —
a valid header with missing image data:

| File | Header size | Result |
|---|---|---|
| `mark-dark.png` | 540 × 706 | truncated |
| `wordmark-dark-new.png` | 1108 × 364 | truncated |
| `lockup-dark.png` | 1480 × 1160 | truncated |
| `logo-light-transparent.png` | 1536 × 1200 | truncated |

Every one decoded to exactly 196 608 bytes — the payload cut at the cap, not a
coincidence of file size.

They were decoded, inspected, and **deleted**. A corrupt PNG sitting in
`design/assets/` would eventually be shipped by someone who trusted the folder.

This is the *same 256 KiB server-side cap* that forced the mobile canvas to be
split into four parts, hitting a different file type. It cannot be worked around
from this repo — there is no range request and no pagination. **To get them:
export them from the design project directly, or re-save them smaller there.**

### A second way to lose a file, and the guard against it

`mark-icon.png` came back **complete and inline**, and was still corrupt on
disk: it was small enough that I copied the base64 out of the tool result by
hand instead of decoding a file, and the copy was imperfect. `Image.open()`
read its header fine and reported 130 × 165 — the corruption only surfaced on a
full `load()`.

So the rule is not "watch the size", it is **never transcribe a binary**:
decode from the file the tool wrote. Where a result is small enough to arrive
inline and there is no file, `scratchpad/decode_verify.py` writes to a temp
path, checks the PNG signature and the trailing `IEND` chunk, fully decodes it,
and only then moves it into place. A bad copy cannot land.

`identity_test.dart` re-checks the `IEND` chunk on every asset this file names,
so a truncated or mis-copied PNG fails the suite rather than shipping.

> **Corrected 2026-08-20.** This file, `design/README.md` and `design-deltas.md`
> all said the brand assets "live only in the design project" and that the
> import path was "prohibitively expensive" because binaries come back
> base64-encoded through the model's context. Both halves were wrong — and being
> wrong, they stopped anyone from trying for weeks. The assets are reachable via
> `DesignSync` against project `012e55a7-8d3d-4aed-abf7-f1ab95fadf63` (that id
> was sitting in `design/README.md` the whole time), and a large result is
> written to a **file on disk**, so it decodes without passing through context at
> all. The real constraint is the size cap above, which is a different thing and
> only affects three files.

## What the design specifies

`design/ipelege-ds-1-foundations.dc.html`, the Brand section, gives five
presentations of one lockup and the rule for choosing between them:

> Every asset above is cut from the one supplied lockup, so the mark keeps its
> ripple rings at every size and the wordmark keeps the blue i — the earlier set
> had been assembled from different exports and dropped both. Light versions are
> the supplied artwork with its white plate knocked out; dark versions are the
> supplied dark artwork untouched. **Use the full lockup above about 180 px, the
> horizontal lockup between 90 and 180, and the mark alone below that**, where
> the tagline stops being legible.

The splash artboard draws the mark at **88 px** and the wordmark at **176 px**,
so the app never needs the full lockup at all. It needs the mark (have it) and
the wordmark (blocked by the cap).

## Still stock, and what unblocks it

- **Launcher icon** — **done.** Five densities plus an adaptive icon
  (`mipmap-anydpi-v26/ic_launcher.xml`, white background per `ipelegeIconBg`,
  the design's foreground, and the same layer declared `<monochrome>` for
  Android 13 themed icons). Generated from the 512 px source, so no density is
  upscaled.
- **The mark in-app** — **done.** `app/assets/brand/mark.png`, rendered by
  `BrandMark`.
- **Splash wordmark** — blocked. The mark beside it is real; the wordmark is
  still set in type and labelled as a placeholder in `BrandLockup`.
- **Notification icon** — artwork pulled; not yet declared in the manifest.
- **iOS** — `ios/` is stock throughout and unverified: this project has only ever
  been built on Windows, so there is no way to compile or look at an iOS build
  here.
