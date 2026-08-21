/// Create your account — UC-1.
///
/// "Each field is its own card, and the reason there is no password is stated
/// where the decision lands." The passwordless note is not a footer: it sits
/// directly under the number, at the moment the person is wondering what
/// happens next.
///
/// Nothing is validated against a server yet. What is enforced is the shape
/// the design fixed: a name and a number, then a code — never a password.
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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.addListener(_refresh);
    _phone.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool _busy = false;

  /// Why the last send did not happen. Null when nothing has failed.
  String? _error;

  bool get _ready =>
      _name.text.trim().isNotEmpty && Phone.isPlausible(_phone.text) && !_busy;

  /// A real send, and the screen only moves on if one happened. See the same
  /// method on the sign-in screen for why: this used to navigate to "Confirm
  /// your number" whether or not a code existed.
  Future<void> _continue() async {
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
        ref
            .read(sessionProvider.notifier)
            .requestCode(name: _name.text.trim(), phone: phone);
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
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        children: [
          const EntryHeader(
            title: 'Create your account',
            subtitle:
                "You'll start as a customer. You can apply to offer services "
                'later.',
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
                  label: 'FULL NAME',
                  icon: Icons.person,
                  controller: _name,
                  hint: 'Kabo Mothibi',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: Space.x3),
                FormFieldCard(
                  label: 'PHONE NUMBER',
                  icon: Icons.phone,
                  controller: _phone,
                  hint: Phone.placeholder,
                  keyboardType: TextInputType.phone,
                  mono: true,
                  // The promise while the number is fine; **why the button is
                  // dead** once it is not. One slot, because two lines under
                  // one field is noise and the validation is the more urgent
                  // of the two.
                  hintIcon: (_error ?? Phone.noteFor(_phone.text)) == null
                      ? Icons.sms
                      : Icons.info_outline,
                  note:
                      _error ??
                      Phone.noteFor(_phone.text) ??
                      "We'll text a code to confirm this number",
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (_ready) _continue();
                  },
                ),
                const SizedBox(height: Space.x3),
                // Stated here rather than in a help page: this is where the
                // absence of a password field becomes a question.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: palette.selectedBg,
                    borderRadius: Radii.rowAll,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock, size: 18, color: palette.accentText),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No password to create, forget or have phished. A '
                          'code confirms it is you.',
                          style: text.labelSmall?.copyWith(
                            fontSize: 11.5,
                            height: 1.5,
                            color: palette.accentText,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                    label: 'Continue',
                    onPressed: _ready ? _continue : null,
                  ),
                  const SizedBox(height: Space.x2),
                  InlineLink(
                    prefix: 'Already have an account?',
                    action: 'Sign in',
                    onTap: () => context.goReplacing(Routes.signIn),
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
