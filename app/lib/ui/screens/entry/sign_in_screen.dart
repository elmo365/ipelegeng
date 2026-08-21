/// Sign in.
///
/// "Every fresh login goes through OTP — the returning name is shown so the
/// person knows which account they are entering." One field, because there is
/// nothing else to ask: the code is the authentication.
///
/// The name and initials come from the session when the device remembers an
/// account. On a genuinely fresh device the header falls back to a greeting
/// with no name rather than inventing one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/haptics.dart';
import '../../../core/phone.dart';
import '../../../core/session.dart';
import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../components/actions.dart';
import '../../components/entry_header.dart';
import '../../components/form_field_card.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: ref.read(sessionProvider).phone ?? '')
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  bool _busy = false;

  /// Why the last send did not happen. Null when nothing has failed — an
  /// error that outlives its cause is worse than none.
  String? _error;

  bool get _ready => Phone.isPlausible(_phone.text) && !_busy;

  /// Nothing here used to ask for a code — the screen set the session's state
  /// and navigated, and with a stub verifier that looked identical to working.
  /// It is a real send now, and **the screen only moves on if one happened**:
  /// a "Confirm your number" screen above a code that was never sent is the
  /// worst version of this failing.
  Future<void> _send() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final phone = Phone.normalise(_phone.text);
    final outcome = await ref.read(otpVerifierProvider).send(phone);

    if (!mounted) return;
    setState(() => _busy = false);

    switch (outcome) {
      case OtpSendOutcome.sent:
        ref.read(sessionProvider.notifier).requestCode(phone: phone);
        context.goReplacing(Routes.verify);
      case OtpSendOutcome.invalidNumber:
        setState(() => _error = Phone.requirement);
      case OtpSendOutcome.tooManyRequests:
        Haptics.error();
        setState(
          () => _error =
              'Too many codes requested for this number. Wait a few minutes '
              'and try again.',
        );
      case OtpSendOutcome.unavailable:
        Haptics.error();
        setState(
          () => _error =
              'Could not send a code just now. Check your connection and try '
              'again.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final known = session.name != null && session.name!.isNotEmpty;

    return Scaffold(
      body: Column(
        children: [
          EntryHeader(
            leading: known
                ? Row(
                    children: [
                      InitialsAvatar(initials: session.initials),
                      const SizedBox(width: Space.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Welcome back',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Brand.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              session.name!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Brand.white.withValues(alpha: 0.78),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
            // When the avatar row is present it carries the greeting, so the
            // header's own title would repeat it.
            title: known ? '' : 'Welcome back',
            subtitle: "Enter your number and we'll text you a code.",
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.x5,
                18,
                Space.x5,
                Space.x5,
              ),
              children: [
                FormFieldCard(
                  label: 'PHONE NUMBER',
                  icon: Icons.phone,
                  controller: _phone,
                  hint: Phone.placeholder,
                  keyboardType: TextInputType.phone,
                  mono: true,
                  autofocus: true,
                  // Says why the button is dead, instead of leaving the user
                  // to guess. Null while the field is empty — nothing is
                  // wrong yet.
                  // The field's own requirement while typing; whatever the
                  // send actually failed with once one has been tried.
                  note: _error ?? Phone.noteFor(_phone.text),
                  hintIcon: Icons.info_outline,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (_ready) _send();
                  },
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.x5, 0, Space.x5, 22),
              child: Column(
                children: [
                  PrimaryAction(
                    label: _busy ? 'Sending…' : 'Send code',
                    icon: Icons.sms,
                    onPressed: _ready ? _send : null,
                  ),
                  const SizedBox(height: Space.x2),
                  InlineLink(
                    prefix: 'New here?',
                    action: 'Create an account',
                    onTap: () => context.goReplacing(Routes.register),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
