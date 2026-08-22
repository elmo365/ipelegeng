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

import '../../../core/haptics.dart';
import '../../../core/session.dart';
import '../../../routing/entry_flow.dart';
import '../../../routing/navigation.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../../components/actions.dart';
import '../../components/choice_cards.dart';
import '../../components/entry_header.dart';

class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  /// Deliberately an alias rather than its own number: two constants that
  /// mean the same thing are two constants that will disagree. See
  /// [Session.codeLength] for why it is six and not the artboard's four.
  static const codeLength = Session.codeLength;

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

  /// Whether **this** round is the one that owes consent — no stored version,
  /// or one that has been superseded.
  ///
  /// Read once, at build, and never re-read: it must not flip mid-round, and
  /// the answer changes the moment [SessionController.agree] runs.
  ///
  /// **A returning member is not asked again.** The artboard draws the consent
  /// card on every verification, and drawing it for someone whose consent is
  /// current means an unticked optional box silently withdraws a channel they
  /// granted — signing in is not a place to renegotiate consent. Registered in
  /// docs/design-deltas.md and docs/entry-flow.md §9.2.
  late final bool _owesConsent =
      ref.read(sessionProvider).consentVersion != Consent.current;

  /// The platform read the SMS itself and there is nothing left to type.
  StreamSubscription<void>? _autoVerified;

  Timer? _ticker;
  int _remaining = VerifyScreen.resendSeconds;

  /// A resend is in flight. Separate from the countdown: the countdown says
  /// whether one *may* be sent, this says whether one *is* being sent.
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _code.addListener(() {
      // Typing clears the error. It described the previous code.
      if (_wrongCode && _code.text.isNotEmpty) _wrongCode = false;
      setState(() {});
    });
    // Android auto-retrieval. The round was opened by the previous screen, so
    // this stream is the only way this screen hears about it — see
    // [OtpVerifier.autoVerifications].
    _autoVerified = ref.read(otpVerifierProvider).autoVerifications.listen((_) {
      if (mounted) _verify();
    });
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

  /// **Resend actually sends.** This was wired to [_startCountdown] alone, so
  /// the button restarted the timer and nothing else — the one situation it
  /// exists for, an SMS that never arrived, was the one it could not fix.
  ///
  /// It does not restore attempts. The limit is on guessing, and a resend that
  /// reset it would make it decorative. See docs/entry-flow.md §6.4.
  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);

    final phone = ref.read(sessionProvider).phone ?? '';
    final outcome = await ref.read(otpVerifierProvider).send(phone);

    if (!mounted) return;
    setState(() => _resending = false);

    switch (outcome) {
      case OtpSendOutcome.sent:
        _startCountdown();
        _say('A new code is on its way.');
      // The platform answered the resend by verifying outright. Nothing left to
      // type, so nothing to come back to this screen for.
      case OtpSendOutcome.autoVerified:
        _verify();
      case OtpSendOutcome.tooManyRequests:
        Haptics.error();
        _say(
          'Too many codes requested for this number. Wait a few minutes and '
          'try again.',
        );
      case OtpSendOutcome.invalidNumber:
      case OtpSendOutcome.unavailable:
        Haptics.error();
        // The countdown is deliberately not restarted: nothing was sent, so
        // there is nothing to wait for and the button should stay live.
        _say('Could not send a new code just now. Try again.');
    }
  }

  void _say(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  void dispose() {
    _autoVerified?.cancel();
    _ticker?.cancel();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  /// Set when a code comes back wrong. Cleared as soon as the person types
  /// again — an error that outlives the thing it describes is noise.
  bool _wrongCode = false;

  bool get _complete => _code.text.length == VerifyScreen.codeLength;

  /// Satisfied when this round does not owe consent at all, or when the
  /// required box has been ticked.
  bool get _consented => !_owesConsent || _agreed;

  bool get _ready =>
      _complete && _consented && !ref.read(sessionProvider).codeLocked;

  Future<void> _submit() async {
    final outcome = await ref
        .read(sessionProvider.notifier)
        .submitCode(_code.text, ref.read(otpVerifierProvider));

    // The await crosses a network with a real sender, and the screen can be
    // gone by the time it returns.
    if (!mounted) return;

    switch (outcome) {
      case OtpOutcome.accepted:
        _verify();
      case OtpOutcome.wrongCode:
      case OtpOutcome.locked:
        // "Error. A wrong OTP or a failed top-up, **paired with the
        // message**." The buzz never fires without the text.
        Haptics.error();
        setState(() {
          _wrongCode = true;
          _code.clear();
        });
    }
  }

  /// The round passed — by a typed code, by auto-retrieval, or by the platform
  /// answering a resend outright. All three land here.
  void _verify() {
    final session = ref.read(sessionProvider.notifier)
      // Idempotent, and called unconditionally because the three ways in do not
      // agree on whether it has already run: `submitCode` calls it, the two
      // platform paths do not.
      ..confirmCode();

    // **Only when this round owes it.** Calling `agree` for a member whose
    // consent is current would rewrite their channel grants from two
    // checkboxes they were never shown.
    if (_owesConsent) {
      session.agree(channels: {if (_smsUpdates) ConsentChannel.sms});
    }

    // Replace, not push: the code has been spent, and back must not be able to
    // re-enter a flow that would send a second one.
    //
    // The ladder afterwards is [nextEntryRoute]'s, shared with the two screens
    // that can reach a verified session without ever showing this one.
    context.goReplacing(nextEntryRoute(ref.read(sessionProvider)));
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
                    resending: _resending,
                    onResend: _resend,
                  ),
                  if (_owesConsent) ...[
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
                      label:
                          'I agree to the Terms of Service and Privacy Policy',
                    ),
                    const SizedBox(height: 9),
                    ConsentCard(
                      value: _smsUpdates,
                      onChanged: (v) => setState(() => _smsUpdates = v),
                      label: ConsentChannel.sms.label,
                    ),
                  ],
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
                    if (_complete && !_consented)
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
                      onPressed: _ready ? _submit : null,
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
    required this.resending,
    required this.onResend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int remaining;
  final bool resending;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final canResend = remaining <= 0 && !resending;

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
                    resending
                        ? 'Sending a new code…'
                        : canResend
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
