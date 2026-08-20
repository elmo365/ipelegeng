/// The auth gate — UC-4.
///
/// "The wall sits at the booking action, not at launch, and names the provider
/// who needs the number."
///
/// It is a **sheet, not a route**, and that is the design rather than a
/// shortcut: the listing stays visible behind it, dimmed, so refusing does not
/// mean losing your place. "Keep looking around" dismisses back onto the same
/// screen. A full-page interstitial would make browsing feel like it had been
/// taken away, which is the opposite of what UC-4 grants.
///
/// Naming the provider is the other half. "Sign in to continue" is a policy;
/// "so Kabelo can reach you about this job" is a reason.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session.dart';
import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../components/actions.dart';

/// Ask for an account if there is not one yet.
///
/// Returns true when the caller may proceed. The call site reads as the rule:
/// `if (!await requireAccount(...)) return;`
Future<bool> requireAccount(
  BuildContext context,
  WidgetRef ref, {
  required String providerName,
  required String providerFirstName,
}) async {
  if (ref.read(sessionProvider).canBook) return true;

  await showModalBottomSheet<void>(
    context: context,
    // The root navigator, not the tab's. A tab's Navigator has its pages
    // managed declaratively by go_router, and an imperative route pushed onto
    // it makes the router re-sync on pop — which takes the listing underneath
    // down with the sheet. The gate also *should* sit above everything: it is
    // not a step inside the Home tab's stack.
    useRootNavigator: true,
    isScrollControlled: true,
    // The listing stays legible behind it. The canvas draws the screen at 35%,
    // so the barrier is light rather than the Material default black-54.
    barrierColor: Brand.navy.withValues(alpha: 0.45),
    builder: (context) => _AuthGateSheet(
      providerName: providerName,
      providerFirstName: providerFirstName,
    ),
  );

  // Never true on return: signing in replaces the route, so this sheet's
  // caller is gone by then. Returning false keeps the caller from acting on a
  // dismissal as though it were consent.
  return false;
}

class _AuthGateSheet extends StatelessWidget {
  const _AuthGateSheet({
    required this.providerName,
    required this.providerFirstName,
  });

  final String providerName;
  final String providerFirstName;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, Space.x2, 22, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.selectedBg,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
            child: Icon(
              Icons.lock_open,
              size: 24,
              color: palette.accentText,
            ),
          ),
          const SizedBox(height: Space.x4),
          Text(
            'Sign in to book',
            style: text.titleLarge?.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Space.x2),
          Text(
            'Browsing is free. We only need your number so '
            '$providerFirstName can reach you about this job.',
            style: text.bodyMedium?.copyWith(
              height: 1.55,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          PrimaryAction(
            label: 'Continue with phone number',
            icon: Icons.phone,
            onPressed: () {
              Navigator.of(context).pop();
              context.pushScreen(Routes.signIn);
            },
          ),
          const SizedBox(height: 10),
          // Dismissal is a real choice, so it is a full-width target with the
          // same weight of label — not a small "cancel".
          Semantics(
            button: true,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: Radii.buttonAll,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: Touch.min),
                  alignment: Alignment.center,
                  child: Text(
                    'Keep looking around',
                    style: text.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
