/// Location permission.
///
/// "The three promises are cards rather than a paragraph, and the manual
/// fallback carries equal visual weight."
///
/// Both halves are the design. The promises are specific and checkable —
/// *only while the app is open*, *nothing tracked in the background*, *you can
/// pick your area from a list instead* — because a vague permission prompt on
/// a data-conscious handset gets refused. And "Choose my area instead" is a
/// [SoftAction], not a text link: refusing is a supported way to use the app,
/// not a degraded one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session.dart';
import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../components/actions.dart';
import '../../components/choice_cards.dart';

class LocationScreen extends ConsumerWidget {
  const LocationScreen({super.key});

  static const _promises = <String>[
    'Only while the app is open',
    'Nothing tracked in the background',
    'You can pick your area from a list instead',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    void answer(bool granted) {
      ref.read(sessionProvider.notifier).setLocationGranted(granted);
      context.goReplacing(Routes.home);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.cardBg,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  boxShadow: palette.shadowCard,
                ),
                child: Icon(
                  Icons.location_on,
                  size: 30,
                  color: palette.accentText,
                ),
              ),
              const SizedBox(height: Space.x5),
              Text(
                'Show providers near you?',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Space.x2),
              Text(
                'Ipelege uses your location to sort providers by distance and '
                'to share pickup points with a driver on a ride.',
                style: text.bodyMedium?.copyWith(
                  height: 1.6,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 18),
              for (final promise in _promises) ...[
                PromiseCard(label: promise),
                const SizedBox(height: 9),
              ],
              const Spacer(),
              PrimaryAction(
                label: 'Allow while using the app',
                onPressed: () => answer(true),
              ),
              const SizedBox(height: 10),
              SoftAction(
                label: 'Choose my area instead',
                onPressed: () => answer(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
