# Device permissions and platform capabilities

**What the app asks the handset for, when it asks, and what happens when the
answer is no.**

This document exists because the permission surface was scattered across screens
and manifests with no single place stating the rules. On 2026-08-21 the manifest
declared exactly one permission — `USE_BIOMETRIC` — while the app already had a
location screen, a notification icon and a rides category whose whole flow
depends on capabilities nobody had written down.

Two principles govern everything below, and both come from the design rather
than from platform convention:

- **A battery is the user's lifeline.** The motion rules already refuse looping
  animations on this basis — *"a shimmer or a pulse holds the GPU awake and
  drains a battery that is the user's lifeline"*. Anything that holds the screen
  or the radio awake is held to the same standard: **scoped to the moment that
  needs it, never to the app**.
- **Every capability is refusable, and refusing costs the user nothing they
  cannot get another way.** A permission the app cannot function without is a
  permission that will be granted resentfully and revoked later.

> **Status: specified. The store lands in Phase 3.5; the manifest entries land
> in the phase that uses them.** The rides screens are Phase 5, so nothing here
> holds a screen awake yet — but the preference that will govern it is built
> early, because the alternative is jumping to Phase 7 to add one row. See
> §2b for why the same trick does not work for the overlay permission, and
> [`build-order.md`](build-order.md) for the phase.

---

## 1. Keep the display on during a ride

**Raised as a requirement on 2026-08-21: "for rides it's a critical part."**
It is. A passenger watching a driver approach and a driver following a route
are both *looking at a screen they are not touching*, which is precisely the
condition every handset's display timeout is designed to end. The default
Samsung timeout is 30 seconds. A navigation screen that blacks out every 30
seconds is not usable.

### This is an option, not a permission

Worth stating plainly because it changes the design: **Android needs no
permission for this.** It is a window flag — `FLAG_KEEP_SCREEN_ON`, or the
`wakelock_plus` package — and the app can simply set it. There is no dialog, no
grant, and nothing to refuse.

Which means the *user's* control over it has to be built deliberately, or it
does not exist. That is the option half of the requirement:

- **Preferences → "Keep the screen on during a ride"**, default **on**, on
  screen 18. Off is honoured absolutely — a user on 8% battery who turns this
  off has made a real decision about their evening.
- The app never re-enables it silently, and never asks twice.

### Scoped to the moment, never to the app

The flag goes on for **exactly** these states and comes off at every exit,
including a crash, a backgrounding, or the ride ending:

| On | Why |
|---|---|
| A ride is `ACCEPTED` or `IN_PROGRESS`, customer side | Watching the car approach |
| A driver is navigating to pickup or to destination | Following a route |
| Arrival attestation (screen 21) | A moment that ends in a tap, with a hand not on the phone |

**Off everywhere else, and that includes the rest of the booking flow.** A
plumber's booking status screen does not need the display held: nothing on it
moves, and the user is not watching a map. Applying this app-wide would be the
lazy version and would cost every non-rides user battery for nothing.

**It must be released on background, not only on dispose.** A wakelock that
survives the user switching apps is a battery bug that looks exactly like
nothing at all until someone's phone is flat.

---

## 2. Reaching a driver who is not in the app

**Also raised on 2026-08-21: "and also to draw over other apps."** The need is
real — dispatch is worthless if a driver misses requests while replying to a
message — but "draw over other apps" is one of three possible answers, and it
is the one Android has spent a decade discouraging. Recording all three, with
the constraints, because picking the wrong one costs a Play Store review.

The design already specifies what the moment *looks* like: a sheet that rises
in 180 ms, a ringtone, the one heavy haptic in the app, and the only looping
animation in the app (the countdown). What it does not specify is how that
moment reaches a driver whose phone is showing something else.

### Option A — Full-screen intent notification · **recommended**

A high-priority notification with `setFullScreenIntent()` launches the activity
over the lock screen and over other apps. This is what dispatch and calling
apps actually use, and it is what Android's own guidance points at.

- Needs `USE_FULL_SCREEN_INTENT`, plus `POST_NOTIFICATIONS` at runtime on
  Android 13+.
- **Android 14 (API 34) narrowed it.** The permission is now granted by default
  only to apps whose core function is calling or alarms; everything else must
  send the user to `MANAGE_APP_USE_FULL_SCREEN_INTENT` to grant it by hand.
  A ride-dispatch app has a reasonable claim to the category. It is not a
  guaranteed one, and that is the open question below.
- Degrades honestly: if the permission is absent, the same notification still
  arrives as a heads-up banner with the ringtone. The driver sees it; it just
  does not take over the screen.

### Option B — Draw over other apps

`SYSTEM_ALERT_WINDOW`. A true overlay, drawn above whatever is running.

- **Not a runtime dialog.** It cannot be requested with a prompt; the user must
  be sent to `Settings.ACTION_MANAGE_OVERLAY_PERMISSION` and toggle it there,
  then come back. Check with `Settings.canDrawOverlays()`.
- Play Store treats it as sensitive and rejects unjustified use. A dispatch
  overlay is justifiable, but it must be declared and defended.
- **Only worth it as a fallback**, for drivers on builds where Option A was
  refused or restricted. Never as the primary path, and never requested at
  first launch — ask at the moment a driver goes on duty, where the reason is
  self-evident.

