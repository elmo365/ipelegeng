/// First open.
///
/// "Three cards say what the app is for instead of one line of prose, and the
/// sign-in route is visible immediately." Both halves matter: a marketplace
/// with nine categories cannot be summarised in a sentence without picking a
/// winner, and a returning user must not have to tap "Get started" to find
/// sign in.
///
/// The lockup is missing — see docs/identity.md. Its slot is held rather than
/// filled with a substitute mark.
library;

import 'package:flutter/material.dart';

import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../components/actions.dart';
import '../../components/brand_lockup.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// Verbatim from the canvas. Three promises, in the order the business
  /// leads with: dispatch first because it is daily, trades second because
  /// they are the breadth, verification third because it is the reason to
  /// trust either.
  static const _promises = <(IconData, String)>[
    (Icons.directions_car, 'Rides, when you need one'),
    (Icons.handyman, 'Movers, plumbers, tilers, caterers'),
    (Icons.verified_user, 'Every provider verified before listing'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.splashGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.x8,
              vertical: Space.x10,
            ),
            child: Column(
              children: [
                const Expanded(
                  child: Center(child: BrandLockup(width: 176)),
                ),
                for (final (icon, label) in _promises) ...[
                  _PromiseOnDark(icon: icon, label: label),
                  const SizedBox(height: 9),
                ],
                const SizedBox(height: Space.x4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // White on the gradient, not brand blue: the ground is
                    // already brand blue, and a blue button on it would sink.
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Brand.white,
                      foregroundColor: Brand.heroDeep,
                      padding: const EdgeInsets.symmetric(vertical: Space.x4),
                    ),
                    onPressed: () => context.pushScreen(Routes.register),
                    child: const Text('Get started'),
                  ),
                ),
                const SizedBox(height: Space.x3),
                InlineLink(
                  prefix: 'Already have an account?',
                  action: 'Sign in',
                  onDark: true,
                  onTap: () => context.pushScreen(Routes.signIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A promise card on the gradient: a 10% white plate rather than a surface,
/// because there is no page underneath for a real card to float on.
class _PromiseOnDark extends StatelessWidget {
  const _PromiseOnDark({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Brand.white.withValues(alpha: 0.10),
        borderRadius: Radii.rowAll,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Brand.sky),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Brand.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
