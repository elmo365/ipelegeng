/// Confirm your number — the OTP step.
///
/// "Code entry is its own card with the resend timer attached; required
/// consent is bordered and separable from the optional channel."
///
/// Two things here are rules rather than layout:
///
/// - **The required consent is on this screen, not after it.** FR-1.10 wants
///   consent captured at the point of account creation, and a separate screen
///   afterwards is a screen people learn to dismiss.
/// - **"Verify & continue" stays dead until both are satisfied** — four digits
///   *and* the required tick. A disabled primary is the honest form of "you
///   cannot proceed"; an enabled one that then complains is not.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session.dart';
import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../../components/actions.dart';
import '../../components/choice_cards.dart';
import '../../components/entry_header.dart';

class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  /// The design draws four boxes.
  static const codeLength = 4;

  /// `0:42` on the canvas. Long enough that a slow SMS arrives before the
  /// resend is offered, short enough that a lost one is not a dead end.
  static const resendSeconds = 42;

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  bool _agreed = false;
  bool _smsUpdates = false;

  Timer? _ticker;
  int _remaining = VerifyScreen.resendSeconds;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
    _startCountdown();
  }

  void _startCountdown() {
    _ticker?.cancel();
    setState(() => _remaining = VerifyScreen.resendSeconds);
    // Bounded, and it stops. Nothing in this design loops.
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  bool get _complete => _code.text.length == VerifyScreen.codeLength;
  bool get _ready => _complete && _agreed;

  void _verify() {
    ref.read(sessionProvider.notifier)
      ..confirmCode()
      ..agree(channels: {if (_smsUpdates) ConsentChannel.sms});

    // Replace, not push: the code has been spent, and back must not be able to
    // re-enter a flow that would send a second one.
    //
    // The enrolment offer comes straight after the first OTP and is made once —
    // "offered once after first OTP, declinable without penalty". Skipping it
    // is what left `/unlock` unreachable by any real path.
    final session = ref.read(sessionProvider);
    context.goReplacing(switch (session) {
      _ when !session.biometricOffered => Routes.biometricEnrolment,
      _ when !session.locationGranted => Routes.location,
      _ => Routes.home,
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final phone = ref.watch(sessionProvider).phone ?? '';

    // "Back is blocked in two places. During an OTP verification round trip,
    // and while a payment or top-up is in flight." The code has already been
    // sent server-side, so backing out here does not un-send it — it just
    // strands the person outside a flow they are already in the middle of.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The code has already been sent. Enter it, or start again from '
              'sign in.',
            ),
          ),
        );
      },
      child: Scaffold(
        body: Column(
          children: [
            EntryHeader(
              leading: const HeaderGlyph(icon: Icons.sms),
              title: 'Confirm your number',
              subtitleRich: Text.rich(
                TextSpan(
                  text: 'Code sent to ',
                  children: [
                    TextSpan(
                      text: phone,
                      style: TextStyle(
                        fontFamily: AppFonts.mono,
                        fontWeight: FontWeight.w600,
                        color: Brand.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, Space.x5, 22, Space.x5),
                children: [
                  _CodeCard(
                    controller: _code,
                    focusNode: _codeFocus,
                    remaining: _remaining,
                    onResend: _startCountdown,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'CONSENT · V${Consent.current}',
                    style: AppTypography.sectionLabel.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 9),
                  ConsentCard(
                    required: true,
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v),
                    label: 'I agree to the Terms of Service and Privacy Policy',
                  ),
                  const SizedBox(height: 9),
                  ConsentCard(
                    value: _smsUpdates,
                    onChanged: (v) => setState(() => _smsUpdates = v),
                    label: ConsentChannel.sms.label,
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_complete && !_agreed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.x2),
                        child: Text(
                          'The required consent above has to be ticked before '
                          'the account can be created.',
                          textAlign: TextAlign.center,
                          style: text.labelSmall?.copyWith(
                            fontSize: 11.5,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                    PrimaryAction(
                      label: 'Verify & continue',
                      onPressed: _ready ? _verify : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The code boxes and the resend timer, in one card.
///
/// Four visible boxes over a single hidden field: one field means the platform
/// SMS autofill works and a paste of "1234" lands correctly, which four
/// separate inputs break.
class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.controller,
    required this.focusNode,
    required this.remaining,
    required this.onResend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int remaining;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final canResend = remaining <= 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: Radii.cardAll,
        boxShadow: palette.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Row(
                  children: [
                    for (var i = 0; i < VerifyScreen.codeLength; i++) ...[
                      if (i > 0) const SizedBox(width: 9),
                      Expanded(
                        child: _CodeBox(
                          digit: i < controller.text.length
                              ? controller.text[i]
                              : '',
                          active: i == controller.text.length,
                        ),
                      ),
                    ],
                  ],
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      maxLength: VerifyScreen.codeLength,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: canResend ? onResend : null,
              borderRadius: Radii.buttonAll,
              child: Row(
                children: [
                  Icon(
                    canResend ? Icons.refresh : Icons.timer,
                    size: 16,
                    color: canResend ? palette.accentText : palette.textFaint,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    canResend
                        ? 'Resend code'
                        : 'Resend code in 0:${remaining.toString().padLeft(2, '0')}',
                    style: text.labelSmall?.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: canResend ? palette.accentText : palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.digit, required this.active});

  final String digit;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.inputBg,
        borderRadius: Radii.buttonAll,
        border: Border.all(
          color: active ? palette.accentText : palette.inputBorder,
          width: 1.5,
        ),
      ),
      child: Text(
        digit,
        style: text.headlineSmall?.copyWith(
          fontFamily: AppFonts.mono,
          fontSize: 23,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      ),
    );
  }
}
