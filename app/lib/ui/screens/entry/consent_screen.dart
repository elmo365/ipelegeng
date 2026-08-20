/// Consent capture — FR-1.10.
///
/// "Required consent is a bordered card; optional channels are toggle rows in
/// their own group, each recorded separately."
///
/// The OTP screen already captures consent for a new account. This screen
/// exists for the other path, which is the one that cannot be skipped: an
/// existing user whose agreed version is behind [Consent.current] is sent here
/// before anything else proceeds. That is why the version is printed as a chip
/// rather than assumed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session.dart';
import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../../components/actions.dart';
import '../../components/choice_cards.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _agreed = false;
  final _channels = <ConsentChannel>{};

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.x6,
                Space.x6,
                Space.x6,
                Space.x2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Before you continue',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      _VersionChip(label: Consent.termsLabel),
                      const SizedBox(width: 7),
                      _VersionChip(label: Consent.privacyLabel),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Space.x5,
                  Space.x4,
                  Space.x5,
                  Space.x5,
                ),
                children: [
                  ConsentCard(
                    required: true,
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v),
                    label: 'I agree to the Terms of Service and Privacy Policy',
                  ),
                  const SizedBox(height: Space.x3),
                  Text(
                    'OPTIONAL · CHANGE ANY TIME',
                    style: AppTypography.sectionLabel.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 9),
                  for (final channel in ConsentChannel.values) ...[
                    ChannelToggle(
                      label: channel.label,
                      icon: switch (channel) {
                        ConsentChannel.sms => Icons.sms,
                        ConsentChannel.whatsApp => Icons.chat,
                      },
                      value: _channels.contains(channel),
                      onChanged: (v) => setState(() {
                        // Each one is its own record. Never one switch that
                        // sets both.
                        v ? _channels.add(channel) : _channels.remove(channel);
                      }),
                    ),
                    const SizedBox(height: 9),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.x5, 0, Space.x5, 22),
              child: PrimaryAction(
                label: 'Agree & continue',
                onPressed: _agreed
                    ? () {
                        ref
                            .read(sessionProvider.notifier)
                            .agree(channels: {..._channels});
                        context.goReplacing(Routes.home);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.chipNeutralBg,
        borderRadius: Radii.pillAll,
      ),
      child: Text(
        label,
        style: AppTypography.chipLabel.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: palette.chipNeutralText,
        ),
      ),
    );
  }
}
