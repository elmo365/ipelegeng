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
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session.dart';
import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../components/actions.dart';

class UnlockScreen extends ConsumerWidget {
  const UnlockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final session = ref.watch(sessionProvider);

    final first = (session.name ?? '').split(' ').first;

    void open() {
      ref.read(sessionProvider.notifier).unlock();
      context.goReplacing(Routes.home);
    }

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
                          first.isEmpty
                              ? "You're still signed in. Use your fingerprint "
                                    'to continue.'
                              : "You're still signed in as $first. Use your "
                                    'fingerprint to continue.',
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
              PrimaryAction(
                label: 'Use fingerprint',
                icon: Icons.fingerprint,
                onPressed: open,
              ),
              const SizedBox(height: 10),
              SoftAction(
                label: 'Enter device passcode',
                icon: Icons.dialpad,
                onPressed: open,
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
