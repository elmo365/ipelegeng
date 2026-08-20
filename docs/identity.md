# Brand identity in the app

**Status: the artwork is designed and is not in this repository.** The app ships
Flutter's stock blue-flag launcher icon, and no screen renders the mark.

This file exists because "add the logo" was drifting as a note. It is the
declared state of identity in the build, and
[`app/test/identity/identity_test.dart`](../app/test/identity/identity_test.dart)
checks the declaration against what is actually on disk. When the artwork
lands, that suite fails until this file is updated with it.

---

## What the design defines

`design/ipelege-ds-1-foundations.dc.html` carries a complete identity section —
five presentations of one lockup, with size rules:

| Presentation | Files the foundations canvas renders |
|---|---|
| Mark | `mark-light.png` · `mark-dark.png` · `mark-icon.png` |
| App icon | `appicon-light.png` · `appicon-dark.png` |
| Wordmark | `wordmark-light-new.png` · `wordmark-dark-new.png` · `wordmark-dark.png` |
| Horizontal lockup | `lockup-h-light.png` · `lockup-h-dark.png` |
| Full lockup, with tagline | `lockup-dark.png` · `logo-light-transparent.png` |

Those are the twelve the canvas itself displays. The full export set is larger —
it also carries `adaptive-foreground.png`, `notification-icon.png`,
`app-icon-light-512.png`, `app-icon-dark-512.png`, `lockup-horizontal.png`,
`wordmark-light.png` — and is listed in full under **Not imported** in
[`design-deltas.md`](design-deltas.md). Treat that list as canonical.

The canvas states the rules in its own words:

> Every asset above is cut from the one supplied lockup, so the mark keeps its
> ripple rings at every size and the wordmark keeps the blue i — the earlier set
> had been assembled from different exports and dropped both. Light versions are
> the supplied artwork with its white plate knocked out; dark versions are the
> supplied dark artwork untouched. **Use the full lockup above about 180 px, the
> horizontal lockup between 90 and 180, and the mark alone below that**, where
> the tagline stops being legible.

## What is missing, and why it cannot be fixed here

All twelve files live in the Claude Design project. `design/` in this repo holds
the five `.dc.html` canvases and nothing else — **the HTML came across, the
images never did**, so every `<img src="assets/…">` in the canvases points at
files this repository has never contained.

They cannot be reconstructed from the repo. They are cuts of supplied artwork,
and the canvas is explicit that a previous set assembled from mixed exports lost
the ripple rings and the blue *i*. Drawing a substitute would reintroduce exactly
that failure, so nothing here fakes one.

**To unblock: export the asset set from the design project into
`design/assets/`.** Everything below then becomes mechanical.

## What is already done, without the artwork

- **The cold-start flash is gone.** `launch_background.xml` used
  `?android:colorBackground`, which resolves to plain white under `Theme.Light`
  and plain black under `Theme.Black` — so every launch flashed a colour the app
  never uses. It now paints `@color/ipelegeLaunchBg`, defined as the palette's
  `screenBg2` in `values/colors.xml` and `values-night/colors.xml`. The test
  asserts both against `AppPalette`.
- **The app label is right**: `android:label="ipelege"`, lowercase, as the
  wordmark sets it.

## What is still stock, and waiting

- **Launcher icon** — `mipmap-*/ic_launcher.png` are Flutter's defaults. Needs
  `appicon-light.png` / `appicon-dark.png`, plus an adaptive icon
  (`mipmap-anydpi-v26/ic_launcher.xml` with foreground and background layers)
  so it is not letterboxed on Android 8+.
- **Splash artwork** — the launch drawable is a flat ground. The mark belongs on
  it once `mark-icon.png` exists. On Android 12+ this should move to the
  platform splash API (`windowSplashScreenBackground` +
  `windowSplashScreenAnimatedIcon`) rather than the legacy window background.
- **The mark in-app** — the design's splash, register and sign-in artboards all
  render the lockup. Phase 1 builds those screens, so it needs at minimum
  `lockup-dark.png` and `mark-icon.png`. See
  [`build-order.md`](build-order.md).
- **iOS** — `ios/` is stock throughout: `AppIcon.appiconset` and the
  `LaunchScreen` storyboard are Flutter's defaults. Untouched and unverified,
  because this project has only ever been built on Windows; there is no way to
  compile or look at an iOS build here.
