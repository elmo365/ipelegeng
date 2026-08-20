/// The gradient band at the top of an entry screen.
///
/// Register, sign in and OTP all open with the same object: a radial blue
/// field, squared off at the top and rounded 28 at the bottom, carrying the
/// title and one line of explanation. It reads as the top of the page rather
/// than as a card floating on it, which is why it is not a [HeroSurface].
///
/// See docs/design-system.md#surface-treatment.
library;

import 'package:flutter/material.dart';

import '../../theme/dimens.dart';
import '../../theme/tokens.dart';

class EntryHeader extends StatelessWidget {
  const EntryHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleRich,
    this.leading,
  });

  final String title;

  /// One line under the title. Use [subtitleRich] instead when part of it
  /// needs the mono face — the OTP screen sets the number that way.
  final String? subtitle;
  final Widget? subtitleRich;

  /// The avatar on sign in, the glyph plate on OTP. Sits above the title.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      // Full width, always. A Column centres its children on the cross axis
      // and this band is only as wide as its own text otherwise — which is
      // invisible on a screen with a long subtitle and obvious on one with a
      // short one.
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: palette.entryGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radii.hero),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.x6,
            Space.x6,
            Space.x6,
            Space.x8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(height: Space.x4),
              ],
              // Empty when [leading] already carries the greeting — sign in
              // puts the name beside the avatar rather than under it.
              if (title.isNotEmpty)
                Text(
                  title,
                  style: text.headlineSmall?.copyWith(
                    color: Brand.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (subtitle != null || subtitleRich != null) ...[
                const SizedBox(height: Space.x2),
                DefaultTextStyle.merge(
                  style:
                      text.bodyMedium?.copyWith(
                        height: 1.5,
                        // 82% white: legible against the gradient at every
                        // stop, which a flat tint of the palette's muted grey
                        // would not be.
                        color: Brand.white.withValues(alpha: 0.82),
                      ) ??
                      const TextStyle(),
                  child: subtitleRich ?? Text(subtitle!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The round initials chip on sign in: "KM" on a translucent white disc.
///
/// It shows *which* account is being entered. A returning user with two
/// numbers needs to see that before typing one.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.initials, this.size = 44});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Brand.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: text.labelLarge?.copyWith(
          color: Brand.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The translucent glyph plate on the OTP header: a 46 dp rounded square with
/// the `sms` mark on it.
class HeaderGlyph extends StatelessWidget {
  const HeaderGlyph({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Brand.white.withValues(alpha: 0.16),
        borderRadius: const BorderRadius.all(Radii.button),
      ),
      child: Icon(icon, size: 24, color: Brand.white),
    );
  }
}
