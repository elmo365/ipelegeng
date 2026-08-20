/// A form field as its own card.
///
/// "Each field is its own card" — the design's note on the register screen.
/// The label sits above a bordered input rather than floating into it, so the
/// requirement stays readable while the field is being typed into, which is
/// exactly when it needs re-reading.
///
/// The card carries `shadowCard` (the canvas calls it `shRaise`) and the input
/// inside it carries a border. That is not a contradiction of "a shadow or a
/// border, never both": they are two different surfaces.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/dimens.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

class FormFieldCard extends StatelessWidget {
  const FormFieldCard({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.hintIcon,
    this.note,
    this.keyboardType,
    this.mono = false,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
  });

  /// `FULL NAME`. Rendered in the design's small caps label style.
  final String label;

  /// Leading glyph inside the input. Takes the accent colour once the field
  /// has focus, along with the border — the canvas draws the focused phone
  /// field that way.
  final IconData icon;

  final TextEditingController controller;
  final String? hint;

  /// The small line under the input: "We'll text a code to confirm this
  /// number", with its own glyph.
  final IconData? hintIcon;
  final String? note;

  final TextInputType? keyboardType;

  /// A phone number is set in the mono face so the digits align — the same
  /// rule money follows.
  final bool mono;

  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: Radii.cardAll,
        boxShadow: palette.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.fieldLabel.copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: Space.x2),
            _Input(
              icon: icon,
              controller: controller,
              hint: hint,
              keyboardType: keyboardType,
              mono: mono,
              autofocus: autofocus,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
            ),
            if (note != null) ...[
              const SizedBox(height: 9),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hintIcon != null) ...[
                    Icon(hintIcon, size: 15, color: palette.textFaint),
                    const SizedBox(width: 7),
                  ],
                  Expanded(
                    child: Text(
                      note!,
                      style: text.labelSmall?.copyWith(
                        fontSize: 11.5,
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The bordered row the text actually sits in. Split out because it is the
/// part that reacts to focus, and rebuilding only this keeps the card still.
class _Input extends StatefulWidget {
  const _Input({
    required this.icon,
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.mono,
    required this.autofocus,
    required this.textInputAction,
    required this.onSubmitted,
  });

  final IconData icon;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool mono;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_Input> createState() => _InputState();
}

class _InputState extends State<_Input> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final focused = _focus.hasFocus;

    final style = widget.mono
        ? text.bodyLarge?.copyWith(fontFamily: AppFonts.mono)
        : text.bodyLarge;

    return Container(
      constraints: const BoxConstraints(minHeight: Touch.min),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: Radii.inputAll,
        border: Border.all(
          color: focused ? palette.accentText : palette.inputBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.icon,
            size: 19,
            color: focused ? palette.accentText : palette.textFaint,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              style: style?.copyWith(color: palette.textPrimary),
              cursorColor: palette.accentText,
              inputFormatters: widget.keyboardType == TextInputType.phone
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))]
                  : null,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: Space.x3,
                ),
                hintText: widget.hint,
                hintStyle: style?.copyWith(color: palette.textFaint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
