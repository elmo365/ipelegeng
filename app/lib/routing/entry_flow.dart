/// Where the entry flow goes next — the one place that decides.
///
/// Three screens used to answer this question and they answered it slightly
/// differently: the verify screen picked the enrolment offer, the enrolment
/// screen picked location, and nothing at all picked what a launch should do.
/// Instant verification then added a fourth caller that skips the verify screen
/// entirely, and four copies of a ladder is four chances to drop a rung.
///
/// Both functions here are pure. They take a [Session] and return a path; they
/// touch no `BuildContext`, which is what lets the whole entry flow be tested
/// without pumping a widget.
///
/// The spec is docs/entry-flow.md — §5.2 for [launchRoute], §2 for
/// [nextEntryRoute]'s ladder.
library;

import '../core/session.dart';
import 'routes.dart';

/// Where a **launch** lands, given whatever was restored from the device store.
///
/// Made once, before anything is drawn, and made in the router rather than in a
/// screen's `initState`: a screen that decides where to go can be reached by
/// another route that skips the decision, which is how `/unlock` came to be
/// unreachable by any real path.
///
/// A returning member never sees `/welcome`. It is a marketing screen, and
/// showing it to someone who already has an account is what made a reopen cost
/// an SMS — they had no way forward but "Sign in", and two of those in a row
/// is a `too-many-requests` from the sender.
String launchRoute(Session session) => switch (session.stage) {
  // Restored and locked by SessionCodec.reopened. Always, whatever the
  // biometric preference says — that preference decides what /unlock offers
  // first, not whether it appears.
  SessionStage.locked => Routes.unlock,

  // Verified on a superseded consent version, or on none. FR-1.10 wants this
  // settled before anything else proceeds, so it is a launch destination and
  // not something the router catches on the next movement.
  SessionStage.needsConsent => Routes.consent,

  // Nothing was stored, or what was stored is not worth resuming into. A
  // visitor gets the welcome screen; browsing is free under UC-4.
  //
  // `active` cannot occur here — a restore never produces one (see
  // SessionCodec.reopened) — and `confirmingNumber` is never persisted. Both
  // are listed rather than defaulted so that adding a stage forces a decision
  // here instead of silently falling through to the welcome screen.
  SessionStage.none ||
  SessionStage.confirmingNumber ||
  SessionStage.active => Routes.splash,
};

/// Where a **just-verified** session goes, whether the code was typed, read by
/// the platform, or never sent at all.
///
/// The order is the design's: consent, then the biometric offer, then location,
/// then home. Each rung is skipped when it has already been answered — and
/// *answered* means asked, not agreed. A refusal is an answer.
String nextEntryRoute(Session session) {
  // Consent first and unconditionally. A new account reaching this through
  // instant verification has never seen a consent card, because there was no
  // code screen to carry one.
  if (session.stage == SessionStage.needsConsent) return Routes.consent;

  // "Offered once after first OTP, declinable without penalty." Spent is spent.
  if (!session.biometricOffered) return Routes.biometricEnrolment;

  // Asked, not granted — refusing location is a supported way to use the app,
  // and re-asking on every entry would make "Choose my area instead" read as a
  // holding position rather than a choice.
  if (!session.locationAsked) return Routes.location;

  return Routes.home;
}
