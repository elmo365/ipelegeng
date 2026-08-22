/// Biometric enrolment — part 4, screen 20.
///
/// "Offered once after first OTP, declinable without penalty. The two
/// reassurances are cards because that is the actual objection."
///
/// Three things here are the design rather than layout:
///
/// - **Offered once.** [SessionController.answerBiometricOffer] records that
///   the offer was made whichever way it is answered, so declining is spent
///   rather than deferred. Nagging is how a permission prompt gets refused
///   permanently.
/// - **The objection is privacy, not convenience**, so the two cards answer
///   that and nothing else: it stays on the device, and Ipelege never sees it.
/// - **"Not now" carries no penalty and no warning.** The cost of declining is
///   stated on the Security screen — an OTP each time the app opens — and not
///   used as pressure here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session.dart';
import '../../../routing/entry_flow.dart';
import '../../../routing/navigation.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../components/actions.dart';
import '../../components/choice_cards.dart';

class BiometricEnrolmentScreen extends ConsumerWidget {
  const BiometricEnrolmentScreen({super.key});

  /// Verbatim from the canvas. Both are about where the fingerprint goes, not
  /// about what it unlocks.
  static const _reassurances = <String>[
    'Stays on this device only',
    'Ipelege never sees your fingerprint',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    void answer({required bool enrol}) {
      ref.read(sessionProvider.notifier).answerBiometricOffer(enrol: enrol);
      // Location is the next rung, and only if it has not been asked. The
      // ladder is [nextEntryRoute]'s rather than this screen's — it used to
      // read `locationGranted`, which meant a refusal looked identical to
      // never having been asked and produced the screen again on every entry.
      context.goReplacing(nextEntryRoute(ref.read(sessionProvider)));
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          // 34 / 24 / 24, from the artboard.
          padding: const EdgeInsets.fromLTRB(Space.x6, 34, Space.x6, Space.x6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          // `shRaise` in the canvas — our shadowCard.
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
                        'Skip the code next time?',
                        textAlign: TextAlign.center,
                        style: text.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: Space.x2),
                      ConstrainedBox(
                        // 262 px in the artboard, not a round number — it is
                        // set so the sentence breaks after "instead of".
                        constraints: const BoxConstraints(maxWidth: 262),
                        child: Text(
                          'Use your fingerprint to open Ipelege instead of '
                          'waiting for an SMS.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            fontSize: 13.5,
                            height: 1.55,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.x5),
                      for (final line in _reassurances) ...[
                        // `pal.verifiedText` here, not creditColor and not
                        // Status.success — the enrolment artboard and the
                        // location artboard use different greens on the same
                        // glyph, and each one follows its own screen.
                        PromiseCard(
                          label: line,
                          iconColor: palette.verifiedText,
                        ),
                        const SizedBox(height: 9),
                      ],
                    ],
                  ),
                ),
              ),
              PrimaryAction(
                label: 'Turn on biometric unlock',
                icon: Icons.fingerprint,
                onPressed: () => answer(enrol: true),
              ),
              const SizedBox(height: 10),
              // No warning attached, and no accent colour. Declining is free,
              // and the cost of it is stated on the Security screen instead of
              // being used as pressure here.
              QuietAction(
                label: 'Not now',
                onPressed: () => answer(enrol: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