### Option C — Foreground service · **required regardless of A or B**

Neither of the above helps if the process is dead. A driver who is *on duty*
needs a foreground service with its persistent notification for the whole
shift — that is also the only honest way to tell someone their location is
being used.

- `FOREGROUND_SERVICE`, and on Android 14+ a declared type:
  `FOREGROUND_SERVICE_LOCATION`.
- `ACCESS_FINE_LOCATION` while on duty. **`ACCESS_BACKGROUND_LOCATION` should
  be avoided** — a foreground service with the location type covers the on-duty
  case, and background location triggers the heaviest Play Store review there
  is.
- The notification says *"On duty — Ipelege is using your location"*, and
  tapping it goes to the on-duty screen. Going off duty stops the service the
  same second.

**Decision: build A + C, and treat B as a per-driver fallback offered only
after A is unavailable.** It is the combination with the lowest review risk and
the least battery cost, and it is the one that degrades into something useful
rather than into silence.

---

## 2b. Why permissions cannot be "set early and defaulted on"

Asked directly on 2026-08-21 — *"where will we have the permissions to draw
over screens, or do we set them early and wire the on/off later so we are not
forced to jump to Phase 7?"* The instinct is right for one of these two and
impossible for the other, and the difference is worth stating once so it is not
re-litigated.

**Keep-screen-on can be front-loaded, because it is not a permission.** It is a
window flag. There is nothing to grant, nothing to ask for, and nothing the OS
can refuse. On-by-default is safe, and the only thing that has to exist early
is somewhere to *store* the user's choice.

**`SYSTEM_ALERT_WINDOW` cannot be, for three reasons that are not about us:**

1. It is a **special** permission, not a runtime one. Declaring it in the
   manifest grants nothing, and **there is no API that can turn it on**. The
   user must open `Settings.ACTION_MANAGE_OVERLAY_PERMISSION` and toggle it by
   hand. "Default on" is not a state this permission has, in any phase.
2. **Play Store scans the manifest.** A sensitive permission declared with no
   feature behind it is a review flag and appears on the store listing. Every
   internal build for months would carry the cost with none of the benefit.
3. The same shape applies to `USE_FULL_SCREEN_INTENT`, whose default grant on
   Android 14+ is limited to calling and alarm apps, and to
   `FOREGROUND_SERVICE_LOCATION`, which needs a Play declaration form
   justifying a feature that would not yet exist.

**So the rule is: the manifest entry lands in the phase that uses it.** What
lands early is the *seam* — a settings store that already holds the preference,
and a capability interface shaped like the one `core/biometrics.dart` already
uses (`PlatformBiometrics` ships, a fake is the default, so a widget test never
needs a platform channel). Phase 5 then wires a real implementation behind an
interface that already exists, and no screen has to be built out of order.

**What this buys, beyond tidiness.** The settings store is not speculative
work: **dark mode is finished and unreachable.** Both themes, the full palette
and `themeModeProvider` all exist, and the only control that drives them is a
row on a screen nobody has built. A settings spine ships a completed feature
that is currently sitting behind a placeholder — see Phase 3.5 in
[`build-order.md`](build-order.md).

---

## 3. The rest of the surface, for completeness

| Capability | Permission | When asked | If refused |
|---|---|---|---|
| Biometric unlock | `USE_BIOMETRIC` | Never asked — no runtime grant | Passcode, promoted to primary. **Built and verified.** |
| Location for browse | `ACCESS_COARSE_LOCATION` | At the location screen, after consent | Manual area selection. Browsing still works. |
| Location on duty | `ACCESS_FINE_LOCATION` + FGS | Going on duty, not at install | Cannot go on duty. Stated plainly at the toggle. |
| Notifications | `POST_NOTIFICATIONS` (13+) | After the first booking is sent | Booking updates by SMS — already an option on the consent screen |
| KYC documents | Camera / photo picker | At the KYC upload step | Photo picker needs no permission on modern Android; prefer it |
| Full-screen dispatch | `USE_FULL_SCREEN_INTENT` | Going on duty | Heads-up banner + ringtone |
| Overlay dispatch | `SYSTEM_ALERT_WINDOW` | Only if the above is restricted | Option A's banner |

**Nothing here is requested at first launch.** Every row is asked at the moment
its reason is visible on screen, which is both the DPA-friendly reading and the
one that gets granted.

---

## Open questions

- **Does Ipelege qualify for `USE_FULL_SCREEN_INTENT` by default on Android
  14+?** The policy names calling and alarm apps. Ride dispatch is arguably
  neither, in which case every driver must grant it by hand and the onboarding
  has to carry that. **This needs checking against current Play policy before
  Phase 5 designs the on-duty flow**, because the answer changes the screen.
- **Is the keep-screen-on default correct at `on`?** It is the right default for
  usability and the wrong one for a user on a failing battery. The alternative
  is defaulting off and offering it the first time a ride starts.
- Whether a driver's on-duty foreground service should keep the display on as
  well, or only during active navigation. Holding it for a whole shift would be
  a significant battery cost for a driver waiting for work.

See [`open-questions.md`](open-questions.md) for the project-wide list.
