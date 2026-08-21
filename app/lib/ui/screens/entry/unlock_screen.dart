/// Biometric unlock, with the passcode fallback.
///
/// "Passcode is a full card of equal weight, not fine print — broken or absent
/// sensors are common on the target hardware." That sentence is the whole
/// design of this screen: the fallback is a [SoftAction] directly under the
/// primary, not a link at the bottom.
///
/// **Biometry unlocks; it never authenticates.** Both buttons reopen the same
/// session, which is why [SessionController.unlock] takes no argument saying
/// which one was used. "Sign in as someone else" is the only path that
/// actually re-authenticates, and it goes back through phone and OTP.
///
/// **Wired to the platform 2026-08-21.** Until then both buttons called
/// `unlock()` directly and no prompt was ever shown. They now go through
/// [Biometrics], and the screen implements the state the journey map names as
/// *"biometry unavailable or refused → passcode"*:
///
/// - **No usable sensor** — the passcode is promoted to the primary action and
///   the fingerprint button is not drawn at all. On a handset with no reader,
///   the passcode is not a fallback; it is the only way in, and drawing it as
///   second best would misdescribe it.
/// - **Refused or cancelled** — nothing is said. A cancelled prompt is a change
///   of mind, not an error, and the other way in is already on screen.
/// - **Reported unavailable mid-prompt** — the screen collapses to the
///   passcode-only layout rather than leaving a button that can only fail.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/biometrics.dart';
import '../../../core/session.dart';
import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../components/actions.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  /// Null until the platform has answered. The fingerprint button is drawn
  /// optimistically in the meantime rather than appearing a frame late — the
  /// check is fast, and a button that pops in reads as a glitch.
  BiometricAvailability? _availability;

  /// One prompt at a time. `authInProgress` is a real error from the platform
  /// and a double tap is the easiest way to cause it.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final availability = await ref.read(biometricsProvider).availability();
    if (mounted) setState(() => _availability = availability);
  }

  /// Both buttons end here. Neither authenticates — see the file comment.
  Future<void> _open(BiometricPrompt prompt, String reason) async {
    if (_busy) return;
    setState(() => _busy = true);

    final outcome = await ref
        .read(biometricsProvider)
        .authenticate(prompt: prompt, reason: reason);

    if (!mounted) return;
    setState(() => _busy = false);

    switch (outcome) {
      case BiometricOutcome.ok:
        ref.read(sessionProvider.notifier).unlock();
        context.goReplacing(Routes.home);
      case BiometricOutcome.unavailable:
        // "Biometry unavailable or refused → passcode." The screen changes to
        // say so rather than leaving a button that can only fail.
        setState(() => _availability = BiometricAvailability.unavailable);
      case BiometricOutcome.refused:
        // Deliberately silent. A cancelled prompt is a change of mind, not an
        // error, and the passcode is already on screen.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final session = ref.watch(sessionProvider);

    final first = (session.name ?? '').split(' ').first;
    final biometricsOffered =
        _availability != BiometricAvailability.unsupported &&
        _availability != BiometricAvailability.unavailable;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.x6,
            Space.x10,
            Space.x6,
            Space.x6,
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: palette.cardBg,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(34),
                          ),
                          boxShadow: palette.shadowCard,
                        ),
                        child: Icon(
                          Icons.fingerprint,
                          size: 50,
                          color: palette.accentText,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Unlock Ipelege',
                        style: text.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: Space.x2),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 250),
                        child: Text(
                          // The instruction has to match the buttons under it.
                          // Telling someone to use a fingerprint on a handset
                          // with no sensor is the kind of copy that makes
                          // people think the app is broken rather than their
                          // phone.
                          [
                            first.isEmpty
                                ? "You're still signed in."
                                : "You're still signed in as $first.",
                            if (biometricsOffered)
                              'Use your fingerprint to continue.'
                            else
                              'Use your device passcode to continue.',
                          ].join(' '),
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            height: 1.55,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // With no usable sensor the passcode is promoted to the primary
              // rather than left as the quieter of two cards. It is not a
              // fallback on this handset — it is the only way in, and drawing
              // it as second best would be a lie about that.
              if (biometricsOffered) ...[
                PrimaryAction(
                  label: 'Use fingerprint',
                  icon: Icons.fingerprint,
                  onPressed: _busy
                      ? null
                      : () =>
                            _open(BiometricPrompt.biometric, 'Unlock Ipelege'),
                ),
                const SizedBox(height: 10),
                SoftAction(
                  label: 'Enter device passcode',
                  icon: Icons.dialpad,
                  onPressed: _busy
                      ? null
                      : () => _open(
                          BiometricPrompt.deviceCredential,
                          'Unlock Ipelege',
                        ),
                ),
              ] else
                PrimaryAction(
                  label: 'Enter device passcode',
                  icon: Icons.dialpad,
                  onPressed: _busy
                      ? null
                      : () => _open(
                          BiometricPrompt.deviceCredential,
                          'Unlock Ipelege',
                        ),
                ),
              const SizedBox(height: Space.x2),
              InlineLink(
                prefix: '',
                action: 'Sign in as someone else',
                onTap: () {
                  ref.read(sessionProvider.notifier).signOut();
                  context.goReplacing(Routes.signIn);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
