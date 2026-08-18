/// A note that explains a rule the user is about to be held to — what a
/// verification requires, why a booking cannot be cancelled, what a fee covers.
///
/// It appears instantly. This is not a toast and not an alert: it does not
/// travel, and it never animates in over content the user is already reading.
///
/// Tones map onto the palette's info and danger pairs, which are re-toned per
/// theme rather than re-hued.
library;

import 'package:flutter/material.dart';

import '../../theme/dimens.dart';
import '../../theme/tokens.dart';

enum NoteTone { info, warning, danger }

class InfoNote extends StatelessWidget {
  const InfoNote({
    super.key,
    required this.body,
    this.title,
    this.tone = NoteTone.info,
  });

  final String body;
  final String? title;
  final NoteTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    final (bg, border, titleColor, bodyColor, icon) = switch (tone) {
      NoteTone.info => (
        p.infoBg,
        p.infoBorder,
        p.infoTitle,
        p.infoText,
        Icons.info_outline,
      ),
      NoteTone.warning => (
        p.pendingBg,
        p.pendingText,
        p.pendingText,
        p.pendingText,
        Icons.schedule,
      ),
      NoteTone.danger => (
        p.dangerBg,
        p.dangerText,
        p.dangerText,
        p.dangerText,
        Icons.error_outline,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(Space.x3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: Radii.cardAll,
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: titleColor),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: text.titleMedium?.copyWith(color: titleColor),
                  ),
                  const SizedBox(height: Space.x1),
                ],
                Text(
                  body,
                  style: text.bodySmall?.copyWith(color: bodyColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
